package com.mhz.savegallery.saver_gallery

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.getMIMEType
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.scanUri
import io.flutter.plugin.common.MethodChannel.Result as MethodResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import java.io.IOException

// Implementation of the SaverDelegate for Android that handles saving images and files to the gallery.
class SaverDelegateAndroidT(context: Context) : SaverDelegate(context) {

    private val mainScope = CoroutineScope(Dispatchers.IO)

    override fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        fileName: String,
        extension: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodResult
    ) {
        mainScope.launch {
            // Check if the file already exists in the gallery, if `skipIfExists` is true.
            if (skipIfExists && fileExistsInGallery(relativePath, fileName)) {
                result.success(SaveResultModel(true).toHashMap())
                return@launch
            }

            // Create a URI to save the image in the gallery.
            val uri = createMediaUri(extension, fileName, relativePath)
            val isSuccess = saveImage(image, quality, extension, uri)

            // Scan and make the saved image visible in the gallery.
            scanUri(context, uri, "image/$extension")
            result.success(SaveResultModel(isSuccess, if (!isSuccess) "Couldn't save the image" else null).toHashMap())
        }
    }

    override fun saveFileToGallery(
        filePath: String,
        fileName: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodResult
    ) {
        mainScope.launch {
            // Check if the file already exists in the gallery, if `skipIfExists` is true.
            if (skipIfExists && fileExistsInGallery(relativePath, fileName)) {
                result.success(SaveResultModel(true).toHashMap())
                return@launch
            }

            val file = File(filePath)
            val extension = file.extension
            val mimeType = getMIMEType(extension)

            if (mimeType.isNullOrEmpty()) {
                result.success(SaveResultModel(false, "Unsupported file type").toHashMap())
                return@launch
            }

            // Create a URI to save the file in the gallery.
            val uri = createMediaUri(extension, fileName, relativePath)
            val isSuccess = saveFile(file, uri)

            // Scan and make the saved file visible in the gallery.
            scanUri(context, uri, mimeType)
            result.success(SaveResultModel(isSuccess, if (!isSuccess) "Couldn't save the file" else null).toHashMap())
        }
    }

    // Saves the image to the given URI.
    private fun saveImage(imageBytes: ByteArray, quality: Int, extension: String, uri: Uri): Boolean {
        return try {
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                if (extension.equals("gif", ignoreCase = true)) {
                    outputStream.write(imageBytes)
                } else {
                    val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                    return try {
                        val format = if (extension.equals("png", ignoreCase = true)) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
                        bitmap.compress(format, quality, outputStream)
                        outputStream.flush()
                        true
                    } finally {
                        bitmap.recycle() // Properly release the Bitmap's memory
                    }
                }
                outputStream.flush()
                true
            } ?: false
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    // Saves a file to the specified URI.
    private fun saveFile(file: File, uri: Uri): Boolean {
        return try {
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(file).use { fileInputStream ->
                    val buffer = ByteArray(1024)
                    var bytesRead: Int
                    while (fileInputStream.read(buffer).also { bytesRead = it } > 0) {
                        outputStream.write(buffer, 0, bytesRead)
                    }
                    outputStream.flush()
                }
                true
            } ?: false
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    // Creates a URI for media content with the given parameters.
    @SuppressLint("InlinedApi")
    private fun createMediaUri(extension: String, fileName: String, relativePath: String?): Uri {
        val mimeType = getMIMEType(extension)

        // Determine the type of content URI based on MIME type.
        val contentUri = when {
            mimeType?.startsWith("video") == true -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            mimeType?.startsWith("audio") == true -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

        // Set a default relative path if it's null or empty.
        val defaultRelativePath = when {
            mimeType?.startsWith("video") == true -> Environment.DIRECTORY_MOVIES
            mimeType?.startsWith("audio") == true -> Environment.DIRECTORY_MUSIC
            else -> Environment.DIRECTORY_PICTURES
        }

        val resolvedRelativePath = if (relativePath.isNullOrEmpty()) defaultRelativePath else relativePath

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.RELATIVE_PATH, resolvedRelativePath)
            if (!mimeType.isNullOrEmpty()) put(MediaStore.Images.Media.MIME_TYPE, mimeType)
        }

        return context.contentResolver.insert(contentUri, contentValues)
            ?: throw IOException("Failed to create Media URI for $fileName")
    }

    // Checks if a file with the given name already exists in the specified relative path.
    @SuppressLint("InlinedApi")
    private fun fileExistsInGallery(relativePath: String, fileName: String): Boolean {
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.RELATIVE_PATH} LIKE ? AND ${MediaStore.Images.Media.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf("%$relativePath%", fileName)
        val sortOrder = "${MediaStore.Images.Media.DISPLAY_NAME} ASC"

        return try {
            context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )?.use { cursor ->
                cursor.count > 0
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    // Releases resources when the delegate is closed.
    override fun onClose() {
        super.onClose()
        mainScope.cancel()
    }
}
