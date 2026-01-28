package com.store.stylester_store

import io.flutter.embedding.android.FlutterActivity
/*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import android.graphics.Bitmap
*/

class MainActivity : FlutterActivity()/*{
    private val CHANNEL = "plugins.justsoft.xyz/video_thumbnail"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "file") {
                val path = call.argument<String>("path")
                val thumbnailPath = getThumbnail(path)
                result.success(thumbnailPath)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getThumbnail(videoPath: String?): String? {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(videoPath)
            val bitmap = retriever.frameAtTime
            val file = File(cacheDir, "thumbnail.jpg")
            val outputStream = FileOutputStream(file)
            bitmap?.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
            outputStream.close()
            return file.absolutePath
        } catch (e: IOException) {
            e.printStackTrace()
        } finally {
            retriever.release()
        }
        return null
    }

}*/
