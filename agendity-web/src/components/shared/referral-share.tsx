'use client';

import { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Copy, Check, Share2, Download } from 'lucide-react';
import {
  WhatsappShareButton,
  FacebookShareButton,
  TwitterShareButton,
  TelegramShareButton,
  WhatsappIcon,
  FacebookIcon,
  XIcon,
  TelegramIcon,
} from 'react-share';
import { Button } from '@/components/ui/button';

type ReferralShareProps = {
  code: string;
  referralLink: string;
};

export function ReferralShare({ code, referralLink }: ReferralShareProps) {
  const [copied, setCopied] = useState(false);

  const shareTitle = 'Administra tu negocio de servicios con Agendity';
  const shareText = `Administra citas, empleados y pagos de tu negocio con Agendity. Pruébalo gratis: ${referralLink}`;

  const handleCopy = async () => {
    await navigator.clipboard.writeText(referralLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownloadQR = () => {
    const svg = document.getElementById('referral-qr-svg');
    if (!svg) return;

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    canvas.width = 400;
    canvas.height = 400;

    const svgData = new XMLSerializer().serializeToString(svg);
    const img = new Image();
    img.onload = () => {
      ctx.fillStyle = 'white';
      ctx.fillRect(0, 0, 400, 400);
      ctx.drawImage(img, 0, 0, 400, 400);

      const a = document.createElement('a');
      a.download = `agendity-referido-${code}.png`;
      a.href = canvas.toDataURL('image/png');
      a.click();
    };
    img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgData)));
  };

  const handleNativeShare = async () => {
    if (!navigator.share) return;

    try {
      // Try to share QR as image
      const svg = document.getElementById('referral-qr-svg');
      if (svg) {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        if (ctx) {
          canvas.width = 400;
          canvas.height = 400;
          const svgData = new XMLSerializer().serializeToString(svg);
          const img = new Image();

          await new Promise<void>((resolve) => {
            img.onload = () => {
              ctx.fillStyle = 'white';
              ctx.fillRect(0, 0, 400, 400);
              ctx.drawImage(img, 0, 0, 400, 400);
              resolve();
            };
            img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgData)));
          });

          const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/png'));
          if (blob) {
            const file = new File([blob], `agendity-referido-${code}.png`, { type: 'image/png' });
            await navigator.share({
              title: shareTitle,
              text: shareText,
              files: [file],
            });
            return;
          }
        }
      }

      // Fallback: share text only
      await navigator.share({
        title: shareTitle,
        text: shareText,
        url: referralLink,
      });
    } catch {
      // User cancelled or share failed
    }
  };

  return (
    <div className="space-y-6">
      {/* QR Code */}
      <div className="flex flex-col items-center gap-3">
        <div className="rounded-xl bg-white p-4 shadow-sm border border-gray-100">
          <QRCodeSVG
            id="referral-qr-svg"
            value={referralLink}
            size={160}
            level="M"
            fgColor="#7c3aed"
          />
        </div>
        <p className="text-xs text-gray-400">Escanea o comparte este QR</p>
      </div>

      {/* Link + Copy */}
      <div className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3">
        <span className="flex-1 truncate text-sm text-gray-600">{referralLink}</span>
        <button
          onClick={handleCopy}
          className="flex cursor-pointer shrink-0 items-center gap-1 rounded-md bg-violet-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-violet-700 transition-colors"
        >
          {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
          {copied ? 'Copiado' : 'Copiar'}
        </button>
      </div>

      {/* Native Share (mobile) */}
      {'share' in navigator && (
        <Button onClick={handleNativeShare} className="w-full" variant="outline">
          <Share2 className="mr-2 h-4 w-4" />
          Compartir
        </Button>
      )}

      {/* Social share buttons */}
      <div className="space-y-3">
        <p className="text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
          Compartir en redes
        </p>
        <div className="flex justify-center gap-3">
          <WhatsappShareButton url={referralLink} title={shareText} separator="">
            <WhatsappIcon size={44} round />
          </WhatsappShareButton>

          <FacebookShareButton url={referralLink} hashtag="#Agendity">
            <FacebookIcon size={44} round />
          </FacebookShareButton>

          <TwitterShareButton url={referralLink} title={shareTitle}>
            <XIcon size={44} round />
          </TwitterShareButton>

          <TelegramShareButton url={referralLink} title={shareTitle}>
            <TelegramIcon size={44} round />
          </TelegramShareButton>
        </div>
      </div>

      {/* Download QR */}
      <button
        onClick={handleDownloadQR}
        className="mx-auto flex cursor-pointer items-center gap-1.5 text-xs text-gray-400 transition-colors hover:text-violet-600"
      >
        <Download className="h-3.5 w-3.5" />
        Descargar QR
      </button>
    </div>
  );
}
