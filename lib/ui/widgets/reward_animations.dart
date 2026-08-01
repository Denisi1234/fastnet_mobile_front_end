import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HeartSaveButton — animated ❤️ that springs + bursts particles on save
// ─────────────────────────────────────────────────────────────────────────────
class HeartSaveButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onToggle;
  final double size;

  const HeartSaveButton({
    Key? key,
    required this.isSaved,
    required this.onToggle,
    this.size = 20,
  }) : super(key: key);

  @override
  State<HeartSaveButton> createState() => _HeartSaveButtonState();
}

class _HeartSaveButtonState extends State<HeartSaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _particleOpacity;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Spring: grow → shrink → bounce back
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.55, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _particleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    widget.onToggle();
    if (!widget.isSaved) {
      // Saving (will become saved after toggle)
      setState(() => _showParticles = true);
      _ctrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _showParticles = false);
      });
    } else {
      // Un-saving: just a quick shrink
      _ctrl.forward(from: 0.5).then((_) => _ctrl.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: SizedBox(
        width: widget.size + 24,
        height: widget.size + 24,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Particle burst (only on save)
                if (_showParticles)
                  ...List.generate(6, (i) {
                    final angle = (i / 6) * 2 * pi;
                    final progress = _ctrl.value;
                    final radius = progress * (widget.size * 1.4);
                    return Positioned(
                      left: (widget.size + 24) / 2 + cos(angle) * radius - 3,
                      top: (widget.size + 24) / 2 + sin(angle) * radius - 3,
                      child: Opacity(
                        opacity: _particleOpacity.value,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i.isEven ? Colors.red.shade400 : Colors.pink.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                // Heart icon with spring scale
                Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isSaved ? Icons.favorite : Icons.favorite_border,
                      color: widget.isSaved ? Colors.red.shade600 : Colors.grey.shade400,
                      size: widget.size,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConfettiOverlay — full-screen confetti celebration
// Call ConfettiOverlay.show(context) after payment success
// ─────────────────────────────────────────────────────────────────────────────
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context, {int durationMs = 2800}) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => const ConfettiOverlay(),
    );
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Particle {
  late double x, y, vx, vy, size, rot, rotSpeed;
  late Color color;
  late _ParticleShape shape;
}

enum _ParticleShape { circle, rect, triangle }

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  final List<_Particle> _particles = [];
  late AnimationController _ctrl;

  static const _colors = [
    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFF2EC4B6),
    Color(0xFF7209B7), Color(0xFF3A86FF), Color(0xFFFFBE0B),
    Color(0xFF06D6A0), Color(0xFFEF476F),
  ];

  @override
  void initState() {
    super.initState();
    _spawnParticles();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() {
        _updateParticles();
        if (_ctrl.isCompleted && mounted) Navigator.of(context).pop();
      });
    _ctrl.forward();
  }

  void _spawnParticles() {
    for (int i = 0; i < 90; i++) {
      final p = _Particle();
      p.x = _rng.nextDouble();
      p.y = -_rng.nextDouble() * 0.5; // start above screen
      p.vx = (_rng.nextDouble() - 0.5) * 0.008;
      p.vy = 0.003 + _rng.nextDouble() * 0.007;
      p.size = 6 + _rng.nextDouble() * 8;
      p.rot = _rng.nextDouble() * 2 * pi;
      p.rotSpeed = (_rng.nextDouble() - 0.5) * 0.15;
      p.color = _colors[_rng.nextInt(_colors.length)];
      p.shape = _ParticleShape.values[_rng.nextInt(3)];
      _particles.add(p);
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.rot += p.rotSpeed;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(size.width, size.height),
          painter: _ConfettiPainter(_particles, size),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Size screenSize;
  _ConfettiPainter(this.particles, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.y > 1.2) continue;
      final paint = Paint()..color = p.color;
      final cx = p.x * screenSize.width;
      final cy = p.y * screenSize.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rot);

      switch (p.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ParticleShape.rect:
          canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
              paint);
          break;
        case _ParticleShape.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingSuccessPulse — green checkmark that scales in with a ripple ring
// Wrap around a child widget to show on mount
// ─────────────────────────────────────────────────────────────────────────────
class BookingSuccessPulse extends StatefulWidget {
  final Widget child;
  const BookingSuccessPulse({Key? key, required this.child}) : super(key: key);

  @override
  State<BookingSuccessPulse> createState() => _BookingSuccessPulseState();
}

class _BookingSuccessPulseState extends State<BookingSuccessPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ringScale = Tween<double>(begin: 0.6, end: 2.4).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 1.0)),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple ring
            Transform.scale(
              scale: _ringScale.value,
              child: Opacity(
                opacity: _ringOpacity.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade400, width: 3),
                  ),
                ),
              ),
            ),
            // Checkmark icon
            Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
