package com.mhz.savegallery.saver_gallery

import android.os.Environment

internal data class LegacyRelativePath(
    val publicDirectory: String,
    val childPath: String?
)

internal object LegacyRelativePathResolver {
    private val publicDirectoryAliases = mapOf(
        "DCIM" to Environment.DIRECTORY_DCIM,
        "Documents" to Environment.DIRECTORY_DOCUMENTS,
        "Download" to Environment.DIRECTORY_DOWNLOADS,
        "Downloads" to Environment.DIRECTORY_DOWNLOADS,
        "Movies" to Environment.DIRECTORY_MOVIES,
        "Music" to Environment.DIRECTORY_MUSIC,
        "Pictures" to Environment.DIRECTORY_PICTURES
    )

    fun resolve(relativePath: String, mimeType: String?): LegacyRelativePath {
        val defaultDirectory = defaultDirectoryForMimeType(mimeType)
        val normalizedPath = normalize(relativePath)

        if (normalizedPath.isEmpty()) {
            return LegacyRelativePath(defaultDirectory, null)
        }

        val segments = normalizedPath.split("/")
        val publicDirectory = publicDirectoryAliases[segments.first()]

        return if (publicDirectory != null) {
            LegacyRelativePath(
                publicDirectory = publicDirectory,
                childPath = segments.drop(1).joinToString("/").ifEmpty { null }
            )
        } else {
            LegacyRelativePath(
                publicDirectory = defaultDirectory,
                childPath = normalizedPath
            )
        }
    }

    private fun normalize(relativePath: String): String {
        val path = relativePath.trim().replace('\\', '/')

        require(!path.startsWith("/")) {
            "androidRelativePath must be relative"
        }
        require(!Regex("^[A-Za-z]:").containsMatchIn(path)) {
            "androidRelativePath must be relative"
        }

        val normalizedPath = path.trim('/')
        if (normalizedPath.isEmpty()) {
            return ""
        }

        val segments = normalizedPath.split("/")
        require(segments.none { it.isEmpty() || it == "." || it == ".." }) {
            "androidRelativePath contains unsafe path segments"
        }

        return normalizedPath
    }

    private fun defaultDirectoryForMimeType(mimeType: String?): String {
        return when {
            mimeType?.startsWith("image/") == true -> Environment.DIRECTORY_PICTURES
            mimeType?.startsWith("video/") == true -> Environment.DIRECTORY_MOVIES
            mimeType?.startsWith("audio/") == true -> Environment.DIRECTORY_MUSIC
            else -> Environment.DIRECTORY_DOWNLOADS
        }
    }
}
