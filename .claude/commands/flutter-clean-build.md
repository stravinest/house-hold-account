---
description: Flutter 클린 빌드 실행 - 의존성 재설치 및 코드 생성
---

# Flutter Clean Build

Flutter 프로젝트를 완전히 정리하고 재빌드합니다.

## 실행 순서

1. 빌드 캐시 정리
2. 의존성 재설치
3. 코드 생성 (Riverpod)
4. 린트 검사

## 명령어

```bash
# 1. 빌드 캐시 정리
flutter clean

# 2. 의존성 설치
flutter pub get

# 3. 코드 생성 (Riverpod 등)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 린트 검사
flutter analyze
```

## 사용 시점

- 의존성 추가/변경 후
- 빌드 에러 발생 시
- 코드 생성 파일 업데이트 필요 시
- 린트 에러 확인 시

## 예상 소요 시간

약 1-2분
