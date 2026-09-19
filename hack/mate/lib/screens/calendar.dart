import 'package:flutter/material.dart';

import '../data.dart';
import '../sheets.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 달력 탭: 주간/월간 보기, 날짜 칸 안의 일정 글씨, AI 건강 챙기기, 그날의 일정, 다가오는 마감

const Map<String, int> _chipOrder = {'assign': 0, 'opp': 1, 'meet': 2, 'job': 3, 'dept': 4, 'class': 5};
double _chipOrd(String t) => (_chipOrder[t] ?? 3.5).toDouble();

class CalendarScreen extends LiveView {
  const CalendarScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final key = app.sel;
    final all = app.eventsOn(key);
    final shown = app.filter == 'all' ? all : all.where((e) => e.type == app.filter).toList();
    final load = app.loadOf(key);
    final ups = app.upcoming();
    final lvlName = ['여유', '보통', '빡빡'][load.lvl];
    final lvlStyle = [TS(p.pri, p.priSoft, p.priText), p.types['job']!, p.types['assign']!][load.lvl];

    return Column(children: [
      SafeArea(
        bottom: false,
        child: BackHeader(
          '',
          titleWidget: Text.rich(TextSpan(children: [
            TextSpan(text: '${monthOf(key)}월', style: disp(34, p.ink, height: 1.1)),
            TextSpan(text: ' 2026', style: TextStyle(fontSize: 13, color: p.mut)),
          ])),
        ),
      ),
      Expanded(
        child: Body(children: [
          Row(children: [
            Expanded(child: Seg(items: const [('week', '주간'), ('month', '월간')], value: app.calView, onChanged: app.setView)),
            const SizedBox(width: 10),
            Btn('일정', ic: 'plus', small: true, expand: false, onTap: () => showAddSheet(context)),
          ]),
          FullWidth(child: _Grid()),
          AiCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('AI 건강 챙기기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.priText))),
                Pill('오늘 부담 $lvlName', style: lvlStyle),
              ]),
              const SizedBox(height: 4),
              Txt(app.aiText(key), size: 14),
            ]),
          ),
          _FilterRow(),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Expanded(child: Heading('${dayLabel(key)}${key == kToday ? ' · 오늘' : ''}', size: 19)),
                Txt('일정 ${shown.length}개', size: 12, muted: true),
              ]),
              if (shown.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Txt('일정을 누르면 수정하거나 지울 수 있어요', size: 12, muted: true)),
              const SizedBox(height: 6),
              for (final e in shown) _EventRow(e: e),
              if (shown.isEmpty)
                Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 20),
                  alignment: Alignment.center,
                  child: Txt(all.isEmpty ? '비어있는 하루예요. 밥약을 보내 보는 건 어때요?' : '이 종류의 일정은 없어요.', muted: true, align: TextAlign.center),
                ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionHead('다가오는 마감', trailing: '과제 · 추가한 기회'),
            const SizedBox(height: 10),
            if (ups.isEmpty)
              Txt('다가오는 마감이 없어요.', size: 13, muted: true)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final e in ups) _UpCard(e: e),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ 달력 격자

class _Grid extends LiveView {
  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final week = app.calView == 'week';
    final cellH = week ? 136.0 : 80.0;
    final rows = <List<Widget>>[];
    if (week) {
      rows.add([for (final k in weekKeys(app.sel)) _DayCell(dayKey: k, max: 4, tall: true)]);
    } else {
      final month = monthOf(app.sel);
      final lead = dowOf('$month-1');
      final nDays = daysInMonth(month);
      final prevDays = DateTime.utc(2026, month, 0).day;
      final cells = <Widget>[
        for (var i = 0; i < lead; i++) _DimCell(n: prevDays - lead + 1 + i),
        for (var d = 1; d <= nDays; d++) _DayCell(dayKey: '$month-$d', max: 2, tall: false),
      ];
      final tail = (7 - cells.length % 7) % 7;
      for (var i = 1; i <= tail; i++) {
        cells.add(_DimCell(n: i));
      }
      for (var i = 0; i < cells.length; i += 7) {
        rows.add(cells.sublist(i, i + 7));
      }
    }
    const heads = ['월', '화', '수', '목', '금', '토', '일'];
    return Column(children: [
      SizedBox(
        height: 22,
        child: Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Text(heads[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: i == 5 ? p.types['class']!.c : (i == 6 ? p.types['assign']!.c : p.mut))),
            ),
        ]),
      ),
      for (final r in rows) ...[
        SizedBox(height: cellH, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final c in r) Expanded(child: c)])),
        const SizedBox(height: 3),
      ],
    ]);
  }
}

class _DimCell extends StatelessWidget {
  final int n;
  const _DimCell({required this.n});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text('$n', style: TextStyle(fontSize: 13, color: p.mut.withAlpha(140))),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String dayKey;
  final int max;
  final bool tall;
  const _DayCell({required this.dayKey, required this.max, required this.tall});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final on = dayKey == app.sel;
    final today = dayKey == kToday;
    final dw = dowOf(dayKey);
    var es = app.eventsOn(dayKey);
    if (app.filter != 'all') es = es.where((e) => e.type == app.filter).toList();
    es.sort((a, b) {
      final c = _chipOrd(a.type).compareTo(_chipOrd(b.type));
      return c != 0 ? c : a.t.compareTo(b.t);
    });
    final shown = es.take(max).toList();
    final more = es.length - shown.length;
    final numColor = today ? p.priInk : (dw == 5 ? p.types['class']!.c : (dw == 6 ? p.types['assign']!.c : p.ink));
    return Semantics(
      button: true,
      selected: on,
      label: '${dayLabel(dayKey)}${today ? ', 오늘' : ''}, 일정 ${es.length}개',
      child: InkWell(
        onTap: () => app.selectDay(dayKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(1, 4, 1, 0),
          decoration: BoxDecoration(
            color: on ? p.priSoft : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? p.pri : Colors.transparent, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 20,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: today ? p.pri : null, borderRadius: BorderRadius.circular(10)),
                  child: Text('${dayOf(dayKey)}', style: TextStyle(fontSize: 13, fontWeight: today ? FontWeight.w700 : FontWeight.w500, color: numColor)),
                ),
                if (more > 0) Text('+$more', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.mut)),
              ]),
            ),
            const SizedBox(height: 3),
            for (final e in shown) _MiniChip(e: e),
          ]),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final Ev e;
  const _MiniChip({required this.e});

  @override
  Widget build(BuildContext context) {
    final t = tsOf(context, e.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          app.selectDay(e.key);
          showEditSheet(context, e);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 17,
            child: Row(children: [
              Container(width: 2, color: t.c),
              Expanded(
                child: Container(
                  color: t.bg,
                  padding: const EdgeInsets.only(left: 2, right: 1),
                  alignment: Alignment.centerLeft,
                  child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: TextStyle(fontSize: 10, letterSpacing: -0.3, fontWeight: FontWeight.w500, color: t.ink, height: 1.1)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 필터 · 일정 목록 · 마감 카드

class _FilterRow extends LiveView {
  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final f in app.filterList()) ...[
          _fchip(context, p, f.$1, f.$2),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _fchip(BuildContext context, Pal p, String k, String label) {
    final on = app.filter == k;
    final dot = k == 'all' ? null : tsOf(context, k).c;
    return Semantics(
      button: true,
      selected: on,
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: on ? p.pri : p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? p.pri : p.line)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => app.setFilter(k),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: on ? p.priInk : dot, shape: BoxShape.circle)), const SizedBox(width: 6)],
                Text(label, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? p.priInk : p.ink)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Ev e;
  const _EventRow({required this.e});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final t = tsOf(context, e.type);
    // 줄 전체를 누르면 수정 창이 열려요. 오른쪽 X 는 바로 지우기예요.
    return Semantics(
      button: true,
      label: '${e.title} 수정',
      child: InkWell(
        onTap: () => showEditSheet(context, e),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: 42, child: Center(child: Text(e.t, style: TextStyle(fontSize: 12, color: p.mut)))),
              const SizedBox(width: 10),
              Container(width: 4, margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: t.c, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(e.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.35, color: p.ink)),
                  if (e.sub.isNotEmpty) Text(e.sub, style: TextStyle(fontSize: 12, height: 1.4, color: p.mut)),
                ]),
              ),
              const SizedBox(width: 8),
              Center(child: Pill(app.typeName(e.type), style: t)),
              if (e.mine || e.type == 'opp')
                Semantics(
                  button: true,
                  label: '${e.title} 삭제',
                  child: InkWell(
                    onTap: () => app.deleteEvent(e.id),
                    child: SizedBox(width: 36, height: 44, child: Icon(icon('x'), size: 18, color: p.mut)),
                  ),
                )
              else
                const SizedBox(width: 4),
            ]),
          ),
        ),
      ),
    );
  }
}

class _UpCard extends StatelessWidget {
  final Ev e;
  const _UpCard({required this.e});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final t = tsOf(context, e.type);
    final parts = e.sub.split(' · ');
    final from = e.type == 'assign' ? '아이캠퍼스' : (parts.length > 1 ? parts[1] : '기회');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showEditSheet(context, e),
      child: Container(
        width: 164,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${ddayText(e.key)} · $from', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.ink)),
          const SizedBox(height: 2),
          Text(e.title, style: TextStyle(fontSize: 13, height: 1.4, color: p.ink)),
        ]),
      ),
    );
  }
}
