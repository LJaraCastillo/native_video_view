package cl.ceisufro.native_video_view

import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.atomic.AtomicInteger

class NativeVideoViewBuilder : NativeVideoViewOptionsSink {
    private var useExoPlayer: Boolean = false

    fun build(id: Int, state: AtomicInteger, registrar: PluginRegistry.Registrar): PlatformView {
        return if (useExoPlayer) {
            ExoPlayerController(id, state, registrar)
        } else {
            NativeVideoViewController(id, state, registrar)
        }
    }

    override fun setUseExoPlayer(useExoPlayer: Boolean) {
        this.useExoPlayer = useExoPlayer
    }
}