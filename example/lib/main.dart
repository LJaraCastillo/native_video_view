import 'package:flutter/material.dart';
import 'package:native_video_view/native_video_view.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
	      enableVolumeControl: true,
        onCreated: (controller) {
          controller.setVideoSource(
            'assets/example.mp4',
            sourceType: VideoSourceType.asset,
            requestAudioFocus: true,
          );
        },
        onPrepared: (controller, info) {
          debugPrint('NativeVideoView: Video prepared');
          controller.play();
        },
        onError: (controller, what, extra, message) {
          debugPrint('NativeVideoView: Player Error ($what | $extra | $message)');
        },
        onCompletion: (controller) {
          debugPrint('NativeVideoView: Video completed');
        },
      ),
    );
  }
}
