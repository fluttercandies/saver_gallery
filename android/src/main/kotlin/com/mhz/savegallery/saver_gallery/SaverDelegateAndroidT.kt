package com.mhz.savegallery.saver_gallery

import android.annotation.SuppressLint
import android.content.ContentUris
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
            val mimeType = getMIMEType(extension) ?: "image/$extension"
            val existingUri = if (skipIfExists) findExistingUri(relativePath, fileName, mimeType) else null
            if (skipIfExists && existingUri != null) {
                result.success(SaveResultModel(true, savedUri = existingUri.toString()).toHashMap())
                return@launch
            }

            // Create a URI to save the image in the gallery.
            val uri = createMediaUri(extension, fileName, relativePath) ?: run {
                result.success(SaveResultModel(false, "Couldn't create the image URI").toHashMap())
                return@launch
            }
            val isSuccess = saveImage(image, quality, extension, uri)

            // Scan and make the saved image visible in the gallery.
            scanUri(context, uri, "image/$extension")
            result.success(SaveResultModel(isSuccess, if (!isSuccess) "Couldn't save the image" else null, savedUri = if (isSuccess) uri.toString() else null).toHashMap())
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
            val file = File(filePath)
            val extension = file.extension
            val mimeType = getMIMEType(extension)

            if (mimeType.isNullOrEmpty()) {
                result.success(SaveResultModel(false, "Unsupported file type").toHashMap())
                return@launch
            }

            val existingUri = if (skipIfExists) findExistingUri(relativePath, fileName, mimeType) else null
            if (skipIfExists && existingUri != null) {
                result.success(SaveResultModel(true, savedUri = existingUri.toString()).toHashMap())
                return@launch
            }

            // Create a URI to save the file in the gallery.
            val uri = createMediaUri(extension, fileName, relativePath) ?: run {
                result.success(SaveResultModel(false, "Couldn't create the file URI").toHashMap())
                return@launch
            }
            val isSuccess = saveFile(file, uri)

            // Scan and make the saved file visible in the gallery.
            scanUri(context, uri, mimeType)
            result.success(SaveResultModel(isSuccess, if (!isSuccess) "Couldn't save the file" else null, savedUri = if (isSuccess) uri.toString() else null).toHashMap())
        }
    }

    override fun saveFilesToGallery(
        files: List<Map<String, String>>,
        skipIfExists: Boolean,
        result: MethodResult
    ) {
        mainScope.launch {
            var successCount = 0
            var failureCount = 0
            val errors = mutableListOf<String>()
            val savedUris = mutableListOf<String>()

            for (fileData in files) {
                val filePath = fileData["filePath"] ?: continue
                val fileName = fileData["fileName"] ?: continue
                val relativePath = fileData["relativePath"] ?: "Download"

                try {
                    val file = File(filePath)
                    val extension = file.extension
                    val mimeType = getMIMEType(extension)

                    if (mimeType.isNullOrEmpty()) {
                        failureCount++
                        errors.add("$fileName: Unsupported file type")
                        continue
                    }

                    // Check if the file already exists in the gallery, if `skipIfExists` is true.
                    val existingUri = if (skipIfExists) findExistingUri(relativePath, fileName, mimeType) else null
                    if (skipIfExists && existingUri != null) {
                        savedUris.add(existingUri.toString())
                        successCount++
                        continue
                    }

                    // Create a URI to save the file in the gallery.
                    val uri = createMediaUri(extension, fileName, relativePath)
                    if (uri == null) {
                        failureCount++
                        errors.add("$fileName: Failed to create file URI")
                        continue
                    }
                    val isSuccess = saveFile(file, uri)

                    if (isSuccess) {
                        // Scan and make the saved file visible in the gallery.
                        scanUri(context, uri, mimeType)
                        savedUris.add(uri.toString())
                        successCount++
                    } else {
                        failureCount++
                        errors.add("$fileName: Failed to save file")
                    }
                } catch (e: Exception) {
                    failureCount++
                    errors.add("$fileName: ${e.message}")
                }
            }

            val finalResult = if (failureCount == 0) {
                SaveResultModel(true, null, savedUris = savedUris).toHashMap()
            } else {
                val errorMessage = "Saved $successCount files, failed $failureCount files. Errors: ${errors.joinToString("; ")}"
                SaveResultModel(successCount > 0, errorMessage, savedUris = savedUris).toHashMap()
            }

            result.success(finalResult)
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
    private fun createMediaUri(extension: String, fileName: String, relativePath: String?): Uri? {
        val mimeType = getMIMEType(extension)

        // Determine the type of content URI based on MIME type.
        val contentUri = when {
            mimeType?.startsWith("video") == true -> {
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            }
            mimeType?.startsWith("audio") == true -> {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            }
            else -> {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            }
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
            if (!mimeType.isNullOrEmpty()) put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
        }

        return try {
            context.contentResolver.insert(contentUri, contentValues)
        } catch (e: IllegalArgumentException) {
            e.printStackTrace()
            null
        }
    }

    // Finds a file with the given name in the specified relative path.
    @SuppressLint("InlinedApi")
    private fun findExistingUri(relativePath: String, fileName: String, mimeType: String?): Uri? {
        val contentUri = when {
            mimeType?.startsWith("video") == true -> MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            mimeType?.startsWith("audio") == true -> MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else -> MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.Images.Media.RELATIVE_PATH} LIKE ? AND ${MediaStore.Images.Media.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf("%$relativePath%", fileName)
        val sortOrder = "${MediaStore.Images.Media.DISPLAY_NAME} ASC"

        return try {
            context.contentResolver.query(
                contentUri,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                    ContentUris.withAppendedId(contentUri, id)
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    // Releases resources when the delegate is closed.
    override fun onClose() {
        super.onClose()
        mainScope.cancel()
    }
}
