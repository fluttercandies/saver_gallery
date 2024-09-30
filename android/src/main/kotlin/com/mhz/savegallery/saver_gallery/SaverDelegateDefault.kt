package com.mhz.savegallery.saver_gallery

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class SaverDelegateDefault(context: Context) : SaverDelegate(context) {

    override fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        filename: String,
        extension: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodChannel.Result
    ) {
        val saveResult = saveImage(image, quality, extension, filename, skipIfExists, relativePath)
        result.success(saveResult)
    }

    override fun saveFileToGallery(
        path: String,
        filename: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodChannel.Result
    ) {
        val saveResult = saveFile(path, filename, relativePath, skipIfExists)
        result.success(saveResult)
    }

    // Saves an image to the gallery with specified parameters.
    private fun saveImage(
        image: ByteArray,
        quality: Int,
        extension: String,
        fileName: String,
        skipIfExists: Boolean,
        relativePath: String
    ): HashMap<String, Any?> {
        return if (skipIfExists && doesFileExist(relativePath, fileName)) {
            SaveResultModel(true, null).toHashMap()
        } else {
            try {
                val fileUri = generateFileUri(fileName, relativePath)
                context.contentResolver?.openOutputStream(fileUri)?.use { outputStream ->
                    saveBitmapToStream(image, quality, extension, outputStream)
                    outputStream.flush()
                }
                notifyGallery(fileUri)
                SaveResultModel(fileUri.toString().isNotEmpty(), null).toHashMap()
            } catch (e: IOException) {
                e.printStackTrace()
                SaveResultModel(false, "Failed to save image: ${e.message}").toHashMap()
            }
        }
    }

    // Saves a file from the specified path to the gallery.
    private fun saveFile(
        path: String,
        filename: String,
        relativePath: String,
        skipIfExists: Boolean
    ): HashMap<String, Any?> {
        return if (skipIfExists && doesFileExist(relativePath, filename)) {
            SaveResultModel(true, null).toHashMap()
        } else {
            try {
                val originalFile = File(path)
                val fileUri = generateFileUri(filename, relativePath)

                FileInputStream(originalFile).use { fileInputStream ->
                    context.contentResolver?.openOutputStream(fileUri)?.use { outputStream ->
                        val buffer = ByteArray(10240)
                        var bytesRead: Int
                        while (fileInputStream.read(buffer).also { bytesRead = it } > 0) {
                            outputStream.write(buffer, 0, bytesRead)
                        }
                        outputStream.flush()
                    }
                }
                notifyGallery(fileUri)
                SaveResultModel(fileUri.toString().isNotEmpty(), null).toHashMap()
            } catch (e: IOException) {
                SaveResultModel(false, "Failed to save file: ${e.message}").toHashMap()
            }
        }
    }

    // Generates a URI for a new file in the given relative path.
    private fun generateFileUri(fileName: String, relativePath: String): Uri {
        val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator + relativePath
        val directory = File(storePath)
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return Uri.fromFile(File(directory, fileName))
    }

    // Checks if a file already exists in the specified relative path.
    private fun doesFileExist(relativePath: String, fileName: String): Boolean {
        val targetFile = File(Environment.getExternalStorageDirectory().absolutePath + File.separator + relativePath, fileName)
        return targetFile.exists()
    }

    // Saves a bitmap to the provided output stream.
    private fun saveBitmapToStream(image: ByteArray, quality: Int, extension: String, outputStream: java.io.OutputStream) {
        if (extension.equals("gif", ignoreCase = true)) {
            outputStream.write(image)
        } else {
            var bitmap: Bitmap? = null
            try {
                bitmap = BitmapFactory.decodeByteArray(image, 0, image.size)
                val format = if (extension.equals("png", ignoreCase = true)) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
                bitmap.compress(format, quality, outputStream)
            } finally {
                bitmap?.recycle()
            }
        }
    }

    // Notifies the media gallery about the newly added file.
    private fun notifyGallery(fileUri: Uri) {
        context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
    }
}
