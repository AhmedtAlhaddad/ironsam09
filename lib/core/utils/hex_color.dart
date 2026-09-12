import 'package:flutter/material.dart';

final _sixDigitHex = RegExp(r'^#[0-9A-Fa-f]{6}$');

bool isValidHexColor(String? value) =>
    value != null && _sixDigitHex.hasMatch(value.trim());

Color? colorFromHex(String? value) {
  final normalized = value?.trim();
  if (!isValidHexColor(normalized)) return null;
  return Color(int.parse(normalized!.substring(1), radix: 16) | 0xFF000000);
}
