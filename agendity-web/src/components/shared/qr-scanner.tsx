'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { Camera, X } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface QrScannerProps {
  onScan: (code: string) => void;
  onClose: () => void;
}

export function QrScanner({ onScan, onClose }: QrScannerProps) {
  const scannerRef = useRef<{ stop: () => Promise<void> } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const hasScanned = useRef(false);

  const handleScan = useCallback((code: string) => {
    if (hasScanned.current) return;
    hasScanned.current = true;
    onScan(code);
  }, [onScan]);

  useEffect(() => {
    let mounted = true;

    async function startScanner() {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        if (!mounted) return;

        const el = document.getElementById('qr-reader');
        if (!el) return;

        const html5QrCode = new Html5Qrcode('qr-reader');
        scannerRef.current = html5QrCode;

        await html5QrCode.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 220, height: 220 } },
          (decodedText: string) => {
            handleScan(decodedText);
            html5QrCode.stop().catch(() => {});
          },
          () => {},
        );
      } catch (err) {
        console.error('QR Scanner error:', err);
        if (mounted) setError('No se pudo acceder a la camara. Verifica los permisos.');
      }
    }

    startScanner();

    return () => {
      mounted = false;
      scannerRef.current?.stop().catch(() => {});
    };
  }, [handleScan]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80" onClick={onClose}>
      <div
        className="mx-4 w-full max-w-md overflow-hidden rounded-xl bg-black shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-4 py-3">
          <div className="flex items-center gap-2">
            <Camera className="h-5 w-5 text-white" />
            <h3 className="font-semibold text-white">Escanear QR</h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="cursor-pointer text-gray-400 hover:text-white"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <div>
          {error ? (
            <div className="px-4 py-12 text-center">
              <p className="mb-3 text-sm text-red-400">{error}</p>
              <Button variant="outline" size="sm" onClick={onClose}>
                Cerrar
              </Button>
            </div>
          ) : (
            <>
              <style>{`
                #qr-reader video {
                  width: 100% !important;
                  height: auto !important;
                  object-fit: cover !important;
                  border-radius: 0 !important;
                }
                #qr-reader canvas,
                #qr-reader img:not([alt=""]) {
                  display: none !important;
                }
                #qr-reader {
                  border: none !important;
                }
              `}</style>
              <div
                id="qr-reader"
                className="w-full overflow-hidden bg-black"
              />
              <p className="py-3 text-center text-xs text-gray-400">
                Apunta la camara al codigo QR del ticket
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
