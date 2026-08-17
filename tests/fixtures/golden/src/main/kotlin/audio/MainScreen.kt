package com.example.app.audio

import android.app.Activity

class MainScreen : Activity() {

    /**
     * Releases the USB session back to the system and clears the track
     * (→ PlaybackService then stops itself, no second stop needed).
     */
    private fun releaseEverything() {
        stopService(android.content.Intent(this, com.example.app.audio.PlaybackService::class.java))
    }
}
