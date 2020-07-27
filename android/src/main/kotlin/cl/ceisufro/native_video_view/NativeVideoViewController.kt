package cl.ceisufro.native_video_view

import android.app.Activity
import android.app.Application
import android.media.MediaPlayer
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import androidx.constraintlayout.widget.ConstraintLayout
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.CREATED
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.DESTROYED
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.PAUSED
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.RESUMED
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.STARTED
import cl.ceisufro.native_video_view.NativeVideoViewPlugin.Companion.STOPPED
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import java.util.*
import java.util.concurrent.atomic.AtomicInteger


class NativeVideoViewController(private val id: Int,
                                activityState: AtomicInteger,
                                private val registrar: PluginRegistry.Registrar)
    : Application.ActivityLifecycleCallbacks,
        MethodChannel.MethodCallHandler,
        PlatformView,
        MediaPlayer.OnPreparedListener,
        MediaPlayer.OnErrorListener,
        MediaPlayer.OnCompletionListener {
    private val methodChannel: MethodChannel = MethodChannel(registrar.messenger(), "native_video_view_$id")
    private val registrarActivityHashCode: Int
    private val constraintLayout: ConstraintLayout
    private var videoView: CustomVideoView? = null
    private var dataSource: String? = null
    private var disposed: Boolean = false
    private var requestAudioFocus: Boolean = true
    private var volume: Double = 1.0
    private var mute: Boolean = false
    private var mediaPlayer: MediaPlayer? = null
    private var playerState: PlayerState = PlayerState.NOT_INITIALIZED

    init {
        this.methodChannel.setMethodCallHandler(this)
        this.registrarActivityHashCode = registrar.activity().hashCode()
        this.constraintLayout = LayoutInflater.from(registrar.activity())
                .inflate(R.layout.video_layout, null) as ConstraintLayout
        when (activityState.get()) {
            STOPPED -> {
                stopPlayback()
            }
            PAUSED -> {
                pausePlayback()
            }
            RESUMED -> {
                // Not implemented
            }
            STARTED -> {
                // Not implemented
            }
            CREATED -> {
                configurePlayer()
            }
            DESTROYED -> {
                // Not implemented
            }
            else -> throw IllegalArgumentException(
                    "Cannot interpret " + activityState.get() + " as an activity state")
        }
        registrar.activity().application.registerActivityLifecycleCallbacks(this)
    }

    override fun getView(): View {
        return constraintLayout
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        methodChannel.setMethodCallHandler(null)
        this.destroyVideoView()
        registrar.activity().application.unregisterActivityLifecycleCallbacks(this)
        Log.d("NVV", "Disposed view $id")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "player#setVideoSource" -> {
                val videoPath: String? = call.argument("videoSource")
                val sourceType: String? = call.argument("sourceType")
                requestAudioFocus = call.argument("requestAudioFocus") as Boolean? ?: true
                if (videoPath != null) {
                    if (sourceType.equals("VideoSourceType.asset")
                            || sourceType.equals("VideoSourceType.file")) {
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
                arguments["currentPosition"] = videoView?.currentPosition ?: 0
                result.success(arguments)
            }
            "player#isPlaying" -> {
                val arguments = HashMap<String, Any>()
                arguments["isPlaying"] = videoView?.isPlaying ?: false
                result.success(arguments)
            }
            "player#seekTo" -> {
                val position: Int? = call.argument("position")
                if (position != null)
                    videoView?.seekTo(position)
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

    override fun onActivityCreated(activity: Activity?, p1: Bundle?) {
        this.configurePlayer()
    }

    override fun onActivityStarted(activity: Activity?) {
        // Not implemented
    }

    override fun onActivityResumed(activity: Activity?) {
        // Not implemented
    }

    override fun onActivityPaused(activity: Activity?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) return
        this.pausePlayback()
    }

    override fun onActivityStopped(activity: Activity?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) return
        this.stopPlayback()
    }

    override fun onActivityDestroyed(activity: Activity?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) return
        this.destroyVideoView()
    }

    override fun onActivitySaveInstanceState(activity: Activity?, p1: Bundle?) {
        // Not implemented
    }

    private fun configurePlayer() {
        videoView = constraintLayout.findViewById(R.id.native_video_view)
        videoView?.setOnPreparedListener(this)
        videoView?.setOnErrorListener(this)
        videoView?.setOnCompletionListener(this)
        videoView?.setZOrderOnTop(true)
        if (requestAudioFocus)
            videoView?.requestAudioFocus()
    }

    private fun initVideo(dataSource: String?) {
        this.configurePlayer()
        if (dataSource != null) {
            this.videoView?.setVideoPath(dataSource)
            this.dataSource = dataSource
        }
    }

    private fun startPlayback() {
        if (playerState != PlayerState.PLAYING && dataSource != null) {
            if (playerState != PlayerState.NOT_INITIALIZED) {
                videoView?.start()
                playerState = PlayerState.PLAYING
            } else {
                playerState = PlayerState.PLAY_WHEN_READY
                initVideo(dataSource)
            }
        }
    }

    private fun pausePlayback() {
        val canPause = videoView?.canPause() ?: false
        if (canPause) {
            videoView?.pause()
            playerState = PlayerState.PAUSED
        }
    }

    private fun stopPlayback() {
        videoView?.stopPlayback()
        playerState = PlayerState.NOT_INITIALIZED
    }

    private fun destroyVideoView() {
        videoView?.stopPlayback()
        videoView?.setOnPreparedListener(null)
        videoView?.setOnErrorListener(null)
        videoView?.setOnCompletionListener(null)
    }

    override fun onCompletion(mediaPlayer: MediaPlayer?) {
        this.mediaPlayer = null
        stopPlayback()
        methodChannel.invokeMethod("player#onCompletion", null)
    }

    override fun onError(mediaPlayer: MediaPlayer?, what: Int, extra: Int): Boolean {
        dataSource = null
        this.mediaPlayer = null
        playerState = PlayerState.NOT_INITIALIZED
        val arguments = HashMap<String, Any>()
        arguments["what"] = what
        arguments["extra"] = extra
        methodChannel.invokeMethod("player#onError", arguments)
        return true
    }

    private fun configureVolume() {
        if (mediaPlayer != null) {
            if (mute) {
                mediaPlayer?.setVolume(0f, 0f)
            } else {
                mediaPlayer?.setVolume(volume.toFloat(), volume.toFloat())
            }
        }
    }

    override fun onPrepared(mediaPlayer: MediaPlayer?) {
        this.mediaPlayer = mediaPlayer
        configureVolume()
        if (playerState == PlayerState.PLAY_WHEN_READY) {
            this.startPlayback()
        } else {
            notifyPlayerPrepared(mediaPlayer)
        }
    }

    private fun notifyPlayerPrepared(mediaPlayer: MediaPlayer?) {
        val arguments = HashMap<String, Any>()
        if (mediaPlayer != null) {
            arguments["height"] = mediaPlayer.videoHeight
            arguments["width"] = mediaPlayer.videoWidth
            arguments["duration"] = mediaPlayer.duration
        }
        playerState = PlayerState.PREPARED
        methodChannel.invokeMethod("player#onPrepared", arguments)
    }
}