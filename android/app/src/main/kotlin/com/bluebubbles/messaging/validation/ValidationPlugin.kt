package com.bluebubbles.messaging.validation

import dev.fenn.imessage.registration.NacMint
import dev.fenn.imessage.registration.NacRequestBlob
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.SecureRandom

/**
 * Bridge for the NAC validation-data mint.
 *
 * The Rust side owns the two HTTP calls (Apple rejects non-BoringSSL TLS for the
 * anisette/identity endpoints), while the byte-exact mint lives in the vendored
 * open-madrid Kotlin implementation. The flow is:
 *
 *   createRequest(cert)  -> 338-byte session-info-request
 *   (Rust POSTs it to Apple)
 *   finish(sessionInfo, session250) -> 517-byte validation-data stamp
 *
 * The mint state is kept between the two calls because the establish seed is
 * derived from the request blob. Only one setup/login runs at a time.
 */
object ValidationPlugin {
    const val CHANNEL = "com.bluebubbles.messaging/validation"

    private val random = SecureRandom()
    private var establishSeed: ByteArray? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "createRequest" -> {
                    val certData = call.argument<ByteArray>("cert")
                        ?: throw IllegalArgumentException("missing cert")
                    val pearKey16 = ByteArray(16).also(random::nextBytes)
                    val (request, seed) = NacRequestBlob.buildWithSeed(
                        leafCertificate(certData),
                        pearKey16,
                        random,
                    )
                    establishSeed = seed
                    result.success(request)
                }

                "finish" -> {
                    val sessionInfo = call.argument<ByteArray>("sessionInfo")
                        ?: throw IllegalArgumentException("missing sessionInfo")
                    val session250 = call.argument<ByteArray>("session250")
                        ?: throw IllegalArgumentException("missing session250")
                    val seed = establishSeed
                        ?: throw IllegalStateException("createRequest must run before finish")
                    establishSeed = null

                    require(session250.size in 1..0x17c) {
                        "hardware session data is ${session250.size} bytes, expected 1..0x17c"
                    }

                    val established = NacMint.keyEstablishmentFull(sessionInfo, seed)
                    require(established.payload.size >= 0x242) {
                        "establish response payload is ${established.payload.size} bytes, expected >= 0x242"
                    }
                    require(established.trailing.size >= 0x4f) {
                        "establish response trailing data is ${established.trailing.size} bytes, expected >= 0x4f"
                    }

                    val cert79 = established.trailing.copyOfRange(0, 0x4f)
                    val body576 = established.payload.copyOfRange(2, 0x242)
                    val rngPad = ByteArray(0x17c - session250.size).also(random::nextBytes)
                    val rand16 = ByteArray(16).also(random::nextBytes)

                    result.success(NacMint.mint(cert79, session250, rngPad, rand16, body576))
                }

                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error("validation-data", e.message ?: e.javaClass.simpleName, null)
        }
    }

    /**
     * The id-validation-cert bag returns a framed chain: 0x01, count, then
     * (u16 type, u16 len, DER) entries with the leaf last. A bare DER cert is
     * also accepted.
     */
    private fun leafCertificate(data: ByteArray): ByteArray {
        if (data.size > 4 && data[0] == 0x30.toByte() && data[1] == 0x82.toByte()) {
            return data
        }
        require(data.size >= 2 && data[0] == 0x01.toByte()) {
            "validation cert data has no 0x01 chain framing"
        }
        val count = data[1].toInt() and 0xff
        require(count > 0) { "validation cert chain is empty" }
        var offset = 2
        var last: ByteArray? = null
        repeat(count) {
            require(offset + 4 <= data.size) { "validation cert chain is truncated" }
            val length = ((data[offset + 2].toInt() and 0xff) shl 8) or
                (data[offset + 3].toInt() and 0xff)
            offset += 4
            require(length in 1..(data.size - offset)) { "validation cert entry is truncated" }
            last = data.copyOfRange(offset, offset + length)
            offset += length
        }
        return last ?: error("validation cert chain is empty")
    }
}
