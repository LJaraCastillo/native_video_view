import 'package:flutter/material.dart';
import 'package:native_video_view/native_video_view.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
      alignment: Alignment.center,
      child: NativeVideoView(
        keepAspectRatio: true,
        showMediaController: true,
        onCreated: (controller) {
          controller.setVideoSource(
            '/storage/emulated/0/example.mp4',
            sourceType: VideoSourceType.file,
          );
        },
        onPrepared: (controller, info) {
          controller.play();
        },
        onError: (controller, what, extra, message) {
          print('Player Error ($what | $extra | $message)');
        },
        onCompletion: (controller) {
          print('Video completed');
        },
      ),
    );
  }
}
