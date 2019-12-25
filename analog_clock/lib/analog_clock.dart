// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            canvasColor: Color(0xFFE1F5FE),
            primaryColor: Color(0xFF4285F4),
            backgroundColor: Color(0xff02579B),
          )
        : Theme.of(context).copyWith(
            canvasColor: Color(0xFF263238),
            primaryColor: Color(0xFF1F1B24),
            backgroundColor: Color(0xff121212),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final date = DateFormat('MMMM d, yyyy').format(_now);
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: Colors.white, fontSize: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(margin: EdgeInsets.only(bottom: 10), child: Text(date)),
          Container(
              margin: EdgeInsets.only(bottom: 10),
              child: getCondition(_condition)),
          Container(
              margin: EdgeInsets.only(bottom: 0), child: Text(_temperature)),
        ],
      ),
    );

    return new Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              customTheme.primaryColor,
              customTheme.backgroundColor
            ]),
          ),
          child: new Padding(
            padding: const EdgeInsets.all(10.0),
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Expanded(
                    child: new Align(
                      alignment: FractionalOffset.center,
                      child: new AspectRatio(
                        aspectRatio: 1.0,
                        child: new Stack(
                          children: <Widget>[
                            Semantics.fromProperties(
                              properties: SemanticsProperties(
                                label: 'Analog clock with time $time',
                                value: time,
                              ),
                              child: Container(
                                child: Stack(children: [
                                  // Hour Hand Text
                                  HourHandsTextWidget(),
                                  // Hour Hand Canvas
                                  new Positioned.fill(
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 30,
                                            top: 30,
                                            right: 30,
                                            bottom: 30,
                                          ),
                                          child: DrawnHand(
                                            color: customTheme.canvasColor,
                                            thickness: 4,
                                            size: 1,
                                            angleRadians: hourToRadiant(
                                                TimeOfDay.now().hourOfPeriod,
                                                _now.minute,
                                                _now.second),
                                          ))),
                                  // Minute Hand Canvas
                                  new Positioned.fill(
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 50,
                                            top: 50,
                                            right: 50,
                                            bottom: 50,
                                          ),
                                          child: DrawnHand(
                                            color: customTheme.canvasColor,
                                            thickness: 4,
                                            size: 1,
                                            angleRadians: minuteToRadiant(
                                                _now.minute, _now.second),
                                          ))),
                                  MinuteHandsTextWidget(),
                                  // Weather Info
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: weatherInfo,
                                  ),
                                ]),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                          margin: EdgeInsets.only(bottom: 0),
                          child: Text(_location,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)))),
                ]),
          )),
    );
  }

  double hourToRadiant(int hour, int minute, int second) {
    return ((2 * math.pi) / 12) * (hour + (minute / 100) + (second / 1000));
  }

  double minuteToRadiant(int minute, int second) {
    return ((2 * math.pi) / 60) * (minute + second / 100);
  }

  double secondToRadiant(double second) {
    return ((2 * math.pi) / 60) * second;
  }

  Image getCondition(String condition) {
    double size = 40.0;

    switch (condition) {
      case "cloudy":
        {
          return new Image.asset(
            'assets/cloudy_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "foggy":
        {
          return new Image.asset(
            'assets/foggy_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "rainy":
        {
          return new Image.asset(
            'assets/rainy_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "snowy":
        {
          return new Image.asset(
            'assets/snow_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "sunny":
        {
          return new Image.asset(
            'assets/sunny_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "thunderstorm":
        {
          return new Image.asset(
            'assets/thunderstorm_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      case "windy":
        {
          return new Image.asset(
            'assets/breezy_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
        break;
      default:
        {
          return new Image.asset(
            'assets/default_free_alexey_onufriev@2x.png',
            width: size,
            height: size,
          );
        }
    }
  }
}

class HourHandsTextWidget extends StatelessWidget {
  const HourHandsTextWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      Align(
        alignment: Alignment.topCenter,
        child: new ClockHandWidget("12"),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: new ClockHandWidget("3"),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: new ClockHandWidget("9"),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: new ClockHandWidget("6"),
      )
    ]);
  }
}

class MinuteHandsTextWidget extends StatelessWidget {
  const MinuteHandsTextWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          left: 65,
          top: 60,
          right: 65,
          bottom: 60,
        ),
        child: new Stack(children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: new ClockHandWidget("0"),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: new ClockHandWidget("15"),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: new ClockHandWidget("45"),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: new ClockHandWidget("30"),
          ),
        ]));
  }
}

class ClockHandWidget extends StatelessWidget {
  final String text;

  const ClockHandWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10));
  }
}