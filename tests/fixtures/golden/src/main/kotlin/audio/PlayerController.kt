package com.example.app.audio

import android.content.Context
import android.content.Intent

class PlayerController(private val context: Context) {

    /** Called from PlaybackService on SCREEN_ON after lifecycle callbacks had a chance. */
    fun onScreenOn() = refreshRoute()

    fun start() {
        // Publish a session owner before opening the audible path. PlaybackService state is
        // observed by the notification, so the order here is not cosmetic.
        context.startForegroundService(Intent(context, PlaybackService::class.java))
    }

    fun stop() {
        context.stopService(Intent(context, PlaybackService::class.java))
    }
}
