package com.robby031.genauth

import android.app.assist.AssistStructure
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.Dataset
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveRequest
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import org.json.JSONArray
import org.json.JSONObject
import java.net.URI
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.math.pow

@RequiresApi(Build.VERSION_CODES.O)
class GenAuthAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback,
    ) {
        val context = request.fillContexts.lastOrNull()
        val structure = context?.structure
        if (structure == null) {
            callback.onSuccess(null)
            return
        }

        val parsed = parseStructure(structure)
        if (parsed.otpFieldIds.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        val domain = parsed.webDomain?.let(::normalizeHost)
        if (domain.isNullOrEmpty()) {
            logAutofillTelemetry(
                status = "failed",
                detail = "no_web_domain",
                metadata = mapOf("otpFieldCount" to parsed.otpFieldIds.size),
            )
            callback.onSuccess(null)
            return
        }

        val accounts = loadAccounts()
        if (accounts.isEmpty()) {
            logAutofillTelemetry(
                status = "failed",
                detail = "no_accounts",
                metadata = mapOf("domain" to domain),
            )
            callback.onSuccess(null)
            return
        }

        val matched = selectBestAccount(accounts, domain)
        if (matched == null) {
            logAutofillTelemetry(
                status = "failed",
                detail = "no_matching_account",
                metadata = mapOf(
                    "domain" to domain,
                    "accountCount" to accounts.size,
                ),
            )
            callback.onSuccess(null)
            return
        }

        val code = generateTotpCode(matched) ?: run {
            logAutofillTelemetry(
                status = "failed",
                detail = "code_generation_failed",
                metadata = mapOf(
                    "domain" to domain,
                    "accountId" to matched.id,
                ),
            )
            callback.onSuccess(null)
            return
        }

        val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1)
        val title = if (matched.issuer.isNotBlank()) matched.issuer else matched.label
        presentation.setTextViewText(android.R.id.text1, "GenAuth OTP • $title")

        val datasetBuilder = Dataset.Builder(presentation)
        parsed.otpFieldIds.forEach { fieldId ->
            datasetBuilder.setValue(fieldId, AutofillValue.forText(code), presentation)
        }

        val response = FillResponse.Builder()
            .addDataset(datasetBuilder.build())
            .build()

        logAutofillTelemetry(
            status = "success",
            detail = "matched",
            metadata = mapOf(
                "domain" to domain,
                "accountId" to matched.id,
                "issuer" to matched.issuer,
                "label" to matched.label,
                "otpFieldCount" to parsed.otpFieldIds.size,
            ),
        )

        callback.onSuccess(response)
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onSuccess()
    }

    private fun parseStructure(structure: AssistStructure): ParsedForm {
        val parsed = ParsedForm()
        for (i in 0 until structure.windowNodeCount) {
            val node = structure.getWindowNodeAt(i).rootViewNode
            traverseNode(node, parsed)
        }
        return parsed
    }

    private fun traverseNode(node: AssistStructure.ViewNode, parsed: ParsedForm) {
        if (parsed.webDomain == null) {
            parsed.webDomain = node.webDomain
        }

        if (isOtpCandidate(node) && node.autofillId != null) {
            parsed.otpFieldIds.add(node.autofillId)
        }

        for (i in 0 until node.childCount) {
            traverseNode(node.getChildAt(i), parsed)
        }
    }

    private fun isOtpCandidate(node: AssistStructure.ViewNode): Boolean {
        val hints = node.autofillHints?.joinToString(" ")?.lowercase() ?: ""
        val idEntry = node.idEntry?.lowercase() ?: ""
        val hintText = node.hint?.lowercase() ?: ""

        if (hints.contains("otp") || hints.contains("2fa") || hints.contains("one_time") || hints.contains("verification")) {
            return true
        }

        if (idEntry.contains("otp") || idEntry.contains("2fa") || idEntry.contains("code") || idEntry.contains("verification")) {
            return true
        }

        if (hintText.contains("otp") || hintText.contains("2fa") || hintText.contains("code") || hintText.contains("verification")) {
            return true
        }

        return false
    }

    private fun loadAccounts(): List<AutofillAccount> {
        val json = AutofillSyncStore.readAccountsJson(this)
        val array = JSONArray(json)
        val result = mutableListOf<AutofillAccount>()
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            result.add(
                AutofillAccount(
                    id = item.optString("id", ""),
                    issuer = item.optString("issuer", ""),
                    label = item.optString("label", ""),
                    tags = item.optJSONArray("tags").toStringList(),
                    secretB32 = item.optString("secretB32", ""),
                    algorithm = item.optString("algorithm", "SHA1"),
                    digits = item.optInt("digits", 6),
                    period = item.optInt("period", 30),
                    isHotp = item.optBoolean("isHotp", false),
                )
            )
        }
        return result
    }

    private fun normalizeHost(raw: String): String {
        return try {
            val withScheme = if (raw.contains("://")) raw else "https://$raw"
            val uri = URI(withScheme)
            (uri.host ?: raw).lowercase().removePrefix("www.")
        } catch (_: Throwable) {
            raw.lowercase().removePrefix("www.")
        }
    }

    private fun normalizeToken(raw: String): String {
        return raw.lowercase().replace(Regex("[^a-z0-9]"), "")
    }

    private fun matchesDomain(account: AutofillAccount, host: String): Boolean {
        val hostNorm = normalizeHost(host)

        val manualDomains = parseManualDomains(account.tags)
        if (manualDomains.any { mapped ->
                hostNorm == mapped || hostNorm.endsWith(".$mapped") || mapped.endsWith(".$hostNorm")
            }) {
            return true
        }

        val issuerNorm = normalizeToken(account.issuer)
        if (issuerNorm.isNotEmpty() && normalizeToken(hostNorm).contains(issuerNorm)) {
            return true
        }

        val labelDomain = extractEmailDomain(account.label)
        if (!labelDomain.isNullOrBlank()) {
            val labelHost = normalizeHost(labelDomain)
            if (hostNorm == labelHost || hostNorm.endsWith(".$labelHost") || labelHost.endsWith(".$hostNorm")) {
                return true
            }
        }

        return false
    }

    private fun selectBestAccount(accounts: List<AutofillAccount>, host: String): AutofillAccount? {
        val hostNorm = normalizeHost(host)
        val totpAccounts = accounts.filter { !it.isHotp }
        if (totpAccounts.isEmpty()) return null

        val manual = totpAccounts.firstOrNull { account ->
            parseManualDomains(account.tags).any { mapped ->
                hostNorm == mapped || hostNorm.endsWith(".$mapped") || mapped.endsWith(".$hostNorm")
            }
        }
        if (manual != null) return manual

        return totpAccounts.firstOrNull { matchesDomain(it, hostNorm) }
    }

    private fun parseManualDomains(tags: List<String>): List<String> {
        val result = mutableListOf<String>()
        tags.forEach { tag ->
            val raw = tag.trim()
            if (raw.isEmpty()) return@forEach

            val lower = raw.lowercase()
            val domainRaw = when {
                lower.startsWith("domain:") -> raw.substringAfter(':')
                lower.startsWith("host:") -> raw.substringAfter(':')
                lower.startsWith("site:") -> raw.substringAfter(':')
                lower.startsWith("web:") -> raw.substringAfter(':')
                else -> null
            }

            if (!domainRaw.isNullOrBlank()) {
                domainRaw
                    .split(',', ';', ' ')
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }
                    .map(::normalizeHost)
                    .filter { it.isNotEmpty() }
                    .forEach(result::add)
            }
        }
        return result.distinct()
    }

    private fun extractEmailDomain(label: String): String? {
        val at = label.lastIndexOf('@')
        if (at < 0 || at >= label.length - 1) return null
        val domain = label.substring(at + 1).trim()
        return if (domain.contains('.')) domain else null
    }

    private fun generateTotpCode(account: AutofillAccount): String? {
        if (account.secretB32.isBlank()) return null
        if (account.period <= 0 || account.digits <= 0) return null

        val secret = decodeBase32(account.secretB32) ?: return null
        val counter = System.currentTimeMillis() / 1000L / account.period
        val data = ByteArray(8)
        for (i in 7 downTo 0) {
            data[i] = (counter ushr ((7 - i) * 8)).toByte()
        }

        val macAlgo = when (account.algorithm.uppercase()) {
            "SHA256" -> "HmacSHA256"
            "SHA512" -> "HmacSHA512"
            else -> "HmacSHA1"
        }

        val mac = Mac.getInstance(macAlgo)
        mac.init(SecretKeySpec(secret, macAlgo))
        val hash = mac.doFinal(data)

        val offset = hash.last().toInt() and 0x0F
        val binary =
            ((hash[offset].toInt() and 0x7F) shl 24) or
                ((hash[offset + 1].toInt() and 0xFF) shl 16) or
                ((hash[offset + 2].toInt() and 0xFF) shl 8) or
                (hash[offset + 3].toInt() and 0xFF)

        val otp = (binary % 10.0.pow(account.digits.toDouble()).toInt())
        return otp.toString().padStart(account.digits, '0')
    }

    private fun decodeBase32(input: String): ByteArray? {
        val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        val clean = input.uppercase().replace("=", "").replace(" ", "")
        if (clean.isEmpty()) return null

        var buffer = 0
        var bitsLeft = 0
        val out = mutableListOf<Byte>()

        for (char in clean) {
            val val5 = alphabet.indexOf(char)
            if (val5 < 0) return null

            buffer = (buffer shl 5) or val5
            bitsLeft += 5

            if (bitsLeft >= 8) {
                bitsLeft -= 8
                out.add(((buffer shr bitsLeft) and 0xFF).toByte())
            }
        }

        return out.toByteArray()
    }

    private class ParsedForm {
        val otpFieldIds = mutableListOf<AutofillId>()
        var webDomain: String? = null
    }

    private fun logAutofillTelemetry(
        status: String,
        detail: String,
        metadata: Map<String, Any?> = emptyMap(),
    ) {
        val event = JSONObject()
            .put("action", "android_autofill_match")
            .put("status", status)
            .put("detail", detail)
            .put("created_at", System.currentTimeMillis())

        val metadataJson = JSONObject()
        metadata.forEach { (key, value) ->
            metadataJson.put(key, value)
        }
        event.put("metadata", metadataJson)

        AutofillSyncStore.appendTelemetryEvent(this, event)
    }

    private fun JSONArray?.toStringList(): List<String> {
        if (this == null) return emptyList()
        val list = mutableListOf<String>()
        for (i in 0 until length()) {
            val value = optString(i, "").trim()
            if (value.isNotEmpty()) {
                list.add(value)
            }
        }
        return list
    }

    private data class AutofillAccount(
        val id: String,
        val issuer: String,
        val label: String,
        val tags: List<String>,
        val secretB32: String,
        val algorithm: String,
        val digits: Int,
        val period: Int,
        val isHotp: Boolean,
    )
}
