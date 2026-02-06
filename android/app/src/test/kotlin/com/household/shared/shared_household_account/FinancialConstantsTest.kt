package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test

/**
 * FinancialConstants 테스트
 * 금융 키워드 리스트의 구조와 일관성을 검증한다
 */
class FinancialConstantsTest {

    @Test
    fun `EXPENSE_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            "지출 키워드 리스트가 비어있지 않아야 한다",
            FinancialConstants.EXPENSE_KEYWORDS.isNotEmpty()
        )
    }

    @Test
    fun `EXPENSE_KEYWORDS - 주요 지출 키워드를 포함한다`() {
        val keywords = FinancialConstants.EXPENSE_KEYWORDS
        assertTrue("승인을 포함해야 한다", keywords.contains("승인"))
        assertTrue("결제를 포함해야 한다", keywords.contains("결제"))
        assertTrue("출금을 포함해야 한다", keywords.contains("출금"))
        assertTrue("이체를 포함해야 한다", keywords.contains("이체"))
    }

    @Test
    fun `INCOME_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            "수입 키워드 리스트가 비어있지 않아야 한다",
            FinancialConstants.INCOME_KEYWORDS.isNotEmpty()
        )
    }

    @Test
    fun `INCOME_KEYWORDS - 주요 수입 키워드를 포함한다`() {
        val keywords = FinancialConstants.INCOME_KEYWORDS
        assertTrue("입금을 포함해야 한다", keywords.contains("입금"))
        assertTrue("충전을 포함해야 한다", keywords.contains("충전"))
    }

    @Test
    fun `CANCEL_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            "취소 키워드 리스트가 비어있지 않아야 한다",
            FinancialConstants.CANCEL_KEYWORDS.isNotEmpty()
        )
    }

    @Test
    fun `CANCEL_KEYWORDS - 취소와 승인취소를 포함한다`() {
        val keywords = FinancialConstants.CANCEL_KEYWORDS
        assertTrue("취소를 포함해야 한다", keywords.contains("취소"))
        assertTrue("승인취소를 포함해야 한다", keywords.contains("승인취소"))
    }

    @Test
    fun `DEFAULT_TYPE_KEYWORDS - expense와 income 키를 포함한다`() {
        val typeKeywords = FinancialConstants.DEFAULT_TYPE_KEYWORDS
        assertTrue("expense 키가 있어야 한다", typeKeywords.containsKey("expense"))
        assertTrue("income 키가 있어야 한다", typeKeywords.containsKey("income"))
    }

    @Test
    fun `DEFAULT_TYPE_KEYWORDS - expense 리스트가 비어있지 않다`() {
        val expenseKeywords = FinancialConstants.DEFAULT_TYPE_KEYWORDS["expense"]
        assertNotNull("expense 키에 대한 리스트가 null이 아니어야 한다", expenseKeywords)
        assertTrue("expense 리스트가 비어있지 않아야 한다", expenseKeywords!!.isNotEmpty())
    }

    @Test
    fun `DEFAULT_TYPE_KEYWORDS - income 리스트가 비어있지 않다`() {
        val incomeKeywords = FinancialConstants.DEFAULT_TYPE_KEYWORDS["income"]
        assertNotNull("income 키에 대한 리스트가 null이 아니어야 한다", incomeKeywords)
        assertTrue("income 리스트가 비어있지 않아야 한다", incomeKeywords!!.isNotEmpty())
    }

    @Test
    fun `DEFAULT_TYPE_KEYWORDS - expense 키워드가 EXPENSE_KEYWORDS와 일관성이 있다`() {
        val defaultExpense = FinancialConstants.DEFAULT_TYPE_KEYWORDS["expense"]!!
        val expenseKeywords = FinancialConstants.EXPENSE_KEYWORDS

        // DEFAULT_TYPE_KEYWORDS의 expense는 EXPENSE_KEYWORDS의 부분집합이어야 함
        for (keyword in defaultExpense) {
            assertTrue(
                "DEFAULT_TYPE_KEYWORDS의 '$keyword'가 EXPENSE_KEYWORDS에도 있어야 한다",
                expenseKeywords.contains(keyword)
            )
        }
    }

    @Test
    fun `DEFAULT_TYPE_KEYWORDS - income 키워드가 INCOME_KEYWORDS와 일관성이 있다`() {
        val defaultIncome = FinancialConstants.DEFAULT_TYPE_KEYWORDS["income"]!!
        val incomeKeywords = FinancialConstants.INCOME_KEYWORDS

        // DEFAULT_TYPE_KEYWORDS의 income은 INCOME_KEYWORDS의 부분집합이어야 함
        for (keyword in defaultIncome) {
            assertTrue(
                "DEFAULT_TYPE_KEYWORDS의 '$keyword'가 INCOME_KEYWORDS에도 있어야 한다",
                incomeKeywords.contains(keyword)
            )
        }
    }

    @Test
    fun `EXPENSE_KEYWORDS와 INCOME_KEYWORDS가 겹치지 않는다`() {
        val overlap = FinancialConstants.EXPENSE_KEYWORDS.intersect(
            FinancialConstants.INCOME_KEYWORDS.toSet()
        )
        assertTrue(
            "지출과 수입 키워드가 겹치면 안 된다: $overlap",
            overlap.isEmpty()
        )
    }
}
