package com.mhz.savegallery.saver_gallery

import android.content.Context
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result as MethodResult

abstract class SaverDelegate(protected val context: Context) {
    open fun onReady() {}

    abstract fun saveImageToGallery(
        image: ByteArray,
        quality: Int,
        filename: String,
        extension: String,
        relativePath: String,
        existNotSave: Boolean,
        result: MethodResult
    )

    abstract fun saveFileToGallery(
        path: String, filename: String, relativePath: String,
        existNotSave: Boolean, result: MethodResult
    )

    open fun onClose() {}
}