package cl.ceisufro.native_video_view

import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.Lifecycle.Event
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry

class ProxyLifecycleProvider(activity: Activity) : Application.ActivityLifecycleCallbacks,
    LifecycleOwner, LifecycleProvider {
    private val lifecycle: LifecycleRegistry = LifecycleRegistry(this)
    private val registrarActivityHashCode: Int = activity.hashCode()

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        lifecycle.handleLifecycleEvent(Event.ON_CREATE)
    }

    override fun onActivityStarted(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        lifecycle.handleLifecycleEvent(Event.ON_START)
    }

    override fun onActivityResumed(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        lifecycle.handleLifecycleEvent(Event.ON_RESUME)
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        lifecycle.handleLifecycleEvent(Event.ON_PAUSE)
    }

    override fun onActivityStopped(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        lifecycle.handleLifecycleEvent(Event.ON_STOP)
    }

    override fun onActivitySaveInstanceState(activity: Activity, bundle: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        activity.application.unregisterActivityLifecycleCallbacks(this)
        lifecycle.handleLifecycleEvent(Event.ON_DESTROY)
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycle
    }

    init {
        activity.application.registerActivityLifecycleCallbacks(this)
    }
}