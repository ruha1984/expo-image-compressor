# @rahimwws/expo-image-compressor

[![npm version](https://badge.fury.io/js/@rahimwws/expo-image-compressor.svg)](https://badge.fury.io/js/@rahimwws/expo-image-compressor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform image compression for Expo and React Native apps. The module provides native implementations for iOS, Android, and Web platforms with simple TypeScript bindings.

## Features

- 🚀 **Cross-platform compression** - iOS, Android, and Web support
- 📱 **Works with `ph://` library assets** or local file URIs
- 🔧 **Strict TypeScript types** for options and results
- 🌐 **Web implementation** with Canvas API and ImageBitmap support
- 🤖 **Android implementation** with native Bitmap API
- ⚡ **Fast and efficient** native implementations
- 📦 **Zero dependencies** - lightweight package
- 🎯 **Expo Modules** compatible

## Installation

```sh
npm install @rahimwws/expo-image-compressor
# or
yarn add @rahimwws/expo-image-compressor
```

Run `npx pod-install` afterwards to make sure the native module is linked in your iOS project.

### Requirements

- **iOS**: iOS 11.0+
- **Android**: API level 21+
- **Web**: Modern browsers with Canvas API support
- **Expo**: SDK 49+
- **React Native**: 0.70+
- **Node.js**: 16.0+

## Usage

### Basic Usage

```ts
import { compress, type ImageAsset } from "@rahimwws/expo-image-compressor";

const asset: ImageAsset = { uri: localUri };

const result = compress(asset, {
  quality: 0.6,
  maxWidth: 1080,
  maxHeight: 1080,
});

console.log(result.uri);
console.log(result.size); // bytes
```

### Advanced Examples

#### Compress with different quality levels

```ts
import { compress } from "@rahimwws/expo-image-compressor";

// High quality compression
const highQuality = compress(image, { quality: 0.9 });

// Medium quality compression
const mediumQuality = compress(image, { quality: 0.7 });

// Low quality compression (smaller file size)
const lowQuality = compress(image, { quality: 0.3 });
```

#### Resize images

```ts
import { compress } from "@rahimwws/expo-image-compressor";

// Resize to specific dimensions
const resized = compress(image, {
  maxWidth: 800,
  maxHeight: 600,
  quality: 0.8,
});

// Keep aspect ratio, limit width only
const widthLimited = compress(image, {
  maxWidth: 1200,
  quality: 0.7,
});
```

#### Working with photo library assets

```ts
import * as ImagePicker from "expo-image-picker";
import { compress } from "@rahimwws/expo-image-compressor";

const pickImage = async () => {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    quality: 1,
  });

  if (!result.canceled) {
    const compressed = compress(
      { uri: result.assets[0].uri },
      { quality: 0.6, maxWidth: 1080 }
    );

    console.log("Original size:", result.assets[0].fileSize);
    console.log("Compressed size:", compressed.size);
    console.log("Compressed URI:", compressed.uri);
  }
};
```

### API

#### `compress(image: ImageAsset, options?: CompressOptions): CompressResult`

| Param       | Type         | Description                                                |
| ----------- | ------------ | ---------------------------------------------------------- |
| `image`     | `ImageAsset` | Target image with a `file://` or `ph://` URI.              |
| `quality`   | `number`     | Optional JPEG quality between `0` and `1` (default `0.7`). |
| `maxWidth`  | `number`     | Optional max width in pixels.                              |
| `maxHeight` | `number`     | Optional max height in pixels.                             |

Returns a `CompressResult` containing the new `uri`, `width`, `height`, and byte `size` of the compressed image. The output file is persisted to the iOS caches directory.

> **Note**
> If the source is already smaller than the requested dimensions the original resolution is kept.

## Platform implementations

### iOS

- Handles both local `file://` URIs and `ph://` identifiers from the photo library.
- Automatically selects JPEG encoding when possible, otherwise falls back to PNG.
- Keeps aspect ratio when resizing with `maxWidth`/`maxHeight`.

### Android

- Supports `content://`, `file://` URIs and local file paths.
- Uses native Bitmap API for efficient compression and resizing.
- Automatically detects image format and applies appropriate compression.

### Web

- Uses Canvas API with ImageBitmap and HTMLImageElement support.
- Supports both JPEG and PNG output formats.
- Handles CORS-enabled images and blob URLs.

## Troubleshooting

### Common Issues

**Module not found on iOS**

- Make sure you've run `npx pod-install` after installation
- Clean and rebuild your iOS project: `npx expo run:ios --clear`

**Permission denied for photo library**

- Add `NSPhotoLibraryUsageDescription` to your `Info.plist`
- Request permissions using `expo-image-picker` before compression

**Web platform returns original image**

- This is expected behavior. The web shim returns the original image without compression.

### Performance Tips

- Use appropriate quality values (0.6-0.8 for most use cases)
- Set reasonable `maxWidth`/`maxHeight` limits
- Consider compressing images in background threads for better UX

## Development

```sh
npm run build      # Compile TypeScript to build/
npm run lint       # Lint source files
npm run clean      # Remove build artifacts
```

### Releasing

1. Update the version in `package.json`.
2. Commit changes and create a git tag matching the version (e.g. `v1.0.0`).
3. Run `npm run clean && npm run build`.
4. Inspect the package with `npm pack`.
5. Publish with `npm publish`.

## License

MIT © Rahim
