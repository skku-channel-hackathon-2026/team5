/// 앱 이름 · 예시 데이터 · 날짜/시간 도우미가 모여 있는 파일이에요.
/// 화면에 나오는 이름, 일정, 공지는 모두 예시예요. 여기서 고치면 앱 전체에 반영돼요.

const String kAppName = 'mate';

/// 데모 기준일: 2026-09-21 (월). 날짜는 'M-D' 글자로 다뤄요. 예) '9-21'
const String kToday = '9-21';
const List<String> kDayN = ['월', '화', '수', '목', '금', '토', '일'];
const List<int> kWeek = [21, 22, 23, 24, 25, 26, 27];

/// 일정 목록의 작은 알약에 쓰는 짧은 이름
const Map<String, String> kTypeShort = {
  'class': '시간표',
  'assign': '과제',
  'job': '개인',
  'meet': '약속',
  'dept': '학과',
  'opp': '기회',
};

/// 필터 · 일정 종류 (id, 이름)
const List<(String, String)> kBaseTypes = [
  ('class', '시간표'),
  ('assign', '과제'),
  ('job', '개인 일정'),
  ('meet', '약속'),
  ('dept', '학과 일정'),
  ('opp', '기회'),
];
const int kMaxCustom = 6;

/// 추천 분야
const Map<String, String> kCats = {
  'edu': '비교과',
  'schol': '장학금',
  'lab': '산학협력',
  'vol': '봉사활동',
  'club': '동아리',
  'etc': '기타',
};
const List<String> kFields = ['개발·IT', '디자인', '경영·마케팅', '연구·실험', '공연·예술', '취업·진로'];

/// 추천 소식. url 을 누르면 그 사이트가 열려요.
/// [whenKind]: deadline(마감) · event(행사 당일) · posted(제목에 날짜 없음)
class Opp {
  final String id, url, cat, g, src, title, key, t, meta;
  final List<String> fields;
  final String whenKind;
  const Opp(this.id, this.url, this.cat, this.g, this.src, this.title, this.key, this.t, this.meta, this.fields, {this.whenKind = 'deadline'});
}

const List<Opp> kOpps = [
  Opp('o1', 'https://cse.skku.edu/cse/notice.do', 'edu', 'dept', '학과 홈페이지', '신입생 진로탐색 특강', '9-25', '18:00', '선착순 40명', ['취업·진로'], whenKind: 'event'),
  Opp('o2', 'https://www.skku.edu/skku/campus/skk_comm/notice06.do', 'schol', 'school', '학교 홈페이지', '교내 장학금 신청 안내', '9-25', '17:00', '성적·소득 기준 확인', []),
  Opp('o3', 'https://ranbiz.skku.edu/?p=21', 'lab', 'school', '산학협력단', '산학협력 프로젝트 모집', '9-25', '23:59', '팀 또는 개인 지원', ['개발·IT', '연구·실험']),
  Opp('o4', 'https://cse.skku.edu/cse/notice.do', 'edu', 'dept', '소프트웨어학과', 'AI 아이디어톤 참가팀 모집', '9-27', '23:59', '팀 구성 필수', ['개발·IT']),
  Opp('o5', 'https://www.skku.edu/skku/campus/skk_comm/notice01.do', 'vol', 'school', '학교 홈페이지', '지역 아동센터 교육 봉사자 모집', '9-28', '17:00', '주 1회 · 교육 멘토링', []),
  Opp('o7', 'https://www.skku.edu/skku/campus/skk_comm/notice01.do', 'edu', 'school', '학교 홈페이지', '인문학 특강 시리즈', '10-1', '14:00', '전 학년 · 오프라인 특강', [], whenKind: 'event'),
  Opp('o6', 'https://everytime.kr', 'club', 'etta', '에타', '해커톤 팀원 모집', '9-22', '23:59', '디자이너·기획자 환영', ['개발·IT', '디자인']),
];

/// 가입한 학생 (데모용). 밥약 · 놀기는 서로 팔로우한(맞팔) 사람끼리만 이어져요.
/// 과팅은 팔로우와 상관없이 가입한 모든 학생이 대상이에요.
class Friend {
  final String n, d, t; // 이름, 학과·학번, 색 종류
  final String s; // 짧은 학과 이름 (과팅 카드용)
  final int y; // 학번 두 자리
  final String no; // 학번 전체 (검색용)
  final bool followsMe; // 상대가 나를 팔로우하고 있는지
  const Friend(this.n, this.d, this.t, this.s, this.y, this.no, {this.followsMe = true});

  /// 학과 이름만 (d 에서 학번 두 자리를 뺀 것)
  String get dept => d.replaceAll(RegExp(r'\s*\d+$'), '');
}

const List<Friend> kFriends = [
  Friend('김민준', '컴퓨터공학 26', 'class', '컴공', 26, '2026110231'),
  Friend('이서연', '경영학 26', 'meet', '경영', 26, '2026210417'),
  Friend('박지훈', '전자전기공학 26', 'job', '전전', 26, '2026310528', followsMe: false), // 내가 팔로우만 한 사람
  Friend('낙빈', '스포츠과학 24', 'dept', '스과', 24, '2024410163'),
  Friend('최유나', '간호학 25', 'opp', '간호', 25, '2025510372'), // 나를 팔로우했지만 내가 아직 안 한 사람
  Friend('한지우', '컴퓨터공학 26', 'assign', '컴공', 26, '2026110774'), // 나를 팔로우했지만 내가 아직 안 한 사람
  Friend('정하늘', '소프트웨어 26', 'class', '소프트', 26, '2026120845', followsMe: false),
  Friend('윤도현', '화학공학 25', 'job', '화공', 25, '2025320916', followsMe: false),
  Friend('강예린', '생명과학 25', 'meet', '생명', 25, '2025610259', followsMe: false),
  Friend('송재원', '경영학 24', 'dept', '경영', 24, '2024210688', followsMe: false),
  Friend('오나은', '소프트웨어 26', 'opp', '소프트', 26, '2026120319', followsMe: false),
];

/// 처음에 내가 팔로우하고 있는 사람 (kFriends 번호)
const Set<int> kFollowingSeed = {0, 1, 2, 3};

/// 밥약 찾기 · 내 친구가 보낸 밥약
class MealReq {
  final String id, time, title, place, msg;
  final int by; // 보낸 사람 (kFriends 번호)
  const MealReq(this.id, this.time, this.title, this.place, this.msg, this.by);
}

const List<MealReq> kMealReqs = [
  MealReq('r1', '12:00', '학식', '공학관', '한식 먹으러', 0),
  MealReq('r2', '12:30', '돈까스', '인문관', '밥먹을 사람', 4),
];

/// 밥약 찾기 · 랜덤 매칭
class RandMeal {
  final String id, time, msg;
  final int by; // 랜덤으로 이어질 사람 (kFriends 번호, 맞팔한 사람만 보여요)
  const RandMeal(this.id, this.time, this.msg, this.by);
  String get name => kFriends[by].n;
  String get dept => '${kFriends[by].d}학번';
}

const List<RandMeal> kRandMeals = [
  RandMeal('q1', '12:30', '돈까스 좋아해요', 3),
];

/// 과팅 찾기 · 올라온 과팅 (m: 남자 팀원, f: 여자 팀원 — (짧은 학과, 학번))
class MeetPost {
  final String id, key, time, place, size, note;
  final List<(String, int)> m, f;
  final bool mine;
  const MeetPost(this.id, this.key, this.time, this.place, this.size, this.m, this.f, {this.mine = false, this.note = ''});
}

const List<MeetPost> kMeetSeed = [
  MeetPost('m1', '9-21', '18:00', '학생회관', '3:3', [('스과', 24), ('스과', 24), ('스과', 25)], [('생명', 25)]),
  MeetPost('m2', '9-22', '19:00', '실내체육관', '3:3', [('소프트', 26), ('소프트', 26), ('소프트', 26)], []),
];

/// 놀기 · 어떤 걸 할까요? (id, 이름, 아이콘)
const List<(String, String, String)> kActs = [
  ('cafe', '카페', 'cafe'),
  ('movie', '영화', 'film'),
  ('gym', '운동', 'gym'),
  ('pc', 'PC방', 'pc'),
  ('beer', '술', 'beer'),
  ('etc', '기타', 'more'),
];

class PlayPost {
  final String id, title, when, who, time, end;
  final String? key;
  final List<int> by; // 올린 사람들 (kFriends 번호). 첫 번째가 글쓴이예요.
  const PlayPost(this.id, this.title, this.when, this.who, this.by, this.time, this.end, [this.key]);
  List<String> get names => [for (final i in by) kFriends[i].n[0]];
}

const List<PlayPost> kPlays = [
  PlayPost('p1', '영화 보러 갈 사람?', '오늘 20:00', '2~4명 · 익명 가능', [0, 1], '20:00', '22:30'),
  PlayPost('p2', '보드게임 카페 가실 분', '토 9/26 15:00', '3~5명 · 같은 학교', [3], '15:00', '17:00', '9-26'),
  PlayPost('p3', '카페 가서 수다 떨 사람', '일 9/27 14:00', '2~3명 · 맞팔 친구', [4], '14:00', '16:00', '9-27'),
];

/// 달력 일정 하나
class Ev {
  final String id, key, t, end, type, title, sub;
  final bool mine;
  final double? hours;
  final String? src, cat, g, oppId;
  Ev({
    required this.id,
    required this.key,
    required this.t,
    required this.end,
    required this.type,
    required this.title,
    required this.sub,
    this.mine = false,
    this.hours,
    this.src,
    this.cat,
    this.g,
    this.oppId,
  });

  /// 일부만 바꾼 새 일정을 만들어요 (시간표 · 과제 · 직접 만든 일정 모두 고칠 수 있어요).
  /// hours 는 알바 같은 '개인 일정'의 시간 수예요. clearHours 를 켜면 비워요.
  Ev copyWith({String? key, String? t, String? end, String? type, String? title, String? sub, double? hours, bool clearHours = false}) => Ev(
        id: id,
        key: key ?? this.key,
        t: t ?? this.t,
        end: end ?? this.end,
        type: type ?? this.type,
        title: title ?? this.title,
        sub: sub ?? this.sub,
        mine: mine,
        hours: clearHours ? null : (hours ?? this.hours),
        src: src,
        cat: cat,
        g: g,
        oppId: oppId,
      );
}

/// 직접 만든 일정 종류
class CustomType {
  final String id, name;
  final int p; // 색 번호 (0~5)
  CustomType(this.id, this.name, this.p);
}

// ---------------------------------------------------------------- 날짜·시간 도우미

int monthOf(String key) => int.parse(key.split('-')[0]);

int daysInMonth(int month) => DateTime.utc(2026, month + 1, 0).day;

String dateKey(DateTime d) => '${d.month}-${d.day}';

DateTime dateOf(String key) {
  final p = key.split('-');
  return DateTime.utc(2026, int.parse(p[0]), int.parse(p[1]));
}

int dowOf(String key) {
  return dateOf(key).weekday - 1; // 월=0 … 일=6
}

int dayOf(String key) => int.parse(key.split('-')[1]);

/// [key] 가 속한 주(월~일)의 날짜 키
List<String> weekKeys(String key) {
  final d = dateOf(key);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return [for (var i = 0; i < 7; i++) dateKey(monday.add(Duration(days: i)))];
}

int diffDays(String key) {
  final p = key.split('-');
  return DateTime.utc(2026, int.parse(p[0]), int.parse(p[1])).difference(DateTime.utc(2026, 9, 21)).inDays;
}

String dayLabel(String key) => '${dayOf(key)}일 ${kDayN[dowOf(key)]}요일';

String ddayText(String key) {
  final n = diffDays(key);
  return n == 0 ? 'D-DAY' : (n > 0 ? 'D-$n' : 'D+${n.abs()}');
}

String shortDate(String key) {
  final p = key.split('-');
  return '${p[0]}/${p[1]} (${kDayN[dowOf(key)]})';
}

/// 추천 카드·토스트에 쓰는 "9/30 18:00 행사" / "10/13 마감"
String whenPhrase(Opp o) {
  final showTime = o.t.isNotEmpty && o.t != '23:59';
  final clock = showTime ? ' ${o.t}' : (o.whenKind == 'deadline' ? ' 자정' : '');
  switch (o.whenKind) {
    case 'event':
      return '${shortDate(o.key)}$clock 행사';
    case 'posted':
      return '${shortDate(o.key)} 기준';
    default:
      return '${shortDate(o.key)}$clock 마감';
  }
}

int toMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String fromMin(int n) {
  final v = n.clamp(0, 1440);
  return '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';
}

List<String> timeOpts(String a, String b) {
  final o = <String>[];
  for (var n = toMin(a); n <= toMin(b); n += 30) {
    o.add(fromMin(n));
  }
  return o;
}

double hoursBetween(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final d = (toMin(b) - toMin(a)) / 60;
  return d < 0 ? 0 : d;
}

String fmtH(double h) {
  final r = (h * 2).round() / 2;
  return r == r.roundToDouble() ? r.round().toString() : r.toString();
}

/// "9/28", "9-28", "28", "0928", "9월 28일" 처럼 친 글자를 'M-D' 로 바꿔요. 9월이 아니면 null.
String? parseSeptDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final nums = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).toList();
  int? month, day;
  if (nums.length >= 2) {
    month = int.tryParse(nums[nums.length - 2]);
    day = int.tryParse(nums[nums.length - 1]);
  } else if (nums.length == 1) {
    final d = nums[0];
    if (d.length <= 2) {
      month = 9;
      day = int.tryParse(d);
    } else if (d.length == 3) {
      month = int.tryParse(d.substring(0, 1));
      day = int.tryParse(d.substring(1));
    } else if (d.length == 4) {
      month = int.tryParse(d.substring(0, 2));
      day = int.tryParse(d.substring(2));
    }
  }
  if (month != 9 || day == null || day < 1 || day > 30) return null;
  return '9-$day';
}

/// 스크롤 칸에 쓰는 날짜 글자. 예) "오늘 9/21 (월)", "9/22 (화)"
String wheelDate(String key) {
  final p = key.split('-');
  return '${key == kToday ? '오늘 ' : ''}${p[0]}/${p[1]} (${kDayN[dowOf(key)]})';
}

/// 오늘부터 n일치 날짜 키 (9월 30일까지)
List<String> nextDays(int n) {
  final out = <String>[];
  for (var i = 0; i < n; i++) {
    final d = 21 + i;
    if (d > 30) break;
    out.add('9-$d');
  }
  return out;
}
