package com.mhz.savegallery.saver_gallery

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.text.TextUtils
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.lang.RuntimeException

/** SaverGalleryPlugin */
class SaverGalleryPlugin : FlutterPlugin, MethodCallHandler {
    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null

    private lateinit var channel: MethodChannel

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes") ?: return
                val quality = call.argument<Int>("quality") ?: return
                val fileName = call.argument<String>("fileName")!!
                val existsDelete = call.argument<Boolean>("existsDelete")!!
                val extension = call.argument<String>("extension")!!
                //部分国内厂商修改目录名
                val relativePath = call.argument<String>("relativePath")!!
                result.success(
                    saveImageToGallery(
                        BitmapFactory.decodeByteArray(
                            image,
                            0,
                            image.size
                        ), quality, extension, fileName, existsDelete, relativePath
                    )
                )
            }
            "saveFileToGallery" -> {
                val path = call.argument<String>("path")!!
                result.success(saveFileToGallery(path))
            }
            else -> result.notImplemented()
        }

    }


    private fun generateUri(extension: String, fileName: String, relativePath: String): Uri {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            var uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

            val values = ContentValues()
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            val mimeType = getMIMEType(extension)
            if (!TextUtils.isEmpty(mimeType)) {
                values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                if (mimeType!!.startsWith("video")) {
                    uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                }
            }
            return applicationContext?.contentResolver?.insert(uri, values)!!
        } else {
            val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator + relativePath
            val appDir = File(storePath)
            if (!appDir.exists()) {
                appDir.mkdir()
            }
            return Uri.fromFile(File(appDir, fileName))
        }
    }

    private fun getMIMEType(extension: String): String? {
        var type: String? = null;
        if (!TextUtils.isEmpty(extension)) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase())
        }
        return type
    }

    private fun saveImageToGallery(
        bmp: Bitmap,
        quality: Int,
        extension: String,
        fileName: String,
        existsDelete: Boolean,
        relativePath: String,
    ): HashMap<String, Any?> {
        ///如果存在,并且不需要删除
        return try {
            val fileUri = generateUri(extension, fileName, relativePath)
            val context = applicationContext
            val fos = context?.contentResolver?.openOutputStream(fileUri)!!
            println("ImageGallerySaverPlugin $quality")
            bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
            fos.flush()
            fos.close()
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
            bmp.recycle()
            SaveResultModel(
                fileUri.toString().isNotEmpty(),
                fileUri.toString(),
                null
            ).toHashMap()
        } catch (e: IOException) {
            SaveResultModel(false, null, e.toString()).toHashMap()
        }

    }

    private fun saveFileToGallery(path: String): HashMap<String, Any?> {
        val context = applicationContext
        return try {
            val originalFile = File(path)
            val fileUri = generateUri(originalFile.extension, path, "")

            val outputStream = context?.contentResolver?.openOutputStream(fileUri)!!
            val fileInputStream = FileInputStream(originalFile)

            val buffer = ByteArray(10240)
            var count: Int
            while (fileInputStream.read(buffer).also { count = it } > 0) {
                outputStream.write(buffer, 0, count)
            }

            outputStream.flush()
            outputStream.close()
            fileInputStream.close()

            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
            SaveResultModel(fileUri.toString().isNotEmpty(), fileUri.toString(), null).toHashMap()
        } catch (e: IOException) {
            SaveResultModel(false, null, e.toString()).toHashMap()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
        methodChannel!!.setMethodCallHandler(null);
        methodChannel = null;
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
        this.applicationContext = applicationContext
        methodChannel = MethodChannel(messenger, "saver_gallery")
        methodChannel!!.setMethodCallHandler(this)
    }

}

class SaveResultModel(
    var isSuccess: Boolean,
    var filePath: String? = null,
    var errorMessage: String? = null
) {
    fun toHashMap(): HashMap<String, Any?> {
        val hashMap = HashMap<String, Any?>()
        hashMap["isSuccess"] = isSuccess
        hashMap["filePath"] = filePath
        hashMap["errorMessage"] = errorMessage
        return hashMap
    }
}
