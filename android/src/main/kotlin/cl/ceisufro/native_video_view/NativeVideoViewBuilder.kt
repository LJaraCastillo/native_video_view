package cl.ceisufro.native_video_view

import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.atomic.AtomicInteger

class NativeVideoViewBuilder : NativeVideoViewOptionsSink {

    fun build(id: Int, state: AtomicInteger, registrar: PluginRegistry.Registrar): NativeVideoViewController {
        return NativeVideoViewController(id, state, registrar)
    }
}