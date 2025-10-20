# BIGS Frontend Assignment

Flutter 기반으로 BIGS 게시판 API와 연동하는 인증/게시판 클라이언트입니다. 아래 안내대로 의존성을 설치하고 각 플랫폼에서 실행할 수 있습니다.

## 1. 사전 준비

- Flutter 3.9 이상 (Dart 3.9 포함)
- Xcode 15+ (iOS/macOS 테스트 시)
- Android Studio / SDK (Android 테스트 시)
- Chrome (웹 테스트 시)

`flutter --version`으로 환경을 확인하세요.

## 2. 의존성 설치

프로젝트 루트에서 한 번만 실행하면 됩니다.

```bash
flutter pub get
```

### iOS/Mac Catalyst

```bash
cd ios
pod install
cd ..
```

## 3. 실행 방법

### 웹 (Chrome)
```bash
flutter run -d chrome
```
> CORS 회피를 위해 `--disable-web-security`로 Chrome을 띄워야 할 수 있습니다.

### macOS 데스크톱
```bash
flutter run -d macos
```
macOS 권한 사용을 위해 `macos/Runner/*.entitlements`에 네트워크/파일 권한을 추가해 두었습니다.

### iOS (시뮬레이터/실기기)
```bash
flutter run -d ios
```
또는 `ios/Runner.xcworkspace`를 Xcode로 열어 빌드합니다.

### Android (에뮬레이터/실기기)
```bash
flutter run -d <android-device-id>
```
`flutter devices`로 연결된 기기를 확인할 수 있습니다.

## 4. 환경 설정

| 항목 | 설명 |
| --- | --- |
| API Base URL | `https://front-mission.bigs.or.kr` |
| Origin 헤더 | 자동으로 `https://front-mission.bigs.or.kr` 설정 |
| 이미지 업로드 | 2MB 초과 시 내부에서 리사이즈/재인코딩 |
| 토큰 갱신 | 만료 30초 전 자동 리프레시 |

## 5. 제공 계정

| 항목 | 값 |
| --- | --- |
| 아이디 | `developer@bigs.or.kr` |
| 비밀번호 | `123qwe!@#` |

## 6. 테스트 & 정적 분석

```bash
flutter analyze
flutter test
```

테스트는 위젯 초기 렌더링 smoke 테스트를 포함합니다. 필요 시 추가 테스트를 작성해 주세요.

## 7. 디렉터리 구조

```
lib/
  api/        API 클라이언트 및 레포지토리
  models/     데이터 모델
  providers/  Provider 상태 관리
  screens/    UI 화면 (Auth, Board 등)
  utils/      JWT 디코딩, 이미지 압축 유틸
  widgets/    재사용 가능한 컴포넌트
```

## 8. 자주 발생하는 문제

- `Generated.xcconfig not found`: `flutter pub get` → `pod install` 순으로 실행하세요.
- macOS에서 이미지 선택 불가: 샌드박스 권한 문제. 이미 entitlements에 사용자 선택 파일 읽기 권한을 포함했습니다.
- "요청 처리에 실패했습니다": 대부분 토큰 만료. 자동 리프레시 이후에도 실패하면 재로그인하세요.

## 9. 추가 개발/배포 메모

- API 오류 메시지를 SnackBar로 그대로 출력하여 디버깅이 쉽습니다.
- Provider 구조를 사용하므로 필요 시 ChangeNotifierProxyProvider로 손쉽게 확장 가능합니다.
- 빌드 산출물(`build/`)은 포함하지 않고 있습니다.

필요한 추가 문의가 있으면 언제든 말씀 주세요!
