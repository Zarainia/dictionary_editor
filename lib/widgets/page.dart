import 'package:flutter/material.dart';

import 'package:measured_size/measured_size.dart';

import 'appbar.dart';

class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({required this.child});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double appbar_height = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MeasuredSize(
          child: const AppBarWidgets(),
          onChange: (size) {
            setState(() {
              appbar_height = size.height;
            });
          },
        ),
        toolbarHeight: appbar_height,
      ),
      body: widget.child,
    );
  }
}

class DialogPage extends StatelessWidget {
  final Widget child;
  final AppBar? appbar;

  const DialogPage({required this.child, this.appbar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar ?? AppBar(),
      body: Padding(child: child, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)),
    );
  }
}
