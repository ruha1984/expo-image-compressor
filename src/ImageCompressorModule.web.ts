import { NativeModule, registerWebModule } from 'expo-modules-core';

import type { CompressOptions, CompressResult, ImageAsset } from './ImageCompressor.types';

class ImageCompressorWebModule extends NativeModule {
  compress(image: ImageAsset, _options: CompressOptions = {}): CompressResult {
    return {
      uri: image.uri,
      width: 0,
      height: 0,
      size: 0,
    };
  }
}

export default registerWebModule(ImageCompressorWebModule, 'ImageCompressor');
