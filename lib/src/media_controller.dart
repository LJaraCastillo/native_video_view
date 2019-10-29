part of native_video_view;

typedef ControlPressedCallback = Future<bool> Function(MediaControl control);

typedef PositionChangedCallback = bool Function(int position);

typedef MediaDurationCallback = bool Function(int duration);

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
  bool _visible = false;
  bool _playing = false;
  double _progress = 0;
  double _duration = 1;

  @override
  void initState() {
    super.initState();
    _initMediaController();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        child: Stack(
          children: <Widget>[
            widget.child,
            _buildMediaController(),
          ],
        ),
      ),
      onTap: _toggleController,
    );
  }

  Widget _buildMediaController() {
    Widget child;
    if (_visible) {
      child = _buildControls();
    }
    return Positioned(
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
      icon: Icon(iconData),
      onPressed: onPressed,
    );
  }

  void _initMediaController() {
    if (widget.controller != null) {
      widget.controller.addPositionChangedListener(_onPositionChanged);
      widget.controller.addMediaDurationListener(_onDurationChanged);
    }
  }

  void _onPositionChanged(int position) {
    setState(() {
      _progress = position.toDouble();
    });
  }

  void _onDurationChanged(int duration) {
    setState(() {
      _duration = duration.toDouble();
    });
  }

  void _onSliderPositionChanged(double position) {
    if (widget.onPositionChanged != null)
      widget.onPositionChanged(position.toInt());
  }

  void _rewind() {
    if (widget.onControlPressed != null) {
      widget.onControlPressed(MediaControl.rwd);
    }
  }

  void _playPause() async {
    if (widget.onControlPressed != null) {
      bool changed = await widget
          .onControlPressed(_playing ? MediaControl.pause : MediaControl.play);
      if (changed) {
        setState(() {
          _playing = !_playing;
        });
      }
    }
  }

  void _stop() async {
    if (widget.onControlPressed != null) {
      bool succeeded = await widget.onControlPressed(MediaControl.stop);
      if (succeeded) {
        setState(() {
          _playing = false;
        });
      }
    }
  }

  void _forward() {
    if (widget.onControlPressed != null) {
      widget.onControlPressed(MediaControl.fwd);
    }
  }

  void _toggleController() {
    setState(() {
      _visible = !_visible;
    });
  }
}

class MediaControlsController {
  PositionChangedCallback _positionChangedCallback;
  MediaDurationCallback _mediaDurationCallback;

  void addPositionChangedListener(
      PositionChangedCallback positionChangedCallback) {
    _positionChangedCallback = positionChangedCallback;
  }

  void clearPositionChangedListener() {
    _positionChangedCallback = null;
  }

  void notifyPositionChanged(int position) {
    if (_positionChangedCallback != null) _positionChangedCallback(position);
  }

  void addMediaDurationListener(MediaDurationCallback mediaDurationCallback) {
    _mediaDurationCallback = mediaDurationCallback;
  }

  void clearMediaDurationListener() {
    _mediaDurationCallback = null;
  }

  void notifyMediaDurationListener(int duration) {
    if (_mediaDurationCallback != null) _mediaDurationCallback(duration);
  }
}
