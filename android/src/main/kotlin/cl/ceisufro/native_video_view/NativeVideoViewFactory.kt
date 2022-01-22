package cl.ceisufro.native_video_view

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class NativeVideoViewFactory(private val binaryMessenger: BinaryMessenger,
                             private val lifecycleProvider: LifecycleProvider)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    @Suppress("UNCHECKED_CAST")
    override fun create(context: Context?, id: Int, args: Any?): PlatformView {
        val params = args as Map<String, Any?>
        val builder = NativeVideoViewBuilder()
        if (params.containsKey("useExoPlayer")) {
            val useExoPlayer = params["useExoPlayer"] as Boolean
            builder.setUseExoPlayer(useExoPlayer)
        }
        return builder.build(id, context, binaryMessenger, lifecycleProvider)
    }
}