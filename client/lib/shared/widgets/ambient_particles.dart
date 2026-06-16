import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AmbientParticles extends StatefulWidget {
  final int count;
  final Color? color;

  const AmbientParticles({
    super.key,
    this.count = 35,
    this.color,
  });

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late List<_Particle> _particles;
  final Random _random = Random();
  Size? _lastSize;
  double _elapsedTime = 0.0;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _Particle(_random));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastSize == null) return;
    
    // Compute dt safely
    final double currentMs = elapsed.inMilliseconds.toDouble();
    _elapsedTime = currentMs / 1000.0;
    
    setState(() {
      for (final p in _particles) {
        p.update(_lastSize!, _elapsedTime);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final particleColor = widget.color ?? (isDark ? const Color(0xFFCDC8EE) : const Color(0xFF7A6E5E));

    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);
        _lastSize = currentSize;
        
        // Initialize particle positions if first frame
        for (final p in _particles) {
          if (p.x == 0.0 && p.y == 0.0) {
            p.initializePosition(currentSize);
          }
        }

        return RepaintBoundary(
          child: CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              color: particleColor,
              totalTime: _elapsedTime,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _Particle {
  final Random random;
  double x = 0.0;
  double y = 0.0;
  double speed = 0.0;
  double baseSize = 0.0;
  double currentSize = 0.0;
  double baseOpacity = 0.0;
  double currentOpacity = 0.0;
  double swayAmplitude = 0.0;
  double swaySpeed = 0.0;
  double offset = 0.0;

  _Particle(this.random) {
    speed = random.nextDouble() * 8 + 4; // slow drift (pixels per sec)
    baseSize = random.nextDouble() * 2.5 + 1.2;
    baseOpacity = random.nextDouble() * 0.35 + 0.1;
    swayAmplitude = random.nextDouble() * 6 + 3;
    swaySpeed = random.nextDouble() * 1.2 + 0.4;
    offset = random.nextDouble() * pi * 2;
  }

  void initializePosition(Size size) {
    x = random.nextDouble() * size.width;
    y = random.nextDouble() * size.height;
  }

  void update(Size bounds, double totalTime) {
    // Drifts slowly upwards
    y -= speed * 0.016; 
    
    // Wrap around top border
    if (y < -10.0) {
      y = bounds.height + 10.0;
      x = random.nextDouble() * bounds.width;
    }
    
    // Pulse sizes and opacities slightly over time
    currentOpacity = (baseOpacity + sin(totalTime * 1.8 + offset) * 0.08).clamp(0.01, 0.5);
    currentSize = (baseSize + cos(totalTime * 1.2 + offset) * 0.4).clamp(0.5, 4.0);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double totalTime;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.totalTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (final p in particles) {
      paint.color = color.withValues(alpha: p.currentOpacity);
      
      // Calculate dynamic visual sway position using time
      final sway = sin(totalTime * p.swaySpeed + p.offset) * p.swayAmplitude;
      final drawX = (p.x + sway).clamp(0.0, size.width);
      
      canvas.drawCircle(Offset(drawX, p.y), p.currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
