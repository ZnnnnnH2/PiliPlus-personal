import 'package:PiliPlus/common/widgets/list_tile.dart';
import 'package:PiliPlus/pages/setting/widgets/item_style.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SetSwitchItem extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? setKey;
  final bool defaultVal;
  final ValueChanged<bool>? onChanged;
  final bool needReboot;
  final Widget? leading;
  final Function? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;

  const SetSwitchItem({
    this.title,
    this.subtitle,
    this.setKey,
    this.defaultVal = false,
    this.onChanged,
    this.needReboot = false,
    this.leading,
    this.onTap,
    this.contentPadding,
    this.titleStyle,
    super.key,
  });

  @override
  State<SetSwitchItem> createState() => _SetSwitchItemState();
}

class _SetSwitchItemState extends State<SetSwitchItem> {
  late bool val;

  bool _readSettingValue() {
    if (widget.setKey == SettingBoxKey.appFontWeight) {
      return Pref.appFontWeight != -1;
    }
    return GStorage.setting.get(
      widget.setKey,
      defaultValue: widget.defaultVal,
    );
  }

  void _syncValue() {
    val = _readSettingValue();
  }

  @override
  void didUpdateWidget(SetSwitchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setKey != widget.setKey) {
      _syncValue();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncValue();
  }

  Future<void> _persistValue(bool value) async {
    if (widget.setKey == SettingBoxKey.appFontWeight) {
      await GStorage.setting.put(SettingBoxKey.appFontWeight, value ? 4 : -1);
      return;
    }
    await GStorage.setting.put(widget.setKey, value);
  }

  bool _shouldConfirmDisableSsl(bool? value) {
    return widget.setKey == SettingBoxKey.badCertificateCallback &&
        (value ?? !val);
  }

  void _showDisableSslDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定禁用 SSL 证书验证？'),
        content: const Text('禁用容易受到中间人攻击'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _persistValue(true);
              val = true;
              SmartDialog.showToast('重启生效');
              setState(() {});
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchChange(ThemeData theme, bool? value) async {
    if (_shouldConfirmDisableSsl(value)) {
      _showDisableSslDialog(theme);
      return;
    }

    final nextValue = value ?? !val;
    val = nextValue;
    await _persistValue(nextValue);
    widget.onChanged?.call(nextValue);
    if (widget.needReboot) {
      SmartDialog.showToast('重启生效');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        widget.titleStyle ??
        settingTitleStyle(
          theme,
          color: widget.onTap != null && !val
              ? theme.colorScheme.outline
              : null,
        );
    final subTitleStyle = settingSubtitleStyle(theme);
    return ListTile(
      contentPadding: widget.contentPadding,
      enabled: widget.onTap != null ? val : true,
      onTap: () =>
          widget.onTap != null ? widget.onTap!() : _switchChange(theme, null),
      title: Text(widget.title!, style: titleStyle),
      subtitle: widget.subtitle != null
          ? Text(widget.subtitle!, style: subTitleStyle)
          : null,
      leading: widget.leading,
      trailing: Transform.scale(
        alignment: Alignment.centerRight,
        scale: 0.8,
        child: Switch(
          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
            Set<WidgetState> states,
          ) {
            if (states.isNotEmpty && states.first == WidgetState.selected) {
              return const Icon(Icons.done);
            }
            return null;
          }),
          value: val,
          onChanged: (value) => _switchChange(theme, value),
        ),
      ),
    );
  }
}
