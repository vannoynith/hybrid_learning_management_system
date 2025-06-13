import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double? elevation;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.padding,
    this.textStyle,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFFFF6949),
          foregroundColor: color ?? const Color(0xFFFF6949),
          minimumSize: const Size(0, 0), // Remove fixed width constraint
          padding:
              padding ??
              const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 24),
          ),
          elevation: elevation ?? 4,
          shadowColor: (color ?? const Color(0xFFFF6949)).withOpacity(0.2),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style:
              textStyle ??
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
