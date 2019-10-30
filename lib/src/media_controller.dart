part of native_video_view;

typedef ControlPressedCallback = void Function(MediaControl control);

typedef PositionChangedCallback = void Function(int position, int duration);

typedef MediaDurationCallback = void Function(int duration);

class MediaController extends StatefulWidget {
  final Widget child;
  final MediaControlsController controller;
  final ControlPressedCallback onControlPressed;
  final PositionChangedCallback onPositionChanged;

  const MediaController({
    Key key,
    @required this.child,
    this.controller,
    this.onControlPressed,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  _MediaControllerState createState() => _MediaControllerState();
}

class _MediaControllerState extends State<MediaController> {
  bool _visible = true;
  bool _playing = false;
  double _progress = 0;
  double _duration = 1000;

  @override
  void initState() {
    super.initState();
    _initMediaController();
  }

  @override
  void dispose() {
    _disposeMediaController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            child: widget.child,
            onTap: _toggleController,
          ),
          _buildMediaController(),
        ],
      ),
    );
  }

  Widget _buildMediaController() {
    Widget child;
    if (_visible) {
      child = _buildControls();
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(child: child, opacity: animation);
        },
        child: child ?? Container(),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildControlButton(
                iconData: Icons.fast_rewind,
                onPressed: _rewind,
              ),
              _buildControlButton(
                iconData: _playing ? Icons.pause : Icons.play_arrow,
                onPressed: _playPause,
              ),
              _buildControlButton(
                iconData: Icons.stop,
                onPressed: _stop,
              ),
              _buildControlButton(
                iconData: Icons.fast_forward,
                onPressed: _forward,
              ),
            ],
          ),
          _buildProgressionBar(),
        ],
      ),
    );
  }

  Widget _buildProgressionBar() {
    return Slider(
      onChanged: _onSliderPositionChanged,
      value: _progress,
      min: 0,
      max: _duration,
    );
  }

  Widget _buildControlButton({IconData iconData, Function onPressed}) {
    return IconButton(
      icon: Icon(iconData, color: Colors.white),
      onPressed: onPressed,
    );
  }

  void _initMediaController() {
    if (widget.controller != null) {
      widget.controller.addControlPressedListener(_onControlPressed);
      widget.controller.addPositionChangedListener(_onPositionChanged);
    }
  }

  void _disposeMediaController() {
    if (widget.controller != null) {
      widget.controller.clearControlPressedListener();
      widget.controller.clearPositionChangedListener();
    }
  }

  void _onControlPressed(MediaControl mediaControl) {
    switch (mediaControl) {
      case MediaControl.pause:
        setState(() {
          _playing = false;
        });
        break;
      case MediaControl.play:
        setState(() {
          _playing = true;
        });
        break;
      case MediaControl.stop:
        setState(() {
          _playing = false;
        });
        break;
      default:
        break;
    }
  }

  void _onPositionChanged(int position, int duration) {
    setState(() {
      _progress = position.toDouble();
      _duration = duration.toDouble();
    });
  }

  void _onSliderPositionChanged(double position) {
    if (widget.onPositionChanged != null)
      widget.onPositionChanged(position.toInt(), _duration.toInt());
  }

  void _rewind() {
    if (widget.onControlPressed != null)
      widget.onControlPressed(MediaControl.rwd);
  }

  void _playPause() async {
    if (widget.onControlPressed != null)
      widget
          .onControlPressed(_playing ? MediaControl.pause : MediaControl.play);
  }

  void _stop() async {
    if (widget.onControlPressed != null)
      widget.onControlPressed(MediaControl.stop);
  }

  void _forward() {
    if (widget.onControlPressed != null)
      widget.onControlPressed(MediaControl.fwd);
  }

  void _toggleController() {
    setState(() {
      _visible = !_visible;
    });
  }
}

class MediaControlsController {
  ControlPressedCallback _controlPressedCallback;
  PositionChangedCallback _positionChangedCallback;

  void addControlPressedListener(
      ControlPressedCallback controlPressedCallback) {
    _controlPressedCallback = controlPressedCallback;
  }

  void clearControlPressedListener() {
    _controlPressedCallback = null;
  }

  void notifyControlPressed(MediaControl mediaControl) {
    if (_controlPressedCallback != null) _controlPressedCallback(mediaControl);
  }

  void addPositionChangedListener(
      PositionChangedCallback positionChangedCallback) {
    _positionChangedCallback = positionChangedCallback;
  }

  void clearPositionChangedListener() {
    _positionChangedCallback = null;
  }

  void notifyPositionChanged(int position, int duration) {
    if (_positionChangedCallback != null)
      _positionChangedCallback(position, duration);
  }
}
