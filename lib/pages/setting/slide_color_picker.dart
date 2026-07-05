import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show LengthLimitingTextInputFormatter, FilteringTextInputFormatter;
import 'package:get/get.dart';

class SlideColorPicker extends StatefulWidget {
  const SlideColorPicker({
    super.key,
    required this.color,
    required this.callback,
    this.showResetBtn = false,
  });

  final Color color;
  final Function(Color? color) callback;
  final bool showResetBtn;

  @override
  State<SlideColorPicker> createState() => _SlideColorPickerState();
}

class _SlideColorPickerState extends State<SlideColorPicker> {
  late int _r;
  late int _g;
  late int _b;
  late final TextEditingController _textController;

  Color get _currentColor => Color.fromARGB(255, _r, _g, _b);

  void _setChannelsFromColor(Color color) {
    _r = color.r.round();
    _g = color.g.round();
    _b = color.b.round();
  }

  void _updateChannels({
    int? r,
    int? g,
    int? b,
  }) {
    _r = r ?? _r;
    _g = g ?? _g;
    _b = b ?? _b;
    _textController.text = _convert;
  }

  @override
  void initState() {
    super.initState();
    _setChannelsFromColor(widget.color);
    _textController = TextEditingController(text: _convert);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _convert =>
      _currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase();

  Widget _slider({
    required String title,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        const SizedBox(width: 16),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(16),
          child: Text(title),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbSize: const WidgetStatePropertyAll(Size(4, 25)),
            ),
            child: Slider(
              padding: EdgeInsets.zero,
              min: 0,
              max: 255,
              divisions: 255,
              value: value.toDouble(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(25) + 16,
          child: Text(
            value.toString(),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 100,
            color: _currentColor,
          ),
          const SizedBox(height: 10),
          IntrinsicWidth(
            child: TextField(
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              ],
              controller: _textController,
              decoration: const InputDecoration(
                isDense: true,
                prefixText: '#',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                _textController.text = value.toUpperCase();
                if (value.length == 6) {
                  final color = Color(
                    int.tryParse('FF$value', radix: 16) ?? 0xFF000000,
                  );
                  setState(() {
                    _setChannelsFromColor(color);
                  });
                }
              },
            ),
          ),
          _slider(
            title: 'R',
            value: _r,
            onChanged: (value) {
              setState(() {
                _updateChannels(r: value.round());
              });
            },
          ),
          _slider(
            title: 'G',
            value: _g,
            onChanged: (value) {
              setState(() {
                _updateChannels(g: value.round());
              });
            },
          ),
          _slider(
            title: 'B',
            value: _b,
            onChanged: (value) {
              setState(() {
                _updateChannels(b: value.round());
              });
            },
          ),
          Row(
            children: [
              if (widget.showResetBtn) ...[
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    Get.back();
                    widget.callback(null);
                  },
                  child: const Text('重置'),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: Get.back,
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  widget.callback(_currentColor);
                },
                child: const Text('确定'),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}
