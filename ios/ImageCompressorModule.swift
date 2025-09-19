import ExpoModulesCore
import Photos
import UIKit

private struct ImageAsset: Record {
  @Field var uri: String
}

private struct CompressionOptions: Record {
  @Field var quality: Double?
  @Field var maxWidth: Double?
  @Field var maxHeight: Double?
}

private struct CompressionResult: Record {
  @Field var uri: String = ""
  @Field var width: Double = 0
  @Field var height: Double = 0
  @Field var size: Double = 0

  init() {}

  init(uri: String, width: Double, height: Double, size: Double) {
    self.uri = uri
    self.width = width
    self.height = height
    self.size = size
  }
}

public class ImageCompressorModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ImageCompressor")

    Function("compress") { (image: ImageAsset, options: CompressionOptions?) throws -> CompressionResult in
      let quality = Self.clamp(options?.quality ?? 0.7, lower: 0, upper: 1)
      let originalImage = try Self.loadImage(from: image.uri)
      let processedImage = Self.resize(image: originalImage,
                                       maxWidth: options?.maxWidth,
                                       maxHeight: options?.maxHeight)

      let encoded: (data: Data, ext: String)
      if let jpegData = processedImage.jpegData(compressionQuality: quality) {
        encoded = (jpegData, "jpg")
      } else if let pngData = processedImage.pngData() {
        encoded = (pngData, "png")
      } else {
        throw CompressionError("Unable to encode image data")
      }

      let outputURL = try Self.persist(data: encoded.data, preferredExtension: encoded.ext)
      return CompressionResult(
        uri: outputURL.absoluteString,
        width: Double(processedImage.size.width),
        height: Double(processedImage.size.height),
        size: Double(encoded.data.count)
      )
    }
  }

  private struct CompressionError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
      self.message = message
    }

    var errorDescription: String? { message }
  }

  private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
    return min(max(value, lower), upper)
  }

  private static func loadImage(from uri: String) throws -> UIImage {
    if uri.hasPrefix("ph://") {
      return try loadImageFromPhotoLibrary(uri: uri)
    }

    if let url = URL(string: uri), let scheme = url.scheme {
      guard scheme == "file" else {
        throw CompressionError("Unsupported uri scheme: \(scheme)")
      }
      return try loadImageFromFile(url)
    }

    let fileURL = URL(fileURLWithPath: uri)
    return try loadImageFromFile(fileURL)
  }

  private static func loadImageFromFile(_ url: URL) throws -> UIImage {
    do {
      let data = try Data(contentsOf: url)
      if let image = UIImage(data: data) {
        return image
      }
      throw CompressionError("Unable to decode image at \(url.path)")
    } catch {
      throw CompressionError("Failed to read image: \(error.localizedDescription)")
    }
  }

  private static func loadImageFromPhotoLibrary(uri: String) throws -> UIImage {
    let assetId = uri.replacingOccurrences(of: "ph://", with: "")
    let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

    guard let asset = results.firstObject else {
      throw CompressionError("No asset found for uri: \(uri)")
    }

    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true

    var resultImage: UIImage?
    var requestError: Error?

    PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions) { data, _, _, info in
      if let error = info?[PHImageErrorKey] as? Error {
        requestError = error
        return
      }

      if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
        requestError = CompressionError("Image request cancelled")
        return
      }

      if let data = data {
        resultImage = UIImage(data: data)
      }
    }

    if let error = requestError {
      throw CompressionError("Failed to load asset: \(error.localizedDescription)")
    }

    guard let image = resultImage else {
      throw CompressionError("Unable to decode asset data for uri: \(uri)")
    }

    return image
  }

  private static func resize(image: UIImage, maxWidth: Double?, maxHeight: Double?) -> UIImage {
    guard image.size.width > 0 && image.size.height > 0 else {
      return image
    }

    let widthLimit = maxWidth ?? Double.greatestFiniteMagnitude
    let heightLimit = maxHeight ?? Double.greatestFiniteMagnitude

    if widthLimit == Double.greatestFiniteMagnitude && heightLimit == Double.greatestFiniteMagnitude {
      return image
    }

    let scale = min(widthLimit / Double(image.size.width), heightLimit / Double(image.size.height))

    if scale >= 1 || scale <= 0 {
      return image
    }

    let newSize = CGSize(width: image.size.width * CGFloat(scale),
                         height: image.size.height * CGFloat(scale))

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage ?? image
  }

  private static func persist(data: Data, preferredExtension: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
    let filename = "compressed-\(UUID().uuidString).\(preferredExtension)"
    let outputURL = directory.appendingPathComponent(filename)

    do {
      try data.write(to: outputURL, options: .atomic)
      return outputURL
    } catch {
      throw CompressionError("Failed to write compressed image: \(error.localizedDescription)")
    }
  }
}
