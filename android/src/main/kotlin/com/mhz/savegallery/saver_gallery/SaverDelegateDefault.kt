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
        result: MethodChannel.Result
    ) {
        result.success(
            saveImageToGallery(
                image, quality, extension, filename, relativePath
            )
        )
    }

    override fun saveFileToGallery(path: String, result: MethodChannel.Result) {
        result.success(saveFileToGallery(path))
    }

    private fun generateUri(extension: String, fileName: String, relativePath: String): Uri {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

            val values = ContentValues()
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            val mimeType = getMIMEType(extension)
            if (!mimeType.isNullOrEmpty()) {
                values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                if (mimeType.startsWith("video")) {
                    uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                }
            }
            return context.contentResolver?.insert(uri, values)!!
        } else {
            @Suppress("DEPRECATION")
            val storePath =
                Environment.getExternalStorageDirectory().absolutePath + File.separator + relativePath
            val appDir = File(storePath)
            if (!appDir.exists()) {
                appDir.mkdirs()
            }
            return Uri.fromFile(File(appDir, fileName))
        }
    }

    private fun getMIMEType(extension: String): String? {
        var type: String? = null;
        if (extension.isNotEmpty()) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
        }
        return type
    }

    private fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        extension: String,
        fileName: String,
        relativePath: String,
    ): HashMap<String, Any?> {
        ///如果存在,并且不需要删除
        return if (context.exist(relativePath, fileName)) {
            SaveResultModel(true, null).toHashMap()
        } else {
            try {
                val fileUri = generateUri(extension, fileName, relativePath)
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
            val fileUri = generateUri(originalFile.extension, path, "")

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
}

fun Context.exist(relativePath: String, fileName: String): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
        )
        //想不到吧？居然是这样写？
        //咕噜咕噜，这不翻源码写的出来？
        val selection = "${
            MediaStore.Images.Media.RELATIVE_PATH
        } LIKE ? AND ${
            MediaStore.Images.Media.DISPLAY_NAME
        } = ?"
        val selectionArgs = arrayOf(
            "%${
                relativePath
            }%",
            fileName,
        )
        val sortOrder = "${
            MediaStore.Images.Media.DISPLAY_NAME
        } ASC"
        return try {
            val query = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )
            val count = query?.count ?: 0
            query?.close()
            count > 0
        } catch (e: Exception) {
            false
        }
    } else {
        val targetFile =
            File(
                File(Environment.getExternalStorageDirectory().absolutePath, relativePath),
                fileName
            )
        return targetFile.exists()
    }
}