import 'dart:async';

import 'package:flutter/material.dart';

import 'data.dart';
import 'feeds.dart';

/// 앱의 모든 상태와 "버튼을 눌렀을 때 일어나는 일"이 들어 있는 파일이에요.
/// 화면(screens/*.dart)은 여기 있는 app 을 읽고, 버튼에서 app.○○() 를 불러요.

class BannerData {
  final String t, ic, k, title, body, cta, go;
  const BannerData({required this.t, required this.ic, required this.k, required this.title, required this.body, this.cta = '', this.go = ''});
}

class MealState {
  String date = kToday;
  String time = '12:30';
  String who = 'solo'; // solo | all | pick
  bool random = false; // 랜덤 파티
  final Set<int> picked = {}; // 친구 선택 (kFriends 번호)
  final List<int> mates = []; // 매칭된 친구
  bool anon = false, push = true;
  String msg = '';
  String step = 'form'; // form | searching | matched | posted
}

class MeetState {
  String date = kToday;
  String time = '17:30';
  String size = '2:2';
  final List<int> members = []; // 우리팀에 추가한 친구 (kFriends 번호)
  String step = 'form'; // form | matched
  String? postId; // 신청한 과팅
  bool warned = false;
}

class PlayState {
  String date = kToday;
  String time = '18:00';
  String act = 'cafe';
  String who = 'team'; // team | all | pick
  bool push = true;
  String view = 'main'; // main | done
  final Set<int> picked = {}; // 친구 지정 (kFriends 번호)
}

class Load {
  final double score, jobH;
  final int assigns, n, lvl;
  const Load(this.score, this.jobH, this.assigns, this.n, this.lvl);
}

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  int _uid = 100;
  Timer? _toastT, _bannerT, _searchT;
  final FeedClient feeds = FeedClient();
  int _syncGen = 0;
  bool _syncedOnce = false;

  // ---- 화면 상태
  /// 지금 보이는 화면: login | verify | interest | home | cal | reco | meal | meet | play | plans | me
  String screen = 'login';
  String? _pending; // 관심사 고른 뒤에 열 화면
  final List<String> _hist = []; // 뒤로가기로 돌아갈 화면들
  bool interestDone = false; // 관심사는 딱 한 번만 골라요
  String verify = 'idle'; // idle | scanning | done
  String mealView = 'find'; // find | send
  String meetView = 'find'; // find | make
  String calView = 'week';
  String sel = kToday;
  String filter = 'all';
  bool push = false;
  BannerData? banner;
  String toastMsg = '';

  // 내 정보
  String userName = '혜인';
  String studentNo = '2026123456';
  String dept = '소프트웨어학과';
  String gender = 'male'; // male | female
  bool autoLogin = false, showPw = false;

  late List<Ev> events;
  late List<Opp> opps;
  late Map<String, bool> cats, fields, conn;
  final Map<String, String> feedStatus = {};
  bool syncing = false;
  late List<CustomType> customTypes;
  late List<MeetPost> meetPosts;
  late MealState meal;
  late MeetState meet;
  late PlayState play;
  final Map<String, String> mealReqState = {}; // 밥약 찾기 카드 상태: accepted | declined | applied
  final Set<String> meetApplied = {}; // 신청한 과팅

  // 함께 신청
  String shareOpp = 'o1';
  late Map<int, bool> shareTo;
  final Set<int> reqPicked = {}; // 밥약 신청을 보낼 맞팔 친구 (kFriends 번호)
  bool reqAnon = true;

  // 팔로우: 밥약 · 놀기는 서로 팔로우한(맞팔) 사람끼리만, 과팅은 가입한 모두가 대상
  final Set<int> following = {}; // 내가 팔로우한 사람 (kFriends 번호)
  final followSearchC = TextEditingController(); // 이름 · 학번 검색

  // 일정 추가
  String addType = 'job';
  bool addNewOpen = false;
  String addStart = '18:00', addEnd = '22:00';

  // 글자 입력칸
  final idC = TextEditingController();
  final pwC = TextEditingController();
  final signNameC = TextEditingController();
  final signNoC = TextEditingController();
  final signDeptC = TextEditingController();
  String signErr = ''; // 회원가입 화면의 안내 문구
  final mealMsgC = TextEditingController();
  final addTitleC = TextEditingController();
  final addDateC = TextEditingController();
  final addNewC = TextEditingController();

  // 일정 수정 창
  String? editId;
  String editType = 'job', editStart = '18:00', editEnd = '';
  final editTitleC = TextEditingController();
  final editDateC = TextEditingController();
  final editSubC = TextEditingController();
  final reqMsgC = TextEditingController();
  final meetPlaceC = TextEditingController();
  final meetNoteC = TextEditingController();
  final playPlaceC = TextEditingController();

  void _init() {
    screen = 'login';
    _pending = null;
    _hist.clear();
    interestDone = false;
    verify = 'idle';
    mealView = 'find';
    meetView = 'find';
    calView = 'week';
    sel = kToday;
    filter = 'all';
    push = false;
    banner = null;
    toastMsg = '';
    gender = 'male';
    autoLogin = false;
    showPw = false;
    events = _initialEvents();
    cats = {'edu': true, 'schol': true, 'lab': true, 'vol': true, 'club': true, 'etc': true};
    fields = {'개발·IT': true, '경영·마케팅': true};
    conn = {'icampus': true, 'school': true, 'dept': true, 'college': true, 'etta': true};
    opps = List.of(kOpps);
    feedStatus
      ..clear()
      ..addEntries(kFeedSources.map((s) => MapEntry(s.id, s.needsLogin ? '로그인 연동 전 · 예시 데이터' : '아직 가져오지 않았어요')));
    syncing = false;
    _syncedOnce = false;
    _syncGen++;
    customTypes = [];
    meetPosts = [for (final p in kMeetSeed) MeetPost(p.id, p.key, p.time, p.place, p.size, List.of(p.m), List.of(p.f), mine: p.mine, note: p.note)];
    meal = MealState();
    meet = MeetState();
    play = PlayState();
    mealReqState.clear();
    meetApplied.clear();
    reqPicked.clear();
    reqAnon = true;
    following
      ..clear()
      ..addAll(kFollowingSeed);
    followSearchC.clear();
    shareOpp = 'o1';
    shareTo = {0: true, 1: true, 2: false};
    addType = 'job';
    addNewOpen = false;
    addStart = '18:00';
    addEnd = '22:00';
    idC.clear();
    pwC.clear();
    signNameC.clear();
    signNoC.clear();
    signDeptC.clear();
    signErr = '';
    mealMsgC.clear();
    addTitleC.clear();
    addDateC.text = '9/21';
    addNewC.clear();
    meetPlaceC.clear();
    meetNoteC.clear();
    playPlaceC.clear();
    reqMsgC.text = '안녕하세요! 같은 학과 새내기예요. 시간 되실 때 밥 한 끼 같이 먹어도 될까요?';
  }

  void _n() => notifyListeners();

  // ------------------------------------------------------------ 예시 일정

  Ev _ev(String key, String t, String end, String type, String title, String sub,
      {bool mine = false, double? hours, String? src}) {
    return Ev(id: 'e${_uid++}', key: key, t: t, end: end, type: type, title: title, sub: sub, mine: mine, hours: hours, src: src);
  }

  Ev oppEvent(Opp o) => Ev(
        id: 'opp-${o.id}',
        key: o.key,
        t: o.t,
        end: '',
        type: 'opp',
        title: o.title,
        sub: o.whenKind == 'event' ? '기회 추천에서 추가 · ${o.src} · 행사' : '기회 추천에서 추가 · ${o.src}',
        cat: o.cat,
        g: o.g,
        oppId: o.id,
      );

  List<Ev> _initialEvents() {
    const ic = 'icampus';
    const from = '아이캠퍼스에서 가져옴';
    final base = <Ev>[
      _ev('9-21', '09:00', '10:15', 'class', '자료구조', from, src: ic),
      _ev('9-21', '13:00', '14:15', 'class', '논리회로', from, src: ic),
      _ev('9-21', '23:59', '', 'assign', '자료구조 과제 2', '아이캠퍼스 · 마감', src: ic),
      _ev('9-21', '23:59', '', 'assign', '영어 에세이', '아이캠퍼스 · 마감', src: ic),
      _ev('9-21', '23:59', '', 'assign', '논리회로 실험 보고서', '아이캠퍼스 · 마감', src: ic),
      _ev('9-22', '10:30', '12:00', 'class', '프로그래밍 실습', from, src: ic),
      _ev('9-22', '12:00', '18:00', 'job', '카페 알바', '6시간 · 직접 입력', mine: true, hours: 6),
      _ev('9-23', '09:00', '10:15', 'class', '자료구조', from, src: ic),
      _ev('9-23', '15:00', '16:15', 'class', '영어 회화', from, src: ic),
      _ev('9-23', '18:30', '20:00', 'meet', '동기들과 저녁 약속', '캠퍼스 앞 · 3명', mine: true),
      _ev('9-24', '10:30', '12:00', 'class', '프로그래밍 실습', from, src: ic),
      _ev('9-24', '17:00', '', 'dept', '학과 신입생 멘토링 설명회', '학과 홈페이지 · 공지'),
      _ev('9-25', '13:00', '14:15', 'class', '논리회로', from, src: ic),
      _ev('9-25', '19:00', '21:00', 'meet', '동아리 첫 모임', '에타에서 찾은 일정', mine: true),
      _ev('9-26', '15:00', '17:00', 'job', '과외', '2시간 · 직접 입력', mine: true, hours: 2),
      oppEvent(kOpps[5]),
      oppEvent(kOpps[2]),
    ];
    return base..addAll(_fillerEvents());
  }

  /// 21~27일 밖의 날들: 월간 보기가 비어 보이지 않도록 넣은 예시 일정
  List<Ev> _fillerEvents() {
    final out = <Ev>[];
    const ic = 'icampus';
    const from = '아이캠퍼스에서 가져옴';
    final days = <int>[for (var d = 1; d <= 20; d++) d, 28, 29, 30];
    for (final d in days) {
      final k = '9-$d';
      final w = dowOf(k);
      Ev cls(String t, String e, String n) => _ev(k, t, e, 'class', n, from, src: ic);
      if (w == 0) out.addAll([cls('09:00', '10:15', '자료구조'), cls('13:00', '14:15', '논리회로')]);
      if (w == 1) {
        out.addAll([cls('10:30', '12:00', '프로그래밍 실습'), _ev(k, '12:00', '18:00', 'job', '카페 알바', '6시간 · 직접 입력', mine: true, hours: 6)]);
      }
      if (w == 2) out.addAll([cls('09:00', '10:15', '자료구조'), cls('15:00', '16:15', '영어 회화')]);
      if (w == 3) out.add(cls('10:30', '12:00', '프로그래밍 실습'));
      if (w == 4) out.add(cls('13:00', '14:15', '논리회로'));
      if (w == 5) out.add(_ev(k, '15:00', '17:00', 'job', '과외', '2시간 · 직접 입력', mine: true, hours: 2));
    }
    Ev a(String k, String title) => _ev(k, '23:59', '', 'assign', title, '아이캠퍼스 · 마감', src: ic);
    out.addAll([
      a('9-4', '영어 에세이 1'),
      a('9-7', '자료구조 과제 1'),
      _ev('9-11', '17:00', '', 'dept', '학과 신입생 OT', '학과 홈페이지 · 공지'),
      _ev('9-12', '18:00', '20:00', 'meet', '동기 첫 모임', '캠퍼스 앞 · 5명', mine: true),
      a('9-14', '논리회로 과제 1'),
      _ev('9-16', '12:00', '13:00', 'meet', '밥약 · 학식', '이서연 외 2명', mine: true),
      a('9-18', '실험 보고서 1'),
      _ev('9-19', '19:00', '21:00', 'meet', '동아리 설명회', '에타에서 찾은 일정', mine: true),
      a('9-28', '자료구조 과제 3'),
      _ev('9-29', '17:00', '', 'dept', '졸업생 특강', '학과 홈페이지 · 공지'),
      a('9-30', '영어 에세이 2'),
    ]);
    return out;
  }

  // ------------------------------------------------------------ 조회 도우미

  CustomType? customOf(String t) {
    for (final c in customTypes) {
      if (c.id == t) return c;
    }
    return null;
  }

  String typeName(String t) => customOf(t)?.name ?? kTypeShort[t] ?? t;

  /// 필터 · 일정 종류 목록 (맨 앞이 '전체')
  List<(String, String)> filterList() => [('all', '전체'), ...kBaseTypes, ...customTypes.map((c) => (c.id, c.name))];

  bool isAdded(String oppId) => events.any((e) => e.id == 'opp-$oppId');

  bool visible(Ev e) {
    if (e.src == 'icampus' && conn['icampus'] != true) return false;
    if (e.type == 'opp') {
      if (cats[e.cat] != true) return false;
      if (conn[e.g] == false) return false;
    }
    return true;
  }

  List<Ev> eventsOn(String key) {
    final l = events.where((e) => e.key == key && visible(e)).toList();
    l.sort((a, b) => a.t.compareTo(b.t));
    return l;
  }

  Load loadOf(String key) {
    final es = eventsOn(key);
    double score = 0, jobH = 0;
    var assigns = 0;
    for (final e in es) {
      if (e.type == 'class') {
        score += 1;
      } else if (e.type == 'assign') {
        score += 1.5;
        assigns++;
      } else if (e.type == 'job') {
        final h = e.hours ?? 2;
        score += h * 0.5;
        jobH += h;
      } else {
        score += 0.5;
      }
    }
    final lvl = score >= 6 ? 2 : (score >= 3 ? 1 : 0);
    return Load(score, jobH, assigns, es.length, lvl);
  }

  String aiText(String key) {
    final l = loadOf(key);
    final d = dateOf(key).subtract(const Duration(days: 1));
    final pl = loadOf('${d.month}-${d.day}');
    if (l.n == 0) return '비어있는 하루예요. 밥약이나 산책으로 기분 전환 어때요?';
    if (l.assigns >= 3) return '마감이 ${l.assigns}개예요. 충분히 자고, 영양가 있는 저녁을 챙겨요.';
    if (l.jobH >= 6) return '알바가 ${fmtH(l.jobH)}시간이에요. 내일은 쉬어가는 날로 비워두는 게 좋겠어요.';
    if (pl.jobH >= 6) return '어제 알바가 길었어요. 오늘은 물 자주 마시고 일찍 쉬어요.';
    if (l.lvl == 2) return '오늘은 빡빡한 하루예요. 끼니를 거르지 말고 중간에 쉬어가요.';
    if (l.lvl == 1) return '적당히 바쁜 날이에요. 점심은 꼭 챙겨 먹어요.';
    return '오늘은 여유로워요. 저녁 전에 가볍게 산책해 보는 건 어때요?';
  }

  List<Ev> upcoming() {
    final l = events.where((e) => visible(e) && (e.type == 'assign' || e.type == 'opp') && diffDays(e.key) >= 0).toList();
    l.sort((a, b) {
      final d = diffDays(a.key) - diffDays(b.key);
      return d != 0 ? d : a.t.compareTo(b.t);
    });
    return l.take(6).toList();
  }

  String? fieldMatch(Opp o) {
    for (final f in o.fields) {
      if (fields[f] == true) return f;
    }
    return null;
  }

  List<Opp> recoList() => opps.where((o) => cats[o.cat] == true && conn[o.g] != false).toList();

  Opp? findOpp(String id) {
    for (final o in opps) {
      if (o.id == id) return o;
    }
    for (final o in kOpps) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// 켜 둔 곳에서 소식을 모아요. 학교·학과는 공개 홈페이지, 나머지는 연동 전 예시.
  Future<void> syncFeeds({String? only}) async {
    final gen = ++_syncGen;
    syncing = true;
    _n();
    final targets = kFeedSources.where((s) => (only == null || s.id == only) && conn[s.id] == true).toList();
    var net = 0, snap = 0;
    for (final def in targets) {
      try {
        final bundle = await feeds.load(def);
        if (gen != _syncGen) return;
        if (def.id != 'icampus') _replaceOpps(def.id, bundle.opps);
        feedStatus[def.id] = bundle.status;
        if (bundle.fromNetwork) {
          net += bundle.opps.length;
        } else {
          snap += bundle.opps.length;
        }
      } catch (_) {
        if (gen != _syncGen) return;
        feedStatus[def.id] = '가져오지 못했어요. 잠시 뒤 다시 눌러 주세요';
      }
    }
    if (gen != _syncGen) return;
    syncing = false;
    _n();
    if (only != null) {
      showToast(feedStatus[only] ?? '가져왔어요');
    } else if (net > 0) {
      showToast('공개 공지 $net건을 홈페이지에서 가져왔어요');
    } else if (snap > 0) {
      showToast('지금은 저장해 둔 공지로 보여요 (웹은 CORS, 폰에서는 바로 가져와요)');
    }
  }

  void _replaceOpps(String sourceId, List<Opp> next) {
    opps.removeWhere((o) => o.g == sourceId);
    opps.addAll(next);
  }

  String feedLine() {
    final parts = <String>[];
    for (final s in kFeedSources) {
      if (conn[s.id] != true) continue;
      parts.add(s.name);
    }
    return parts.isEmpty ? '가져온 곳을 켜 주세요' : '${parts.join(' · ')}에서 소식을 모아요.';
  }

  // 밥약 도우미
  String mealAt() => (meal.date == kToday ? '' : '${shortDate(meal.date)} ') + meal.time;
  bool mealDone() => events.any((e) => e.title == '밥약' && e.t == meal.time && e.key == meal.date);
  bool todayMealDone() => events.any((e) => e.key == kToday && e.title.startsWith('밥약'));

  /// 메인화면 카드에 쓰는 요약 글자
  String nextMealText() {
    final l = events.where((e) => e.mine && e.title.startsWith('밥약') && diffDays(e.key) >= 0).toList();
    l.sort((a, b) {
      final d = diffDays(a.key) - diffDays(b.key);
      return d != 0 ? d : a.t.compareTo(b.t);
    });
    // 데모의 지금 시각은 12:10
    l.removeWhere((e) => e.key == kToday && toMin(e.t) < 12 * 60 + 10);
    if (l.isEmpty) return '예정된 밥약이 없어요';
    final e = l.first;
    if (e.key != kToday) return '다음 밥약 ${shortDate(e.key)} ${e.t}';
    final m = toMin(e.t) - (12 * 60 + 10);
    return m < 60 ? '다음 밥약 $m분 뒤' : '다음 밥약 ${(m / 60).ceil()}시간 뒤';
  }

  /// 내 약속: 오늘 이후의 약속 (밥약 · 과팅 · 놀기 · 직접 넣은 약속)
  List<Ev> myPlans() {
    final l = events.where((e) => e.type == 'meet' && e.mine && diffDays(e.key) >= 0).toList();
    l.sort((a, b) {
      final d = diffDays(a.key) - diffDays(b.key);
      return d != 0 ? d : a.t.compareTo(b.t);
    });
    return l;
  }

  /// 이번 주(월~일)에 올라온 과팅 팀 수
  int weekMeetTeamCount() => meetPosts.where((p) => kWeek.contains(dayOf(p.key))).length;

  String formatStudentNo() {
    final n = studentNo.replaceAll(RegExp(r'\s'), '');
    return n.length == 10 ? '${n.substring(0, 4)} ${n.substring(4)}' : n;
  }

  // 과팅 도우미
  int meetCap(String size) => int.tryParse(size.split(':').first) ?? 2;

  int meetMaleCap(String size) => int.tryParse(size.split(':').first) ?? 2;

  int meetFemaleCap(String size) {
    final parts = size.split(':');
    return int.tryParse(parts.length > 1 ? parts.last : parts.first) ?? 2;
  }

  int meetSideCap(MeetPost post) => gender == 'male' ? meetMaleCap(post.size) : meetFemaleCap(post.size);

  int meetSideCount(MeetPost post) => gender == 'male' ? post.m.length : post.f.length;

  bool meetSideFull(MeetPost post) => meetSideCount(post) >= meetSideCap(post);

  String meetSideName() => gender == 'male' ? '남자' : '여자';

  (String, int) meTag() {
    final n = studentNo.replaceAll(RegExp(r'\s'), '');
    final y = n.length >= 4 ? (int.tryParse(n.substring(2, 4)) ?? 26) : 26;
    return ('소프트', y);
  }

  // ------------------------------------------------------------ 알림 · 토스트 · 배너

  void showToast(String m) {
    toastMsg = m;
    _toastT?.cancel();
    _toastT = Timer(const Duration(milliseconds: 2400), () {
      toastMsg = '';
      _n();
    });
    _n();
  }

  void showBanner(BannerData b) {
    banner = b;
    _bannerT?.cancel();
    _bannerT = Timer(const Duration(seconds: 6), () {
      banner = null;
      _n();
    });
    _n();
  }

  void addEvent(Ev e) => events.add(e);

  // ------------------------------------------------------------ 이동

  void _clearOverlays() {
    push = false;
    banner = null;
  }

  /// 새 화면을 위에 올려요 (뒤로가기로 돌아올 수 있어요).
  /// 달력·추천은 관심사를 한 번도 안 골랐다면 관심사 선택이 먼저 떠요.
  void open(String s) {
    _clearOverlays();
    if ((s == 'cal' || s == 'reco') && !interestDone) {
      _pending = s;
      s = 'interest';
    }
    if (s == screen) {
      _n();
      return;
    }
    final seen = _hist.lastIndexOf(s);
    if ((screen == 'cal' || screen == 'reco') && (s == 'cal' || s == 'reco')) {
      screen = s; // 달력 ↔ 추천 은 제자리에서 바꿔요
    } else if (seen >= 0) {
      // 이미 거쳐 온 화면이면 새로 쌓지 않고 그 화면으로 돌아가요 (뒤로가기가 빙글빙글 돌지 않게)
      final dropped = _hist.sublist(seen);
      _hist.removeRange(seen, _hist.length);
      if (dropped.any(_isSocial) && !_isSocial(s)) resetFlows();
      screen = s;
    } else {
      _hist.add(screen);
      screen = s;
    }
    if (screen == 'reco' || screen == 'me' || screen == 'cal') _kickSync();
    _n();
  }

  void _kickSync() {
    if (_syncedOnce || syncing) return;
    _syncedOnce = true;
    syncFeeds();
  }

  bool _isSocial(String x) => x == 'meal' || x == 'meet' || x == 'play';

  /// 아래 탭(달력 · 추천) 전환
  void switchTab(String s) {
    _clearOverlays();
    screen = s;
    if (s == 'reco' || s == 'cal') _kickSync();
    _n();
  }

  void goHome() {
    _clearOverlays();
    _hist.clear();
    resetFlows();
    screen = 'home';
    _n();
  }

  void resetFlows() {
    _searchT?.cancel();
    meal = MealState();
    meet = MeetState();
    play = PlayState();
    mealMsgC.clear();
    meetPlaceC.clear();
    meetNoteC.clear();
    playPlaceC.clear();
  }

  // 밥약 · 과팅 · 놀기 여는 곳
  void openMeal([String view = 'find']) {
    resetFlows();
    mealView = view;
    open('meal');
  }

  void setMealView(String v) {
    if (meal.step != 'form') {
      _searchT?.cancel();
      meal = MealState();
      mealMsgC.clear();
    }
    mealView = v;
    _n();
  }

  void openMeet([String view = 'find']) {
    resetFlows();
    meetView = view;
    open('meet');
  }

  void openPlay() {
    resetFlows();
    open('play');
  }

  /// 과팅 찾기 / 과팅 만들기 / 놀기 아래 버튼 전환
  void switchSocial(String t) {
    final cur = screen == 'play' ? 'play' : (screen == 'meet' ? meetView : '');
    final pristine = screen == 'play' ? play.view == 'main' : meet.step == 'form';
    if (cur == t && pristine) return; // 이미 보고 있는 화면이면 입력한 내용을 지우지 않아요
    resetFlows();
    _clearOverlays();
    if (t == 'play') {
      screen = 'play';
    } else {
      screen = 'meet';
      meetView = t == 'make' ? 'make' : 'find';
    }
    _n();
  }

  /// 안드로이드 뒤로가기. 처리했으면 true, 앱을 나가도 되면 false.
  bool back() {
    if (push) {
      push = false;
      _n();
      return true;
    }
    if (_hist.isEmpty) return false;
    final from = screen;
    screen = _hist.removeLast();
    if (from == 'meal' || from == 'meet' || from == 'play') resetFlows();
    if (from == 'interest') _pending = null;
    banner = null;
    _n();
    return true;
  }

  void resetAll() {
    _searchT?.cancel();
    _toastT?.cancel();
    _bannerT?.cancel();
    _init();
    screen = 'home';
    _n();
  }

  // ------------------------------------------------------------ 로그인 · 회원가입

  void toggleAuto() {
    autoLogin = !autoLogin;
    _n();
  }

  void togglePw() {
    showPw = !showPw;
    _n();
  }

  void login() {
    final id = idC.text.trim();
    if (id.isEmpty || pwC.text.isEmpty) {
      showToast('학번과 비밀번호를 입력해주세요 (데모라서 아무 값이나 괜찮아요)');
      return;
    }
    studentNo = id;
    pwC.clear();
    interestDone = true; // 이미 가입한 사람은 관심사를 또 고르지 않아요
    _pending = null;
    _hist.clear();
    screen = 'home';
    _n();
    _kickSync();
  }

  void _resetSignup() {
    verify = 'idle';
    signErr = '';
    signNameC.clear();
    signNoC.clear();
    signDeptC.clear();
  }

  void toSignup() {
    _resetSignup();
    open('verify');
  }

  void logout() {
    _clearOverlays();
    resetFlows();
    _pending = null;
    _hist.clear();
    screen = 'login';
    _n();
  }

  void setGender(String g) {
    gender = g;
    _n();
  }

  /// 학생증 사진 찍기(모의). 끝나면 학번·학과가 자동으로 채워져요.
  void verifyShot() {
    verify = 'scanning';
    signErr = '';
    _n();
    Timer(const Duration(milliseconds: 900), () {
      if (verify != 'scanning') return;
      verify = 'done';
      if (signNoC.text.trim().isEmpty) signNoC.text = '2026123456';
      if (signDeptC.text.trim().isEmpty) signDeptC.text = '소프트웨어학과';
      _n();
    });
  }

  void setSignErr(String m) {
    signErr = m;
    _n();
  }

  /// 회원가입 제출. 잘못된 곳이 있으면 화면에 안내 문구를 띄우고, 잘 됐으면 메인화면으로 가요.
  void submitSignup() {
    if (verify != 'done') {
      setSignErr('학생증 사진을 먼저 입력해주세요');
      return;
    }
    final name = signNameC.text.trim(), no = signNoC.text.trim(), dp = signDeptC.text.trim();
    if (name.isEmpty || no.isEmpty || dp.isEmpty) {
      setSignErr('이름, 학번, 학과를 모두 입력해주세요');
      return;
    }
    userName = name;
    studentNo = no;
    dept = dp;
    signErr = '';
    obNext();
  }

  /// 가입이 끝나면 메인화면이 먼저 떠요. 관심사는 달력·추천을 처음 열 때 한 번만 고르게 해요.
  void obNext() {
    interestDone = false;
    _pending = null;
    _hist.clear();
    screen = 'home';
    showToast('가입이 끝났어요! 메인화면에서 시작해요');
    _kickSync();
  }

  /// 관심사 고르기 끝. 원래 가려던 화면(달력 · 추천)으로 가요.
  void obDone() {
    interestDone = true;
    final to = _pending ?? 'cal';
    _pending = null;
    screen = to;
    showToast('끝났어요! 이제 앱이 알아서 소식을 모아요');
    _kickSync();
  }

  /// 관심사는 나중에 (내 정보에서 다시 고를 수 있어요)
  void obLater() {
    interestDone = true;
    final to = _pending ?? 'cal';
    _pending = null;
    screen = to;
    _kickSync();
    _n();
  }

  void toggleCat(String k) {
    cats[k] = !(cats[k] ?? false);
    _n();
  }

  void toggleField(String k) {
    fields[k] = !(fields[k] ?? false);
    _n();
  }

  void toggleConn(String k) {
    conn[k] = !(conn[k] ?? false);
    _n();
    if (conn[k] == true) syncFeeds(only: k);
  }

  // ------------------------------------------------------------ 달력

  void setView(String v) {
    calView = v;
    _n();
  }

  void selectDay(String k) {
    sel = k;
    _n();
  }

  void setFilter(String k) {
    filter = k;
    _n();
  }

  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
    showToast('일정을 지웠어요');
  }

  void toggleOpp(String id) {
    final o = findOpp(id);
    if (o == null) return;
    if (isAdded(id)) {
      events.removeWhere((e) => e.id == 'opp-$id');
      showToast('달력에서 뺐어요');
    } else {
      events.add(oppEvent(o));
      sel = o.key;
      if (calView == 'week' && !weekKeys(kToday).contains(o.key)) calView = 'month';
      final label = o.whenKind == 'event' ? '행사 당일' : (o.whenKind == 'posted' ? '날짜' : '마감일');
      showToast('${shortDate(o.key)} ${label}을 달력에 추가했어요');
    }
  }

  void openShare(String oppId) {
    shareOpp = oppId;
    _n();
  }

  void toggleShareTo(int i) {
    shareTo[i] = !(shareTo[i] ?? false);
    _n();
  }

  int shareCount() => shareTo.values.where((v) => v).length;

  void shareSend() => showToast('${shareCount()}명에게 “같이 신청하자”를 보냈어요');

  // 일정 추가 창
  void prepareAdd() {
    addDateC.text = shortDate(sel).split(' ')[0];
    addNewOpen = false;
  }

  void setAddType(String v) {
    addType = v;
    _n();
  }

  void toggleAddNew() {
    addNewOpen = !addNewOpen;
    _n();
  }

  void setAddTime(bool start, String v) {
    if (start) {
      addStart = v;
    } else {
      addEnd = v;
    }
    _n();
  }

  /// 새 종류 추가. 문제가 있으면 안내 문구를, 성공하면 null 을 돌려줘요.
  String? addCustomType() {
    final name = addNewC.text.trim();
    String norm(String x) => x.replaceAll(RegExp(r'\s'), '');
    if (name.isEmpty) return '종류 이름을 적어주세요';
    if (filterList().any((e) => norm(e.$2) == norm(name))) return '이미 있는 종류예요';
    if (customTypes.length >= kMaxCustom) return '종류는 6개까지 추가할 수 있어요';
    final id = 'x${_uid++}';
    customTypes.add(CustomType(id, name, customTypes.length % 6));
    addType = id;
    addNewOpen = false;
    addNewC.clear();
    _n();
    return null;
  }

  // ------------------------------------------------------------ 일정 수정

  /// 수정 창에 지금 일정 내용을 채워요.
  void prepareEdit(Ev e) {
    editId = e.id;
    editType = e.type;
    editStart = e.t;
    editEnd = e.end;
    editTitleC.text = e.title;
    editDateC.text = shortDate(e.key).split(' ')[0];
    editSubC.text = e.sub;
  }

  void setEditType(String v) {
    editType = v;
    _n();
  }

  void setEditTime(bool start, String v) {
    if (start) {
      editStart = v;
    } else {
      editEnd = v;
    }
    _n();
  }

  /// 일정 수정 저장. 문제가 있으면 안내 문구를, 성공하면 null 을 돌려줘요.
  String? submitEdit() {
    final i = events.indexWhere((x) => x.id == editId);
    if (i < 0) return '이 일정을 찾을 수 없어요';
    final old = events[i];
    final key = parseSeptDate(editDateC.text);
    if (key == null) return '9월 안의 날짜를 입력해주세요 (예: 9/28)';
    final title = editTitleC.text.trim();
    if (title.isEmpty) return '일정 이름을 적어주세요';
    if (editEnd.isNotEmpty && toMin(editEnd) <= toMin(editStart)) return '끝나는 시간은 시작 시간보다 늦어야 해요';
    final job = editType == 'job';
    final h = job && editEnd.isNotEmpty ? hoursBetween(editStart, editEnd) : 0.0;
    final hours = job ? (h == 0 ? (old.hours ?? 2) : h) : null;
    var sub = editSubC.text.trim();
    // '6시간 · 직접 입력' 처럼 자동으로 만든 설명은 시간을 바꾸면 같이 바꿔요
    if (job && sub == old.sub && RegExp(r'^[\d.]+시간 · 직접 입력$').hasMatch(sub)) sub = '${fmtH(hours!)}시간 · 직접 입력';
    events[i] = old.copyWith(key: key, t: editStart, end: editEnd, type: editType, title: title, sub: sub, hours: hours, clearHours: !job);
    sel = key;
    if (calView == 'week' && !kWeek.map((d) => '9-$d').contains(key)) calView = 'month';
    editId = null;
    showToast('일정을 고쳤어요');
    return null;
  }

  /// 일정 추가. 문제가 있으면 안내 문구를, 성공하면 null 을 돌려줘요.
  String? submitAdd() {
    final key = parseSeptDate(addDateC.text);
    if (key == null) return '9월 안의 날짜를 입력해주세요 (예: 9/28)';
    final job = addType == 'job';
    final h = job ? hoursBetween(addStart, addEnd) : 0.0;
    final title = addTitleC.text.trim();
    events.add(Ev(
      id: 'e${_uid++}',
      key: key,
      t: addStart.isEmpty ? '18:00' : addStart,
      end: addEnd,
      type: addType,
      title: title.isEmpty ? typeName(addType) : title,
      sub: job ? '${fmtH(h)}시간 · 직접 입력' : '직접 입력',
      mine: true,
      hours: job ? (h == 0 ? 2 : h) : null,
    ));
    sel = key;
    addTitleC.clear();
    if (calView == 'week' && !kWeek.map((d) => '9-$d').contains(key)) calView = 'month';
    showToast('달력에 추가했어요');
    return null;
  }

  // ------------------------------------------------------------ 팔로우

  /// 내가 팔로우한 사람들 (kFriends 번호 순서대로)
  List<int> followingList() => following.toList()..sort();

  /// 검색어 (앞뒤 공백 · 학번 사이의 공백/하이픈은 무시)
  String get followQuery => followSearchC.text.trim();

  /// 이름이나 학번으로 가입한 학생 찾기 (검색어가 없으면 빈 목록)
  List<int> followSearch() {
    final q = followQuery.toLowerCase();
    if (q.isEmpty) return const [];
    final digits = q.replaceAll(RegExp(r'[\s-]'), '');
    return [
      for (var i = 0; i < kFriends.length; i++)
        if (kFriends[i].n.toLowerCase().contains(q) || (RegExp(r'^\d+$').hasMatch(digits) && kFriends[i].no.contains(digits))) i,
    ];
  }

  void followSearchChanged() => _n();

  void followSearchClear() {
    followSearchC.clear();
    _n();
  }

  /// 서로 팔로우한(맞팔) 사이인지. 밥약 · 놀기는 이런 사람끼리만 이어져요.
  bool isMutual(int i) => following.contains(i) && kFriends[i].followsMe;

  /// 맞팔한 사람들 (kFriends 번호 순서대로)
  List<int> mutuals() => [for (var i = 0; i < kFriends.length; i++) if (isMutual(i)) i];

  /// 팔로우 · 팔로우 취소
  void toggleFollow(int i) {
    if (following.remove(i)) {
      // 맞팔이 풀리면 밥약·놀기·신청 대상에서도 빠져요
      meal.picked.remove(i);
      play.picked.remove(i);
      reqPicked.remove(i);
      meet.members.remove(i);
      shareTo.remove(i);
      showToast('${kFriends[i].n} 님 팔로우를 취소했어요');
    } else {
      following.add(i);
      showToast(kFriends[i].followsMe
          ? '${kFriends[i].n} 님과 맞팔이 됐어요. 이제 밥약 · 놀기를 함께할 수 있어요'
          : '${kFriends[i].n} 님을 팔로우했어요. 상대도 팔로우하면 맞팔이 돼요');
    }
    _n();
  }

  // ------------------------------------------------------------ 밥약

  /// 밥약 보내기: 날짜 · 시간 고르기
  void mealPick({String? date, String? time}) {
    if (date != null) meal.date = date;
    if (time != null) meal.time = time;
    _n();
  }

  void mealWho(String v) {
    meal.who = v;
    meal.random = false;
    _n();
  }

  void mealToggleRandom() {
    meal.random = !meal.random;
    _n();
  }

  void mealTogglePick(int i) {
    if (!isMutual(i)) return;
    if (!meal.picked.add(i)) meal.picked.remove(i);
    _n();
  }

  void mealSetAnon(bool v) {
    meal.anon = v;
    _n();
  }

  void mealSetPush(bool v) {
    meal.push = v;
    _n();
  }

  void mealSubmit() {
    final m = meal;
    if (m.step != 'form') return;
    final mutual = mutuals();
    final pickMode = !m.random && m.who == 'pick';
    if (pickMode && !m.picked.any(isMutual)) {
      showToast(mutual.isEmpty ? '맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요' : '밥약을 보낼 맞팔 친구를 골라주세요');
      return;
    }
    if (mutual.isEmpty && (m.random || m.who == 'all')) {
      showToast('맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요');
      return;
    }
    m.msg = mealMsgC.text.trim();
    // 혼자 먹을 사람을 찾는 글이거나 푸시를 끄면 게시판에만 올려요
    final board = !m.random && (m.who == 'solo' || !m.push);
    if (board) {
      m.step = 'posted';
      _n();
      return;
    }
    m.step = 'searching';
    _searchT?.cancel();
    _searchT = Timer(const Duration(milliseconds: 1500), () {
      if (meal.step != 'searching') return;
      // 맞팔한 사람만 매칭돼요. 랜덤 파티는 맞팔한 사람 중에서 최대 2명을 무작위로 골라요.
      final ok = mutuals();
      final chosen = meal.random
          ? (ok.toList()..shuffle()).take(2).toList()
          : (meal.who == 'pick' ? meal.picked.where(isMutual).toList() : ok);
      meal.mates
        ..clear()
        ..addAll(chosen..sort());
      if (meal.mates.isEmpty) {
        meal.step = 'form';
        showToast('맞팔한 친구가 없어서 매칭하지 못했어요');
        _n();
        return;
      }
      meal.step = 'matched';
      final names = meal.mates.map((i) => kFriends[i].n).join(', ');
      showBanner(BannerData(
        t: 'job',
        ic: 'utensils',
        k: '밥약 매칭',
        title: '${meal.mates.length}명이 같이 먹기로 했어요!',
        body: '${mealAt()} · $names${meal.msg.isEmpty ? '' : ' · “${meal.msg}”'}',
        cta: '약속 확인',
        go: 'plans',
      ));
      _n();
    });
    _n();
  }

  void mealAddToCalendar() {
    final m = meal;
    final first = m.mates.isEmpty ? '' : kFriends[m.mates.first].n;
    final who = m.mates.length <= 1 ? first : '$first 외 ${m.mates.length - 1}명';
    events.add(Ev(
      id: 'e${_uid++}',
      key: m.date,
      t: m.time,
      end: '',
      type: 'meet',
      title: '밥약',
      sub: m.msg.isEmpty ? who : '$who · ${m.msg}',
      mine: true,
    ));
    showToast('달력에 밥약을 추가했어요');
  }

  void mealReset() {
    meal = MealState();
    mealMsgC.clear();
    _n();
  }

  // 밥약 찾기: 받은 밥약 수락 · 거절 · 랜덤 매칭 신청
  void mealAccept(String id) {
    final r = kMealReqs.firstWhere((x) => x.id == id);
    mealReqState[id] = 'accepted';
    events.add(Ev(id: 'e${_uid++}', key: kToday, t: r.time, end: '', type: 'meet', title: '밥약 · ${r.title}', sub: '${r.place} · ${r.msg}', mine: true));
    showToast('${r.time} 밥약을 수락했어요. 달력에 넣었어요');
  }

  void mealDecline(String id) {
    mealReqState[id] = 'declined';
    showToast('정중하게 거절했어요');
  }

  void mealApplyRandom(String id) {
    mealReqState[id] = 'applied';
    showToast('같이 먹기를 신청했어요. 수락되면 배너로 알려드려요');
  }

  void reqTogglePick(int i) {
    if (!isMutual(i)) return;
    if (!reqPicked.add(i)) reqPicked.remove(i);
    _n();
  }

  void reqToggleAnon() {
    reqAnon = !reqAnon;
    _n();
  }

  /// 밥약 신청하기 (맞팔 친구에게만). 성공하면 true.
  bool reqSend() {
    final to = reqPicked.where(isMutual).toList()..sort();
    if (to.isEmpty) {
      showToast(mutuals().isEmpty ? '맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요' : '신청을 보낼 맞팔 친구를 골라주세요');
      return false;
    }
    final names = to.map((i) => kFriends[i].n).join(', ');
    reqPicked.clear();
    showToast('$names에게 밥약 신청을 보냈어요. 답장이 오면 배너로 알려드려요');
    return true;
  }

  // ------------------------------------------------------------ 과팅

  void meetPick({String? date, String? time}) {
    if (date != null) meet.date = date;
    if (time != null) meet.time = time;
    _n();
  }

  void meetSize(String v) {
    meet.size = v;
    final cap = meetCap(v) - 1; // 나 빼고
    while (meet.members.length > cap) {
      meet.members.removeLast();
    }
    _n();
  }

  /// 우리팀에 친구 넣기 · 빼기
  void meetToggleMember(int i) {
    if (meet.members.contains(i)) {
      meet.members.remove(i);
    } else if (meet.members.length + 1 < meetCap(meet.size)) {
      meet.members.add(i);
    } else {
      showToast('${meet.size} 과팅은 우리팀이 ${meetCap(meet.size)}명까지예요');
      return;
    }
    _n();
  }

  /// 과팅 올리기. 문제가 있으면 안내 문구를, 성공하면 null 을 돌려줘요.
  String? meetCreate() {
    final place = meetPlaceC.text.trim();
    if (place.isEmpty) return '장소를 입력해주세요';
    final mine = <(String, int)>[('소프트', 26), for (final i in meet.members) (kFriends[i].s, kFriends[i].y)];
    final male = gender == 'male';
    meetPosts.insert(
      0,
      MeetPost('mp${_uid++}', meet.date, meet.time, place, meet.size, male ? mine : const [], male ? const [] : mine, mine: true, note: meetNoteC.text.trim()),
    );
    meet = MeetState();
    meetPlaceC.clear();
    meetNoteC.clear();
    meetView = 'find';
    showToast('과팅을 올렸어요. 신청이 오면 배너로 알려드려요');
    return null;
  }

  /// 올라온 과팅에 신청. 내 성별 쪽에 자리가 있으면 그 그룹에 들어가요.
  void meetApply(String id) {
    if (meetApplied.contains(id)) return;
    final post = meetPosts.firstWhere((x) => x.id == id);
    if (post.mine) return;
    if (meetSideFull(post)) {
      showToast('이 과팅은 ${meetSideName()} 인원이 다 찼어요');
      return;
    }
    meetApplied.add(id);
    final tag = meTag();
    if (gender == 'male') {
      post.m.add(tag);
    } else {
      post.f.add(tag);
    }
    final end = fromMin(toMin(post.time) + 120);
    events.add(Ev(
      id: 'e${_uid++}',
      key: post.key,
      t: post.time,
      end: end,
      type: 'meet',
      title: '과팅 ${post.size.replaceAll(':', ' : ')}',
      sub: '${post.place} · ${meetSideName()} 팀 · 나',
      mine: true,
    ));
    showToast('${meetSideName()} 팀에 들어갔어요. 달력에 넣어뒀어요');
    _n();
  }

  void meetWarn() {
    meet.warned = true;
    showToast('익명 경고를 보냈어요');
  }

  void meetReset() {
    meet = MeetState();
    meetView = 'find';
    _n();
  }

  // ------------------------------------------------------------ 놀기

  void playPick({String? date, String? time}) {
    if (date != null) play.date = date;
    if (time != null) play.time = time;
    _n();
  }

  void playAct(String v) {
    play.act = v;
    _n();
  }

  void playWho(String v) {
    play.who = v;
    _n();
  }

  void playSetPush(bool v) {
    play.push = v;
    _n();
  }

  void playTogglePick(int i) {
    if (!isMutual(i)) return;
    if (!play.picked.add(i)) play.picked.remove(i);
    _n();
  }

  bool playJoined(String id) => events.any((e) => e.id == 'play-$id');

  /// 받은 놀기 신청 중 맞팔한 사람이 올린 것만 (글쓴이 기준)
  List<PlayPost> playInbox() => kPlays.where((x) => isMutual(x.by.first) && !playJoined(x.id)).toList();

  /// 받은 놀기 신청에 참여
  void playJoin(String id) {
    if (playJoined(id)) return;
    final x = kPlays.firstWhere((p) => p.id == id);
    events.add(Ev(id: 'play-$id', key: x.key ?? kToday, t: x.time, end: x.end, type: 'meet', title: x.title, sub: '놀기 · 참여 확정', mine: true));
    showBanner(BannerData(t: 'class', ic: 'film', k: '놀기 매칭', title: '같이 갈 사람이 모였어요', body: '${x.when} · ${x.title}', cta: '내 약속 보기', go: 'plans'));
  }

  /// 놀 친구 구하기
  void playSubmit() {
    final mutual = mutuals();
    if (play.who == 'pick' && !play.picked.any(isMutual)) {
      showToast(mutual.isEmpty ? '맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요' : '같이 놀 맞팔 친구를 골라주세요');
      return;
    }
    if (play.who == 'all' && mutual.isEmpty) {
      showToast('맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요');
      return;
    }
    final place = playPlaceC.text.trim();
    final act = kActs.firstWhere((a) => a.$1 == play.act);
    final to = play.who == 'pick' ? play.picked.where(isMutual).length : (play.who == 'all' ? mutual.length : 0);
    final toText = to == 0 ? '' : ' · 맞팔 친구 $to명에게 보냈어요';
    events.add(Ev(
      id: 'e${_uid++}',
      key: play.date,
      t: play.time,
      end: fromMin(toMin(play.time) + 120),
      type: 'meet',
      title: '${act.$2} 같이 가요',
      sub: '${place.isEmpty ? '놀기 · 내가 올린 모임' : '놀기 · 내가 올린 모임 · $place'}$toText',
      mine: true,
    ));
    play.view = 'done';
    playPlaceC.clear();
    _n();
  }

  void playBackToList() {
    play = PlayState();
    _n();
  }

  // ------------------------------------------------------------ 푸시 · 배너

  void showPush() {
    push = true;
    _n();
  }

  void hidePush() {
    push = false;
    _n();
  }

  void pushYes() {
    push = false;
    sel = kToday;
    if (!events.any((e) => e.id == 'push-meal')) {
      events.add(Ev(id: 'push-meal', key: kToday, t: '12:30', end: '13:00', type: 'meet', title: '밥약', sub: '익명의 맞팔 친구와', mine: true));
    }
    open('cal');
    showBanner(const BannerData(t: 'job', ic: 'utensils', k: '밥약 확정', title: '12:30 밥약이 달력에 들어갔어요', body: '수락하면 서로 이름이 공개돼요'));
  }

  void closeBanner() {
    banner = null;
    _n();
  }

  void bannerGo(String g) {
    banner = null;
    open(g);
  }

  /// 화면 뒤에서 바뀐 값을 화면에 알려줘요 (시트 안에서 쓰는 도우미)
  void refresh() => _n();

  @override
  void dispose() {
    _toastT?.cancel();
    _bannerT?.cancel();
    _searchT?.cancel();
    idC.dispose();
    pwC.dispose();
    signNameC.dispose();
    signNoC.dispose();
    signDeptC.dispose();
    mealMsgC.dispose();
    addTitleC.dispose();
    addDateC.dispose();
    addNewC.dispose();
    reqMsgC.dispose();
    meetPlaceC.dispose();
    meetNoteC.dispose();
    playPlaceC.dispose();
    super.dispose();
  }
}

/// 앱 어디서든 쓰는 상태 하나
final AppState app = AppState();
