import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:temperature_app/main.dart';
import 'package:temperature_app/temp_notifier.dart';

import 'logic_extension.dart';

class MakerDialog extends Dialog {
  final TempNotifier notifier;

  MakerDialog(this.notifier);

  @override
  Widget build(BuildContext context) {
    var width = TempApp.screenWidth - TempApp.decorationWidth * 2;
    var height = width * 5 / 4;
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Swiper(
              itemBuilder: (context, index) {
                var data = simpleData(test);
                return Stack(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.only(top: 48, right: 3),
                      child: RepaintBoundary(
                        child: CustomPaint(
                            size: Size(width - 100, height - 100),
                            painter:
                                TempPainter(data, notifier.makers[index], true)),
                      ),
                    ),
                    Align(
                        alignment: Alignment.topCenter,
                        child: Text(notifier.getMakerName(index),
                            style: TextStyle(fontSize: 25, color: Colors.white))),
                  ],
                );
              },
              itemCount: notifier.makers.length,
              index: notifier.makers.indexOf(notifier.colorMaker),
              onIndexChanged: ((index) => notifier.index = index),
              viewportFraction: 0.7,
              scale: 0.65,
              pagination: new SwiperPagination(
                  margin: const EdgeInsets.only(bottom: 20),
                  builder: DotSwiperPaginationBuilder(
                      activeColor: Colors.deepPurple[600])),
              control: new SwiperControl(
                  color: Colors.deepPurple[600],
                  size: 38,
                  padding: EdgeInsets.all(10)),
            ),
          ),
        ),
      ),
    );
  }
}

class HandlerDialog extends Dialog {
  final TempNotifier notifier;

  HandlerDialog(this.notifier);

  @override
  Widget build(BuildContext context) {
    var width = TempApp.screenWidth - TempApp.decorationWidth * 2;
    var height = width * 5 / 4;
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Swiper(
              itemBuilder: (context, index) {
                var data = notifier.handlers[index](test);
                return Stack(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.only(top: 48, right: 3),
                      child: RepaintBoundary(
                        child: CustomPaint(
                            size: Size(width - 100, height - 100),
                            painter:
                                TempPainter(data, notifier.colorMaker, true)),
                      ),
                    ),
                    Align(
                        alignment: Alignment.topCenter,
                        child: Text(notifier.getHandlerName(index),
                            style: TextStyle(fontSize: 25, color: Colors.white))),
                  ],
                );
              },
              itemCount: notifier.handlers.length,
              index: notifier.handlers.indexOf(notifier.refactorHandler),
              onIndexChanged: ((index) => notifier.index = index),
              viewportFraction: 0.7,
              scale: 0.65,
              pagination: new SwiperPagination(
                  margin: const EdgeInsets.only(bottom: 20),
                  builder: DotSwiperPaginationBuilder(
                      activeColor: Colors.deepPurple[600])),
              control: new SwiperControl(
                  color: Colors.deepPurple[600],
                  size: 38,
                  padding: EdgeInsets.all(10)),
            ),
          ),
        ),
      ),
    );
  }
}
