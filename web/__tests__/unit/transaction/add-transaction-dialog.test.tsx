import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Supabase 클라이언트 mock
const mockFrom = vi.fn();
const mockSelect = vi.fn();
const mockEq = vi.fn();
const mockOrder = vi.fn();

vi.mock('@/lib/supabase/client', () => ({
  createClient: () => ({
    from: mockFrom,
  }),
}));

vi.mock('@/lib/actions/transaction', () => ({
  addTransaction: vi.fn().mockResolvedValue({ success: true }),
}));

// next/navigation mock
vi.mock('next/navigation', () => ({
  useRouter: () => ({ refresh: vi.fn() }),
}));

import { AddTransactionDialog } from '@/components/transaction/AddTransactionDialog';
import { addTransaction } from '@/lib/actions/transaction';

const MOCK_CATEGORIES = [
  { id: 'cat-1', name: '식비', type: 'expense', icon: 'restaurant' },
  { id: 'cat-2', name: '교통', type: 'expense', icon: 'directions_bus' },
  { id: 'cat-3', name: '급여', type: 'income', icon: 'attach_money' },
  { id: 'cat-4', name: '정기예금', type: 'asset', icon: 'savings' },
];

const MOCK_PAYMENT_METHODS = [
  { id: 'pm-1', name: 'KB국민카드' },
  { id: 'pm-2', name: '현금' },
];

const MOCK_FIXED_EXPENSE_CATEGORIES = [
  { id: 'fec-1', name: '월세', icon: 'house' },
  { id: 'fec-2', name: '관리비', icon: 'domain' },
  { id: 'fec-3', name: '보험료', icon: 'shield' },
  { id: 'fec-4', name: '통신비', icon: 'cell_tower' },
  { id: 'fec-5', name: '구독료', icon: 'subscriptions' },
];

function setupSupabaseMock() {
  mockOrder.mockImplementation(() => Promise.resolve({ data: [] }));

  mockEq.mockImplementation(() => ({
    order: (col: string) => {
      if (col === 'sort_order') {
        // categories 또는 fixed_expense_categories
        return Promise.resolve({ data: MOCK_CATEGORIES });
      }
      if (col === 'created_at') {
        return Promise.resolve({ data: MOCK_PAYMENT_METHODS });
      }
      return Promise.resolve({ data: [] });
    },
  }));

  mockSelect.mockImplementation(() => ({
    eq: mockEq,
  }));

  // 각 테이블에 맞는 데이터 반환
  mockFrom.mockImplementation((table: string) => ({
    select: () => ({
      eq: () => ({
        order: () => {
          if (table === 'categories') {
            return Promise.resolve({ data: MOCK_CATEGORIES });
          }
          if (table === 'payment_methods') {
            return Promise.resolve({ data: MOCK_PAYMENT_METHODS });
          }
          if (table === 'fixed_expense_categories') {
            return Promise.resolve({ data: MOCK_FIXED_EXPENSE_CATEGORIES });
          }
          return Promise.resolve({ data: [] });
        },
      }),
    }),
  }));
}

function renderDialog(props = {}) {
  return render(
    <AddTransactionDialog
      open={true}
      onClose={vi.fn()}
      ledgerId='ledger-1'
      onSuccess={vi.fn()}
      {...props}
    />
  );
}

describe('AddTransactionDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupSupabaseMock();
  });

  describe('기본 렌더링', () => {
    it('모달이 열리면 거래 추가 제목이 표시되어야 한다', async () => {
      renderDialog();
      expect(screen.getByText('거래 추가')).toBeInTheDocument();
    });

    it('지출/수입/자산 탭이 모두 표시되어야 한다', async () => {
      renderDialog();
      expect(screen.getByText('지출')).toBeInTheDocument();
      expect(screen.getByText('수입')).toBeInTheDocument();
      expect(screen.getByText('자산')).toBeInTheDocument();
    });

    it('기본 탭은 지출이어야 한다', async () => {
      renderDialog();
      // 지출 탭이 활성화 상태 (bg-white 클래스)
      const expenseTab = screen.getByText('지출');
      expect(expenseTab).toHaveClass('bg-white');
    });

    it('금액, 제목, 날짜, 메모 입력 필드가 있어야 한다', async () => {
      renderDialog();
      expect(screen.getByPlaceholderText('0')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('거래 내용을 입력하세요')).toBeInTheDocument();
      expect(screen.getByText('날짜')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('메모를 입력하세요 (선택)')).toBeInTheDocument();
    });

    it('저장, 취소 버튼이 있어야 한다', async () => {
      renderDialog();
      expect(screen.getByText('저장')).toBeInTheDocument();
      expect(screen.getByText('취소')).toBeInTheDocument();
    });

    it('open=false이면 렌더링하지 않아야 한다', () => {
      render(
        <AddTransactionDialog
          open={false}
          onClose={vi.fn()}
          ledgerId='ledger-1'
          onSuccess={vi.fn()}
        />
      );
      expect(screen.queryByText('거래 추가')).not.toBeInTheDocument();
    });
  });

  describe('거래 타입 전환', () => {
    it('수입 탭 클릭 시 수입 카테고리만 표시되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      fireEvent.click(screen.getByText('수입'));

      await waitFor(() => {
        expect(screen.getByText('급여')).toBeInTheDocument();
        expect(screen.queryByText('식비')).not.toBeInTheDocument();
        expect(screen.queryByText('교통')).not.toBeInTheDocument();
      });
    });

    it('자산 탭 클릭 시 자산 카테고리만 표시되어야 한다', async () => {
      renderDialog();
      fireEvent.click(screen.getByText('자산'));

      await waitFor(() => {
        expect(screen.getByText('정기예금')).toBeInTheDocument();
        expect(screen.queryByText('식비')).not.toBeInTheDocument();
      });
    });

    it('수입/자산 탭에서는 고정비, 반복 체크박스가 표시되지 않아야 한다', async () => {
      renderDialog();
      // 지출에서는 보임
      expect(screen.getByText('고정비')).toBeInTheDocument();

      fireEvent.click(screen.getByText('수입'));
      expect(screen.queryByText('고정비')).not.toBeInTheDocument();

      fireEvent.click(screen.getByText('자산'));
      expect(screen.queryByText('고정비')).not.toBeInTheDocument();
    });

    it('수입/자산 탭에서는 결제수단이 표시되지 않아야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('KB국민카드')).toBeInTheDocument();
      });

      fireEvent.click(screen.getByText('수입'));
      expect(screen.queryByText('KB국민카드')).not.toBeInTheDocument();

      fireEvent.click(screen.getByText('자산'));
      expect(screen.queryByText('KB국민카드')).not.toBeInTheDocument();
    });

    it('자산 탭에서는 만기일 입력이 표시되어야 한다', async () => {
      renderDialog();
      expect(screen.queryByText('만기일 (선택)')).not.toBeInTheDocument();

      fireEvent.click(screen.getByText('자산'));
      expect(screen.getByText('만기일 (선택)')).toBeInTheDocument();
    });

    it('타입 전환 시 선택된 카테고리가 초기화되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });
      fireEvent.click(screen.getByText('식비'));

      // 수입으로 전환
      fireEvent.click(screen.getByText('수입'));
      // 다시 지출로 돌아오면 식비가 선택 해제 상태여야 함
      fireEvent.click(screen.getByText('지출'));

      await waitFor(() => {
        const catButton = screen.getByText('식비').closest('button');
        expect(catButton).not.toHaveClass('border-primary');
      });
    });
  });

  describe('카테고리 아이콘 렌더링', () => {
    it('Material Icons 아이콘이 올바른 클래스와 함께 렌더링되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      // material-icons-outlined 클래스가 적용된 span 확인
      const iconElements = document.querySelectorAll('.material-icons-outlined');
      expect(iconElements.length).toBeGreaterThan(0);
    });

    it('아이콘 값이 텍스트가 아닌 아이콘 폰트로 렌더링되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      // 'restaurant'가 material-icons-outlined span 안에 있어야 함
      const restaurantIcon = screen.getByText('restaurant');
      expect(restaurantIcon).toHaveClass('material-icons-outlined');
    });

    it('아이콘이 null인 카테고리는 첫 글자가 표시되어야 한다', async () => {
      mockFrom.mockImplementation((table: string) => ({
        select: () => ({
          eq: () => ({
            order: () => {
              if (table === 'categories') {
                return Promise.resolve({
                  data: [{ id: 'no-icon', name: '테스트', type: 'expense', icon: null }],
                });
              }
              if (table === 'payment_methods') return Promise.resolve({ data: [] });
              if (table === 'fixed_expense_categories') return Promise.resolve({ data: [] });
              return Promise.resolve({ data: [] });
            },
          }),
        }),
      }));

      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('테스트')).toBeInTheDocument();
      });

      // '테' 글자가 표시되어야 함
      const firstChar = screen.getByText('테', { selector: 'span.text-xs' });
      expect(firstChar).toBeInTheDocument();
    });
  });

  describe('고정비 기능', () => {
    it('고정비 체크 시 고정비 카테고리가 표시되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      // 고정비 카테고리는 초기에 표시되지 않음
      expect(screen.queryByText('월세')).not.toBeInTheDocument();

      // 고정비 체크
      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        expect(screen.getByText('고정비 카테고리')).toBeInTheDocument();
        expect(screen.getByText('월세')).toBeInTheDocument();
        expect(screen.getByText('관리비')).toBeInTheDocument();
        expect(screen.getByText('보험료')).toBeInTheDocument();
        expect(screen.getByText('통신비')).toBeInTheDocument();
        expect(screen.getByText('구독료')).toBeInTheDocument();
      });
    });

    it('고정비 체크 시 일반 카테고리(식비, 교통 등)가 숨겨져야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
        expect(screen.getByText('교통')).toBeInTheDocument();
      });

      // 고정비 체크
      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        expect(screen.queryByText('식비')).not.toBeInTheDocument();
        expect(screen.queryByText('교통')).not.toBeInTheDocument();
      });
    });

    it('고정비 체크 해제 시 일반 카테고리가 다시 표시되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;

      // 체크 → 해제
      fireEvent.click(fixedCheckbox);
      await waitFor(() => {
        expect(screen.queryByText('식비')).not.toBeInTheDocument();
      });

      fireEvent.click(fixedCheckbox);
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
        expect(screen.queryByText('월세')).not.toBeInTheDocument();
      });
    });

    it('고정비 체크 시 반복이 자동으로 활성화되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        // 반복 체크박스가 체크되어 있어야 함
        const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
        expect(recurringCheckbox).toBeChecked();
      });
    });

    it('고정비 선택 상태에서 반복 체크박스가 비활성화(disabled)되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      expect(recurringCheckbox).toBeDisabled();
    });

    it('고정비 체크 시 반복 주기가 매월로 자동 설정되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        // 반복 설정 UI가 표시되고, 매월이 활성화 상태
        const monthlyButton = screen.getByText('매월');
        expect(monthlyButton).toHaveClass('bg-primary');
      });
    });

    it('고정비 카테고리를 선택/해제할 수 있어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        expect(screen.getByText('월세')).toBeInTheDocument();
      });

      // 월세 선택
      fireEvent.click(screen.getByText('월세').closest('button')!);
      expect(screen.getByText('월세').closest('button')).toHaveClass('border-primary');

      // 월세 해제
      fireEvent.click(screen.getByText('월세').closest('button')!);
      expect(screen.getByText('월세').closest('button')).not.toHaveClass('border-primary');
    });
  });

  describe('반복 설정', () => {
    it('반복 체크 시 반복 주기 선택 UI가 표시되어야 한다', async () => {
      renderDialog();
      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      fireEvent.click(recurringCheckbox);

      expect(screen.getByText('반복 주기')).toBeInTheDocument();
      expect(screen.getByText('매일')).toBeInTheDocument();
      expect(screen.getByText('매월')).toBeInTheDocument();
      expect(screen.getByText('매년')).toBeInTheDocument();
    });

    it('반복 주기를 매일/매월/매년으로 전환할 수 있어야 한다', async () => {
      renderDialog();
      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      fireEvent.click(recurringCheckbox);

      // 기본값은 매월
      expect(screen.getByText('매월')).toHaveClass('bg-primary');

      // 매일로 변경
      fireEvent.click(screen.getByText('매일'));
      expect(screen.getByText('매일')).toHaveClass('bg-primary');
      expect(screen.getByText('매월')).not.toHaveClass('bg-primary');

      // 매년으로 변경
      fireEvent.click(screen.getByText('매년'));
      expect(screen.getByText('매년')).toHaveClass('bg-primary');
    });

    it('반복 해제 시 반복 주기 UI가 사라져야 한다', async () => {
      renderDialog();
      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      fireEvent.click(recurringCheckbox);
      expect(screen.getByText('반복 주기')).toBeInTheDocument();

      fireEvent.click(recurringCheckbox);
      expect(screen.queryByText('반복 주기')).not.toBeInTheDocument();
    });

    it('종료일 입력 필드가 표시되어야 한다', async () => {
      renderDialog();
      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      fireEvent.click(recurringCheckbox);

      expect(screen.getByText('종료일 (선택, 미입력 시 무기한)')).toBeInTheDocument();
    });
  });

  describe('유효성 검사', () => {
    it('금액 미입력 시 에러 메시지가 표시되어야 한다', async () => {
      renderDialog();
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '테스트' } });

      fireEvent.click(screen.getByText('저장'));
      expect(screen.getByText('금액을 입력해주세요.')).toBeInTheDocument();
    });

    it('제목 미입력 시 에러 메시지가 표시되어야 한다', async () => {
      renderDialog();
      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '10000' } });

      fireEvent.click(screen.getByText('저장'));
      expect(screen.getByText('제목을 입력해주세요.')).toBeInTheDocument();
    });

    it('금액이 0 이하이면 에러 메시지가 표시되어야 한다', async () => {
      renderDialog();
      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '0' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '테스트' } });

      fireEvent.click(screen.getByText('저장'));
      expect(screen.getByText('금액을 입력해주세요.')).toBeInTheDocument();
    });
  });

  describe('폼 제출 - 서버 액션 호출 검증', () => {
    it('기본 지출 거래가 올바른 FormData로 전송되어야 한다', async () => {
      const onSuccess = vi.fn();
      render(
        <AddTransactionDialog
          open={true}
          onClose={vi.fn()}
          ledgerId='ledger-1'
          onSuccess={onSuccess}
        />
      );

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '15000' } });

      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '점심 식사' } });

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        expect(addTransaction).toHaveBeenCalledTimes(1);
        const formData = (addTransaction as any).mock.calls[0][0] as FormData;
        expect(formData.get('type')).toBe('expense');
        expect(formData.get('amount')).toBe('15000');
        expect(formData.get('description')).toBe('점심 식사');
        expect(formData.get('ledger_id')).toBe('ledger-1');
      });
    });

    it('고정비 거래 시 is_fixed_expense와 관련 데이터가 전송되어야 한다', async () => {
      renderDialog();

      await waitFor(() => {
        expect(screen.getByText('식비')).toBeInTheDocument();
      });

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '500000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '월세' } });

      // 고정비 체크
      const fixedCheckbox = screen.getByText('고정비').closest('label')!.querySelector('input')!;
      fireEvent.click(fixedCheckbox);

      await waitFor(() => {
        expect(screen.getByText('월세')).toBeInTheDocument();
      });

      // 고정비 카테고리 선택
      fireEvent.click(screen.getByText('월세').closest('button')!);

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        const formData = (addTransaction as any).mock.calls[0][0] as FormData;
        expect(formData.get('is_fixed_expense')).toBe('true');
        expect(formData.get('is_recurring')).toBe('true');
        expect(formData.get('recurring_type')).toBe('monthly');
        expect(formData.get('fixed_expense_category_id')).toBe('fec-1');
      });
    });

    it('반복 거래 시 recurring_type이 전송되어야 한다', async () => {
      renderDialog();

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '3000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '버스비' } });

      // 반복 체크
      const recurringCheckbox = screen.getByText('반복').closest('label')!.querySelector('input')!;
      fireEvent.click(recurringCheckbox);

      // 매일로 변경
      fireEvent.click(screen.getByText('매일'));

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        const formData = (addTransaction as any).mock.calls[0][0] as FormData;
        expect(formData.get('is_recurring')).toBe('true');
        expect(formData.get('recurring_type')).toBe('daily');
      });
    });

    it('자산 거래 시 is_asset과 maturity_date가 전송되어야 한다', async () => {
      renderDialog();

      // 자산 탭 선택
      fireEvent.click(screen.getByText('자산'));

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '5000000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '정기예금' } });

      // 만기일 입력
      const maturityInput = screen.getByText('만기일 (선택)').closest('div')!.querySelector('input')!;
      fireEvent.change(maturityInput, { target: { value: '2027-02-14' } });

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        const formData = (addTransaction as any).mock.calls[0][0] as FormData;
        expect(formData.get('type')).toBe('asset');
        expect(formData.get('is_asset')).toBe('true');
        expect(formData.get('maturity_date')).toBe('2027-02-14');
      });
    });

    it('수입 거래 시 결제수단과 고정비 관련 데이터가 전송되지 않아야 한다', async () => {
      renderDialog();

      fireEvent.click(screen.getByText('수입'));

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '3200000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '급여' } });

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        const formData = (addTransaction as any).mock.calls[0][0] as FormData;
        expect(formData.get('type')).toBe('income');
        expect(formData.get('payment_method_id')).toBeNull();
        expect(formData.get('is_fixed_expense')).toBeNull();
        expect(formData.get('is_recurring')).toBeNull();
      });
    });
  });

  describe('모달 동작', () => {
    it('취소 버튼 클릭 시 onClose가 호출되어야 한다', () => {
      const onClose = vi.fn();
      render(
        <AddTransactionDialog
          open={true}
          onClose={onClose}
          ledgerId='ledger-1'
          onSuccess={vi.fn()}
        />
      );
      fireEvent.click(screen.getByText('취소'));
      expect(onClose).toHaveBeenCalled();
    });

    it('오버레이 클릭 시 onClose가 호출되어야 한다', () => {
      const onClose = vi.fn();
      render(
        <AddTransactionDialog
          open={true}
          onClose={onClose}
          ledgerId='ledger-1'
          onSuccess={vi.fn()}
        />
      );
      // 오버레이는 fixed bg-black/50
      const overlay = document.querySelector('.bg-black\\/50');
      if (overlay) fireEvent.click(overlay);
      expect(onClose).toHaveBeenCalled();
    });

    it('저장 성공 시 onSuccess가 호출되어야 한다', async () => {
      const onSuccess = vi.fn();
      render(
        <AddTransactionDialog
          open={true}
          onClose={vi.fn()}
          ledgerId='ledger-1'
          onSuccess={onSuccess}
        />
      );

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '10000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '테스트' } });

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        expect(onSuccess).toHaveBeenCalled();
      });
    });

    it('서버 에러 시 에러 메시지가 표시되어야 한다', async () => {
      (addTransaction as any).mockResolvedValueOnce({ error: '서버 에러가 발생했습니다.' });

      renderDialog();

      const amountInput = screen.getByPlaceholderText('0');
      fireEvent.change(amountInput, { target: { value: '10000' } });
      const descInput = screen.getByPlaceholderText('거래 내용을 입력하세요');
      fireEvent.change(descInput, { target: { value: '테스트' } });

      fireEvent.click(screen.getByText('저장'));

      await waitFor(() => {
        expect(screen.getByText('서버 에러가 발생했습니다.')).toBeInTheDocument();
      });
    });
  });
});
