package cl.ceisufro.native_video_view

import android.app.Activity
import android.app.Application
import android.content.Context
import android.media.MediaPlayer
import android.os.Bundle
import android.view.View
import android.widget.VideoView
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


class NativeVideoViewController(id: Int,
                                context: Context?,
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
    private val videoView: VideoView
    private var dataSource: String? = null
    private var disposed: Boolean = false
    private var initialized: Boolean = false

    init {
        this.methodChannel.setMethodCallHandler(this)
        this.registrarActivityHashCode = registrar.activity().hashCode()
        this.videoView = VideoView(context)
        when (activityState.get()) {
            STOPPED -> {
                videoView.stopPlayback()
            }
            PAUSED -> {
                videoView.pause()
            }
            RESUMED -> {
                // Not implemented
            }
            STARTED -> {
                // Not implemented
            }
            CREATED -> {
                this.initVideoView()
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
        return videoView
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        methodChannel.setMethodCallHandler(null)
        videoView.stopPlayback()
        registrar.activity().application.unregisterActivityLifecycleCallbacks(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "player#setVideoFromFile" -> {
                val videoPath: String? = call.argument("videoPath")
                if (videoPath != null)
                    initVideo("file://$videoPath")
                result.success(null)
            }
            "player#setNetworkVideo" -> {
                val videoUri: String? = call.argument("videoUri")
                initVideo(videoUri)
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
                arguments["currentPosition"] = videoView.currentPosition
                result.success(arguments)
            }
            "player#seekTo" -> {
                val position: Int? = call.argument("position")
                if (position != null)
                    videoView.seekTo(position)
                result.success(null)
            }
        }
    }

    override fun onActivityCreated(activity: Activity?, p1: Bundle?) {
        this.initVideoView()
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

    private fun initVideoView() {
        videoView.setOnPreparedListener(this)
        videoView.setOnErrorListener(this)
        videoView.setOnCompletionListener(this)
        this.initialized = true
    }

    private fun initVideo(dataSource: String?) {
        if (!initialized) this.initVideoView()
        if (dataSource != null) {
            this.videoView.setVideoPath(dataSource)
            this.dataSource = dataSource
        }
    }

    private fun startPlayback() {
        if (!videoView.isPlaying && dataSource != null) {
            videoView.start()
        }
    }

    private fun pausePlayback() {
        if (videoView.canPause())
            videoView.pause()
    }

    private fun stopPlayback() {
        videoView.stopPlayback()
    }

    private fun destroyVideoView() {
        this.stopPlayback()
        videoView.setOnPreparedListener(null)
        videoView.setOnErrorListener(null)
        videoView.setOnCompletionListener(null)
        this.initialized = false
    }

    override fun onCompletion(mediaPlayer: MediaPlayer?) {
        methodChannel.invokeMethod("player#onCompletion", null)
    }

    override fun onError(mediaPlayer: MediaPlayer?, what: Int, extra: Int): Boolean {
        val arguments = HashMap<String, Any>()
        arguments["what"] = what
        arguments["extra"] = extra
        methodChannel.invokeMethod("player#onError", arguments)
        return true
    }

    override fun onPrepared(mediaPlayer: MediaPlayer?) {
        methodChannel.invokeMethod("player#onPrepared", null)
    }
}