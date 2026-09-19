import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sheets.dart';
import 'state.dart';
import 'theme.dart';
import 'feeds.dart';

/// 여러 화면이 같이 쓰는 작은 부품(버튼, 칩, 카드, 머리글 등)이에요.

Pal pal(BuildContext c) => Pal.of(c);

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url.replaceAll('&amp;', '&'));
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// 위젯 사이에 같은 간격을 넣어줘요.
List<Widget> gapped(List<Widget> children, double gap) {
  final out = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(children[i]);
  }
  return out;
}

/// 화면 본문: 스크롤 + 좌우 16 여백 + 위젯 사이 14 간격
/// FullWidth 로 감싼 위젯은 좌우 여백 없이 화면 끝까지 넓게 써요 (달력 격자).
class Body extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final EdgeInsets padding;
  const Body({super.key, required this.children, this.gap = 14, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24)});

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final c in children) c is FullWidth ? c : Padding(padding: EdgeInsets.only(left: padding.left, right: padding.right), child: c),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(items, gap)),
    );
  }
}

class FullWidth extends StatelessWidget {
  final Widget child;
  const FullWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: child);
}

/// 아래 고정 버튼 줄
class CtaBar extends StatelessWidget {
  final List<Widget> children;
  const CtaBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
    );
  }
}

class Txt extends StatelessWidget {
  final String text;
  final double size;
  final bool bold, muted, disp_;
  final Color? color;
  final TextAlign? align;
  final double height;
  final int? maxLines;
  const Txt(this.text,
      {super.key, this.size = 14, this.bold = false, this.muted = false, this.color, this.align, this.height = 1.5, this.maxLines, this.disp_ = false});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final col = color ?? (muted ? p.mut : p.ink);
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: disp_
          ? disp(size, col, height: height)
          : TextStyle(fontSize: size, color: col, height: height, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
    );
  }
}

/// 제목용(주아체) 글자
class Heading extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final TextAlign? align;
  const Heading(this.text, {super.key, this.size = 20, this.color, this.align});

  @override
  Widget build(BuildContext context) => Text(text, textAlign: align, style: disp(size, color ?? pal(context).ink));
}

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? ic;
  final String kind; // pri | soft | line | mint
  final bool small;
  final bool expand;
  final double? radius; // 기본은 알약 모양. 시안처럼 각진 둥근 사각형이 필요하면 값을 줘요.
  const Btn(this.label, {super.key, this.onTap, this.ic, this.kind = 'pri', this.small = false, this.expand = true, this.radius});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    Color bg, fg;
    Color? border;
    switch (kind) {
      case 'soft':
        bg = p.priSoft;
        fg = p.priText;
        break;
      case 'mint': // 시안의 연한 초록 + 초록 테두리 버튼
        bg = p.priSoft;
        fg = p.priText;
        border = p.pri;
        break;
      case 'line':
        bg = p.surface;
        fg = p.ink;
        border = p.line;
        break;
      default:
        bg = p.pri;
        fg = p.priInk;
    }
    final enabled = onTap != null;
    final r = radius ?? (small ? 22.0 : 26.0);
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (ic != null) ...[Icon(icon(ic!), size: small ? 18 : 20, color: fg), const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: small ? 14 : 16, fontWeight: FontWeight.w700))),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r), side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.5)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: Container(height: small ? 44 : 52, padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20), child: child),
        ),
      ),
    );
  }
}

/// 글씨만 있는 작은 버튼 (예: "처음으로")
class LinkBtn extends StatelessWidget {
  final String label;
  final String? bold;
  final VoidCallback onTap;
  const LinkBtn(this.label, {super.key, this.bold, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        child: Text.rich(TextSpan(style: TextStyle(color: p.mut, fontSize: 13), children: [
          TextSpan(text: label),
          if (bold != null) TextSpan(text: bold, style: TextStyle(color: p.pri, fontWeight: FontWeight.w700)),
        ])),
      ),
    );
  }
}

/// 선택하는 알약 칩
class PillChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  final TS? dot; // 앞에 색 점을 붙일 때
  final String? leading; // 앞에 아이콘을 붙일 때
  final bool dashed;
  final bool expand;
  const PillChip(this.label, {super.key, required this.on, required this.onTap, this.dot, this.leading, this.dashed = false, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final fg = on ? p.priText : (dashed ? p.priText : p.ink);
    final row = Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: dot!.c, shape: BoxShape.circle)), const SizedBox(width: 6)],
      if (leading != null) ...[Icon(icon(leading!), size: 16, color: fg), const SizedBox(width: 6)],
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: fg, fontWeight: on || dashed ? FontWeight.w700 : FontWeight.w500))),
    ]);
    return Semantics(
      button: true,
      selected: on,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: on ? p.priSoft : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? p.pri : p.line, width: 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: EdgeInsets.symmetric(horizontal: expand ? 10 : 14, vertical: 11),
              alignment: expand ? Alignment.center : null,
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// 칩을 n칸 격자로 나란히
class ChipGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;
  const ChipGrid({super.key, required this.children, this.cols = 2});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final cells = <Widget>[];
      for (var j = 0; j < cols; j++) {
        if (j > 0) cells.add(const SizedBox(width: 8));
        cells.add(Expanded(child: i + j < children.length ? children[i + j] : const SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14), this.color, this.borderColor, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.line),
        boxShadow: const [BoxShadow(color: Color(0x0D1E3A2A), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// 시안의 연한 초록 칸: 아이콘 + 제목 + 안쪽 내용 (과팅 만들기, 놀기 등)
class SectionCard extends StatelessWidget {
  final String ic, title;
  final String? small;
  final Widget child;
  const SectionCard({super.key, required this.ic, required this.title, this.small, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(icon(ic), size: 24, color: p.pri),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
        ]),
        if (small != null) Padding(padding: const EdgeInsets.only(top: 2, left: 34), child: Text(small!, style: TextStyle(fontSize: 12, color: p.mut))),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

/// 초록 안내 카드 (AI 건강 챙기기 등)
class AiCard extends StatelessWidget {
  final Widget child;
  final String ic;
  final Color? icBg, icFg;
  final bool center;
  const AiCard({super.key, required this.child, this.ic = 'leaf', this.icBg, this.icFg, this.center = false});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.priSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.priLine)),
      child: Row(crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
        IconDisc(ic, bg: icBg, fg: icFg),
        const SizedBox(width: 12),
        Expanded(child: child),
      ]),
    );
  }
}

class IconDisc extends StatelessWidget {
  final String ic;
  final Color? bg, fg;
  final double size;
  const IconDisc(this.ic, {super.key, this.bg, this.fg, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? p.pri, shape: BoxShape.circle),
      child: Icon(icon(ic), size: size * 0.53, color: fg ?? p.priInk),
    );
  }
}

/// 매너 지킴이 같은 붉은 안내 카드
class SafeCard extends StatelessWidget {
  final String title, body;
  final Widget? extra;
  const SafeCard({super.key, required this.title, required this.body, this.extra});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final t = p.types['assign']!;
    return AppCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconDisc('shield', bg: t.bg, fg: t.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt(title, bold: true, size: 15),
            const SizedBox(height: 2),
            Txt(body, size: 12, muted: true, height: 1.55),
            if (extra != null) ...[const SizedBox(height: 10), extra!],
          ]),
        ),
      ]),
    );
  }
}

class SectionHead extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color? trailingColor;
  const SectionHead(this.title, {super.key, this.trailing, this.trailingColor});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Text(title, style: disp(19, p.ink, height: 1.3)),
      if (trailing != null) ...[
        const SizedBox(width: 10),
        Expanded(child: Text(trailing!, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: trailingColor ?? p.mut, fontWeight: trailingColor == null ? FontWeight.w400 : FontWeight.w700))),
      ] else
        const Spacer(),
    ]);
  }
}

/// 작은 소제목 (예: "종류", "날짜")
class Lbl extends StatelessWidget {
  final String text;
  final String? small;
  const Lbl(this.text, {super.key, this.small});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Text.rich(TextSpan(children: [
      TextSpan(text: text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      if (small != null) TextSpan(text: '  $small', style: TextStyle(fontSize: 12, color: p.mut)),
    ]));
  }
}

class Pill extends StatelessWidget {
  final String text;
  final TS? style;
  const Pill(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: style?.bg ?? p.seg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: style?.ink ?? p.mut)),
    );
  }
}

class Avatar extends StatelessWidget {
  final String letter;
  final TS? style;
  final double size;
  final Color? bg, fg;
  const Avatar(this.letter, {super.key, this.style, this.size = 40, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg ?? style?.bg ?? p.seg, shape: BoxShape.circle),
      child: Text(letter, style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * 0.36, color: fg ?? style?.ink ?? p.mut)),
    );
  }
}

/// 겹쳐 놓은 동그란 아바타들
class AvatarStack extends StatelessWidget {
  final List<Widget> avatars;
  const AvatarStack(this.avatars, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < avatars.length; i++)
        Transform.translate(offset: Offset(-8.0 * i, 0), child: avatars[i]),
    ]);
  }
}

class AppSwitch extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  final String label;
  const AppSwitch({super.key, required this.on, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Semantics(
      label: label,
      toggled: on,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(color: on ? p.pri : const Color(0xFF9AA69F), borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 2, offset: Offset(0, 1))]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 제목 + 설명 + 스위치 한 줄 카드
class SwitchCard extends StatelessWidget {
  final String title, sub;
  final bool on;
  final VoidCallback onTap;
  const SwitchCard({super.key, required this.title, required this.sub, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Txt(title, bold: true, size: 15), Txt(sub, size: 12, muted: true)])),
        AppSwitch(on: on, onTap: onTap, label: title),
      ]),
    );
  }
}

/// 소식을 가져올 곳 한 줄. 켜면 학교·학과·단대는 홈페이지를 읽고, 아이캠퍼스·에타는 연동 전 예시를 넣어요.
class SourceCard extends StatelessWidget {
  final FeedDef s;
  const SourceCard({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final on = app.conn[s.id] ?? false;
    final st = app.feedStatus[s.id];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt(s.name, bold: true, size: 15),
            Txt(s.sub, size: 12, muted: true),
            if (st != null && st.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(st, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.priText)),
            ],
          ]),
        ),
        AppSwitch(on: on, onTap: () => app.toggleConn(s.id), label: s.name),
      ]),
    );
  }
}

/// 사람 한 줄 (아바타 + 이름 + 학과)
class PersonRow extends StatelessWidget {
  final Widget avatar;
  final String name, sub;
  final Widget? trailing;
  final bool first;
  const PersonRow({super.key, required this.avatar, required this.name, required this.sub, this.trailing, this.first = false});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: p.line))),
      child: Row(children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Txt(name, bold: true, size: 15, height: 1.3), Txt(sub, size: 12, muted: true, height: 1.3)])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class OkBadge extends StatelessWidget {
  final String text;
  const OkBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: p.priSoft, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.priText)),
    );
  }
}

/// 가운데 큰 안내 (검색 중, 완료 등)
class BigMessage extends StatelessWidget {
  final Widget lead;
  final String title;
  final String body;
  final Widget? extra;
  const BigMessage({super.key, required this.lead, required this.title, this.body = '', this.extra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 10),
      child: Column(children: [
        lead,
        const SizedBox(height: 10),
        Heading(title, size: 24, align: TextAlign.center),
        if (body.isNotEmpty) ...[const SizedBox(height: 10), Txt(body, muted: true, height: 1.6, align: TextAlign.center)],
        if (extra != null) ...[const SizedBox(height: 6), extra!],
      ]),
    );
  }
}

class BigIcon extends StatelessWidget {
  final String ic;
  final Color? bg, fg;
  const BigIcon(this.ic, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: bg ?? p.priSoft, shape: BoxShape.circle),
      child: Icon(icon(ic), size: 34, color: fg ?? p.pri),
    );
  }
}

class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 4, color: p.pri, backgroundColor: p.priSoft));
  }
}

class AppInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? prefix; // 앞에 붙일 아이콘 이름
  final Widget? suffix;
  final bool obscure;
  final bool pill; // 시안의 둥근 입력칸
  final bool autocorrect;
  final TextInputAction? action;
  const AppInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint = '',
    this.maxLength = 0,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.pill = false,
    this.autocorrect = true,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final r = pill ? 30.0 : 14.0;
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(borderRadius: BorderRadius.circular(r), borderSide: BorderSide(color: c, width: w));
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: obscure ? 1 : maxLines,
      minLines: obscure ? 1 : maxLines,
      obscureText: obscure,
      autocorrect: autocorrect && !obscure,
      enableSuggestions: autocorrect && !obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      textCapitalization: TextCapitalization.none,
      inputFormatters: inputFormatters,
      maxLength: maxLength == 0 ? null : maxLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, color: p.ink),
      cursorColor: p.pri,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.mut.withAlpha(170)),
        filled: true,
        fillColor: p.surface,
        isDense: false,
        prefixIcon: prefix == null ? null : Icon(icon(prefix!), size: 22, color: p.mut),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(horizontal: pill ? 20 : 14, vertical: pill ? 16 : 14),
        enabledBorder: b(p.line, 1),
        focusedBorder: b(p.pri, 2),
        border: b(p.line, 1),
      ),
    );
  }
}

/// 탭하면 스크롤 시간 선택 창이 열리는 칸 (시작 / 끝 시간)
class TimeField extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onPicked;
  final List<String> options;
  const TimeField({super.key, required this.label, required this.value, required this.onPicked, required this.options});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Lbl(label),
      const SizedBox(height: 6),
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final v = await pickTimeWheel(context, title: label, initial: value, options: options);
          if (v != null) onPicked(v);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
          child: Row(children: [
            Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: p.ink, fontFeatures: const [FontFeature.tabularFigures()]))),
            Icon(icon('clock'), size: 18, color: p.mut),
          ]),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ 머리글 · 아래 탭

class RoundIconBtn extends StatelessWidget {
  final String ic;
  final VoidCallback onTap;
  final String label;
  const RoundIconBtn({super.key, required this.ic, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.line)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(icon(ic), size: 22, color: p.ink),
          ),
        ),
      ),
    );
  }
}

class MeBtn extends StatelessWidget {
  const MeBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Semantics(
      button: true,
      label: '내 정보',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => app.open('me'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
          child: Text('내 정보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.priText)),
        ),
      ),
    );
  }
}

/// 화면 위쪽 머리글: 뒤로가기 + 제목 + (오른쪽 버튼들)
class BackHeader extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final VoidCallback? onBack;
  const BackHeader(this.title, {super.key, this.titleWidget, this.actions = const [], this.onBack});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 6),
      child: Row(children: [
        Semantics(
          button: true,
          label: '뒤로가기',
          child: InkWell(
            onTap: onBack ?? () => app.back(),
            customBorder: const CircleBorder(),
            child: SizedBox(width: 44, height: 44, child: Icon(icon('back'), size: 32, color: p.ink)),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(child: titleWidget ?? Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: disp(26, p.ink, height: 1.2))),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ]),
    );
  }
}

/// 굵은 제목 + 밑에 연한 초록 줄 (시안의 "로그인", "내 정보", "과팅 찾기")
class UnderTitle extends StatelessWidget {
  final String text;
  final double size;
  const UnderTitle(this.text, {super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(text, style: disp(size, p.ink, height: 1.2)),
      const SizedBox(height: 4),
      Container(width: 46, height: 5, decoration: BoxDecoration(color: p.priLine, borderRadius: BorderRadius.circular(3))),
    ]);
  }
}

class BarItem {
  final String label;
  final String? ic;
  final bool active; // 지금 보고 있는 것
  final bool solid; // 진한 초록으로 꽉 채운 버튼 (실제로 "보내기 · 만들기"를 하는 버튼)
  final int flex;
  final VoidCallback onTap;
  const BarItem(this.label, {this.ic, this.active = false, this.solid = false, this.flex = 1, required this.onTap});
}

/// 화면 아래 알약 버튼 줄 (밥약 찾기 / 밥약 보내기, 과팅 찾기 / 과팅 만들기 / 놀기)
class ActionBar extends StatelessWidget {
  final List<BarItem> items;
  const ActionBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(color: p.paper, border: Border(top: BorderSide(color: p.line))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(flex: items[i].flex, child: _BarBtn(items[i], dense: items.length > 2)),
          ],
        ]),
      ),
    );
  }
}

class _BarBtn extends StatelessWidget {
  final BarItem it;
  final bool dense; // 버튼이 3개 이상이면 조금 작게
  const _BarBtn(this.it, {this.dense = false});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final Color bg = it.solid ? p.pri : (it.active ? p.priSoft : p.surface);
    final Color fg = it.solid ? p.priInk : (it.active ? p.priText : p.ink);
    final Color bd = it.solid ? p.pri : (it.active ? p.pri : p.priLine.withAlpha(150));
    return Semantics(
      button: true,
      selected: it.active || it.solid,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: bd, width: it.active || it.solid ? 1.5 : 1)),
        child: InkWell(
          onTap: it.onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (it.ic != null) ...[Icon(icon(it.ic!), size: dense ? 18 : 20, color: fg), SizedBox(width: dense ? 4 : 6)],
              Flexible(child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: dense ? 14 : 15, fontWeight: FontWeight.w700, color: fg))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 달력 · 추천 화면 아래 탭
class BottomTabs extends StatelessWidget {
  const BottomTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    const tabs = [('cal', '달력', 'calendar'), ('reco', '추천', 'sparkle')];
    return ListenableBuilder(listenable: app, builder: (c, _) => _tabs(c, p, tabs));
  }

  Widget _tabs(BuildContext context, Pal p, List<(String, String, String)> tabs) {
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(children: [
            for (final t in tabs)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: app.screen == t.$1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: app.screen == t.$1 ? p.priSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () => app.switchTab(t.$1),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon(t.$3), size: 26, color: app.screen == t.$1 ? p.pri : p.mut),
                            const SizedBox(height: 2),
                            Text(t.$2, style: TextStyle(fontSize: 13, fontWeight: app.screen == t.$1 ? FontWeight.w800 : FontWeight.w500, color: app.screen == t.$1 ? p.pri : p.mut)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// 두 개 중 하나를 고르는 위쪽 전환 버튼 (주간 / 월간)
class Seg extends StatelessWidget {
  final List<(String, String)> items;
  final String value;
  final ValueChanged<String> onChanged;
  const Seg({super.key, required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.seg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: value == it.$1 ? p.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: value == it.$1 ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1))] : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onChanged(it.$1),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(child: Text(it.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: value == it.$1 ? p.ink : p.mut))),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ 스크롤 선택 (날짜 · 시간)

/// 위아래로 밀어서 고르는 한 칸. 사람이 돌렸을 때만 onUserChange 가 불려요.
class WheelCol extends StatefulWidget {
  final List<(String, String)> items; // (값, 보이는 글자)
  final String value;
  final String label;
  final ValueChanged<String> onUserChange;
  const WheelCol({super.key, required this.items, required this.value, required this.label, required this.onUserChange});

  @override
  State<WheelCol> createState() => _WheelColState();
}

class _WheelColState extends State<WheelCol> {
  late FixedExtentScrollController _c;
  late int _idx;
  bool _silent = false;
  int _tok = 0;

  int _indexOf(String v) {
    final i = widget.items.indexWhere((e) => e.$1 == v);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _idx = _indexOf(widget.value);
    _c = FixedExtentScrollController(initialItem: _idx);
  }

  @override
  void didUpdateWidget(WheelCol old) {
    super.didUpdateWidget(old);
    final i = _indexOf(widget.value);
    if (i != _idx && _c.hasClients) {
      final t = ++_tok;
      _silent = true;
      _c.animateToItem(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOut).whenComplete(() {
        if (t == _tok) _silent = false;
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.mut)),
      const SizedBox(height: 2),
      SizedBox(
        height: 220,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: p.priSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.priLine)),
          ),
          ListWheelScrollView.useDelegate(
            controller: _c,
            itemExtent: 44,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 3.2,
            perspective: 0.002,
            overAndUnderCenterOpacity: 0.4,
            onSelectedItemChanged: (i) {
              setState(() => _idx = i);
              if (!_silent) widget.onUserChange(widget.items[i].$1);
            },
            childDelegate: ListWheelChildListDelegate(children: [
              for (var i = 0; i < widget.items.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _c.animateToItem(i, duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
                  child: Center(
                    child: Text(
                      widget.items[i].$2,
                      style: TextStyle(
                        fontSize: i == _idx ? 18 : 16,
                        fontWeight: i == _idx ? FontWeight.w700 : FontWeight.w400,
                        color: i == _idx ? p.priText : p.mut,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ 자잘한 도우미

/// 일정 종류(기본 · 직접 만든 것 모두)의 색
TS tsOf(BuildContext context, String type) {
  final p = pal(context);
  final base = p.types[type];
  if (base != null) return base;
  final c = app.customOf(type);
  return p.custom[(c?.p ?? 0) % p.custom.length];
}

/// 작은 제목 + 입력칸 묶음
class Field extends StatelessWidget {
  final String label;
  final Widget child;
  const Field(this.label, {super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Lbl(label), const SizedBox(height: 6), child]);
  }
}

/// 칩들을 줄바꿈하며 나열
class ChipWrap extends StatelessWidget {
  final List<Widget> children;
  const ChipWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

/// 상태(app)가 바뀌면 스스로 다시 그려지는 화면의 바탕 클래스.
/// 화면을 만들 때 build 대신 body 를 채우면 돼요.
abstract class LiveView extends StatelessWidget {
  const LiveView({super.key});

  Widget body(BuildContext context);

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (c, _) => body(c));
}

// ------------------------------------------------------------------ 배경 · 로고

/// 크림색 바탕 위에 연한 초록 물결과 나뭇잎을 깔아줘요 (로그인, 가입, 내 정보)
class Backdrop extends StatelessWidget {
  final Widget child;
  final bool leaves;
  const Backdrop({super.key, required this.child, this.leaves = true});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Stack(children: [
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter(p.blob, Color.lerp(p.blob, p.pri, 0.28)!, leaves)))),
      Positioned.fill(child: child),
    ]);
  }
}

class _BlobPainter extends CustomPainter {
  final Color blob, leaf;
  final bool leaves;
  const _BlobPainter(this.blob, this.leaf, this.leaves);

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = blob;
    final top = Path()
      ..moveTo(-20, -20)
      ..lineTo(s.width * 0.6, -20)
      ..cubicTo(s.width * 0.6, s.height * 0.05, s.width * 0.3, s.height * 0.08, -20, s.height * 0.19)
      ..close();
    canvas.drawPath(top, paint);
    final bottom = Path()
      ..moveTo(s.width + 20, s.height * 0.84)
      ..cubicTo(s.width * 0.78, s.height * 0.86, s.width * 0.6, s.height * 0.95, s.width * 0.56, s.height + 20)
      ..lineTo(s.width + 20, s.height + 20)
      ..close();
    canvas.drawPath(bottom, paint);
    if (leaves) {
      final lp = Paint()..color = leaf;
      void one(double x, double y, double rot, double w, double h) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rot);
        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(w * 0.5, -h, w, 0)
          ..quadraticBezierTo(w * 0.5, h, 0, 0);
        canvas.drawPath(path, lp);
        canvas.restore();
      }

      final x = s.width - 96, y = s.height * 0.1;
      one(x, y + 26, -0.75, 46, 15);
      one(x + 24, y + 30, -0.05, 44, 14);
      final sp = Paint()
        ..color = leaf
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x + 20, y - 4), Offset(x + 24, y + 6), sp);
      canvas.drawLine(Offset(x + 40, y - 6), Offset(x + 40, y + 6), sp);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.blob != blob || old.leaf != leaf || old.leaves != leaves;
}

/// "Mate" 글자 로고 + 작은 나뭇잎
class MateLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const MateLogo({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final c = color ?? p.pri;
    return Padding(
      padding: EdgeInsets.only(right: size * 0.42, top: size * 0.2),
      child: Stack(clipBehavior: Clip.none, children: [
        Text('Mate', style: logoStyle(size, c)),
        Positioned(right: -size * 0.4, top: -size * 0.22, child: CustomPaint(size: Size(size * 0.42, size * 0.4), painter: _LeafPainter(c))),
      ]),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  const _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final a = Paint()..color = color.withAlpha(150);
    final b = Paint()..color = color.withAlpha(210);
    Path leaf(double x, double y, double w, double h) => Path()
      ..moveTo(x, y + h)
      ..quadraticBezierTo(x, y, x + w, y)
      ..quadraticBezierTo(x + w, y + h, x, y + h);
    canvas.drawPath(leaf(0, s.height * 0.35, s.width * 0.55, s.height * 0.6), a);
    canvas.drawPath(leaf(s.width * 0.42, 0, s.width * 0.58, s.height * 0.6), b);
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}

/// 사람 모양 동그란 아이콘 (과팅 카드의 팀원 자리)
class PersonDot extends StatelessWidget {
  final Color bg, fg;
  final double size;
  const PersonDot({super.key, required this.bg, required this.fg, this.size = 52});

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(Icons.person, size: size * 0.7, color: fg));
}

/// 점선 테두리 상자 (학생증 사진 올리는 칸)
class DashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  const DashedBox({super.key, required this.child, required this.color, this.radius = 26});

  @override
  Widget build(BuildContext context) => CustomPaint(foregroundPainter: _DashPainter(color, radius), child: child);
}

class _DashPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius)).deflate(1));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.radius != radius;
}

/// 두 개 중 하나 고르는 칸 (남 / 여). 시안의 둥근 테두리 안에 초록 알약이 들어 있어요.
class TwoWaySeg extends StatelessWidget {
  final List<(String, String)> items; // (값, 글자)
  final String value;
  final ValueChanged<String> onChanged;
  const TwoWaySeg({super.key, required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
      child: Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: value == items[i].$1,
              child: Material(
                color: value == items[i].$1 ? p.priSoft : p.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onChanged(items[i].$1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    child: Text(items[i].$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: value == items[i].$1 ? p.priText : p.mut)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
