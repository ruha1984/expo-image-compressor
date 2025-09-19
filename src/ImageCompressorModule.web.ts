import { registerWebModule, NativeModule } from "expo";

import type {
  CompressOptions,
  CompressResult,
  ImageAsset,
} from "./ImageCompressor.types";

type LoadedImage = {
  source: CanvasImageSource;
  width: number;
  height: number;
  blob: Blob;
  release: () => void;
};

const clamp = (value: number, lower: number, upper: number) =>
  Math.min(Math.max(value, lower), upper);

async function loadImage(uri: string): Promise<LoadedImage> {
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status}`);
  }

  const blob = await response.blob();

  if ("createImageBitmap" in globalThis) {
    const bitmap = await createImageBitmap(blob);
    return {
      source: bitmap,
      width: bitmap.width,
      height: bitmap.height,
      blob,
      release: () => {
        if ("close" in bitmap) {
          bitmap.close();
        }
      },
    };
  }

  const imageElement = await new Promise<HTMLImageElement>(
    (resolve, reject) => {
      const img = new Image();
      img.crossOrigin = "anonymous";
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error("Failed to decode image."));
      img.src = URL.createObjectURL(blob);
    }
  );

  return {
    source: imageElement,
    width: imageElement.naturalWidth,
    height: imageElement.naturalHeight,
    blob,
    release: () => {
      if (imageElement.src.startsWith("blob:")) {
        URL.revokeObjectURL(imageElement.src);
      }
    },
  };
}

async function canvasToBlob(
  canvas: HTMLCanvasElement | OffscreenCanvas,
  type: string,
  quality: number
) {
  if ("convertToBlob" in canvas) {
    return await (canvas as OffscreenCanvas).convertToBlob({ type, quality });
  }

  return await new Promise<Blob>((resolve, reject) => {
    (canvas as HTMLCanvasElement).toBlob(
      (blob) => {
        if (blob) {
          resolve(blob);
        } else {
          reject(new Error("Canvas toBlob returned null."));
        }
      },
      type,
      quality
    );
  });
}

class ImageCompressorModule extends NativeModule {
  async compress(
    image: ImageAsset,
    options: CompressOptions = {}
  ): Promise<CompressResult> {
    if (!image?.uri) {
      throw new Error("Image uri is required");
    }

    const loaded = await loadImage(image.uri);
    try {
      const maxWidth = options.maxWidth ?? Number.POSITIVE_INFINITY;
      const maxHeight = options.maxHeight ?? Number.POSITIVE_INFINITY;

      let targetWidth = loaded.width;
      let targetHeight = loaded.height;

      if (
        maxWidth !== Number.POSITIVE_INFINITY ||
        maxHeight !== Number.POSITIVE_INFINITY
      ) {
        const scale = clamp(
          Math.min(maxWidth / loaded.width, maxHeight / loaded.height),
          0,
          1
        );
        if (scale > 0 && scale < 1) {
          targetWidth = Math.max(Math.round(loaded.width * scale), 1);
          targetHeight = Math.max(Math.round(loaded.height * scale), 1);
        }
      }

      const quality = clamp(options.quality ?? 0.7, 0, 1);
      const preferredType =
        loaded.blob.type === "image/png" ? "image/png" : "image/jpeg";
      const canvas: HTMLCanvasElement | OffscreenCanvas =
        typeof OffscreenCanvas !== "undefined"
          ? new OffscreenCanvas(targetWidth, targetHeight)
          : Object.assign(document.createElement("canvas"), {
              width: targetWidth,
              height: targetHeight,
            });

      const context = canvas.getContext("2d") as CanvasRenderingContext2D;
      if (!context) {
        throw new Error("Failed to obtain 2d context");
      }

      context.drawImage(loaded.source, 0, 0, targetWidth, targetHeight);

      const outputBlob = await canvasToBlob(canvas, preferredType, quality);
      const objectUrl = URL.createObjectURL(outputBlob);

      return {
        uri: objectUrl,
        width: targetWidth,
        height: targetHeight,
        size: outputBlob.size,
      };
    } finally {
      loaded.release();
    }
  }
}

export default registerWebModule(ImageCompressorModule, "ImageCompressor");
