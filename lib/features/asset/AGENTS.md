# ASSET FEATURE

## OVERVIEW
자산 관리 - 정기예금, 적금, 주식, 펀드, 부동산, 암호화폐, 목표 설정

## STRUCTURE
```
asset/
├── domain/entities/          # 자산 엔티티
├── data/
│   ├── models/              # 자산 모델
│   └── repositories/        # 자산 CRUD (398줄)
└── presentation/
    ├── pages/               # 자산 페이지 (796줄)
    └── widgets/             # 자산 카드, 목표 폼 (569줄, 359줄)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 자산 타입 | `core/constants/asset_constants.dart` | 아이콘, 색상 맵 |
| 목표 설정 | `presentation/widgets/asset_goal_form_sheet.dart` | 목표 금액, 달성률 |
| 자산 카드 | `presentation/widgets/asset_goal_card.dart` | 569줄 |
| Repository | `data/repositories/asset_repository.dart` | 만기일 계산 |

## CONVENTIONS
- **자산 타입**: DEPOSIT, SAVING, STOCK, FUND, REAL_ESTATE, CRYPTO
- **transactions.is_asset**: true로 표시
- **maturity_date**: 만기일 저장 (정기예금, 적금)

## NOTES
- asset_page.dart 796줄 - 리팩토링 고려
- 015 마이그레이션에서 saving → asset 통합
- 목표 달성률 UI는 LinearProgressIndicator 사용
