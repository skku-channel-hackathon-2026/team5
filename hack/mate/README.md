# mate (Flutter · 안드로이드 / 아이폰 / 웹)

새내기의 하루를 한 곳에서 — 시간표·과제·학과 소식을 한 달력에 모으고, 밥약·과팅·놀기까지 이어주는 앱 프로토타입이에요.
(해커톤 주제: "새내기의 하루를 구제해줄 서비스")

웹으로 만들었던 프로토타입(`../index.html`)을 **Flutter 앱으로 그대로 옮긴** 버전이에요.
모든 이름·일정·마감일은 **예시 데이터**이고, 학생증 인증·에브리타임 연결·푸시 알림은 **화면으로 보여주는 데모**예요(진짜 서버 연결은 없어요).

## 터미널에 이렇게 치면 돼요

먼저 [Flutter](https://docs.flutter.dev/get-started/install) 를 설치한 뒤, 터미널에서 이 폴더로 들어가요.

```bash
cd mate
flutter pub get
```

그다음 **쓰는 시뮬레이터에 맞춰** 하나만 치면 돼요.

### 아이폰 시뮬레이터 (맥)

```bash
open -a Simulator
flutter run -d ios
```

시뮬레이터가 이미 켜져 있으면 `flutter run -d ios` 만 해도 돼요.

> **Xcode 27** 에서는 Simulator 앱 이름이 **Device Hub** 로 바뀌었어요. `open -a Simulator` 가 안 되면 `open -a "Device Hub"` 를 쓰고,
> 같은 이름의 시뮬레이터가 여러 개면 `flutter devices` 로 나온 **기기 ID(UUID)** 로 `flutter run -d <ID>` 하세요.
> 처음 한 번은 `sudo xcodebuild -license accept` 와 `sudo xcodebuild -runFirstLaunch` 도 필요해요.

### 안드로이드 에뮬레이터

Android Studio에서 에뮬레이터를 켠 다음:

```bash
flutter run -d android
```

에뮬레이터 목록을 보고 직접 켜려면:

```bash
flutter emulators
flutter emulators --launch <에뮬레이터_id>
flutter run
```

### 크롬에서 폰처럼 보기 (맥 / 윈도우 / 리눅스)

시뮬레이터가 아직 없으면 이 명령이 제일 빨라요.

```bash
flutter run -d chrome
```

### 연결된 기기가 여러 개일 때

```bash
flutter devices
flutter run -d <기기_id>
```

예: 아이폰 시뮬레이터만 고르려면 `flutter run -d iPhone`, 안드로이드면 `flutter run -d emulator`.

---

설치가 잘 됐는지는 `flutter doctor` 로 확인해요. 안드로이드는 Android Studio, 아이폰은 **맥 + Xcode** 가 필요해요. 윈도우에서는 iOS 시뮬레이터를 켤 수 없어요.

## 들어 있는 기능

- **로그인 / 회원가입**: 학번 · 비밀번호 로그인(데모라서 아무 값이나 OK), 회원가입은 학생증 사진(모의) → 이름·학번·학과·성별 입력 → 제출
- **메인화면**: 가입하면 **메인화면이 먼저** 떠요. 카드 4개(밥약 · 과팅 / 놀기 · 달력 · 내 약속)를 눌러서 각 화면으로 이동해요.
- **관심사 고르기**: 달력이나 추천을 **처음 열 때 딱 한 번만** 떠요 (로그인으로 들어오면 건너뛰어요)
- **달력**: 주간/월간 보기, 날짜 칸 안에 일정 글씨, AI 건강 챙기기, 일정 추가(날짜 직접 입력 · 종류 직접 추가), 다가오는 마감 · 아래 탭으로 **추천**과 오가요
- **추천**: 관심사에 맞는 소식 → "달력에 추가", 누르면 원문 사이트로 이동, 친구와 함께 신청
- **밥약**: 맞팔(서로 팔로우)한 친구가 보낸 밥약 수락·거절, 랜덤 매칭 상세, 밥약 보내기(날짜·시간, 먹는 사람, 랜덤 파티, 실명/익명, 푸시 켬/끔) — 상대는 맞팔한 친구만
- **과팅 / 놀기**: 과팅 찾기(남·여 팀 카드 → 신청), 과팅 만들기(날짜·시간 스크롤, 장소, 2:2~4:4, 우리팀 친구 추가), 놀기(맞팔 친구가 보낸 신청 받기, 시간·장소·무엇을·맞팔 친구와). 과팅은 팔로우와 상관없이 가입한 모두가 대상이에요
- **내 약속**: 밥약 · 과팅 · 놀기로 잡힌 약속 모아보기
- **팔로우**: 내 정보에서 내가 팔로우 / 나를 팔로우 목록 보기, 이름·학번으로 찾아서 팔로우 (밥약 · 놀기는 맞팔끼리만 이어져요)
- **내 정보**: 이름 · 학번 · 학과 · 성별, 채널톡 연동(자리만 있음), 로그아웃, 정보 가져올 곳, 데모 둘러보기
- 받는 사람 화면(푸시 알림 미리보기), 알림 배너, 다크 모드 자동 대응

## 폰에 설치할 파일 만들기

```bash
# 안드로이드 APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

아이폰은 맥에서 `ios/Runner.xcworkspace` 를 Xcode로 열어 Signing & Capabilities 에서 Apple ID를 Team으로 고른 뒤 `flutter run` 하면 돼요.

홈 화면 이름은 `mate`예요. 바꾸려면 안드로이드는 `android/app/src/main/AndroidManifest.xml` 의 `android:label`, iOS는 `ios/Runner/Info.plist` 의 `CFBundleDisplayName` 을 고치면 돼요.

## 파일 설명 — 어디를 고치면 되나요?

| 바꾸고 싶은 것 | 파일 |
| --- | --- |
| 학교·학과·단대 공지 HTML 파서, 아이캠퍼스/에타 예시 JSON | `lib/feeds.dart`, `assets/feeds/` |
| 색깔, 글꼴, 아이콘 | `lib/theme.dart` (`Pal.light` / `Pal.dark`) |
| 버튼을 눌렀을 때 일어나는 일, 예시 일정, 알림 문구 | `lib/state.dart` |
| 공통 부품(버튼, 칩, 카드, 스크롤 선택) | `lib/widgets.dart` |
| 아래에서 올라오는 창(일정 추가, 알림, 밥약 상세, 과팅 신청 …) | `lib/sheets.dart` |
| 화면 뼈대, 배너, 받는 사람 화면 | `lib/shell.dart` |
| 화면들 | `lib/screens/` — `onboarding`(로그인·가입·관심사) · `home`(메인·내 약속·내 정보) · `calendar` · `reco` · `social`(밥약·과팅·놀기) |

## 알아두세요

- 제목 글꼴은 주아체(Jua, OFL 라이선스)예요. 라이선스 파일은 `assets/fonts/OFL.txt`.
- 학교·학과·소프트웨어융합대학 공지는 소프트웨어학과 **학부생**에게 필요한 글만 가져와요. 대학원 게시판은 읽지 않고, 제목에 대학원·조교·교수 채용이 있으면 빼요.
- 추천에서 + 를 누르면 공지 제목의 **마감일**이나 **행사 당일**에 달력 일정이 들어가요.
- 진짜 푸시 알림, 학생증 인증, 아이캠퍼스/에타 **로그인 연동**은 아직 없어요 (학교·서비스 허가가 필요해요).
- 안드로이드 뒤로가기 버튼은 앱 안의 이전 화면으로 돌아가도록 되어 있어요. 아이폰에는 뒤로가기 버튼이 없어서 화면 왼쪽 위 `<` 버튼으로 이동해요.

## 채널톡 도우미 (상담 봇)

홈 오른쪽 아래의 동그란 버튼을 누르면 채널톡 웹 플러그인이 웹뷰로 열려요. 봇의 질문·답변은 채널톡 관리자 화면에서 만들어요.

플러그인 키(공개용 값)는 `lib/channel.dart`에 기본값으로 들어 있어서 그냥 실행하면 돼요. 다른 채널을 쓰려면 이렇게 덮어써요. (Access Secret 은 서버용 비밀값이라 앱·저장소에 절대 넣지 않아요.)

```
flutter pub get
flutter run -d <기기 ID> --dart-define=CHANNEL_PLUGIN_KEY=다른_플러그인_키
```
