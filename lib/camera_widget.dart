import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:temperature_app/main.dart';

class CameraMain extends StatefulWidget {
  @override
  _CameraMainState createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> {
  CameraController controller;
  CustomPainter painter;
  var isProcess = false;

  @override
  void initState() {
    super.initState();
    getCameras();
  }

  getCameras() async {
    var cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize();

    controller.startImageStream((image) async {
      if (mounted && !isProcess) {
        isProcess = true;
        var detector = FirebaseVision.instance.faceDetector();
        var visionImage = FirebaseVisionImage.fromBytes(image.planes[0].bytes,
            buildMetaData(image, ImageRotation.rotation90));
        List<Face> faces = await detector.processImage(visionImage);
        List<Rect> rects = faces.map((face) => face.boundingBox).toList();
        isProcess = false;
        setState(() {
          painter = FacePainter(rects, controller.value.previewSize);
        });
      }
    });
  }

  FirebaseVisionImageMetadata buildMetaData(
      CameraImage image, ImageRotation rotation) {
    return FirebaseVisionImageMetadata(
        rawFormat: image.format.raw,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        planeData: image.planes
            .map((plane) => FirebaseVisionImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: Stack(
        children: <Widget>[
          formatCameraPreview(controller, 2),
          CustomPaint(size: Size.infinite, painter: painter)
        ],
      ),
    );
  }

  Widget formatCameraPreview1(CameraController controller, double scale) {
    var width = TempApp.screenWidth;
    var height = TempApp.screenWidth * controller.value.aspectRatio;

    /// 去掉下面多余的部分
    return ClipRect(
      child: SizedOverflowBox(
        alignment: Alignment.topCenter,
        size: Size(width, width * 512 / 384),

        /// 放大到原来大小
        child: Container(
          width: width,
          height: height,
          child: Transform.scale(
            scale: 2,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: FittedBox(
                child: Container(
                    width: width,
                    height: height,
                    child: CameraPreview(controller)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TODO FractionallySizedBox + FittedBox ?
  Widget formatCameraPreview(CameraController controller, double scale) {
    var width = TempApp.screenWidth;
    var height = TempApp.screenWidth * controller.value.aspectRatio;

    /// 去掉下面多余的部分
    return ClipRect(
      child: SizedOverflowBox(
        alignment: Alignment.topCenter,
        size: Size(width, width * 512 / 384),

        /// 放大到原来大小
        child: Container(
          width: width,
          height: height,
          child: SizedBox.expand(
            /// 截取一半宽度
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                width: width,
                height: height / scale,

                /// 截取一半高度
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Container(
                    width: width,
                    height: height,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Rect> rects;
  final Size imgSize;

  FacePainter(this.rects, this.imgSize);

  Rect scaleRect(Size size, Rect rect) {
    /// 由于相机图像旋转90°，这里的[imgSize.height]其实就是图像宽度
    /// 又由于Stack中使用了统一的[AspectRatio]，所以高度之比也是[scale]
    double scale = size.width / imgSize.height;
    Rect newRect = Rect.fromLTRB(rect.left * scale, rect.top * scale,
        rect.right * scale, rect.bottom * scale);
    return newRect;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.red;
    for (Rect rect in rects) {
      canvas.drawRect(scaleRect(size, rect), paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => oldDelegate.rects != rects;

  @override
  bool shouldRebuildSemantics(FacePainter oldDelegate) => false;
}
