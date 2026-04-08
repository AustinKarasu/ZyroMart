import 'dart:async';

import 'package:flutter/material.dart';

class SlideToConfirmButton extends StatefulWidget {
  const SlideToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.backgroundColor = const Color(0xFF1D8C3A),
    this.thumbColor = Colors.white,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 58,
  });

  final String label;
  final FutureOr<void> Function() onConfirmed;
  final Color backgroundColor;
  final Color thumbColor;
  final IconData icon;
  final double height;

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton> {
  static const double _thumbSize = 50;
  double _progress = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = (constraints.maxWidth - _thumbSize - 8).clamp(
          0.0,
          double.infinity,
        );
        final left = 4 + (maxOffset * _progress);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: Center(
                  child: Text(
                    _submitting ? 'Processing...' : widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left,
                child: GestureDetector(
                  onHorizontalDragUpdate: _submitting
                      ? null
                      : (details) {
                          if (maxOffset <= 0) return;
                          setState(() {
                            _progress = (_progress +
                                    (details.delta.dx / maxOffset))
                                .clamp(0.0, 1.0);
                          });
                        },
                  onHorizontalDragEnd: _submitting
                      ? null
                      : (_) => _handleDragEnd(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? Padding(
                            padding: const EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.backgroundColor,
                              ),
                            ),
                          )
                        : Icon(widget.icon, color: widget.backgroundColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDragEnd() async {
    if (_progress < 0.82) {
      setState(() => _progress = 0);
      return;
    }
    setState(() {
      _progress = 1;
      _submitting = true;
    });
    try {
      await widget.onConfirmed();
    } finally {
      if (mounted) {
        setState(() {
          _progress = 0;
          _submitting = false;
        });
      }
    }
  }
}
