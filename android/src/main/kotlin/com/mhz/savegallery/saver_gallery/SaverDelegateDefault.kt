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
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.lang.Exception

class SaverDelegateDefault(context: Context) : SaverDelegate(context) {
    override fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        filename: String,
        extension: String,
        relativePath: String,
        existNotSave: Boolean,
        result: MethodChannel.Result
    ) {
        result.success(
            saveImageToGallery(
                image, quality, extension, filename,existNotSave, relativePath
            )
        )
    }

    override fun saveFileToGallery(path: String, result: MethodChannel.Result) {
        result.success(saveFileToGallery(path))
    }

    private fun generateUri(fileName: String, relativePath: String): Uri {
        @Suppress("DEPRECATION")
        val storePath =
            Environment.getExternalStorageDirectory().absolutePath + File.separator + relativePath
        val appDir = File(storePath)
        if (!appDir.exists()) {
            appDir.mkdirs()
        }
        return Uri.fromFile(File(appDir, fileName))
    }


    private fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        extension: String,
        fileName: String,
        existNotSave: Boolean,
        relativePath: String,
    ): HashMap<String, Any?> {
        ///如果存在,并且不需要删除
        return if (exist(relativePath, fileName)) {
            SaveResultModel(true, null).toHashMap()
        } else {
            try {
                val fileUri = generateUri(fileName, relativePath)
                context.contentResolver?.openOutputStream(fileUri)!!.use {
                    println("ImageGallerySaverPlugin $quality")
                    //如果是gif的话
                    if (extension == "gif") {
                        it.write(image)
                    } else {
                        var bmp: Bitmap? = null
                        try {
                            bmp = BitmapFactory.decodeByteArray(
                                image,
                                0,
                                image.size
                            )
                            bmp.compress(
                                if (extension == "png") {
                                    Bitmap.CompressFormat.PNG
                                } else {
                                    Bitmap.CompressFormat.JPEG
                                }, quality, it
                            )
                        } finally {
                            bmp?.recycle()
                        }
                    }
                    it.flush()
                    context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
                    SaveResultModel(
                        fileUri.toString().isNotEmpty(),
                        null
                    ).toHashMap()
                }
            } catch (e: IOException) {
                e.printStackTrace()
                SaveResultModel(false, e.toString()).toHashMap()
            }
        }
    }

    private fun saveFileToGallery(path: String): HashMap<String, Any?> {
        return try {
            val originalFile = File(path)
            val fileUri = generateUri(path, "")

            val outputStream = context.contentResolver?.openOutputStream(fileUri)!!
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
            SaveResultModel(fileUri.toString().isNotEmpty(), null).toHashMap()
        } catch (e: IOException) {
            SaveResultModel(false, e.toString()).toHashMap()
        }
    }


    private fun exist(relativePath: String, fileName: String): Boolean {
        val targetFile =
            File(
                File(Environment.getExternalStorageDirectory().absolutePath, relativePath),
                fileName
            )
        return targetFile.exists()
    }
}
