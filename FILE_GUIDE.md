# 파일 역할 안내서

## lib/
- `main.dart` – 의존성 주입(리포지토리/프로바이더) 및 초기 라우팅을 담당하는 진입점입니다.
- `api/bigs_api_client.dart` – 공통 HTTP 클라이언트로 JSON 요청·응답과 멀티파트 업로드를 지원합니다.
- `api/auth_repository.dart` – 회원가입, 로그인, 토큰 리프레시 API를 호출합니다.
- `api/board_repository.dart` – 게시판 목록/상세/CRUD, 카테고리 조회, 파일 업로드를 처리합니다.
- `models/auth_session.dart` – JWT에서 추출한 세션 정보를 표현하고 저장/만료 로직을 제공합니다.
- `models/board_models.dart` – 게시글 요약/상세 및 폼 입력 모델 정의입니다.
- `models/paged_result.dart` – 페이지네이션 응답을 캡슐화한 제네릭 모델입니다.
- `providers/auth_provider.dart` – 로그인 상태, 토큰 자동 갱신, SharedPreferences 저장을 관리합니다.
- `providers/board_provider.dart` – 게시글 목록/상세 상태, 페이징, CRUD 흐름, 오류 메시지를 관리합니다.
- `screens/auth/auth_screen.dart` – 로그인/회원가입 UI와 검증을 제공합니다.
- `screens/board/board_list_screen.dart` – 게시판 메인 화면으로 목록, 상세 패널, 새 글 작성 버튼을 구성합니다.
- `screens/board/board_detail_screen.dart` – 모바일 친화적인 단일 게시글 상세 화면입니다.
- `screens/board/board_form_screen.dart` – 게시글 작성 및 수정 폼을 재사용 가능한 형태로 제공합니다.
- `screens/splash_screen.dart` – 세션 복원 중 표시되는 단순 로딩 화면입니다.
- `utils/jwt_utils.dart` – JWT 페이로드 디코딩을 담당합니다.
- `utils/image_compressor.dart` – 이미지 용량이 크면 리사이즈/재인코딩으로 압축합니다.
- `widgets/board_card.dart` – 게시글 요약용 카드 컴포넌트입니다.
- `widgets/loading_overlay.dart` – 로딩 스피너를 덮어씌우는 공용 오버레이 위젯입니다.

## test/
- `widget_test.dart` – 앱 초기 렌더링을 확인하는 스모크 테스트입니다.

## 플랫폼 디렉터리
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` – 각 플랫폼별 런너 설정과 프로젝트 파일입니다.

## 기타 문서
- `README.md` – 전체 실행 가이드 및 기능 요약입니다.
- `FILE_GUIDE.md` – 현재 문서로, 파일별 역할을 정리해 두었습니다.
