import 'package:flutter/material.dart';
import 'package:native_video_view/native_video_view.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  VideoViewController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: _buildVideoPlayerWidget(),
    );
  }

  Widget _buildVideoPlayerWidget() {
    return Container(
      child: NativeVideoView(
        showMediaController: true,
        onCreated: (controller) {
          controller.setVideoFromAsset('assets/example.mp4');
          _controller = controller;
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
    );
  }

  Widget _buildControlsWidget() {
    return Container(
      child: Row(
        children: <Widget>[],
      ),
    );
  }
}
