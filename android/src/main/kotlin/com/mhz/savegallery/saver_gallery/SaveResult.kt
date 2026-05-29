package com.mhz.savegallery.saver_gallery

class SaveResultModel(
    var isSuccess: Boolean,
    var errorMessage: String? = null,
    var savedUri: String? = null,
    var savedUris: List<String> = emptyList()
) {
    fun toHashMap(): HashMap<String, Any?> {
        val hashMap = HashMap<String, Any?>()
        hashMap["isSuccess"] = isSuccess
        hashMap["errorMessage"] = errorMessage
        hashMap["savedUri"] = savedUri
        hashMap["savedUris"] = if (savedUris.isNotEmpty()) savedUris else savedUri?.let { listOf(it) }.orEmpty()
        return hashMap
    }
}
