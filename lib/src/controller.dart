part of native_video_view;

class VideoViewController {
  final MethodChannel channel;

  final _NativeVideoViewState _videoViewState;

  VideoViewController._(
    this.channel,
    this._videoViewState,
  ) : assert(channel != null) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<VideoViewController> init(
    int id,
    _NativeVideoViewState videoViewState,
  ) async {
    assert(id != null);
    final MethodChannel channel = MethodChannel('native_video_view_$id');
    return VideoViewController._(
      channel,
      videoViewState,
    );
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'player#onCompletion':
        if (_videoViewState.widget.onCompletion != null) {
          _videoViewState.widget.onCompletion(this);
        }
        break;
      case 'player#onError':
        if (_videoViewState.widget.onError != null) {
          int what = call.arguments['what'] ?? -1;
          int extra = call.arguments['extra'] ?? -1;
          _videoViewState.widget.onError(this, what, extra);
        }
        break;
      case 'player#onPrepared':
        if (_videoViewState.widget.onPrepared != null) {
          _videoViewState.widget.onPrepared(this);
        }
        break;
    }
  }

  Future<void> setVideoFromAsset(String videoAsset) async {
    assert(videoAsset != null);
    File file = await _getAssetFile(videoAsset);
    await setVideoFromFile(file.path);
  }

  Future<File> _getAssetFile(String asset) async {
    Directory directory = await getApplicationDocumentsDirectory();
    var tempFile = File("${directory.path}/temp.mp4");
    ByteData data = await rootBundle.load(asset);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    if (!tempFile.existsSync()) tempFile.createSync(recursive: true);
    return tempFile.writeAsBytes(bytes);
  }

  Future<void> setVideoFromFile(String videoPath) async {
    assert(videoPath != null);
    Map<String, dynamic> args = {"videoPath": videoPath};
    await channel.invokeMethod<void>("player#setVideoFromFile", args);
  }

  Future<void> setNetworkVideo(String videoUri) async {
    assert(videoUri != null);
    Map<String, dynamic> args = {"videoUri": videoUri};
    await channel.invokeMethod<void>("player#setNetworkVideo", args);
  }

  Future<void> play() async {
    await channel.invokeMethod("player#start");
  }

  Future<void> resume() async {
    await channel.invokeMethod("player#resume");
  }

  Future<void> pause() async {
    await channel.invokeMethod("player#pause");
  }

  Future<void> stop() async {
    await channel.invokeMethod("player#stop");
  }

  Future<int> currentPosition() async {
    final result = await channel.invokeMethod("player#currentPosition");
    return result['currentPosition'] ?? -1;
  }

  Future<void> seekTo(int position) async {
    assert(position != null);
    Map<String, dynamic> args = {"position": position};
    await channel.invokeMethod<void>("player#seekTo", args);
  }
}
