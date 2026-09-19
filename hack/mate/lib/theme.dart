import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// 색 · 글꼴 · 아이콘을 한곳에 모아둔 파일이에요.
/// 색을 바꾸고 싶으면 아래 Pal.light / Pal.dark 의 값을 고치면 돼요.

Color _c(int rgb) => Color(0xFF000000 | rgb);

/// 일정 종류 하나의 색 (c: 진한 색, bg: 배경색, ink: 글자색)
class TS {
  final Color c, bg, ink;
  const TS(this.c, this.bg, this.ink);
}

class Pal {
  final Color paper, surface, tint, ink, mut, line, seg, blob;
  final Color pri, priInk, priSoft, priLine, priText;
  final Color featBg, featInk, featMut, featBtn, featBtnInk;
  final Color blue, blueBg, pink, pinkBg;
  final Color danger, lock;
  final Map<String, TS> types;
  final List<TS> custom;

  const Pal({
    required this.paper,
    required this.surface,
    required this.tint,
    required this.ink,
    required this.mut,
    required this.line,
    required this.seg,
    required this.blob,
    required this.pri,
    required this.priInk,
    required this.priSoft,
    required this.priLine,
    required this.priText,
    required this.featBg,
    required this.featInk,
    required this.featMut,
    required this.featBtn,
    required this.featBtnInk,
    required this.blue,
    required this.blueBg,
    required this.pink,
    required this.pinkBg,
    required this.danger,
    required this.lock,
    required this.types,
    required this.custom,
  });

  static final Pal light = Pal(
    paper: _c(0xFBFBF6),
    surface: _c(0xFFFFFF),
    tint: _c(0xEEF6F0),
    ink: _c(0x17301F),
    mut: _c(0x66766D),
    line: _c(0xE0E8E2),
    seg: _c(0xE8F0EA),
    blob: _c(0xE3F1E7),
    pri: _c(0x3A7B58),
    priInk: _c(0xFFFFFF),
    priSoft: _c(0xDCEFE3),
    priLine: _c(0x86BB9C),
    priText: _c(0x1F4D37),
    featBg: _c(0x2F6B4D),
    featInk: _c(0xFFFFFF),
    featMut: _c(0xD3E9DC),
    featBtn: _c(0xFFFFFF),
    featBtnInk: _c(0x1F4D37),
    blue: _c(0x1F4E9E),
    blueBg: _c(0xEAF0FD),
    pink: _c(0xB8264F),
    pinkBg: _c(0xFDEFF2),
    danger: _c(0xB4381F),
    lock: _c(0x123B2A),
    types: {
      'class': TS(_c(0x2F62D6), _c(0xE5ECFB), _c(0x1D3F94)),
      'assign': TS(_c(0xC4452C), _c(0xFBE8E2), _c(0x8F2E18)),
      'job': TS(_c(0xB7791F), _c(0xFAEFD7), _c(0x6B4A0F)),
      'meet': TS(_c(0x8A47B8), _c(0xF0E6F8), _c(0x5C2A80)),
      'dept': TS(_c(0x4B5563), _c(0xE9ECEF), _c(0x333B47)),
      'opp': TS(_c(0x2F7A55), _c(0xDCEFE3), _c(0x1F4D37)),
    },
    custom: [
      TS(_c(0x0E8A8A), _c(0xDDF1F1), _c(0x0B5C5C)),
      TS(_c(0xC2457D), _c(0xFBE4EE), _c(0x862A55)),
      TS(_c(0x6E8B1F), _c(0xEDF3D9), _c(0x465A0F)),
      TS(_c(0x5B4BD6), _c(0xE9E6FB), _c(0x3B2E96)),
      TS(_c(0xD9601F), _c(0xFCE9DC), _c(0x8F3E0F)),
      TS(_c(0x2A8FBF), _c(0xDFF0F8), _c(0x17607F)),
    ],
  );

  static final Pal dark = Pal(
    paper: _c(0x0F1612),
    surface: _c(0x18211B),
    tint: _c(0x1A261F),
    ink: _c(0xE8F0EB),
    mut: _c(0x9DABA4),
    line: _c(0x26332B),
    seg: _c(0x212D25),
    blob: _c(0x15251C),
    pri: _c(0x56C795),
    priInk: _c(0x062015),
    priSoft: _c(0x1B3327),
    priLine: _c(0x2F6449),
    priText: _c(0xBFE8D3),
    featBg: _c(0x1D4A34),
    featInk: _c(0xF2FAF5),
    featMut: _c(0xB5D3C2),
    featBtn: _c(0xE8F0EB),
    featBtnInk: _c(0x0F2A1D),
    blue: _c(0x9DBBFF),
    blueBg: _c(0x18223A),
    pink: _c(0xF29BB4),
    pinkBg: _c(0x3A1B27),
    danger: _c(0xF08A72),
    lock: _c(0x0B241A),
    types: {
      'class': TS(_c(0x7AA2FF), _c(0x1A2540), _c(0xB7CBFF)),
      'assign': TS(_c(0xF08A72), _c(0x3A1F19), _c(0xFFC0B0)),
      'job': TS(_c(0xE4B25A), _c(0x3A2E14), _c(0xF6D89B)),
      'meet': TS(_c(0xC79BEA), _c(0x2C1F3A), _c(0xE3C8F7)),
      'dept': TS(_c(0xA8B2BD), _c(0x232A30), _c(0xCDD5DC)),
      'opp': TS(_c(0x56C795), _c(0x1B3327), _c(0xBFE8D3)),
    },
    custom: [
      TS(_c(0x5CCFCF), _c(0x163333), _c(0xB5EBEB)),
      TS(_c(0xF08DB8), _c(0x3A1B29), _c(0xFAC3DC)),
      TS(_c(0xB4D35A), _c(0x29300F), _c(0xD9EBA3)),
      TS(_c(0xA79BFF), _c(0x24204A), _c(0xD0CAFF)),
      TS(_c(0xFFA46B), _c(0x3B2314), _c(0xFFCFAE)),
      TS(_c(0x6CC3EE), _c(0x15303D), _c(0xB5E2F7)),
    ],
  );

  static Pal of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark ? dark : light;
}

/// 제목용 굵은 글자. 시안처럼 폰 기본 글꼴의 굵은 글씨를 써요.
TextStyle disp(double size, Color color, {double height = 1.25}) =>
    TextStyle(fontSize: size, color: color, height: height, fontWeight: FontWeight.w800, letterSpacing: -0.4);

/// 로고("Mate") 전용 손글씨 느낌 글꼴(주아체)
TextStyle logoStyle(double size, Color color) =>
    TextStyle(fontFamily: 'Jua', fontSize: size, color: color, height: 1.0, letterSpacing: 0.5);

ThemeData buildTheme(Pal p, Brightness b) {
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme.fromSeed(seedColor: p.pri, brightness: b).copyWith(
      primary: p.pri,
      onPrimary: p.priInk,
      surface: p.surface,
      onSurface: p.ink,
    ),
    scaffoldBackgroundColor: p.paper,
    canvasColor: p.paper,
    splashFactory: InkRipple.splashFactory,
    textTheme: Typography.material2021(platform: defaultTargetPlatform).black.apply(bodyColor: p.ink, displayColor: p.ink),
  );
}

/// 이름으로 아이콘을 찾아요.
IconData icon(String name) {
  switch (name) {
    case 'bell':
      return Icons.notifications_none;
    case 'bellOn':
      return Icons.notifications_active_outlined;
    case 'bellOff':
      return Icons.notifications_off_outlined;
    case 'leaf':
      return Icons.eco_outlined;
    case 'sparkle':
      return Icons.auto_awesome_outlined;
    case 'calendar':
      return Icons.calendar_month_outlined;
    case 'users':
      return Icons.groups_outlined;
    case 'utensils':
      return Icons.restaurant;
    case 'heart':
      return Icons.favorite_border;
    case 'film':
      return Icons.movie_outlined;
    case 'plus':
      return Icons.add;
    case 'plusCircle':
      return Icons.add_circle_outline;
    case 'check':
      return Icons.check;
    case 'back':
      return Icons.chevron_left;
    case 'chev':
      return Icons.chevron_right;
    case 'ext':
      return Icons.open_in_new;
    case 'share':
      return Icons.ios_share;
    case 'camera':
      return Icons.photo_camera_outlined;
    case 'shield':
      return Icons.shield_outlined;
    case 'idcard':
      return Icons.badge_outlined;
    case 'x':
      return Icons.close;
    case 'user':
      return Icons.person_outline;
    case 'clock':
      return Icons.schedule;
    case 'pin':
      return Icons.place_outlined;
    case 'chat':
      return Icons.chat_bubble_outline;
    case 'mask':
      return Icons.theater_comedy_outlined;
    case 'pencil':
      return Icons.edit_outlined;
    case 'gamepad':
      return Icons.sports_esports_outlined;
    case 'cafe':
      return Icons.local_cafe_outlined;
    case 'beer':
      return Icons.sports_bar_outlined;
    case 'gym':
      return Icons.fitness_center;
    case 'pc':
      return Icons.desktop_windows_outlined;
    case 'more':
      return Icons.more_horiz;
    case 'mail':
      return Icons.mail_outline;
    case 'lock':
      return Icons.lock_outline;
    case 'eye':
      return Icons.visibility_outlined;
    case 'eyeOff':
      return Icons.visibility_off_outlined;
    case 'logout':
      return Icons.logout;
    case 'school':
      return Icons.school_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'star':
      return Icons.star_border;
    case 'note':
      return Icons.sticky_note_2_outlined;
    case 'search':
      return Icons.search;
    case 'refresh':
      return Icons.refresh;
    case 'image':
      return Icons.image_outlined;
    default:
      return Icons.circle_outlined;
  }
}
