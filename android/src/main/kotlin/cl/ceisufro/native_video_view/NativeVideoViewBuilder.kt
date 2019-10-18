package cl.ceisufro.native_video_view

import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.atomic.AtomicInteger

class NativeVideoViewBuilder : NativeVideoViewOptionsSink {
    fun build(id: Int, context: Context?, state: AtomicInteger, registrar: PluginRegistry.Registrar): NativeVideoViewController {
        return NativeVideoViewController(id, context, state, registrar)
    }
}