import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:temperature_app/logic_extension.dart';
import 'package:temperature_app/ui_extension.dart';

typedef RefactorHandler = List<List<double>> Function(List<double>);
typedef ColorMaker = Color Function(double, [double]);

class TempNotifier with ChangeNotifier {
  // ignore: close_sinks
  Socket socket;

  String min = '';
  String max = '';
  String avg = '';
  String center = '';
  bool normal = true;

  List<double> _dataList = List();

  set dataList(List<double> newList) {
    if (newList.isEmpty) {
      min = '';
      max = '';
      avg = '';
      center = '';
      normal = true;
      _dataList = List();
      notifyListeners();
      return;
    }
    min = newList.reduce(math.min).toStringAsFixed(2);
    var maxValue = newList.reduce(math.max);
    max = maxValue.toStringAsFixed(2);
    var total = 0.0;
    newList.forEach((e) => total += e);
    avg = (total / newList.length).toStringAsFixed(2);
    center = newList[(newList.length / 2).round()].toStringAsFixed(2);
    normal = maxValue <= 37.2;
    _dataList = List()..addAll(newList);
    notifyListeners();
  }

  List<double> get dataList => _dataList;

  List<List<double>> refactor(List<double> list) =>
      list.isEmpty ? List() : _refactorHandler(list);

  RefactorHandler _refactorHandler = singleRefactor;

  set refactorHandler(RefactorHandler newHandler) {
    _refactorHandler = newHandler;
    notifyListeners();
  }

  RefactorHandler get refactorHandler => _refactorHandler;

  ColorMaker _colorMaker = rainbow2;

  set colorMaker(ColorMaker newMaker) {
    _colorMaker = newMaker;
    notifyListeners();
  }

  ColorMaker get colorMaker => _colorMaker;

  String getMakerName([int index]) {
    switch (index == null ? _colorMaker : makers[index]) {
      case rainbow1:
        return '彩虹一';
      case rainbow2:
        return '彩虹二';
      case rainbow3:
        return '彩虹三';
      case pseudo1:
        return '伪彩一';
      case pseudo2:
        return '伪彩二';
      case metal1:
        return '金属一';
      case metal2:
        return '金属二';
      default:
        return '灰度';
    }
  }

  String getHandlerName([int index]) {
    switch (index == null ? _refactorHandler : handlers[index]) {
      case simpleData:
        return '原始';
      case simpleNearest:
        return '临近法';
      case simpleLinear:
        return '线性法';
      case singleRefactor:
        return '单高阶';
      case complexRefactor:
        return '混合阶';
      case doubleRefactor:
        return '双高阶';
      default:
        return '？？？';
    }
  }

  List<ColorMaker> get makers =>
      [rainbow1, rainbow2, rainbow3, pseudo1, pseudo2, metal1, metal2, gray];

  List<RefactorHandler> get handlers => [
        simpleData,
        simpleNearest,
        simpleLinear,
        singleRefactor,
        complexRefactor,
        doubleRefactor
      ];

  int index;

  notify({@required bool maker}) {
    if (index == null) return;
    if (maker)
      colorMaker = makers[index];
    else
      refactorHandler = handlers[index];
  }
}
