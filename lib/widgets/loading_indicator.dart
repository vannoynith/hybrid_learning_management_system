import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key}); // Removed the required color parameter

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SpinKitFadingCircle(
        color: Color.fromARGB(255, 255, 123, 35), // Fixed color
        size: 50.0,
      ),
    );
  }
}
