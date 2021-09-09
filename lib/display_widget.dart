import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:temperature_app/info_dialog.dart';
import 'package:temperature_app/main.dart';
import 'package:temperature_app/persistent.dart';
import 'package:temperature_app/temp_notifier.dart';

class DisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var list = readLocal(TempApp.pref);
    var notifier = Provider.of<TempNotifier>(context, listen: false);
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        var abnormal = double.parse(list[index].max) > 37.2;
        return DefaultTextStyle(
          style: TextStyle(fontSize: 13, color: Colors.black),
          child: GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => DisplayDialog(
                      notifier.refactor(list[index]
                          .data
                          .map((e) => double.parse(e))
                          .toList()),
                      notifier.colorMaker));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              height: 115,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[200]),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(list[index].date,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        abnormal
                            ? Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 25)
                            : Container(),
                        abnormal
                            ? Text("异常！",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red))
                            : Container(),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(children: [
                      SizedBox(
                        width: 120,
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '姓名: ',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          TextSpan(
                              text: list[index].name,
                              style: TextStyle(fontSize: 14)),
                        ])),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '地址: ',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          TextSpan(
                              text: list[index].address,
                              style: TextStyle(fontSize: 14)),
                        ])),
                      ),
                    ]),
                    SizedBox(height: 5),
                    Row(children: [
                      SizedBox(
                          width: 120, child: Text('最高温度: ${list[index].max}')),
                      SizedBox(
                          width: 120, child: Text('最低温度: ${list[index].min}')),
                    ]),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        SizedBox(
                            width: 120,
                            child: Text('平均温度: ${list[index].avg}')),
                        SizedBox(
                            width: 120,
                            child: Text('中心温度: ${list[index].center}')),
                      ],
                    )
                  ]),
            ),
          ),
        );
      },
    );
  }
}
