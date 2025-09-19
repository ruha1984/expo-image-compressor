import ImageCompressorModule from './ImageCompressorModule';

import type { CompressOptions, CompressResult, ImageAsset } from './ImageCompressor.types';

export * from './ImageCompressor.types';

export const compress = (
  image: ImageAsset,
  options?: CompressOptions
): CompressResult => ImageCompressorModule.compress(image, options);

export default ImageCompressorModule;
