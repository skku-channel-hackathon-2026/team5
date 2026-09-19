import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'screens/onboarding.dart';
import 'screens/calendar.dart';
import 'screens/home.dart';
import 'screens/reco.dart';
import 'screens/social.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// 앱의 큰 틀: 현재 화면 + (달력·추천일 때) 아래 탭 + 위에 뜨는 것들(배너 · 안내 문구 · 받는 사람 화면)
/// 안드로이드 뒤로가기 버튼은 app.back() 이 처리해요 (state.dart).

class Shell extends LiveView {
  const Shell({super.key});

  @override
  Widget body(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;

    Widget page;
    switch (app.screen) {
      case 'login':
        page = const LoginScreen();
        break;
      case 'verify':
        page = const VerifyScreen();
        break;
      case 'interest':
        page = const InterestScreen();
        break;
      case 'cal':
        page = const CalendarScreen();
        break;
      case 'reco':
        page = const RecoScreen();
        break;
      case 'meal':
        page = const MealScreen();
        break;
      case 'meet':
        page = const MeetScreen();
        break;
      case 'play':
        page = const PlayScreen();
        break;
      case 'plans':
        page = const PlansScreen();
        break;
      case 'me':
        page = const MeScreen();
        break;
      default:
        page = const HomeScreen();
    }

    // 아래 탭(달력 · 추천)은 이 두 화면에서만 보여요
    final showTabs = (app.screen == 'cal' || app.screen == 'reco') && !keyboard;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!app.back()) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: Column(children: [
              Expanded(child: MediaQuery.removePadding(context: context, removeBottom: showTabs, child: page)),
              if (showTabs) const BottomTabs(),
            ]),
          ),
          if (app.banner != null) _BannerCard(b: app.banner!),
          if (app.toastMsg.isNotEmpty) _Toast(text: app.toastMsg),
          if (app.push) const _LockPreview(),
        ]),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  final String text;
  const _Toast({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 96 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8))]),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: p.paper, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

/// 화면 위에서 내려오는 알림 배너
class _BannerCard extends StatelessWidget {
  final BannerData b;
  const _BannerCard({required this.b});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final t = p.types[b.t] ?? p.types['opp']!;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 10,
      right: 10,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${b.k}|${b.title}'),
        tween: Tween(begin: -30, end: 0),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        builder: (c, v, child) => Transform.translate(offset: Offset(0, v), child: Opacity(opacity: 1 + v / 30, child: child)),
        child: Material(
          color: p.surface,
          elevation: 10,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: t.bg, shape: BoxShape.circle), child: Icon(icon(b.ic), size: 20, color: t.ink)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.ink)),
                    Text(b.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4, color: p.ink)),
                    Text(b.body, style: TextStyle(fontSize: 12, height: 1.45, color: p.mut)),
                  ]),
                ),
                InkWell(
                  onTap: app.closeBanner,
                  customBorder: const CircleBorder(),
                  child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon('x'), size: 18, color: p.mut)),
                ),
              ]),
              if (b.go.isNotEmpty) ...[
                const SizedBox(height: 10),
                Btn(b.cta, small: true, onTap: () => app.bannerGo(b.go)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// "받는 사람 화면" 미리보기: 폰 잠금화면 위로 푸시가 떠 있는 모습
class _LockPreview extends StatelessWidget {
  const _LockPreview();

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    const ink = Color(0xFF15201B);
    const sub = Color(0xFF55625B);
    const green = Color(0xFF1F6B4A);
    Widget appRow(String ic, String when) => Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(7)), child: Icon(icon(ic), size: 14, color: Colors.white)),
          const SizedBox(width: 8),
          const Text(kAppName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sub)),
          const Spacer(),
          Text(when, style: const TextStyle(fontSize: 12, color: sub)),
        ]);
    final msg = app.meal.msg.isEmpty ? '12:30 같이 밥 먹을래요?' : '“${app.meal.msg}”';
    return Positioned.fill(
      child: Material(
        color: p.lock,
        child: SafeArea(
          child: Stack(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 48, 12, 20),
              child: Column(children: [
                const Text('9월 21일 월요일', style: TextStyle(fontSize: 17, color: Color(0xD9FFFFFF))),
                Text('12:04', style: disp(92, Colors.white, height: 1.1)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xF0FFFFFF), borderRadius: BorderRadius.circular(24)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    appRow('utensils', '지금'),
                    const SizedBox(height: 10),
                    const Text('익명의 새내기가 밥약을 보냈어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4, color: ink)),
                    Text(msg, style: const TextStyle(fontSize: 14, height: 1.5, color: ink)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _LockBtn('좋아요', bg: green, fg: Colors.white, onTap: app.pushYes)),
                      const SizedBox(width: 8),
                      Expanded(child: _LockBtn('다음에', bg: const Color(0xFFE3E7E4), fg: ink, onTap: app.hidePush)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xDBFFFFFF), borderRadius: BorderRadius.circular(24)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    appRow('heart', '5분 전'),
                    const SizedBox(height: 6),
                    const Text('과팅 매칭이 성사됐어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4, color: ink)),
                    const Text('토 9/26 저녁 7–9시 · 상대 팀 3명', style: TextStyle(fontSize: 13, color: sub)),
                  ]),
                ),
                const SizedBox(height: 28),
                const Text('폰 화면 위로 이렇게 떠요 · 위로 밀어서 열기', style: TextStyle(fontSize: 13, color: Color(0xBFFFFFFF))),
              ]),
            ),
            Positioned(
              top: 4,
              right: 8,
              child: InkWell(
                onTap: app.hidePush,
                customBorder: const CircleBorder(),
                child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0x24FFFFFF), shape: BoxShape.circle), child: Icon(icon('x'), color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LockBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _LockBtn(this.label, {required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(height: 44, alignment: Alignment.center, child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: fg))),
      ),
    );
  }
}
