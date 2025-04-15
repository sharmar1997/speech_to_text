package com.example.speech_text_app
import android.os.Bundle
import android.speech.tts.TextToSpeech
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private lateinit var tts: TextToSpeech
    private var isTtsInitialized = false

    private val CHANNEL = "com.example.tts"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        tts = TextToSpeech(this, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "speakText") {
                val text = call.argument<String>("text")
                if (isTtsInitialized && text != null) {
                    tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
                    result.success("Speaking")
                } else {
                    result.error("UNAVAILABLE", "TTS not ready or text is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        isTtsInitialized = (status == TextToSpeech.SUCCESS)
        if (isTtsInitialized) {
            tts.language = Locale.US
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        tts.stop()
        tts.shutdown()
    }
}

