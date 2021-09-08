import 'dart:io';
import 'package:flutter/material.dart';
import 'package:temperature_app/logic_extension.dart';
import 'package:temperature_app/ui_extension.dart';

typedef RefactorHandler = List<List<double>> Function(List<double>);
typedef ColorMaker = Color Function(double);

class TempNotifier with ChangeNotifier {
  // ignore: close_sinks
  Socket socket;

  List<double> _dataList;

  set dataList(List<double> newList) {
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

  ColorMaker _colorMaker = rainbow1;

  set colorMaker(ColorMaker newMaker) {
    _colorMaker = newMaker;
    notifyListeners();
  }

  ColorMaker get colorMaker => _colorMaker;

  String get makerName {
    switch (_colorMaker) {
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

  String get handlerName {
    switch (_refactorHandler) {
      case doubleRefactor:
        return '最复杂';
      case singleRefactor:
        return '正常';
      case nearest:
        return '最邻近';
      default:
        return '原始';
    }
  }
}
