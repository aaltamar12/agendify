'use client';

import { useState, useMemo, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import {
  CreditCard,
  User,
  Phone,
  Scissors,
  DollarSign,
  Calendar,
  Clock,
  ImageIcon,
  CheckCircle2,
  XCircle,
  Inbox,
  Search,
  Hash,
  Bell,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { ImageViewerModal } from '@/components/shared/image-viewer-modal';
import {
  usePendingProofs,
  useWaitingPayment,
  useApprovedPayments,
  useRejectedPayments,
  useApprovePayment,
  useRejectPayment,
  useSendPaymentReminder,
} from '@/lib/hooks/use-payments';
import { formatDate, formatTime } from '@/lib/utils/date';
import { formatCurrency, formatPhone } from '@/lib/utils/format';
import { useUIStore } from '@/lib/stores/ui-store';
import type { Appointment } from '@/lib/api/types';
import { cn } from '@/lib/utils/cn';

type Tab = 'proofs' | 'waiting' | 'approved' | 'rejected';

const TABS: { key: Tab; label: string }[] = [
  { key: 'proofs', label: 'Pendientes' },
  { key: 'waiting', label: 'Sin comprobante' },
  { key: 'approved', label: 'Aprobados' },
  { key: 'rejected', label: 'Rechazados' },
];

function filterAppointments(
  appointments: Appointment[],
  search: string,
): Appointment[] {
  if (!search.trim()) return appointments;
  const q = search.toLowerCase().trim();
  return appointments.filter((a) => {
    const name = a.customer?.name?.toLowerCase() ?? '';
    const phone = a.customer?.phone?.toLowerCase() ?? '';
    const ticketCode = a.ticket_code?.toLowerCase() ?? '';
    return name.includes(q) || phone.includes(q) || ticketCode.includes(q);
  });
}

/** Returns a human-readable relative time string in Spanish. */
function timeAgo(dateStr: string): string {
  const now = new Date();
  const date = new Date(dateStr);
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60_000);

  if (diffMin < 1) return 'Hace un momento';
  if (diffMin < 60) return `Hace ${diffMin} min`;
  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return `Hace ${diffHours}h`;
  const diffDays = Math.floor(diffHours / 24);
  return `Hace ${diffDays}d`;
}

/** Checks if the appointment was created more than 15 minutes ago. */
function isOlderThan15Min(dateStr: string): boolean {
  const now = new Date();
  const date = new Date(dateStr);
  return now.getTime() - date.getTime() > 15 * 60_000;
}

export default function PaymentsPage() {
  return (
    <Suspense fallback={<LoadingSkeleton />}>
      <PaymentsPageContent />
    </Suspense>
  );
}

function PaymentsPageContent() {
  const searchParams = useSearchParams();
  const addToast = useUIStore((s) => s.addToast);
  const [activeTab, setActiveTab] = useState<Tab>(
    (searchParams.get('tab') as Tab) || 'proofs',
  );
  const [search, setSearch] = useState(searchParams.get('search') || '');

  // Image viewer state
  const [viewerOpen, setViewerOpen] = useState(false);
  const [viewerImageUrl, setViewerImageUrl] = useState('');

  // Queries
  const { data: proofsData, isLoading: proofsLoading } = usePendingProofs();
  const { data: waitingData, isLoading: waitingLoading } = useWaitingPayment();
  const { data: approvedData, isLoading: approvedLoading } =
    useApprovedPayments();
  const { data: rejectedData, isLoading: rejectedLoading } =
    useRejectedPayments();

  // Mutations
  const approvePayment = useApprovePayment();
  const rejectPayment = useRejectPayment();
  const sendReminder = useSendPaymentReminder();

  const proofsAppointments = proofsData?.data ?? [];
  const waitingAppointments = waitingData?.data ?? [];
  const approvedAppointments = approvedData?.data ?? [];
  const rejectedAppointments = rejectedData?.data ?? [];

  const headerBadgeCount =
    proofsAppointments.length + waitingAppointments.length;

  // Handlers
  async function handleApprove(appointment: Appointment) {
    if (!appointment.payment) return;
    try {
      await approvePayment.mutateAsync(appointment.payment.id);
      addToast({ type: 'success', message: 'Pago aprobado exitosamente' });
    } catch {
      addToast({ type: 'error', message: 'Error al aprobar el pago' });
    }
  }

  // Rejection modal state
  const [rejectTarget, setRejectTarget] = useState<Appointment | null>(null);
  const [rejectReason, setRejectReason] = useState('');

  function openRejectModal(appointment: Appointment) {
    setRejectTarget(appointment);
    setRejectReason('');
  }

  async function confirmReject() {
    if (!rejectTarget?.payment) return;
    try {
      await rejectPayment.mutateAsync({
        paymentId: rejectTarget.payment.id,
        reason: rejectReason.trim() || undefined,
      });
      addToast({ type: 'success', message: 'Pago rechazado' });
      setRejectTarget(null);
      setRejectReason('');
    } catch {
      addToast({ type: 'error', message: 'Error al rechazar el pago' });
    }
  }

  async function handleRemind(appointment: Appointment) {
    try {
      await sendReminder.mutateAsync(appointment.id);
      addToast({
        type: 'success',
        message: 'Recordatorio enviado al cliente',
      });
    } catch {
      addToast({
        type: 'error',
        message: 'Error al enviar el recordatorio',
      });
    }
  }

  function handleViewProof(url: string) {
    setViewerImageUrl(url);
    setViewerOpen(true);
  }

  // Tab content
  function getTabData(): {
    appointments: Appointment[];
    isLoading: boolean;
  } {
    switch (activeTab) {
      case 'proofs':
        return { appointments: proofsAppointments, isLoading: proofsLoading };
      case 'waiting':
        return { appointments: waitingAppointments, isLoading: waitingLoading };
      case 'approved':
        return {
          appointments: approvedAppointments,
          isLoading: approvedLoading,
        };
      case 'rejected':
        return {
          appointments: rejectedAppointments,
          isLoading: rejectedLoading,
        };
    }
  }

  const { appointments: rawAppointments, isLoading } = getTabData();

  const appointments = useMemo(
    () => filterAppointments(rawAppointments, search),
    [rawAppointments, search],
  );

  function getTabCount(tab: Tab): number {
    switch (tab) {
      case 'proofs':
        return proofsAppointments.length;
      case 'waiting':
        return waitingAppointments.length;
      case 'approved':
        return approvedAppointments.length;
      case 'rejected':
        return rejectedAppointments.length;
    }
  }

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="border-b border-gray-200 bg-white px-4 py-4 sm:px-6">
        <div className="flex items-center gap-3">
          <CreditCard className="h-6 w-6 text-violet-600" />
          <h1 className="text-lg font-semibold text-gray-900 sm:text-xl">
            Pagos
          </h1>
          {headerBadgeCount > 0 && (
            <span className="inline-flex items-center justify-center rounded-full bg-violet-600 px-2.5 py-0.5 text-xs font-medium text-white">
              {headerBadgeCount}
            </span>
          )}
        </div>
      </div>

      {/* Search bar */}
      <div className="border-b border-gray-200 bg-white px-4 py-3 sm:px-6">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Buscar por nombre, teléfono o código de cita..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-gray-300 bg-white py-2 pl-10 pr-4 text-sm text-gray-900 placeholder-gray-400 focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 bg-white px-4 sm:px-6">
        <div className="-mb-px flex gap-0 overflow-x-auto">
          {TABS.map((tab) => {
            const count = getTabCount(tab.key);
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={cn(
                  'relative cursor-pointer whitespace-nowrap px-4 py-3 text-sm font-medium transition-colors',
                  activeTab === tab.key
                    ? 'text-violet-600'
                    : 'text-gray-500 hover:text-gray-700',
                )}
              >
                {tab.label}
                {count > 0 && (
                  <span className="ml-1.5 inline-flex items-center justify-center rounded-full bg-violet-100 px-1.5 py-0.5 text-[10px] font-medium text-violet-700">
                    {count}
                  </span>
                )}
                {activeTab === tab.key && (
                  <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-violet-600" />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto bg-gray-50 p-4 sm:p-6">
        {isLoading ? (
          <LoadingSkeleton />
        ) : appointments.length === 0 ? (
          search.trim() ? (
            <EmptySearchState />
          ) : (
            <EmptyState tab={activeTab} />
          )
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {appointments.map((appointment) => (
              <PaymentCard
                key={appointment.id}
                appointment={appointment}
                tab={activeTab}
                onApprove={() => handleApprove(appointment)}
                onReject={() => openRejectModal(appointment)}
                onRemind={() => handleRemind(appointment)}
                onViewProof={handleViewProof}
                isApproving={approvePayment.isPending}
                isRejecting={rejectPayment.isPending}
                isReminding={sendReminder.isPending}
              />
            ))}
          </div>
        )}
      </div>

      {/* Rejection reason modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white p-6 shadow-xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
                <XCircle className="h-5 w-5 text-red-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">
                Rechazar comprobante
              </h3>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              El cliente será notificado por correo y podrá subir un nuevo comprobante.
            </p>
            <div className="mb-4">
              <label
                htmlFor="reject-reason"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Motivo del rechazo (opcional)
              </label>
              <textarea
                id="reject-reason"
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Ej: El comprobante no es legible, el monto no coincide..."
                rows={3}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500"
              />
            </div>
            <div className="flex gap-3">
              <Button
                fullWidth
                variant="outline"
                onClick={() => {
                  setRejectTarget(null);
                  setRejectReason('');
                }}
                disabled={rejectPayment.isPending}
              >
                Cancelar
              </Button>
              <Button
                fullWidth
                variant="destructive"
                onClick={confirmReject}
                loading={rejectPayment.isPending}
              >
                <XCircle className="h-4 w-4" />
                Rechazar
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Image viewer modal */}
      <ImageViewerModal
        open={viewerOpen}
        onClose={() => setViewerOpen(false)}
        imageUrl={viewerImageUrl}
      />
    </div>
  );
}

// --- Payment Card ---

interface PaymentCardProps {
  appointment: Appointment;
  tab: Tab;
  onApprove: () => void;
  onReject: () => void;
  onRemind: () => void;
  onViewProof: (url: string) => void;
  isApproving: boolean;
  isRejecting: boolean;
  isReminding: boolean;
}

function PaymentCard({
  appointment,
  tab,
  onApprove,
  onReject,
  onRemind,
  onViewProof,
  isApproving,
  isRejecting,
  isReminding,
}: PaymentCardProps) {
  const payment = appointment.payment;
  const paymentMethod = payment?.payment_method ?? 'No especificado';

  return (
    <div className="flex h-full flex-col rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
      {/* Ticket code header */}
      {(
        <div className="mb-2 flex items-center gap-2 border-b border-gray-100 pb-2">
          <Hash className="h-4 w-4 text-violet-500" />
          <span className="font-mono text-sm font-bold text-gray-900">
            {appointment.ticket_code}
          </span>
        </div>
      )}

      {/* Customer info + badge */}
      <div className="mb-3 flex items-start justify-between">
        <div className="space-y-1">
          {appointment.customer && (
            <>
              <div className="flex items-center gap-2 text-sm font-medium text-gray-900">
                <User className="h-4 w-4 text-gray-400" />
                <span>{appointment.customer.name}</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <Phone className="h-3.5 w-3.5 text-gray-400" />
                <span>{formatPhone(appointment.customer.phone)}</span>
              </div>
            </>
          )}
        </div>

        {/* Status badge */}
        {tab === 'proofs' && (
          <Badge variant="info">Comprobante enviado</Badge>
        )}
        {tab === 'waiting' && (
          <Badge variant="warning">Esperando pago</Badge>
        )}
        {tab === 'approved' && <Badge variant="success">Aprobado</Badge>}
        {tab === 'rejected' && <Badge variant="error">Rechazado</Badge>}
      </div>

      {/* Service and price */}
      <div className="mb-3 space-y-1.5">
        {appointment.service && (
          <div className="flex items-center gap-2 text-sm text-gray-700">
            <Scissors className="h-4 w-4 text-gray-400" />
            <span>{appointment.service.name}</span>
          </div>
        )}
        <div className="flex items-center gap-2 text-sm font-semibold text-gray-900">
          <DollarSign className="h-4 w-4 text-gray-400" />
          <span>{formatCurrency(appointment.price)}</span>
        </div>
        {Number(appointment.credits_applied) > 0 && (
          <div className="ml-6 space-y-0.5">
            <p className="text-xs text-gray-500">
              Precio original: {formatCurrency(Number(appointment.price) + Number(appointment.credits_applied))}
            </p>
            <p className="text-xs font-medium text-green-600">
              Creditos: -{formatCurrency(Number(appointment.credits_applied))}
            </p>
          </div>
        )}
      </div>

      {/* Date and time */}
      <div className="mb-3 space-y-1.5">
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <Calendar className="h-3.5 w-3.5 text-gray-400" />
          <span>{formatDate(appointment.date)}</span>
        </div>
        <div className="flex items-center gap-2 text-xs text-gray-500">
          <Clock className="h-3.5 w-3.5 text-gray-400" />
          <span>
            {formatTime(appointment.start_time)} -{' '}
            {formatTime(appointment.end_time)}
          </span>
        </div>
      </div>

      {/* Payment method */}
      <div className="mb-3 flex items-center gap-2 text-xs text-gray-500">
        <CreditCard className="h-3.5 w-3.5 text-gray-400" />
        <span className="capitalize">{paymentMethod}</span>
      </div>

      {/* Time since booking — only on "Sin comprobante" tab */}
      {tab === 'waiting' && (
        <div className="mb-3 text-xs text-amber-600">
          {timeAgo(appointment.created_at)}
        </div>
      )}

      {/* Proof image thumbnail — on proofs/approved/rejected tabs */}
      {payment?.proof_url && tab !== 'waiting' && (
        <button
          onClick={() => onViewProof(payment.proof_url!)}
          className="mb-3 flex w-full items-center gap-2 rounded-lg border border-gray-200 p-2 text-xs text-violet-600 transition-colors hover:bg-violet-50"
        >
          <ImageIcon className="h-4 w-4" />
          <span>Ver comprobante</span>
          {/* Small thumbnail */}
          <div className="ml-auto h-10 w-10 overflow-hidden rounded-md border border-gray-200">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={payment.proof_url}
              alt="Comprobante"
              className="h-full w-full object-cover"
            />
          </div>
        </button>
      )}

      {/* Approval/rejection dates */}
      {tab === 'approved' && payment?.approved_at && (
        <div className="mb-3 flex items-center gap-2 text-xs text-green-600">
          <CheckCircle2 className="h-3.5 w-3.5" />
          <span>Aprobado el {formatDate(payment.approved_at)}</span>
        </div>
      )}
      {tab === 'rejected' && payment?.rejected_at && (
        <div className="mb-3 space-y-1">
          <div className="flex items-center gap-2 text-xs text-red-600">
            <XCircle className="h-3.5 w-3.5" />
            <span>Rechazado el {formatDate(payment.rejected_at)}</span>
          </div>
          {payment.rejection_reason && (
            <p className="pl-5 text-xs text-gray-500">
              Motivo: {payment.rejection_reason}
            </p>
          )}
        </div>
      )}

      {/* Action buttons — only for "Pendientes" tab (payment_sent — has proof) */}
      {tab === 'proofs' && (
        <div className="mt-auto flex gap-2 border-t border-gray-100 pt-3">
          <Button
            size="sm"
            onClick={onApprove}
            loading={isApproving}
            className="flex-1 bg-green-600 hover:bg-green-700"
          >
            <CheckCircle2 className="h-4 w-4" />
            Aprobar
          </Button>
          <Button
            variant="destructive"
            size="sm"
            onClick={onReject}
            loading={isRejecting}
            className="flex-1"
          >
            <XCircle className="h-4 w-4" />
            Rechazar
          </Button>
        </div>
      )}

      {/* "Notificar al cliente" — only for "Sin comprobante" tab, after 15min */}
      {tab === 'waiting' && (
        <div className="border-t border-gray-100 pt-3">
          {isOlderThan15Min(appointment.created_at) ? (
            <Button
              size="sm"
              variant="outline"
              onClick={onRemind}
              loading={isReminding}
              className="w-full"
            >
              <Bell className="h-4 w-4" />
              Notificar al cliente
            </Button>
          ) : (
            <p className="text-center text-xs text-amber-600">
              El cliente aún no ha enviado su comprobante
            </p>
          )}
        </div>
      )}
    </div>
  );
}

// --- Empty state ---

function EmptyState({ tab }: { tab: Tab }) {
  const messages: Record<Tab, { title: string; description: string }> = {
    proofs: {
      title: 'No hay comprobantes por revisar',
      description:
        'Cuando un cliente envíe un comprobante de pago, aparecerá aquí para que lo apruebes.',
    },
    waiting: {
      title: 'No hay citas esperando pago',
      description:
        'Cuando un cliente tenga una cita pendiente de pago, aparecerá aquí.',
    },
    approved: {
      title: 'No hay pagos aprobados',
      description: 'Los pagos que apruebes aparecerán aquí.',
    },
    rejected: {
      title: 'No hay pagos rechazados',
      description: 'Los pagos que rechaces aparecerán aquí.',
    },
  };

  const { title, description } = messages[tab];

  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-100">
        <Inbox className="h-8 w-8 text-gray-400" />
      </div>
      <h3 className="text-base font-medium text-gray-900">{title}</h3>
      <p className="mt-1 max-w-sm text-sm text-gray-500">{description}</p>
    </div>
  );
}

// --- Empty search state ---

function EmptySearchState() {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-100">
        <Search className="h-8 w-8 text-gray-400" />
      </div>
      <h3 className="text-base font-medium text-gray-900">Sin resultados</h3>
      <p className="mt-1 max-w-sm text-sm text-gray-500">
        No se encontraron pagos que coincidan con tu búsqueda.
      </p>
    </div>
  );
}

// --- Loading skeleton ---

function LoadingSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: 6 }).map((_, i) => (
        <div
          key={i}
          className="space-y-3 rounded-xl border border-gray-200 bg-white p-4"
        >
          <div className="flex items-center gap-2">
            <Skeleton className="h-4 w-4 rounded-full" />
            <Skeleton className="h-4 w-32" />
          </div>
          <div className="flex items-center gap-2">
            <Skeleton className="h-4 w-4 rounded-full" />
            <Skeleton className="h-4 w-24" />
          </div>
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-40" />
          <Skeleton className="h-4 w-28" />
          <div className="flex gap-2 pt-2">
            <Skeleton className="h-8 flex-1" />
            <Skeleton className="h-8 flex-1" />
          </div>
        </div>
      ))}
    </div>
  );
}
