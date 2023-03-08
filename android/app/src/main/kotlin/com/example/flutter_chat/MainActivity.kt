package com.example.flutter_chat

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap;
import java.util.Map;
import android.net.ProxyInfo;
import android.content.Context;
import android.net.ConnectivityManager;


class MainActivity: FlutterActivity() {
    private val CHANNEL = "system_proxy"
    private var manager: ConnectivityManager? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getProxySettings") {
                val data = getProxy()
                if (data != null) {
                    result.success(data)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getProxy(): String {
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        var defaultProxy = manager.getDefaultProxy()
        if (defaultProxy != null) {
            return "${defaultProxy.getHost()}:${defaultProxy.getPort()}"
        } else {
            return ""
        }
    }
}