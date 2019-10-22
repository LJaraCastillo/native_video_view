package cl.ceisufro.native_video_view

import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.atomic.AtomicInteger

class NativeVideoViewFactory(private val activityState: AtomicInteger,
                             private val registrar: PluginRegistry.Registrar)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, id: Int, args: Any?): PlatformView {
        val params = args as Map<String, Any>
        val builder = NativeVideoViewBuilder()
        if (params.containsKey("showMediaController"))
            builder.showMediaController(params["showMediaController"] as Boolean)
        return builder.build(id, context, activityState, registrar)
    }
}