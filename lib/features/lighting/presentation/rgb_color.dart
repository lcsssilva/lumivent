// Converts domain colors to Flutter colors for the lighting widgets.

import 'package:flutter/material.dart';

import '../domain/rgb.dart';

Color toColor(Rgb c) => Color.fromARGB(255, c.r, c.g, c.b);
