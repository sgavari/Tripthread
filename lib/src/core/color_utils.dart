import 'package:flutter/material.dart';

/// A soft, cohesive palette (tonal variations within the app's ocean-blue
/// family) for giving things without their own photo (a trip with no
/// destination photo yet, a member with no avatar) a stable, distinct touch
/// of color instead of a flat gray box — without clashing like a rainbow of
/// unrelated hues would.
const _palette = [
  Color(0xFF3E7FA6), // ocean blue
  Color(0xFF5FA8B8), // soft teal
  Color(0xFF2C6B84), // deep teal
  Color(0xFF6FA8A0), // seafoam
  Color(0xFF4A6FA5), // denim
  Color(0xFF7BB8C9), // sky
];

/// Deterministic color from [key] (e.g. a trip or user id) — same input
/// always gets the same color, spread across the palette.
Color colorForKey(String key) => _palette[key.hashCode.abs() % _palette.length];
