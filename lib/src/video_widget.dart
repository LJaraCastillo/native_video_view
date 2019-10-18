part of native_video_view;

typedef ViewCreatedCallback = void Function(VideoViewController controller);
typedef CompletionCallback = void Function(VideoViewController controller);
typedef ErrorCallback = void Function(
    VideoViewController controller, int what, int extra);
typedef PreparedCallback = void Function(VideoViewController controller);

class NativeVideoView extends StatefulWidget {
  final ViewCreatedCallback onCreated;
  final CompletionCallback onCompletion;
  final ErrorCallback onError;
  final PreparedCallback onPrepared;

  const NativeVideoView(
      {Key key,
      this.onCreated,
      this.onCompletion,
      this.onError,
      this.onPrepared})
      : super(key: key);

  @override
  _NativeVideoViewState createState() => _NativeVideoViewState();
}

class _NativeVideoViewState extends State<NativeVideoView> {
  final Completer<VideoViewController> _controller =
      Completer<VideoViewController>();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'native_video_view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'native_video_view',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the video plugin.');
  }

  Future<void> onPlatformViewCreated(int id) async {
    final VideoViewController controller = await VideoViewController.init(
      id,
      this,
    );
    _controller.complete(controller);
    if (widget.onCreated != null) {
      widget.onCreated(controller);
    }
  }

  void onCompletion(VideoViewController controller) {
    widget.onCompletion(controller);
  }

  void onError(VideoViewController controller, int what, int extra) {
    widget.onError(controller, what, extra);
  }

  void onPrepared(VideoViewController controller) {
    widget.onPrepared(controller);
  }
}
