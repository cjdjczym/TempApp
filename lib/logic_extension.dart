import 'dart:math';

/// 一维数组拆分为二维数组
List<List<double>> split(List<double> list, int width) {
  int depth = (list.length / width).round();
  return List.generate(depth,
      (column) => List.generate(width, (row) => list[column * width + row]));
}

/// 原始数据
List<List<double>> simpleData(List<double> data) {
  List<List<double>> list = split(data, 32);
  return list;
}

/// 临近法：临近（8）
List<List<double>> simpleNearest(List<double> data) {
  List<List<double>> list = split(data, 32);
  return nearest(list, 8);
}

/// 线性法：线性（8）
List<List<double>> simpleLinear(List<double> data) {
  List<List<double>> list = split(data, 32);
  return linear(list, 8);
}

/// 单高阶：三次 + 线性（2）
List<List<double>> singleRefactor(List<double> data) {
  List<List<double>> list = split(data, 32);
  List<List<double>> result = List.generate(24 * 4, (_) => List(32 * 4));
  for (int i = 0; i < 24; i++) {
    result[i] = polynomialInterpolation(list[i], 4, true);
  }
  List<double> temp;
  for (int i = 0; i < 32 * 4; i++) {
    temp = polynomialInterpolation(
        List()..addAll(result.getRange(0, 24).map((e) => e[i])), 4, false);
    for (int j = 0; j < 24 * 4; j++) {
      result[j][i] = temp[j];
    }
  }
  return linear(result, 2);
}

/// 混合阶：三次 + 线性（2）+ 临近（2）
List<List<double>> complexRefactor(List<double> data) {
  List<List<double>> list = split(data, 32);
  List<List<double>> result = List.generate(24 * 4, (_) => List(32 * 4));
  for (int i = 0; i < 24; i++) {
    result[i] = polynomialInterpolation(list[i], 4, i.isOdd);
  }
  List<double> temp;
  for (int i = 0; i < 32 * 4; i++) {
    temp = polynomialInterpolation(
        List()..addAll(result.getRange(0, 24).map((e) => e[i])), 4, i.isEven);
    for (int j = 0; j < 24 * 4; j++) {
      result[j][i] = temp[j];
    }
  }
  return nearest(linear(result, 2), 2);
}

/// 双高阶：三次 + 三次
List<List<double>> doubleRefactor(List<double> data) {
  List<List<double>> list = split(data, 32);
  List<List<double>> result =
      List.generate(24 * 4 * 4, (_) => List(32 * 4 * 4));
  for (int i = 0; i < 24; i++) {
    result[i] = polynomialInterpolation(
        polynomialInterpolation(list[i], 4, true), 4, false);
  }
  List<double> temp;
  for (int i = 0; i < 32 * 4 * 4; i++) {
    temp = polynomialInterpolation(
        polynomialInterpolation(
            List()..addAll(result.getRange(0, 24).map((e) => e[i])), 4, true),
        4,
        false);
    for (int j = 0; j < 24 * 4 * 4; j++) {
      result[j][i] = temp[j];
    }
  }
  return result;
}

/// 最邻近插值法 × scale
List<List<double>> nearest(List<List<double>> src, int scale) {
  var col = src.length, row = src[0].length;
  var result = List.generate(
      col * scale,
      (j) => List.generate(
          row * scale,
          (i) => src[min((j / scale).floor(), col * scale - 1)]
              [min((i / scale).floor(), row * scale - 1)]));
  return result;
}

/// 双线性插值法 × scale
List<List<double>> linear(List<List<double>> src, int scale) {
  int srcRows = src.length,
      srcCols = src[0].length,
      dstRows = srcRows * scale,
      dstCols = srcCols * scale;
  List<List<double>> dst = List.generate(dstRows, (_) => List(dstCols));
  for (int j = 0; j < dstRows; j++) {
    double fy = (j + 0.5) / scale - 0.5;
    int sy = fy.floor();
    fy -= sy;
    sy = min(sy, srcRows - 2);
    sy = max(0, sy);
    List<double> cbufy = List(2);
    cbufy[0] = 1 - fy;
    cbufy[1] = 1 - cbufy[0];

    for (int i = 0; i < dstCols; i++) {
      double fx = (i + 0.5) / scale - 0.5;
      int sx = fx.floor();
      fx -= sx;
      if (sx < 0) {
        fx = 0;
        sx = 0;
      }
      if (sx >= srcCols - 1) {
        fx = 0;
        sx = srcCols - 2;
      }
      List<double> cbufx = List(2);
      cbufx[0] = 1 - fx;
      cbufx[1] = 1 - cbufx[0];
      var value = (src[sy][sx] * cbufx[1] * cbufy[1] +
          src[sy + 1][sx] * cbufx[0] * cbufy[1] +
          src[sy][sx + 1] * cbufx[1] * cbufy[0] +
          src[sy + 1][sx + 1] * cbufx[0] * cbufy[0]);
      dst[j][i] = value;
    }
  }
  return dst;
}

/// 三次多项式 + 双线性插值法 ×4
/// [source]为插值前的一行（或一列）一维double数组
/// [times]为插值多项式的项数（项数 = 最高项次数 + 1）
/// [fromStart]是否在首端插2个值（false的话就只插1个，改为后端插2个）
List<double> polynomialInterpolation(
    List<double> source, int times, bool fromStart) {
  if (times < 2 || times > 4) times = 2; // 只支持一次、二次、三次多项式
  int len = source.length;
  int startIndex = fromStart ? 2 : 1; // 跳过首端的一个或两个值
  List<List<double>> originData =
      List.generate(2, (_) => List(times)); // originData[2][times]
  List<double> cores = List(4);
  List<double> result = List(4 * len); // result[4 * len]

  /// 源数据复制到目标数组result
  for (int i = 0; i < len; i++) {
    result[startIndex + i * 4] = source[i];
  }

  /// 主体部分插值
  var temp;
  for (int i = 0; i <= len - times; i++) {
    for (int j = 0; j < times; j++) {
      originData[0][j] = (j * 4).toDouble();
      originData[1][j] = source[i + j];
    }
    cores = getPolyData(originData, times);
    for (int j = 1; j < 4; j++) {
      if (times >= 2) temp = cores[0] + j * cores[1];
      if (times >= 3) temp = temp + j * j * cores[2];
      if (times >= 4) temp = temp + j * j * j * cores[3];
      result[startIndex + i * 4 + j] = temp;
    }
  }

  /// 首端插值，使用线性插值（一次多项式）
  originData[0][0] = 0;
  originData[1][0] = source[0];
  originData[0][1] = 4;
  originData[1][1] = source[1];

  cores = getPolyData(originData, 2);

  if (fromStart) {
    result[1] = cores[0] + (-1) * cores[1];
    result[0] = cores[0] + (-2) * cores[1];
  } else {
    result[0] = cores[0] + (-1) * cores[1];
  }

  /// 末端插值，使用线性插值（一次多项式）
  for (int i = len - times; i < len - 1; i++) {
    // 这里好像和上面在i = len - times时重叠了，暂时不管
    for (int j = 0; j < 2; j++) {
      originData[0][j] = (j * 4).toDouble();
      originData[1][j] = source[i + j];
    }
    cores = getPolyData(originData, 2);
    for (int j = 1; j < 4; j++) {
      result[startIndex + i * 4 + j] = cores[0] + j * cores[1];
    }
  }

  if (fromStart) {
    result[len * 4 - 1] = cores[0] + 5 * cores[1];
  } else {
    result[len * 4 - 2] = cores[0] + 5 * cores[1];
    result[len * 4 - 1] = cores[0] + 6 * cores[1];
  }

  return result;
}

/// 1次多项式：a + bx = y
/// 2次多项式：a + bx + cx ^ 2 = y
/// 3次多项式：a + bx + cx ^ 2 + dx ^ 3 = y
List<double> getPolyData(List<List<double>> originData, int times) {
  double x2, x3, x4; // x1 = originData[0][0] is useless
  double y1, y2, y3, y4;
  List<double> cores = List(4);
  if (times == 2) {
    x2 = originData[0][1];
    y1 = originData[1][0];
    y2 = originData[1][1];
    cores[1] = (y2 - y1) / x2;
    cores[0] = y1;
  } else if (times == 3) {
    x2 = originData[0][1];
    x3 = originData[0][2];
    y1 = originData[1][0];
    y2 = originData[1][1];
    y3 = originData[1][2];
    cores[2] =
        ((y3 - y1) * x2 - (y2 - y1) * x3) / (x2 * x3 * x3 - x2 * x2 * x3);
    cores[1] = (y2 - y1) / x2;
    cores[0] = y1;
  } else {
    x2 = originData[0][1];
    x3 = originData[0][2];
    x4 = originData[0][3];
    y1 = originData[1][0];
    y2 = originData[1][1];
    y3 = originData[1][2];
    y4 = originData[1][3];
    cores[3] = ((y4 - y1) * x2 - (y2 - y1) * x4) / x2 -
        ((y3 - y1) * x2 - (y2 - y1) * x3) /
            (x2 * x3 * x3 - x2 * x2 * x3) *
            (x2 * x4 * x4 - x2 * x2 * x4) /
            x2;
    cores[3] = cores[3] /
        ((x2 * x4 * x4 * x4 - x2 * x2 * x2 * x4) / x2 -
            (x2 * x3 * x3 * x3 - x2 * x2 * x2 * x3) /
                (x2 * x3 * x3 - x2 * x2 * x3) *
                (x2 * x4 * x4 - x2 * x2 * x4) /
                x2);
    cores[2] =
        ((y3 - y1) * x2 - (y2 - y1) * x3) / (x2 * x3 * x3 - x2 * x2 * x3);
    cores[1] = (y2 - y1) / x2;
    cores[0] = y1;
  }
  return cores;
}

List<double> test = [
  26.45,
  25.79,
  25.89,
  26.51,
  26.99,
  24.99,
  26.59,
  25.92,
  26.17,
  26.25,
  26.42,
  26.44,
  26.30,
  26.61,
  26.78,
  26.16,
  26.26,
  26.17,
  26.14,
  27.31,
  26.63,
  25.87,
  26.53,
  26.61,
  27.28,
  27.73,
  27.91,
  28.15,
  28.95,
  29.25,
  31.02,
  32.07,
  27.54,
  27.07,
  26.01,
  26.82,
  26.14,
  26.26,
  26.27,
  26.22,
  26.39,
  26.70,
  26.88,
  26.31,
  26.11,
  25.76,
  25.90,
  26.34,
  26.21,
  26.37,
  25.64,
  26.41,
  26.53,
  26.81,
  26.31,
  27.39,
  27.41,
  27.68,
  29.03,
  29.34,
  30.89,
  31.41,
  32.42,
  32.63,
  27.69,
  25.91,
  27.01,
  26.32,
  26.41,
  26.73,
  26.82,
  26.10,
  26.54,
  26.39,
  25.36,
  25.97,
  26.97,
  26.57,
  26.68,
  26.83,
  27.25,
  26.44,
  26.74,
  25.94,
  26.55,
  26.51,
  27.46,
  28.61,
  31.03,
  31.23,
  31.01,
  31.31,
  32.34,
  32.42,
  32.43,
  32.44,
  26.71,
  26.00,
  26.14,
  26.40,
  26.40,
  26.60,
  26.42,
  26.89,
  26.18,
  26.74,
  26.10,
  26.34,
  26.24,
  26.37,
  26.48,
  26.32,
  26.51,
  26.80,
  26.52,
  26.62,
  26.63,
  27.03,
  28.81,
  30.49,
  31.41,
  32.18,
  31.33,
  31.60,
  31.94,
  31.95,
  32.89,
  32.90,
  26.66,
  26.26,
  26.18,
  26.55,
  26.84,
  26.23,
  26.63,
  25.75,
  26.71,
  26.99,
  26.23,
  26.56,
  25.99,
  26.25,
  26.75,
  26.00,
  27.22,
  26.06,
  26.99,
  26.72,
  26.25,
  26.81,
  30.17,
  30.86,
  31.64,
  31.85,
  31.53,
  31.46,
  31.72,
  31.55,
  30.68,
  28.64,
  26.35,
  26.32,
  25.77,
  26.20,
  26.23,
  25.67,
  26.84,
  26.18,
  26.72,
  25.83,
  26.71,
  27.06,
  26.38,
  26.27,
  26.22,
  27.01,
  26.37,
  26.08,
  26.09,
  26.69,
  27.04,
  26.96,
  30.40,
  31.41,
  31.35,
  31.78,
  31.73,
  31.69,
  31.40,
  30.74,
  30.43,
  30.25,
  26.67,
  25.94,
  26.44,
  26.31,
  26.02,
  26.06,
  25.90,
  26.23,
  26.90,
  26.01,
  26.88,
  26.42,
  26.30,
  26.50,
  26.64,
  26.56,
  26.97,
  26.52,
  26.68,
  26.70,
  27.01,
  27.66,
  31.22,
  31.73,
  31.86,
  31.73,
  31.76,
  31.51,
  30.70,
  30.47,
  30.44,
  30.06,
  27.12,
  26.65,
  26.22,
  26.10,
  26.15,
  27.05,
  26.15,
  26.53,
  26.31,
  26.54,
  26.34,
  26.71,
  27.04,
  27.16,
  26.61,
  27.15,
  26.44,
  26.37,
  26.47,
  26.69,
  27.26,
  28.46,
  31.40,
  32.63,
  32.22,
  32.50,
  30.94,
  31.72,
  30.92,
  30.78,
  30.48,
  30.71,
  26.78,
  27.00,
  27.12,
  26.84,
  26.61,
  26.36,
  26.17,
  26.70,
  26.69,
  27.04,
  28.38,
  28.65,
  29.60,
  29.91,
  31.20,
  31.58,
  30.82,
  28.40,
  27.00,
  26.84,
  28.42,
  30.35,
  32.41,
  31.76,
  31.63,
  31.93,
  31.29,
  31.19,
  30.91,
  30.24,
  30.83,
  30.87,
  26.11,
  26.59,
  26.38,
  27.22,
  25.87,
  26.19,
  26.49,
  26.38,
  27.24,
  27.37,
  29.44,
  29.57,
  30.00,
  31.85,
  32.51,
  32.85,
  31.94,
  31.27,
  27.73,
  27.93,
  28.81,
  32.27,
  33.24,
  32.65,
  31.94,
  32.36,
  31.35,
  31.10,
  30.45,
  31.08,
  30.36,
  31.39,
  26.81,
  26.30,
  26.56,
  26.19,
  26.49,
  26.08,
  26.85,
  26.94,
  27.35,
  28.08,
  30.43,
  29.84,
  31.76,
  32.91,
  33.82,
  33.54,
  32.99,
  33.23,
  32.62,
  33.10,
  33.98,
  34.56,
  34.12,
  34.19,
  33.19,
  31.96,
  31.80,
  31.06,
  32.12,
  30.79,
  30.89,
  31.02,
  27.19,
  26.11,
  26.83,
  26.94,
  26.24,
  26.26,
  26.73,
  26.55,
  27.62,
  29.17,
  29.66,
  29.65,
  31.56,
  33.35,
  34.17,
  33.32,
  33.44,
  33.20,
  33.29,
  33.46,
  33.88,
  34.23,
  33.88,
  34.70,
  34.17,
  33.35,
  31.35,
  31.82,
  30.94,
  31.27,
  31.20,
  31.48,
  26.80,
  26.69,
  26.48,
  26.86,
  26.61,
  26.47,
  26.83,
  26.65,
  28.74,
  29.20,
  29.81,
  30.52,
  31.37,
  33.66,
  33.99,
  33.56,
  34.42,
  33.97,
  34.14,
  34.46,
  34.45,
  33.82,
  33.82,
  34.51,
  34.16,
  33.77,
  32.22,
  31.09,
  31.02,
  31.17,
  31.61,
  31.40,
  26.41,
  26.64,
  25.94,
  26.89,
  27.28,
  26.30,
  26.08,
  26.94,
  28.70,
  29.54,
  30.33,
  30.37,
  31.60,
  33.67,
  33.78,
  32.91,
  33.34,
  33.67,
  33.91,
  34.07,
  33.76,
  33.66,
  34.35,
  34.56,
  34.21,
  34.92,
  32.06,
  31.40,
  31.42,
  31.81,
  31.30,
  31.09,
  27.05,
  26.79,
  26.40,
  26.70,
  26.69,
  26.90,
  26.59,
  26.51,
  27.57,
  28.61,
  30.85,
  30.96,
  32.29,
  33.10,
  34.74,
  33.58,
  33.58,
  33.84,
  33.86,
  34.33,
  33.72,
  33.74,
  34.63,
  34.37,
  34.22,
  32.29,
  32.61,
  32.11,
  32.05,
  31.32,
  32.10,
  31.51,
  26.73,
  26.84,
  26.58,
  26.50,
  26.84,
  26.22,
  26.79,
  26.48,
  27.53,
  27.86,
  30.33,
  31.08,
  32.03,
  33.41,
  34.10,
  34.39,
  33.61,
  33.83,
  33.94,
  33.50,
  30.89,
  30.97,
  34.23,
  34.13,
  33.13,
  32.43,
  32.12,
  33.37,
  32.06,
  32.00,
  31.44,
  31.77,
  27.01,
  26.67,
  26.56,
  26.16,
  26.07,
  26.61,
  26.98,
  26.73,
  26.94,
  27.20,
  28.47,
  29.36,
  30.66,
  31.03,
  31.95,
  30.86,
  29.39,
  29.43,
  28.67,
  27.71,
  27.83,
  28.45,
  32.35,
  32.66,
  33.24,
  32.45,
  32.90,
  32.80,
  32.04,
  32.21,
  31.58,
  31.86,
  26.92,
  27.09,
  26.56,
  26.82,
  26.61,
  26.61,
  26.15,
  26.02,
  26.55,
  26.72,
  27.22,
  28.29,
  28.31,
  29.08,
  28.39,
  27.23,
  26.36,
  27.24,
  27.08,
  27.47,
  27.92,
  27.14,
  31.27,
  32.69,
  32.82,
  32.94,
  32.85,
  32.21,
  31.93,
  32.20,
  32.18,
  32.53,
  26.89,
  26.65,
  26.56,
  27.08,
  26.86,
  26.95,
  26.88,
  26.05,
  26.92,
  27.00,
  27.47,
  27.24,
  27.60,
  27.03,
  26.31,
  26.51,
  26.02,
  26.15,
  26.46,
  27.22,
  26.54,
  26.77,
  29.89,
  31.68,
  31.65,
  31.97,
  32.39,
  31.93,
  31.20,
  31.16,
  31.72,
  32.41,
  27.08,
  27.55,
  26.01,
  27.74,
  26.28,
  26.96,
  25.82,
  27.09,
  26.89,
  27.36,
  26.42,
  27.05,
  26.67,
  27.06,
  26.77,
  26.64,
  26.93,
  27.04,
  26.41,
  27.01,
  27.56,
  27.25,
  28.53,
  30.45,
  31.68,
  32.14,
  32.01,
  31.85,
  31.57,
  31.64,
  31.02,
  31.08,
  27.11,
  27.32,
  26.21,
  27.65,
  26.69,
  27.04,
  27.04,
  26.98,
  27.29,
  26.61,
  26.84,
  26.46,
  26.49,
  26.65,
  26.97,
  27.03,
  26.68,
  26.65,
  26.77,
  27.38,
  27.52,
  26.68,
  27.43,
  27.81,
  28.38,
  29.19,
  30.31,
  30.68,
  30.37,
  30.37,
  28.78,
  29.48,
  26.64,
  27.15,
  26.18,
  27.55,
  26.63,
  26.87,
  26.25,
  27.15,
  26.80,
  27.63,
  26.98,
  26.62,
  26.90,
  26.36,
  26.92,
  27.00,
  27.13,
  27.33,
  27.03,
  27.06,
  27.41,
  27.54,
  26.50,
  27.43,
  28.08,
  28.17,
  28.23,
  28.61,
  29.27,
  29.76,
  28.44,
  28.42,
  27.90,
  26.75,
  26.57,
  27.18,
  27.31,
  26.70,
  26.82,
  26.46,
  27.37,
  26.84,
  26.53,
  27.22,
  27.10,
  26.43,
  26.77,
  26.87,
  26.84,
  26.26,
  27.36,
  27.36,
  27.68,
  27.36,
  27.11,
  27.00,
  27.51,
  27.10,
  27.39,
  27.36,
  26.98,
  27.56,
  27.33,
  28.66,
  27.75,
  27.07,
  27.20,
  27.58,
  26.82,
  26.66,
  26.79,
  27.13,
  27.00,
  26.86,
  26.65,
  27.52,
  26.76,
  27.28,
  27.16,
  26.64,
  26.70,
  26.96,
  26.72,
  27.16,
  27.36,
  27.88,
  27.17,
  27.34,
  27.68,
  27.91,
  27.42,
  27.16,
  27.58,
  28.53,
  27.48,
  28.94
];
