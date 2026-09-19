import 'package:flutter/material.dart';

import '../data.dart';
import '../feeds.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 처음 시작: 로그인 · 회원가입(학생증 인증) · 관심사 고르기(딱 한 번)

// ------------------------------------------------------------------ 로그인

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();

  @override
  void dispose() {
    _idFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Backdrop(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Padding(padding: EdgeInsets.only(left: 6), child: UnderTitle('로그인')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [BoxShadow(color: Color(0x141E3A2A), blurRadius: 30, offset: Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(24)),
                  child: const MateLogo(size: 62),
                ),
                const SizedBox(height: 18),
                AppInput(
                  controller: app.idC,
                  focusNode: _idFocus,
                  hint: '학번',
                  prefix: 'school',
                  pill: true,
                  autocorrect: false,
                  keyboardType: TextInputType.visiblePassword,
                  action: TextInputAction.next,
                  onSubmitted: (_) => _pwFocus.requestFocus(),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => AppInput(
                    controller: app.pwC,
                    focusNode: _pwFocus,
                    hint: '비밀번호',
                    prefix: 'lock',
                    pill: true,
                    autocorrect: false,
                    obscure: !app.showPw,
                    keyboardType: TextInputType.visiblePassword,
                    action: TextInputAction.done,
                    onSubmitted: (_) => app.login(),
                    suffix: IconButton(
                      tooltip: app.showPw ? '비밀번호 숨기기' : '비밀번호 보기',
                      onPressed: app.togglePw,
                      icon: Icon(icon(app.showPw ? 'eye' : 'eyeOff'), color: p.mut),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => Semantics(
                    checked: app.autoLogin,
                    label: '자동 로그인',
                    child: InkWell(
                      onTap: app.toggleAuto,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: app.autoLogin ? p.pri : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: app.autoLogin ? p.pri : p.mut, width: 2),
                            ),
                            child: app.autoLogin ? Icon(icon('check'), size: 18, color: p.priInk) : null,
                          ),
                          const SizedBox(width: 10),
                          const Txt('자동 로그인', size: 16),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Btn('로그인', kind: 'mint', onTap: app.login),
                const SizedBox(height: 10),
                Center(child: Btn('회원가입 / 인증', kind: 'soft', small: true, expand: false, onTap: app.toSignup)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 회원가입 · 학생증 인증

class VerifyScreen extends LiveView {
  const VerifyScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final st = app.verify;
    final scanning = st == 'scanning';
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const BackHeader(''),
        Expanded(
          child: Body(padding: EdgeInsets.fromLTRB(22, 0, 22, 24 + MediaQuery.paddingOf(context).bottom), gap: 16, children: [
            Padding(padding: const EdgeInsets.only(top: 4, bottom: 4), child: Text('학생증 한 장이면\n계정이 만들어져요', style: disp(32, p.ink, height: 1.3))),
            _ScanBox(state: st),
            Row(children: [
              Expanded(flex: 3, child: Btn(st == 'done' ? '다시 찍기' : '사진 찍기', ic: 'camera', radius: 18, onTap: scanning ? null : app.verifyShot)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: Btn('앨범', ic: 'image', kind: 'line', radius: 18, onTap: scanning ? null : app.verifyShot)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: p.priSoft, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Icon(icon('shield'), size: 26, color: p.pri),
                const SizedBox(width: 12),
                const Expanded(child: Txt('학과와 학번은 학생증에서 자동으로 입력돼요. 미팅과 과팅에서는 학과·학번만 보여줘요.', size: 14, height: 1.55)),
              ]),
            ),
            Field('이름', child: AppInput(controller: app.signNameC, hint: '이름을 입력해주세요', action: TextInputAction.next)),
            Field(
              '학번',
              child: AppInput(
                controller: app.signNoC,
                hint: '학번을 입력해주세요',
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                action: TextInputAction.next,
              ),
            ),
            Field('학과', child: AppInput(controller: app.signDeptC, hint: '학과를 입력해주세요', action: TextInputAction.done)),
            Field('성별', child: TwoWaySeg(items: const [('male', '남'), ('female', '여')], value: app.gender, onChanged: app.setGender)),
            if (app.signErr.isNotEmpty) Text(app.signErr, textAlign: TextAlign.center, style: TextStyle(color: p.danger, fontSize: 14, fontWeight: FontWeight.w700)),
            Btn('제출', radius: 20, onTap: app.submitSignup),
          ]),
        ),
      ]),
    );
  }
}

class _ScanBox extends StatelessWidget {
  final String state;
  const _ScanBox({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final done = state == 'done';
    Widget inner;
    if (state == 'scanning') {
      inner = const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Spinner(), SizedBox(height: 14), Txt('학생증을 읽고 있어요', bold: true, size: 16)]);
    } else if (done) {
      inner = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 84, height: 84, decoration: BoxDecoration(color: p.priSoft, shape: BoxShape.circle), child: Icon(icon('check'), size: 42, color: p.pri)),
        const SizedBox(height: 14),
        const Txt('학생증 사진이 입력됐어요', bold: true, size: 16),
        const Txt('아래 정보를 확인해주세요', size: 13, muted: true),
      ]);
    } else {
      inner = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 84, height: 84, decoration: BoxDecoration(color: p.priSoft, shape: BoxShape.circle), child: Icon(icon('idcard'), size: 42, color: p.pri)),
        const SizedBox(height: 18),
        const Txt('학생증 사진을 입력해주세요.', bold: true, size: 16),
      ]);
    }
    return DashedBox(
      color: p.priLine,
      child: Container(
        height: 250,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(26)),
        child: inner,
      ),
    );
  }
}

// ------------------------------------------------------------------ 관심사 고르기 (딱 한 번)

class InterestScreen extends LiveView {
  const InterestScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    const src = kFeedSources;
    return Backdrop(
      leaves: false,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          const BackHeader('관심사 고르기'),
          Expanded(
            child: Body(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
              Text('관심사', style: TextStyle(color: p.pri, fontWeight: FontWeight.w700, fontSize: 13)),
              Heading('딱 한 번만 골라요\n나머지는 앱이 해요', size: 30, color: p.ink),
              const Txt('고른 분야의 새 소식이 추천 탭에 모여요.', muted: true, height: 1.6),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Lbl('어떤 소식이 궁금해요?', small: '추천 탭에서 언제든 바꿀 수 있어요'),
                const SizedBox(height: 8),
                ChipWrap(children: [for (final e in kCats.entries) PillChip(e.value, on: app.cats[e.key] ?? false, onTap: () => app.toggleCat(e.key))]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Lbl('관심 분야'),
                const SizedBox(height: 8),
                ChipWrap(children: [for (final f in kFields) PillChip(f, on: app.fields[f] ?? false, onTap: () => app.toggleField(f))]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Lbl('소식을 가져올 곳'),
                const SizedBox(height: 8),
                ...gapped([for (final s in src) SourceCard(s: s)], 8),
              ]),
            ]),
          ),
          CtaBar(children: [
            Btn('시작하기', onTap: app.obDone),
            LinkBtn('나중에 고를게요', onTap: app.obLater),
          ]),
        ]),
      ),
    );
  }
}
