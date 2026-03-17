'use client';

import { useRef, useState } from 'react';
import { useParams } from 'next/navigation';
import { toPng } from 'html-to-image';
import { QRCodeSVG } from 'qrcode.react';
import {
  MapPin,
  Calendar,
  Clock,
  User,
  Scissors,
  Download,
  Share2,
  CreditCard,
  Copy,
  Check,
  ClockIcon,
  CheckCircle,
  XCircle,
  Ban,
  AlertTriangle,
  Upload,
  ImageIcon,
} from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button, Badge, Spinner, Card, Input } from '@/components/ui';
import { usePublicTicket, useCancelBooking, useSubmitTicketPayment } from '@/lib/hooks/use-public';
import { getSavedCustomer } from '@/lib/utils/saved-customer';
import { formatDate, formatTime } from '@/lib/utils/date';
import { formatCurrency } from '@/lib/utils/format';
import { APPOINTMENT_STATUSES } from '@/lib/constants';
import type { AppointmentStatus } from '@/lib/api/types';

export default function TicketPage() {
  const params = useParams<{ slug: string; code: string }>();
  const { code } = params;
  const ticketRef = useRef<HTMLDivElement>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [showCancelDialog, setShowCancelDialog] = useState(false);

  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [verifyEmail, setVerifyEmail] = useState('');
  const [downloading, setDownloading] = useState(false);

  const savedCustomer = getSavedCustomer();
  const customerEmail = savedCustomer?.email || verifyEmail;

  const { data, isLoading, error } = usePublicTicket(code);
  const cancelMutation = useCancelBooking();
  const paymentMutation = useSubmitTicketPayment();

  const ticketUrl =
    typeof window !== 'undefined'
      ? `${window.location.origin}/${params.slug}/ticket/${code}`
      : code;

  async function handleDownload() {
    if (!ticketRef.current) return;
    setDownloading(true);
    try {
      const dataUrl = await toPng(ticketRef.current, { quality: 0.95 });
      const link = document.createElement('a');
      link.download = `ticket-${code}.png`;
      link.href = dataUrl;
      link.click();
    } catch {
      // Fallback to print
      window.print();
    } finally {
      setDownloading(false);
    }
  }

  async function handleShare() {
    if (!data) return;
    if (navigator.share) {
      try {
        await navigator.share({
          title: `Ticket - ${data.business.name}`,
          text: `Mi cita en ${data.business.name}`,
          url: window.location.href,
        });
      } catch {
        // User cancelled or API unavailable
      }
    }
  }

  function handleCopy(text: string, field: string) {
    navigator.clipboard.writeText(text);
    setCopiedField(field);
    setTimeout(() => setCopiedField(null), 2000);
  }

  async function handleCancel() {
    try {
      await cancelMutation.mutateAsync({ code });
      setShowCancelDialog(false);
    } catch {
      // Error handled by mutation state
    }
  }

  function handleFileSelect(file: File) {
    if (file.size > 5 * 1024 * 1024) {
      // Max 5MB
      return;
    }
    setSelectedFile(file);
    setPreviewUrl(URL.createObjectURL(file));
  }

  function handleFileInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFileSelect(file);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith('image/')) handleFileSelect(file);
  }

  async function handleSubmitProof() {
    if (!selectedFile || !customerEmail) return;
    try {
      await paymentMutation.mutateAsync({
        code,
        payment_method: 'transfer',
        proof: selectedFile,
        customer_email: customerEmail,
      });
      setSelectedFile(null);
      setPreviewUrl(null);
    } catch {
      // Error handled by mutation state
    }
  }

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-950">
        <Spinner size="lg" color="text-violet-400" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-gray-950 px-4">
        <h1 className="text-xl font-bold text-white">Ticket no encontrado</h1>
        <p className="text-gray-400">
          El código puede ser incorrecto o la cita ya no existe.
        </p>
      </div>
    );
  }

  const { appointment, business, ticket_vip: ticketVip } = data;
  const statusInfo = APPOINTMENT_STATUSES[appointment.status];
  const status: AppointmentStatus = appointment.status;

  const hasPaymentMethods =
    business.nequi_phone || business.daviplata_phone || business.bancolombia_account;

  // Check if the appointment can be cancelled by the customer
  const canCancel =
    status === 'pending_payment' ||
    status === 'payment_sent' ||
    status === 'confirmed';

  // Calculate if cancellation would incur penalty
  function wouldIncurPenalty(): boolean {
    if (!business.cancellation_policy_pct || business.cancellation_policy_pct === 0) {
      return false;
    }
    const deadlineHours = business.cancellation_deadline_hours ?? 24;
    const appointmentDateTime = new Date(
      `${appointment.date}T${appointment.start_time}:00`
    );
    const now = new Date();
    const hoursUntil =
      (appointmentDateTime.getTime() - now.getTime()) / (1000 * 60 * 60);
    return hoursUntil < deadlineHours;
  }

  function getPenaltyAmount(): number {
    if (!wouldIncurPenalty()) return 0;
    return Math.round(
      appointment.price * (business.cancellation_policy_pct / 100)
    );
  }

  // Render payment instructions card (reusable across statuses)
  function renderPaymentInstructions() {
    if (!hasPaymentMethods) return null;
    return (
      <div className="w-full max-w-sm mt-4">
        <div className="rounded-2xl bg-gray-900 border border-gray-800 px-6 py-5">
          <div className="flex items-center gap-2 mb-3">
            <CreditCard className="h-5 w-5 text-violet-400" />
            <h3 className="font-semibold text-white">Instrucciones de pago</h3>
          </div>
          <p className="text-sm text-gray-400 mb-4">
            Para confirmar tu cita, realiza el pago por uno de estos medios:
          </p>
          <div className="space-y-3">
            {business.nequi_phone && (
              <div className="flex items-center justify-between rounded-lg bg-gray-800/50 px-3 py-2">
                <div>
                  <p className="text-xs text-gray-500">Nequi</p>
                  <p className="text-sm font-medium text-white">{business.nequi_phone}</p>
                </div>
                <button
                  onClick={() => handleCopy(business.nequi_phone!, 'nequi')}
                  className="cursor-pointer rounded-lg p-2 text-gray-400 hover:bg-gray-700 hover:text-white transition-colors"
                >
                  {copiedField === 'nequi' ? (
                    <Check className="h-4 w-4 text-green-400" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                </button>
              </div>
            )}
            {business.daviplata_phone && (
              <div className="flex items-center justify-between rounded-lg bg-gray-800/50 px-3 py-2">
                <div>
                  <p className="text-xs text-gray-500">Daviplata</p>
                  <p className="text-sm font-medium text-white">{business.daviplata_phone}</p>
                </div>
                <button
                  onClick={() => handleCopy(business.daviplata_phone!, 'daviplata')}
                  className="cursor-pointer rounded-lg p-2 text-gray-400 hover:bg-gray-700 hover:text-white transition-colors"
                >
                  {copiedField === 'daviplata' ? (
                    <Check className="h-4 w-4 text-green-400" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                </button>
              </div>
            )}
            {business.bancolombia_account && (
              <div className="flex items-center justify-between rounded-lg bg-gray-800/50 px-3 py-2">
                <div>
                  <p className="text-xs text-gray-500">Bancolombia</p>
                  <p className="text-sm font-medium text-white">{business.bancolombia_account}</p>
                </div>
                <button
                  onClick={() => handleCopy(business.bancolombia_account!, 'bancolombia')}
                  className="cursor-pointer rounded-lg p-2 text-gray-400 hover:bg-gray-700 hover:text-white transition-colors"
                >
                  {copiedField === 'bancolombia' ? (
                    <Check className="h-4 w-4 text-green-400" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                </button>
              </div>
            )}
          </div>
          <p className="mt-4 text-xs text-gray-500 text-center">
            Después de pagar, sube tu comprobante abajo para confirmar tu cita
          </p>
        </div>
      </div>
    );
  }

  // Render appointment details (reusable across statuses)
  function renderAppointmentDetails() {
    return (
      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <User className="h-4 w-4 shrink-0 text-violet-400" />
          <div>
            <p className="text-xs text-gray-500">Cliente</p>
            <p className="text-sm font-medium text-white">
              {appointment.customer?.name}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <Scissors className="h-4 w-4 shrink-0 text-violet-400" />
          <div>
            <p className="text-xs text-gray-500">Servicio</p>
            <p className="text-sm font-medium text-white">
              {appointment.service?.name}
            </p>
          </div>
        </div>

        {appointment.employee && (
          <div className="flex items-center gap-3">
            <User className="h-4 w-4 shrink-0 text-violet-400" />
            <div>
              <p className="text-xs text-gray-500">Profesional</p>
              <p className="text-sm font-medium text-white">
                {appointment.employee.name}
              </p>
            </div>
          </div>
        )}

        <div className="flex items-center gap-3">
          <Calendar className="h-4 w-4 shrink-0 text-violet-400" />
          <div>
            <p className="text-xs text-gray-500">Fecha</p>
            <p className="text-sm font-medium text-white">
              {formatDate(appointment.date)}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <Clock className="h-4 w-4 shrink-0 text-violet-400" />
          <div>
            <p className="text-xs text-gray-500">Hora</p>
            <p className="text-sm font-medium text-white">
              {formatTime(appointment.start_time)}
            </p>
          </div>
        </div>

        {business.address && (
          <div className="flex items-center gap-3">
            <MapPin className="h-4 w-4 shrink-0 text-violet-400" />
            <div>
              <p className="text-xs text-gray-500">Dirección</p>
              <p className="text-sm font-medium text-white">
                {business.address}
                {business.city && `, ${business.city}`}
              </p>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Render cancel button and dialog
  function renderCancelSection() {
    if (!canCancel) return null;

    const penalty = wouldIncurPenalty();
    const penaltyAmount = getPenaltyAmount();

    return (
      <>
        <div className="w-full max-w-sm mt-4">
          <Button
            fullWidth
            variant="outline"
            className="border-red-800 text-red-400 hover:bg-red-950 hover:text-red-300"
            onClick={() => setShowCancelDialog(true)}
          >
            <XCircle className="h-4 w-4" />
            Cancelar cita
          </Button>
        </div>

        {/* Cancel confirmation dialog */}
        {showCancelDialog && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
            <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-500/10">
                  <AlertTriangle className="h-5 w-5 text-red-400" />
                </div>
                <h3 className="text-lg font-bold text-white">
                  Cancelar cita
                </h3>
              </div>

              {penalty ? (
                <div className="space-y-3">
                  <p className="text-sm text-gray-300">
                    Estás cancelando con menos de{' '}
                    <span className="font-semibold text-white">
                      {business.cancellation_deadline_hours} horas
                    </span>{' '}
                    de anticipación.
                  </p>
                  <div className="rounded-lg bg-red-500/10 border border-red-500/20 px-4 py-3">
                    <p className="text-sm font-medium text-red-400">
                      Se aplicará una penalización de{' '}
                      <span className="font-bold">
                        {formatCurrency(penaltyAmount)}
                      </span>{' '}
                      ({business.cancellation_policy_pct}% del servicio) que se
                      sumará al precio de tu próxima reserva.
                    </p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-300">
                  ¿Estás seguro de que deseas cancelar esta cita? Esta acción no
                  se puede deshacer.
                </p>
              )}

              {cancelMutation.isError && (
                <div className="mt-3 rounded-lg bg-red-500/10 px-4 py-2 text-sm text-red-400">
                  Error al cancelar la cita. Intenta de nuevo.
                </div>
              )}

              <div className="mt-5 flex gap-3">
                <Button
                  fullWidth
                  variant="outline"
                  className="border-gray-700 text-gray-300 hover:bg-gray-800"
                  onClick={() => setShowCancelDialog(false)}
                  disabled={cancelMutation.isPending}
                >
                  Volver
                </Button>
                <Button
                  fullWidth
                  variant="destructive"
                  onClick={handleCancel}
                  loading={cancelMutation.isPending}
                >
                  {penalty ? 'Cancelar con penalización' : 'Sí, cancelar'}
                </Button>
              </div>
            </div>
          </div>
        )}
      </>
    );
  }

  // --- Status-specific views ---

  // Cancelled
  if (status === 'cancelled') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
        <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-red-500/10">
            <Ban className="h-8 w-8 text-red-400" />
          </div>
          <h2 className="mt-4 text-xl font-bold text-white">Cita cancelada</h2>
          <p className="mt-2 text-sm text-gray-400">
            {appointment.cancelled_by === 'customer'
              ? 'Cancelaste esta cita.'
              : appointment.cancelled_by === 'business'
                ? `${business.name} canceló esta cita.`
                : 'Esta cita ha sido cancelada y ya no es válida.'}
          </p>
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>
        <p className="mt-6 text-xs text-gray-600">
          Gestionado por{' '}
          <span className="font-semibold text-violet-500">Agendify</span>
        </p>
      </div>
    );
  }

  // Completed
  if (status === 'completed') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
        <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-gray-500/10">
            <CheckCircle className="h-8 w-8 text-gray-400" />
          </div>
          <h2 className="mt-4 text-xl font-bold text-white">Servicio completado</h2>
          <p className="mt-2 text-sm text-gray-400">
            Tu cita ya fue atendida. Gracias por tu visita.
          </p>
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>
        <p className="mt-6 text-xs text-gray-600">
          Gestionado por{' '}
          <span className="font-semibold text-violet-500">Agendify</span>
        </p>
      </div>
    );
  }

  // Checked in
  if (status === 'checked_in') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
        <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-violet-500/10">
            <CheckCircle className="h-8 w-8 text-violet-400" />
          </div>
          <h2 className="mt-4 text-xl font-bold text-white">Ya te registraste</h2>
          <p className="mt-2 text-sm text-gray-400">
            Tu llegada ha sido confirmada. Pronto serás atendido.
          </p>
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>
        <p className="mt-6 text-xs text-gray-600">
          Gestionado por{' '}
          <span className="font-semibold text-violet-500">Agendify</span>
        </p>
      </div>
    );
  }

  // Payment sent — waiting for confirmation
  if (status === 'payment_sent') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
        <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-blue-500/10">
            <ClockIcon className="h-8 w-8 text-blue-400" />
          </div>
          <h2 className="mt-4 text-xl font-bold text-white">Comprobante en revisión</h2>
          <p className="mt-2 text-sm text-gray-400">
            Tu comprobante de pago está siendo revisado por el negocio.
            Te notificaremos cuando sea confirmado.
          </p>
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>

        {renderCancelSection()}

        <p className="mt-6 text-xs text-gray-600">
          Gestionado por{' '}
          <span className="font-semibold text-violet-500">Agendify</span>
        </p>
      </div>
    );
  }

  // Check if there was a previous rejection
  const wasRejected = appointment.payment?.status === 'rejected';
  const rejectionReason = appointment.payment?.rejection_reason;

  // Pending payment — show payment instructions + upload area
  if (status === 'pending_payment') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
        {/* Rejection warning */}
        {wasRejected && (
          <div className="w-full max-w-sm mb-4">
            <div className="rounded-2xl bg-red-500/10 border border-red-500/20 px-6 py-4">
              <div className="flex items-center gap-2 mb-2">
                <XCircle className="h-5 w-5 text-red-400 shrink-0" />
                <h3 className="font-semibold text-red-400">Comprobante rechazado</h3>
              </div>
              <p className="text-sm text-gray-300">
                Tu comprobante anterior fue rechazado.
                {rejectionReason && (
                  <>
                    {' '}
                    <span className="font-medium text-white">Motivo: {rejectionReason}</span>
                  </>
                )}
              </p>
              <p className="text-sm text-gray-400 mt-2">
                Sube un nuevo comprobante para confirmar tu cita.
              </p>
            </div>
          </div>
        )}

        <div className="w-full max-w-sm rounded-2xl bg-gray-900 border border-gray-800 px-6 py-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-amber-500/10">
            <CreditCard className="h-8 w-8 text-amber-400" />
          </div>
          <h2 className="mt-4 text-xl font-bold text-white">
            {wasRejected ? 'Sube un nuevo comprobante' : 'Realiza tu pago'}
          </h2>
          <p className="mt-2 text-sm text-gray-400">
            {wasRejected
              ? 'Tu comprobante anterior fue rechazado. Sube uno nuevo para confirmar tu cita.'
              : 'Tu cita está reservada. Realiza el pago para confirmarla.'}
          </p>
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>

        {renderPaymentInstructions()}

        {/* Upload proof area */}
        <div className="w-full max-w-sm mt-4">
          <div className="rounded-2xl bg-gray-900 border border-gray-800 px-6 py-5">
            <div className="flex items-center gap-2 mb-3">
              <Upload className="h-5 w-5 text-violet-400" />
              <h3 className="font-semibold text-white">Subir comprobante</h3>
            </div>
            <p className="text-sm text-gray-400 mb-4">
              Sube una captura o foto de tu comprobante de pago para que el negocio lo revise.
            </p>

            {paymentMutation.isSuccess ? (
              <div className="flex flex-col items-center gap-2 py-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-green-500/10">
                  <CheckCircle className="h-6 w-6 text-green-400" />
                </div>
                <p className="text-sm font-medium text-green-400">
                  Comprobante enviado
                </p>
                <p className="text-xs text-gray-500">
                  El negocio revisará tu comprobante pronto
                </p>
              </div>
            ) : (
              <>
                {/* Email verification — shown when no saved customer data */}
                {!savedCustomer?.email && (
                  <div className="mb-4">
                    <Input
                      label="Correo electrónico"
                      placeholder="El correo con el que reservaste"
                      type="email"
                      value={verifyEmail}
                      onChange={(e) => setVerifyEmail(e.target.value)}
                      className="bg-gray-800 border-gray-700 text-white placeholder-gray-500"
                    />
                    <p className="mt-1 text-xs text-gray-500">
                      Ingresa tu correo electrónico para verificar tu identidad
                    </p>
                  </div>
                )}

                {/* Drop zone */}
                <div
                  className="relative rounded-xl border-2 border-dashed border-gray-700 hover:border-violet-500 transition-colors cursor-pointer p-6"
                  onClick={() => fileInputRef.current?.click()}
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={handleDrop}
                >
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={handleFileInputChange}
                  />

                  {previewUrl ? (
                    <div className="flex flex-col items-center gap-3">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={previewUrl}
                        alt="Vista previa del comprobante"
                        className="max-h-40 rounded-lg object-contain"
                      />
                      <p className="text-xs text-gray-400">
                        Toca para cambiar la imagen
                      </p>
                    </div>
                  ) : (
                    <div className="flex flex-col items-center gap-2">
                      <ImageIcon className="h-8 w-8 text-gray-600" />
                      <p className="text-sm text-gray-400">
                        Toca para seleccionar una imagen
                      </p>
                      <p className="text-xs text-gray-600">
                        o arrastra y suelta aquí
                      </p>
                    </div>
                  )}
                </div>

                {paymentMutation.isError && (
                  <p className="mt-2 text-xs text-red-400 text-center">
                    Error al enviar el comprobante. Intenta de nuevo.
                  </p>
                )}

                {/* Submit button */}
                <Button
                  fullWidth
                  className="mt-4 bg-violet-600 hover:bg-violet-700"
                  disabled={!selectedFile || !customerEmail}
                  loading={paymentMutation.isPending}
                  onClick={handleSubmitProof}
                >
                  <Upload className="h-4 w-4" />
                  Subir comprobante de pago
                </Button>
              </>
            )}
          </div>
        </div>

        {renderCancelSection()}

        <p className="mt-6 text-xs text-gray-600">
          Gestionado por{' '}
          <span className="font-semibold text-violet-500">Agendify</span>
        </p>
      </div>
    );
  }

  // Confirmed — Basic card (Plan Basico) or VIP ticket (Plan Profesional+)
  if (!ticketVip) {
    // Basic plan — simple info card, no QR, no download/share
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50 p-4">
        <div className="w-full max-w-sm rounded-2xl bg-white shadow-md border border-gray-200 px-6 py-8">
          {/* Business name */}
          <div className="text-center">
            <h2 className="text-xl font-bold text-gray-900">{business.name}</h2>
          </div>

          {/* Status badge */}
          <div className="mt-3 flex justify-center">
            <span
              className="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold"
              style={{
                backgroundColor: statusInfo.color + '20',
                color: statusInfo.color,
              }}
            >
              {statusInfo.label}
            </span>
          </div>

          {/* Details */}
          <div className="mt-6 space-y-4">
            <div className="flex items-center gap-3">
              <User className="h-4 w-4 shrink-0 text-violet-600" />
              <div>
                <p className="text-xs text-gray-500">Cliente</p>
                <p className="text-sm font-medium text-gray-900">
                  {appointment.customer?.name}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Scissors className="h-4 w-4 shrink-0 text-violet-600" />
              <div>
                <p className="text-xs text-gray-500">Servicio</p>
                <p className="text-sm font-medium text-gray-900">
                  {appointment.service?.name}
                </p>
              </div>
            </div>

            {appointment.employee && (
              <div className="flex items-center gap-3">
                <User className="h-4 w-4 shrink-0 text-violet-600" />
                <div>
                  <p className="text-xs text-gray-500">Profesional</p>
                  <p className="text-sm font-medium text-gray-900">
                    {appointment.employee.name}
                  </p>
                </div>
              </div>
            )}

            <div className="flex items-center gap-3">
              <Calendar className="h-4 w-4 shrink-0 text-violet-600" />
              <div>
                <p className="text-xs text-gray-500">Fecha</p>
                <p className="text-sm font-medium text-gray-900">
                  {formatDate(appointment.date)}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Clock className="h-4 w-4 shrink-0 text-violet-600" />
              <div>
                <p className="text-xs text-gray-500">Hora</p>
                <p className="text-sm font-medium text-gray-900">
                  {formatTime(appointment.start_time)}
                </p>
              </div>
            </div>

            {business.address && (
              <div className="flex items-center gap-3">
                <MapPin className="h-4 w-4 shrink-0 text-violet-600" />
                <div>
                  <p className="text-xs text-gray-500">Direccion</p>
                  <p className="text-sm font-medium text-gray-900">
                    {business.address}
                    {business.city && `, ${business.city}`}
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Ticket code */}
          <div className="mt-6 text-center">
            <p className="text-xs text-gray-500">Codigo de tu cita</p>
            <p className="mt-1 font-mono text-lg font-bold tracking-wider text-violet-600">
              {code}
            </p>
            <p className="mt-1 text-xs text-gray-400">
              Presenta este codigo al llegar
            </p>
          </div>
        </div>

        {canCancel && (
          <div className="w-full max-w-sm mt-4">
            <Button
              fullWidth
              variant="outline"
              className="border-red-300 text-red-600 hover:bg-red-50 hover:text-red-700"
              onClick={() => setShowCancelDialog(true)}
            >
              <XCircle className="h-4 w-4" />
              Cancelar cita
            </Button>
          </div>
        )}

        {/* Cancel dialog — reuse same logic but with light theme */}
        {showCancelDialog && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-sm rounded-2xl bg-white border border-gray-200 px-6 py-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-50">
                  <AlertTriangle className="h-5 w-5 text-red-500" />
                </div>
                <h3 className="text-lg font-bold text-gray-900">
                  Cancelar cita
                </h3>
              </div>

              {wouldIncurPenalty() ? (
                <div className="space-y-3">
                  <p className="text-sm text-gray-600">
                    Estas cancelando con menos de{' '}
                    <span className="font-semibold text-gray-900">
                      {business.cancellation_deadline_hours} horas
                    </span>{' '}
                    de anticipacion.
                  </p>
                  <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3">
                    <p className="text-sm font-medium text-red-600">
                      Se aplicara una penalizacion de{' '}
                      <span className="font-bold">
                        {formatCurrency(getPenaltyAmount())}
                      </span>{' '}
                      ({business.cancellation_policy_pct}% del servicio) que se
                      sumara al precio de tu proxima reserva.
                    </p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-600">
                  Estas seguro de que deseas cancelar esta cita? Esta accion no
                  se puede deshacer.
                </p>
              )}

              {cancelMutation.isError && (
                <div className="mt-3 rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600">
                  Error al cancelar la cita. Intenta de nuevo.
                </div>
              )}

              <div className="mt-5 flex gap-3">
                <Button
                  fullWidth
                  variant="outline"
                  className="border-gray-300 text-gray-600 hover:bg-gray-50"
                  onClick={() => setShowCancelDialog(false)}
                  disabled={cancelMutation.isPending}
                >
                  Volver
                </Button>
                <Button
                  fullWidth
                  variant="destructive"
                  onClick={handleCancel}
                  loading={cancelMutation.isPending}
                >
                  {wouldIncurPenalty() ? 'Cancelar con penalizacion' : 'Si, cancelar'}
                </Button>
              </div>
            </div>
          </div>
        )}

        {/* Footer */}
        <p className="mt-6 text-xs text-gray-400">
          Gestionado por{' '}
          <span className="font-semibold text-violet-600">Agendify</span>
        </p>
      </div>
    );
  }

  // VIP ticket (Plan Profesional+) — full design with QR + download + share
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gray-950 p-4">
      {/* Ticket card — wrapped for screenshot capture */}
      <div ref={ticketRef} className="w-full max-w-sm">
        {/* Top section */}
        <div className="rounded-t-2xl bg-gray-900 px-6 pt-6 pb-4 border border-gray-800 border-b-0">
          {/* Brand */}
          <div className="text-center">
            <h1 className="text-lg font-bold tracking-widest text-violet-400">
              AGENDIFY
            </h1>
            <div className="mt-1 h-px bg-gradient-to-r from-transparent via-violet-600 to-transparent" />
          </div>

          {/* Business name */}
          <div className="mt-4 text-center">
            <h2 className="text-xl font-bold text-white">{business.name}</h2>
          </div>

          {/* Status badge */}
          <div className="mt-3 flex justify-center">
            <span
              className="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold"
              style={{
                backgroundColor: statusInfo.color + '20',
                color: statusInfo.color,
              }}
            >
              {statusInfo.label}
            </span>
          </div>

          {/* Details */}
          <div className="mt-6">
            {renderAppointmentDetails()}
          </div>
        </div>

        {/* Divider — perforated line effect */}
        <div className="relative border-x border-gray-800 bg-gray-900">
          <div className="absolute -left-2.5 top-1/2 h-5 w-5 -translate-y-1/2 rounded-full bg-gray-950" />
          <div className="absolute -right-2.5 top-1/2 h-5 w-5 -translate-y-1/2 rounded-full bg-gray-950" />
          <div className="mx-8 border-t border-dashed border-gray-700 py-0" />
        </div>

        {/* Bottom section — QR Code */}
        <div className="rounded-b-2xl bg-gray-900 px-6 pt-4 pb-6 border border-gray-800 border-t-0">
          <div className="flex flex-col items-center">
            {/* QR Code */}
            <div className="rounded-xl bg-white p-3">
              <QRCodeSVG
                value={ticketUrl}
                size={140}
                level="M"
                fgColor="#1F2937"
                bgColor="#FFFFFF"
              />
            </div>

            {/* Ticket code */}
            <p className="mt-3 text-center font-mono text-lg font-bold tracking-wider text-violet-400">
              {code}
            </p>
            <p className="mt-1 text-xs text-gray-500">
              Presenta este codigo al llegar
            </p>
          </div>
        </div>
      </div>

      {/* Action buttons */}
      <div className="mt-6 w-full max-w-sm flex gap-3">
        <Button
          fullWidth
          variant="outline"
          className="border-gray-700 text-gray-300 hover:bg-gray-800 hover:text-white"
          onClick={handleDownload}
          loading={downloading}
          disabled={downloading}
        >
          <Download className="h-4 w-4" />
          Guardar
        </Button>
        {typeof navigator !== 'undefined' && 'share' in navigator && (
          <Button
            fullWidth
            variant="outline"
            className="border-gray-700 text-gray-300 hover:bg-gray-800 hover:text-white"
            onClick={handleShare}
          >
            <Share2 className="h-4 w-4" />
            Compartir
          </Button>
        )}
      </div>

      {renderCancelSection()}

      {/* Footer */}
      <p className="mt-6 text-xs text-gray-600">
        Gestionado por{' '}
        <span className="font-semibold text-violet-500">Agendify</span>
      </p>
    </div>
  );
}
