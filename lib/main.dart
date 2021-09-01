import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:temperature_app/camera_widget.dart';
import 'package:temperature_app/temp_notifier.dart';
import 'package:temperature_app/logic_extension.dart';
import 'package:temperature_app/ui_extension.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(TempApp());
  }, (Object error, StackTrace stack) {
    TempApp.logs.add(error);
    TempApp.logs.add(stack.toString());
  }, zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
    if (TempApp.logs.length > 30) TempApp.logs.clear();
    TempApp.logs.add(line);
  }));
}

class TempApp extends StatelessWidget {
  static List<String> logs = List();
  static double screenWidth;
  static double screenHeight;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (ctx) => TempNotifier()),
    ], child: MaterialApp(home: MainPage()));
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    TempApp.screenWidth = size.width;
    TempApp.screenHeight = size.height;
    return Scaffold(
        body: PageView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            children: [TempWidget(), CameraMain()]));
    // return CameraWidget();
  }
}

class TempWidget extends StatefulWidget {
  @override
  _TempWidgetState createState() => _TempWidgetState();
}

class _TempWidgetState extends State<TempWidget> {
  Socket socket;
  bool flag = false;
  List<double> bufferList = List();

  connect(TempNotifier notifier) async {
    const IP = "192.168.43.2";
    socket = await Socket.connect(IP, 80);
    socket.listen((event) {
      // print("数据类型: ${event.runtimeType} | 预计数据量: ${event.length / 4}");
      if (event[0] == 66) {
        flag = true;
      } else if (flag) {
        List<double> list = event.buffer.asFloat32List();
        // print("本次float数据量： ${list.length}---------------------------------");
        bufferList.addAll(list);
        if (bufferList.length > 768) {
          flag = false;
          bufferList.clear();
        }
        if (bufferList.length == 768) {
          // print(
              // "==========================成功接收一组数据=============================");
          // print(bufferList.toString());
          // print(
          //     "======================================================================");
          notifier.dataList = bufferList;
          flag = false;
          bufferList.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var canvasHeight = TempApp.screenWidth * 512 / 384;
    return Consumer<TempNotifier>(builder: (context, notifier, _) {
      return SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  height: canvasHeight,
                  child: notifier.dataList == null
                      ? Container()
                      : CustomPaint(
                          size: Size(TempApp.screenWidth, canvasHeight),
                          painter: TempPainter(notifier))),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Container(
                  width: 70,
                  height: 32,
                  child: FlatButton(
                      height: 32,
                      onPressed: () => connect(notifier),
                      color: Color.fromRGBO(98, 103, 124, 1.0),
                      child: Text('start')),
                ),
                button('A'),
                button('B'),
                button('C')
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                button('D'),
                button('E'),
                button('P'),
                button('Q')
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                button('伪彩1', () => notifier.colorMaker = pseudo1),
                button('伪彩2', () => notifier.colorMaker = pseudo2),
                button('金属1', () => notifier.colorMaker = metal1),
                button('金属2', () => notifier.colorMaker = metal2)
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                button('彩虹1', () => notifier.colorMaker = rainbow1),
                button('彩虹2', () => notifier.colorMaker = rainbow2),
                button('彩虹3', () => notifier.colorMaker = rainbow3),
                button('灰度', () => notifier.colorMaker = gray)
              ]),
              Container(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                // button('刷新', () => setState(() {})),
                // button('清除', () => setState(() => TempApp.logs.clear())),
                button('测试',
                    () => notifier.dataList = test.map((e) => e + 10).toList())
              ]),
              // Container(
              //   height: 70,
              //   child: ListView.builder(
              //       padding: EdgeInsets.symmetric(vertical: 3, horizontal: 15),
              //       itemCount: TempApp.logs.length,
              //       itemBuilder: (context, index) => Text(TempApp.logs[index],
              //           style: TextStyle(fontSize: 12, color: Colors.black))),
              // )
            ],
          ),
        ),
      );
    });
  }

  Widget button(String abc, [Function fun]) => Container(
        width: 70,
        height: 32,
        child: FlatButton(
            height: 32,
            onPressed: () => fun == null ? socket.write(abc) : fun(),
            color: Color.fromRGBO(98, 103, 124, 1.0),
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
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(TempPainter oldDelegate) =>
      oldDelegate.list != this.list ||
      oldDelegate.colorMaker != this.colorMaker;
}
