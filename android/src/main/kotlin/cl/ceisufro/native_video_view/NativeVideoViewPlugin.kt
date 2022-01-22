package cl.ceisufro.native_video_view

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter


class NativeVideoViewPlugin : FlutterPlugin, ActivityAware {
    private var lifecycle: Lifecycle? = null

    companion object {
        private const val VIEW_TYPE_ID = "native_video_view"

        @Suppress("deprecation")
        fun registerWith(registrar: io.flutter.plugin.common.PluginRegistry.Registrar) {
            val activity = registrar.activity() ?: return
            // When a background flutter view tries to register the plugin, the registrar has no activity.
            // We stop the registration process as this plugin is foreground only.

            if (activity is LifecycleOwner) {
                registrar
                    .platformViewRegistry()
                    .registerViewFactory(
                        VIEW_TYPE_ID,
                        NativeVideoViewFactory(
                            registrar.messenger(),
                            object : LifecycleProvider {
                                override fun getLifecycle(): Lifecycle {
                                    return (activity as LifecycleOwner).lifecycle
                                }
                            })
                    )
            } else {
                registrar
                    .platformViewRegistry()
                    .registerViewFactory(
                        VIEW_TYPE_ID,
                        NativeVideoViewFactory(
                            registrar.messenger(),
                            ProxyLifecycleProvider(activity)
                        )
                    )
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding
            .platformViewRegistry
            .registerViewFactory(
                VIEW_TYPE_ID,
                NativeVideoViewFactory(
                    binding.binaryMessenger,
                    object : LifecycleProvider {
                        override fun getLifecycle(): Lifecycle? {
                            return lifecycle
                        }
                    })
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Not implemented
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
    }

    override fun onDetachedFromActivity() {
        lifecycle = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}

