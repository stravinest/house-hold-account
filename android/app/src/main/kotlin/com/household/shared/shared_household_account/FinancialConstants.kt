package com.household.shared.shared_household_account

object FinancialConstants {
    
    val EXPENSE_KEYWORDS = listOf(
        "승인", "결제", "사용", "출금", "이체", "지급", "체크", "일시불", "할부"
    )
    
    val INCOME_KEYWORDS = listOf(
        "입금", "받으셨습니다", "지급되었습니다", "충전", "환급", "환불"
    )
    
    val CANCEL_KEYWORDS = listOf(
        "취소", "승인취소", "결제취소"
    )
    
    val DEFAULT_TYPE_KEYWORDS = mapOf(
        "expense" to listOf("출금", "결제", "승인", "이체", "사용", "지급", "체크", "일시불", "할부"),
        "income" to listOf("입금", "충전", "환불", "환급")
    )
}
