import 'dart:async';

import 'package:flutter/services.dart';

class NativeVideoView {
  static const MethodChannel _channel =
      const MethodChannel('native_video_view');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
