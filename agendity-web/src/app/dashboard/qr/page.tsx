'use client';

import { useCallback, useRef, useState } from 'react';
import { QRCodeSVG, QRCodeCanvas } from 'qrcode.react';
import { Copy, Download, Check, QrCode, Smartphone } from 'lucide-react';
import { Card, Button } from '@/components/ui';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import { Skeleton } from '@/components/ui';

const PUBLIC_BASE_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'https://agendity.com';

export default function QrPage() {
  const { data: business, isLoading } = useCurrentBusiness();
  const canvasRef = useRef<HTMLDivElement>(null);
  const [copied, setCopied] = useState(false);

  const publicUrl = business ? `${PUBLIC_BASE_URL}/${business.slug}` : '';

  const handleCopy = useCallback(async () => {
    if (!publicUrl) return;
    await navigator.clipboard.writeText(publicUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [publicUrl]);

  const handleDownload = useCallback(() => {
    const canvas = canvasRef.current?.querySelector('canvas');
    if (!canvas) return;

    const url = canvas.toDataURL('image/png');
    const link = document.createElement('a');
    link.download = `agendity-qr-${business?.slug ?? 'code'}.png`;
    link.href = url;
    link.click();
  }, [business?.slug]);

  if (isLoading) {
    return (
      <div>
        <div className="mb-6">
          <Skeleton className="h-8 w-48" />
        </div>
        <div className="flex justify-center">
          <Skeleton className="h-96 w-full max-w-lg" />
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Código QR</h1>
        <p className="mt-1 text-sm text-gray-500">
          Comparte tu enlace de reservas con tus clientes.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
        {/* QR Card */}
        <Card className="flex flex-col items-center text-center">
          <div className="mb-2 rounded-full bg-violet-100 p-3">
            <QrCode className="h-6 w-6 text-violet-600" />
          </div>
          <h2 className="mb-6 text-lg font-semibold text-gray-900">Tu código QR</h2>

          {/* QR SVG (visible) */}
          <div className="mb-6 rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
            <QRCodeSVG
              value={publicUrl}
              size={256}
              level="H"
              bgColor="#FFFFFF"
              fgColor="#000000"
            />
          </div>

          {/* Hidden canvas for download */}
          <div ref={canvasRef} className="hidden">
            <QRCodeCanvas
              value={publicUrl}
              size={512}
              level="H"
              bgColor="#FFFFFF"
              fgColor="#000000"
            />
          </div>

          {/* Public URL */}
          <div className="mb-6 w-full">
            <p className="mb-2 text-xs font-medium uppercase tracking-wider text-gray-400">
              Enlace público
            </p>
            <div className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5">
              <span className="flex-1 truncate text-sm text-gray-700">{publicUrl}</span>
              <button
                onClick={handleCopy}
                className="flex-shrink-0 cursor-pointer rounded-md p-1.5 text-gray-400 transition-colors hover:bg-gray-200 hover:text-gray-600"
                title="Copiar enlace"
              >
                {copied ? (
                  <Check className="h-4 w-4 text-green-500" />
                ) : (
                  <Copy className="h-4 w-4" />
                )}
              </button>
            </div>
          </div>

          {/* Action buttons */}
          <div className="flex w-full flex-col gap-3 sm:flex-row">
            <Button variant="outline" className="flex-1" onClick={handleCopy}>
              {copied ? (
                <Check className="mr-2 h-4 w-4" />
              ) : (
                <Copy className="mr-2 h-4 w-4" />
              )}
              {copied ? 'Copiado' : 'Copiar enlace'}
            </Button>
            <Button variant="primary" className="flex-1" onClick={handleDownload}>
              <Download className="mr-2 h-4 w-4" />
              Descargar QR
            </Button>
          </div>
        </Card>

        {/* Instructions & Phone preview */}
        <div className="space-y-6">
          {/* Instructions */}
          <Card>
            <h3 className="mb-3 text-base font-semibold text-gray-900">
              Cómo usar tu código QR
            </h3>
            <ul className="space-y-3 text-sm text-gray-600">
              <li className="flex gap-3">
                <span className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-600">
                  1
                </span>
                <span>
                  Descarga e imprime el código QR.
                </span>
              </li>
              <li className="flex gap-3">
                <span className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-600">
                  2
                </span>
                <span>
                  Colócalo en un lugar visible de tu local (mostrador, espejo, puerta).
                </span>
              </li>
              <li className="flex gap-3">
                <span className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-600">
                  3
                </span>
                <span>
                  Tus clientes lo escanean con su celular y reservan al instante.
                </span>
              </li>
            </ul>
          </Card>

          {/* Phone mockup preview */}
          <Card className="flex flex-col items-center py-8">
            <p className="mb-4 text-sm font-medium text-gray-500">
              Así lo ven tus clientes
            </p>
            <div className="relative mx-auto w-56">
              {/* Phone frame */}
              <div className="rounded-[2rem] border-4 border-gray-800 bg-white p-2 shadow-xl">
                {/* Notch */}
                <div className="mx-auto mb-2 h-5 w-20 rounded-full bg-gray-800" />
                {/* Screen content */}
                <div className="flex flex-col items-center rounded-2xl bg-gray-50 px-4 py-6">
                  <Smartphone className="mb-2 h-8 w-8 text-violet-600" />
                  <p className="mb-1 text-xs font-semibold text-gray-900">
                    {business?.name ?? 'Tu negocio'}
                  </p>
                  <p className="mb-4 text-[10px] text-gray-500">Reservar cita</p>
                  <div className="rounded-xl border border-gray-200 bg-white p-3">
                    <QRCodeSVG
                      value={publicUrl}
                      size={120}
                      level="H"
                      bgColor="#FFFFFF"
                      fgColor="#000000"
                    />
                  </div>
                  <p className="mt-3 text-[10px] text-gray-400">
                    Escanea para reservar
                  </p>
                </div>
                {/* Home indicator */}
                <div className="mx-auto mt-2 h-1 w-16 rounded-full bg-gray-300" />
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
