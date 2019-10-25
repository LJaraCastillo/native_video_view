part of native_video_view;

typedef ControlPressed = bool Function(MediaControl control);

typedef PositionChanged = bool Function(int position);

class MediaController extends StatefulWidget {
  final Widget child;
  final ControlPressed onControlPressed;
  final PositionChanged onPositionChanged;

  const MediaController({
    Key key,
    @required this.child,
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
      onChanged: (double value) {},
      value: _progress,
    );
  }

  Widget _buildControlButton({IconData iconData, Function onPressed}) {
    return IconButton(
      icon: Icon(iconData),
      onPressed: onPressed,
    );
  }

  void _rewind() {
    if (widget.onControlPressed != null) {
      bool succeded = widget.onControlPressed(MediaControl.rwd);
    }
  }

  void _playPause() {
    if (widget.onControlPressed != null) {
      bool changed = widget
          .onControlPressed(_playing ? MediaControl.pause : MediaControl.play);
      if (changed) {
        setState(() {
          _playing = !_playing;
        });
      }
    }
  }

  void _stop() {
    if (widget.onControlPressed != null) {
      bool succeeded = widget.onControlPressed(MediaControl.stop);
      if (succeeded) {
        setState(() {
          _playing = false;
        });
      }
    }
  }

  void _forward() {
    if (widget.onControlPressed != null) {
      bool succeded = widget.onControlPressed(MediaControl.fwd);
    }
  }

  void _toggleController() {
    setState(() {
      _visible = !_visible;
    });
  }
}
