part of '../main_spike.dart';

class _SpikePageState extends State<SpikePage> {
  IsolatedHtmlEffectRuntime? _rt;
  int _index = 0;
  Timer? _timer;
  bool _busy = false, _hidden = false;
  final _clock = Stopwatch()..start();
  var _stats = _SpikeStats(), _hiddenStats = _SpikeStats();
  Color _led = Colors.black;
  ui.Image? _preview;
  String _status = '';
  final _results = <String>[];

  @override
  void initState() {
    super.initState();
    if (widget.only != null) {
      _index = widget.files
          .indexWhere((f) => f.path.contains(widget.only!))
          .clamp(0, 1 << 30);
    }
    _start();
  }

  Future<void> _start() async {
    _timer?.cancel();
    _rt?.dispose();
    _rt = null;
    _stats = _SpikeStats();
    _hiddenStats = _SpikeStats();
    final file = widget.files[_index];
    try {
      _rt = await IsolatedHtmlEffectRuntime.load(await file.readAsString());
    } catch (e) {
      setState(() => _status = 'erro ao carregar ${file.path}: $e');
      stdout.writeln(_status);
      return;
    }
    _timer = Timer.periodic(
      const Duration(microseconds: 1000000 ~/ _fps),
      (_) => _tick(),
    );
    setState(() {});
    if (widget.auto) unawaited(_autoRun());
  }

  Future<void> _tick() async {
    final rt = _rt;
    if (rt == null || _busy) return;
    _busy = true;
    try {
      final frame = await rt.renderFrame(_clock.elapsedMicroseconds / 1000);
      // Mesmo caminho que a engine vai usar: RGBA cru → amostra nos LEDs.
      final sw = Stopwatch()..start();
      final px = _sample(frame.rgba, 160, 100);
      (_hidden ? _hiddenStats : _stats).add(rt, sw.elapsed);
      for (final l in rt.drainLog()) {
        stdout.writeln('[js] $l');
      }
      if (!_hidden && mounted) {
        setState(() {
          _led = px;
          _preview?.dispose();
          _preview = rt.preview?.clone();
        });
      }
    } catch (e) {
      _timer?.cancel();
      stdout.writeln('erro no quadro: $e');
      if (mounted) setState(() => _status = '$e');
    } finally {
      _busy = false;
    }
  }

  Color _sample(Uint8List b, int x, int y) {
    final o = (y * IsolatedHtmlEffectRuntime.width + x) * 4;
    return Color.fromARGB(255, b[o], b[o + 1], b[o + 2]);
  }

  /// The spike reports the process share of one core; dividing by the core
  /// count gives the share of the whole machine (what `top`/Task Manager show).
  String _cpuLabel(double cpu) {
    final total = cpu / Platform.numberOfProcessors;
    return 'CPU ${cpu.toStringAsFixed(1)} % '
        '(${total.toStringAsFixed(1)} % da máquina)';
  }

  Future<void> _hideFor(Duration d) async {
    _hiddenStats = _SpikeStats();
    final cpu0 = _cpuTicks();
    final t0 = _clock.elapsed;
    _hidden = true;
    await windowManager.hide();
    await Future<void>.delayed(d);
    final secs = (_clock.elapsed - t0).inMilliseconds / 1000;
    final cpu = (_cpuTicks() - cpu0) / (secs * 100) * 100;
    await windowManager.show();
    _hidden = false;
    final fps = _hiddenStats.frames / secs;
    final line =
        'OCULTA ${secs.toStringAsFixed(1)} s: ${fps.toStringAsFixed(1)} fps · '
        '${_cpuLabel(cpu)} · $_hiddenStats';
    stdout.writeln(line);
    _results.add(line);
    if (mounted) setState(() => _status = line);
  }

  Future<void> _autoRun() async {
    // The runtime may be replaced or disposed while this run awaits (effect
    // switch, widget disposal); abort instead of dereferencing a stale one.
    final rt = _rt;
    if (rt == null) return;
    bool stale() => !mounted || !identical(_rt, rt);
    final name = rt.effect.title;
    stdout.writeln(
      '== $name (${rt.effect.properties.map((p) => '${p.name}=${p.initialValue}').join(', ')})',
    );
    final cpu0 = _cpuTicks();
    final t0 = _clock.elapsed;
    await Future<void>.delayed(const Duration(seconds: 4));
    if (stale()) return;
    final secs = (_clock.elapsed - t0).inMilliseconds / 1000;
    final cpu = (_cpuTicks() - cpu0) / (secs * 100) * 100;
    stdout.writeln(
      'VISIBLE ${secs.toStringAsFixed(1)} s: '
      '${(_stats.frames / secs).toStringAsFixed(1)} fps · ${_cpuLabel(cpu)} · $_stats',
    );
    stdout.writeln(
      'LED (160,100) = #${(_led.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
    );
    final dump = widget.dump;
    if (dump != null && rt.preview != null) {
      final png = await rt.snapshotPng();
      if (stale()) return;
      final f = File('$dump/${name.replaceAll(' ', '_')}.png');
      await f.writeAsBytes(png!);
      stdout.writeln('quadro salvo em ${f.path}');
    }
    await _hideFor(const Duration(seconds: 10));
    if (stale()) return;
    final before = _stats.frames;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (stale()) return;
    stdout.writeln('VISIBLE again: ${_stats.frames - before} frames in 3 s');
    final unknown = rt.unknownOps;
    stdout.writeln(
      'unsupported ops: ${unknown.isEmpty ? 'none' : unknown.join(', ')}',
    );
    // Chain the next effect; exit after the last one.
    if (widget.only == null && _index + 1 < widget.files.length) {
      _index++;
      await _start();
    } else {
      exit(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rt?.dispose();
    _preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<int>(
                  value: _index,
                  items: [
                    for (var i = 0; i < widget.files.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(widget.files[i].uri.pathSegments.last),
                      ),
                  ],
                  onChanged: (i) {
                    _index = i!;
                    _start();
                  },
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => _hideFor(const Duration(seconds: 10)),
                  child: const Text('Ocultar 10 s'),
                ),
                const SizedBox(width: 16),
                Container(width: 32, height: 32, color: _led),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 320 / 200,
              child: _preview == null
                  ? const ColoredBox(color: Colors.black)
                  : RawImage(
                      image: _preview,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
            ),
            const SizedBox(height: 16),
            Text('$_stats'),
            Text(_status),
            for (final r in _results) Text(r),
          ],
        ),
      ),
    );
  }
}
