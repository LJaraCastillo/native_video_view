package cl.ceisufro.native_video_view

import android.content.Context
import androidx.lifecycle.Lifecycle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView

class NativeVideoViewBuilder : NativeVideoViewOptionsSink {
    private var useExoPlayer: Boolean = false

    fun build(id: Int, context: Context?, binaryMessenger: BinaryMessenger, lifecycleProvider: LifecycleProvider): PlatformView {
        return if (useExoPlayer) {
            ExoPlayerController(id, context!!, binaryMessenger, lifecycleProvider)
        } else {
            NativeVideoViewController(id, context!!, binaryMessenger, lifecycleProvider)
        }
    }

    override fun setUseExoPlayer(useExoPlayer: Boolean) {
        this.useExoPlayer = useExoPlayer
    }
}