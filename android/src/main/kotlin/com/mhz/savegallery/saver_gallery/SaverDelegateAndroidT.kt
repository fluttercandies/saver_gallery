package com.mhz.savegallery.saver_gallery

import android.Manifest
import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import android.text.TextUtils
import androidx.core.content.ContextCompat
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.getMIMEType
import com.mhz.savegallery.saver_gallery.utils.MediaStoreUtils.scanUri
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import io.flutter.plugin.common.MethodChannel.Result as MethodResult

class SaverDelegateAndroidT(context: Context) : SaverDelegate(context) {
    private val mainScope = CoroutineScope(Dispatchers.IO)
//    private fun checkReadStoragePermission(): Boolean {
//        return ContextCompat.checkSelfPermission(
//            context,
//            Manifest.permission.READ_EXTERNAL_STORAGE
//        ) == PackageManager.PERMISSION_GRANTED
//    }

    override fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        filename: String,
        extension: String,
        relativePath: String,
        existNotSave: Boolean,
        result: MethodResult
    ) {
        mainScope.launch(Dispatchers.IO) {
            ///此刻要判断是否拥有存储权限不然没法做到如果存在就不保存
            if (existNotSave) {
//                if (checkReadStoragePermission()) {
                    if (exist(relativePath, filename)) {
                        result.success(
                            SaveResultModel(
                                true
                            ).toHashMap()
                        )
                        return@launch
                    }
//                } else {
//                    ///没有权限
//                    result.success(
//                        SaveResultModel(
//                            false,
//                            "existNotSave must have read storage permission when it is true"
//                        ).toHashMap()
//                    )
//                    return@launch
//                }

            }
            val uri = generateUri(extension, filename, relativePath)
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

    override fun saveFileToGallery(
        path: String, filename: String, relativePath: String,
        existNotSave: Boolean, result: MethodResult
    ) {
        mainScope.launch(Dispatchers.IO) {
            ///此刻要判断是否拥有存储权限不然没法做到如果存在就不保存
            if (existNotSave) {
//                if (checkReadStoragePermission()) {
                    if (exist(relativePath, filename)) {
                        result.success(
                            SaveResultModel(
                                true
                            ).toHashMap()
                        )
                        return@launch
                    }
//                } else {
//                    ///没有权限
//                    result.success(
//                        SaveResultModel(
//                            false,
//                            "existNotSave must have read storage permission when it is true"
//                        ).toHashMap()
//                    )
//                    return@launch
//                }

            }
            val file = File(path)
            val extension = file.extension
            val mimeType = getMIMEType(extension)

            if (mimeType.isNullOrEmpty()) {
                result.success(
                    SaveResultModel(
                        false,
                        "Unsupported file"
                    ).toHashMap()
                )
                return@launch
            }

            val uri = generateUri(extension, filename, relativePath)

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


    @SuppressLint("InlinedApi")
    private fun exist(relativePath: String, fileName: String): Boolean {
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
            val query = context.contentResolver.query(
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
    }

    @SuppressLint("InlinedApi")
    private fun generateUri(extension: String, fileName: String, relativePath: String): Uri {

        var uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        val values = ContentValues()
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
        values.put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
        val mimeType = getMIMEType(extension)
        if (!TextUtils.isEmpty(mimeType)) {
            values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            if (mimeType!!.startsWith("video")) {
                uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            } else if (mimeType.startsWith("audio")) {
                uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }
        }
        return context.contentResolver.insert(uri, values)!!
    }

    override fun onClose() {
        super.onClose()
        mainScope.cancel()
    }

}