'use client';

import { useState } from 'react';
import {
  CheckCircle,
  Calendar,
  Clock,
  User,
  Scissors,
  MapPin,
  Ticket,
  CreditCard,
  Copy,
  Check,
  AlertTriangle,
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { Button, Card } from '@/components/ui';
import { useBookingStore } from '@/lib/stores/booking-store';
import { useBookAppointment } from '@/lib/hooks/use-public';
import { formatCurrency, formatDuration } from '@/lib/utils/format';
import { formatDate, formatTime } from '@/lib/utils/date';
import dayjs from 'dayjs';
import type { Business } from '@/lib/api/types';
import { saveCustomer } from '@/lib/utils/saved-customer';

interface BookingConfirmationProps {
  slug: string;
  business: Business;
}

export function BookingConfirmation({
  slug,
  business,
}: BookingConfirmationProps) {
  const {
    selectedService,
    selectedServices,
    selectedEmployee,
    selectedDate,
    selectedTime,
    customerInfo,
    reset,
  } = useBookingStore();

  const bookMutation = useBookAppointment();
  const [ticketCode, setTicketCode] = useState<string | null>(null);
  const [booked, setBooked] = useState(false);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [penaltyApplied, setPenaltyApplied] = useState<number>(0);
  // After booking, use the business from the API response (includes payment data via :with_payment view)
  // instead of the prop (which uses :public view and excludes payment fields).
  const [bookedBusiness, setBookedBusiness] = useState<Business | null>(null);

  const activeBusiness = bookedBusiness ?? business;

  const hasPaymentMethods =
    activeBusiness.nequi_phone || activeBusiness.daviplata_phone || activeBusiness.bancolombia_account;

  function handleCopy(text: string, field: string) {
    navigator.clipboard.writeText(text);
    setCopiedField(field);
    setTimeout(() => setCopiedField(null), 2000);
  }

  async function handleConfirm() {
    if (!selectedService || !selectedDate || !selectedTime || !customerInfo) {
      return;
    }

    try {
      // Additional services = all selected services except the primary (first) one
      const additionalServiceIds = selectedServices
        .slice(1)
        .map((s) => s.id);

      const result = await bookMutation.mutateAsync({
        slug,
        service_id: selectedService.id,
        employee_id: selectedEmployee?.id ?? null,
        date: selectedDate,
        start_time: selectedTime,
        customer: {
          name: customerInfo.name,
          email: customerInfo.email || '',
          phone: customerInfo.phone,
        },
        ...(additionalServiceIds.length > 0 && {
          additional_service_ids: additionalServiceIds,
        }),
      });

      // Save customer data for future bookings
      if (customerInfo) {
        saveCustomer({
          name: customerInfo.name,
          email: customerInfo.email || '',
          phone: customerInfo.phone,
        });
      }

      setTicketCode(result.data.ticket_code ?? null);
      setPenaltyApplied(result.data.penalty_applied ?? 0);
      if (result.data.business) {
        setBookedBusiness(result.data.business);
      }
      setBooked(true);
    } catch {
      // Error handled by mutation state
    }
  }

  // Success state
  if (booked) {
    return (
      <div className="space-y-6 text-center">
        <div className="flex justify-center">
          <div className="rounded-full bg-green-100 p-3">
            <CheckCircle className="h-10 w-10 text-green-600" />
          </div>
        </div>

        <div>
          <h2 className="text-xl font-bold text-gray-900">
            Reserva confirmada
          </h2>
          <p className="mt-2 text-sm text-gray-500">
            {ticketCode
              ? 'Tu cita ha sido agendada exitosamente'
              : 'Tu cita ha sido registrada. Te contactaremos para confirmar.'}
          </p>
        </div>

        <Card className="mx-auto max-w-sm text-left">
          <div className="space-y-3 text-sm">
            {ticketCode && (
              <div className="flex items-center gap-2 text-gray-600">
                <Ticket className="h-4 w-4 text-violet-600" />
                <span>
                  Código:{' '}
                  <span className="font-bold text-gray-900">{ticketCode}</span>
                </span>
              </div>
            )}
            <div className="flex items-center gap-2 text-gray-600">
              <Scissors className="h-4 w-4 text-violet-600" />
              <span>{selectedService?.name}</span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <Calendar className="h-4 w-4 text-violet-600" />
              <span>{selectedDate && formatDate(selectedDate)}</span>
            </div>
            <div className="flex items-center gap-2 text-gray-600">
              <Clock className="h-4 w-4 text-violet-600" />
              <span>{selectedTime && formatTime(selectedTime)}</span>
            </div>
          </div>

          {/* QR Code — only for plans with ticket digital */}
          {ticketCode && (
            <div className="mt-4 flex flex-col items-center border-t border-gray-100 pt-4">
              <div className="rounded-xl bg-white p-2 shadow-sm border border-gray-100">
                <QRCodeSVG
                  value={`${window.location.origin}/${slug}/ticket/${ticketCode}`}
                  size={180}
                  level="M"
                  fgColor="#1F2937"
                  bgColor="#FFFFFF"
                />
              </div>
              <p className="mt-2 text-xs text-gray-500">
                Muestra este código al llegar
              </p>
            </div>
          )}
        </Card>

        {/* Penalty notice */}
        {penaltyApplied > 0 && (
          <Card className="mx-auto max-w-sm bg-amber-50 border-amber-200">
            <div className="flex items-center gap-2 mb-2">
              <AlertTriangle className="h-5 w-5 text-amber-600" />
              <h3 className="font-semibold text-amber-900">
                Penalización aplicada
              </h3>
            </div>
            <p className="text-sm text-amber-700">
              Se ha sumado una penalización de{' '}
              <span className="font-bold">{formatCurrency(penaltyApplied)}</span>{' '}
              por una cancelación anterior. El precio total de esta cita incluye
              dicha penalización.
            </p>
          </Card>
        )}

        {/* Payment instructions after booking */}
        {hasPaymentMethods && (
          <Card className="mx-auto max-w-sm bg-violet-50 border-violet-200">
            <div className="flex items-center gap-2 mb-2">
              <CreditCard className="h-5 w-5 text-violet-600" />
              <h3 className="font-semibold text-violet-900">
                Instrucciones de pago
              </h3>
            </div>
            <p className="text-sm text-violet-700 mb-3">
              Para confirmar tu cita, realiza el pago por uno de estos medios:
            </p>
            <div className="space-y-2">
              {activeBusiness.nequi_phone && (
                <div className="flex items-center justify-between rounded-lg bg-white px-3 py-2 border border-violet-100">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-purple-600 text-xs font-bold text-white">N</div>
                    <div>
                      <p className="text-xs text-gray-500">Nequi</p>
                      <p className="text-sm font-medium text-gray-900">
                        {activeBusiness.nequi_phone}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleCopy(activeBusiness.nequi_phone!, 'nequi-confirm')}
                    className="rounded-lg p-2 text-violet-400 hover:bg-violet-100 transition-colors"
                  >
                    {copiedField === 'nequi-confirm' ? (
                      <Check className="h-4 w-4 text-green-500" />
                    ) : (
                      <Copy className="h-4 w-4" />
                    )}
                  </button>
                </div>
              )}
              {activeBusiness.daviplata_phone && (
                <div className="flex items-center justify-between rounded-lg bg-white px-3 py-2 border border-violet-100">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-red-600 text-xs font-bold text-white">D</div>
                    <div>
                      <p className="text-xs text-gray-500">Daviplata</p>
                      <p className="text-sm font-medium text-gray-900">
                        {activeBusiness.daviplata_phone}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleCopy(activeBusiness.daviplata_phone!, 'daviplata-confirm')}
                    className="rounded-lg p-2 text-violet-400 hover:bg-violet-100 transition-colors"
                  >
                    {copiedField === 'daviplata-confirm' ? (
                      <Check className="h-4 w-4 text-green-500" />
                    ) : (
                      <Copy className="h-4 w-4" />
                    )}
                  </button>
                </div>
              )}
              {activeBusiness.bancolombia_account && (
                <div className="flex items-center justify-between rounded-lg bg-white px-3 py-2 border border-violet-100">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-yellow-500 text-xs font-bold text-white">B</div>
                    <div>
                      <p className="text-xs text-gray-500">Bancolombia</p>
                      <p className="text-sm font-medium text-gray-900">
                        {activeBusiness.bancolombia_account}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleCopy(activeBusiness.bancolombia_account!, 'bancolombia-confirm')}
                    className="rounded-lg p-2 text-violet-400 hover:bg-violet-100 transition-colors"
                  >
                    {copiedField === 'bancolombia-confirm' ? (
                      <Check className="h-4 w-4 text-green-500" />
                    ) : (
                      <Copy className="h-4 w-4" />
                    )}
                  </button>
                </div>
              )}
            </div>
            <p className="mt-3 text-xs text-violet-600 text-center">
              Sube tu comprobante desde la página del ticket para confirmar tu cita
            </p>
          </Card>
        )}

        <div className="flex flex-col gap-3 sm:flex-row sm:justify-center">
          {ticketCode && (
            <Button
              variant="primary"
              onClick={() =>
                (window.location.href = `/${slug}/ticket/${ticketCode}`)
              }
            >
              Ver mi ticket
            </Button>
          )}
          <Button
            variant="outline"
            onClick={() => {
              reset();
              setTicketCode(null);
              setBooked(false);
            }}
          >
            Nueva reserva
          </Button>
        </div>
      </div>
    );
  }

  // Confirmation / summary state
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">
          Confirma tu reserva
        </h2>
        <p className="mt-1 text-sm text-gray-500">
          Revisa los detalles antes de confirmar
        </p>
      </div>

      <Card className="divide-y divide-gray-100">
        <div className="flex items-start gap-3 pb-4">
          <Scissors className="mt-0.5 h-5 w-5 shrink-0 text-violet-600" />
          <div className="flex-1">
            <p className="text-sm text-gray-500">
              {selectedServices.length > 1 ? `Servicios (${selectedServices.length})` : 'Servicio'}
            </p>
            {selectedServices.map((svc) => (
              <div key={svc.id} className="flex items-baseline justify-between gap-2">
                <p className="font-medium text-gray-900">{svc.name}</p>
                <p className="text-sm text-violet-600 font-semibold whitespace-nowrap">
                  {formatCurrency(svc.price)}
                </p>
              </div>
            ))}
            {selectedServices.length > 1 && (
              <div className="mt-1 flex items-baseline justify-between border-t border-gray-100 pt-1">
                <p className="text-sm font-medium text-gray-700">Total</p>
                <p className="text-sm font-bold text-violet-700">
                  {formatCurrency(selectedServices.reduce((sum, s) => sum + Number(s.price), 0))}
                </p>
              </div>
            )}
          </div>
        </div>

        <div className="flex items-start gap-3 py-4">
          <User className="mt-0.5 h-5 w-5 shrink-0 text-violet-600" />
          <div>
            <p className="text-sm text-gray-500">Profesional</p>
            <p className="font-medium text-gray-900">
              {selectedEmployee?.name ?? 'Cualquier disponible'}
            </p>
          </div>
        </div>

        <div className="flex items-start gap-3 py-4">
          <Calendar className="mt-0.5 h-5 w-5 shrink-0 text-violet-600" />
          <div>
            <p className="text-sm text-gray-500">Fecha y hora</p>
            <p className="font-medium text-gray-900">
              {selectedDate && formatDate(selectedDate)}
            </p>
            <p className="text-sm text-gray-600">
              {selectedTime && formatTime(selectedTime)}
            </p>
            {selectedServices.length > 0 && selectedTime && (() => {
              const totalMinutes = selectedServices.reduce((sum, s) => sum + s.duration_minutes, 0);
              return (
                <>
                  <p className="mt-1 text-sm text-gray-500">
                    Duración total estimada: <span className="font-semibold text-gray-700">{formatDuration(totalMinutes)}</span>
                  </p>
                  <p className="text-sm text-gray-500">
                    Tu cita terminaría aproximadamente a las{' '}
                    <span className="font-medium text-gray-700">
                      {formatTime(
                        dayjs(selectedTime, 'HH:mm')
                          .add(totalMinutes, 'minute')
                          .format('HH:mm')
                      )}
                    </span>
                  </p>
                </>
              );
            })()}
          </div>
        </div>

        <div className="flex items-start gap-3 py-4">
          <User className="mt-0.5 h-5 w-5 shrink-0 text-violet-600" />
          <div>
            <p className="text-sm text-gray-500">Tus datos</p>
            <p className="font-medium text-gray-900">{customerInfo?.name}</p>
            <p className="text-sm text-gray-600">{customerInfo?.email}</p>
            <p className="text-sm text-gray-600">{customerInfo?.phone}</p>
          </div>
        </div>

        {business.address && (
          <div className="flex items-start gap-3 pt-4">
            <MapPin className="mt-0.5 h-5 w-5 shrink-0 text-violet-600" />
            <div>
              <p className="text-sm text-gray-500">Dirección</p>
              <p className="font-medium text-gray-900">{business.address}</p>
              {business.city && (
                <p className="text-sm text-gray-600">{business.city}</p>
              )}
            </div>
          </div>
        )}
      </Card>

      {/* Payment instructions */}
      {(business.nequi_phone ||
        business.daviplata_phone ||
        business.bancolombia_account) && (
        <Card className="bg-violet-50 border-violet-200">
          <h3 className="font-medium text-violet-900">
            Instrucciones de pago
          </h3>
          <p className="mt-1 text-sm text-violet-700">
            Para confirmar tu cita, realiza el pago por uno de estos medios:
          </p>
          <ul className="mt-3 space-y-2 text-sm text-violet-800">
            {business.nequi_phone && (
              <li>
                <span className="font-medium">Nequi:</span>{' '}
                {business.nequi_phone}
              </li>
            )}
            {business.daviplata_phone && (
              <li>
                <span className="font-medium">Daviplata:</span>{' '}
                {business.daviplata_phone}
              </li>
            )}
            {business.bancolombia_account && (
              <li>
                <span className="font-medium">Bancolombia:</span>{' '}
                {business.bancolombia_account}
              </li>
            )}
          </ul>
        </Card>
      )}

      {bookMutation.isError && (
        <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
          Ocurrió un error al realizar la reserva. Intenta de nuevo.
        </div>
      )}

      <Button
        fullWidth
        size="lg"
        loading={bookMutation.isPending}
        onClick={handleConfirm}
      >
        Confirmar reserva
      </Button>
    </div>
  );
}
