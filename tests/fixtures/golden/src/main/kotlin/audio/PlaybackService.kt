package com.example.app.audio

import android.app.Service
import android.content.Intent

class PlaybackService : Service() {

    private lateinit var controller: PlayerController

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        controller.attachForeground(this)
        return START_STICKY
    }
}
