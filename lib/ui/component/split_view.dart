import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxypin/l10n/app_localizations.dart';

class VerticalSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double ratio;
  final double minRatio;
  final double maxRatio;
  final Function(double ratio)? onRatioChanged;

  const VerticalSplitView(
      {super.key,
      required this.left,
      required this.right,
      this.ratio = 0.5,
      this.minRatio = 0,
      this.maxRatio = 1,
      this.onRatioChanged})
      : assert(ratio >= 0 && ratio <= 1);

  @override
  State<VerticalSplitView> createState() => _VerticalSplitViewState();
}

class _VerticalSplitViewState extends State<VerticalSplitView> {
  final _dividerWidth = 10.0;
  static const _keyboardStep = 0.02;

  //from 0-1
  late double _ratio;
  double _maxWidth = double.infinity;

  get _width1 => _ratio * _maxWidth;

  get _width2 => (1 - _ratio) * _maxWidth;

  void _updateRatio(double nextRatio) {
    final clamped = nextRatio.clamp(widget.minRatio, widget.maxRatio).toDouble();
    if (clamped == _ratio) return;
    setState(() {
      _ratio = clamped;
    });
    widget.onRatioChanged?.call(_ratio);
  }

  @override
  void initState() {
    super.initState();
    _ratio = widget.ratio;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      if (_maxWidth != constraints.maxWidth) {
        _maxWidth = constraints.maxWidth - _dividerWidth;
      }

      return SizedBox(
        width: constraints.maxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _width1 - 5,
              child: widget.left,
            ),
            Semantics(
              label: localizations.resizePane,
              value: '${(_ratio * 100).round()}%',
              increasedValue: '${((_ratio + _keyboardStep).clamp(widget.minRatio, widget.maxRatio) * 100).round()}%',
              decreasedValue: '${((_ratio - _keyboardStep).clamp(widget.minRatio, widget.maxRatio) * 100).round()}%',
              focusable: true,
              onIncrease: () => _updateRatio(_ratio + _keyboardStep),
              onDecrease: () => _updateRatio(_ratio - _keyboardStep),
              child: Focus(
                canRequestFocus: true,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _updateRatio(_ratio - _keyboardStep);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _updateRatio(_ratio + _keyboardStep);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanEnd: (DragEndDetails details) {
                    widget.onRatioChanged?.call(_ratio);
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    _updateRatio(_ratio + details.delta.dx / _maxWidth);
                  },
                  child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: SizedBox(
                        width: _dividerWidth,
                        height: double.infinity,
                        child: (_ratio <= 0 || _ratio >= 1)
                            ? const Icon(Icons.drag_handle, size: 16)
                            : const VerticalDivider(thickness: 1),
                      )),
                ),
              ),
            ),
            SizedBox(
              width: _width2,
              child: widget.right,
            ),
          ],
        ),
      );
    });
  }
}
