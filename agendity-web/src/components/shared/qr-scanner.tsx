'use client';

import { useEffect, useRef, useState } from 'react';
import { Camera, X } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface QrScannerProps {
  onScan: (code: string) => void;
  onClose: () => void;
}

export function QrScanner({ onScan, onClose }: QrScannerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const scannerRef = useRef<unknown>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let scanner: { clear: () => Promise<void>; stop: () => Promise<void> } | null = null;

    async function startScanner() {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        const scannerId = 'qr-reader';

        if (!document.getElementById(scannerId)) return;

        const html5QrCode = new Html5Qrcode(scannerId);
        scanner = html5QrCode as unknown as typeof scanner;
        scannerRef.current = html5QrCode;

        await html5QrCode.start(
          { facingMode: 'environment' },
          {
            fps: 10,
            qrbox: { width: 250, height: 250 },
            aspectRatio: 1,
          },
          (decodedText: string) => {
            onScan(decodedText);
            html5QrCode.stop().catch(() => {});
          },
          () => {
            // QR not found in frame — ignore
          },
        );
      } catch (err) {
        console.error('QR Scanner error:', err);
        setError('No se pudo acceder a la camara. Verifica los permisos.');
      }
    }

    startScanner();

    return () => {
      if (scanner) {
        scanner.stop().catch(() => {});
      }
    };
  }, [onScan]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
      <div className="mx-4 w-full max-w-sm overflow-hidden rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-gray-200 px-4 py-3">
          <div className="flex items-center gap-2">
            <Camera className="h-5 w-5 text-violet-600" />
            <h3 className="font-semibold text-gray-900">Escanear QR</h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="cursor-pointer text-gray-400 hover:text-gray-600"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="p-4">
          {error ? (
            <div className="py-8 text-center">
              <p className="mb-3 text-sm text-red-600">{error}</p>
              <Button variant="outline" size="sm" onClick={onClose}>
                Cerrar
              </Button>
            </div>
          ) : (
            <>
              <div
                id="qr-reader"
                ref={containerRef}
                className="overflow-hidden rounded-lg"
              />
              <p className="mt-3 text-center text-xs text-gray-500">
                Apunta la camara al codigo QR del ticket
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
