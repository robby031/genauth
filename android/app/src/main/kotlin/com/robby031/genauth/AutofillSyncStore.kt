package com.robby031.genauth

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray
import org.json.JSONObject

object AutofillSyncStore {
    private const val PREF_NAME = "genauth_autofill_store"
    private const val KEY_ACCOUNTS_JSON = "accounts_json"
    private const val KEY_TELEMETRY_JSON = "telemetry_json"
    private const val MAX_TELEMETRY_ITEMS = 200

    private fun prefs(context: Context): SharedPreferences {
        return try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                PREF_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        } catch (_: Throwable) {
            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        }
    }

    fun saveAccountsJson(context: Context, accountsJson: String) {
        prefs(context).edit().putString(KEY_ACCOUNTS_JSON, accountsJson).apply()
    }

    fun readAccountsJson(context: Context): String {
        return prefs(context).getString(KEY_ACCOUNTS_JSON, "[]") ?: "[]"
    }

    fun clear(context: Context) {
        prefs(context).edit()
            .remove(KEY_ACCOUNTS_JSON)
            .remove(KEY_TELEMETRY_JSON)
            .apply()
    }

    fun appendTelemetryEvent(context: Context, event: JSONObject) {
        val pref = prefs(context)
        val current = pref.getString(KEY_TELEMETRY_JSON, "[]") ?: "[]"
        val array = try {
            JSONArray(current)
        } catch (_: Throwable) {
            JSONArray()
        }

        array.put(event)
        val trimmed = if (array.length() > MAX_TELEMETRY_ITEMS) {
            val start = array.length() - MAX_TELEMETRY_ITEMS
            JSONArray().also { out ->
                for (i in start until array.length()) {
                    out.put(array.get(i))
                }
            }
        } else {
            array
        }

        pref.edit().putString(KEY_TELEMETRY_JSON, trimmed.toString()).apply()
    }

    fun drainTelemetryJson(context: Context): String {
        val pref = prefs(context)
        val data = pref.getString(KEY_TELEMETRY_JSON, "[]") ?: "[]"
        pref.edit().remove(KEY_TELEMETRY_JSON).apply()
        return data
    }
}
