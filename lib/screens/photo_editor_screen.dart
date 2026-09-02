import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Стандартен, професионален редактор за профилни снимки.
class PhotoEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const PhotoEditorScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  static const double _cropSize = 280.0;

  final GlobalKey _cropAreaKey = GlobalKey();
  ui.Image? _decodedImage;
  bool _loadingImage = true;
  bool _saving = false;

  // Трансформации
  double _scale = 1.0;
  double _minScale = 1.0;
  static const double _maxScale = 4.0;
  Offset _offset = Offset.zero;

  // Проследяване при влачене (Drag)
  Offset _startFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frameInfo = await codec.getNextFrame();
    final img = frameInfo.image;

    // Пресмятаме минималния мащаб, така че снимката винаги да покрива изцяло кръга
    final scaleX = _cropSize / img.width;
    final scaleY = _cropSize / img.height;
    final initialScale = math.max(scaleX, scaleY);

    if (!mounted) return;

    setState(() {
      _decodedImage = img;
      _minScale = initialScale;
      _scale = initialScale;
      _offset = Offset.zero;
      _loadingImage = false;
    });
  }

  Offset _clampOffset(Offset offset, double scale) {
    if (_decodedImage == null) return offset;

    final imgWidth = _decodedImage!.width * scale;
    final imgHeight = _decodedImage!.height * scale;

    // Ограничаваме преместването, за да няма празни пространства в рамката
    final maxOffsetX = (imgWidth - _cropSize) / 2;
    final maxOffsetY = (imgHeight - _cropSize) / 2;

    final clampedX = offset.dx.clamp(-maxOffsetX, maxOffsetX);
    final clampedY = offset.dy.clamp(-maxOffsetY, maxOffsetY);

    return Offset(clampedX, clampedY);
  }

  void _reset() {
    setState(() {
      _scale = _minScale;
      _offset = Offset.zero;
    });
  }

  Future<void> _save() async {
    if (_saving || _cropAreaKey.currentContext == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final boundary = _cropAreaKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (!mounted) return;

      if (byteData != null) {
        final resultBytes = byteData.buffer.asUint8List();
        Navigator.pop(context, resultBytes);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Възникна грешка при запазване на снимката.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Редактирай снимка',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Нулирай',
            onPressed: _loadingImage ? null : _reset,
          ),
        ],
      ),
      body: _loadingImage
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Column(
              children: [
                const Spacer(),

                // Рамка за изрязване (Interactive Crop Area)
                Center(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _startFocalPoint = details.focalPoint;
                      _startOffset = _offset;
                      _startScale = _scale;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        // Обновяваме zoom
                        final newScale = (_startScale * details.scale)
                            .clamp(_minScale, _minScale * _maxScale);
                        _scale = newScale;

                        // Обновяваме позицията (Pan)
                        final delta = details.focalPoint - _startFocalPoint;
                        _offset = _clampOffset(_startOffset + delta, newScale);
                      });
                    },
                    child: ClipOval(
                      child: RepaintBoundary(
                        key: _cropAreaKey,
                        child: Container(
                          width: _cropSize,
                          height: _cropSize,
                          color: Colors.black,
                          child: CustomPaint(
                            painter: _ImageCropPainter(
                              image: _decodedImage!,
                              scale: _scale,
                              offset: _offset,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Плъзни с пръст, за да позиционираш',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                // Слайдър за увеличение
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_size_select_actual_outlined,
                          color: Colors.grey, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade800,
                            thumbColor: Colors.white,
                            trackHeight: 3.0,
                          ),
                          child: Slider(
                            value: _scale,
                            min: _minScale,
                            max: _minScale * _maxScale,
                            onChanged: (value) {
                              setState(() {
                                _scale = value;
                                _offset = _clampOffset(_offset, _scale);
                              });
                            },
                          ),
                        ),
                      ),
                      const Icon(Icons.photo_size_select_actual,
                          color: Colors.white, size: 24),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Бутон за запазване
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Запази профилната снимка',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// CustomPainter за отрисуване на снимката с точна трансформация
class _ImageCropPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;

  _ImageCropPainter({
    required this.image,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    final center = Offset(size.width / 2, size.height / 2);
    final scaledWidth = image.width * scale;
    final scaledHeight = image.height * scale;

    final dstRect = Rect.fromCenter(
      center: center + offset,
      width: scaledWidth,
      height: scaledHeight,
    );

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ImageCropPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.image != image;
  }
}