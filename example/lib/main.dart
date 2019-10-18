import 'package:flutter/material.dart';
import 'package:native_video_view/native_video_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: NativeVideoView(
            onCreated: (controller) {
              controller
                  .setVideoFromAsset('assets/example.mp4');
            },
            onPrepared: (controller) {
              controller.play();
            },
            onError: (controller, what, extra) {
              print('Player Error ($what | $extra)');
            },
            onCompletion: (controller) {
              print('Video completed');
            },
          ),
        ),
      ),
    );
  }
}
