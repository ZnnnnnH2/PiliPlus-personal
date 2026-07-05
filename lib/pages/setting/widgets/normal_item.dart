import 'package:PiliPlus/common/widgets/list_tile.dart';
import 'package:PiliPlus/pages/setting/widgets/item_style.dart';
import 'package:flutter/material.dart' hide ListTile;

typedef StringGetter = String Function();

class NormalItem extends StatefulWidget {
  final String? title;
  final StringGetter? getTitle;
  final String? subtitle;
  final StringGetter? getSubtitle;
  final String? setKey;
  final Widget? leading;
  final Widget Function()? getTrailing;
  final Function? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;

  const NormalItem({
    this.title,
    this.getTitle,
    this.subtitle,
    this.getSubtitle,
    this.setKey,
    this.leading,
    this.getTrailing,
    this.onTap,
    this.contentPadding,
    this.titleStyle,
    super.key,
  }) : assert(title != null || getTitle != null);

  @override
  State<NormalItem> createState() => _NormalItemState();
}

class _NormalItemState extends State<NormalItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: widget.contentPadding,
      onTap: () => widget.onTap?.call(() {
        setState(() {});
      }),
      title: Text(
        widget.title ?? widget.getTitle!(),
        style: widget.titleStyle ?? settingTitleStyle(theme),
      ),
      subtitle: widget.subtitle != null || widget.getSubtitle != null
          ? Text(
              widget.subtitle ?? widget.getSubtitle!(),
              style: settingSubtitleStyle(theme),
            )
          : null,
      leading: widget.leading,
      trailing: widget.getTrailing?.call(),
    );
  }
}
