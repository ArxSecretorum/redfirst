package com.example.app.service

import android.app.Service
import android.util.Log
import com.example.app.crypto.KeyStorage

class BackgroundService : Service() {

    private fun announceIdentity(store: KeyStorage) {
        if (BuildConfig.DEBUG) {
            Log.i(
                PROBE_LOG_TAG,
                "Security identity: device=${store.localDeviceId}, " +
                    "key=${store.identityFingerprintSha256().take(16)}…",
            )
            store.verifyEncryptedStorage().getOrThrow()
            Log.i(PROBE_LOG_TAG, "Security storage: AES-GCM round-trip passed")
        }
    }
}
