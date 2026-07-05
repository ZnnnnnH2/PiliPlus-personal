import 'package:flutter/material.dart';

/// https://stackoverflow.com/a/76605401

class SelfSizedHorizontalList extends StatefulWidget {
  final Widget Function(int index) childBuilder;
  final int itemCount;
  final double gapSize;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const SelfSizedHorizontalList({
    super.key,
    required this.childBuilder,
    required this.itemCount,
    this.gapSize = 5,
    this.padding,
    this.controller,
  });

  @override
  State<SelfSizedHorizontalList> createState() =>
      _SelfSizedHorizontalListState();
}

class _SelfSizedHorizontalListState extends State<SelfSizedHorizontalList> {
  final infoKey = GlobalKey();
  double? _height;
  bool _measureScheduled = false;

  void _scheduleMeasure() {
    if (_measureScheduled || !mounted || widget.itemCount == 0) {
      return;
    }
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) {
        return;
      }
      final nextHeight = infoKey.globalPaintBounds?.height;
      if (nextHeight != null && nextHeight != _height) {
        setState(() {
          _height = nextHeight;
        });
      }
    });
  }

  void _invalidateHeight() {
    _height = null;
    _scheduleMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invalidateHeight();
  }

  @override
  void didUpdateWidget(SelfSizedHorizontalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.gapSize != widget.gapSize ||
        oldWidget.padding != widget.padding) {
      _invalidateHeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }
    if (_height == null) {
      _scheduleMeasure();
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          key: infoKey,
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.childBuilder(0),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        controller: widget.controller,
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        itemBuilder: (c, i) => widget.childBuilder(i),
        separatorBuilder: (c, i) => SizedBox(width: widget.gapSize),
      ),
    );
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
