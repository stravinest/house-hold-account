# NOTIFICATION FEATURE

## OVERVIEW
푸시 알림 (FCM) 및 로컬 알림 시스템

## STRUCTURE
```
notification/
├── domain/entities/          # 알림 엔티티 (3개)
├── data/
│   ├── models/              # FCM 토큰, 알림 설정 모델
│   └── repositories/        # Supabase fcm_tokens 테이블 접근
├── services/                # Firebase 통합 서비스
└── presentation/
    ├── pages/               # 알림 설정 페이지
    └── providers/           # 6개 Provider (.g.dart 포함)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| FCM 초기화 | `services/fcm_service.dart` | Firebase Messaging 설정 |
| 토큰 관리 | `data/repositories/fcm_token_repository.dart` | 등록/삭제 |
| 알림 설정 | `presentation/pages/notification_settings_page.dart` | UI |
| Provider | `presentation/providers/notification_provider.dart` | StateNotifierProvider |

## CONVENTIONS
- **토큰 저장**: fcm_tokens 테이블 (user_id, token, platform, created_at)
- **알림 타입**: 거래 추가, 초대 수락, 가계부 공유
- **권한 요청**: 앱 시작 시 자동 (iOS 필수)

## NOTES
- Firebase 설정은 `.env`에서 선택적 활성화
- 로컬 알림은 flutter_local_notifications 사용
- 토큰 갱신 로직은 main.dart에서 처리
