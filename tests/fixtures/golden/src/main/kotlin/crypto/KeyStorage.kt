package com.example.app.crypto

import java.security.MessageDigest
import java.util.Base64

class KeyStorage(private val context: Context) {

    val localDeviceId: String
        get() = withReadyStore { readOrCreateDeviceId() }

    fun identityFingerprintSha256(): String = withReadyStore {
        Base64.getUrlEncoder().withoutPadding().encodeToString(
            MessageDigest.getInstance("SHA-256").digest(getOrCreateIdentityKey().public.encoded),
        )
    }

    /** Runs a destructive-only-to-itself probe entry and always removes it. */
    fun verifyEncryptedStorage(): Result<Unit> = runCatching {
        withReadyStore { probeRoundTrip() }
    }
}
