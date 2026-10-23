import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumivent/core/ui/async_action.dart';

part 'probe_state.dart';

class Probe extends StatefulWidget {
  const Probe({super.key, required this.body});

  final Future<void> Function() body;

  @override
  State<Probe> createState() => ProbeState();
}
