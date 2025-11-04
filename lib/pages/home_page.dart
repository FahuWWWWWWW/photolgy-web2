import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  // Simulation parameters
  double _zDistance = 300.0; // distance from sources to screen (pixels)
  double _sourceSeparation = 80.0; // pixels between two point sources
  double _verticalOffset =
      0.0; // vertical offset of sources relative to center (pixels)
  double _wavelength = 550.0; // wavelength in nm (visual mapping)
  double _sampleStep = 3.0; // painter sampling step (px)

  // interactive model drag
  Offset _modelPos = const Offset(0, 0);
  // measurement & interaction
  bool _measureMode = false;
  List<Offset> _measuredPoints = [];
  Offset? _lastTapPos;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('物理光学 — 双点源干涉 (交互式)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left: interactive 3D-like model + draggable controls
              Flexible(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        // use constraints if needed later; currently layout handled by Stack
                        return Stack(
                          children: [
                            // Screen with interference pattern (interactive)
                            Positioned.fill(
                              child: Container(
                                margin: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black87),
                                    color: Colors.black),
                                child: GestureDetector(
                                  onTapUp: (details) {
                                    final local = details.localPosition;
                                    setState(() {
                                      _lastTapPos = local;
                                      if (_measureMode) {
                                        _measuredPoints.add(local);
                                        if (_measuredPoints.length > 2)
                                          _measuredPoints.removeAt(0);
                                      }
                                    });
                                  },
                                  child: RepaintBoundary(
                                    key: _repaintKey,
                                    child: CustomPaint(
                                      painter: InterferencePainter(
                                        z: _zDistance,
                                        separation: _sourceSeparation,
                                        verticalOffset: _verticalOffset,
                                        wavelengthNm: _wavelength,
                                        sampleStep: _sampleStep,
                                        measuredPoints: _measuredPoints,
                                        lastTap: _lastTapPos,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 3D-like model overlay (front/back plates shown as rectangles)
                            Positioned(
                              right: 24,
                              top: 24 + _modelPos.dy,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _modelPos += details.delta;
                                    // vertical drag of model -> change vertical offset (映射)
                                    _verticalOffset =
                                        (_modelPos.dy).clamp(-200.0, 200.0);
                                  });
                                },
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateX(0.15)
                                    ..rotateY(-0.25),
                                  alignment: Alignment.center,
                                  child: _ModelWidget(z: _zDistance),
                                ),
                              ),
                            ),

                            // Z control draggable knob (maps to front/back movement)
                            Positioned(
                              left: 20,
                              bottom: 20,
                              child: Row(
                                children: [
                                  const Text('深度 Z:'),
                                  Slider(
                                    value: _zDistance,
                                    min: 50,
                                    max: 1200,
                                    onChanged: (v) =>
                                        setState(() => _zDistance = v),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(_zDistance.toStringAsFixed(0)),
                                  )
                                ],
                              ),
                            )
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // quick hints
                    Row(
                      children: const [
                        Icon(Icons.drag_indicator, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                            child:
                                Text('拖拽右上角模型可上下移动（控制干涉板上下位置），拖动 Z 滑块控制前后距离'))
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                            value: _measureMode,
                            onChanged: (v) =>
                                setState(() => _measureMode = v ?? false)),
                        const SizedBox(width: 6),
                        const Text('测量模式（点选两点显示距离）'),
                        const Spacer(),
                        ElevatedButton.icon(
                            onPressed: _saveImage,
                            icon: const Icon(Icons.download),
                            label: const Text('保存图片'))
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right: controls
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('参数控制',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildNumberControl('光源间距 (px)', _sourceSeparation, 0,
                          300, (v) => setState(() => _sourceSeparation = v)),
                      _buildNumberControl('干涉板垂直偏移 (px)', _verticalOffset, -200,
                          200, (v) => setState(() => _verticalOffset = v)),
                      _buildNumberControl('波长 (nm)', _wavelength, 380, 780,
                          (v) => setState(() => _wavelength = v)),
                      _buildNumberControl('渲染采样步长 (px)', _sampleStep, 1, 8,
                          (v) => setState(() => _sampleStep = v)),
                      const SizedBox(height: 12),
                      const Text('演示说明：'),
                      const Text('- 拖动右上角模型上下移动以改变干涉板的高度。'),
                      const Text('- 使用 Z 滑块控制后板到屏幕的距离，距离越大条纹更密集。'),
                      const Text('- 调整波长以观察色散效果（单色近似，颜色映射用于可视化）。'),
                      const SizedBox(height: 20),
                      const Text('学校信息',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('深圳技术大学'),
                      const Text('中德智能制造学院'),
                      const Text('电子科学与技术'),
                      const Text('物理光学 - 杨氏干涉仿真'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberControl(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              SizedBox(
                  width: 72,
                  child: Text(value.toStringAsFixed(1),
                      textAlign: TextAlign.right)),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _saveImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image =
          await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = 'interference.png'
          ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // non-web: skipping detailed file save; could implement using path_provider + file IO
      }
    } catch (e) {
      // ignore for now
    }
  }
}

class _ModelWidget extends StatelessWidget {
  final double z;
  const _ModelWidget({required this.z, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white70, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('干涉装置', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // rear plate
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 18,
                      bottom: 18,
                      child: Container(
                        decoration: BoxDecoration(
                            border:
                                Border.all(width: 1.5, color: Colors.blueGrey),
                            color: Colors.blue.shade50),
                      ),
                    ),
                    // label z
                    Positioned(
                        bottom: 4,
                        right: 6,
                        child: Text('Z=${z.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InterferencePainter extends CustomPainter {
  final double z; // pixels
  final double separation; // px
  final double verticalOffset; // px
  final double wavelengthNm; // nm
  final double sampleStep; // px
  final List<Offset>? measuredPoints;
  final Offset? lastTap;

  InterferencePainter(
      {required this.z,
      required this.separation,
      required this.verticalOffset,
      required this.wavelengthNm,
      required this.sampleStep,
      this.measuredPoints,
      this.lastTap});

  @override
  void paint(Canvas canvas, Size size) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);

    // center of screen
    final cx = size.width / 2;
    final cy = size.height / 2;

    // sources positions (on plane z=0 behind screen center)
    final x1 = cx - separation / 2;
    final x2 = cx + separation / 2;
    final y1 = cy + verticalOffset;
    final y2 = cy + verticalOffset;

    // map wavelength (nm) to pixel-based k. We choose an empirical scale so visible fringes appear.
    final double lambdaPx =
        (wavelengthNm / 1000.0) * 30.0; // ~ scale: 500nm -> 15px
    final double k = 2 * math.pi / math.max(1e-6, lambdaPx);

    final paint = Paint()..style = PaintingStyle.fill;

    // draw background
    c.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // iterate with step to improve performance
    final step = sampleStep.clamp(1.0, 8.0).toInt();
    for (int yy = 0; yy < size.height; yy += step) {
      for (int xx = 0; xx < size.width; xx += step) {
        final dx1 = xx - x1;
        final dy1 = yy - y1;
        final r1 = math.sqrt(dx1 * dx1 + dy1 * dy1 + z * z);

        final dx2 = xx - x2;
        final dy2 = yy - y2;
        final r2 = math.sqrt(dx2 * dx2 + dy2 * dy2 + z * z);

        final phase = k * (r1 - r2);
        final intensity = 0.5 * (1 + math.cos(phase)); // 0..1

        // color mapping: use cool-to-warm mapping based on wavelength for tinted look
        final hue =
            ((wavelengthNm - 380) / (780 - 380) * 360).clamp(0.0, 360.0);
        final base = HSVColor.fromAHSV(1.0, hue, 0.6, intensity.clamp(0.0, 1.0))
            .toColor();

        paint.color = base;
        c.drawRect(
            Rect.fromLTWH(
                xx.toDouble(), yy.toDouble(), step.toDouble(), step.toDouble()),
            paint);
      }
    }

    final picture = recorder.endRecording();
    canvas.drawPicture(picture);

    // draw measurement overlays on top
    final overlayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    if (measuredPoints != null && measuredPoints!.isNotEmpty) {
      for (final p in measuredPoints!) {
        canvas.drawCircle(p, 6, Paint()..color = Colors.yellow);
        canvas.drawCircle(p, 6, overlayPaint);
      }
      if (measuredPoints!.length == 2) {
        final a = measuredPoints![0];
        final b = measuredPoints![1];
        canvas.drawLine(a, b, overlayPaint);
        final dist = (a - b).distance;
        final txt = 'd=${dist.toStringAsFixed(1)} px';
        final tp = TextPainter(
            text: TextSpan(
                text: txt,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            textDirection: TextDirection.ltr);
        tp.layout();
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        tp.paint(canvas, mid + const Offset(6, -12));
      }
    }

    if (lastTap != null) {
      canvas.drawCircle(lastTap!, 4, Paint()..color = Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(covariant InterferencePainter oldDelegate) {
    return oldDelegate.z != z ||
        oldDelegate.separation != separation ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.wavelengthNm != wavelengthNm ||
        oldDelegate.sampleStep != sampleStep ||
        oldDelegate.measuredPoints != measuredPoints ||
        oldDelegate.lastTap != lastTap;
  }
}

// save image implementation in State class
