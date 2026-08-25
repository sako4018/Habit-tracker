import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CheckButton extends StatefulWidget {
  final bool isDone;
  final VoidCallback onTap;

  const CheckButton({
    super.key,
    required this.isDone,
    required this.onTap,
  });

  @override
  State<CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  bool _showBurst = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final willBeDone = !widget.isDone;

    widget.onTap();

    if (willBeDone) {
      _controller.forward(from: 0);

      setState(() {
        _showBurst = true;
      });

      Future.delayed(
        const Duration(milliseconds: 550),
        () {
          if (mounted) {
            setState(() {
              _showBurst = false;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('check_button'),
      onTap: _handleTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_showBurst) const _BurstEffect(),

            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isDone
                      ? AppColors.accent
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isDone
                        ? AppColors.accent
                        : Colors.grey.shade600,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.isDone
                    ? const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurstEffect extends StatefulWidget {
  const _BurstEffect();

  @override
  State<_BurstEffect> createState() => _BurstEffectState();
}

class _BurstEffectState extends State<_BurstEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<double> _angles = List.generate(
    6,
    (i) => i * (360 / 6),
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: _angles.map((angle) {
            final rad = angle * pi / 180;
            final distance = 26 * t;

            final dx = cos(rad) * distance;
            final dy = sin(rad) * distance;

            return Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: const Icon(
                  Icons.star,
                  size: 10,
                  color: AppColors.accent,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}