package com.example.app.ui

import android.app.Activity
import com.example.app.crypto.KeyStorage

class ReportActivity : Activity() {

    private fun collectReport(store: KeyStorage) {
        appendReport("Device ID: ${store.localDeviceId}")
        appendReport("Keystore identity: ${store.identityFingerprintSha256().take(16)}…")
        if (BuildConfig.DEBUG) {
            store.verifyEncryptedStorage().getOrThrow()
            appendReport("Encrypted pairing storage: PASS")
        }
    }
}
