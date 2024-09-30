package com.mhz.savegallery.saver_gallery

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result as MethodResult

class SaverGalleryPlugin : FlutterPlugin, MethodCallHandler {

    private var context: Context? = null
    private var delegate: SaverDelegate? = null
    private var channel: MethodChannel? = null

    companion object {
        private const val CHANNEL_NAME = "saver_gallery"
    }

    // Method to handle Flutter method calls.
    override fun onMethodCall(call: MethodCall, result: MethodResult) {
        when (call.method) {
            "saveImageToGallery" -> handleSaveImage(call, result)
            "saveFileToGallery" -> handleSaveFile(call, result)
            else -> result.notImplemented()
        }
    }

    // Handles saving images to the gallery.
    private fun handleSaveImage(call: MethodCall, result: MethodResult) {
        val imageBytes = call.argument<ByteArray>("imageBytes") ?: run {
            result.error("INVALID_ARGUMENT", "imageBytes is required", null)
            return
        }
        val quality = call.argument<Int>("quality") ?: 100
        val filename = call.argument<String>("name") ?: run {
            result.error("INVALID_ARGUMENT", "Filename is required", null)
            return
        }
        val extension = call.argument<String>("extension") ?: run {
            result.error("INVALID_ARGUMENT", "File extension is required", null)
            return
        }
        val relativePath = call.argument<String>("relativePath") ?: "Pictures"
        val skipIfExists = call.argument<Boolean>("skipIfExists") ?: false

        delegate?.saveImageToGallery(
            image = imageBytes,
            quality = quality,
            filename = filename,
            extension = extension,
            relativePath = relativePath,
            skipIfExists = skipIfExists,
            result = result
        )
    }

    // Handles saving files to the gallery.
    private fun handleSaveFile(call: MethodCall, result: MethodResult) {
        val filePath = call.argument<String>("path") ?: run {
            result.error("INVALID_ARGUMENT", "File path is required", null)
            return
        }
        val filename = call.argument<String>("name") ?: run {
            result.error("INVALID_ARGUMENT", "Filename is required", null)
            return
        }
        val relativePath = call.argument<String>("relativePath") ?: "Download"
        val skipIfExists = call.argument<Boolean>("skipIfExists") ?: false

        delegate?.saveFileToGallery(
            filePath = filePath,
            filename = filename,
            relativePath = relativePath,
            skipIfExists = skipIfExists,
            result = result
        )
    }

    // Called when the plugin is attached to the Flutter engine.
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)

        // Create the appropriate delegate based on Android version.
        delegate = constructDelegate(context!!)
        delegate?.onReady()
    }

    // Called when the plugin is detached from the Flutter engine.
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        delegate?.onClose()
        delegate = null
        context = null
    }

    // Constructs a delegate based on the Android version.
    private fun constructDelegate(context: Context): SaverDelegate {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            SaverDelegateDefault(context)
        } else {
            SaverDelegateAndroidT(context)
        }
    }
}
