import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  late AnimationController _animationController;
  bool isScanned = false;
  double _zoomFactor = 0.0;
  double _baseZoomFactor = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              final torchState = state.torchState;
              IconData icon;
              Color color;
              
              switch (torchState) {
                case TorchState.on:
                  icon = Icons.flash_on_rounded;
                  color = Colors.yellow;
                  break;
                case TorchState.off:
                default:
                  icon = Icons.flash_off_rounded;
                  color = Colors.white;
                  break;
              }
              
              return IconButton(
                icon: Icon(icon, color: color),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onScaleStart: (details) {
              _baseZoomFactor = _zoomFactor;
            },
            onScaleUpdate: (details) {
              setState(() {
                _zoomFactor = (_baseZoomFactor * details.scale).clamp(0.0, 1.0);
                controller.setZoomScale(_zoomFactor);
              });
            },
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (isScanned) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() {
                      isScanned = true;
                    });
                    Navigator.pop(context, barcode.rawValue);
                    break;
                  }
                }
              },
            ),
          ),
          _buildScannerOverlay(context),
          
          Positioned(
            bottom: 100,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(138),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.blueAccent,
                            inactiveTrackColor: Colors.white.withAlpha(60),
                            thumbColor: Colors.white,
                            overlayColor: Colors.blueAccent.withAlpha(50),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _zoomFactor,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) {
                              setState(() {
                                _zoomFactor = value;
                                controller.setZoomScale(value);
                              });
                            },
                          ),
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Align QR code within the frame",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Pinch to zoom or use the slider",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: Colors.blueAccent,
              borderRadius: 24,
              borderLength: 40,
              borderWidth: 10,
              cutOutSize: 280,
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withAlpha(0),
                      Colors.blueAccent,
                      Colors.blueAccent.withAlpha(0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withAlpha(100),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                transform: Matrix4.translationValues(
                  0,
                  (280 * _animationController.value) - 140,
                  0,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 8,
    this.borderLength = 30,
    this.borderRadius = 20,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()..color = Colors.black.withAlpha(178);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            cutOutRect,
            Radius.circular(borderRadius),
          )),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left, rrect.top + borderLength)
        ..lineTo(rrect.left, rrect.top + borderRadius)
        ..arcToPoint(Offset(rrect.left + borderRadius, rrect.top), radius: Radius.circular(borderRadius))
        ..lineTo(rrect.left + borderLength, rrect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right - borderLength, rrect.top)
        ..lineTo(rrect.right - borderRadius, rrect.top)
        ..arcToPoint(Offset(rrect.right, rrect.top + borderRadius), radius: Radius.circular(borderRadius))
        ..lineTo(rrect.right, rrect.top + borderLength),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left, rrect.bottom - borderLength)
        ..lineTo(rrect.left, rrect.bottom - borderRadius)
        ..arcToPoint(Offset(rrect.left + borderRadius, rrect.bottom), radius: Radius.circular(borderRadius), clockwise: false)
        ..lineTo(rrect.left + borderLength, rrect.bottom),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right, rrect.bottom - borderLength)
        ..lineTo(rrect.right, rrect.bottom - borderRadius)
        ..arcToPoint(Offset(rrect.right - borderRadius, rrect.bottom), radius: Radius.circular(borderRadius))
        ..lineTo(rrect.right, rrect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
