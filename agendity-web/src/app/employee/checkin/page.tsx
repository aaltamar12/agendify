'use client';

import { useState } from 'react';
import { ScanLine, Check, AlertTriangle } from 'lucide-react';
import { Button, Card, Input, Modal } from '@/components/ui';
import { useEmployeeCheckin } from '@/lib/hooks/use-employee-dashboard';
import { useUIStore } from '@/lib/stores/ui-store';

const SUBSTITUTE_REASONS = [
  'Cambio de turno',
  'Empleado ausente',
  'Reasignacion',
  'Solicitud del cliente',
  'Otro',
];

export default function EmployeeCheckinPage() {
  const [ticketCode, setTicketCode] = useState('');
  const [checkinResult, setCheckinResult] = useState<{ success: boolean; message: string } | null>(null);
  const [substituteModal, setSubstituteModal] = useState<{ appointmentId: number; assignedEmployee: string } | null>(null);
  const [substituteReason, setSubstituteReason] = useState('');
  const [customReason, setCustomReason] = useState('');
  const checkinMutation = useEmployeeCheckin();
  const { addToast } = useUIStore();

  // First we need to find the appointment by ticket code, then do check-in
  // For now, we use the appointment ID from a search or the ticket code
  // The employee portal check-in works by appointment ID

  const handleCheckin = async () => {
    // TODO: Add endpoint to find appointment by ticket_code in employee context
    // For now this is a placeholder — in the real flow, the employee scans QR which gives the appointment ID
    addToast({ type: 'info', message: 'Ingresa el codigo del ticket para hacer check-in' });
  };

  const handleSubstituteConfirm = async () => {
    if (!substituteModal) return;
    const reason = substituteReason === 'Otro' ? customReason : substituteReason;

    try {
      await checkinMutation.mutateAsync({
        appointmentId: substituteModal.appointmentId,
        confirmed: true,
        substitute_reason: reason,
      });
      setSubstituteModal(null);
      setCheckinResult({ success: true, message: 'Check-in realizado como sustituto' });
      addToast({ type: 'success', message: 'Check-in completado' });
    } catch {
      addToast({ type: 'error', message: 'Error al hacer check-in' });
    }
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
            <p className="text-xs text-gray-500">Ingresa el codigo del ticket del cliente</p>
          </div>
        </div>

        <div className="flex gap-2">
          <Input
            value={ticketCode}
            onChange={(e) => setTicketCode(e.target.value.toUpperCase())}
            placeholder="Codigo de ticket"
            className="flex-1"
          />
          <Button
            onClick={handleCheckin}
            disabled={!ticketCode.trim()}
            loading={checkinMutation.isPending}
          >
            <Check className="mr-1.5 h-4 w-4" />
            Check-in
          </Button>
        </div>

        {checkinResult && (
          <div className={`mt-4 rounded-lg p-3 ${checkinResult.success ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
            <p className="text-sm font-medium">{checkinResult.message}</p>
          </div>
        )}
      </Card>

      {/* Substitute confirmation modal */}
      <Modal
        open={!!substituteModal}
        onClose={() => setSubstituteModal(null)}
        title="Check-in de otro empleado"
      >
        {substituteModal && (
          <div className="space-y-4">
            <div className="flex items-center gap-3 rounded-lg bg-orange-50 p-3">
              <AlertTriangle className="h-5 w-5 text-orange-600" />
              <div>
                <p className="text-sm font-medium text-orange-800">
                  Esta cita esta asignada a {substituteModal.assignedEmployee}
                </p>
                <p className="text-xs text-orange-600">¿Deseas hacer el check-in de todos modos?</p>
              </div>
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Razon</label>
              <select
                value={substituteReason}
                onChange={(e) => setSubstituteReason(e.target.value)}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-violet-500 focus:outline-none"
              >
                <option value="">Selecciona una razon</option>
                {SUBSTITUTE_REASONS.map((r) => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
            </div>

            {substituteReason === 'Otro' && (
              <Input
                label="Especificar razon"
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
                placeholder="Describe la razon..."
              />
            )}

            <div className="flex justify-end gap-3">
              <Button variant="ghost" onClick={() => setSubstituteModal(null)}>Cancelar</Button>
              <Button
                onClick={handleSubstituteConfirm}
                disabled={!substituteReason || (substituteReason === 'Otro' && !customReason)}
                loading={checkinMutation.isPending}
              >
                Confirmar check-in
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
