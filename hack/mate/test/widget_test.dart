import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mate/feeds.dart';
import 'package:mate/main.dart';
import 'package:mate/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FeedClient.allowNetwork = false;
  });

  setUp(() {
    app.resetAll();
    app.logout();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MateApp());
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, '2026123456');
    await tester.enterText(find.byType(TextField).last, 'demo');
    await tester.tap(find.text('로그인').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
  }


  testWidgets('로그인 칸에 학번·비밀번호를 칠 수 있어요', (tester) async {
    await tester.pumpWidget(const MateApp());
    await tester.enterText(find.byType(TextField).first, '2026123456');
    await tester.enterText(find.byType(TextField).at(1), 'demo');
    expect(app.idC.text, '2026123456');
    expect(app.pwC.text, 'demo');
    await tester.tap(find.text('로그인').last);
    await tester.pump();
    expect(find.text('밥약'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('로그인 뒤 내 정보는 로그아웃까지예요', (tester) async {
    await tester.pumpWidget(const MateApp());
    app.idC.text = '2026123456';
    app.pwC.text = 'demo';
    app.login();
    await tester.pump();
    expect(find.text('밥약'), findsOneWidget);
    app.open('me');
    await tester.pump();
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('채널톡 연동'), findsOneWidget);
    expect(find.text('정보를 가져올 곳'), findsNothing);
    expect(find.text('지금 가져오기'), findsNothing);
    expect(find.text('데모 둘러보기'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  test('성균관대 공지 HTML에서 제목·날짜·글번호를 뽑아요', () {
    final html = File('test/fixtures/skku_board.html').readAsStringSync();
    final list = SkkuBoardParser.parse(html, baseUrl: 'https://www.skku.edu/skku/campus/skk_comm/notice01.do');
    expect(list.length, 3);
    expect(list.first.id, '140050');
    expect(list.first.categoryRaw, '장학');
    expect(list.first.posted, '2026-09-18');
    expect(list.first.title, contains('대학원우수장학금'));
    expect(list.first.url, 'https://www.skku.edu/skku/campus/skk_comm/notice01.do?mode=view&articleNo=140050');
  });

  test('제목 안의 마감일·행사 당일을 달력 키로 바꿔요', () {
    expect(noticeWhen('추천서 접수: 9.23.(수)~10.13.(화)', '2026-09-18').key, '10-13');
    expect(noticeWhen('추천서 접수: 9.23.(수)~10.13.(화)', '2026-09-18').kind, 'deadline');
    expect(noticeWhen('모집[~9.22.(화) 16:00까지]', '2026-09-19').key, '9-22');
    expect(noticeWhen('모집[~9.22.(화) 16:00까지]', '2026-09-19').time, '16:00');
    expect(noticeWhen('날짜 없는 공지', '2026-09-18').key, '9-18');
    expect(noticeWhen('날짜 없는 공지', '2026-09-18').kind, 'posted');
    final info = noticeWhen('2026-2학기 소프트웨어학과 진학설명회 안내 (9/30(목) 18:00 / 사전접수 : 9/18(금))', '2026-09-16');
    expect(info.key, '9-30');
    expect(info.time, '18:00');
    expect(info.kind, 'event');
    final forum = noticeWhen('(9월 29일(화)/여의도 FKI타워) 대한민국 클라우드/SaaS 포럼 2026', '2026-09-11');
    expect(forum.key, '9-29');
    expect(forum.kind, 'event');
    final talk = noticeWhen('(9/14(월) 12:00-13:30 2공학관 26106호) 한화시스템 방산부문 채용설명회', '2026-09-11');
    expect(talk.key, '9-14');
    expect(talk.time, '12:00');
    expect(talk.kind, 'event');
    expect(noticeCat('장학', '선발 안내'), 'schol');
    expect(noticeCat('동아리', '모집'), 'club');
    expect(noticeCat('학사', '졸업평가 안내'), 'etc');
    expect(noticeCat('행사/세미나', '2026 ICPC 대학생 프로그래밍 경시대회 안내'), 'edu');
    expect(noticeCat('', '국가장학금 지급 안내'), 'schol');
    expect(noticeCat('취업', 'ICT학점연계 인턴십'), 'lab');
    expect(noticeCat('채용/모집', '신입사원 모집'), 'etc');
    expect(noticeCat('행사/세미나', '비교과 프로그램 참여 후기 조사'), 'edu');
    expect(noticeViewUrl('https://cse.skku.edu/cse/notice.do?mode=list', '225776'), 'https://cse.skku.edu/cse/notice.do?mode=view&articleNo=225776');
  });

  test('학부생에게 필요한 글만 남기고 대학원·조교는 빼요', () {
    expect(keepUndergradNotice('2026 ICPC 대학생 프로그래밍 경시대회 안내', '행사/세미나'), isTrue);
    expect(keepUndergradNotice('[졸업평가] 연구논문작품 신청서 제출 방법 안내', '학사'), isTrue);
    expect(keepUndergradNotice('2026-2학기 소프트웨어학과 진학설명회 안내', '행사/세미나'), isTrue);
    expect(keepUndergradNotice('[한국장학재단] 2026학년도 2학기 국가장학금 지급 안내', ''), isTrue);
    expect(keepUndergradNotice('2027학년도 1학기 新대학원우수장학금 선발 안내', '장학'), isFalse);
    expect(keepUndergradNotice('사회과학대학 행정조교 모집', '채용/모집'), isFalse);
    expect(keepUndergradNotice('AI응용공학과(일반대학원) 신입생 모집', '입학'), isFalse);
    expect(keepUndergradNotice('산학교수 채용', '채용/모집'), isFalse);
    expect(keepUndergradNotice('2026-2학기 대학원 한마당 및 소프트웨어학과 오픈랩 안내', '행사/세미나'), isFalse);
    expect(keepUndergradNotice('When Language Meets 3D: Language-Grounded Perception and Reasoning', ''), isFalse);
  });

  test('저장해 둔 JSON 공지도 Opp 로 바뀌어요', () {
    const json = '''
{
  "sourceId": "school",
  "loginRequired": false,
  "items": [
    {"id": "1", "title": "교내 장학금", "url": "https://example.com", "posted": "2026-09-18", "categoryRaw": "장학"}
  ]
}
''';
    final doc = parseSnapshot(json);
    expect(doc.opps.single.g, 'school');
    expect(doc.opps.single.cat, 'schol');
    expect(doc.opps.single.id, 'feed-school-1');
  });

  test('공개 게시판 HTML을 가져오면 네트워크 결과로 표시해요', () async {
    FeedClient.allowNetwork = true;
    addTearDown(() => FeedClient.allowNetwork = false);
    final html = File('test/fixtures/skku_board.html').readAsStringSync();
    final client = FeedClient(
      httpClient: MockClient((req) async {
        expect(req.url.host, 'www.skku.edu');
        return http.Response.bytes(utf8.encode(html), 200, headers: {'content-type': 'text/html; charset=utf-8'});
      }),
      loadAsset: (_) async => throw StateError('snapshot should not be used'),
    );
    final bundle = await client.load(kFeedSources.firstWhere((s) => s.id == 'school'));
    expect(bundle.fromNetwork, isTrue);
    expect(bundle.opps, isNotEmpty);
    expect(bundle.opps.every((o) => keepUndergradNotice(o.title, o.meta)), isTrue);
    expect(bundle.opps.any((o) => o.title.contains('ICPC')), isTrue);
    expect(bundle.opps.any((o) => o.title.contains('대학원우수')), isFalse);
    expect(bundle.opps.where((o) => o.title.contains('ICPC')).every((o) => o.url.contains('articleNo=225776')), isTrue);
    expect(bundle.opps.first.src, '학교 홈페이지');
  });

  test('로그인이 필요한 곳은 공개 HTML을 긁지 않아요', () async {
    var hits = 0;
    final client = FeedClient(
      httpClient: MockClient((req) async {
        hits++;
        return http.Response('nope', 500);
      }),
      loadAsset: (path) async {
        expect(path, 'assets/feeds/icampus.json');
        return File(path).readAsStringSync();
      },
    );
    final bundle = await client.load(kFeedSources.firstWhere((s) => s.id == 'icampus'));
    expect(hits, 0);
    expect(bundle.loginPending, isTrue);
    expect(bundle.fromNetwork, isFalse);
    expect(bundle.opps, isNotEmpty);
  });

  test('소프트웨어융합대학 학부 공지를 가져와요', () async {
    FeedClient.allowNetwork = true;
    addTearDown(() => FeedClient.allowNetwork = false);
    final html = File('test/fixtures/sw_college_board.html').readAsStringSync();
    final client = FeedClient(
      httpClient: MockClient((req) async {
        expect(req.url.host, 'sw.skku.edu');
        return http.Response.bytes(utf8.encode(html), 200, headers: {'content-type': 'text/html; charset=utf-8'});
      }),
      loadAsset: (_) async => throw StateError('snapshot should not be used'),
    );
    final bundle = await client.load(kFeedSources.firstWhere((s) => s.id == 'college'));
    expect(bundle.fromNetwork, isTrue);
    expect(bundle.opps, isNotEmpty);
    expect(bundle.opps.every((o) => o.src == '소프트웨어융합대학'), isTrue);
    expect(bundle.opps.any((o) => o.title.contains('진학설명회')), isTrue);
    expect(bundle.opps.any((o) => o.title.contains('한마당')), isFalse);
    final info = bundle.opps.firstWhere((o) => o.title.contains('진학설명회'));
    expect(info.key, '9-30');
    expect(info.t, '18:00');
    expect(info.whenKind, 'event');
    expect(info.url, contains('articleNo=225638'));
  });

  test('저장해 둔 단대 공지 스냅샷도 Opp 로 바뀌어요', () {
    final doc = parseSnapshot(File('assets/feeds/college.json').readAsStringSync());
    expect(doc.sourceId, 'college');
    expect(doc.opps, isNotEmpty);
    expect(doc.opps.any((o) => o.title.contains('진학설명회') && o.key == '9-30' && o.whenKind == 'event'), isTrue);
  });

  testWidgets('추천 + 는 공지의 마감일·행사 당일에 달력 일정을 넣어요', (tester) async {
    await tester.pumpWidget(const MateApp());
    final before = app.events.length;
    app.toggleOpp('o1');
    await tester.pump();
    final added = app.events.where((e) => e.id == 'opp-o1');
    expect(added, isNotEmpty);
    expect(added.first.key, '9-25');
    expect(added.first.t, '18:00');
    expect(app.sel, '9-25');
    app.toggleOpp('o1');
    await tester.pump();
    expect(app.events.where((e) => e.id == 'opp-o1'), isEmpty);
    expect(app.events.length, before);

    final o = parseSnapshot(File('assets/feeds/college.json').readAsStringSync()).opps.firstWhere((x) => x.title.contains('진학설명회'));
    app.opps.add(o);
    app.toggleOpp(o.id);
    await tester.pump();
    final ev = app.events.firstWhere((e) => e.id == 'opp-${o.id}');
    expect(ev.key, '9-30');
    expect(ev.t, '18:00');
    expect(app.sel, '9-30');
    app.events.removeWhere((e) => e.id == ev.id);
    app.opps.removeWhere((x) => x.id == o.id);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('홈에는 알림·마이페이지가 없고, 내 약속에서만 마이페이지가 보여요', (tester) async {
    await pumpApp(tester);
    await login(tester);

    expect(find.bySemanticsLabel(RegExp(r'^알림')), findsNothing);
    expect(find.bySemanticsLabel('내 정보'), findsNothing);

    await tester.ensureVisible(find.text('내 약속'));
    await tester.tap(find.text('내 약속'));
    await tester.pump();

    expect(find.bySemanticsLabel('내 정보'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('메인 인사와 과팅 팀 문구가 바뀌었어요', (tester) async {
    await pumpApp(tester);
    await login(tester);

    expect(find.textContaining('혜인님', findRichText: true), findsOneWidget);
    expect(find.textContaining('메이트 찾으시나요?', findRichText: true), findsOneWidget);
    expect(find.textContaining('오늘도 혼자가 아니에요', findRichText: true), findsNothing);
    expect(find.textContaining('이번주 과팅 팀 2개'), findsOneWidget);
    expect(find.textContaining('이벤트 확정됨'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('페이지 오른쪽 위에 동그란 홈 버튼이 없어요', (tester) async {
    await pumpApp(tester);
    await login(tester);

    expect(find.bySemanticsLabel('달력, 메인화면으로'), findsNothing);
    expect(find.bySemanticsLabel('과팅 / 놀기, 메인화면으로'), findsNothing);

    await tester.tap(find.text('달력').first);
    await tester.pump();
    expect(find.bySemanticsLabel('달력, 메인화면으로'), findsNothing);

    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pump();
    await tester.tap(find.text('과팅 / 놀기'));
    await tester.pump();
    expect(find.bySemanticsLabel('과팅 / 놀기, 메인화면으로'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('추천 탭은 둘러보세요만 있고 관심 카드는 없어요', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('달력').first);
    await tester.pump();
    await tester.tap(find.text('추천'));
    await tester.pump();

    expect(find.text('둘러보세요'), findsOneWidget);
    expect(find.text('이거 관심 있으세요?'), findsNothing);
    expect(find.text('이런 것도 있어요'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('과팅은 내 성별 팀이 가득하면 신청불가예요', (tester) async {
    await pumpApp(tester);
    await login(tester);

    await tester.tap(find.text('과팅 / 놀기'));
    await tester.pump();
    expect(find.text('신청불가'), findsWidgets);
    expect(find.text('신청하기'), findsNothing);

    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pump();
    await tester.ensureVisible(find.text('내 약속'));
    await tester.tap(find.text('내 약속'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('내 정보'));
    await tester.pump();
    await tester.tap(find.text('여성'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('뒤로가기'));
    await tester.pump();
    await tester.tap(find.text('과팅 / 놀기'));
    await tester.pump();

    expect(find.text('신청하기'), findsWidgets);
    await tester.tap(find.text('신청하기').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('우리 팀으로 신청하기'));
    await tester.pump();
    expect(find.text('신청했어요'), findsOneWidget);
    expect(find.text('남 3 · 여 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('밥약 신청하기에서 맞팔 친구를 골라 보낼 수 있어요', (tester) async {
    await pumpApp(tester);
    await login(tester);

    await tester.tap(find.text('밥약').first);
    await tester.pump();
    expect(find.text('밥약 찾기'), findsWidgets);

    await tester.tap(find.text('밥약 보내기'));
    await tester.pump();
    expect(find.text('누구와 먹을까요?'), findsOneWidget);

    final openReq = find.textContaining('밥약 신청하기');
    await tester.ensureVisible(openReq);
    await tester.tap(openReq);
    await tester.pumpAndSettle();

    expect(find.textContaining('맞팔한 친구에게만 신청할 수 있어요'), findsOneWidget);
    expect(find.text('김민준'), findsWidgets);
    expect(find.text('이서연'), findsWidgets);
    expect(find.text('낙빈'), findsWidgets);
    expect(find.text('학과 선배'), findsNothing);
    expect(find.text('신청할 친구를 골라주세요'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('김민준에게 신청'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('이서연에게 신청'));
    await tester.pump();
    expect(find.text('2명에게 신청 보내기'), findsOneWidget);

    await tester.tap(find.text('2명에게 신청 보내기'));
    await tester.pump();
    expect(find.text('김민준, 이서연에게 밥약 신청을 보냈어요. 답장이 오면 배너로 알려드려요'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
