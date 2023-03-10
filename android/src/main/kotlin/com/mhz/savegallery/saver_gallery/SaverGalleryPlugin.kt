package com.mhz.savegallery.saver_gallery

import android.content.Context
import android.os.Build
import android.os.Environment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result as MethodResult

class SaverGalleryPlugin : FlutterPlugin, MethodCallHandler {
    private var context: Context? = null
    private var delegate: SaverDelegate? = null
    private var channel: MethodChannel? = null
    private var binding: FlutterPluginBinding? = null

    companion object {
        private const val CHANNEL = "saver_gallery"
    }

    override fun onMethodCall(call: MethodCall, result: MethodResult) {
        when (call.method) {
            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes") ?: return
                val quality = call.argument<Int>("quality") ?: return
                val filename = call.argument<String>("name")!!
                val extension = call.argument<String>("extension")!!
                val relativePath = call.argument<String>("relativePath")!!
                delegate?.saveImageToGallery(
                    image = image,
                    quality = quality,
                    filename = filename,
                    extension = extension,
                    relativePath = relativePath,
                    result = result
                )
            }
            "saveFileToGallery" -> {
                val path = call.argument<String>("path")!!
                delegate?.saveFileToGallery(path = path, result = result)
            }
            else -> result.notImplemented()
        }

    }

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.binding = binding
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
        delegate = constructDelegate(binding.applicationContext)
        delegate?.onReady()
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        this.binding = null;
        channel?.setMethodCallHandler(null)
        channel = null
        delegate?.onClose()
        delegate = null
    }

    private fun constructDelegate(context: Context): SaverDelegate {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || Environment.isExternalStorageLegacy()) {
            SaverDelegateDefault(context)
        } else {
            SaverDelegateAndroidT(context)
        }
    }
}
