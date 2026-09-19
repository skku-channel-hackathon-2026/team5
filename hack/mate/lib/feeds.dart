import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'data.dart';

/// 아이캠퍼스 · 학교/학과/단대 홈페이지 · 에브리타임에서 소식을 가져오는 층이에요.
///
/// 소프트웨어학과 **학부생**에게 필요한 글만 남깁니다.
/// 대학원 공지·교수 채용·영어 세미나 포스터는 빼요.
///
/// - 학교·학과·소프트웨어융합대학: 로그인 없이 볼 수 있는 HTML을 읽어요.
/// - 아이캠퍼스·에브리타임: 공식 공개 API가 없어서 같은 JSON 계약의 예시를 써요.

class FeedBoard {
  final String url, label;
  const FeedBoard(this.url, this.label);

  String get baseUrl {
    final u = Uri.parse(url);
    return '${u.scheme}://${u.host}${u.path}';
  }
}

class FeedDef {
  final String id, name, sub;
  final bool needsLogin;
  final List<FeedBoard> boards;
  final String snapshotAsset;
  const FeedDef({
    required this.id,
    required this.name,
    required this.sub,
    required this.needsLogin,
    required this.snapshotAsset,
    this.boards = const [],
  });

  bool get canFetchLive => boards.isNotEmpty && !needsLogin;
}

/// 관심사 고르기 · 내 정보에서 같이 쓰는 목록
const List<FeedDef> kFeedSources = [
  FeedDef(
    id: 'icampus',
    name: '아이캠퍼스',
    sub: '학부 시간표·과제는 킹고 로그인이 필요해요. 지금은 연동 전 예시를 써요.',
    needsLogin: true,
    snapshotAsset: 'assets/feeds/icampus.json',
  ),
  FeedDef(
    id: 'school',
    name: '학교 홈페이지',
    sub: '학부생 장학·비교과·공모만 가져와요. 대학원·조교 공지는 빼요.',
    needsLogin: false,
    snapshotAsset: 'assets/feeds/school.json',
    boards: [
      FeedBoard('https://www.skku.edu/skku/campus/skk_comm/notice01.do?mode=list&articleLimit=20', '학교 공지'),
      FeedBoard('https://www.skku.edu/skku/campus/skk_comm/notice06.do?mode=list&articleLimit=20', '학교 장학'),
    ],
  ),
  FeedDef(
    id: 'dept',
    name: '학과 홈페이지',
    sub: '소프트 학부 공지·취업·학부연구생·공모전만 가져와요.',
    needsLogin: false,
    snapshotAsset: 'assets/feeds/dept.json',
    boards: [
      FeedBoard('https://cse.skku.edu/cse/notice.do?mode=list&articleLimit=20', '학부 공지'),
      FeedBoard('https://cse.skku.edu/cse/notice_job.do?mode=list&articleLimit=20', '취업·인턴'),
      FeedBoard('https://cse.skku.edu/cse/notice_recruit.do?mode=list&articleLimit=20', '학부연구생'),
      FeedBoard('https://cse.skku.edu/cse/notice_senimar.do?mode=list&articleLimit=20', '공모전·대회'),
    ],
  ),
  FeedDef(
    id: 'college',
    name: '소프트웨어융합대학',
    sub: '단대 학부 공지·산학·비교과만 가져와요. 대학원 게시판은 읽지 않아요.',
    needsLogin: false,
    snapshotAsset: 'assets/feeds/college.json',
    boards: [
      FeedBoard('https://sw.skku.edu/sw/notice.do?mode=list&articleLimit=20', '학부 공지'),
    ],
  ),
  FeedDef(
    id: 'etta',
    name: '에브리타임',
    sub: '공식 API가 없어요. 로그인 연동 전이라 예시 글만 보여요.',
    needsLogin: true,
    snapshotAsset: 'assets/feeds/etta.json',
  ),
];

FeedDef? feedDef(String id) {
  for (final s in kFeedSources) {
    if (s.id == id) return s;
  }
  return null;
}

/// 게시판에서 읽은 글 한 줄 (아직 앱의 Opp 로 바꾸기 전)
class RawNotice {
  final String id, title, url, posted, categoryRaw;
  const RawNotice({
    required this.id,
    required this.title,
    required this.url,
    required this.posted,
    required this.categoryRaw,
  });
}

class FeedBundle {
  final String sourceId;
  final bool fromNetwork;
  final bool loginPending;
  final List<Opp> opps;
  const FeedBundle({
    required this.sourceId,
    required this.fromNetwork,
    required this.loginPending,
    required this.opps,
  });

  String get status {
    final n = opps.length;
    if (loginPending) return '로그인 연동 전 · 예시 $n건';
    if (fromNetwork) return '학부생 공지 $n건을 방금 가져왔어요';
    return '저장해 둔 학부 공지 $n건 (네트워크가 안 될 때)';
  }
}

// ------------------------------------------------------------------ HTML 파서 · 날짜 · 분류

/// 성균관대 CMS(jwxe) 게시판 HTML에서 글 목록을 뽑아요.
class SkkuBoardParser {
  static List<RawNotice> parse(String html, {required String baseUrl}) {
    final out = <RawNotice>[];
    final seen = <String>{};
    final chunks = html.split('board-list-content-wrap');
    for (var i = 1; i < chunks.length; i++) {
      final block = chunks[i];
      final id = _first(RegExp(r'articleNo=(\d+)'), block);
      if (id == null || !seen.add(id)) continue;
      final cat = _first(RegExp(r'c-board-list-category">\[([^\]]+)\]'), block) ?? '';
      final rawTitle = _first(RegExp(r'title="자세히 보기">([\s\S]*?)</a>'), block);
      if (rawTitle == null) continue;
      final title = _plain(rawTitle);
      if (title.isEmpty) continue;
      final posted = _first(RegExp(r'<li>(20\d{2}-\d{2}-\d{2})</li>'), block) ?? '';
      out.add(RawNotice(
        id: id,
        title: title,
        url: noticeViewUrl(baseUrl, id),
        posted: posted,
        categoryRaw: cat,
      ));
    }
    return out;
  }

  static String? _first(RegExp re, String s) => re.firstMatch(s)?.group(1);

  static String _plain(String raw) {
    var t = raw.replaceAll(RegExp(r'<[^>]+>'), ' ');
    t = t
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#034;', '"')
        .replaceAll('&nbsp;', ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _DateHit {
  final int month, day, start, end;
  final bool deadline;
  final String? time;
  const _DateHit(this.month, this.day, this.start, this.end, this.deadline, this.time);
  String get key => '$month-$day';
}

String? _timeIn(String s) {
  final colon = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
  if (colon != null) return '${colon.group(1)!.padLeft(2, '0')}:${colon.group(2)}';
  final hm = RegExp(r'(\d{1,2})시\s*(\d{1,2})분').firstMatch(s);
  if (hm != null) return '${hm.group(1)!.padLeft(2, '0')}:${hm.group(2)!.padLeft(2, '0')}';
  final h = RegExp(r'(\d{1,2})시').firstMatch(s);
  if (h != null) return '${h.group(1)!.padLeft(2, '0')}:00';
  return null;
}

bool _looksEventNotice(String title) {
  return RegExp(r'설명회|특강|세미나|포럼|개최|강연|워크숍|워크샵|컨퍼런스|만남').hasMatch(title);
}

/// 제목 안의 마감일(~9/22, 10.13까지) 또는 행사 당일(9/30 18:00)을 찾아요. 없으면 게시일.
({String key, String time, String kind}) noticeWhen(String title, String posted) {
  final hits = <_DateHit>[];
  final dateRe = RegExp(r'(?:20\d{2}\s*[.\-/년]\s*)?(\d{1,2})[.\-/월]\s*(\d{1,2})(?:일)?');
  for (final m in dateRe.allMatches(title)) {
    final month = int.tryParse(m.group(1) ?? '');
    final day = int.tryParse(m.group(2) ?? '');
    if (month == null || day == null || month < 1 || month > 12 || day < 1 || day > 31) continue;
    if (title.substring(m.end).startsWith('학기')) continue;
    final before = title.substring((m.start - 10).clamp(0, title.length), m.start);
    final after = title.substring(m.end, (m.end + 14).clamp(0, title.length));
    final deadline = RegExp(r'~|～|까지|마감|기한').hasMatch('$before$after') || RegExp(r'접수|신청').hasMatch(before);
    hits.add(_DateHit(month, day, m.start, m.end, deadline, _timeIn(after)));
  }
  if (hits.isEmpty) {
    return (key: postedToKey(posted) ?? kToday, time: '23:59', kind: 'posted');
  }

  _DateHit pick;
  String kind;
  if (_looksEventNotice(title)) {
    final events = hits.where((h) => !h.deadline).toList();
    if (events.isNotEmpty) {
      pick = events.reversed.firstWhere((h) => h.time != null, orElse: () => events.first);
      kind = 'event';
    } else {
      pick = hits.last;
      kind = 'deadline';
    }
  } else {
    final dues = hits.where((h) => h.deadline).toList();
    pick = dues.isNotEmpty ? dues.last : hits.last;
    kind = 'deadline';
  }
  final time = pick.time ?? (kind == 'event' ? '14:00' : '23:59');
  return (key: pick.key, time: time, kind: kind);
}

String? postedToKey(String posted) {
  final m = RegExp(r'^20\d{2}-(\d{2})-(\d{2})$').firstMatch(posted.trim());
  if (m == null) return null;
  return '${int.parse(m.group(1)!)}-${int.parse(m.group(2)!)}';
}

/// 학부생에게 필요한 글만 true. 대학원·교원·조교·영어 세미나 포스터는 false.
bool keepUndergradNotice(String title, String category) {
  final text = '$category $title';
  if (text.contains('진학설명') || text.contains('학부연구')) return true;
  const drop = [
    '대학원',
    '석사',
    '박사',
    '학위과',
    '일반대학원',
    '전문대학원',
    '법학전문',
    '산학교수',
    '전임교원',
    '교수 채용',
    '중장년',
    '평생대학',
    '행정조교',
    '한마당',
    '오픈랩',
    'BK21',
    '학위수여식',
    'Call for Proposals',
  ];
  for (final d in drop) {
    if (text.contains(d)) return false;
  }
  final ko = RegExp(r'[가-힣]').allMatches(title).length;
  final en = RegExp(r'[A-Za-z]').allMatches(title).length;
  if (en >= 20 && ko < 8) return false;
  return true;
}

/// 데모 기준일(9/21) 근처에 아직 쓸 만한 글인가.
bool isFreshNotice(String title, String posted) {
  if (posted.compareTo('2026-08-01') >= 0) return true;
  if (posted.isEmpty) return true;
  return diffDays(noticeWhen(title, posted).key) >= -3;
}

List<RawNotice> selectUndergradNotices(Iterable<RawNotice> raw) {
  final seen = <String>{};
  final out = <RawNotice>[];
  for (final n in raw) {
    if (!seen.add(n.id)) continue;
    if (!keepUndergradNotice(n.title, n.categoryRaw)) continue;
    if (!isFreshNotice(n.title, n.posted)) continue;
    out.add(n);
  }
  out.sort((a, b) {
    int rank(RawNotice n) {
      final t = '${n.categoryRaw} ${n.title}';
      if (t.contains('학사') || t.contains('졸업')) return 0;
      if (t.contains('장학')) return 1;
      if (t.contains('인턴') || t.contains('공모') || t.contains('대회')) return 2;
      return 3;
    }

    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    return b.posted.compareTo(a.posted);
  });
  if (out.length > 24) return out.sublist(0, 24);
  return out;
}

/// 게시판 글의 원문(그 글 보기) 주소. 목록 페이지가 아니라 articleNo 가 붙은 주소예요.
String noticeViewUrl(String baseUrl, String articleNo) {
  final uri = Uri.parse(baseUrl.replaceAll('&amp;', '&'));
  final path = '${uri.scheme}://${uri.host}${uri.path}';
  return '$path?mode=view&articleNo=$articleNo';
}

String articleUrl(Opp o) {
  final raw = o.url.replaceAll('&amp;', '&');
  if (raw.contains('articleNo=')) return raw;
  final m = RegExp(r'(?:feed-(?:school|dept|college)-)?(\d+)$').firstMatch(o.id);
  if (m == null) return raw;
  final base = o.g == 'dept'
      ? 'https://cse.skku.edu/cse/notice.do'
      : o.g == 'college'
          ? 'https://sw.skku.edu/sw/notice.do'
          : (o.g == 'school' ? 'https://www.skku.edu/skku/campus/skk_comm/notice01.do' : raw);
  if (!base.startsWith('http')) return raw;
  return noticeViewUrl(base, m.group(1)!);
}

String noticeCat(String raw, String title) {
  final t = '$raw $title';
  if (t.contains('장학')) return 'schol';
  if (t.contains('봉사')) return 'vol';
  if (t.contains('동아리')) return 'club';
  if (t.contains('산학') || t.contains('학부연구') || t.contains('학점연계') || t.contains('채용연계')) return 'lab';
  if (RegExp(r'비교과|특강|공모|대회|해커톤|아이디어톤|챌린지|부트캠프|EXPO|엑스포|참가팀|설문|프로그램').hasMatch(t)) return 'edu';
  if (t.contains('인턴')) return 'lab';
  return 'etc';
}

List<String> noticeFields(String title) {
  final out = <String>[];
  if (RegExp(r'AI|IT|개발|프로그래밍|소프트웨어|SW|코딩|엔지니어').hasMatch(title)) out.add('개발·IT');
  if (RegExp(r'디자인').hasMatch(title)) out.add('디자인');
  if (RegExp(r'경영|마케팅').hasMatch(title)) out.add('경영·마케팅');
  if (RegExp(r'채용|인턴|진로|취업|공모|대회').hasMatch(title)) out.add('취업·진로');
  if (RegExp(r'연구|학부연구').hasMatch(title)) out.add('연구·실험');
  return out;
}

String noticeSrcName(String sourceId) {
  switch (sourceId) {
    case 'school':
      return '학교 홈페이지';
    case 'dept':
      return '학과 홈페이지';
    case 'college':
      return '소프트웨어융합대학';
    case 'icampus':
      return '아이캠퍼스';
    case 'etta':
      return '에타';
    default:
      return sourceId;
  }
}

Opp noticeToOpp(RawNotice n, String sourceId) {
  final when = noticeWhen(n.title, n.posted);
  return Opp(
    'feed-$sourceId-${n.id}',
    n.url,
    noticeCat(n.categoryRaw, n.title),
    sourceId,
    noticeSrcName(sourceId),
    n.title,
    when.key,
    when.time,
    n.categoryRaw.isEmpty ? '학부 공지' : n.categoryRaw,
    noticeFields(n.title),
    whenKind: when.kind,
  );
}

// ------------------------------------------------------------------ JSON 스냅샷

class SnapshotDoc {
  final String sourceId;
  final bool loginRequired;
  final List<Opp> opps;
  const SnapshotDoc({required this.sourceId, required this.loginRequired, required this.opps});
}

SnapshotDoc parseSnapshot(String jsonText) {
  final map = json.decode(jsonText) as Map<String, dynamic>;
  final sourceId = map['sourceId'] as String? ?? '';
  final items = <Opp>[];
  for (final raw in (map['items'] as List? ?? const [])) {
    final m = raw as Map<String, dynamic>;
    final title = m['title'] as String? ?? '';
    final posted = m['posted'] as String? ?? '';
    final catRaw = m['categoryRaw'] as String? ?? '';
    if (!keepUndergradNotice(title, catRaw)) continue;
    final computed = noticeWhen(title, posted);
    final when = m['key'] is String
        ? (
            key: m['key'] as String,
            time: (m['t'] as String?) ?? computed.time,
            kind: (m['whenKind'] as String?) ?? 'deadline',
          )
        : computed;
    final rawId = m['id'] as String? ?? 'x';
    final id = rawId.contains('-') ? rawId : 'feed-$sourceId-$rawId';
    items.add(Opp(
      id,
      m['url'] as String? ?? '',
      (m['cat'] as String?) ?? noticeCat(catRaw, title),
      sourceId,
      noticeSrcName(sourceId),
      title,
      when.key,
      when.time,
      (m['meta'] as String?) ?? (catRaw.isEmpty ? '학부 공지' : catRaw),
      ((m['fields'] as List?) ?? noticeFields(title)).cast<String>(),
      whenKind: when.kind,
    ));
  }
  return SnapshotDoc(sourceId: sourceId, loginRequired: map['loginRequired'] == true, opps: items);
}

// ------------------------------------------------------------------ 가져오기

class FeedClient {
  FeedClient({http.Client? httpClient, this.loadAsset}) : _http = httpClient ?? http.Client();

  /// 위젯 테스트에서는 실제 학교 홈페이지를 치지 않아요.
  static bool allowNetwork = true;

  final http.Client _http;
  final Future<String> Function(String asset)? loadAsset;

  Future<String> _asset(String path) async {
    if (loadAsset != null) return loadAsset!(path);
    return rootBundle.loadString(path);
  }

  Future<String> _getHtml(String url) async {
    final r = await _http
        .get(
          Uri.parse(url),
          headers: const {
            'User-Agent': 'mate-mvp/1.0 (hackathon public notice reader)',
            'Accept': 'text/html',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('status ${r.statusCode}');
    return utf8.decode(r.bodyBytes);
  }

  Future<FeedBundle> load(FeedDef def) async {
    if (def.canFetchLive && allowNetwork) {
      try {
        final chunks = await Future.wait(def.boards.map((b) async {
          try {
            final html = await _getHtml(b.url);
            return SkkuBoardParser.parse(html, baseUrl: b.baseUrl);
          } catch (_) {
            return <RawNotice>[];
          }
        }));
        final notices = selectUndergradNotices(chunks.expand((e) => e));
        if (notices.isNotEmpty) {
          return FeedBundle(
            sourceId: def.id,
            fromNetwork: true,
            loginPending: false,
            opps: [for (final n in notices) noticeToOpp(n, def.id)],
          );
        }
      } catch (_) {
        // 크롬(CORS) · 오프라인이면 스냅샷으로 넘어가요.
      }
    }
    final snap = parseSnapshot(await _asset(def.snapshotAsset));
    return FeedBundle(
      sourceId: def.id,
      fromNetwork: false,
      loginPending: def.needsLogin,
      opps: snap.opps,
    );
  }
}
