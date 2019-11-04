part of native_video_view;

typedef _ControlPressedCallback = void Function(_MediaControl control);

typedef _PositionChangedCallback = void Function(int position, int duration);

class _MediaController extends StatefulWidget {
  final Widget child;
  final MediaControlsController controller;
  final _ControlPressedCallback onControlPressed;
  final _PositionChangedCallback onPositionChanged;

  const _MediaController({
    Key key,
    @required this.child,
    this.controller,
    this.onControlPressed,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  _MediaControllerState createState() => _MediaControllerState();
}

class _MediaControllerState extends State<_MediaController> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Stack(
          children: <Widget>[
            widget.child,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleController,
                child: Container(),
              ),
            ),
          ],
        ),
        _buildMediaController(),
      ],
    );
  }

  Widget _buildMediaController() {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Offstage(
          child: _MediaControls(
            controller: widget.controller,
            onControlPressed: widget.onControlPressed,
            onPositionChanged: widget.onPositionChanged,
          ),
          offstage: !_visible,
        ));
  }

  void _toggleController() {
    setState(() {
      _visible = !_visible;
    });
  }
}

class _MediaControls extends StatefulWidget {
  final MediaControlsController controller;
  final _ControlPressedCallback onControlPressed;
  final _PositionChangedCallback onPositionChanged;

  const _MediaControls({
    Key key,
    this.controller,
    this.onControlPressed,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  _MediaControlsState createState() => _MediaControlsState();
}

class _MediaControlsState extends State<_MediaControls> {
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

  void _onControlPressed(_MediaControl mediaControl) {
    switch (mediaControl) {
      case _MediaControl.pause:
        setState(() {
          _playing = false;
        });
        break;
      case _MediaControl.play:
        setState(() {
          _playing = true;
        });
        break;
      case _MediaControl.stop:
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
      widget.onControlPressed(_MediaControl.rwd);
  }

  void _playPause() async {
    if (widget.onControlPressed != null)
      widget.onControlPressed(
          _playing ? _MediaControl.pause : _MediaControl.play);
  }

  void _stop() async {
    if (widget.onControlPressed != null)
      widget.onControlPressed(_MediaControl.stop);
  }

  void _forward() {
    if (widget.onControlPressed != null)
      widget.onControlPressed(_MediaControl.fwd);
  }
}

class MediaControlsController {
  _ControlPressedCallback _controlPressedCallback;
  _PositionChangedCallback _positionChangedCallback;

  void addControlPressedListener(
      _ControlPressedCallback controlPressedCallback) {
    _controlPressedCallback = controlPressedCallback;
  }

  void clearControlPressedListener() {
    _controlPressedCallback = null;
  }

  void notifyControlPressed(_MediaControl mediaControl) {
    if (_controlPressedCallback != null) _controlPressedCallback(mediaControl);
  }

  void addPositionChangedListener(
      _PositionChangedCallback positionChangedCallback) {
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
