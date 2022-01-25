package cl.ceisufro.native_video_view

import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.LayoutInflater
import android.view.SurfaceView
import android.view.View
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.upstream.DataSource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.*
import com.google.android.exoplayer2.upstream.DefaultDataSource.Factory as DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource.Factory as DefaultHttpDataSourceFactory


class ExoPlayerController(
    private val id: Int,
    private val context: Context,
    binaryMessenger: BinaryMessenger,
    private val lifecycleProvider: LifecycleProvider
) : DefaultLifecycleObserver,
    MethodChannel.MethodCallHandler,
    PlatformView,
    Player.Listener {
    private val methodChannel: MethodChannel =
        MethodChannel(binaryMessenger, "native_video_view_$id")
    private val lifeCycleHashcode: Int
    private val constraintLayout: ConstraintLayout
    private val surfaceView: SurfaceView
    private val exoPlayer: ExoPlayer
    private var dataSource: String? = null
    private var requestAudioFocus: Boolean = true
    private var volume: Double = 1.0
    private var mute: Boolean = false
    private var disposed: Boolean = false
    private var playerState: PlayerState = PlayerState.NOT_INITIALIZED

    init {
        this.methodChannel.setMethodCallHandler(this)
        this.lifeCycleHashcode = lifecycleProvider.getLifecycle().hashCode()
        this.constraintLayout = LayoutInflater.from(context)
            .inflate(R.layout.exoplayer_layout, null) as ConstraintLayout
        this.surfaceView = constraintLayout.findViewById(R.id.exo_player_surface_view)
        val trackSelector = DefaultTrackSelector(context)
        this.exoPlayer = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .build()
        lifecycleProvider.getLifecycle()!!.addObserver(this)
    }

    override fun getView(): View {
        return constraintLayout
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        methodChannel.setMethodCallHandler(null)
        this.destroyVideoView()
        lifecycleProvider.getLifecycle()!!.removeObserver(this)
        Log.d("NVV#ExoPlayer", "Disposed view $id")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "player#setVideoSource" -> {
                val videoPath: String? = call.argument("videoSource")
                val sourceType: String? = call.argument("sourceType")
                requestAudioFocus = call.argument("requestAudioFocus") as Boolean? ?: true
                if (videoPath != null) {
                    if (sourceType.equals("VideoSourceType.asset")
                        || sourceType.equals("VideoSourceType.file")
                    ) {
                        initVideo("file://$videoPath")
                    } else {
                        initVideo(videoPath)
                    }
                }
                result.success(null)
            }
            "player#start" -> {
                startPlayback()
                result.success(null)
            }
            "player#pause" -> {
                pausePlayback()
                result.success(null)
            }
            "player#stop" -> {
                stopPlayback()
                result.success(null)
            }
            "player#currentPosition" -> {
                val arguments = HashMap<String, Any>()
                arguments["currentPosition"] = exoPlayer.currentPosition
                result.success(arguments)
            }
            "player#isPlaying" -> {
                val arguments = HashMap<String, Any>()
                arguments["isPlaying"] = exoPlayer.isPlaying
                result.success(arguments)
            }
            "player#seekTo" -> {
                val position: Int? = call.argument("position")
                if (position != null)
                    exoPlayer.seekTo(position.toLong())
                result.success(null)
            }
            "player#toggleSound" -> {
                mute = !mute
                configureVolume()
                result.success(null)
            }
            "player#setVolume" -> {
                val volume: Double? = call.argument("volume")
                if (volume != null) {
                    this.mute = false
                    this.volume = volume
                    configureVolume()
                }
                result.success(null)
            }
        }
    }

    override fun onCreate(owner: LifecycleOwner) {
        super.onCreate(owner)
        this.configurePlayer()
    }

    override fun onPause(owner: LifecycleOwner) {
        super.onPause(owner)
        if (disposed) return
        this.pausePlayback()
    }

    override fun onStop(owner: LifecycleOwner) {
        super.onStop(owner)
        if (disposed) return
        this.stopPlayback()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        super.onDestroy(owner)
        if (disposed) return
        this.destroyVideoView()
    }

    private fun configurePlayer() {
        try {
            exoPlayer.addListener(this)
            exoPlayer.setVideoSurfaceView(surfaceView)
            handleAudioFocus()
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    private fun handleAudioFocus() {
        exoPlayer.setAudioAttributes(getAudioAttributes(), requestAudioFocus)
    }

    private fun getAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.CONTENT_TYPE_MOVIE)
            .build()
    }

    private fun configureVolume() {
        if (mute) {
            exoPlayer.volume = 0f
        } else {
            exoPlayer.volume = volume.toFloat()
        }
    }

    private fun initVideo(dataSource: String?) {
        this.configurePlayer()
        if (dataSource != null) {
            val uri = Uri.parse(dataSource)
            val dataSourceFactory = getDataSourceFactory(uri)
            val mediaSource = ProgressiveMediaSource
                .Factory(dataSourceFactory, DefaultExtractorsFactory())
                .createMediaSource(MediaItem.fromUri(uri))
            this.exoPlayer.playWhenReady = false
            this.exoPlayer.setMediaSource(mediaSource)
            this.exoPlayer.prepare()
            playerState = PlayerState.PREPARED
            this.dataSource = dataSource
        }
    }

    private fun getDataSourceFactory(uri: Uri): DataSource.Factory {
        val scheme: String? = uri.scheme
        return if (scheme != null && (scheme == "http" || scheme == "https")) {
            DefaultHttpDataSourceFactory()
        } else {
            DefaultDataSourceFactory(context)
        }
    }

    private fun startPlayback() {
        if (playerState != PlayerState.PLAYING && dataSource != null) {
            if (playerState != PlayerState.NOT_INITIALIZED) {
                playerState = PlayerState.PLAYING
                exoPlayer.playWhenReady = true
            } else {
                playerState = PlayerState.PLAY_WHEN_READY
                initVideo(dataSource)
            }
        }
    }

    private fun pausePlayback() {
        playerState = PlayerState.PAUSED
        exoPlayer.playWhenReady = false
    }

    private fun stopPlayback() {
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        playerState = PlayerState.NOT_INITIALIZED
    }

    private fun destroyVideoView() {
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        exoPlayer.removeListener(this)
        exoPlayer.release()
    }

    override fun onPlayerError(error: PlaybackException) {
        super.onPlayerError(error)
        dataSource = null
        playerState = PlayerState.NOT_INITIALIZED
        val arguments = HashMap<String, Any>()
        arguments["what"] = error.errorCodeName
        arguments["extra"] = error.message ?: ""
        methodChannel.invokeMethod("player#onError", arguments)
    }

    override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
        if (playbackState == Player.STATE_ENDED) {
            stopPlayback()
            methodChannel.invokeMethod("player#onCompletion", null)
        } else if (playbackState == Player.STATE_READY) {
            configureVolume()
            if (playerState == PlayerState.PLAY_WHEN_READY) {
                this.startPlayback()
            } else if (playerState == PlayerState.PREPARED) {
                notifyPlayerPrepared()
            }
        }
    }

    private fun notifyPlayerPrepared() {
        val arguments = HashMap<String, Any>()
        val videoFormat = exoPlayer.videoFormat
        if (videoFormat != null) {
            arguments["height"] = videoFormat.height
            arguments["width"] = videoFormat.width
            arguments["duration"] = exoPlayer.duration
        }
        methodChannel.invokeMethod("player#onPrepared", arguments)
    }

}