'use client';

import { useState } from 'react';
import { ScanLine, Check, AlertTriangle, Camera, Keyboard } from 'lucide-react';
import { Button, Card, Input } from '@/components/ui';
import { QrScanner } from '@/components/shared/qr-scanner';
import { useEmployeeCheckinByCode } from '@/lib/hooks/use-employee-dashboard';
import { useUIStore } from '@/lib/stores/ui-store';

export default function EmployeeCheckinPage() {
  const [ticketCode, setTicketCode] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [checkinResult, setCheckinResult] = useState<{ success: boolean; message: string; details?: string } | null>(null);
  const checkinMutation = useEmployeeCheckinByCode();
  const { addToast } = useUIStore();

  const handleCheckin = async (code?: string) => {
    const codeToUse = code || ticketCode.trim();
    if (!codeToUse) return;

    try {
      await checkinMutation.mutateAsync(codeToUse);
      setCheckinResult({
        success: true,
        message: 'Check-in exitoso',
        details: `Ticket: ${codeToUse}`,
      });
      setTicketCode('');
      addToast({ type: 'success', message: 'Check-in completado' });
    } catch (err) {
      const message = (err as Error)?.message || 'Error al hacer check-in';
      setCheckinResult({ success: false, message });
      addToast({ type: 'error', message });
    }
  };

  function extractTicketCode(scanned: string): string {
    const match = scanned.match(/\/ticket\/([A-Za-z0-9]+)\/?$/);
    return match ? match[1] : scanned;
  }

  const handleScan = (code: string) => {
    setShowScanner(false);
    const ticketCode = extractTicketCode(code);
    setTicketCode(ticketCode);
    handleCheckin(ticketCode);
  };

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Check-in</h1>

      <Card className="max-w-md">
        <div className="mb-4 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-violet-100">
            <ScanLine className="h-5 w-5 text-violet-600" />
          </div>
          <div>
            <h2 className="font-semibold text-gray-900">Registrar llegada</h2>
            <p className="text-xs text-gray-500">Escanea el QR o ingresa el codigo manualmente</p>
          </div>
        </div>

        {/* Scanner button */}
        <Button
          className="mb-4 w-full"
          onClick={() => setShowScanner(true)}
        >
          <Camera className="mr-2 h-4 w-4" />
          Escanear codigo QR
        </Button>

        {/* Manual input */}
        <div className="flex gap-2">
          <Input
            value={ticketCode}
            onChange={(e) => setTicketCode(e.target.value.toUpperCase())}
            placeholder="Codigo de ticket"
            className="flex-1"
            onKeyDown={(e) => e.key === 'Enter' && handleCheckin()}
          />
          <Button
            variant="outline"
            onClick={() => handleCheckin()}
            disabled={!ticketCode.trim() || checkinMutation.isPending}
            loading={checkinMutation.isPending}
          >
            <Keyboard className="mr-1.5 h-4 w-4" />
            Manual
          </Button>
        </div>

        {/* Result */}
        {checkinResult && (
          <div className={`mt-4 rounded-lg p-3 ${checkinResult.success ? 'bg-green-50' : 'bg-red-50'}`}>
            <div className="flex items-center gap-2">
              {checkinResult.success ? (
                <Check className="h-5 w-5 text-green-600" />
              ) : (
                <AlertTriangle className="h-5 w-5 text-red-600" />
              )}
              <div>
                <p className={`text-sm font-medium ${checkinResult.success ? 'text-green-700' : 'text-red-700'}`}>
                  {checkinResult.message}
                </p>
                {checkinResult.details && (
                  <p className="text-xs text-gray-500">{checkinResult.details}</p>
                )}
              </div>
            </div>
          </div>
        )}
      </Card>

      {/* QR Scanner modal */}
      {showScanner && (
        <QrScanner
          onScan={handleScan}
          onClose={() => setShowScanner(false)}
        />
      )}
    </div>
  );
}
