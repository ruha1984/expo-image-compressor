package expo.modules.compressor

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.webkit.MimeTypeMap
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import kotlin.math.min
import kotlin.math.roundToInt

class ExpoCompressorModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ImageCompressor")

    AsyncFunction("compress") { image: Map<String, Any>, options: Map<String, Any>? ->
      val uriString = image["uri"] as? String ?: throw CompressionException("Image uri is required")
      val context = appContext.reactContext ?: throw CompressionException("React context not available")
      val resolver = context.contentResolver

      val source = resolveBitmap(resolver, uriString)
      val original = source.bitmap

      val maxWidth = (options?.get("maxWidth") as? Number)?.toDouble()
      val maxHeight = (options?.get("maxHeight") as? Number)?.toDouble()
      val target = resizeBitmap(original, maxWidth, maxHeight)

      val quality = ((options?.get("quality") as? Number)?.toDouble() ?: 0.7).coerceIn(0.0, 1.0)
      val format = when (source.extension?.lowercase()) {
        "png" -> Bitmap.CompressFormat.PNG
        else -> Bitmap.CompressFormat.JPEG
      }
      val extension = if (format == Bitmap.CompressFormat.PNG) "png" else "jpg"

      val cacheDir = context.cacheDir
      val outputFile = File.createTempFile("compressed-", ".${extension}", cacheDir)

      val resultWidth = target.width.toDouble()
      val resultHeight = target.height.toDouble()

      FileOutputStream(outputFile).use { stream ->
        val qualityInt = (quality * 100).roundToInt().coerceIn(0, 100)
        val success = target.compress(format, qualityInt, stream)
        if (!success) {
          throw CompressionException("Failed to encode bitmap")
        }
      }

      if (target !== original) {
        original.recycle()
      }
      if (!target.isRecycled) {
        target.recycle()
      }

      mapOf(
        "uri" to Uri.fromFile(outputFile).toString(),
        "width" to resultWidth,
        "height" to resultHeight,
        "size" to outputFile.length().toDouble()
      )
    }
  }

  private data class BitmapSource(val bitmap: Bitmap, val extension: String?)

  private fun resolveBitmap(resolver: ContentResolver, uriString: String): BitmapSource {
    val uri = runCatching { Uri.parse(uriString) }.getOrNull()

    return when (uri?.scheme?.lowercase()) {
      "content" -> resolver.openInputStream(uri)?.use { input ->
        val bitmap = BitmapFactory.decodeStream(input) ?: throw CompressionException("Unable to decode bitmap from content uri")
        BitmapSource(bitmap, inferExtensionFromMime(resolver.getType(uri)))
      } ?: throw CompressionException("Unable to read content uri: $uriString")

      "file" -> loadBitmapFromFile(File(uri.path ?: throw CompressionException("Invalid file uri")))

      null -> loadBitmapFromFile(File(uriString))

      else -> throw CompressionException("Unsupported uri scheme: ${uri.scheme}")
    }
  }

  private fun loadBitmapFromFile(file: File): BitmapSource {
    if (!file.exists()) {
      throw CompressionException("File does not exist: ${file.path}")
    }

    return FileInputStream(file).use { stream ->
      val bitmap = BitmapFactory.decodeStream(stream) ?: throw CompressionException("Unable to decode bitmap from file")
      BitmapSource(bitmap, file.extension.ifEmpty { null })
    }
  }

  private fun resizeBitmap(bitmap: Bitmap, maxWidth: Double?, maxHeight: Double?): Bitmap {
    if (bitmap.width <= 0 || bitmap.height <= 0) {
      throw CompressionException("Invalid bitmap size")
    }

    val widthLimit = maxWidth ?: Double.POSITIVE_INFINITY
    val heightLimit = maxHeight ?: Double.POSITIVE_INFINITY

    if (widthLimit == Double.POSITIVE_INFINITY && heightLimit == Double.POSITIVE_INFINITY) {
      return bitmap
    }

    val scale = min(widthLimit / bitmap.width, heightLimit / bitmap.height)

    if (scale >= 1.0 || scale <= 0.0) {
      return bitmap
    }

    val targetWidth = maxOf((bitmap.width * scale).roundToInt(), 1)
    val targetHeight = maxOf((bitmap.height * scale).roundToInt(), 1)

    return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
  }

  private fun inferExtensionFromMime(mime: String?): String? {
    if (mime == null) return null
    return MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
  }
}

class CompressionException(message: String) : Exception(message)
