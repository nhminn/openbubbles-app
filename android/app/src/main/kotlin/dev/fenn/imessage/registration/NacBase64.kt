package dev.fenn.imessage.registration

/**
 * Android-compatible base64 decoder for the vendored NAC tables.
 *
 * The upstream open-madrid sources use java.util.Base64, which is only available
 * on Android API 26+. The app supports API 24, so route the table decoding through
 * android.util.Base64 instead. DEFAULT accepts the MIME line breaks used by the
 * embedded chunks.
 */
internal object NacBase64 {
    fun decode(value: String): ByteArray = android.util.Base64.decode(value, android.util.Base64.DEFAULT)
}
