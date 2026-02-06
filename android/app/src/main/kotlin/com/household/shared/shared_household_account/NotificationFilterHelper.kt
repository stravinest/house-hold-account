package com.household.shared.shared_household_account

import android.util.Log
import io.flutter.BuildConfig

/**
 * 금융 알림 필터링 순수 함수 모음
 * FinancialNotificationListener에서 추출하여 테스트 가능하도록 분리
 */
object NotificationFilterHelper {

    private const val TAG = "NotificationFilter"

    // 금융 앱 패키지명 목록 (소문자로 저장)
    val FINANCIAL_APP_PACKAGES: Set<String> = buildSet {
        // KB 카드/은행
        add("com.kbcard.cxh.appcard")
        add("com.kbstar.kbbank")
        // 신한 카드/은행
        add("com.shcard.smartpay")
        add("com.shinhancard.wallet")
        add("com.shinhan.sbanking")
        // 삼성 카드/페이
        add("kr.co.samsungcard.mpocket")
        add("com.samsung.android.spay")
        add("net.ib.android.smcard")
        // 현대카드
        add("com.hyundaicard.appcard")
        add("com.hyundaicard.weather")
        add("com.hyundaicard.cultureapp")
        // 롯데카드
        add("com.lcacapp")
        add("com.lottecard.lcap")
        // 경기지역화폐
        add("gov.gyeonggi.ggcard")
        // 간편결제
        add("com.kakaopay.app")
        add("com.naverfin.payapp")
        add("viva.republica.toss")
        // 우리 카드/은행
        add("com.wooricard.smartapp")
        add("com.wooribank.smart.npib")
        // 하나 카드/은행
        add("com.hanaskcard.paycla")
        add("com.hanabank.ebk.channel.android.hananbank")
        // NH농협
        add("nh.smart.nhallonepay")
        add("com.nh.cashcardapp")
        // 기타 은행
        add("com.ibk.neobanking")
        add("com.epost.psf.sdsi")
        add("com.kdb.mobilebank")
        add("kr.co.citibank.citimobile")
        // 테스트용 패키지 (디버그 빌드에서만 포함)
        if (BuildConfig.DEBUG) {
            add("com.android.shell")
        }
    }

    // 카카오톡 알림톡 지원 패키지
    val ALIMTALK_APP_PACKAGES: Set<String> = setOf(
        "com.kakao.talk",
    )

    // 카카오톡 알림톡 금융 채널 키워드
    val FINANCIAL_CHANNEL_KEYWORDS: List<String> = listOf(
        // 카드사
        "KB국민카드", "국민카드", "신한카드", "삼성카드", "현대카드",
        "롯데카드", "우리카드", "하나카드", "BC카드", "NH카드",
        "비씨카드",
        // 은행
        "KB국민은행", "국민은행", "신한은행", "우리은행", "하나은행",
        "NH농협", "농협은행", "IBK기업은행", "기업은행",
        "카카오뱅크", "토스뱅크", "케이뱅크",
        // 간편결제
        "카카오페이", "네이버페이",
        // 카카오톡 알림톡 채널명 (실제 알림에서 title로 사용됨)
        "카드영수증",
    )

    // 카카오톡 알림톡 본문 거래 키워드
    val ALIMTALK_TRANSACTION_KEYWORDS: List<String> = listOf(
        "승인", "결제", "출금", "입금", "이체", "충전",
        "취소", "환불", "일시불", "할부", "사용금액",
        "잔액", "체크카드", "신용카드",
    )

    // 금액 패턴 정규식
    val AMOUNT_PATTERN: Regex = Regex("[0-9,]+원|\\d{1,3}(,\\d{3})+")

    // 메시지 앱 패키지명 목록
    val MESSAGE_APP_PACKAGES: Set<String> = buildSet {
        add("com.samsung.android.messaging")
        add("com.google.android.apps.messaging")
        add("com.android.mms")
        add("com.sonyericsson.conversations")
        add("com.lge.message")
        add("com.htc.sense.mms")
        add("com.motorola.messaging")
        add("org.thoughtcrime.securesms")
        add("com.textra")
        add("com.jb.gosms")
        if (BuildConfig.DEBUG) {
            add("com.android.shell")
        }
    }

    // 결제/거래 관련 키워드
    val PAYMENT_KEYWORDS: List<String> = listOf(
        "원", "won", "krw",
        "승인", "결제", "사용", "출금", "입금", "이체", "충전",
        "취소", "환불", "일시불", "할부",
        "카드", "체크", "신용", "체크카드", "신용카드",
        "계좌", "통장", "잔액",
        "지역화폐", "페이", "pay"
    )

    fun isFinancialApp(packageName: String): Boolean {
        return FINANCIAL_APP_PACKAGES.contains(packageName.lowercase())
    }

    fun isAlimtalkApp(packageName: String): Boolean {
        return ALIMTALK_APP_PACKAGES.contains(packageName.lowercase())
    }

    fun isMessageApp(packageName: String): Boolean {
        return MESSAGE_APP_PACKAGES.contains(packageName.lowercase())
    }

    /**
     * 카카오톡 알림톡 금융 알림 3중 검증
     * 1) title이 금융 채널 키워드 포함 (발신 채널 확인)
     * 2) content에 거래 키워드 포함 (승인, 결제, 출금 등)
     * 3) content에 금액 패턴 포함 (숫자+원)
     * 세 조건 모두 충족해야 금융 알림으로 판별
     */
    fun isFinancialAlimtalk(title: String?, content: String?): Boolean {
        if (title.isNullOrBlank() || content.isNullOrBlank()) {
            Log.d(TAG, "[3중검증] 실패: title 또는 content가 비어있음 - title=${title.isNullOrBlank()}, content=${content.isNullOrBlank()}")
            return false
        }

        // 1) 금융 채널 title 확인
        val isFinancialChannel = FINANCIAL_CHANNEL_KEYWORDS.any { keyword ->
            title.contains(keyword, ignoreCase = true)
        }
        if (!isFinancialChannel) {
            Log.d(TAG, "[3중검증] 1단계 실패: 금융채널 아님 - title='$title'")
            return false
        }

        // 2) 거래 키워드 확인
        val hasTransactionKeyword = ALIMTALK_TRANSACTION_KEYWORDS.any { keyword ->
            content.contains(keyword, ignoreCase = true)
        }
        if (!hasTransactionKeyword) {
            Log.d(TAG, "[3중검증] 2단계 실패: 거래키워드 없음 - title='$title', content='${content.take(80)}'")
            return false
        }

        // 3) 금액 패턴 확인
        val hasAmountPattern = AMOUNT_PATTERN.containsMatchIn(content)
        if (!hasAmountPattern) {
            Log.d(TAG, "[3중검증] 3단계 실패: 금액패턴 없음 - title='$title', content='${content.take(80)}'")
            return false
        }

        Log.d(TAG, "[3중검증] 통과: title='$title'")
        return true
    }

    fun containsPaymentKeyword(text: String): Boolean {
        val lowerText = text.lowercase()
        return PAYMENT_KEYWORDS.any { keyword ->
            lowerText.contains(keyword)
        }
    }

    fun normalizeContent(content: String): String {
        return content
            .replace("\r\n", " ")
            .replace("\n", " ")
            .replace("\r", " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    fun determineSourceType(isFromMessageApp: Boolean): String {
        return if (isFromMessageApp) "sms" else "notification"
    }

    fun getExpectedSource(sourceType: String): String {
        return if (sourceType == "sms") "sms" else "push"
    }
}
