import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temperature_app/camera_widget.dart';
import 'package:temperature_app/info_dialog.dart';
import 'package:temperature_app/persistent.dart';
import 'package:temperature_app/swiper.dart';
import 'package:temperature_app/temp_notifier.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:temperature_app/webview.dart';
import 'display_widget.dart';
import 'logic_extension.dart';

void main() {
  runApp(TempApp());
}

class TempApp extends StatelessWidget {
  static SharedPreferences pref;
  static String name = '小明';
  static String address = '北洋园校区';

  static double contentScale = 1.5;
  static double decorationWidth = 4;
  static double screenWidth;
  static double screenHeight;
  static double faceOpacity = 1.0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharedPreferences.getInstance().then((value) => pref = value);
    });
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(98, 103, 124, 1.0),
          title: Text("红外测温App"),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: Text("信息录入"), value: "信息录入"),
                PopupMenuItem(child: Text("删除记录"), value: "删除记录"),
              ],
              onSelected: (value) {
                if (value == "信息录入") {
                  showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => InfoDialog());
                } else {
                  TempApp.pref.clear();
                }
              },
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '图像'),
              Tab(text: '统计'),
              Tab(text: '数据库'),
            ],
          ),
        ),
        backgroundColor: Color.fromRGBO(98, 103, 124, 1.0),
        body: ChangeNotifierProvider<TempNotifier>(
          create: (ctx) => TempNotifier(),
          child: TabBarView(children: [
            TempWidget(),
            DisplayWidget(),
            WebWidget(),
          ]),
        ),
      ),
    );
  }
}

class TempWidget extends StatelessWidget {
  static const List<ButtonState> states = [
    ButtonState.idle, // click to connect
    ButtonState.loading,
    ButtonState.fail,
    ButtonState.success,
    ButtonState.idle, // click to disconnect
  ];
  static const IP = "192.168.43.2";
  final List<double> bufferList = List();
  final ValueNotifier<int> buttonState = ValueNotifier(0);
  final ValueNotifier<bool> cameraState = ValueNotifier(false);
  final ValueNotifier<bool> faceState = ValueNotifier(true);

  Future<bool> connect(TempNotifier notifier) async {
    try {
      notifier.socket =
          await Socket.connect(IP, 80, timeout: Duration(seconds: 5));
    } catch (e) {
      return false;
    }
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
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var notifier = Provider.of<TempNotifier>(context, listen: false);
    var canvasHeight = TempApp.screenWidth * 4 / 3;
    var side = BorderSide(color: Colors.blue, width: TempApp.decorationWidth);
    return SafeArea(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: side, right: side, bottom: side)),
            child: ValueListenableBuilder(
              valueListenable: cameraState,
              builder: (_, value, __) {
                return Stack(
                  children: [
                    SizedBox(
                      height: canvasHeight,
                      child: value ? CameraMain() : Container(),
                    ),
                    Container(
                      height: canvasHeight,
                      child: Consumer<TempNotifier>(
                        builder: (_, tempNotifier, __) {
                          if (notifier.dataList == null) {
                            return Container();
                          } else {
                            var data = notifier.refactor(notifier.dataList);
                            return RepaintBoundary(
                              child: CustomPaint(
                                  size: Size(TempApp.screenWidth, canvasHeight),
                                  painter: TempPainter(
                                      data, notifier.colorMaker, !value)),
                            );
                          }
                        },
                      ),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      margin: const EdgeInsets.all(10),
                      child: Consumer<TempNotifier>(
                        builder: (_, tempNotifier, __) {
                          return DefaultTextStyle.merge(
                            style: TextStyle(fontWeight: FontWeight.bold),
                            child: Column(children: [
                              Text('最高温度: ${tempNotifier.max}'),
                              Text('最低温度: ${tempNotifier.min}'),
                              Text('平均温度: ${tempNotifier.avg}'),
                              Text('中心温度: ${tempNotifier.center}'),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(fontSize: 12),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('相机'),
                          ValueListenableBuilder(
                            valueListenable: cameraState,
                            builder: (_, value, __) {
                              return Switch(
                                value: value,
                                onChanged: (bool newValue) =>
                                    cameraState.value = newValue,
                                activeColor: Colors.deepPurple,
                                inactiveThumbColor: Colors.grey[400],
                                activeTrackColor: Colors.deepPurple[100],
                                inactiveTrackColor: Colors.white,
                              );
                            },
                          ),
                          SizedBox(height: 10),
                          Text('人脸识别'),
                          ValueListenableBuilder(
                            valueListenable: faceState,
                            builder: (_, value, __) {
                              return Switch(
                                value: value,
                                onChanged: (bool newValue) {
                                  newValue
                                      ? TempApp.faceOpacity = 1.0
                                      : TempApp.faceOpacity = 0.0;
                                  faceState.value = newValue;
                                },
                                activeColor: Colors.deepPurple,
                                inactiveThumbColor: Colors.grey[400],
                                activeTrackColor: Colors.deepPurple[100],
                                inactiveTrackColor: Colors.white,
                              );
                            },
                          )
                        ]),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.white)),
                          child: IconButton(
                              icon: Icon(Icons.camera, color: Colors.white),
                              onPressed: () {
                                if (notifier.dataList.isEmpty) return;
                                UserDaily daily = UserDaily.fromData(
                                    notifier.normal,
                                    notifier.min,
                                    notifier.max,
                                    notifier.avg,
                                    notifier.center,
                                    notifier.dataList);
                                saveLocal(TempApp.pref, daily);
                                postRemote(daily);
                                // notifier.dataList = test;
                              }),
                        ),
                        SizedBox(height: 20),
                        ValueListenableBuilder(
                          valueListenable: buttonState,
                          builder: (context, index, _) {
                            return ProgressButton.icon(
                              maxWidth: 135.0,
                              state: states[index],
                              iconedButtons: {
                                ButtonState.idle: index == 0
                                    ? IconedButton(
                                        text: "Connect",
                                        icon: Icon(Icons.send,
                                            color: Colors.white),
                                        color: Colors.deepPurple)
                                    : IconedButton(
                                        text: "Disconnect",
                                        icon: Icon(Icons.access_time,
                                            color: Colors.white),
                                        color: Colors.deepPurple),
                                ButtonState.loading: IconedButton(
                                    text: "Loading",
                                    color: Colors.deepPurple[700]),
                                ButtonState.fail: IconedButton(
                                    text: "Failed",
                                    icon:
                                        Icon(Icons.cancel, color: Colors.white),
                                    color: Colors.red[300]),
                                ButtonState.success: IconedButton(
                                    text: "Success",
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    color: Colors.green[400])
                              },
                              onPressed: () async {
                                if (index == 0) {
                                  buttonState.value = 1;
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                  var flag = await connect(notifier);
                                  if (flag) {
                                    buttonState.value = 3;
                                    await Future.delayed(Duration(seconds: 2));
                                    notifier.socket.write('C');
                                    buttonState.value = 4;
                                  } else {
                                    buttonState.value = 2;
                                    await Future.delayed(Duration(seconds: 2));
                                    buttonState.value = 0;
                                  }
                                } else if (index == 4) {
                                  buttonState.value = 1;
                                  notifier.socket.write('Q');
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                  notifier.dataList = List();
                                  buttonState.value = 0;
                                }
                              },
                            );
                          },
                        ),
                        SizedBox(height: 20)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Consumer<TempNotifier>(
                      builder: (_, notifier, __) {
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('伪彩方案'),
                              SizedBox(
                                width: 75,
                                child: RaisedButton(
                                  child: Text(notifier.getMakerName(),
                                      style: TextStyle(fontSize: 13)),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) =>
                                            MakerDialog(notifier)).then(
                                        (_) => notifier.notify(maker: true));
                                  },
                                  color: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('插值算法'),
                              SizedBox(
                                width: 75,
                                child: RaisedButton(
                                  child: Text(notifier.getHandlerName(),
                                      style: TextStyle(fontSize: 13)),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) =>
                                            HandlerDialog(notifier)).then(
                                        (_) => notifier.notify(maker: false));
                                  },
                                  color: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TempPainter extends CustomPainter {
  final List<List<double>> data;
  final ColorMaker colorMaker;
  final bool fill;

  TempPainter(this.data, this.colorMaker, this.fill);

  @override
  void paint(Canvas canvas, Size size) async {
    if (data.isEmpty) return;
    Paint paint = Paint()..style = PaintingStyle.fill;
    int x = data.length, y = data[0].length;
    double sliceX = size.width / x, sliceY = size.height / y;
    for (int i = 0; i < x; i++) {
      for (int j = 0; j < y; j++) {
        Rect rect = Offset(sliceX * i, sliceY * j) & Size(sliceX, sliceY);
        paint.color = colorMaker(data[i][j], fill ? 1.0 : null);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TempPainter oldDelegate) => true;
}
