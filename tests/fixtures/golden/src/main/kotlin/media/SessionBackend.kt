package com.example.app.media

import android.media.session.MediaController
import android.media.session.PlaybackState

/**
 * Ranking of media sessions when several applications publish one at once.
 * Higher tier wins; the user's preferred package always outranks the rest.
 */
private fun MediaController.sessionIdentity(): SessionIdentity =
    SessionIdentity(packageName, sessionToken)

internal fun MediaController.selectionTier(preferredPackage: String?): Int {
    return sessionSelectionTier(
        state = playbackState?.state,
        preferred = packageName == preferredPackage,
    )
}

private fun sessionSelectionTier(state: Int?, preferred: Boolean): Int = when {
    preferred -> 2
    state == PlaybackState.STATE_PLAYING -> 1
    else -> 0
}
