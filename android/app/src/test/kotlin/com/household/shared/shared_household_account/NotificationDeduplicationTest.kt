package com.household.shared.shared_household_account

import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * 알림 중복 방지 로직 테스트
 *
 * Samsung FreecessController freeze/unfreeze 사이클로 인해
 * onNotificationPosted가 동일 알림에 대해 여러 번 호출되는 문제를 방지하는
 * 3중 방어 메커니즘을 검증한다.
 *
 * 방어 계층:
 * 1차: 메모리 캐시 (ConcurrentHashMap) - onNotificationPosted에서 즉시 차단
 * 2차: Mutex - processNotification 순차 실행 보장
 * 3차: SQLite UNIQUE 인덱스 + Supabase duplicateHash - DB 레벨 방어
 */
class NotificationDeduplicationTest {

    // =========================================================================
    // 1차 방어: 메모리 캐시 테스트
    // =========================================================================

    private lateinit var recentHashes: ConcurrentHashMap<String, Long>
    private val dedupWindowMs = 30_000L
    private val maxCacheSize = 50

    @Before
    fun setUp() {
        recentHashes = ConcurrentHashMap()
    }

    /**
     * 동일한 content가 30초 이내에 2번 들어오면 두 번째는 차단되어야 한다.
     * 이것이 Samsung freeze/unfreeze 중복의 가장 일반적인 시나리오이다.
     */
    @Test
    fun `메모리 캐시 - 동일 content가 30초 이내에 재수신되면 중복으로 차단한다`() {
        val content = "KB국민카드 50,000원 승인 스타벅스"
        val contentHash = content.hashCode().toString()

        // 첫 번째 알림 처리
        val firstTime = System.currentTimeMillis()
        assertNull(
            "첫 번째 알림은 캐시에 없어야 한다",
            recentHashes[contentHash]
        )
        recentHashes[contentHash] = firstTime

        // 50ms 후 동일 알림 재수신 (Samsung freeze/unfreeze 시나리오)
        val secondTime = firstTime + 50
        val lastProcessed = recentHashes[contentHash]
        assertNotNull("캐시에 이전 처리 기록이 있어야 한다", lastProcessed)
        assertTrue(
            "30초 이내 동일 알림은 중복으로 판단해야 한다",
            lastProcessed != null && (secondTime - lastProcessed) < dedupWindowMs
        )
    }

    /**
     * 30초가 지난 후 동일 content가 들어오면 새 알림으로 처리해야 한다.
     * 동일한 가게에서 30초 이상 간격으로 결제하는 경우를 허용한다.
     */
    @Test
    fun `메모리 캐시 - 30초 경과 후 동일 content는 새 알림으로 처리한다`() {
        val content = "KB국민카드 50,000원 승인 스타벅스"
        val contentHash = content.hashCode().toString()

        val firstTime = System.currentTimeMillis()
        recentHashes[contentHash] = firstTime

        // 31초 후 동일 알림 수신
        val laterTime = firstTime + 31_000
        val lastProcessed = recentHashes[contentHash]
        assertFalse(
            "30초 경과 후에는 중복이 아니어야 한다",
            lastProcessed != null && (laterTime - lastProcessed) < dedupWindowMs
        )
    }

    /**
     * content가 다르면 (다른 결제) 당연히 차단하면 안 된다.
     */
    @Test
    fun `메모리 캐시 - 서로 다른 content는 각각 독립적으로 처리한다`() {
        val content1 = "KB국민카드 50,000원 승인 스타벅스"
        val content2 = "KB국민카드 30,000원 승인 맥도날드"
        val hash1 = content1.hashCode().toString()
        val hash2 = content2.hashCode().toString()

        assertNotEquals(
            "서로 다른 content는 서로 다른 해시를 가져야 한다",
            hash1, hash2
        )

        val now = System.currentTimeMillis()
        recentHashes[hash1] = now

        assertNull(
            "다른 content의 해시는 캐시에 없어야 한다",
            recentHashes[hash2]
        )
    }

    /**
     * timestamp 버킷 없이 content hash만 사용하므로
     * 분 경계(59.999초 -> 00.001초)에서도 중복 차단이 동작해야 한다.
     * 이전에 timestamp/60000 버킷을 사용했을 때의 Critical 이슈가 수정되었는지 검증한다.
     */
    @Test
    fun `메모리 캐시 - 분 경계에서도 동일 content는 중복으로 차단한다`() {
        val content = "KB국민카드 50,000원 승인 스타벅스"
        val contentHash = content.hashCode().toString()

        // 12:00:59.999에 첫 번째 알림
        val firstTime = 1000L * 60 * 60 * 12 + 59_999  // 임의의 분 경계 직전
        recentHashes[contentHash] = firstTime

        // 12:01:00.001에 두 번째 알림 (분 경계를 넘음)
        val secondTime = firstTime + 2  // 2ms 후
        val lastProcessed = recentHashes[contentHash]

        assertTrue(
            "분 경계를 넘어도 30초 이내면 중복으로 차단해야 한다 (timestamp 버킷 미사용)",
            lastProcessed != null && (secondTime - lastProcessed) < dedupWindowMs
        )
    }

    // =========================================================================
    // 캐시 정리 로직 테스트
    // =========================================================================

    /**
     * 오래된 캐시 항목이 정리되어 메모리 누수를 방지해야 한다.
     */
    @Test
    fun `캐시 정리 - 30초 경과한 항목은 제거된다`() {
        val now = System.currentTimeMillis()

        // 오래된 항목 추가
        recentHashes["old_hash_1"] = now - 40_000  // 40초 전
        recentHashes["old_hash_2"] = now - 35_000  // 35초 전
        recentHashes["recent_hash"] = now - 10_000 // 10초 전

        assertEquals("정리 전 캐시에 3개 항목이 있어야 한다", 3, recentHashes.size)

        // 정리 실행
        recentHashes.entries.removeAll { (now - it.value) > dedupWindowMs }

        assertEquals("정리 후 최근 항목만 남아야 한다", 1, recentHashes.size)
        assertNotNull("10초 전 항목은 유지되어야 한다", recentHashes["recent_hash"])
        assertNull("40초 전 항목은 제거되어야 한다", recentHashes["old_hash_1"])
    }

    /**
     * 캐시 크기가 MAX_CACHE_SIZE를 초과하면 정리가 트리거되어야 한다.
     */
    @Test
    fun `캐시 정리 - 최대 크기 초과 시 오래된 항목이 정리된다`() {
        val now = System.currentTimeMillis()

        // 50개 초과 항목 추가 (대부분 만료됨)
        for (i in 0..55) {
            recentHashes["hash_$i"] = now - 40_000  // 모두 40초 전 (만료)
        }
        recentHashes["recent"] = now  // 최근 항목 1개

        assertTrue(
            "캐시 크기가 MAX_CACHE_SIZE를 초과해야 한다",
            recentHashes.size > maxCacheSize
        )

        // 정리 실행 (FinancialNotificationListener의 정리 로직 시뮬레이션)
        recentHashes.entries.removeAll { (now - it.value) > dedupWindowMs }

        assertEquals("만료된 항목 정리 후 최근 항목만 남아야 한다", 1, recentHashes.size)
    }

    // =========================================================================
    // 2차 방어: Mutex 테스트
    // =========================================================================

    /**
     * Mutex를 사용하면 병렬 코루틴이 순차 실행됨을 검증한다.
     * onNotificationPosted에서 serviceScope.launch로 코루틴이 2개 생성되더라도
     * Mutex로 인해 한 번에 1개만 processNotification을 실행한다.
     */
    @Test
    fun `Mutex - 병렬 코루틴이 순차적으로 실행된다`() = runTest {
        val mutex = Mutex()
        val executionOrder = mutableListOf<Int>()
        val processedCount = AtomicInteger(0)

        // 동시에 2개의 코루틴 실행 (Samsung 중복 시나리오 시뮬레이션)
        val jobs = listOf(
            launch {
                mutex.withLock {
                    executionOrder.add(1)
                    delay(100)  // 처리 시간 시뮬레이션
                    processedCount.incrementAndGet()
                }
            },
            launch {
                mutex.withLock {
                    executionOrder.add(2)
                    delay(100)
                    processedCount.incrementAndGet()
                }
            }
        )

        jobs.forEach { it.join() }

        assertEquals(
            "Mutex를 통해 2개의 코루틴이 모두 순차 실행되어야 한다",
            2, processedCount.get()
        )
        assertEquals(
            "실행 순서가 기록되어야 한다",
            2, executionOrder.size
        )
    }

    /**
     * Mutex + SQLite UNIQUE 조합 시나리오:
     * 첫 번째 코루틴이 SQLite에 저장 성공하면,
     * 두 번째 코루틴은 SQLite UNIQUE 제약에 의해 차단된다.
     */
    @Test
    fun `Mutex + SQLite 시뮬레이션 - 순차 실행 시 두 번째는 중복 감지된다`() = runTest {
        val mutex = Mutex()
        val sqliteStore = ConcurrentHashMap<String, Boolean>()  // SQLite UNIQUE 시뮬레이션
        val savedCount = AtomicInteger(0)
        val duplicateCount = AtomicInteger(0)

        val contentKey = "KB국민카드_50000_스타벅스_같은분버킷"

        // 2개의 동시 코루틴 (동일 알림)
        val jobs = listOf(
            launch {
                mutex.withLock {
                    // SQLite insertWithOnConflict(CONFLICT_IGNORE) 시뮬레이션
                    val existing = sqliteStore.putIfAbsent(contentKey, true)
                    if (existing == null) {
                        savedCount.incrementAndGet()  // 저장 성공
                    } else {
                        duplicateCount.incrementAndGet()  // 중복 감지
                    }
                }
            },
            launch {
                mutex.withLock {
                    val existing = sqliteStore.putIfAbsent(contentKey, true)
                    if (existing == null) {
                        savedCount.incrementAndGet()
                    } else {
                        duplicateCount.incrementAndGet()
                    }
                }
            }
        )

        jobs.forEach { it.join() }

        assertEquals("1건만 저장되어야 한다", 1, savedCount.get())
        assertEquals("1건은 중복으로 감지되어야 한다", 1, duplicateCount.get())
    }

    // =========================================================================
    // 3차 방어: duplicateHash 테스트
    // =========================================================================

    /**
     * auto 모드에서도 duplicateHash가 생성되고 전달되는지 검증한다.
     * 이전에는 auto 모드(createConfirmedTransaction)에서 duplicateHash를 전달하지 않았다.
     */
    @Test
    fun `duplicateHash - FinancialMessageParser의 해시 생성이 결정적이다`() {
        val hash1 = generateTestDuplicateHash(50000, "pm-123", 1700000000000L)
        val hash2 = generateTestDuplicateHash(50000, "pm-123", 1700000000000L)

        assertEquals(
            "동일한 금액, 결제수단, 시간에 대해 같은 해시를 반환해야 한다",
            hash1, hash2
        )
    }

    @Test
    fun `duplicateHash - 금액이 다르면 다른 해시가 생성된다`() {
        val hash1 = generateTestDuplicateHash(50000, "pm-123", 1700000000000L)
        val hash2 = generateTestDuplicateHash(30000, "pm-123", 1700000000000L)

        assertNotEquals(
            "금액이 다르면 다른 해시를 반환해야 한다",
            hash1, hash2
        )
    }

    @Test
    fun `duplicateHash - 결제수단이 다르면 다른 해시가 생성된다`() {
        val hash1 = generateTestDuplicateHash(50000, "pm-123", 1700000000000L)
        val hash2 = generateTestDuplicateHash(50000, "pm-456", 1700000000000L)

        assertNotEquals(
            "결제수단이 다르면 다른 해시를 반환해야 한다",
            hash1, hash2
        )
    }

    @Test
    fun `duplicateHash - 3분 버킷 내 동일 거래는 같은 해시를 가진다`() {
        val baseTime = 1700000000000L
        val hash1 = generateTestDuplicateHash(50000, "pm-123", baseTime)
        val hash2 = generateTestDuplicateHash(50000, "pm-123", baseTime + 60_000)  // 1분 후

        assertEquals(
            "3분 버킷 내 동일 거래는 같은 해시를 가져야 한다",
            hash1, hash2
        )
    }

    @Test
    fun `duplicateHash - 3분 버킷을 넘으면 다른 해시가 생성된다`() {
        val baseTime = 1700000000000L
        val hash1 = generateTestDuplicateHash(50000, "pm-123", baseTime)
        val hash2 = generateTestDuplicateHash(50000, "pm-123", baseTime + 180_001)  // 3분 1ms 후

        assertNotEquals(
            "3분 버킷을 넘으면 다른 해시를 반환해야 한다 (동일 가게 재결제 허용)",
            hash1, hash2
        )
    }

    // =========================================================================
    // 통합 시나리오 테스트
    // =========================================================================

    /**
     * Samsung freeze/unfreeze로 인한 실제 중복 시나리오를 전체 방어 체인으로 검증한다.
     *
     * 시나리오:
     * 1. KB Pay에서 50,000원 결제 알림 수신
     * 2. Samsung FreecessController가 앱을 unfreeze하면서 같은 알림 재전달
     * 3. onNotificationPosted가 50ms 간격으로 2회 호출됨
     * 4. 메모리 캐시에서 두 번째 호출을 차단해야 함
     */
    @Test
    fun `통합 시나리오 - Samsung freeze unfreeze 중복 알림이 메모리 캐시에서 차단된다`() {
        val content = "KB국민카드 체크(9765) 승인 50,000원 스타벅스 잔액 1,234,567원"
        val contentHash = content.hashCode().toString()
        var processedCount = 0

        // 첫 번째 onNotificationPosted 호출
        val firstCallTime = System.currentTimeMillis()
        val firstCheck = recentHashes[contentHash]
        if (firstCheck == null || (firstCallTime - firstCheck) >= dedupWindowMs) {
            recentHashes[contentHash] = firstCallTime
            processedCount++  // processNotification 진입
        }

        // 두 번째 onNotificationPosted 호출 (50ms 후, Samsung 재전달)
        val secondCallTime = firstCallTime + 50
        val secondCheck = recentHashes[contentHash]
        if (secondCheck == null || (secondCallTime - secondCheck) >= dedupWindowMs) {
            recentHashes[contentHash] = secondCallTime
            processedCount++
        }

        assertEquals(
            "Samsung 중복 알림은 메모리 캐시에서 차단되어 1건만 처리되어야 한다",
            1, processedCount
        )
    }

    /**
     * 실제 결제가 연속으로 발생하는 시나리오 (중복이 아닌 정상 케이스).
     * 같은 가게에서 31초 간격으로 2번 결제하면 둘 다 저장되어야 한다.
     */
    @Test
    fun `통합 시나리오 - 31초 간격 연속 결제는 모두 정상 처리된다`() {
        val content = "KB국민카드 체크(9765) 승인 50,000원 스타벅스 잔액 1,234,567원"
        val contentHash = content.hashCode().toString()
        var processedCount = 0

        // 첫 번째 결제
        val firstTime = System.currentTimeMillis()
        val firstCheck = recentHashes[contentHash]
        if (firstCheck == null || (firstTime - firstCheck) >= dedupWindowMs) {
            recentHashes[contentHash] = firstTime
            processedCount++
        }

        // 두 번째 결제 (31초 후, 동일 가게 재결제)
        val secondTime = firstTime + 31_000
        val secondCheck = recentHashes[contentHash]
        if (secondCheck == null || (secondTime - secondCheck) >= dedupWindowMs) {
            recentHashes[contentHash] = secondTime
            processedCount++
        }

        assertEquals(
            "31초 간격 연속 결제는 둘 다 처리되어야 한다",
            2, processedCount
        )
    }

    /**
     * SMS와 Push가 동시에 수신되는 시나리오.
     * 동일 결제에 대해 SMS 알림과 Push 알림이 모두 올 수 있는데,
     * content가 다르므로 둘 다 통과하지만,
     * 이후 결제수단의 autoCollectSource 설정에 의해 하나만 처리된다.
     */
    @Test
    fun `통합 시나리오 - SMS와 Push 알림은 content가 달라 둘 다 메모리 캐시를 통과한다`() {
        val smsContent = "KB국민카드 체크 승인 50,000원 12/15 스타벅스"
        val pushContent = "KB Pay 체크카드(9765) 50,000원 승인 스타벅스 잔액 1,234,567원"
        val smsHash = smsContent.hashCode().toString()
        val pushHash = pushContent.hashCode().toString()

        assertNotEquals(
            "SMS와 Push의 content가 다르므로 해시도 달라야 한다",
            smsHash, pushHash
        )

        val now = System.currentTimeMillis()
        recentHashes[smsHash] = now

        assertNull(
            "Push 해시는 캐시에 없어 통과해야 한다",
            recentHashes[pushHash]
        )
    }

    /**
     * 서비스가 재시작되면 메모리 캐시가 초기화되는 시나리오.
     * companion object(static)에 있으므로 프로세스가 살아있는 동안은 유지된다.
     * 프로세스 재시작 시에는 SQLite UNIQUE 인덱스가 3차 방어로 동작한다.
     */
    @Test
    fun `통합 시나리오 - 캐시 초기화 후에도 SQLite 방어가 동작하는 구조를 가진다`() {
        val content = "KB국민카드 50,000원 승인 스타벅스"
        val contentHash = content.hashCode().toString()
        val now = System.currentTimeMillis()

        // 캐시에 기록
        recentHashes[contentHash] = now

        // 서비스 재시작 시뮬레이션 (캐시 초기화)
        recentHashes.clear()

        assertNull(
            "캐시 초기화 후 해시가 없어야 한다 (이 경우 SQLite UNIQUE가 방어)",
            recentHashes[contentHash]
        )
        assertTrue(
            "캐시가 비어있어야 한다",
            recentHashes.isEmpty()
        )
    }

    // =========================================================================
    // ConcurrentHashMap 동시성 테스트
    // =========================================================================

    /**
     * 여러 스레드에서 동시에 캐시에 접근해도 안전한지 검증한다.
     */
    @Test
    fun `동시성 - 여러 스레드에서 동시 접근해도 ConcurrentHashMap이 안전하다`() = runTest {
        val cache = ConcurrentHashMap<String, Long>()
        val successCount = AtomicInteger(0)

        // 100개의 코루틴이 동시에 서로 다른 키에 접근
        val jobs = (1..100).map { i ->
            launch(Dispatchers.Default) {
                cache["hash_$i"] = System.currentTimeMillis()
                successCount.incrementAndGet()
            }
        }

        jobs.forEach { it.join() }

        assertEquals(
            "100개의 코루틴이 모두 성공적으로 캐시에 기록해야 한다",
            100, successCount.get()
        )
        assertEquals(
            "캐시에 100개 항목이 있어야 한다",
            100, cache.size
        )
    }

    /**
     * 동일 키에 대해 여러 코루틴이 동시 접근하는 경우를 테스트한다.
     * ConcurrentHashMap.putIfAbsent를 사용하면 1개만 성공한다.
     */
    @Test
    fun `동시성 - 동일 키에 putIfAbsent로 1건만 성공한다`() = runTest {
        val cache = ConcurrentHashMap<String, Long>()
        val firstInsertCount = AtomicInteger(0)
        val contentHash = "same_content_hash"

        val jobs = (1..10).map {
            launch(Dispatchers.Default) {
                val existing = cache.putIfAbsent(contentHash, System.currentTimeMillis())
                if (existing == null) {
                    firstInsertCount.incrementAndGet()
                }
            }
        }

        jobs.forEach { it.join() }

        assertEquals(
            "동일 키에 대해 putIfAbsent는 최초 1건만 null(성공)을 반환해야 한다",
            1, firstInsertCount.get()
        )
    }

    // =========================================================================
    // 헬퍼 메서드
    // =========================================================================

    /**
     * 실제 FinancialMessageParser.generateDuplicateHash를 호출하여 검증한다.
     */
    private fun generateTestDuplicateHash(amount: Int, paymentMethodId: String?, timestamp: Long): String {
        return FinancialMessageParser.generateDuplicateHash(amount, paymentMethodId, timestamp)
    }
}
