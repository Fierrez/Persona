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
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Pinch to Zoom + Scanner
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
          // Custom Scanner Overlay
          _buildScannerOverlay(context),
          
          // Zoom Slider (Scalable UI)
          Positioned(
            bottom: 140,
            left: 50,
            right: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white, size: 18),
                  Expanded(
                    child: Slider(
                      value: _zoomFactor,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        setState(() {
                          _zoomFactor = value;
                          controller.setZoomScale(value);
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () => controller.toggleTorch(),
                ),
                _buildCircleButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
          // Help Text
          const Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Pinch to zoom or use the slider",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
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
              borderColor: Colors.blue,
              borderRadius: 20,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 230,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Colors.blue, Colors.transparent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                transform: Matrix4.translationValues(
                  0,
                  (250 * _animationController.value) - 125,
                  0,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({required Widget icon, required VoidCallback onPressed}) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
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

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
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
