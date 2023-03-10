package com.mhz.savegallery.saver_gallery

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.provider.MediaStore
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.scanUri
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import io.flutter.plugin.common.MethodChannel.Result as MethodResult
import java.io.IOException

class SaverDelegateAndroidT(context: Context) : SaverDelegate(context) {
    private val mainScope = CoroutineScope(Dispatchers.IO)

    override fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        filename: String,
        extension: String,
        relativePath: String,
        result: MethodResult
    ) {
        mainScope.launch(Dispatchers.IO) {
            val mimeType = MediaStoreUtils.getMIMEType(extension)

            if (mimeType.isNullOrEmpty()) {
                result.success(
                    SaveResultModel(
                        false,
                        "Unsupported file"
                    ).toHashMap()
                )
                return@launch
            }

            val uri = MediaStoreUtils.createImageUri(context, filename, mimeType)
            if (uri == null) {
                result.success(
                    SaveResultModel(
                        false,
                        "Couldn't create an image Uri: $filename"
                    ).toHashMap()
                )
                return@launch
            }

            try {
                context.contentResolver.openOutputStream(uri, "w")?.use {
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
                    scanUri(context, uri, "image/$extension")
                    result.success(
                        SaveResultModel(
                            uri.toString().isNotEmpty(),
                            null
                        ).toHashMap()
                    )
                }

            } catch (e: IOException) {
                e.printStackTrace()
                result.success(
                    SaveResultModel(
                        false,
                        "Couldn't save the image\n$uri"
                    ).toHashMap()
                )
            }
        }
    }

    override fun saveFileToGallery(path: String, result: MethodResult) {
        mainScope.launch(Dispatchers.IO) {
            val file = File(path)
            val filename = file.nameWithoutExtension
            val extension = file.extension
            val mimeType = MediaStoreUtils.getMIMEType(extension)

            if (mimeType.isNullOrEmpty()) {
                result.success(
                    SaveResultModel(
                        false,
                        "Unsupported file"
                    ).toHashMap()
                )
                return@launch
            }

            val uri = if (mimeType.startsWith("image")) {
                MediaStoreUtils.createImageUri(context, filename, mimeType)
            } else if (mimeType.startsWith("video")) {
                MediaStoreUtils.createVideoUri(context, filename, mimeType)
            } else if (mimeType.startsWith("audio")) {
                MediaStoreUtils.createAudioUri(context, filename, mimeType)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStoreUtils.createDownloadUri(context, filename)
            } else {
                null
            }
            if (uri == null) {
                result.success(
                    SaveResultModel(
                        false,
                        "Couldn't create file: $filename"
                    ).toHashMap()
                )
                return@launch
            }

            try {
                context.contentResolver.openOutputStream(uri, "w")?.use { outputStream ->
                    val fileInputStream = FileInputStream(path)

                    val buffer = ByteArray(10240)
                    var count: Int
                    while (fileInputStream.read(buffer).also { count = it } > 0) {
                        outputStream.write(buffer, 0, count)
                    }

                    outputStream.flush()
                    outputStream.close()
                    fileInputStream.close()
                    scanUri(context, uri, mimeType ?: "")
                    result.success(
                        SaveResultModel(
                            uri.toString().isNotEmpty(),
                            null
                        ).toHashMap()
                    )
                }

            } catch (e: IOException) {
                e.printStackTrace()
                result.success(
                    SaveResultModel(
                        false,
                        "Couldn't save the file\n$uri"
                    ).toHashMap()
                )
            }
        }
    }

    override fun onClose() {
        super.onClose()
        mainScope.cancel()
    }
}