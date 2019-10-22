package cl.ceisufro.native_video_view

import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.atomic.AtomicInteger

class NativeVideoViewBuilder : NativeVideoViewOptionsSink {
    private var showMediaController: Boolean = false

    fun build(id: Int, context: Context?, state: AtomicInteger, registrar: PluginRegistry.Registrar): NativeVideoViewController {
        val nativeVideoViewController = NativeVideoViewController(id, state, registrar)
        nativeVideoViewController.showMediaController(showMediaController)
        return nativeVideoViewController
    }

    override fun showMediaController(showMediaController: Boolean) {
        this.showMediaController = showMediaController
    }
}