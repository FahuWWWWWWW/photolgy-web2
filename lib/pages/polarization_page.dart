import 'dart:math' as math;
import 'package:flutter/material.dart';

class PolarizationPage extends StatefulWidget {
  const PolarizationPage({super.key});

  @override
  State<PolarizationPage> createState() => _PolarizationPageState();
}

class _PolarizationPageState extends State<PolarizationPage> {
  // 控制参数
  double _amplitude1 = 100.0;
  double _amplitude2 = 100.0;
  double _phaseDifference = 0.0; // 相位差（弧度）
  double _frequency1 = 1.0;
  double _frequency2 = 1.0;
  double _coherenceTime = 1.0; // 相干时间
  bool _sameFrequencyMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('光的偏振与干涉'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 控制面板
              _buildControlPanel(),
              const SizedBox(height: 16),
              // 图形展示区域
              Expanded(
                child: _buildVisualizationArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '控制面板',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 修复SwitchListTile布局问题
                SizedBox(
                  width: 120,
                  child: SwitchListTile(
                    title: const Text('同频模式'),
                    value: _sameFrequencyMode,
                    onChanged: (value) {
                      setState(() {
                        _sameFrequencyMode = value;
                        if (value) {
                          _frequency2 = _frequency1;
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildSlider('光束1振幅', _amplitude1, 10, 200, (value) {
              setState(() {
                _amplitude1 = value;
              });
            }),
            _buildSlider('光束2振幅', _amplitude2, 10, 200, (value) {
              setState(() {
                _amplitude2 = value;
              });
            }),
            _buildSlider('相位差 (弧度)', _phaseDifference, 0, 2 * math.pi,
                (value) {
              setState(() {
                _phaseDifference = value;
              });
            }),
            if (!_sameFrequencyMode)
              _buildSlider('光束1频率', _frequency1, 0.1, 3.0, (value) {
                setState(() {
                  _frequency1 = value;
                });
              }),
            if (!_sameFrequencyMode)
              _buildSlider('光束2频率', _frequency2, 0.1, 3.0, (value) {
                setState(() {
                  _frequency2 = value;
                });
              }),
            _buildSlider('相干时间', _coherenceTime, 0.01, 2.0, (value) {
              setState(() {
                _coherenceTime = value;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationArea() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '可视化展示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CustomPaint(
                painter: PolarizationPainter(
                  amplitude1: _amplitude1,
                  amplitude2: _amplitude2,
                  phaseDifference: _phaseDifference,
                  frequency1: _frequency1,
                  frequency2: _frequency2,
                  coherenceTime: _coherenceTime,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 16),
            _buildPolarizationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPolarizationInfo() {
    // 计算偏振参数
    final ellipicity = (_amplitude1 - _amplitude2).abs() / (_amplitude1 + _amplitude2);
    final stokesQ = math.pow(_amplitude1, 2) - math.pow(_amplitude2, 2);
    final stokesU = 2 * _amplitude1 * _amplitude2 * math.cos(_phaseDifference);
    final stokesV = 2 * _amplitude1 * _amplitude2 * math.sin(_phaseDifference);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '偏振参数',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('椭圆率: ${ellipicity.toStringAsFixed(3)}'),
        Text('Stokes参数: Q=${stokesQ.toStringAsFixed(2)}, U=${stokesU.toStringAsFixed(2)}, V=${stokesV.toStringAsFixed(2)}'),
        if (_sameFrequencyMode) 
          Text('偏振方向角: ${(_phaseDifference / 2).toStringAsFixed(3)} 弧度'),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('说明'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 可以调节两个光束的振幅、频率和相位差'),
                Text('2. 同频模式下只能调节振幅比和相位差'),
                Text('3. 可以观察线性、圆形和椭圆偏振状态'),
                Text('4. 调节相干时间可观察干涉条纹清晰度变化'),
                Text('5. 频率不同时可观察拍频现象'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}

class PolarizationPainter extends CustomPainter {
  final double amplitude1;
  final double amplitude2;
  final double phaseDifference;
  final double frequency1;
  final double frequency2;
  final double coherenceTime;

  PolarizationPainter({
    required this.amplitude1,
    required this.amplitude2,
    required this.phaseDifference,
    required this.frequency1,
    required this.frequency2,
    required this.coherenceTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制坐标轴
    paint.color = Colors.grey;
    canvas.drawLine(
        Offset(0, centerY), Offset(size.width, centerY), paint);
    canvas.drawLine(
        Offset(centerX, 0), Offset(centerX, size.height), paint);

    // 绘制合成轨迹
    final path = Path();
    paint.color = Colors.blue;
    
    const steps = 100;
    double? firstX, firstY;
    
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * 4 * math.pi; // 两个周期
      final ex = amplitude1 * math.cos(frequency1 * t);
      final ey = amplitude2 * math.cos(frequency2 * t + phaseDifference);
      
      final x = centerX + ex;
      final y = centerY - ey; // Y轴向上为正
      
      if (i == 0) {
        path.moveTo(x, y);
        firstX = x;
        firstY = y;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // 绘制起始点
    if (firstX != null && firstY != null) {
      paint.style = PaintingStyle.fill;
      paint.color = Colors.red;
      canvas.drawCircle(Offset(firstX, firstY), 5, paint);
    }

    // 绘制光强分布（考虑相干时间的影响）
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.green;
    final intensityPath = Path();
    
    for (int i = 0; i <= steps; i++) {
      final z = i / steps * size.width;
      final t = z / size.width * 4 * math.pi; // 空间位置对应的时间相位
      
      // 计算两个光束的瞬时电场
      final ex1 = amplitude1 * math.cos(frequency1 * t);
      final ex2 = amplitude2 * math.cos(frequency2 * t + phaseDifference);
      
      // 计算合成光强，考虑相干时间的影响
      // 相干时间越短，干涉条纹越模糊
      final coherenceFactor = math.exp(-t / (coherenceTime * 10)); // 归一化相干因子
      final intensity = math.pow(ex1 + ex2, 2) * coherenceFactor + 
          (math.pow(amplitude1, 2) + math.pow(amplitude2, 2)) * (1 - coherenceFactor);
      
      final y = centerY - (intensity / (2 * (math.pow(amplitude1, 2) + math.pow(amplitude2, 2))) * 50);
      
      if (i == 0) {
        intensityPath.moveTo(z, y);
      } else {
        intensityPath.lineTo(z, y);
      }
    }
    
    canvas.drawPath(intensityPath, paint);
    
    // 绘制包络线，更清楚地显示相干时间的影响
    paint.color = Colors.orange;
    final envelopePath1 = Path();
    final envelopePath2 = Path();
    
    for (int i = 0; i <= steps; i++) {
      final z = i / steps * size.width;
      final t = z / size.width * 4 * math.pi;
      
      final envelope = math.exp(-t / (coherenceTime * 10)) * 50;
      
      if (i == 0) {
        envelopePath1.moveTo(z, centerY - envelope);
        envelopePath2.moveTo(z, centerY + envelope);
      } else {
        envelopePath1.lineTo(z, centerY - envelope);
        envelopePath2.lineTo(z, centerY + envelope);
      }
    }
    
    canvas.drawPath(envelopePath1, paint);
    canvas.drawPath(envelopePath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 优化重绘条件
    if (oldDelegate is PolarizationPainter) {
      return oldDelegate.amplitude1 != amplitude1 ||
          oldDelegate.amplitude2 != amplitude2 ||
          oldDelegate.phaseDifference != phaseDifference ||
          oldDelegate.frequency1 != frequency1 ||
          oldDelegate.frequency2 != frequency2 ||
          oldDelegate.coherenceTime != coherenceTime;
    }
    return true;
  }
}