import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temperature_app/main.dart';

postRemote(UserDaily daily) async {
  await Dio().post('http://47.100.236.6:3305/api/user/daily', data: daily.toSimpleJson());
}

saveLocal(SharedPreferences pref, UserDaily daily) async {
  List<UserDaily> data = readLocal(pref);
  data.add(daily);
  await pref.setStringList('data', data.map((e) => json.encode(e)).toList());
}

List<UserDaily> readLocal(SharedPreferences pref) {
  List<String> data = pref.getStringList('data');
  if (data == null) return List<UserDaily>();
  return data.map((e) => UserDaily.fromJson(json.decode(e))).toList();
}

class UserDaily {
  String name;
  String address;
  String date;
  bool normal;
  String min;
  String max;
  String avg;
  String center;
  List<String> data;


  UserDaily(this.name, this.address, this.date, this.normal, this.min, this.max,
      this.avg, this.center, this.data);

  UserDaily.fromData(this.normal, this.min, this.max, this.avg, this.center,
      List<double> raw) {
    data = raw.map((e) => e.toStringAsFixed(2)).toList();
    name = TempApp.name;
    address = TempApp.address;
    var now = DateTime.now();
    var m = now.month.toString();
    var d = now.day.toString();
    date =
        "${now.year}-${m.length == 1 ? '0' + m : m}-${d.length == 1 ? '0' + d : d}";
  }

  UserDaily.fromJson(Map<String, dynamic> map)
      : name = map['name'],
        address = map['address'],
        date = map['date'],
        normal = map['normal'],
        min = map['min'],
        max = map['max'],
        avg = map['avg'],
        center = map['center'],
        data = (map['data'] as List<dynamic>).map((e) => e.toString()).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'date': date,
        'normal': normal,
        'min': min,
        'max': max,
        'avg': avg,
        'center': center,
        'data': data
      };

  Map<String, dynamic> toSimpleJson() => {
        'name': name,
        'address': address,
        'date': date,
        'normal': normal,
        'min': min,
        'max': max,
        'avg': avg,
        'center': center
      };
}
