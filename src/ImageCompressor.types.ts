export type ImageAsset = {
  uri: string;
};

export type CompressOptions = {
  quality?: number;
  maxWidth?: number;
  maxHeight?: number;
};

export type CompressResult = {
  uri: string;
  width: number;
  height: number;
  size: number;
};

export type ImageCompressorModule = {
  compress(image: ImageAsset, options?: CompressOptions): CompressResult;
};
