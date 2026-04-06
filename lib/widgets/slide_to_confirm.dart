import 'package:flutter/material.dart';

class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.confirmLabel,
    required this.onConfirmed,
    this.icon = Icons.chevron_right_rounded,
    this.backgroundColor = const Color(0xFF1D8C3A),
    this.knobColor = Colors.white,
    this.textColor = Colors.white,
    this.height = 56,
  });

  final String label;
  final String confirmLabel;
  final Future<bool> Function() onConfirmed;
  final IconData icon;
  final Color backgroundColor;
  final Color knobColor;
  final Color textColor;
  final double height;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const double _knobInset = 4;
  double _progress = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final knobSize = widget.height - (_knobInset * 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDx = (trackWidth - knobSize - (_knobInset * 2))
            .clamp(0, double.infinity)
            .toDouble();
        final knobDx = maxDx * _progress;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _progress < 0.9 ? 1 : 0,
                  child: Text(
                    _busy ? widget.confirmLabel : widget.label,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _knobInset + knobDx,
                top: _knobInset,
                child: GestureDetector(
                  onHorizontalDragUpdate: _busy
                      ? null
                      : (details) {
                          if (maxDx <= 0) return;
                          setState(() {
                            _progress = (_progress + (details.delta.dx / maxDx))
                                .clamp(0, 1);
                          });
                        },
                  onHorizontalDragEnd: _busy
                      ? null
                      : (_) => _onDragEnd(maxDx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: widget.knobColor,
                      borderRadius: BorderRadius.circular(knobSize / 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _busy
                        ? SizedBox(
                            width: knobSize * 0.4,
                            height: knobSize * 0.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.backgroundColor,
                              ),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: widget.backgroundColor,
                            size: knobSize * 0.46,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onDragEnd(double maxDx) async {
    if (_progress < 0.88 || maxDx <= 0) {
      setState(() => _progress = 0);
      return;
    }
    setState(() => _busy = true);
    final confirmed = await widget.onConfirmed();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = confirmed ? 1 : 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _progress = 0);
  }
}
