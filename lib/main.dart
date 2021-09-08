import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:temperature_app/camera_widget.dart';
import 'package:temperature_app/temp_notifier.dart';
import 'package:temperature_app/logic_extension.dart';
import 'package:temperature_app/ui_extension.dart';

void main() {
  runApp(TempApp());
}

class TempApp extends StatelessWidget {
  static double contentScale = 1.5;
  static double decorationWidth = 4;
  static double screenWidth;
  static double screenHeight;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => GestureDetector(
          onTapDown: (TapDownDetails details) {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus.unfocus();
            }
          },
          child: child),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    TempApp.screenWidth = size.width;
    TempApp.screenHeight = size.height;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Color.fromRGBO(98, 103, 124, 1.0),
          title: Text("红外测温App"),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: IconButton(
                icon: Icon(Icons.list, size: 28),
                splashRadius: 30,
                onPressed: () {},
              ),
            )
          ]),
      body: ChangeNotifierProvider<TempNotifier>(
          create: (ctx) => TempNotifier(), child: TempWidget()),
    );
  }
}

class TempWidget extends StatelessWidget {
  final ValueNotifier<bool> showCamera = ValueNotifier(false);
  static const IP = "192.168.43.2";
  final List<double> bufferList = List();

  connect(TempNotifier notifier) async {
    notifier.socket = await Socket.connect(IP, 80);
    var flag = false;
    notifier.socket.listen((event) {
      if (event[0] == 66) {
        flag = true;
      } else if (flag) {
        List<double> list = event.buffer.asFloat32List();
        bufferList.addAll(list);
        if (bufferList.length > 768) {
          flag = false;
          bufferList.clear();
        }
        if (bufferList.length == 768) {
          notifier.dataList = bufferList;
          flag = false;
          bufferList.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var notifier = Provider.of<TempNotifier>(context, listen: false);
    var canvasHeight = TempApp.screenWidth * 512 / 384;
    return SafeArea(
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 12),
        child: Container(
          color: Color.fromRGBO(98, 103, 124, 1.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Colors.blue, width: TempApp.decorationWidth)),
                child: Stack(
                  children: [
                    ValueListenableBuilder(
                        valueListenable: showCamera,
                        builder: (_, value, __) {
                          return SizedBox(
                            height: canvasHeight,
                            child: value ? CameraMain() : Container(),
                          );
                        }),
                    Container(
                      height: canvasHeight,
                      child: Consumer<TempNotifier>(
                        builder: (context, tempNotifier, _) {
                          if (notifier.dataList == null) {
                            return Container();
                          } else {
                            return RepaintBoundary(
                              child: CustomPaint(
                                  size: Size(TempApp.screenWidth, canvasHeight),
                                  painter: TempPainter(tempNotifier)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Container(
                  width: 70,
                  height: 32,
                  child: FlatButton(
                      height: 32,
                      onPressed: () => connect(notifier),
                      color: Colors.green[300],
                      child: Text('start')),
                ),
                button('A', notifier),
                button('B', notifier),
                button('C', notifier)
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                button('D', notifier),
                button('E', notifier),
                button('P', notifier),
                button('Q', notifier)
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                button('彩虹1', notifier, () => notifier.colorMaker = rainbow1),
                button('彩虹2', notifier, () => notifier.colorMaker = rainbow2),
                button('彩虹3', notifier, () => notifier.colorMaker = rainbow3),
                button('灰度', notifier, () => notifier.colorMaker = gray)
              ]),
              // Container(height: 10),
              // Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              //   button('伪彩1', notifier, () => notifier.colorMaker = pseudo1),
              //   button('伪彩2', notifier, () => notifier.colorMaker = pseudo2),
              //   button('金属1', notifier, () => notifier.colorMaker = metal1),
              //   button('金属2', notifier, () => notifier.colorMaker = metal2)
              // ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ValueListenableBuilder(
                  valueListenable: showCamera,
                  builder: (_, value, __) {
                    return SizedBox(
                        width: 70,
                        height: 32,
                        child: FlatButton(
                            height: 32,
                            color: Colors.green[300],
                            onPressed: () {
                              showCamera.value = !showCamera.value;
                            },
                            child: Text(value ? '隐藏' : '显示')));
                  },
                ),
                button('测试', notifier,
                    () => notifier.dataList = test.map((e) => e + 10).toList())
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget button(String abc, TempNotifier notifier, [Function fun]) => Container(
        width: 70,
        height: 32,
        child: FlatButton(
            height: 32,
            onPressed: () => fun == null ? notifier.socket.write(abc) : fun(),
            color: Colors.green[300],
            child: Text(abc)),
      );
}

class TempPainter extends CustomPainter {
  final List<List<double>> list;
  final ColorMaker colorMaker;

  TempPainter(TempNotifier notifier)
      : list = notifier.refactorHandler(notifier.dataList),
        colorMaker = notifier.colorMaker;

  @override
  void paint(Canvas canvas, Size size) async {
    Paint paint = Paint()..style = PaintingStyle.fill;
    int x = list.length, y = list[0].length;
    double sliceX = size.width / x, sliceY = size.height / y;
    for (int i = 0; i < x; i++) {
      for (int j = 0; j < y; j++) {
        Rect rect = Offset(sliceX * i, sliceY * j) & Size(sliceX, sliceY);
        paint.color = colorMaker(list[i][j]);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TempPainter oldDelegate) => true;
}

// class TempPainter extends CustomPainter {
//   final ui.Image image;
//
//   TempPainter(TempNotifier notifier) : image = notifier.image;
//
//   @override
//   void paint(Canvas canvas, Size size) async {
//     canvas.drawImage(image, Offset.zero, Paint());
//   }
//
//   @override
//   bool shouldRepaint(TempPainter oldDelegate) => true;
// }
