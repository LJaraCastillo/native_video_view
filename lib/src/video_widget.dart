part of native_video_view;

/// Callback that is called when the view is created and ready.
typedef ViewCreatedCallback = void Function(VideoViewController controller);

/// Callback that is called when the playback of a video is completed.
typedef CompletionCallback = void Function(VideoViewController controller);

/// Callback that is called when the player had an error trying to load/play
/// the video source.
typedef ErrorCallback = void Function(
    VideoViewController controller, int what, int extra);

/// Callback that is called when the player finished loading the video
/// source and is prepared to start the playback. The [controller]
/// and [videoInfo] is given as parameters when the function is called.
/// The [videoInfo] parameter contains info related to the file loaded.
typedef PreparedCallback = void Function(
    VideoViewController controller, VideoInfo videoInfo);

/// Callback that indicates the progression of the media being played.
typedef ProgressionCallback = void Function(int elapsedTime, int duration);

/// Widget that displays a video player.
/// This widget calls an underlying player in the
/// respective platform, [VideoView] in Android and
/// [AVPlayer] in iOS.
class NativeVideoView extends StatefulWidget {
  /// Wraps the [PlatformView] in an [AspectRatio]
  /// to resize the widget once the video is loaded.
  final bool keepAspectRatio;

  /// Shows a default media controller to control the player state.
  final bool showMediaController;

  /// Instance of [ViewCreatedCallback] to notify
  /// when the view is finished creating.
  final ViewCreatedCallback onCreated;

  /// Instance of [CompletionCallback] to notify
  /// when a video has finished playing.
  final CompletionCallback onCompletion;

  /// Instance of [ErrorCallback] to notify
  /// when the player had an error loading the video source.
  final ErrorCallback onError;

  /// Instance of [ProgressionCallback] to notify
  /// when the time progresses while playing.
  final ProgressionCallback onProgress;

  /// Instance of [PreparedCallback] to notify
  /// when the player is ready to start the playback of a video.
  final PreparedCallback onPrepared;

  /// Constructor of the widget.
  const NativeVideoView(
      {Key key,
      this.keepAspectRatio = false,
      this.showMediaController = false,
      this.onCreated,
      this.onCompletion,
      this.onError,
      this.onProgress,
      this.onPrepared})
      : super(key: key);

  @override
  _NativeVideoViewState createState() => _NativeVideoViewState();
}

/// State of the video widget.
class _NativeVideoViewState extends State<NativeVideoView> {
  /// Completer that is finished when [onPlatformViewCreated]
  /// is called and the controller created.
  final Completer<VideoViewController> _controller =
      Completer<VideoViewController>();

  /// Value of the aspect ratio. Changes depending of the
  /// loaded file.
  double _aspectRatio = 4 / 3;

  /// Controller of the MediaController widget. This is used
  /// to update the.
  MediaControlsController _mediaController;

  @override
  void initState() {
    super.initState();
    _mediaController = MediaControlsController();
  }

  /// Disposes the state and remove the temp files created
  /// by the Widget.
  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  /// Builds the view based on the platform that runs the app.
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _buildVideoView(
          child: AndroidView(
        viewType: 'native_video_view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildVideoView(
        child: UiKitView(
          viewType: 'native_video_view',
          onPlatformViewCreated: onPlatformViewCreated,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }
    return Text('$defaultTargetPlatform is not yet supported by this plugin.');
  }

  /// Builds the video view depending of the configuration.
  Widget _buildVideoView({Widget child}) {
    Widget videoView = widget.keepAspectRatio
        ? AspectRatio(
            child: child,
            aspectRatio: _aspectRatio,
          )
        : child;
    return widget.showMediaController
        ? MediaController(
            child: videoView,
            controller: _mediaController,
            onControlPressed: _onControlPressed,
            onPositionChanged: _onPositionChanged,
          )
        : videoView;
  }

  /// Callback that is called when the view is created in the platform.
  Future<void> onPlatformViewCreated(int id) async {
    final VideoViewController controller =
        await VideoViewController.init(id, this);
    _controller.complete(controller);
    if (widget.onCreated != null) widget.onCreated(controller);
  }

  /// Disposes the controller of the player.
  void _disposeController() async {
    final controller = await _controller.future;
    if (controller != null) controller._cleanTempFile();
  }

  /// Function that is called when the platform notifies that the video has
  /// finished playing.
  /// This function calls the widget's [CompletionCallback] instance.
  void onCompletion(VideoViewController controller) {
    if (widget.onCompletion != null) widget.onCompletion(controller);
  }

  /// Notifies when an action of the player (play, pause & stop) must be
  /// reflected by the media controller view.
  void notifyControlChanged(MediaControl mediaControl) {
    if (_mediaController != null)
      _mediaController.notifyControlPressed(mediaControl);
  }

  /// Notifies the player position to the media controller view.
  void notifyPlayerPosition(int position, int duration) {
    if (_mediaController != null)
      _mediaController.notifyPositionChanged(position, duration);
  }

  /// Function that is called when the platform notifies that an error has
  /// occurred during the video source loading.
  /// This function calls the widget's [ErrorCallback] instance.
  void onError(VideoViewController controller, int what, int extra) {
    if (widget.onError != null) widget.onError(controller, what, extra);
  }

  /// Function that is called when the platform notifies that the video
  /// source has been loaded and is ready to start playing.
  /// This function calls the widget's [PreparedCallback] instance.
  void onPrepared(VideoViewController controller, VideoInfo videoInfo) {
    if (widget.onPrepared != null && videoInfo != null) {
      setState(() {
        _aspectRatio = videoInfo.aspectRatio;
      });
      widget.onPrepared(controller, videoInfo);
      notifyPlayerPosition(0, videoInfo.duration);
    }
  }

  /// Function that is called when the player updates the time played.
  void onProgress(int position, int duration) {
    if (widget.onProgress != null) widget.onProgress(position, duration);
    notifyPlayerPosition(position, duration);
  }

  /// When a control is pressed in the media controller, the actions are
  /// realized by the [VideoViewController] and then the result is returned
  /// to the media controller to update the view.
  void _onControlPressed(MediaControl mediaControl) async {
    VideoViewController controller = await _controller.future;
    if (controller != null) {
      switch (mediaControl) {
        case MediaControl.pause:
          controller.pause();
          break;
        case MediaControl.play:
          controller.play();
          break;
        case MediaControl.stop:
          controller.stop();
          break;
        case MediaControl.fwd:
          int duration = controller.videoFile?.info?.duration;
          int position = await controller.currentPosition();
          if (duration != null && position != -1) {
            int newPosition =
                position + 3000 > duration ? duration : position + 3000;
            controller.seekTo(newPosition);
          }
          break;
        case MediaControl.rwd:
          int position = await controller.currentPosition();
          if (position != -1) {
            int newPosition = position - 3000 < 0 ? 0 : position - 3000;
            controller.seekTo(newPosition);
          }
          break;
      }
    }
  }

  /// When the position is changed in the media controller, the action is
  /// realized by the [VideoViewController] to change the position of
  /// the video playback.
  void _onPositionChanged(int position, int duration) async {
    VideoViewController controller = await _controller.future;
    if (controller != null) controller.seekTo(position);
  }
}
