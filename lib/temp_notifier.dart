import 'dart:math';

import 'package:flutter/material.dart';
import 'package:temperature_app/logic_extension.dart';
import 'package:temperature_app/ui_extension.dart';

typedef RefactorHandler = List<List<double>> Function(List<double>);
typedef ColorMaker = Color Function(double);

class TempNotifier with ChangeNotifier {
  List<double> _dataList;

  set dataList(List<double> newList) {
    // minTemp = min(minTemp, newList.reduce(min));
    // maxTemp = max(maxTemp, newList.reduce(max));
    _dataList = List()..addAll(newList);
    notifyListeners();
  }

  List<double> get dataList => _dataList;

  RefactorHandler _refactorHandler = refactor1;

  set refactorHandler(RefactorHandler newHandler) {
    _refactorHandler = newHandler;
    notifyListeners();
  }

  RefactorHandler get refactorHandler => _refactorHandler;

  ColorMaker _colorMaker = pseudo1;

  set colorMaker(ColorMaker newMaker) {
    _colorMaker = newMaker;
    notifyListeners();
  }

  ColorMaker get colorMaker => _colorMaker;

  bool _showCamera = false;

  set showCamera(bool newBool) {
    _showCamera = newBool;
    notifyListeners();
  }

  bool get showCamera => _showCamera;
}
