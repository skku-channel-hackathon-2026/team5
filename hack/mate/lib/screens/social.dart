import 'package:flutter/material.dart';

import '../data.dart';
import '../sheets.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 메인화면에서 들어가는 밥약 · 과팅 · 놀기 화면들

/// 서브 화면 공통 틀: 머리글 + 본문 + (아래 버튼 줄)
class _SubPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ActionBar? bar;
  const _SubPage({required this.title, required this.children, this.bar});

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(children: [
      SafeArea(bottom: false, child: BackHeader(title)),
      Expanded(child: Body(children: children)),
      if (bar != null && !keyboard) bar!,
    ]);
  }
}

Widget _searching(String title, String body) => BigMessage(lead: const Spinner(), title: title, body: body);

/// 칸 안의 작은 제목 (시안의 "시간", "누구와 먹을까요?")
Widget _h(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: disp(22, pal(context).ink, height: 1.2)),
    );

// ------------------------------------------------------------------ 밥약

class MealScreen extends LiveView {
  const MealScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final m = app.meal;
    final send = app.mealView == 'send';
    final ActionBar bar = ActionBar(items: [
      BarItem('밥약 찾기', active: !send, solid: !send, onTap: () => app.setMealView('find')),
      BarItem('밥약 보내기', active: send, solid: send, onTap: send && m.step == 'form' ? app.mealSubmit : () => app.setMealView('send')),
    ]);
    if (!send) {
      return _SubPage(title: '밥약 찾기', bar: bar, children: const [_MealFind()]);
    }
    if (m.step == 'searching') {
      return _SubPage(title: '밥약 보내기', bar: bar, children: [_searching('비어있는 새내기를 찾고 있어요', '내 달력과 친구들의 달력을 비교하는 중이에요.')]);
    }
    if (m.step == 'posted') {
      return _SubPage(title: '밥약 보내기', bar: bar, children: [
        const BigMessage(lead: BigIcon('check'), title: '게시판에 올렸어요', body: '푸시는 가지 않아요. 관심 있는 새내기가 직접 신청하면 배너로 알려드릴게요.'),
        Btn('처음으로', kind: 'line', onTap: app.mealReset),
      ]);
    }
    if (m.step == 'matched') return _SubPage(title: '밥약 보내기', bar: bar, children: const [_MealMatched()]);
    return _SubPage(title: '밥약 보내기', bar: bar, children: const [_MealForm()]);
  }
}

// ---- 밥약 찾기

class _MealFind extends LiveView {
  const _MealFind();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final reqs = kMealReqs.where((r) => app.mealReqState[r.id] != 'declined').toList();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(left: 4), child: Text('내 친구가 보낸 밥약', style: disp(20, p.ink))),
        const SizedBox(height: 12),
        if (reqs.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Txt('받은 밥약이 없어요.', muted: true, align: TextAlign.center)),
        ...gapped([for (final r in reqs) _ReqCard(r: r)], 10),
        const SizedBox(height: 16),
        Divider(color: p.line, height: 1),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(left: 4), child: Text('랜덤 매칭', style: disp(20, p.ink))),
        const SizedBox(height: 12),
        ...gapped([for (final q in kRandMeals) _RandCard(q: q)], 10),
      ]),
    );
  }
}

class _MealHead extends StatelessWidget {
  final String time, title;
  const _MealHead(this.time, this.title);

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Row(children: [
      Text(time, style: disp(26, p.ink, height: 1.1)),
      Container(width: 1.5, height: 22, margin: const EdgeInsets.symmetric(horizontal: 12), color: p.line),
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink))),
    ]);
  }
}

class _MealLine extends StatelessWidget {
  final String ic, text;
  const _MealLine(this.ic, this.text);

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(icon(ic), size: 17, color: p.mut),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: p.mut))),
      ]),
    );
  }
}

class _MealCardShell extends StatelessWidget {
  final Widget child;
  const _MealCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
      child: child,
    );
  }
}

class _ReqCard extends StatelessWidget {
  final MealReq r;
  const _ReqCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final accepted = app.mealReqState[r.id] == 'accepted';
    return _MealCardShell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MealHead(r.time, r.title),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(children: [_MealLine('pin', r.place), _MealLine('chat', r.msg)])),
          if (accepted)
            const OkBadge('수락했어요')
          else ...[
            SizedBox(width: 68, child: Btn('수락', kind: 'soft', small: true, onTap: () => app.mealAccept(r.id))),
            const SizedBox(width: 6),
            SizedBox(width: 68, child: Btn('거절', kind: 'mint', small: true, onTap: () => app.mealDecline(r.id))),
          ],
        ]),
      ]),
    );
  }
}

class _RandCard extends StatelessWidget {
  final RandMeal q;
  const _RandCard({required this.q});

  @override
  Widget build(BuildContext context) {
    final applied = app.mealReqState[q.id] == 'applied';
    return _MealCardShell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _MealHead(q.time, q.name),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(children: [_MealLine('pin', q.dept), _MealLine('chat', q.msg)])),
          if (applied) const OkBadge('신청했어요') else SizedBox(width: 68, child: Btn('상세', kind: 'mint', small: true, onTap: () => showMealDetailSheet(context, q))),
        ]),
      ]),
    );
  }
}

// ---- 밥약 보내기

class _MealForm extends LiveView {
  const _MealForm();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final m = app.meal;
    final times = timeOpts('09:00', '21:00');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _h(context, '시간'),
      const SizedBox(height: 10),
      AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Icon(icon('calendar'), size: 22, color: p.pri), const SizedBox(width: 8), const Txt('날짜', bold: true, size: 16)]),
              const SizedBox(height: 10),
              ...gapped([
                for (final k in nextDays(3)) PillChip(wheelDate(k), expand: true, on: m.date == k, onTap: () => app.mealPick(date: k)),
              ], 8),
            ]),
          ),
          Container(width: 1, height: 176, margin: const EdgeInsets.symmetric(horizontal: 10), color: p.line),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Icon(icon('clock'), size: 22, color: p.pri), const SizedBox(width: 8), const Txt('시간', bold: true, size: 16)]),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: times.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => SizedBox(height: 44, child: PillChip(times[i], expand: true, on: m.time == times[i], onTap: () => app.mealPick(time: times[i]))),
                ),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      _h(context, '누구와 먹을까요?'),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [Icon(icon('users'), size: 22, color: p.pri), const SizedBox(width: 8), const Txt('먹는 사람', bold: true, size: 16)]),
                const SizedBox(height: 10),
                ...gapped([
                  for (final w in const [('solo', '혼자'), ('all', '모든 친구'), ('pick', '친구 선택')])
                    PillChip(w.$2, expand: true, on: !m.random && m.who == w.$1, onTap: () => app.mealWho(w.$1)),
                ], 8),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              selected: m.random,
              label: '랜덤 파티',
              child: AppCard(
                color: m.random ? p.priSoft : null,
                borderColor: m.random ? p.pri : null,
                padding: EdgeInsets.zero,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: app.mealToggleRandom,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [Icon(icon('users'), size: 22, color: p.pri), const SizedBox(width: 8), const Txt('랜덤 파티', bold: true, size: 16)]),
                        const SizedBox(height: 10),
                        const Txt('학교의 새로운 친구와\n함께 밥을 먹어요!', size: 13, muted: true, height: 1.5, align: TextAlign.center),
                        const Spacer(),
                        Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: m.random ? p.pri : p.surface, shape: BoxShape.circle, border: Border.all(color: m.random ? p.pri : p.line, width: 1.5)),
                            child: m.random ? Icon(icon('check'), size: 18, color: p.priInk) : null,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      if (!m.random && m.who == 'pick') ...[
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Lbl('밥약을 보낼 친구', small: '여러 명 고를 수 있어요'),
            const SizedBox(height: 8),
            ChipWrap(children: [
              for (var i = 0; i < kFriends.length; i++) PillChip(kFriends[i].n, on: m.picked.contains(i), leading: m.picked.contains(i) ? 'check' : null, onTap: () => app.mealTogglePick(i)),
            ]),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      AppInput(controller: app.mealMsgC, maxLength: 40, hint: '메뉴, 혹은 메모 (선택)', prefix: 'pencil', pill: true),
      const SizedBox(height: 12),
      AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChipGrid(cols: 2, children: [
            PillChip('실명', expand: true, leading: 'user', on: !m.anon, onTap: () => app.mealSetAnon(false)),
            PillChip('익명', expand: true, leading: 'mask', on: m.anon, onTap: () => app.mealSetAnon(true)),
          ]),
          const SizedBox(height: 12),
          Row(children: [Icon(icon('bellOn'), size: 20, color: p.pri), const SizedBox(width: 8), const Txt('푸시 알람', bold: true, size: 16)]),
          const SizedBox(height: 8),
          ChipGrid(cols: 2, children: [
            PillChip('켬', expand: true, on: m.push, onTap: () => app.mealSetPush(true)),
            PillChip('끔', expand: true, on: !m.push, onTap: () => app.mealSetPush(false)),
          ]),
          const SizedBox(height: 12),
          Btn('밥약 보내기', onTap: app.mealSubmit),
        ]),
      ),
      const SizedBox(height: 4),
      LinkBtn('직접 말하기 부끄럽다면 · ', bold: '밥약 신청하기', onTap: () => showReqSheet(context)),
    ]);
  }
}

class _MealMatched extends LiveView {
  const _MealMatched();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final m = app.meal;
    final done = app.mealDone();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      BigMessage(
        lead: const BigIcon('utensils'),
        title: '${m.mates.length}명이 같이 먹기로 했어요!',
        body: '${app.mealAt()} · ${m.anon ? '익명으로 보냈고, 수락하면 이름이 공개돼요' : '실명으로 보냈어요'}',
        extra: m.msg.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: 4), child: Txt('“${m.msg}”', align: TextAlign.center)),
      ),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < m.mates.length; i++)
            PersonRow(
              first: i == 0,
              avatar: Avatar(kFriends[m.mates[i]].n[0], style: p.types[kFriends[m.mates[i]].t]),
              name: kFriends[m.mates[i]].n,
              sub: kFriends[m.mates[i]].d,
              trailing: const OkBadge('수락'),
            ),
        ]),
      ),
      Btn(done ? '달력에 추가했어요' : '달력에 추가', ic: done ? 'check' : 'calendar', onTap: done ? null : app.mealAddToCalendar),
      Btn('받는 새내기 화면 보기', ic: 'bell', kind: 'line', onTap: app.showPush),
      LinkBtn('처음으로', onTap: app.mealReset),
    ], 14));
  }
}

// ------------------------------------------------------------------ 과팅 · 놀기 공통 아래 버튼

ActionBar _socialBar(String on, {VoidCallback? submit}) => ActionBar(items: [
      BarItem('과팅 찾기', ic: 'users', active: on == 'find', flex: 10, onTap: () => app.switchSocial('find')),
      BarItem('과팅 만들기', ic: 'plusCircle', active: on == 'make', solid: on == 'make', flex: 13, onTap: on == 'make' && submit != null ? submit : () => app.switchSocial('make')),
      BarItem('놀기', ic: 'film', active: on == 'play', flex: 9, onTap: () => app.switchSocial('play')),
    ]);

// ------------------------------------------------------------------ 과팅

class MeetScreen extends LiveView {
  const MeetScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final m = app.meet;
    if (m.step == 'matched') {
      return _SubPage(title: '과팅 매칭', bar: _socialBar('find'), children: const [_MeetMatched()]);
    }
    if (app.meetView == 'make') {
      return _SubPage(
        title: '과팅 만들기',
        bar: _socialBar('make', submit: () {
          final e = app.meetCreate();
          if (e != null) app.showToast(e);
        }),
        children: const [_MeetMake()],
      );
    }
    return _SubPage(title: '과팅 찾기', bar: _socialBar('find'), children: const [_MeetFind()]);
  }
}

class _MeetFind extends LiveView {
  const _MeetFind();

  @override
  Widget body(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.only(left: 4), child: UnderTitle('과팅 찾기', size: 28)),
      const SizedBox(height: 10),
      const Padding(padding: EdgeInsets.only(left: 6), child: Txt('같은 캠퍼스 친구들과 새로운 인연을 만들어보세요.', muted: true, size: 14)),
      const SizedBox(height: 14),
      ...gapped([for (final x in app.meetPosts) _PostCard(post: x)], 14),
    ]);
  }
}

class _PostCard extends StatelessWidget {
  final MeetPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final applied = app.meetApplied.contains(post.id);
    final full = !post.mine && !applied && app.meetSideFull(post);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.line),
        boxShadow: const [BoxShadow(color: Color(0x0F1E3A2A), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: p.tint,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: InkWell(
            onTap: post.mine || applied || full ? null : () => showMeetApplySheet(context, post),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(children: [
                Icon(icon('calendar'), size: 24, color: p.pri),
                const SizedBox(width: 8),
                Text(shortDate(post.key), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon('clock'), size: 18, color: p.mut),
                      const SizedBox(width: 4),
                      Text(post.time, style: TextStyle(fontSize: 14, color: p.ink)),
                      const SizedBox(width: 10),
                      Icon(icon('pin'), size: 18, color: p.mut),
                      const SizedBox(width: 2),
                      Flexible(child: Text(post.place, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: p.ink))),
                    ]),
                  ),
                ),
                if (!post.mine && !applied && !full) Icon(icon('chev'), size: 22, color: p.ink),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _SideBox(male: true, people: post.m)),
              Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), color: p.line),
              Expanded(child: _SideBox(male: false, people: post.f)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
          child: Row(children: [
            Icon(icon('chat'), size: 20, color: p.mut),
            const SizedBox(width: 8),
            Text('남 ${post.m.length} · 여 ${post.f.length}', style: TextStyle(fontSize: 14, color: p.ink)),
            const Spacer(),
            if (post.mine)
              OkBadge('내 ${post.size.replaceAll(':', ' : ')} · 대기 중')
            else if (applied)
              const OkBadge('신청했어요')
            else if (full)
              Btn('신청불가', kind: 'line', small: true, expand: false, onTap: () => app.showToast('이 과팅은 ${app.meetSideName()} 인원이 다 찼어요'))
            else
              Btn('신청하기', kind: 'soft', small: true, expand: false, onTap: () => showMeetApplySheet(context, post)),
          ]),
        ),
      ]),
    );
  }
}

class _SideBox extends StatelessWidget {
  final bool male;
  final List<(String, int)> people;
  const _SideBox({required this.male, required this.people});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final bg = male ? p.blueBg : p.pinkBg;
    final fg = male ? p.blue : p.pink;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Text('${male ? '남자' : '여자'} ${people.length}명', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(height: 8),
        if (people.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('신청한 ${male ? '남자' : '여자'}가\n아직 없어요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: p.mut)),
          )
        else
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 8, children: [
            for (final x in people)
              SizedBox(
                width: 54,
                child: Column(children: [
                  PersonDot(bg: fg.withAlpha(90), fg: p.surface, size: 44),
                  const SizedBox(height: 3),
                  Text(x.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.2, color: p.ink)),
                  Text('${x.$2}', style: TextStyle(fontSize: 12, height: 1.2, color: p.ink)),
                ]),
              ),
          ]),
      ]),
    );
  }
}

class _MeetMake extends LiveView {
  const _MeetMake();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final m = app.meet;
    final days = nextDays(9);
    Widget whiteWheel(Widget w) => Container(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18)),
          child: w,
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      SectionCard(
        ic: 'calendar',
        title: '날짜와 시작 시간',
        child: Row(children: [
          Expanded(
            flex: 6,
            child: whiteWheel(WheelCol(label: '날짜', value: m.date, items: [for (final k in days) (k, wheelDate(k))], onUserChange: (v) => app.meetPick(date: v))),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: whiteWheel(WheelCol(label: '시작 시간', value: m.time, items: [for (final t in timeOpts('09:00', '23:30')) (t, t)], onUserChange: (v) => app.meetPick(time: v))),
          ),
        ]),
      ),
      SectionCard(ic: 'pin', title: '장소', child: AppInput(controller: app.meetPlaceC, hint: '장소를 입력해주세요.', maxLength: 30)),
      SectionCard(
        ic: 'users',
        title: '미팅 인원수',
        small: '한 팀당 인원수 (남녀 동일)',
        child: ChipGrid(cols: 3, children: [
          for (final s in const ['2:2', '3:3', '4:4']) PillChip(s.replaceAll(':', ' : '), expand: true, on: m.size == s, onTap: () => app.meetSize(s)),
        ]),
      ),
      SectionCard(
        ic: 'users',
        title: '우리팀',
        small: '함께 갈 친구를 선택해주세요. (선택)',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: _MemberBox(label: '소프트 26 (나)')),
            const SizedBox(width: 8),
            Btn('추가', ic: 'plusCircle', kind: 'mint', small: true, expand: false, onTap: () => showFriendPickSheet(context)),
          ]),
          for (final i in m.members) ...[
            const SizedBox(height: 8),
            _MemberBox(label: '${kFriends[i].s} ${kFriends[i].y} (${kFriends[i].n})', onRemove: () => app.meetToggleMember(i)),
          ],
        ]),
      ),
      SectionCard(
        ic: 'note',
        title: '기타 설정',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppInput(controller: app.meetNoteC, hint: '추가로 하고 싶은 말을 입력해주세요. (선택)', maxLines: 3, maxLength: 200),
          const SizedBox(height: 4),
          ListenableBuilder(
            listenable: app.meetNoteC,
            builder: (c, _) => Align(alignment: Alignment.centerRight, child: Text('${app.meetNoteC.text.length}/200', style: TextStyle(fontSize: 12, color: p.mut))),
          ),
        ]),
      ),
    ], 12));
  }
}

class _MemberBox extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  const _MemberBox({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: p.priSoft, shape: BoxShape.circle), child: Icon(icon('user'), size: 20, color: p.priText)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink))),
        if (onRemove != null)
          InkWell(onTap: onRemove, customBorder: const CircleBorder(), child: SizedBox(width: 40, height: 40, child: Icon(icon('x'), size: 18, color: p.mut))),
      ]),
    );
  }
}

class _MeetMatched extends LiveView {
  const _MeetMatched();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final m = app.meet;
    final t = p.types['meet']!;
    final post = app.meetPosts.firstWhere((x) => x.id == m.postId, orElse: () => app.meetPosts.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      BigMessage(
        lead: BigIcon('heart', bg: t.bg, fg: t.c),
        title: '과팅 매칭이 성사됐어요!',
        body: '${shortDate(post.key)} ${post.time} · ${post.place} · ${post.size.replaceAll(':', ' : ')}\n달력에 약속으로 넣어뒀어요.',
      ),
      SafeCard(
        title: '만난 뒤에 불편했다면',
        body: '익명으로 경고를 보낼 수 있어요. 상대 팀에는 누가 보냈는지 알려지지 않아요.',
        extra: Btn(m.warned ? '익명 경고를 보냈어요' : '익명 경고 보내기', kind: 'line', small: true, onTap: m.warned ? null : app.meetWarn),
      ),
      Btn('받는 팀 화면 보기', ic: 'bell', kind: 'line', onTap: app.showPush),
      LinkBtn('처음으로', onTap: app.meetReset),
    ], 14));
  }
}

// ------------------------------------------------------------------ 놀기

class PlayScreen extends LiveView {
  const PlayScreen({super.key});

  @override
  Widget body(BuildContext context) {
    final pl = app.play;
    final bar = _socialBar('play');
    if (pl.view == 'done') {
      return _SubPage(title: '놀기', bar: bar, children: [
        const BigMessage(lead: BigIcon('check'), title: '놀기 모임을 올렸어요!', body: '같은 시간에 비어 있는 새내기에게\n배너 알림으로 알려드릴게요.'),
        Btn('놀기 화면으로', onTap: app.playBackToList),
      ]);
    }
    return _SubPage(title: '놀기', bar: bar, children: const [_PlayForm()]);
  }
}

class _PlayForm extends LiveView {
  const _PlayForm();

  @override
  Widget body(BuildContext context) {
    final p = pal(context);
    final pl = app.play;
    final inbox = kPlays.where((x) => !app.playJoined(x.id)).toList();
    final days = nextDays(9);
    Widget whiteWheel(Widget w) => Container(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18)),
          child: w,
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(children: [Icon(icon('mail'), size: 24, color: p.pri), const SizedBox(width: 8), Text('받은 놀기 신청', style: disp(20, p.ink))]),
        ),
        const SizedBox(height: 10),
        if (inbox.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.priLine, width: 1.5)),
            child: Column(children: [
              Icon(icon('mail'), size: 32, color: p.priLine),
              const SizedBox(height: 8),
              const Txt('받은 놀기 신청이 아직 없어요.', bold: true, size: 14, align: TextAlign.center),
              const Txt('친구들이 보낸 신청이 여기에 표시돼요.', size: 12, muted: true, align: TextAlign.center),
            ]),
          )
        else
          ...gapped([for (final x in inbox) _InboxCard(x: x)], 10),
      ]),
      SectionCard(
        ic: 'clock',
        title: '시간',
        child: Row(children: [
          Expanded(flex: 6, child: whiteWheel(WheelCol(label: '날짜', value: pl.date, items: [for (final k in days) (k, wheelDate(k))], onUserChange: (v) => app.playPick(date: v)))),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: whiteWheel(WheelCol(label: '시간', value: pl.time, items: [for (final t in timeOpts('06:00', '23:30')) (t, t)], onUserChange: (v) => app.playPick(time: v)))),
        ]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
        child: Row(children: [
          Icon(icon('pin'), size: 24, color: p.pri),
          const SizedBox(width: 8),
          Text('장소', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(width: 10),
          Expanded(child: AppInput(controller: app.playPlaceC, hint: '장소를 입력해주세요.', maxLength: 30)),
        ]),
      ),
      SectionCard(
        ic: 'sparkle',
        title: '어떤 걸 할까요?',
        child: ChipGrid(cols: 3, children: [
          for (final a in kActs) PillChip(a.$2, expand: true, leading: a.$3, on: pl.act == a.$1, onTap: () => app.playAct(a.$1)),
        ]),
      ),
      SectionCard(
        ic: 'users',
        title: '누구와 놀까요?',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChipGrid(cols: 3, children: [
            PillChip('우리 조', expand: true, on: pl.who == 'team', onTap: () => app.playWho('team')),
            PillChip('모든 친구', expand: true, on: pl.who == 'all', onTap: () => app.playWho('all')),
            PillChip('친구 지정', expand: true, on: pl.who == 'pick', onTap: () => app.playWho('pick')),
          ]),
          if (pl.who == 'pick') ...[
            const SizedBox(height: 10),
            ChipWrap(children: [
              for (var i = 0; i < kFriends.length; i++) PillChip(kFriends[i].n, on: pl.picked.contains(i), leading: pl.picked.contains(i) ? 'check' : null, onTap: () => app.playTogglePick(i)),
            ]),
          ],
        ]),
      ),
      SectionCard(
        ic: 'bellOn',
        title: '푸시 알람',
        child: ChipGrid(cols: 2, children: [
          PillChip('켬', expand: true, leading: 'bellOn', on: pl.push, onTap: () => app.playSetPush(true)),
          PillChip('끔', expand: true, leading: 'bellOff', on: !pl.push, onTap: () => app.playSetPush(false)),
        ]),
      ),
      Btn('놀 친구 구하기', onTap: app.playSubmit),
    ], 12));
  }
}

class _InboxCard extends StatelessWidget {
  final PlayPost x;
  const _InboxCard({required this.x});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AvatarStack([for (final n in x.names) Avatar(n, style: p.types['class'], size: 36)]),
          const Spacer(),
          Pill(x.when, style: p.types['class']),
        ]),
        const SizedBox(height: 10),
        Txt(x.title, bold: true, size: 16),
        Txt(x.who, size: 13, muted: true),
        const SizedBox(height: 10),
        Btn('참여하기', small: true, onTap: () => app.playJoin(x.id)),
      ]),
    );
  }
}
