'use client';

import { useState } from 'react';
import { Modal } from '@/components/ui/modal';
import { cn } from '@/lib/utils/cn';

interface ImageViewerModalProps {
  open: boolean;
  onClose: () => void;
  imageUrl: string;
  alt?: string;
}

export function ImageViewerModal({
  open,
  onClose,
  imageUrl,
  alt = 'Comprobante de pago',
}: ImageViewerModalProps) {
  const [zoomed, setZoomed] = useState(false);

  function handleClose() {
    setZoomed(false);
    onClose();
  }

  return (
    <Modal open={open} onClose={handleClose} title="Comprobante de pago" size="lg">
      <div className="flex items-center justify-center">
        <div
          className={cn(
            'relative overflow-auto transition-all duration-200',
            zoomed ? 'max-h-[80vh] cursor-zoom-out' : 'max-h-[60vh] cursor-zoom-in',
          )}
          onClick={() => setZoomed((prev) => !prev)}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={imageUrl}
            alt={alt}
            className={cn(
              'rounded-lg transition-transform duration-200',
              zoomed ? 'scale-150 origin-top-left' : 'max-w-full object-contain',
            )}
          />
        </div>
      </div>
      <p className="mt-2 text-center text-xs text-gray-400">
        Haz clic en la imagen para acercar/alejar
      </p>
    </Modal>
  );
}
