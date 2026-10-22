// Browser-environment shim for HTML/Canvas effects running on QuickJS.
// It draws nothing: it records CanvasRenderingContext2D calls into a binary
// buffer (base64 on the way out) that Dart replays into a dart:ui Canvas
// (canvas_replay.dart). The buffer replaces the spike's JSON commands
// (plan §5.1), and `beginPath` + `rect` + `fill` becomes a single `fillRect`.
//
// Protocol: the host calls __we_frame(nowMs), which runs requestAnimationFrame
// callbacks and due timers, then returns the buffer as base64.
(function (g) {
  "use strict";
  var W = 320, H = 200;
  var now = 0;

  function num(v) { v = +v; return isFinite(v) ? v : 0; }

  // ---- opcodes (same table as canvas_replay.dart) ------------------------
  var OP = {
    unknown: 0,
    fs: 1, ss: 2, lw: 3, ga: 4, gco: 5, lc: 6, lj: 7,
    sv: 8, rs: 9,
    tr: 10, ro: 11, sc: 12, tf: 13, st: 14,
    cr: 15, fr: 16, sr: 17,
    bp: 18, cp: 19, mt: 20, lt: 21, re: 22, ar: 23, el: 24, qc: 25, bc: 26,
    f: 27, s: 28, cl: 29,
    lg: 30, rg: 31, cs: 32, f16: 33, fsh: 34, f16h: 35,
  };

  // ---- binary buffer -----------------------------------------------------
  var buf = new ArrayBuffer(16384);
  var bytes = new Uint8Array(buf);
  var view = new DataView(buf);
  var pos = 0;
  var maxBufferBytes = 4 * 1024 * 1024;

  function ensure(n) {
    if (pos + n > maxBufferBytes) {
      throw new Error("canvas command buffer limit exceeded");
    }
    if (pos + n <= buf.byteLength) return;
    var size = buf.byteLength;
    while (size < pos + n) size = Math.min(size * 2, maxBufferBytes);
    var next = new ArrayBuffer(size);
    new Uint8Array(next).set(bytes.subarray(0, pos));
    buf = next;
    bytes = new Uint8Array(next);
    view = new DataView(next);
  }
  function putU8(v) { ensure(1); bytes[pos++] = v & 255; }
  function putU16(v) { ensure(2); view.setUint16(pos, v, true); pos += 2; }
  function putF32(v) { ensure(4); view.setFloat32(pos, num(v), true); pos += 4; }

  // Float argument (tag 0). The caller has already reserved the 5 bytes.
  function putF(v) {
    bytes[pos++] = 0;
    view.setFloat32(pos, num(v), true);
    pos += 4;
  }
  // Packed ARGB color (tag 3). Avoids UTF-8 and CSS parsing in Dart.
  function putC(c) {
    bytes[pos++] = 3;
    view.setUint32(pos, c >>> 0, true);
    pos += 4;
  }
  function putG(id) {
    bytes[pos++] = 2;
    view.setFloat32(pos, id, true);
    pos += 4;
  }

  // UTF-8 written straight into the buffer, without per-character arrays.
  function putS(str) {
    str = str === undefined || str === null ? "" : String(str);
    var n = str.length;
    ensure(3 + n * 3);
    var tag = pos;
    pos += 3;
    var start = pos;
    for (var i = 0; i < n; i++) {
      var c = str.charCodeAt(i);
      if (c < 0x80) {
        bytes[pos++] = c;
      } else if (c < 0x800) {
        bytes[pos++] = 0xc0 | (c >> 6);
        bytes[pos++] = 0x80 | (c & 63);
      } else if (c >= 0xd800 && c <= 0xdbff && i + 1 < n) {
        var d = str.charCodeAt(++i);
        var cp = 0x10000 + ((c - 0xd800) << 10) + (d - 0xdc00);
        bytes[pos++] = 0xf0 | (cp >> 18);
        bytes[pos++] = 0x80 | ((cp >> 12) & 63);
        bytes[pos++] = 0x80 | ((cp >> 6) & 63);
        bytes[pos++] = 0x80 | (cp & 63);
      } else {
        bytes[pos++] = 0xe0 | (c >> 12);
        bytes[pos++] = 0x80 | ((c >> 6) & 63);
        bytes[pos++] = 0x80 | (c & 63);
      }
    }
    var len = pos - start;
    bytes[tag] = 1;
    view.setUint16(tag + 1, len, true);
  }

  function emitNoArgs(code) {
    ensure(2);
    bytes[pos++] = code;
    bytes[pos++] = 0;
  }
  function emitNumber(code, v) {
    ensure(7);
    bytes[pos++] = code;
    bytes[pos++] = 1;
    putF(v);
  }
  function emitString(code, str) {
    ensure(2);
    bytes[pos++] = code;
    bytes[pos++] = 1;
    putS(str);
  }
  function emitColorArg(code, c) {
    ensure(7);
    bytes[pos++] = code;
    bytes[pos++] = 1;
    putC(c);
  }
  function emitRect(code, x, y, w, h) {
    ensure(22);
    bytes[pos++] = code;
    bytes[pos++] = 4;
    putF(x); putF(y); putF(w); putF(h);
  }
  function isI16(v) {
    return v === (v | 0) && v >= -32768 && v <= 32767;
  }
  // Opaque rect with a color: 13 bytes (opcode + 4×int16 + ARGB), no `fs`.
  function emitRect16(x, y, w, h, color) {
    ensure(13);
    bytes[pos++] = OP.f16;
    view.setInt16(pos, x, true); pos += 2;
    view.setInt16(pos, y, true); pos += 2;
    view.setInt16(pos, w, true); pos += 2;
    view.setInt16(pos, h, true); pos += 2;
    view.setUint32(pos, color >>> 0, true); pos += 4;
  }
  // Compact HSL: 4×int16 + h in tenths + s + l (13 bytes). Dart computes RGB;
  // QuickJS only converts the three numbers from the string.
  function emitRect16Hsl(x, y, w, h, hue, sat, lit) {
    ensure(13);
    bytes[pos++] = OP.f16h;
    view.setInt16(pos, x, true); pos += 2;
    view.setInt16(pos, y, true); pos += 2;
    view.setInt16(pos, w, true); pos += 2;
    view.setInt16(pos, h, true); pos += 2;
    hue = hue % 360;
    if (hue < 0) hue += 360;
    view.setInt16(pos, Math.round(hue * 10), true); pos += 2;
    bytes[pos++] = sat < 0 ? 0 : (sat > 100 ? 100 : Math.round(sat));
    bytes[pos++] = lit < 0 ? 0 : (lit > 100 ? 100 : Math.round(lit));
  }
  function emitFillRect(x, y, w, h) {
    if (st.globalAlpha === 1 &&
        st.globalCompositeOperation === "source-over" &&
        isI16(x) && isI16(y) && isI16(w) && isI16(h)) {
      if (hasPendingHsl) {
        emitRect16Hsl(x, y, w, h, hslH, hslS, hslL);
        return;
      }
      if (pendingFill !== null && (pendingFill >>> 24) === 255) {
        emitRect16(x, y, w, h, pendingFill);
        return;
      }
    }
    flushFill();
    emitRect(OP.fr, x, y, w, h);
  }

  // Generic path (gradients, curves); hot paths use the helpers above.
  function emit(code, args) {
    ensure(2 + args.length * 9);
    bytes[pos++] = code;
    bytes[pos++] = args.length;
    for (var i = 0; i < args.length; i++) {
      var v = args[i];
      if (typeof v === "number") putF(v);
      else if (v instanceof Gradient) putG(v.__id);
      else putS(String(v));
    }
  }

  // ---- CSS colors → ARGB -----------------------------------------------
  var NAMED = {
    transparent: 0x00000000, black: 0xff000000, white: 0xffffffff,
    red: 0xffff0000, green: 0xff008000, lime: 0xff00ff00,
    blue: 0xff0000ff, yellow: 0xffffff00, cyan: 0xff00ffff,
    aqua: 0xff00ffff, magenta: 0xffff00ff, fuchsia: 0xffff00ff,
    gray: 0xff808080, grey: 0xff808080, silver: 0xffc0c0c0,
    maroon: 0xff800000, olive: 0xff808000, teal: 0xff008080,
    navy: 0xff000080, purple: 0xff800080, orange: 0xffffa500,
    pink: 0xffffc0cb, brown: 0xffa52a2a, gold: 0xffffd700,
    violet: 0xffee82ee, indigo: 0xff4b0082, turquoise: 0xff40e0d0,
    tomato: 0xffff6347, coral: 0xffff7f50, salmon: 0xfffa8072,
    khaki: 0xfff0e68c, beige: 0xfff5f5dc, ivory: 0xfffffff0,
    chocolate: 0xffd2691e, crimson: 0xffdc143c, darkblue: 0xff00008b,
    darkgreen: 0xff006400, darkred: 0xff8b0000, lightblue: 0xffadd8e6,
    lightgreen: 0xff90ee90, lightgray: 0xffd3d3d3, lightgrey: 0xffd3d3d3,
    darkgray: 0xffa9a9a9, darkgrey: 0xffa9a9a9,
  };

  function clamp255(v) { return v < 0 ? 0 : (v > 255 ? 255 : (v | 0)); }
  function pack(r, g, b, a) {
    return ((clamp255(a) << 24) | (clamp255(r) << 16) |
      (clamp255(g) << 8) | clamp255(b)) >>> 0;
  }
  function hexColor(s, start) {
    var n = s.length - start, r, g, b, a = 255;
    function h(i) { return parseInt(s.substr(start + i, 1), 16); }
    function h2(i) { return parseInt(s.substr(start + i, 2), 16); }
    if (n === 3 || n === 4) {
      r = h(0); g = h(1); b = h(2);
      if (n === 4) a = h(3);
      r = r * 17; g = g * 17; b = b * 17;
      if (n === 4) a = a * 17;
    } else if (n === 6 || n === 8) {
      r = h2(0); g = h2(2); b = h2(4);
      if (n === 8) a = h2(6);
    } else return null;
    if (r !== r || g !== g || b !== b || a !== a) return null;
    return pack(r, g, b, a);
  }

  // split/parseFloat are fast on QuickJS and avoid a hand-written scanner.
  function alphaPart(p) {
    if (p.length < 4) return 255;
    var x = p[3], a = parseFloat(x);
    if (!isFinite(a)) return 255;
    if (x.indexOf("%") >= 0) a /= 100;
    return clamp255(Math.round(a * 255));
  }
  function channel(x, percent) {
    var v = parseFloat(x);
    if (!isFinite(v)) return 0;
    if (percent) v *= 2.55;
    return v;
  }
  function parseRgb(s, start, end) {
    var p = s.substring(start, end).split(",");
    if (p.length < 3) return null;
    var r = channel(p[0], p[0].indexOf("%") >= 0);
    var g = channel(p[1], p[1].indexOf("%") >= 0);
    var b = channel(p[2], p[2].indexOf("%") >= 0);
    return pack(Math.round(r), Math.round(g), Math.round(b), alphaPart(p));
  }
  function parseHsl(s, start, end) {
    var p = s.substring(start, end).split(",");
    if (p.length < 3) return null;
    var h = parseFloat(p[0]) % 360;
    if (h < 0) h += 360;
    h /= 360;
    var sat = parseFloat(p[1]) / 100;
    var l = parseFloat(p[2]) / 100;
    if (!isFinite(h)) h = 0;
    if (!isFinite(sat)) sat = 0;
    if (!isFinite(l)) l = 0;
    if (sat < 0) sat = 0; else if (sat > 1) sat = 1;
    if (l < 0) l = 0; else if (l > 1) l = 1;
    var r, g, b;
    if (sat === 0 || l === 0) {
      r = g = b = l;
    } else {
      var q = l < 0.5 ? l * (1 + sat) : l + sat - l * sat;
      var p2 = 2 * l - q;
      function hue(t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p2 + (q - p2) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p2 + (q - p2) * (2 / 3 - t) * 6;
        return p2;
      }
      r = hue(h + 1 / 3); g = hue(h); b = hue(h - 1 / 3);
    }
    return pack(Math.round(r * 255), Math.round(g * 255),
      Math.round(b * 255), alphaPart(p));
  }
  function parseColor(v) {
    if (typeof v !== "string") return null;
    var n = v.length;
    if (n < 4) {
      var namedSmall = NAMED[v];
      return namedSmall === undefined ? null : namedSmall;
    }
    var c0 = v.charCodeAt(0);
    if (c0 === 35) return hexColor(v, 1);
    var c1 = v.charCodeAt(1), c2 = v.charCodeAt(2), c3 = v.charCodeAt(3);
    // hsl( hsla( rgb( rgba( — no trim/toLowerCase/slice on the hot path.
    if (c0 === 104 && c1 === 115 && c2 === 108) { // hsl
      if (c3 === 97) { if (v.charCodeAt(4) !== 40) return null; return parseHsl(v, 5, n - 1); }
      if (c3 !== 40) return null;
      return parseHsl(v, 4, n - 1);
    }
    if (c0 === 114 && c1 === 103 && c2 === 98) { // rgb
      if (c3 === 97) { if (v.charCodeAt(4) !== 40) return null; return parseRgb(v, 5, n - 1); }
      if (c3 !== 40) return null;
      return parseRgb(v, 4, n - 1);
    }
    var named = NAMED[v];
    if (named !== undefined) return named;
    var lower = v.toLowerCase();
    named = NAMED[lower];
    return named === undefined ? null : named;
  }

  // ---- base64 output ----------------------------------------------------
  // Base64 writes 4 bytes for every 3 input bytes (hex writes 6) and Dart
  // decodes it natively. `String.fromCharCode.apply` avoids per-character
  // string concatenation in QuickJS.
  var B64C = new Uint8Array(64);
  var B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  for (var bi = 0; bi < 64; bi++) B64C[bi] = B64.charCodeAt(bi);
  function base64String(len) {
    if (len === 0) return "";
    var out = new Uint8Array(((len + 2) / 3 | 0) * 4);
    var i = 0, j = 0;
    for (; i + 2 < len; i += 3) {
      var a = bytes[i], b = bytes[i + 1], c = bytes[i + 2];
      out[j++] = B64C[a >> 2];
      out[j++] = B64C[((a & 3) << 4) | (b >> 4)];
      out[j++] = B64C[((b & 15) << 2) | (c >> 6)];
      out[j++] = B64C[c & 63];
    }
    if (i < len) {
      var a2 = bytes[i], b2 = i + 1 < len ? bytes[i + 1] : 0;
      out[j++] = B64C[a2 >> 2];
      out[j++] = B64C[((a2 & 3) << 4) | (b2 >> 4)];
      out[j++] = i + 1 < len ? B64C[(b2 & 15) << 2] : 61;
      out[j++] = 61;
    }
    var parts = [];
    for (var k = 0; k < out.length; k += 4096) {
      parts.push(String.fromCharCode.apply(
        null, out.subarray(k, Math.min(k + 4096, out.length))));
    }
    return parts.join("");
  }

  // ---- gradients --------------------------------------------------------
  var nextGradient = 1;
  function Gradient(op, args) {
    this.__id = nextGradient++;
    this.__op = op;
    this.__args = args;
    this.__stops = [];
    this.__emittedFrame = 0;
  }
  // Frame counter (starts at 1 on the first frame); a gradient is known to
  // the Dart replay only for the frame in which it was emitted.
  var frameNumber = 0;
  Gradient.prototype.emit = function () {
    this.__emittedFrame = frameNumber;
    emit(this.__op, [this.__id].concat(this.__args));
    for (var i = 0; i < this.__stops.length; i++) {
      emit(OP.cs, [this.__id, this.__stops[i][0], this.__stops[i][1]]);
    }
  };
  Gradient.prototype.addColorStop = function (offset, color) {
    var stop = [num(offset), String(color)];
    this.__stops.push(stop);
    if (this.__emittedFrame === frameNumber) {
      // Already sent this frame: the replay holds the gradient, so just add
      // the stop.
      emit(OP.cs, [this.__id, stop[0], stop[1]]);
    } else if (this.__emittedFrame !== 0) {
      // Sent in an earlier frame and possibly still the active style: send it
      // again with all stops and reapply it where it is in use.
      var isFill = st.fillStyle === this, isStroke = st.strokeStyle === this;
      if (isFill || isStroke) {
        this.emit();
        if (isFill) emit(OP.fs, [this]);
        if (isStroke) emit(OP.ss, [this]);
      }
    }
  };

  // ---- path: rectangles become fillRect ---------------------------------
  // pathRects != null: the current path only has rectangles not emitted yet.
  // pathCleared: an OP.bp was already sent for this path this frame.
  // pathGeometry: the replayed path already has segments.
  var pathRects = null;
  var pathCleared = true;
  var pathGeometry = false;

  function openPath() {
    if (!pathCleared) {
      emitNoArgs(OP.bp);
      pathCleared = true;
    }
  }
  function flushRects() {
    if (!pathRects) return;
    if (pathRects.length) {
      openPath();
      for (var i = 0; i < pathRects.length; i++) {
        emitRect(OP.re, pathRects[i][0], pathRects[i][1],
          pathRects[i][2], pathRects[i][3]);
      }
      pathGeometry = true;
    }
    pathRects = null;
  }
  function breakPath() { flushRects(); }
  function addPath(code, args) {
    flushRects();
    openPath();
    emit(code, args);
    pathGeometry = true;
  }

  // ---- 2D context -------------------------------------------------------
  var stack = [];
  // At the start of every frame the first style assignment is emitted even if
  // the value is unchanged: Dart may have discarded the state (the fast
  // rasterizer starts from the previous state, but the generic replay also
  // needs to receive the color).
  var styleDirty = true;
  var st = {
    fillStyle: "#000000", strokeStyle: "#000000", lineWidth: 1,
    globalAlpha: 1, globalCompositeOperation: "source-over",
    lineCap: "butt", lineJoin: "miter", font: "10px sans-serif",
    textAlign: "start", textBaseline: "alphabetic",
    shadowBlur: 0, shadowColor: "rgba(0, 0, 0, 0)", filter: "none",
    imageSmoothingEnabled: true,
  };
  var stateOps = {
    fillStyle: "fs", strokeStyle: "ss", lineWidth: "lw", globalAlpha: "ga",
    globalCompositeOperation: "gco", lineCap: "lc", lineJoin: "lj",
  };

  // fillStyle is deferred: if the next draw is an integer fillRect, the color
  // travels inside OP.f16/OP.f16h and no OP.fs is emitted.
  var pendingFill = null;
  var hasPendingHsl = false;

  function flushFill() {
    if (hasPendingHsl) {
      emit(OP.fsh, [hslH, hslS, hslL]);
      hasPendingHsl = false;
    }
    if (pendingFill !== null) {
      emitColorArg(OP.fs, pendingFill);
      pendingFill = null;
    }
  }

  // HSL components stay as numbers until the Dart side converts them to RGB.
  // QuickJS's split/parseFloat is faster than a hand-written JS scanner.
  var hslH = 0, hslS = 0, hslL = 0, hslA = 1;
  var hslCache = Object.create(null);
  var hslCacheSize = 0;
  // Effects that use a different color for every cell (Gradient Mesh) would
  // only pay for the hash lookups; back off after the cache overflows.
  var hslCacheCooldown = 0;

  function readHsl(v) {
    if (typeof v !== "string") return false;
    var n = v.length;
    if (n < 7) return false;
    var c0 = v.charCodeAt(0), c1 = v.charCodeAt(1);
    var c2 = v.charCodeAt(2), c3 = v.charCodeAt(3);
    if (c0 !== 104 || c1 !== 115 || c2 !== 108) return false;
    var start;
    if (c3 === 97) {
      if (v.charCodeAt(4) !== 40) return false;
      start = 5;
    } else if (c3 === 40) {
      start = 4;
    } else return false;
    if (hslCacheCooldown <= 0) {
      var hit = hslCache[v];
      if (hit !== undefined) {
        hslH = hit[0]; hslS = hit[1]; hslL = hit[2]; hslA = hit[3];
        return true;
      }
    }
    var p = v.substring(start, n - 1).split(",");
    if (p.length < 3) return false;
    var h = parseFloat(p[0]), sat = parseFloat(p[1]), lit = parseFloat(p[2]);
    if (!isFinite(h) || !isFinite(sat) || !isFinite(lit)) return false;
    var a = 1;
    if (p.length > 3) {
      a = parseFloat(p[3]);
      if (p[3].indexOf("%") >= 0) a /= 100;
      if (!isFinite(a)) a = 1;
    }
    hslH = h; hslS = sat; hslL = lit; hslA = a;
    if (hslCacheCooldown <= 0) {
      if (hslCacheSize >= 512) {
        hslCache = Object.create(null);
        hslCacheSize = 0;
        hslCacheCooldown = 120;
      } else {
        hslCache[v] = [h, sat, lit, a];
        hslCacheSize++;
      }
    }
    return true;
  }

  function setStyle(op, v) {
    if (op === "fs") {
      if (v instanceof Gradient) {
        pendingFill = null;
        hasPendingHsl = false;
        v.emit();
        emit(OP.fs, [v]);
        return;
      }
      if (readHsl(v) && hslA >= 1) {
        hasPendingHsl = true;
        pendingFill = null;
        return;
      }
      hasPendingHsl = false;
      var c = parseColor(v);
      if (c !== null) { pendingFill = c; return; }
      pendingFill = null;
      emitString(OP.fs, String(v));
      return;
    }
    if (v instanceof Gradient) { v.emit(); emit(OP[op], [v]); return; }
    var c2 = parseColor(v);
    if (c2 !== null) emitColorArg(OP[op], c2);
    else emitString(OP[op], String(v));
  }

  var ctx = {
    canvas: null,
    save: function () {
      flushFill();
      stack.push(Object.assign({}, st));
      emitNoArgs(OP.sv);
    },
    restore: function () {
      breakPath();
      flushFill();
      if (stack.length) st = stack.pop();
      pendingFill = null;
      hasPendingHsl = false;
      emitNoArgs(OP.rs);
    },

    translate: function (x, y) { breakPath(); emit(OP.tr, [x, y]); },
    rotate: function (a) { breakPath(); emitNumber(OP.ro, a); },
    scale: function (x, y) { breakPath(); emit(OP.sc, [x, y]); },
    transform: function (a, b, c, d, e, f) {
      breakPath(); emit(OP.tf, [a, b, c, d, e, f]);
    },
    setTransform: function (a, b, c, d, e, f) {
      if (typeof a === "object" && a) { b = a.b; c = a.c; d = a.d; e = a.e; f = a.f; a = a.a; }
      breakPath(); emit(OP.st, [a, b, c, d, e, f]);
    },
    resetTransform: function () { breakPath(); emit(OP.st, [1, 0, 0, 1, 0, 0]); },

    clearRect: function (x, y, w, h) { emitRect(OP.cr, x, y, w, h); },
    fillRect: function (x, y, w, h) { emitFillRect(x, y, w, h); },
    strokeRect: function (x, y, w, h) { emitRect(OP.sr, x, y, w, h); },

    beginPath: function () { pathRects = []; pathCleared = false; pathGeometry = false; },
    closePath: function () {
      if (!pathGeometry) return; // rectangles are already closed
      flushRects();
      emitNoArgs(OP.cp);
    },
    moveTo: function (x, y) { addPath(OP.mt, [x, y]); },
    lineTo: function (x, y) { addPath(OP.lt, [x, y]); },
    rect: function (x, y, w, h) {
      if (pathRects !== null && !pathGeometry) pathRects.push([x, y, w, h]);
      else {
        flushRects();
        openPath();
        emitRect(OP.re, x, y, w, h);
        pathGeometry = true;
      }
    },
    arc: function (x, y, r, a0, a1, ccw) {
      addPath(OP.ar, [x, y, r, a0, a1, ccw ? 1 : 0]);
    },
    ellipse: function (x, y, rx, ry, rot, a0, a1, ccw) {
      addPath(OP.el, [x, y, rx, ry, rot, a0, a1, ccw ? 1 : 0]);
    },
    quadraticCurveTo: function (cx, cy, x, y) { addPath(OP.qc, [cx, cy, x, y]); },
    bezierCurveTo: function (a, b, c, d, e, f) {
      addPath(OP.bc, [a, b, c, d, e, f]);
    },
    fill: function () {
      if (pathRects !== null && !pathGeometry) {
        // The path only has rectangles: direct fillRect, no OP.bp.
        for (var i = 0; i < pathRects.length; i++) {
          emitFillRect(pathRects[i][0], pathRects[i][1],
            pathRects[i][2], pathRects[i][3]);
        }
      } else {
        flushRects();
        openPath();
        flushFill();
        emitNoArgs(OP.f);
      }
    },
    stroke: function () {
      if (pathRects !== null && !pathGeometry) {
        for (var i = 0; i < pathRects.length; i++) {
          emitRect(OP.sr, pathRects[i][0], pathRects[i][1],
            pathRects[i][2], pathRects[i][3]);
        }
      } else {
        flushRects();
        openPath();
        emitNoArgs(OP.s);
      }
    },
    clip: function () {
      flushRects();
      openPath();
      emitNoArgs(OP.cl);
      pathGeometry = true;
    },

    createLinearGradient: function (x0, y0, x1, y1) {
      return new Gradient(OP.lg, [x0, y0, x1, y1]);
    },
    createRadialGradient: function (x0, y0, r0, x1, y1, r1) {
      return new Gradient(OP.rg, [x0, y0, r0, x1, y1, r1]);
    },

    // No text, images or pixel reads in the shim: accepted and ignored.
    fillText: function () {}, strokeText: function () {},
    measureText: function (t) { return { width: String(t).length * 6 }; },
    drawImage: function () {},
    setLineDash: function () {}, getLineDash: function () { return []; },
    createImageData: function (w, h) { return { width: w, height: h, data: new Uint8ClampedArray(w * h * 4) }; },
    getImageData: function (x, y, w, h) { return { width: w, height: h, data: new Uint8ClampedArray(w * h * 4) }; },
    putImageData: function () {},
  };

  Object.keys(st).forEach(function (k) {
    Object.defineProperty(ctx, k, {
      get: function () { return st[k]; },
      set: function (v) {
        if (st[k] === v && !styleDirty) return;
        st[k] = v;
        var op = stateOps[k];
        if (!op) return;
        if (op === "fs" || op === "ss") setStyle(op, v);
        else if (typeof v === "number") emitNumber(OP[op], v);
        else emitString(OP[op], String(v));
        styleDirty = false;
      },
    });
  });

  var canvas = {
    id: "exCanvas", width: W, height: H,
    style: {},
    getContext: function (kind) { return kind === "2d" ? ctx : null; },
    addEventListener: function () {},
  };
  ctx.canvas = canvas;

  // ---- minimal DOM ------------------------------------------------------
  g.window = g;
  g.self = g;
  g.document = {
    getElementById: function () { return canvas; },
    querySelector: function () { return canvas; },
    createElement: function (t) {
      return t === "canvas" ? canvas : { style: {}, appendChild: function () {} };
    },
    addEventListener: function () {},
    body: { style: {}, appendChild: function () {} },
  };
  g.addEventListener = function () {};
  g.console = {
    log: function () {
      var message = Array.prototype.join.call(arguments, " ").slice(0, 2048);
      if (g.__we_log.length === 200) g.__we_log.shift();
      g.__we_log.push(message);
    },
    clear: function () {},
  };
  g.console.warn = g.console.error = g.console.info = g.console.debug = g.console.log;
  g.__we_log = [];

  // ---- time: rAF and timers driven by the host --------------------------
  var raf = [], nextRaf = 1;
  g.requestAnimationFrame = function (cb) { raf.push([nextRaf, cb]); return nextRaf++; };
  g.cancelAnimationFrame = function (id) { raf = raf.filter(function (e) { return e[0] !== id; }); };

  var timers = [], nextTimer = 1;
  function addTimer(cb, ms, repeat) {
    timers.push({ id: nextTimer, cb: cb, at: now + Math.max(0, num(ms)), ms: num(ms), repeat: repeat });
    return nextTimer++;
  }
  g.setTimeout = function (cb, ms) { return addTimer(cb, ms, false); };
  g.setInterval = function (cb, ms) { return addTimer(cb, ms, true); };
  g.clearTimeout = g.clearInterval = function (id) {
    timers = timers.filter(function (t) { return t.id !== id; });
  };
  g.performance = { now: function () { return now; } };

  // ---- effect host API ---------------------------------------------------
  g.__we_sensors = {};
  g.engine = {
    // Audio unavailable: silence (plan §5.1). Audio effects become
    // "Partial" in the compatibility badge.
    audio: { level: -100, density: 0, freq: new Int8Array(200) },
    // Screen capture is out of scope: the effect becomes "Unsupported".
    zone: { hue: [], saturation: [], lightness: [], imagedata: [] },
    getSensorValue: function (id) {
      var v = g.__we_sensors[String(id)];
      if (typeof v !== "number" || !isFinite(v)) return { value: 0, min: 0, max: 100 };
      return { value: v, min: 0, max: 100 };
    },
    vid: 0, pid: 0,
  };

  // Keyboard key: the host has no per-LED keyboard, so it does nothing.
  g.onCanvasTapped = g.onCanvasTapped || function () {};

  g.__we_frame = function (t) {
    now = t;
    frameNumber++;
    styleDirty = true;
    // The replay drops its gradients every frame: resend the ones still in
    // use as the active fill or stroke style.
    if (st.fillStyle instanceof Gradient) {
      st.fillStyle.emit();
      emit(OP.fs, [st.fillStyle]);
    }
    if (st.strokeStyle instanceof Gradient) {
      if (st.strokeStyle !== st.fillStyle) st.strokeStyle.emit();
      emit(OP.ss, [st.strokeStyle]);
    }
    if (hslCacheCooldown > 0) hslCacheCooldown--;
    // The Dart replay starts every frame with a new Path.
    pathCleared = true;
    pathGeometry = false;
    var due = timers.filter(function (x) { return x.at <= now; });
    due.forEach(function (x) {
      if (x.repeat) x.at = now + Math.max(1, x.ms);
      else timers = timers.filter(function (y) { return y !== x; });
      x.cb();
    });
    var cbs = raf;
    raf = [];
    cbs.forEach(function (e) { e[1](t); });
    var out = base64String(pos);
    pos = 0;
    return out;
  };

  g.__we_setProperty = function (name, value) {
    g[name] = value;
    var fn = g["on" + name + "Changed"];
    if (typeof fn === "function") fn();
  };

  g.__we_setSensors = function (map) { g.__we_sensors = map || {}; };
})(globalThis);
