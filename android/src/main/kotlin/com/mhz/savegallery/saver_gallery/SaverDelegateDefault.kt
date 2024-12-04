package com.mhz.savegallery.saver_gallery

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.getMIMEType
import android.os.Build

/**
 * Implementation of [SaverDelegate] for default saving behavior.
 * Handles saving images and files to the device's gallery.
 *
 * @param context The application context.
 */
class SaverDelegateDefault(context: Context) : SaverDelegate(context) {

    private val mainScope = CoroutineScope(Dispatchers.IO)

    /**
     * Saves an image to the gallery.
     *
     * @param imageBytes The image data in bytes.
     * @param quality The quality of the image (applicable for JPEG).
     * @param fileName The name of the file to save.
     * @param extension The file extension (e.g., "jpg", "png").
     * @param relativePath The relative path in the gallery where the file will be saved.
     * @param skipIfExists If true, skips saving if the file already exists.
     * @param result The method result to communicate success or failure.
     */
    override fun saveImageToGallery(
        imageBytes: ByteArray,
        quality: Int,
        fileName: String,
        extension: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodChannel.Result
    ) {
        mainScope.launch {
            val saveResult = saveImage(imageBytes, quality, extension, fileName, skipIfExists, relativePath)
            result.success(saveResult)
        }
    }

    /**
     * Saves a file to the gallery.
     *
     * @param filePath The path of the file to be saved.
     * @param fileName The name of the file to save in the gallery.
     * @param relativePath The relative path in the gallery where the file will be saved.
     * @param skipIfExists If true, skips saving if the file already exists.
     * @param result The method result to communicate success or failure.
     */
    override fun saveFileToGallery(
        filePath: String,
        fileName: String,
        relativePath: String,
        skipIfExists: Boolean,
        result: MethodChannel.Result
    ) {
        mainScope.launch {
            val saveResult = saveFile(filePath, fileName, relativePath, skipIfExists)
            result.success(saveResult)
        }
    }

    /**
     * Saves an image to the gallery with the specified parameters.
     *
     * @param imageBytes The image data in bytes.
     * @param quality The quality of the image (applicable for JPEG).
     * @param extension The file extension (e.g., "jpg", "png").
     * @param fileName The name of the file to save.
     * @param skipIfExists If true, skips saving if the file already exists.
     * @param relativePath The relative path in the gallery where the file will be saved.
     * @return A [SaveResultModel] indicating the outcome of the save operation.
     */
    private fun saveImage(
        imageBytes: ByteArray,
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
                    saveBitmapToStream(imageBytes, quality, extension, outputStream)
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

    /**
     * Saves a file from the specified path to the gallery.
     *
     * @param filePath The path of the file to be saved.
     * @param fileName The name of the file to save in the gallery.
     * @param relativePath The relative path in the gallery where the file will be saved.
     * @param skipIfExists If true, skips saving if the file already exists.
     * @return A [SaveResultModel] indicating the outcome of the save operation.
     */
    private fun saveFile(
        filePath: String,
        fileName: String,
        relativePath: String,
        skipIfExists: Boolean
    ): HashMap<String, Any?> {
        return if (skipIfExists && doesFileExist(relativePath, fileName)) {
            SaveResultModel(true, null).toHashMap()
        } else {
            try {
                val fileUri = generateFileUri(fileName, relativePath)
                FileInputStream(File(filePath)).use { fileInputStream ->
                    context.contentResolver?.openOutputStream(fileUri)?.use { outputStream ->
                        val buffer = ByteArray(1024)
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
                e.printStackTrace()
                SaveResultModel(false, "Failed to save file: ${e.message}").toHashMap()
            }
        }
    }

    /**
     * Generates a URI for a new file in the given relative path.
     *
     * @param fileName The name of the file.
     * @param relativePath The relative path in the gallery.
     * @return The URI where the file will be saved.
     * @throws IOException If the URI cannot be created.
     */
    @SuppressLint("InlinedApi")
    private fun generateFileUri(fileName: String, relativePath: String): Uri {
        val mimeType = getMIMEType(fileName.substringAfterLast('.', ""))
        val isVideo = mimeType?.startsWith("video")==true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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

            val resolvedRelativePath = if (relativePath.isEmpty()) defaultRelativePath else relativePath

            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.RELATIVE_PATH, resolvedRelativePath)
                if (!mimeType.isNullOrEmpty()) put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            }

            return context.contentResolver.insert(contentUri, contentValues)
                ?: throw IOException("Failed to create Media URI for $fileName")
        }else{
            val storePath =
                Environment.getExternalStoragePublicDirectory(when {
                    isVideo -> Environment.DIRECTORY_MOVIES
                    else -> Environment.DIRECTORY_PICTURES
                }).absolutePath
            val appDir = File(storePath).apply {
                if (!exists()) {
                    mkdir()
                }
            }
            val file =
                File(appDir, fileName)
            return Uri.fromFile(file)
        }
    }

    /**
     * Checks if a file with the given name already exists in the specified relative path.
     *
     * @param relativePath The relative path in the gallery.
     * @param fileName The name of the file to check.
     * @return True if the file exists, false otherwise.
     */
    @SuppressLint("InlinedApi")
    private fun doesFileExist(relativePath: String, fileName: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val projection = arrayOf(MediaStore.Images.Media._ID)
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
                    cursor.count > 0
                } ?: false
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        } else {
            val mimeType = getMIMEType(fileName.substringAfterLast('.', ""))
            val isVideo = mimeType?.startsWith("video")==true
            val storePath =
                Environment.getExternalStoragePublicDirectory(when {
                    isVideo -> Environment.DIRECTORY_MOVIES
                    else -> Environment.DIRECTORY_PICTURES
                }).absolutePath
            val appDir = File(storePath).apply {
                if (!exists()) {
                    mkdir()
                }
            }
            val file =
                File(appDir, fileName)
            return file.exists()
        }
    }

    /**
     * Saves a bitmap to the provided output stream.
     *
     * @param imageBytes The image data in bytes.
     * @param quality The quality of the image (applicable for JPEG).
     * @param extension The file extension (e.g., "jpg", "png").
     * @param outputStream The output stream to write the image data.
     */
    private fun saveBitmapToStream(
        imageBytes: ByteArray,
        quality: Int,
        extension: String,
        outputStream: java.io.OutputStream
    ) {
        if (extension.equals("gif", ignoreCase = true)) {
            outputStream.write(imageBytes)
        } else {
            var bitmap: Bitmap? = null
            try {
                bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                val format = if (extension.equals("png", ignoreCase = true)) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
                bitmap.compress(format, quality, outputStream)
            } finally {
                bitmap?.recycle()
            }
        }
    }

    /**
     * Notifies the media gallery about the newly added file.
     *
     * @param fileUri The URI of the file to notify.
     */
    private fun notifyGallery(fileUri: Uri) {
        context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
    }

    /**
     * Releases resources when the delegate is closed.
     */
    override fun onClose() {
        super.onClose()
        mainScope.cancel()
    }
}
