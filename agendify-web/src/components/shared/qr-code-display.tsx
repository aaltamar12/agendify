'use client';

import { useCallback, useRef } from 'react';
import { QRCodeSVG, QRCodeCanvas } from 'qrcode.react';
import { Download } from 'lucide-react';
import { Button } from '@/components/ui';

interface QrCodeDisplayProps {
  value: string;
  size?: number;
  downloadable?: boolean;
}

export function QrCodeDisplay({
  value,
  size = 256,
  downloadable = false,
}: QrCodeDisplayProps) {
  const canvasRef = useRef<HTMLDivElement>(null);

  const handleDownload = useCallback(() => {
    const canvas = canvasRef.current?.querySelector('canvas');
    if (!canvas) return;

    const url = canvas.toDataURL('image/png');
    const link = document.createElement('a');
    link.download = 'agendify-qr.png';
    link.href = url;
    link.click();
  }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      {/* Visible SVG version */}
      <QRCodeSVG
        value={value}
        size={size}
        level="H"
        bgColor="#FFFFFF"
        fgColor="#000000"
      />

      {/* Hidden canvas for download */}
      {downloadable && (
        <>
          <div ref={canvasRef} className="hidden">
            <QRCodeCanvas
              value={value}
              size={size * 2}
              level="H"
              bgColor="#FFFFFF"
              fgColor="#000000"
            />
          </div>
          <Button variant="outline" onClick={handleDownload}>
            <Download className="mr-2 h-4 w-4" />
            Descargar QR
          </Button>
        </>
      )}
    </div>
  );
}
