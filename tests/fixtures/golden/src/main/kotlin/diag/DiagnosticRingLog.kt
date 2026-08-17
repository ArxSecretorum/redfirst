package com.example.app.diag

import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Bounded on-disk journal: notes survive the process being killed by the system.
 * Kept because logcat is unavailable to applications from API 34 onwards.
 */
class DiagnosticRingLog(
    directory: File,
    private val role: String,
    private val maxBytes: Long = DEFAULT_MAX_BYTES,
) {
    private val file = File(directory, FILE_NAME)
    private val journal = journals.computeIfAbsent(file.absolutePath) { JournalState() }

    init {
        require(role.matches(SAFE_TOKEN)) { "Diagnostic role must be a safe token" }
        require(maxBytes >= MIN_MAX_BYTES) { "Diagnostic journal bound is too small" }
    }

    fun note(line: String) = journal.append(file, line, maxBytes)

    private companion object {
        val journals = ConcurrentHashMap<String, JournalState>()
    }
}
