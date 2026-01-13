# STATISTICS FEATURE

## OVERVIEW
통계/차트 기능 - 카테고리별, 결제수단별, 월/연 추이 분석

## STRUCTURE
```
statistics/
├── domain/entities/          # 통계 데이터 엔티티
├── data/repositories/        # 통계 계산 로직 (597줄)
└── presentation/
    ├── pages/                # 탭 기반 통계 페이지
    ├── providers/            # 복잡한 FutureProvider 체인
    └── widgets/
        ├── category_tab/     # 카테고리 통계 (도넛 차트 + 순위)
        ├── payment_method_tab/ # 결제수단 통계
        ├── trend_tab/        # 월/연 추이 (막대 차트)
        └── common/           # 공유 필터 위젯
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 통계 계산 로직 | `data/repositories/statistics_repository.dart` | 그룹화, 집계 쿼리 |
| 도넛 차트 | `presentation/widgets/category_tab/category_donut_chart.dart` | fl_chart 기반 |
| 막대 차트 | `presentation/widgets/trend_tab/trend_bar_chart.dart` | 527줄, 월/연 전환 |
| 필터 위젯 | `presentation/widgets/common/` | 타입/기간/날짜 필터 |
| Provider 체인 | `presentation/providers/statistics_provider.dart` | 6개 FutureProvider |

## CONVENTIONS
- **탭 구조**: 페이지 → 탭 뷰 → 필터 + 차트 + 리스트
- **상태 감시**: selectedLedgerIdProvider, statisticsSelectedDateProvider 감시
- **자동 재조회**: 필터 변경 시 FutureProvider 자동 갱신
- **고정비 필터**: ExpenseTypeFilter.fixedOnly, ExpenseTypeFilter.variableOnly

## NOTES
- trend_bar_chart.dart 527줄 - 리팩토링 고려
- 통계 데이터 캐싱 없음 (매번 재계산)
- 월/연 전환 시 애니메이션 없음
