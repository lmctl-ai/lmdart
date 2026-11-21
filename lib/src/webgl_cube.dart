import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'json.dart';
import 'matrix4.dart';

final class WebglCube {
  late final web.WebGLRenderingContext gl;
  late final web.WebGLProgram program;
  late final web.WebGLUniformLocation matrixLocation;
  final double speed;
  double elapsed = 0;
  double? previous;
  bool paused = false;

  WebglCube(web.HTMLCanvasElement canvas, Object? data)
      : speed = jsonNumber(jsonMap(data, 'WebGL scene')['speed'], 'WebGL speed') {
    gl = _context(canvas);
    program = _program(gl);
    matrixLocation = gl.getUniformLocation(program, 'matrix')!;
    _initialize(canvas, jsonMap(data, 'WebGL scene'));
  }

  static web.WebGLRenderingContext _context(web.HTMLCanvasElement canvas) {
    final options = web.WebGLContextAttributes(preserveDrawingBuffer: true);
    final context = canvas.getContext('webgl', options) as web.WebGLRenderingContext?;
    if (context == null) throw StateError('WebGL is unavailable');
    return context;
  }

  static web.WebGLProgram _program(web.WebGLRenderingContext gl) {
    final vertex = _shader(gl, web.WebGLRenderingContext.VERTEX_SHADER, '''
attribute vec3 position;
attribute vec3 color;
uniform mat4 matrix;
varying vec3 vColor;
void main() {
  gl_Position = matrix * vec4(position, 1.0);
  vColor = color * (0.82 + 0.18 * abs(normalize(position).z));
}
''');
    final fragment = _shader(gl, web.WebGLRenderingContext.FRAGMENT_SHADER, '''
precision mediump float;
varying vec3 vColor;
void main() { gl_FragColor = vec4(vColor, 1.0); }
''');
    final program = gl.createProgram()!;
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    if (!(gl.getProgramParameter(program, web.WebGLRenderingContext.LINK_STATUS) as bool)) {
      throw StateError('WebGL link failed: ${gl.getProgramInfoLog(program)}');
    }
    return program;
  }

  static web.WebGLShader _shader(web.WebGLRenderingContext gl, int type, String source) {
    final shader = gl.createShader(type)!;
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!(gl.getShaderParameter(shader, web.WebGLRenderingContext.COMPILE_STATUS) as bool)) {
      throw StateError('WebGL shader failed: ${gl.getShaderInfoLog(shader)}');
    }
    return shader;
  }

  void _initialize(web.HTMLCanvasElement canvas, Map<String, Object?> data) {
    canvas.width = 960;
    canvas.height = 540;
    final colors = jsonList(data['colors'], 'WebGL colors').map((value) {
      return jsonString(value, 'WebGL color');
    }).toList();
    if (colors.length != 6) throw FormatException('WebGL cube needs six colors');
    final buffer = gl.createBuffer()!;
    gl.bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, buffer);
    gl.bufferData(web.WebGLRenderingContext.ARRAY_BUFFER, _vertices(colors).toJS, web.WebGLRenderingContext.STATIC_DRAW);
    gl.useProgram(program);
    final position = gl.getAttribLocation(program, 'position');
    final color = gl.getAttribLocation(program, 'color');
    gl.enableVertexAttribArray(position);
    gl.enableVertexAttribArray(color);
    gl.vertexAttribPointer(position, 3, web.WebGLRenderingContext.FLOAT, false, 24, 0);
    gl.vertexAttribPointer(color, 3, web.WebGLRenderingContext.FLOAT, false, 24, 12);
    gl.enable(web.WebGLRenderingContext.DEPTH_TEST);
    gl.clearColor(.027, .063, .11, 1);
    render();
  }

  void start() => web.window.requestAnimationFrame(_frame.toJS);

  void toggle() {
    paused = !paused;
    previous = null;
  }

  void reset() {
    elapsed = 0;
    previous = null;
    render();
  }

  void _frame(double timestamp) {
    if (!paused) {
      if (previous != null) elapsed += (timestamp - previous!).clamp(0, 50) / 1000;
      previous = timestamp;
      render();
    }
    web.window.requestAnimationFrame(_frame.toJS);
  }

  void render() {
    final matrix = Matrix4.perspective(math.pi / 3, 960 / 540, .1, 100) *
        Matrix4.translation(0, 0, -4.2) * Matrix4.rotation(elapsed * speed * .7, elapsed * speed);
    gl.viewport(0, 0, 960, 540);
    gl.clear(web.WebGLRenderingContext.COLOR_BUFFER_BIT | web.WebGLRenderingContext.DEPTH_BUFFER_BIT);
    gl.uniformMatrix4fv(matrixLocation, false, matrix.values.toJS);
    gl.drawArrays(web.WebGLRenderingContext.TRIANGLES, 0, 36);
  }

  static Float32List _vertices(List<String> colors) {
    final faces = <List<List<double>>>[
      [[-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]],
      [[1, -1, -1], [-1, -1, -1], [-1, 1, -1], [1, 1, -1]],
      [[-1, -1, -1], [-1, -1, 1], [-1, 1, 1], [-1, 1, -1]],
      [[1, -1, 1], [1, -1, -1], [1, 1, -1], [1, 1, 1]],
      [[-1, 1, 1], [1, 1, 1], [1, 1, -1], [-1, 1, -1]],
      [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1]],
    ];
    final values = <double>[];
    for (var face = 0; face < 6; face++) {
      final rgb = _color(colors[face]);
      for (final index in [0, 1, 2, 0, 2, 3]) {
        values.addAll(faces[face][index]);
        values.addAll(rgb);
      }
    }
    return Float32List.fromList(values);
  }

  static List<double> _color(String value) {
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) throw FormatException('Color must be #rrggbb');
    return [1, 3, 5].map((index) => int.parse(value.substring(index, index + 2), radix: 16) / 255).toList();
  }
}
