package com.robby031.genauth

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
	private val autofillChannel = "genauth/autofill_sync"
	private val autofillSettingsChannel = "genauth/autofill_settings"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, autofillChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"syncAccounts" -> {
						val rawAccounts = call.argument<List<*>>("accounts")
						if (rawAccounts == null) {
							AutofillSyncStore.saveAccountsJson(applicationContext, "[]")
							result.success(null)
							return@setMethodCallHandler
						}

						val jsonArray = JSONArray()
						rawAccounts.forEach { item ->
							jsonArray.put(item)
						}

						AutofillSyncStore.saveAccountsJson(
							applicationContext,
							jsonArray.toString(),
						)
						result.success(null)
					}

					"clearAccounts" -> {
						AutofillSyncStore.clear(applicationContext)
						result.success(null)
					}

					"drainTelemetry" -> {
						val data = AutofillSyncStore.drainTelemetryJson(applicationContext)
						result.success(data)
					}

					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, autofillSettingsChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"openAutofillSettings" -> {
						result.success(openAutofillSettings())
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun openAutofillSettings(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
			return false
		}

		val component = ComponentName(this, GenAuthAutofillService::class.java)

		val requestIntent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE).apply {
			putExtra(Settings.EXTRA_AUTOFILL_SERVICE_COMPONENT_NAME, component)
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		if (requestIntent.resolveActivity(packageManager) != null) {
			startActivity(requestIntent)
			return true
		}

		val fallbackIntent = Intent("android.settings.AUTOFILL_SETTINGS").apply {
			data = Uri.parse("package:$packageName")
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		if (fallbackIntent.resolveActivity(packageManager) != null) {
			startActivity(fallbackIntent)
			return true
		}

		return false
	}
}
