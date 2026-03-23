'use client';

import { useState } from 'react';
import {
  ScanLine,
  CheckCircle,
  AlertCircle,
  Scissors,
  User,
  Calendar,
  Clock,
  Camera,
} from 'lucide-react';
import { Button, Card, Input } from '@/components/ui';
import { QrScanner } from '@/components/shared/qr-scanner';
import { useCheckinByCode } from '@/lib/hooks/use-appointments';
import { formatDate, formatTime } from '@/lib/utils/date';
import type { Appointment } from '@/lib/api/types';

export default function CheckinPage() {
  const [ticketCode, setTicketCode] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [checkedInAppointment, setCheckedInAppointment] =
    useState<Appointment | null>(null);

  const checkinMutation = useCheckinByCode();

  async function handleCheckin(e: React.FormEvent) {
    e.preventDefault();
    const code = ticketCode.trim();
    if (!code) return;

    try {
      const result = await checkinMutation.mutateAsync(code);
      setCheckedInAppointment(result.data);
    } catch {
      // Error handled by mutation state
    }
  }

  function extractTicketCode(scanned: string): string {
    // QR contains URL like "https://agendity.co/slug/ticket/CODE" — extract CODE
    const match = scanned.match(/\/ticket\/([A-Za-z0-9]+)\/?$/);
    return match ? match[1] : scanned;
  }

  async function handleScan(code: string) {
    setShowScanner(false);
    const ticketCode = extractTicketCode(code);
    setTicketCode(ticketCode);
    try {
      const result = await checkinMutation.mutateAsync(ticketCode);
      setCheckedInAppointment(result.data);
    } catch {
      // Error handled by mutation state
    }
  }

  function handleReset() {
    setTicketCode('');
    setCheckedInAppointment(null);
    checkinMutation.reset();
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Check-in</h1>
        <p className="mt-1 text-sm text-gray-500">
          Ingresa el código del ticket para registrar la llegada del cliente
        </p>
      </div>

      {/* Success state */}
      {checkedInAppointment && (
        <Card className="border-green-200 bg-green-50">
          <div className="flex flex-col items-center text-center">
            <div className="rounded-full bg-green-100 p-3">
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
            <h2 className="mt-3 text-lg font-bold text-green-900">
              Check-in exitoso
            </h2>
            <p className="mt-1 text-sm text-green-700">
              El cliente ha sido registrado
            </p>
          </div>

          <div className="mt-4 space-y-3 rounded-lg bg-white p-4">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <User className="h-4 w-4 text-violet-600" />
              <span className="font-medium text-gray-900">
                {checkedInAppointment.customer?.name}
              </span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Scissors className="h-4 w-4 text-violet-600" />
              <span>{checkedInAppointment.service?.name}</span>
            </div>
            {checkedInAppointment.employee && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <User className="h-4 w-4 text-violet-600" />
                <span>{checkedInAppointment.employee.name}</span>
              </div>
            )}
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Calendar className="h-4 w-4 text-violet-600" />
              <span>{formatDate(checkedInAppointment.date)}</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Clock className="h-4 w-4 text-violet-600" />
              <span>{formatTime(checkedInAppointment.start_time)}</span>
            </div>
          </div>

          <Button
            fullWidth
            variant="outline"
            className="mt-4"
            onClick={handleReset}
          >
            Nuevo check-in
          </Button>
        </Card>
      )}

      {/* Input form */}
      {!checkedInAppointment && (
        <Card>
          <div className="flex flex-col items-center">
            <div className="rounded-full bg-violet-100 p-3">
              <ScanLine className="h-8 w-8 text-violet-600" />
            </div>
            <h2 className="mt-3 text-lg font-semibold text-gray-900">
              Verificar ticket
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Escanea el QR o ingresa el código manualmente
            </p>
          </div>

          <form onSubmit={handleCheckin} className="mt-6 space-y-4">
            <Button
              type="button"
              fullWidth
              size="lg"
              onClick={() => setShowScanner(true)}
            >
              <Camera className="mr-2 h-5 w-5" />
              Escanear codigo QR
            </Button>

            <div className="relative flex items-center">
              <div className="flex-grow border-t border-gray-200" />
              <span className="mx-3 text-xs text-gray-400">o ingresa manualmente</span>
              <div className="flex-grow border-t border-gray-200" />
            </div>

            <Input
              label="Código del ticket"
              placeholder="Ej: FE89E62168B5"
              value={ticketCode}
              onChange={(e) => setTicketCode(e.target.value.toUpperCase())}
              className="font-mono text-center text-lg tracking-wider"
            />

            {checkinMutation.isError && (
              <div className="flex items-center gap-2 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>
                  No se pudo hacer check-in. Verifica que el código sea correcto
                  y que la cita esté confirmada.
                </span>
              </div>
            )}

            <Button
              type="submit"
              fullWidth
              size="lg"
              loading={checkinMutation.isPending}
              disabled={!ticketCode.trim()}
            >
              Verificar
            </Button>
          </form>
        </Card>
      )}
      {/* QR Scanner */}
      {showScanner && (
        <QrScanner
          onScan={handleScan}
          onClose={() => setShowScanner(false)}
        />
      )}
    </div>
  );
}
