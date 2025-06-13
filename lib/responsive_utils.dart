import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  final BuildContext context;
  final double _baseWidth = 375.0; // Reference width (e.g., iPhone SE)
  final double _baseHeight = 667.0; // Reference height

  ResponsiveUtils(this.context);

  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  /// Scales a width value based on screen width, with optional min/max clamps.
  double scaledWidth(double value, {double? min, double? max}) {
    final scaled = value * (_screenWidth / _baseWidth);
    return _clamp(scaled, min, max);
  }

  /// Scales a height value based on screen height, with optional min/max clamps.
  double scaledHeight(double value, {double? min, double? max}) {
    final scaled = value * (_screenHeight / _baseHeight);
    return _clamp(scaled, min, max);
  }

  /// Scales a font size based on screen width, with optional min/max clamps.
  double scaledFontSize(double fontSize, {double? min, double? max}) {
    final scaled = fontSize * (_screenWidth / _baseWidth);
    return _clamp(scaled, min ?? 10, max ?? 24);
  }

  /// Scales an icon size based on screen width, with optional min/max clamps.
  double scaledIconSize(double iconSize, {double? min, double? max}) {
    final scaled = iconSize * (_screenWidth / _baseWidth);
    return _clamp(scaled, min ?? 16, max ?? 32);
  }

  /// Scales padding/margin based on screen width, with optional min/max clamps.
  double scaledPadding(double padding, {double? min, double? max}) {
    final scaled = padding * (_screenWidth / _baseWidth);
    return _clamp(scaled, min ?? 8, max ?? 24);
  }

  /// Clamps a value between optional min and max bounds.
  double _clamp(double value, double? min, double? max) {
    return min != null && max != null
        ? value.clamp(min, max)
        : min != null
        ? value < min
            ? min
            : value
        : max != null
        ? value > max
            ? max
            : value
        : value;
  }

  /// Determines if the device is mobile, tablet, or desktop.
  bool get isMobile => _screenWidth < 600;
  bool get isTablet => _screenWidth >= 600 && _screenWidth < 900;
  bool get isDesktop => _screenWidth >= 900;
}
