package com.household.shared.shared_household_account

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

/**
 * 금융 알림을 로컬 SQLite에 캐싱하는 헬퍼 클래스
 * 앱이 종료되어도 알림을 저장하고, 앱 재시작 시 Flutter로 동기화
 */
class NotificationStorageHelper(context: Context) : SQLiteOpenHelper(
    context,
    DATABASE_NAME,
    null,
    DATABASE_VERSION
) {
    companion object {
        private const val TAG = "NotificationStorage"
        private const val DATABASE_NAME = "financial_notifications.db"
        private const val DATABASE_VERSION = 4  // 버전 업그레이드: UNIQUE 제약 조건 추가

        // 테이블 및 컬럼명
        private const val TABLE_NAME = "cached_notifications"
        private const val COLUMN_ID = "id"
        private const val COLUMN_PACKAGE_NAME = "package_name"
        private const val COLUMN_TITLE = "title"
        private const val COLUMN_TEXT = "text"
        private const val COLUMN_RECEIVED_AT = "received_at"
        private const val COLUMN_IS_SYNCED = "is_synced"
        private const val COLUMN_RETRY_COUNT = "retry_count"  // 신규: 재시도 횟수
        private const val COLUMN_SOURCE_TYPE = "source_type"  // 신규: 알림 소스 타입 (sms, notification)
        private const val COLUMN_CREATED_AT = "created_at"

        private val MAX_RETRY_COUNT = NotificationConfig.MAX_RETRY_COUNT

        @Volatile
        private var instance: NotificationStorageHelper? = null

        fun getInstance(context: Context): NotificationStorageHelper {
            return instance ?: synchronized(this) {
                instance ?: NotificationStorageHelper(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTableQuery = """
            CREATE TABLE $TABLE_NAME (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                $COLUMN_TITLE TEXT,
                $COLUMN_TEXT TEXT NOT NULL,
                $COLUMN_RECEIVED_AT INTEGER NOT NULL,
                $COLUMN_IS_SYNCED INTEGER DEFAULT 0,
                $COLUMN_RETRY_COUNT INTEGER DEFAULT 0,
                $COLUMN_SOURCE_TYPE TEXT DEFAULT 'notification',
                $COLUMN_CREATED_AT INTEGER DEFAULT (strftime('%s', 'now'))
            )
        """.trimIndent()

        db.execSQL(createTableQuery)

        // 인덱스 생성
        db.execSQL("CREATE INDEX idx_is_synced ON $TABLE_NAME($COLUMN_IS_SYNCED)")
        db.execSQL("CREATE INDEX idx_received_at ON $TABLE_NAME($COLUMN_RECEIVED_AT)")
        db.execSQL("CREATE INDEX idx_retry_count ON $TABLE_NAME($COLUMN_RETRY_COUNT)")

        Log.d(TAG, "Database created successfully (version $DATABASE_VERSION)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        Log.d(TAG, "Upgrading database from version $oldVersion to $newVersion")

        try {
            if (oldVersion < 2) {
                // v1 -> v2: retry_count 컬럼 추가
                db.execSQL("ALTER TABLE $TABLE_NAME ADD COLUMN $COLUMN_RETRY_COUNT INTEGER DEFAULT 0")
                db.execSQL("CREATE INDEX idx_retry_count ON $TABLE_NAME($COLUMN_RETRY_COUNT)")
                Log.d(TAG, "Added retry_count column")
            }
            if (oldVersion < 3) {
                // v2 -> v3: source_type 컬럼 추가
                db.execSQL("ALTER TABLE $TABLE_NAME ADD COLUMN $COLUMN_SOURCE_TYPE TEXT DEFAULT 'notification'")
                Log.d(TAG, "Added source_type column")
            }
            if (oldVersion < 4) {
                // v3 -> v4: UNIQUE 제약 조건 추가 (text + 1분 버킷으로 중복 방지)
                db.execSQL("""
                    CREATE UNIQUE INDEX idx_unique_content 
                    ON $TABLE_NAME (
                        $COLUMN_TEXT, 
                        ($COLUMN_RECEIVED_AT / 60000)
                    )
                """.trimIndent())
                Log.d(TAG, "Added UNIQUE index on text + time bucket")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Migration failed from v$oldVersion to v$newVersion: ${e.message}", e)
            // 마이그레이션 실패 시 테이블 재생성으로 복구
            // 기존 데이터는 손실되지만 앱 크래시 방지
            try {
                db.execSQL("DROP TABLE IF EXISTS $TABLE_NAME")
                onCreate(db)
                Log.w(TAG, "Database recreated due to migration failure")
            } catch (recreateError: Exception) {
                Log.e(TAG, "Failed to recreate database: ${recreateError.message}", recreateError)
            }
        }
    }

    /**
     * 금융 알림을 저장 (중복 시 무시)
     * @return 저장된 row ID, 중복 시 -1
     */
    fun insertNotification(
        packageName: String,
        title: String?,
        text: String,
        receivedAt: Long = System.currentTimeMillis(),
        sourceType: String = "notification"
    ): Long {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_PACKAGE_NAME, packageName)
            put(COLUMN_TITLE, title)
            put(COLUMN_TEXT, text)
            put(COLUMN_RECEIVED_AT, receivedAt)
            put(COLUMN_IS_SYNCED, 0)
            put(COLUMN_RETRY_COUNT, 0)
            put(COLUMN_SOURCE_TYPE, sourceType)
        }

        val id = db.insertWithOnConflict(TABLE_NAME, null, values, SQLiteDatabase.CONFLICT_IGNORE)
        
        if (id == -1L) {
            Log.d(TAG, "Duplicate notification ignored: $text")
        } else {
            Log.d(TAG, "Notification inserted with id: $id, package: $packageName, sourceType: $sourceType")
        }
        
        return id
    }

    /**
     * 동기화되지 않은 알림 목록 조회
     * retry_count가 MAX_RETRY_COUNT 미만인 알림만 반환
     */
    fun getPendingNotifications(): List<Map<String, Any?>> {
        val db = readableDatabase
        val notifications = mutableListOf<Map<String, Any?>>()

        // is_synced = 0 AND retry_count < MAX_RETRY_COUNT 조건으로 조회
        val cursor = db.query(
            TABLE_NAME,
            null,
            "$COLUMN_IS_SYNCED = ? AND $COLUMN_RETRY_COUNT < ?",
            arrayOf("0", MAX_RETRY_COUNT.toString()),
            null,
            null,
            "$COLUMN_RECEIVED_AT ASC"
        )

        cursor.use {
            while (it.moveToNext()) {
                val retryCountIndex = it.getColumnIndex(COLUMN_RETRY_COUNT)
                val retryCount = if (retryCountIndex >= 0) it.getInt(retryCountIndex) else 0

                val sourceTypeIndex = it.getColumnIndex(COLUMN_SOURCE_TYPE)
                val sourceType = if (sourceTypeIndex >= 0) it.getString(sourceTypeIndex) else "notification"

                val notification = mapOf(
                    "id" to it.getLong(it.getColumnIndexOrThrow(COLUMN_ID)),
                    "packageName" to it.getString(it.getColumnIndexOrThrow(COLUMN_PACKAGE_NAME)),
                    "title" to it.getString(it.getColumnIndexOrThrow(COLUMN_TITLE)),
                    "text" to it.getString(it.getColumnIndexOrThrow(COLUMN_TEXT)),
                    "receivedAt" to it.getLong(it.getColumnIndexOrThrow(COLUMN_RECEIVED_AT)),
                    "isSynced" to (it.getInt(it.getColumnIndexOrThrow(COLUMN_IS_SYNCED)) == 1),
                    "retryCount" to retryCount,
                    "sourceType" to sourceType
                )
                notifications.add(notification)
            }
        }

        Log.d(TAG, "Retrieved ${notifications.size} pending notifications (retry < $MAX_RETRY_COUNT)")
        return notifications
    }

    /**
     * 알림을 동기화됨으로 표시
     */
    fun markAsSynced(ids: List<Long>): Int {
        if (ids.isEmpty()) return 0

        val db = writableDatabase
        val placeholders = ids.joinToString(",") { "?" }
        val values = ContentValues().apply {
            put(COLUMN_IS_SYNCED, 1)
        }

        val count = db.update(
            TABLE_NAME,
            values,
            "$COLUMN_ID IN ($placeholders)",
            ids.map { it.toString() }.toTypedArray()
        )

        Log.d(TAG, "Marked $count notifications as synced")
        return count
    }

    /**
     * 알림의 재시도 횟수를 1 증가
     * 처리 실패 시 호출하여 재시도 횟수 추적
     */
    fun incrementRetryCount(id: Long): Int {
        val db = writableDatabase

        // SQL로 직접 증가 (원자적 연산)
        db.execSQL(
            "UPDATE $TABLE_NAME SET $COLUMN_RETRY_COUNT = $COLUMN_RETRY_COUNT + 1 WHERE $COLUMN_ID = ?",
            arrayOf(id)
        )

        // 업데이트된 retry_count 조회
        val cursor = db.query(
            TABLE_NAME,
            arrayOf(COLUMN_RETRY_COUNT),
            "$COLUMN_ID = ?",
            arrayOf(id.toString()),
            null,
            null,
            null
        )

        var newRetryCount = 0
        cursor.use {
            if (it.moveToFirst()) {
                newRetryCount = it.getInt(0)
            }
        }

        Log.d(TAG, "Incremented retry count for id $id to $newRetryCount")
        return newRetryCount
    }

    /**
     * 오래된 알림 삭제 (동기화된 알림 또는 최대 재시도 초과 알림)
     */
    fun clearOldNotifications(olderThanDays: Int): Int {
        val db = writableDatabase
        val cutoffTime = System.currentTimeMillis() - (olderThanDays * 24 * 60 * 60 * 1000L)

        // 동기화된 알림 또는 최대 재시도 초과 알림 삭제
        val count = db.delete(
            TABLE_NAME,
            "($COLUMN_IS_SYNCED = 1 OR $COLUMN_RETRY_COUNT >= ?) AND $COLUMN_RECEIVED_AT < ?",
            arrayOf(MAX_RETRY_COUNT.toString(), cutoffTime.toString())
        )

        Log.d(TAG, "Deleted $count old notifications")
        return count
    }

    /**
     * 동기화 대기 중인 알림 수 조회 (재시도 가능한 알림만)
     */
    fun getPendingCount(): Int {
        val db = readableDatabase
        val cursor = db.rawQuery(
            "SELECT COUNT(*) FROM $TABLE_NAME WHERE $COLUMN_IS_SYNCED = 0 AND $COLUMN_RETRY_COUNT < ?",
            arrayOf(MAX_RETRY_COUNT.toString())
        )

        var count = 0
        cursor.use {
            if (it.moveToFirst()) {
                count = it.getInt(0)
            }
        }

        return count
    }

    /**
     * 영구 실패한 알림 수 조회 (재시도 초과)
     */
    fun getFailedCount(): Int {
        val db = readableDatabase
        val cursor = db.rawQuery(
            "SELECT COUNT(*) FROM $TABLE_NAME WHERE $COLUMN_IS_SYNCED = 0 AND $COLUMN_RETRY_COUNT >= ?",
            arrayOf(MAX_RETRY_COUNT.toString())
        )

        var count = 0
        cursor.use {
            if (it.moveToFirst()) {
                count = it.getInt(0)
            }
        }

        return count
    }


    /**
     * 모든 알림 삭제 (테스트/디버그용)
     */
    fun clearAll(): Int {
        val db = writableDatabase
        val count = db.delete(TABLE_NAME, null, null)
        Log.d(TAG, "Cleared all $count notifications")
        return count
    }
}
