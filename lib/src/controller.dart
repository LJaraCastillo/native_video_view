part of native_video_view;

/// Controller used to call the functions that
/// controls the [VideoView] in Android and the [AVPlayer] in iOS.
class VideoViewController {
  /// MethodChannel to call methods from the platform.
  final MethodChannel channel;

  /// State of the [StatefulWidget].
  final _NativeVideoViewState _videoViewState;

  /// Current video file loaded in the player.
  /// The [info] attribute is loaded when the player reaches
  /// the prepared state.
  VideoFile _videoFile;

  /// Returns the video file loaded in the player.
  /// The [info] attribute is loaded when the player reaches
  /// the prepared state.
  VideoFile get videoFile => _videoFile;

  /// Timer to control the progression of the video being played.
  Timer _progressionController;

  /// Constructor of the class.
  VideoViewController._(
    this.channel,
    this._videoViewState,
  ) : assert(channel != null) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Initialize the controller.
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

  /// Handle the calls from the listeners of state of the player.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'player#onCompletion':
        _stopProgressTimer();
        _videoViewState.notifyControlChanged(_MediaControl.stop);
        _videoViewState.onCompletion(this);
        break;
      case 'player#onError':
        _videoFile = null;
        int what = call.arguments['what'] ?? -1;
        int extra = call.arguments['extra'] ?? -1;
        String message = call.arguments['message'];
        _videoViewState.onError(this, what, extra, message);
        break;
      case 'player#onPrepared':
        VideoInfo videoInfo = VideoInfo._fromJson(call.arguments);
        _videoFile =
            _videoFile._copyWith(changes: VideoFile._(info: videoInfo));
        _videoViewState.onPrepared(this, videoInfo);
        break;
    }
  }

  /// Sets the video source from an asset file.
  /// The [sourceType] parameter could be [VideoSourceType.asset],
  /// [VideoSourceType.file] or [VideoSourceType.network]
  Future<void> setVideoSource(
    String source, {
    VideoSourceType sourceType = VideoSourceType.file,
  }) async {
    assert(source != null);
    if (sourceType == VideoSourceType.asset) {
      File file = await _getAssetFile(source);
      await _setVideosSource(file.path, sourceType);
    } else {
      await _setVideosSource(source, sourceType);
    }
  }

  /// Load an asset file as a temporary file. File is removed when the
  /// VideoView is disposed.
  /// Returns the file path of the temporary file.
  Future<File> _getAssetFile(String asset) async {
    Directory directory = await getApplicationDocumentsDirectory();
    var tempFile = File("${directory.path}/temp.mp4");
    ByteData data = await rootBundle.load(asset);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    if (!tempFile.existsSync()) tempFile.createSync(recursive: true);
    return tempFile.writeAsBytes(bytes);
  }

  /// Remove the temporary file used for playing assets.
  /// Returns true if the file was removed or file if not.
  Future<bool> _cleanTempFile() async {
    Directory directory = await getApplicationDocumentsDirectory();
    var tempFile = File("${directory.path}/temp.mp4");
    if (tempFile.existsSync()) {
      try {
        tempFile.deleteSync();
        return true;
      } catch (ex) {
        print(ex);
      }
    }
    return false;
  }

  /// Sets the video source from a file in the device memory.
  Future<void> _setVideosSource(
      String videoSource, VideoSourceType sourceType) async {
    assert(videoSource != null);
    Map<String, dynamic> args = {
      "videoSource": videoSource,
      "sourceType": sourceType.toString(),
    };
    try {
      await channel.invokeMethod<void>("player#setVideoSource", args);
      _videoFile = VideoFile._(source: videoSource, sourceType: sourceType);
    } catch (ex) {
      print(ex);
    }
  }

  /// Starts/resumes the playback of the video.
  Future<bool> play() async {
    try {
      await channel.invokeMethod("player#start");
      _startProgressTimer();
      _videoViewState.notifyControlChanged(_MediaControl.play);
      return true;
    } catch (ex) {
      print(ex);
    }
    return false;
  }

  /// Pauses the playback of the video. Use
  /// [play] to resume the playback at any time.
  Future<bool> pause() async {
    try {
      await channel.invokeMethod("player#pause");
      _stopProgressTimer();
      _videoViewState.notifyControlChanged(_MediaControl.pause);
      return true;
    } catch (ex) {
      print(ex);
    }
    return false;
  }

  /// Stops the playback of the video.
  Future<bool> stop() async {
    try {
      await channel.invokeMethod("player#stop");
      _stopProgressTimer();
      _onProgressChanged(null);
      _videoViewState.notifyControlChanged(_MediaControl.stop);
      return true;
    } catch (ex) {
      print(ex);
    }
    return false;
  }

  /// Gets the current position of time in seconds.
  /// Returns the current position of playback in milliseconds.
  Future<int> currentPosition() async {
    final result = await channel.invokeMethod("player#currentPosition");
    return result['currentPosition'] ?? 0;
  }

  /// Moves the cursor of the playback to an specific time.
  /// Must give the [position] of the specific millisecond of playback, if
  /// the [position] is bigger than the duration of source the duration
  /// of the video is used as position.
  Future<bool> seekTo(int position) async {
    assert(position != null);
    try {
      Map<String, dynamic> args = {"position": position};
      await channel.invokeMethod<void>("player#seekTo", args);
      return true;
    } catch (ex) {
      print(ex);
    }
    return false;
  }

  /// Gets the state of the player.
  /// Returns true if the player is playing or false if is stopped or paused.
  Future<bool> isPlaying() async {
    final result = await channel.invokeMethod("player#isPlaying");
    return result['isPlaying'];
  }

  /// Starts the timer that monitor the time progression of the playback.
  void _startProgressTimer() {
    if (_progressionController == null) {
      _progressionController =
          Timer.periodic(Duration(milliseconds: 100), _onProgressChanged);
    }
  }

  /// Stops the progression timer. If [resetCount] is true the elapsed
  /// time is restarted.
  void _stopProgressTimer() {
    if (_progressionController != null) {
      _progressionController.cancel();
      _progressionController = null;
    }
  }

  /// Callback called by the timer when an event is called.
  /// Updates the elapsed time counter and notifies the widget
  /// state.
  void _onProgressChanged(Timer timer) async {
    int position = await currentPosition();
    int duration = this.videoFile?.info?.duration ?? 1000;
    _videoViewState.onProgress(position, duration);
  }
}
