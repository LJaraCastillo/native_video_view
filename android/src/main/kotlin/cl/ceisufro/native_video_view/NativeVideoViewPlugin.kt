package cl.ceisufro.native_video_view

import android.app.Activity
import android.app.Application
import android.os.Bundle
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.concurrent.atomic.AtomicInteger


class NativeVideoViewPlugin(registrar: Registrar) : Application.ActivityLifecycleCallbacks {
    private val state = AtomicInteger(0)
    private val registrarActivityHashCode: Int = registrar.activity().hashCode()

    companion object {
        const val CREATED = 1
        const val STARTED = 2
        const val RESUMED = 3
        const val PAUSED = 4
        const val STOPPED = 5
        const val DESTROYED = 6
        @JvmStatic

        fun registerWith(registrar: Registrar) {
            if (registrar.activity() == null) {
                // When a background flutter view tries to register the plugin, the registrar has no activity.
                // We stop the registration process as this plugin is foreground only.
                return
            }
            val plugin = NativeVideoViewPlugin(registrar)
            registrar.activity().application.registerActivityLifecycleCallbacks(plugin)
            registrar
                    .platformViewRegistry()
                    .registerViewFactory("native_video_view",
                            NativeVideoViewFactory(plugin.state, registrar))
        }
    }

    override fun onActivityCreated(activity: Activity?, p1: Bundle?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        state.set(CREATED)
    }

    override fun onActivityResumed(activity: Activity?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        state.set(RESUMED)
    }

    override fun onActivityStarted(activity: Activity?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        state.set(STARTED)
    }

    override fun onActivityPaused(activity: Activity?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        state.set(PAUSED)
    }

    override fun onActivityStopped(activity: Activity?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        state.set(STOPPED)
    }

    override fun onActivityDestroyed(activity: Activity?) {
        if (activity.hashCode() != registrarActivityHashCode) return
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        state.set(DESTROYED)
    }

    override fun onActivitySaveInstanceState(activity: Activity?, bundle: Bundle?) {
        // Not Implemented
    }
}
