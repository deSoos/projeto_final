package com.example.projeto_final

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.projeto_final/haptic"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val duration = call.argument<Int>("duration") ?: 200
                        vibrateAlarm(duration.toLong())
                        result.success(null)
                    }
                    "vibratePattern" -> {
                        val pattern = call.argument<List<Int>>("pattern")
                            ?.map { it.toLong() }
                            ?.toLongArray()
                            ?: longArrayOf(0, 200)
                        vibratePatternAlarm(pattern)
                        result.success(null)
                    }
                    "cancel" -> {
                        getVibrator().cancel()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // AudioAttributes with USAGE_ALARM makes the vibration bypass silent/DND
    // on most Android devices including Samsung One UI.
    private val alarmAudioAttributes: AudioAttributes by lazy {
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun vibrateAlarm(durationMs: Long) {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
            vibrator.vibrate(effect, alarmAudioAttributes)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }

    private fun vibratePatternAlarm(pattern: LongArray) {
        val vibrator = getVibrator()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(pattern, -1) // -1 = no repeat
            vibrator.vibrate(effect, alarmAudioAttributes)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }
}