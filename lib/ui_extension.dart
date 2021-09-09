import 'package:flutter/material.dart';

double minTemp = 25; // 25
double maxTemp = 40; // 40

int getValue(double temp) {
  if (temp < minTemp) temp = minTemp;
  if (temp > maxTemp) temp = maxTemp;
  return ((temp - minTemp) / (maxTemp - minTemp) * 255).round();
}

double getO(int value) {
  if (value < 85) // 小于30°时
    return 0.15 + value * 0.001765;
  else if (value > 221) // 大于38°时
    return 0.85;
  else
    return 0.3 + (value - 85) * 0.004;
}

/// 伪彩1
Color pseudo1(double temp, [double o]) {
  int value = getValue(temp);
  return Color.fromRGBO((0 - value).abs(), (127 - value).abs(),
      (255 - value).abs(), o == null ? getO(value) : o);
}

/// 伪彩2
Color pseudo2(double temp, [double o]) {
  int value = getValue(temp);
  var color;
  if (value >= 0 && value <= 63) {
    color = Color.fromRGBO(
        0, 0, (value / 64 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 64 && value <= 127) {
    color = Color.fromRGBO(0, ((value - 64) / 64 * 255).round(),
        ((127 - value) / 64 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 128 && value <= 191) {
    color = Color.fromRGBO(((value - 128) / 64 * 255).round(), 255, 0,
        o == null ? getO(value) : o);
  } else {
    color = Color.fromRGBO(255, ((255 - value) / 64 * 255).round(), 0,
        o == null ? getO(value) : o);
  }
  return color;
}

/// 金属1
Color metal1(double temp, [double o]) {
  int value = getValue(temp);
  var color;
  if (value >= 0 && value <= 63) {
    color = Color.fromRGBO(
        0, 0, (value / 64 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 64 && value <= 95) {
    color = Color.fromRGBO(((value - 63) / 32 * 127).round(),
        ((value - 63) / 32 * 127).round(), 255, o == null ? getO(value) : o);
  } else if (value >= 96 && value <= 127) {
    color = Color.fromRGBO(
        ((value - 95) / 32 * 127).round() + 128,
        ((value - 95) / 32 * 127).round() + 128,
        ((127 - value) / 32 * 255).round(),
        o == null ? getO(value) : o);
  } else if (value >= 128 && value <= 191) {
    color = Color.fromRGBO(255, 255, 0, o == null ? getO(value) : o);
  } else {
    color = Color.fromRGBO(255, 255, ((value - 192) / 64 * 255).round(),
        o == null ? getO(value) : o);
  }
  return color;
}

/// 金属2
Color metal2(double temp, [double o]) {
  int value = getValue(temp);
  int r, g, b = 0;
  if (value >= 0 && value <= 16)
    r = 0;
  else if (value >= 17 && value <= 140)
    r = ((value - 16) / (140 - 16) * 255).round();
  else
    r = 255;

  if (value >= 0 && value <= 101)
    g = 0;
  else if (value >= 102 && value <= 218)
    g = ((value - 101) / (208 - 101) * 255).round();
  else
    g = 255;

  if (value >= 0 && value <= 91)
    b = 28 + ((value - 0) / (91 - 0) * 100).round();
  else if (value >= 92 && value <= 120)
    b = ((120 - value) / (120 - 91) * 128).round();
  else if (value >= 121 && value <= 214)
    b = 0;
  else
    b = ((value - 214) / (255 - 214) * 255).round();
  return Color.fromRGBO(r, g, b, o == null ? getO(value) : o);
}

/// 彩虹1
Color rainbow1(double temp, [double o]) {
  int value = getValue(temp);
  var color;
  if (value >= 0 && value <= 31) {
    color = Color.fromRGBO(
        0, 0, (value / 32 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 32 && value <= 63) {
    color = Color.fromRGBO(
        0, ((value - 32) / 32 * 255).round(), 255, o == null ? getO(value) : o);
  } else if (value >= 64 && value <= 95) {
    color = Color.fromRGBO(
        0, 255, ((95 - value) / 32 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 96 && value <= 127) {
    color = Color.fromRGBO(
        ((value - 96) / 32 * 255).round(), 255, 0, o == null ? getO(value) : o);
  } else if (value >= 128 && value <= 191) {
    color = Color.fromRGBO(255, ((191 - value) / 64 * 255).round(), 0,
        o == null ? getO(value) : o);
  } else {
    color = Color.fromRGBO(255, ((value - 192) / 64 * 255).round(),
        ((value - 192) / 64 * 255).round(), o == null ? getO(value) : o);
  }
  return color;
}

/// 彩虹2
Color rainbow2(double temp, [double o]) {
  int value = getValue(temp);
  var color;
  if (value >= 0 && value <= 63) {
    color = Color.fromRGBO(
        0, ((value - 0) / 64 * 255).round(), 255, o == null ? getO(value) : o);
  } else if (value >= 64 && value <= 95) {
    color = Color.fromRGBO(
        0, 255, ((95 - value) / 32 * 255).round(), o == null ? getO(value) : o);
  } else if (value >= 96 && value <= 127) {
    color = Color.fromRGBO(
        ((value - 96) / 32 * 255).round(), 255, 0, o == null ? getO(value) : o);
  } else if (value >= 128 && value <= 191) {
    color = Color.fromRGBO(255, ((191 - value) / 64 * 255).round(), 0,
        o == null ? getO(value) : o);
  } else {
    color = Color.fromRGBO(255, ((value - 192) / 64 * 255).round(),
        ((value - 192) / 64 * 255).round(), o == null ? getO(value) : o);
  }
  return color;
}

/// 彩虹3
Color rainbow3(double temp, [double o]) {
  int value = getValue(temp);
  var color;
  if (value >= 0 && value <= 51) {
    color = Color.fromRGBO(0, value * 5, 255, o == null ? getO(value) : o);
  } else if (value >= 52 && value <= 102) {
    color = Color.fromRGBO(
        0, 255, 255 - (value - 51) * 5, o == null ? getO(value) : o);
  } else if (value >= 103 && value <= 153) {
    color =
        Color.fromRGBO((value - 102) * 5, 255, 0, o == null ? getO(value) : o);
  } else if (value >= 154 && value <= 204) {
    color = Color.fromRGBO(255, (255 - 128 * (value - 153) / 51).round(), 0,
        o == null ? getO(value) : o);
  } else {
    color = Color.fromRGBO(255, (127 - 127 * (value - 204) / 51).round(), 0,
        o == null ? getO(value) : o);
  }
  return color;
}

/// 灰度
Color gray(double temp, [double o]) {
  int value = getValue(temp);
  return Color.fromRGBO(
      value << 16, value << 8, value, o == null ? getO(value) : o);
}
