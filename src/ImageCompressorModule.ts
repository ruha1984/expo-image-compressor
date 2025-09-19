import { requireNativeModule } from 'expo-modules-core';

import type { ImageCompressorModule } from './ImageCompressor.types';

const ImageCompressor = requireNativeModule<ImageCompressorModule>('ImageCompressor');

export default ImageCompressor;
