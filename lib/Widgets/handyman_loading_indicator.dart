import 'package:flutter/material.dart';

class HandymanLoadingIndicator extends StatefulWidget {
  const HandymanLoadingIndicator({super.key});

  @override
  _HandymanLoadingIndicatorState createState() =>
      _HandymanLoadingIndicatorState();
}

class _HandymanLoadingIndicatorState extends State<HandymanLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize AnimationController to rotate the handyman icon
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Continuous loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Rotate the icon during loading
          return Transform.rotate(
            angle: _controller.value * 2.0 * 3.1416, // Full 360-degree rotation
            child: child,
          );
        },
        child: const Icon(
          Icons.handyman_outlined,
          size: 100.0,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
