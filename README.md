# Expo Compressor (iOS)

`expo-compressor` exposes a thin Expo Modules wrapper around a native Swift implementation that synchronously compresses images on iOS.

## How it works

1. **Input** – JS passes an `{ uri }` object (usually from `expo-image-picker`).
2. **Asset loading** – Swift pulls the source image. Local `file://` paths are read directly from disk; `ph://` identifiers are fetched via `PHImageManager` with network access enabled for iCloud assets.
3. **Optional resize** – If `maxWidth` or `maxHeight` are provided, the image is proportionally scaled down using `UIGraphicsBeginImageContextWithOptions`. Images smaller than the limits are left untouched.
4. **Encoding** – The resized bitmap is encoded to JPEG using the requested `quality` (default `0.7`). If JPEG encoding fails, it falls back to PNG.
5. **Persistence** – The encoded bytes are written to a unique file in `NSTemporaryDirectory()` and the module returns its `file://` URI together with width, height, and byte size metadata.

> Android/web stubs currently throw / return the original URI, so the module is effectively iOS-only today.

## Usage

```ts
import ImageCompressor from 'expo-compressor';

const result = ImageCompressor.compress({ uri }, { quality: 0.3 });
// result.uri -> compressed file path
```
