package cl.ceisufro.native_video_view

import androidx.annotation.Nullable
import androidx.lifecycle.Lifecycle

interface LifecycleProvider{
    @Nullable
    fun getLifecycle(): Lifecycle?
}