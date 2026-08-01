package id.uroo.usahaku

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "id.uroo.usahaku/audio"
    private var player: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playSuccess" -> {
                    playSuccessSound()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Memutar suara "cengkereng" dari res/raw/cha_ching.mp3 sekali.
    private fun playSuccessSound() {
        try {
            player?.release()
            player = MediaPlayer.create(this, R.raw.cha_ching).apply {
                setOnCompletionListener { p ->
                    p.release()
                    if (player === p) player = null
                }
                start()
            }
        } catch (_: Exception) {
            // Abaikan jika audio gagal diputar — tidak mengganggu transaksi.
        }
    }
}
