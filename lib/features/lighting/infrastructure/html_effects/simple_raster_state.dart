/// Context state that survives between fast frames (the shim only sends
/// changes, just like a real canvas).
///
/// A null field is unknown: the general replay drew the last frame and left a
/// style the fast path cannot reproduce (a gradient, a restored state...).
/// A frame may only rely on a field after it set it.
class SimpleRasterState {
  const SimpleRasterState({
    this.fill = 0xff000000,
    this.alpha = 1,
    this.srcOver = true,
  });

  /// Nothing about the context is known.
  static const unknown = SimpleRasterState(
    fill: null,
    alpha: null,
    srcOver: null,
  );

  final int? fill;
  final double? alpha;
  final bool? srcOver;

  @override
  bool operator ==(Object other) =>
      other is SimpleRasterState &&
      other.fill == fill &&
      other.alpha == alpha &&
      other.srcOver == srcOver;

  @override
  int get hashCode => Object.hash(fill, alpha, srcOver);
}
