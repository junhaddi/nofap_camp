import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nofapcamp/models/classes.dart';
import 'package:nofapcamp/widgets/custom_dialog.dart';
import 'package:nofapcamp/widgets/numberpicker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class StatusPage extends StatefulWidget {
  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  SharedPreferences _prefs;
  DateTime _initDate;
  DateTime _srcDate;
  DateTime _dstDate;
  int _progressDay;
  int _dday;
  bool _isLoaded = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _getDate();
  }

  Widget build(BuildContext context) {
    if (_isLoaded) {
      _updateDate();
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularPercentIndicator(
            radius: 280.0,
            lineWidth: 20.0,
            arcType: ArcType.FULL,
            arcBackgroundColor: Color(0xFFB8C7CB),
            progressColor: Colors.deepPurpleAccent,
            backgroundColor: Colors.transparent,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animateFromLastPercent: true,
            percent: _isLoaded
                ? max(
                    0.001,
                    min(
                        DateTime.now().difference(_srcDate).inMilliseconds /
                            _dstDate.difference(_srcDate).inMilliseconds,
                        1.0),
                  )
                : 0.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _isLoaded
                    ? Column(
                        children: <Widget>[
                          Text(
                            '$_progressDay일차',
                            style: TextStyle(
                              fontSize: 42.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_initDate.year}/${_initDate.month}/${_initDate.day}~',
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Text(
                            'D${_dday < 0 ? '+' : '-'}${_dday == 0 ? 'DAY' : _dday.abs()}',
                            style: TextStyle(
                              fontSize: 24.0,
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          FadeInImage(
                            height: 40.0,
                            placeholder: MemoryImage(kTransparentImage),
                            image: getClassesImage(_progressDay),
                          ),
                        ],
                      )
                    : Text(
                        '시작하세요',
                        style: TextStyle(
                          fontSize: 42.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
            footer: RaisedButton(
              shape: CircleBorder(),
              color: Colors.deepPurpleAccent,
              padding: EdgeInsets.all(4.0),
              child: Icon(
                _isLoaded
                    ? _isSuccess ? Icons.check : Icons.priority_high
                    : Icons.play_arrow,
                size: 48.0,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              onPressed: () {
                if (_isLoaded) {
                  _updateDate();
                  if (_isSuccess) {
                    _showResetDialog(true);
                  } else {
                    _showReconfirmDialog();
                  }
                } else {
                  _showLoadDialog();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getDate() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      DateTime now = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      _initDate = DateTime.fromMillisecondsSinceEpoch(
          _prefs.getInt('initDate') ?? now.millisecondsSinceEpoch);
      _srcDate = DateTime.fromMillisecondsSinceEpoch(
          _prefs.getInt('srcDate') ?? now.millisecondsSinceEpoch);
      _dstDate = DateTime.fromMillisecondsSinceEpoch(
          _prefs.getInt('dstDate') ?? now.millisecondsSinceEpoch);
      _progressDay = now
              .difference(
                  DateTime(_initDate.year, _initDate.month, _initDate.day))
              .inDays +
          1;
      _dday = DateTime(_dstDate.year, _dstDate.month, _dstDate.day)
          .difference(now)
          .inDays;
      _isLoaded = _initDate != now && _srcDate != now && _dstDate != now;
      _isSuccess = DateTime.now().difference(_dstDate).inMilliseconds >= 0;
    });
  }

  void _updateDate() {
    setState(() {
      DateTime now = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      _progressDay = now
              .difference(
                  DateTime(_initDate.year, _initDate.month, _initDate.day))
              .inDays +
          1;
      _dday = DateTime(_dstDate.year, _dstDate.month, _dstDate.day)
          .difference(now)
          .inDays;
      _isSuccess = DateTime.now().difference(_dstDate).inMilliseconds >= 0;
    });
  }

  Future<void> _showLoadDialog() async {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return NumberPickerDialog.integer(
          initialIntegerValue: 0,
          minValue: 0,
          maxValue: 400,
          title: Text(
            '금딸을 며칠이나\n하고있나요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    ).then((int value) {
      if (value != null) {
        setState(() {
          _initDate = DateTime.now().subtract(Duration(days: value));
          _showResetDialog(true);
        });
      }
    });
  }

  Future<void> _showReconfirmDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: '금딸실패',
          subtitle: '정말이에요?',
          child: Image(
            height: 200.0,
            image: [
              AssetImage('assets/images/reconfirm/reconfirm_1.gif'),
              AssetImage('assets/images/reconfirm/reconfirm_2.gif'),
              AssetImage('assets/images/reconfirm/reconfirm_3.gif'),
            ][Random().nextInt(3)],
            fit: BoxFit.cover,
          ),
          event: () {
            Navigator.of(context).pop();
            _showResetDialog(false);
          },
        );
      },
    );
  }

  Future<void> _showResetDialog(bool isSuccess) async {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return NumberPickerDialog.integer(
          initialIntegerValue: 1,
          minValue: 1,
          maxValue: 100,
          infiniteLoop: true,
          title: Text(
            '목표일수',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    ).then((int value) {
      if (value != null) {
        setState(() {
          if (isSuccess) {
            // 목표 달성 성공
            _srcDate = DateTime.now();
            _dstDate = DateTime.now().add(Duration(days: value));
          } else {
            // 목표 달성 실패
            if (_isLoaded) {
              // 기록 저장
              List<String> dateHistorys =
                  _prefs.getStringList('dateHistorys') ?? [];
              dateHistorys.add(
                jsonEncode({
                  'progressDay': _progressDay,
                  'srcDate':
                      DateTime(_initDate.year, _initDate.month, _initDate.day)
                          .millisecondsSinceEpoch,
                  'dstDate': DateTime(DateTime.now().year, DateTime.now().month,
                          DateTime.now().day)
                      .millisecondsSinceEpoch,
                }),
              );
              _prefs.setStringList('dateHistorys', dateHistorys);
            }
            _initDate = DateTime.now();
            _srcDate = DateTime.now();
            _dstDate = _srcDate.add(Duration(days: value));
          }
          _isLoaded = true;

          // 현황 저장
          _prefs.setInt('initDate', _initDate.millisecondsSinceEpoch);
          _prefs.setInt('srcDate', _srcDate.millisecondsSinceEpoch);
          _prefs.setInt('dstDate', _dstDate.millisecondsSinceEpoch);
          _prefs.setInt('progressDay', _progressDay);
        });
      }
    });
  }
}
