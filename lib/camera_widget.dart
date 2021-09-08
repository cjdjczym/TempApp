import 'dart:async';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:temperature_app/main.dart';

class CameraMain extends StatefulWidget {
  @override
  _CameraMainState createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> {
  StreamController streamController;
  CameraController controller;

  @override
  void initState() {
    super.initState();
    streamController = StreamController<FacePainter>();
    getCameras();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  getCameras() async {
    var cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    await controller.initialize();
    var isProcess = false;
    controller.startImageStream((image) async {
      if (mounted && !isProcess) {
        isProcess = true;
        var detector = FirebaseVision.instance.faceDetector();
        var visionImage = FirebaseVisionImage.fromBytes(image.planes[0].bytes,
            buildMetaData(image, ImageRotation.rotation90));
        List<Face> faces = await detector.processImage(visionImage);
        List<Rect> rects = faces.map((face) => face.boundingBox).toList();
        isProcess = false;
        streamController.add(FacePainter(rects, controller.value.previewSize));
      }
    });
    setState(() {});
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
          formatCameraPreview(controller, TempApp.contentScale),
          StreamBuilder(
            stream: streamController.stream,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
                snapshot.hasData
                    ? CustomPaint(size: Size.infinite, painter: snapshot.data)
                    : SizedBox(),
          )
        ],
      ),
    );
  }

  Widget formatCameraPreview(CameraController controller, double contentScale) {
    var width = TempApp.screenWidth;
    var height = TempApp.screenWidth * controller.value.aspectRatio;

    /// 去掉下面多余的部分
    return ClipRect(
      child: SizedOverflowBox(
        size: Size(width, width * 512 / 384),

        /// 放大到原来大小
        child: SizedBox(
          width: width,
          height: height,
          child: SizedBox.expand(
            /// 截取宽度
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: SizedBox(
                width: width,
                height: height / contentScale,

                /// 截取高度
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: SizedBox(
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

  Rect scaleRect(Size newSize, Rect rect) {
    /// 由于相机图像旋转90°，这里的[imgSize.height]其实就是图像宽度
    /// 又由于Stack中使用了统一的[AspectRatio]，所以高度之比也是[scale]
    double s = newSize.width / imgSize.height, c = 1 / TempApp.contentScale;
    Rect newRect = Rect.fromLTWH(
        (rect.left - imgSize.height * (1 - c) / 2) * s / c,
        (rect.top - imgSize.width * (1 - c) / 2) * s / c,
        rect.width * s / c,
        rect.height * s / c);
    return newRect;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var newSize = Size(size.width + TempApp.decorationWidth * 2, size.height);
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.red;
    for (Rect rect in rects) {
      var newRect = scaleRect(newSize, rect);
      if (newRect.top + newRect.height > newSize.height) continue;
      canvas.drawRect(newRect, paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => oldDelegate.rects != rects;

  @override
  bool shouldRebuildSemantics(FacePainter oldDelegate) => false;
}
