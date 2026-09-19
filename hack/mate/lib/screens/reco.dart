import 'package:flutter/material.dart';

import '../data.dart';
import '../feeds.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 추천 탭: 학부생에게 필요한 소식을 모아 보여주고, 누르면 달력에 마감일·행사 당일이 들어가요.
/// 소프트 학부·소프트웨어융합대학 공지와 학교 장학/비교과를 가져와요.

const Map<String, String> _catStyle = {'schol': 'job', 'lab': 'class', 'vol': 'meet', 'club': 'dept', 'etc': 'opp'};

class RecoScreen extends LiveView {
  const RecoScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final list = app.recoList();
    final srcs = app.feedLine();
    final allAdded = list.isNotEmpty && list.every((o) => app.isAdded(o.id));

    return Column(children: [
      SafeArea(
        bottom: false,
        child: BackHeader(
          '',
          titleWidget: Text('추천', style: disp(32, pal(context).ink, height: 1.2)),
          actions: [
            Semantics(
              button: true,
              label: '소식 새로고침',
              child: InkWell(
                onTap: app.syncing ? null : () => app.syncFeeds(),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: app.syncing
                      ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, color: pal(context).pri))
                      : Icon(icon('refresh'), color: pal(context).ink),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Body(children: [
          Txt(srcs, size: 13, muted: true),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionHead('달력에 띄울 분야', trailing: '눌러서 켜고 끄기'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final e in kCats.entries) ...[
                  _CatChip(label: e.value, on: app.cats[e.key] ?? false, onTap: () => app.toggleCat(e.key)),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ]),
          if (allAdded) const AiCard(ic: 'check', center: true, child: Txt('지금 나온 소식은 모두 달력에 추가했어요.')),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionHead('둘러보세요', trailing: '+ 누르면 마감일·행사 당일이 달력에 들어가요'),
            const SizedBox(height: 10),
            ...gapped([for (final o in list) _OppRow(o: o)], 10),
            if (list.isEmpty)
              AppCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Txt('켜둔 분야가 없어요. 위에서 하나 이상 켜주세요.', muted: true, align: TextAlign.center))),
          ]),
        ]),
      ),
    ]);
  }
}

class _RoundBtn extends StatelessWidget {
  final String ic, kind; // kind: line | pri | on
  final String label;
  final VoidCallback onTap;
  final double size;
  const _RoundBtn({required this.ic, required this.kind, required this.label, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final bg = kind == 'pri' ? p.pri : (kind == 'on' ? p.priSoft : p.surface);
    final fg = kind == 'pri' ? p.priInk : (kind == 'on' ? p.pri : p.ink);
    final bd = kind == 'pri' ? p.pri : (kind == 'on' ? p.priLine : p.line);
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: bd)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Icon(icon(ic), size: size * 0.5, color: fg)),
        ),
      ),
    );
  }
}

class _OppRow extends StatelessWidget {
  final Opp o;
  const _OppRow({required this.o});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final on = app.isAdded(o.id);
    final f = app.fieldMatch(o);
    final ts = p.types[_catStyle[o.cat] ?? 'opp'];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: () => openUrl(articleUrl(o)),
            borderRadius: BorderRadius.circular(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Pill(kCats[o.cat] ?? '기타', style: ts),
                Text(o.src, style: TextStyle(fontSize: 12, color: p.mut)),
                Text(ddayText(o.key), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.types['assign']!.ink)),
              ]),
              const SizedBox(height: 5),
              Text.rich(TextSpan(children: [
                TextSpan(text: o.title),
                const TextSpan(text: ' '),
                WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(icon('ext'), size: 14, color: p.mut)),
              ]), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4, color: p.ink)),
              const SizedBox(height: 5),
              Text.rich(TextSpan(children: [
                TextSpan(text: '${whenPhrase(o)} · ${o.meta}'),
                if (f != null) TextSpan(text: ' · $f 관심사', style: TextStyle(color: p.priText, fontWeight: FontWeight.w700)),
              ]), style: TextStyle(fontSize: 12, color: p.mut)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _RoundBtn(size: 48, ic: 'share', kind: 'line', label: '${o.title} 공지 원문 열기', onTap: () => openUrl(articleUrl(o))),
          const SizedBox(height: 6),
          _RoundBtn(size: 60, ic: on ? 'check' : 'plus', kind: on ? 'on' : 'pri', label: '${on ? '달력에서 빼기' : '달력에 추가'}: ${o.title}', onTap: () => app.toggleOpp(o.id)),
        ]),
      ]),
    );
  }
}

/// "달력에 띄울 분야" 알약 칩 (시안: 체크 표시 + 연한 초록)
class _CatChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? p.priSoft : p.surface,
        shape: StadiumBorder(side: BorderSide(color: on ? p.priSoft : p.line)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (on) ...[Icon(icon('check'), size: 22, color: p.priText), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: on ? p.priText : p.mut)),
            ]),
          ),
        ),
      ),
    );
  }
}
