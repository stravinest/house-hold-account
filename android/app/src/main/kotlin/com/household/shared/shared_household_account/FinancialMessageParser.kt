package com.household.shared.shared_household_account

import android.util.Log
import java.security.MessageDigest
import java.util.regex.Pattern

/**
 * 금융 SMS/Push 메시지 파싱 서비스
 * Flutter의 SmsParsingService를 Kotlin으로 포팅
 */
object FinancialMessageParser {

    private const val TAG = "FinancialParser"

    // 금액 패턴 (콤마 포함, 원 단위)
    private val AMOUNT_PATTERN = Pattern.compile("([0-9,]+)\\s*원")

    // 카드 끝자리 패턴
    private val CARD_DIGITS_PATTERN = Pattern.compile("(\\d{4})\\s*[카승]")

    // 날짜 패턴들
    private val DATE_PATTERNS = listOf(
        Pattern.compile("(\\d{1,2})/(\\d{1,2})\\s+(\\d{1,2}):(\\d{2})"),  // MM/DD HH:MM
        Pattern.compile("(\\d{1,2})-(\\d{1,2})\\s+(\\d{1,2}):(\\d{2})"),  // MM-DD HH:MM
        Pattern.compile("(\\d{4})\\.(\\d{1,2})\\.(\\d{1,2})\\s+(\\d{1,2}):(\\d{2})"),  // YYYY.MM.DD HH:MM
        Pattern.compile("(\\d{1,2})월\\s*(\\d{1,2})일\\s*(\\d{1,2})시\\s*(\\d{2})분")  // MM월DD일 HH시MM분
    )

    private val EXPENSE_KEYWORDS = FinancialConstants.EXPENSE_KEYWORDS
    private val INCOME_KEYWORDS = FinancialConstants.INCOME_KEYWORDS
    private val CANCEL_KEYWORDS = FinancialConstants.CANCEL_KEYWORDS

    /**
     * 파싱 결과 데이터 클래스
     */
    data class ParsedResult(
        val amount: Int?,
        val transactionType: String?,  // "expense" or "income"
        val merchant: String?,
        val dateTimeMillis: Long?,
        val cardLastDigits: String?,
        val confidence: Double,
        val matchedPattern: String?
    ) {
        val isParsed: Boolean
            get() = amount != null && transactionType != null
    }

    /**
     * 학습된 포맷을 사용하여 메시지 파싱
     */
    fun parseWithFormat(
        content: String,
        format: LearnedPushFormat
    ): ParsedResult {
        return parseWithFormatInternal(
            content = content,
            amountRegex = format.amountRegex,
            typeKeywords = format.typeKeywords,
            merchantRegex = format.merchantRegex,
            dateRegex = format.dateRegex,
            formatConfidence = 0.8,
            matchedPattern = format.packageName
        )
    }

    /**
     * 학습된 SMS 포맷을 사용하여 메시지 파싱
     */
    fun parseWithSmsFormat(
        content: String,
        format: LearnedSmsFormat
    ): ParsedResult {
        return parseWithFormatInternal(
            content = content,
            amountRegex = format.amountRegex,
            typeKeywords = format.typeKeywords,
            merchantRegex = format.merchantRegex,
            dateRegex = format.dateRegex,
            formatConfidence = 0.8,
            matchedPattern = format.senderPattern
        )
    }

    private fun parseWithFormatInternal(
        content: String,
        amountRegex: String,
        typeKeywords: Map<String, List<String>>,
        merchantRegex: String?,
        dateRegex: String?,
        formatConfidence: Double,
        matchedPattern: String?
    ): ParsedResult {
        // 취소 메시지 체크
        if (isCancelMessage(content)) {
            return ParsedResult(null, null, null, null, null, 0.0, "cancel")
        }

        // 금액 추출
        val amount = try {
            val pattern = Pattern.compile(amountRegex)
            val matcher = pattern.matcher(content)
            if (matcher.find()) {
                matcher.group(1)?.replace(",", "")?.toIntOrNull()
            } else {
                parseAmount(content)  // fallback
            }
        } catch (e: Exception) {
            parseAmount(content)  // fallback on invalid regex
        }

        // 거래 타입 결정
        var transactionType: String? = null
        for (keyword in typeKeywords["expense"] ?: emptyList()) {
            if (content.contains(keyword)) {
                transactionType = "expense"
                break
            }
        }
        if (transactionType == null) {
            for (keyword in typeKeywords["income"] ?: emptyList()) {
                if (content.contains(keyword)) {
                    transactionType = "income"
                    break
                }
            }
        }

        // 상호명 추출
        val merchant = if (merchantRegex != null) {
            try {
                val pattern = Pattern.compile(merchantRegex)
                val matcher = pattern.matcher(content)
                if (matcher.find()) matcher.group(1)?.trim() else parseMerchant(content)
            } catch (e: Exception) {
                parseMerchant(content)
            }
        } else {
            parseMerchant(content)
        }

        // 날짜 추출
        val dateTimeMillis = if (dateRegex != null) {
            try {
                val pattern = Pattern.compile(dateRegex)
                val matcher = pattern.matcher(content)
                if (matcher.find()) parseDateFromMatcher(matcher) else parseDate(content)
            } catch (e: Exception) {
                parseDate(content)
            }
        } else {
            parseDate(content)
        }

        val confidence = calculateConfidence(amount, transactionType, merchant, dateTimeMillis) * formatConfidence

        return ParsedResult(
            amount = amount,
            transactionType = transactionType,
            merchant = merchant,
            dateTimeMillis = dateTimeMillis,
            cardLastDigits = parseCardDigits(content),
            confidence = confidence,
            matchedPattern = matchedPattern
        )
    }

    /**
     * 기본 파싱 (학습된 포맷 없이)
     */
    fun parse(sender: String, content: String): ParsedResult {
        if (isCancelMessage(content)) {
            return ParsedResult(null, null, null, null, null, 0.0, "cancel")
        }

        val amount = parseAmount(content)
        if (amount == null) {
            return ParsedResult(null, null, null, null, null, 0.0, null)
        }

        val transactionType = parseTransactionType(content)
        val merchant = parseMerchant(content)
        val dateTimeMillis = parseDate(content)
        val cardDigits = parseCardDigits(content)
        val confidence = calculateConfidence(amount, transactionType, merchant, dateTimeMillis)

        return ParsedResult(
            amount = amount,
            transactionType = transactionType,
            merchant = merchant,
            dateTimeMillis = dateTimeMillis,
            cardLastDigits = cardDigits,
            confidence = confidence,
            matchedPattern = null
        )
    }

    private fun isCancelMessage(content: String): Boolean {
        return CANCEL_KEYWORDS.any { content.contains(it) }
    }

    private fun parseAmount(content: String): Int? {
        val matcher = AMOUNT_PATTERN.matcher(content)
        return if (matcher.find()) {
            matcher.group(1)?.replace(",", "")?.toIntOrNull()
        } else null
    }

    private fun parseTransactionType(content: String): String? {
        // 수입 먼저 체크
        for (keyword in INCOME_KEYWORDS) {
            if (content.contains(keyword)) return "income"
        }
        // 지출 체크
        for (keyword in EXPENSE_KEYWORDS) {
            if (content.contains(keyword)) return "expense"
        }
        return null
    }

    private fun parseMerchant(content: String): String? {
        val patterns = listOf(
            Pattern.compile("원\\s+(?:일시불|할부)?\\s*(.+)$"),
            Pattern.compile("승인\\s+(.+)$"),
            Pattern.compile("^[\\w가-힣]+\\s+(.+?)\\s+[\\d,]+원")
        )

        for (pattern in patterns) {
            val matcher = pattern.matcher(content)
            if (matcher.find()) {
                val merchant = cleanMerchant(matcher.group(1)?.trim())
                if (!merchant.isNullOrEmpty()) return merchant
            }
        }
        return null
    }

    private fun cleanMerchant(merchant: String?): String? {
        if (merchant == null) return null
        var cleaned = merchant
            .replace(Regex("\\(누적.*\\)"), "")
            .replace(Regex("잔액.*$"), "")
            .replace(Regex("누적.*$"), "")
            .trim()

        if (cleaned.length < 2 || cleaned.matches(Regex("^[\\d\\s]+$"))) {
            return null
        }
        return cleaned
    }

    private fun parseCardDigits(content: String): String? {
        val matcher = CARD_DIGITS_PATTERN.matcher(content)
        return if (matcher.find()) matcher.group(1) else null
    }

    private fun parseDate(content: String): Long? {
        for (pattern in DATE_PATTERNS) {
            val matcher = pattern.matcher(content)
            if (matcher.find()) {
                return parseDateFromMatcher(matcher)
            }
        }
        return null
    }

    private fun parseDateFromMatcher(matcher: java.util.regex.Matcher): Long? {
        return try {
            val now = java.util.Calendar.getInstance()
            val year: Int
            val month: Int
            val day: Int
            val hour: Int
            val minute: Int

            if (matcher.groupCount() >= 5 && matcher.group(5) != null) {
                // YYYY.MM.DD HH:MM
                year = matcher.group(1)?.toIntOrNull() ?: now.get(java.util.Calendar.YEAR)
                month = (matcher.group(2)?.toIntOrNull() ?: 1) - 1
                day = matcher.group(3)?.toIntOrNull() ?: 1
                hour = matcher.group(4)?.toIntOrNull() ?: 0
                minute = matcher.group(5)?.toIntOrNull() ?: 0
            } else {
                // MM/DD HH:MM
                year = now.get(java.util.Calendar.YEAR)
                month = (matcher.group(1)?.toIntOrNull() ?: 1) - 1
                day = matcher.group(2)?.toIntOrNull() ?: 1
                hour = matcher.group(3)?.toIntOrNull() ?: 0
                minute = matcher.group(4)?.toIntOrNull() ?: 0
            }

            val calendar = java.util.Calendar.getInstance().apply {
                set(year, month, day, hour, minute, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            calendar.timeInMillis
        } catch (e: Exception) {
            null
        }
    }

    private fun calculateConfidence(
        amount: Int?,
        transactionType: String?,
        merchant: String?,
        dateTimeMillis: Long?
    ): Double {
        var score = 0.0
        if (amount != null && amount > 0) score += 0.4
        if (transactionType != null) score += 0.3
        if (!merchant.isNullOrEmpty()) score += 0.2
        if (dateTimeMillis != null) score += 0.1
        return score
    }

    /**
     * 중복 해시 생성 (3분 버킷)
     */
    fun generateDuplicateHash(amount: Int, paymentMethodId: String?, timestamp: Long): String {
        val bucket = timestamp / (3 * 60 * 1000)
        val input = "$amount-${paymentMethodId ?: "unknown"}-$bucket"
        return try {
            val md = MessageDigest.getInstance("MD5")
            val digest = md.digest(input.toByteArray())
            digest.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            input  // fallback to plain string
        }
    }
}
