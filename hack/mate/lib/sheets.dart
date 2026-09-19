import 'package:flutter/material.dart';

import 'data.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// 아래에서 올라오는 창(시트)들이 모여 있어요: 일정 추가, 함께 신청, 밥약 신청, 밥약 상세, 과팅 신청, 친구 추가, 시간 선택.

Future<T?> _openSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Pal.of(context).paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => ListenableBuilder(listenable: app, builder: (c, _) => builder(c)),
  );
}

/// 시트 공통 틀: 손잡이 + 제목 + 닫기 + 스크롤되는 내용
class SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SheetFrame({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 44, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
          child: Row(children: [
            Expanded(child: Heading(title, size: 24)),
            RoundIconBtn(ic: 'x', label: '닫기', onTap: () => Navigator.of(context).pop()),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, 14)),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ 일정 추가

Future<void> showAddSheet(BuildContext context) {
  app.prepareAdd();
  return _openSheet<void>(context, (_) => const _AddSheet());
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  String? _err;

  void _addType() {
    final name = app.addNewC.text.trim();
    final e = app.addCustomType();
    setState(() => _err = e);
    if (e == null && name.isNotEmpty) FocusScope.of(context).unfocus();
  }

  void _submit() {
    final e = app.submitAdd();
    if (e != null) {
      setState(() => _err = e);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final types = app.filterList().skip(1).toList();
    return ListenableBuilder(listenable: app, builder: (c, _) => _content(c, p, types));
  }

  Widget _content(BuildContext context, Pal p, List<(String, String)> types) {
    return SheetFrame(title: '일정 추가', children: [
      Field('무엇을 하나요?', child: AppInput(controller: app.addTitleC, hint: '예: 카페 알바, 과외, 친구 약속')),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Lbl('종류'),
        const SizedBox(height: 8),
        ChipWrap(children: [
          for (final t in types) PillChip(t.$2, on: app.addType == t.$1, dot: tsOf(context, t.$1), onTap: () => app.setAddType(t.$1)),
          if (app.customTypes.length < kMaxCustom) PillChip('종류 추가', on: app.addNewOpen, dashed: true, leading: 'plus', onTap: app.toggleAddNew),
        ]),
        if (app.addNewOpen) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppInput(controller: app.addNewC, maxLength: 8, hint: '새 종류 이름 (예: 스터디)', onSubmitted: (_) => _addType())),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: Btn('추가', small: true, onTap: _addType)),
          ]),
        ],
      ]),
      Field('날짜 (직접 입력)', child: AppInput(controller: app.addDateC, hint: '예: 9/28', maxLength: 10, keyboardType: TextInputType.datetime)),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: TimeField(label: '시작', value: app.addStart, options: timeOpts('00:00', '23:30'), onPicked: (v) => app.setAddTime(true, v))),
        const SizedBox(width: 12),
        Expanded(child: TimeField(label: '끝', value: app.addEnd, options: timeOpts('00:30', '24:00'), onPicked: (v) => app.setAddTime(false, v))),
      ]),
      if (_err != null) Text(_err!, style: TextStyle(color: p.danger, fontSize: 13, fontWeight: FontWeight.w700)),
      Btn('달력에 추가', onTap: _submit),
    ]);
  }
}

// ------------------------------------------------------------------ 일정 수정 · 삭제

/// 달력의 어떤 일정이든(시간표 · 과제 · 직접 만든 일정 · 기회) 눌러서 고치거나 지울 수 있어요.
Future<void> showEditSheet(BuildContext context, Ev e) {
  app.prepareEdit(e);
  return _openSheet<void>(context, (_) => _EditSheet(ev: e));
}

class _EditSheet extends StatefulWidget {
  final Ev ev;
  const _EditSheet({required this.ev});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  String? _err;

  void _save() {
    final e = app.submitEdit();
    if (e != null) {
      setState(() => _err = e);
      return;
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    Navigator.of(context).pop();
    app.deleteEvent(widget.ev.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    // '기회'는 추천에서 온 일정만 고를 수 있어요 (다른 일정을 기회로 바꾸면 달력에서 사라질 수 있어서요)
    final types = app.filterList().skip(1).where((t) => t.$1 != 'opp' || widget.ev.type == 'opp').toList();
    const noEnd = '없음';
    return ListenableBuilder(
      listenable: app,
      builder: (c, _) => SheetFrame(title: '일정 수정', children: [
        if (widget.ev.src == 'icampus')
          const Txt('아이캠퍼스에서 가져온 일정이에요. 여기서 고쳐도 앱 안에서만 바뀌고, 아이캠퍼스는 그대로예요.', size: 12, muted: true, height: 1.5),
        Field('제목', child: AppInput(controller: app.editTitleC, hint: '일정 이름', maxLength: 40)),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Lbl('종류'),
          const SizedBox(height: 8),
          ChipWrap(children: [
            for (final t in types) PillChip(t.$2, on: app.editType == t.$1, dot: tsOf(c, t.$1), onTap: () => app.setEditType(t.$1)),
          ]),
        ]),
        Field('날짜 (직접 입력)', child: AppInput(controller: app.editDateC, hint: '예: 9/28', maxLength: 10, keyboardType: TextInputType.datetime)),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: TimeField(label: '시작', value: app.editStart, options: timeOpts('00:00', '23:30'), onPicked: (v) => app.setEditTime(true, v))),
          const SizedBox(width: 12),
          Expanded(
            child: TimeField(
              label: '끝',
              value: app.editEnd.isEmpty ? noEnd : app.editEnd,
              options: [noEnd, ...timeOpts('00:30', '24:00')],
              onPicked: (v) => app.setEditTime(false, v == noEnd ? '' : v),
            ),
          ),
        ]),
        Field('메모', child: AppInput(controller: app.editSubC, hint: '장소, 메모 등 (비워도 돼요)', maxLength: 60)),
        if (_err != null) Text(_err!, style: TextStyle(color: p.danger, fontSize: 13, fontWeight: FontWeight.w700)),
        Btn('저장', onTap: _save),
        Btn('이 일정 삭제', ic: 'x', kind: 'line', onTap: _delete),
      ]),
    );
  }
}

// ------------------------------------------------------------------ 친구와 함께 신청

Future<void> showShareSheet(BuildContext context, String oppId) {
  app.openShare(oppId);
  return _openSheet<void>(context, (ctx) {
    final o = app.findOpp(app.shareOpp) ?? (app.opps.isNotEmpty ? app.opps.first : kOpps.first);
    final n = app.shareCount();
    return SheetFrame(title: '친구와 함께 신청', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Txt(o.title, bold: true, size: 15),
          Txt('${o.src} · ${whenPhrase(o)}', size: 12, muted: true),
        ]),
      ),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < kFriends.length; i++)
            PersonRow(
              first: i == 0,
              avatar: Avatar(kFriends[i].n[0], style: pal(ctx).types[kFriends[i].t]),
              name: kFriends[i].n,
              sub: kFriends[i].d,
              trailing: AppSwitch(on: app.shareTo[i] ?? false, label: '${kFriends[i].n}에게 보내기', onTap: () => app.toggleShareTo(i)),
            ),
        ]),
      ),
      Btn('$n명에게 “같이 신청하자” 보내기', onTap: n == 0
          ? null
          : () {
              Navigator.of(ctx).pop();
              app.shareSend();
            }),
    ]);
  });
}

// ------------------------------------------------------------------ 밥약 신청하기

Future<void> showReqSheet(BuildContext context) {
  return _openSheet<void>(context, (ctx) {
    final mutual = app.mutuals();
    return SheetFrame(title: '밥약 신청하기', children: [
      const Txt('맞팔한 친구에게만 신청할 수 있어요. 만나서 말하기 어려울 때 먼저 정중하게 보내 보세요.', size: 13, muted: true),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: mutual.isEmpty
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Txt('맞팔한 친구가 아직 없어요. 내 정보에서 팔로우해 보세요.', muted: true, align: TextAlign.center))
            : Column(children: [
                for (var i = 0; i < mutual.length; i++)
                  PersonRow(
                    first: i == 0,
                    avatar: Avatar(kFriends[mutual[i]].n[0], style: pal(ctx).types[kFriends[mutual[i]].t]),
                    name: kFriends[mutual[i]].n,
                    sub: kFriends[mutual[i]].d,
                    trailing: AppSwitch(on: app.reqPicked.contains(mutual[i]), label: '${kFriends[mutual[i]].n}에게 신청', onTap: () => app.reqTogglePick(mutual[i])),
                  ),
              ]),
      ),
      Field('보낼 메시지', child: AppInput(controller: app.reqMsgC, maxLines: 4)),
      SwitchCard(title: '익명으로 신청하기', sub: '수락하면 이름이 공개돼요', on: app.reqAnon, onTap: app.reqToggleAnon),
      Btn(mutual.isEmpty || app.reqPicked.isEmpty ? '신청할 친구를 골라주세요' : '${app.reqPicked.length}명에게 신청 보내기', onTap: mutual.isEmpty || app.reqPicked.isEmpty
          ? null
          : () {
              if (app.reqSend()) Navigator.of(ctx).pop();
            }),
    ]);
  });
}

// ------------------------------------------------------------------ 밥약 찾기 · 랜덤 매칭 상세

Future<void> showMealDetailSheet(BuildContext context, RandMeal q) {
  return _openSheet<void>(context, (ctx) {
    final p = pal(ctx);
    final applied = app.mealReqState[q.id] == 'applied';
    return SheetFrame(title: '밥약 상세', children: [
      Row(children: [
        Avatar(q.name[0], size: 56, bg: p.priSoft, fg: p.priText),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt(q.name, bold: true, size: 20),
            Txt(q.dept, size: 13, muted: true),
          ]),
        ),
        Pill(q.time, style: TS(p.pri, p.priSoft, p.priText)),
      ]),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon('chat'), size: 18, color: p.mut), const SizedBox(width: 8), Expanded(child: Txt('“${q.msg}”', size: 15))]),
          const SizedBox(height: 8),
          Txt('랜덤 매칭은 같은 학교 새내기와 이어줘요. 수락되면 서로 이름이 공개돼요.', size: 12, muted: true, height: 1.5),
        ]),
      ),
      Btn(applied ? '신청했어요' : '같이 먹기 신청', ic: applied ? 'check' : 'utensils', onTap: applied
          ? null
          : () {
              Navigator.of(ctx).pop();
              app.mealApplyRandom(q.id);
            }),
    ]);
  });
}

// ------------------------------------------------------------------ 과팅 신청

Future<void> showMeetApplySheet(BuildContext context, MeetPost post) {
  return _openSheet<void>(context, (ctx) {
    final p = pal(ctx);
    final full = app.meetSideFull(post);
    return SheetFrame(title: '과팅 신청', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon('calendar'), size: 20, color: p.pri), const SizedBox(width: 8), Txt('${shortDate(post.key)} ${post.time}', bold: true, size: 16)]),
          const SizedBox(height: 6),
          Row(children: [Icon(icon('pin'), size: 20, color: p.pri), const SizedBox(width: 8), Txt(post.place, size: 15)]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(icon('users'), size: 20, color: p.pri),
            const SizedBox(width: 8),
            Txt('${post.size.replaceAll(':', ' : ')} 과팅 · 남 ${post.m.length} · 여 ${post.f.length}', size: 15),
          ]),
        ]),
      ),
      if (full)
        Txt('이 과팅은 ${app.meetSideName()} 인원이 다 찼어요. 다른 팀을 찾아 보세요.', size: 13, muted: true)
      else
        Txt('신청하면 ${app.meetSideName()} 팀에 들어가요.', size: 13, muted: true),
      const SafeCard(title: '매너 지킴이', body: '만난 뒤에 불편했다면 익명으로 경고를 보낼 수 있어요. 경고가 3번 쌓이면 과팅이 몇 주간 정지돼요.'),
      Btn(full ? '신청불가' : '우리 팀으로 신청하기', ic: full ? null : 'heart', onTap: full
          ? null
          : () {
              Navigator.of(ctx).pop();
              app.meetApply(post.id);
            }),
    ]);
  });
}

// ------------------------------------------------------------------ 우리팀에 친구 추가

Future<void> showFriendPickSheet(BuildContext context) {
  return _openSheet<void>(context, (ctx) {
    final p = pal(ctx);
    final full = app.meet.members.length + 1 >= app.meetCap(app.meet.size);
    return SheetFrame(title: '우리팀 친구 추가', children: [
      Txt(
        full ? '우리팀이 가득 찼어요. 다른 친구를 넣으려면 먼저 빼주세요.' : '${app.meet.size.replaceAll(':', ' : ')} 과팅은 나를 포함해 ${app.meetCap(app.meet.size)}명까지 함께할 수 있어요.',
        size: 13,
        muted: !full,
        color: full ? p.danger : null,
        bold: full,
      ),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < kFriends.length; i++)
            PersonRow(
              first: i == 0,
              avatar: Avatar(kFriends[i].n[0], style: p.types[kFriends[i].t]),
              name: kFriends[i].n,
              sub: kFriends[i].d,
              trailing: AppSwitch(
                on: app.meet.members.contains(i),
                label: '${kFriends[i].n} 우리팀에 추가',
                onTap: full && !app.meet.members.contains(i) ? () {} : () => app.meetToggleMember(i),
              ),
            ),
        ]),
      ),
      Btn('완료', onTap: () => Navigator.of(ctx).pop()),
    ]);
  });
}

// ------------------------------------------------------------------ 시간 고르기 (스크롤)

Future<String?> pickTimeWheel(BuildContext context, {required String title, required String initial, required List<String> options}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Pal.of(context).paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) {
      var picked = options.contains(initial) ? initial : options.first;
      return StatefulBuilder(builder: (c, setS) {
        return SheetFrame(title: '$title 시간', children: [
          SizedBox(
            height: 250,
            child: WheelCol(
              label: '스크롤해서 고르세요',
              value: picked,
              items: [for (final o in options) (o, o)],
              onUserChange: (v) => setS(() => picked = v),
            ),
          ),
          Btn('$picked 로 정하기', onTap: () => Navigator.of(c).pop(picked)),
        ]);
      });
    },
  );
}
