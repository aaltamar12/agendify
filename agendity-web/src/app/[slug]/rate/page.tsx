'use client';

import { useState } from 'react';
import { useParams, useSearchParams } from 'next/navigation';
import { Star } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button, Card, Spinner } from '@/components/ui';
import { useRatingPage, useCreateReview } from '@/lib/hooks/use-public';
import dayjs from 'dayjs';
import 'dayjs/locale/es';

dayjs.locale('es');

function ClickableStars({
  rating,
  onChange,
}: {
  rating: number;
  onChange: (value: number) => void;
}) {
  const [hovered, setHovered] = useState(0);

  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((value) => {
        const filled = value <= (hovered || rating);
        return (
          <button
            key={value}
            type="button"
            className="p-1 transition-transform hover:scale-110"
            onMouseEnter={() => setHovered(value)}
            onMouseLeave={() => setHovered(0)}
            onClick={() => onChange(value)}
          >
            <Star
              className={cn(
                'h-8 w-8 sm:h-10 sm:w-10 transition-colors',
                filled
                  ? 'fill-violet-500 text-violet-500'
                  : 'fill-gray-200 text-gray-200',
              )}
              strokeWidth={0}
            />
          </button>
        );
      })}
    </div>
  );
}

export default function RatePage() {
  const params = useParams<{ slug: string }>();
  const searchParams = useSearchParams();
  const slug = params.slug;
  const appointmentId = searchParams.get('appointment');

  const { data, isLoading, error } = useRatingPage(slug, appointmentId);
  const createReview = useCreateReview();

  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [submitted, setSubmitted] = useState(false);

  if (!appointmentId) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-4">
        <h1 className="text-xl font-bold text-gray-900">Enlace no válido</h1>
        <p className="text-gray-500 text-center max-w-sm">
          Este enlace de calificación no es válido. Revisa el enlace que recibiste por correo.
        </p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner size="lg" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-4">
        <h1 className="text-xl font-bold text-gray-900">Cita no encontrada</h1>
        <p className="text-gray-500 text-center max-w-sm">
          No pudimos encontrar esta cita. Es posible que el enlace haya expirado.
        </p>
      </div>
    );
  }

  if (data.already_reviewed || submitted) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-4">
        <div className="mx-auto mb-2 flex h-16 w-16 items-center justify-center rounded-full bg-violet-100">
          <Star className="h-8 w-8 fill-violet-500 text-violet-500" />
        </div>
        <h1 className="text-xl font-bold text-gray-900">
          {submitted ? '¡Gracias por tu calificación!' : 'Ya calificaste esta cita'}
        </h1>
        <p className="text-gray-500 text-center max-w-sm">
          {submitted
            ? 'Tu opinión nos ayuda a mejorar. ¡Gracias!'
            : 'Ya dejaste una calificación para esta cita.'}
        </p>
        <a
          href={`/${slug}`}
          className="mt-2 inline-flex items-center gap-2 rounded-lg bg-violet-600 px-5 py-2 text-sm font-medium text-white hover:bg-violet-700 transition-colors"
        >
          Ver negocio
        </a>
      </div>
    );
  }

  const { appointment, business_name, business_logo_url } = data;

  const handleSubmit = () => {
    if (rating === 0) return;

    createReview.mutate(
      {
        slug,
        appointment_id: appointment.id,
        rating,
        comment: comment.trim() || undefined,
        customer_name: appointment.customer_name || undefined,
      },
      {
        onSuccess: () => setSubmitted(true),
      },
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="mx-auto max-w-lg px-4 py-8">
        {/* Header */}
        <div className="mb-8 text-center">
          {business_logo_url && (
            <img
              src={business_logo_url}
              alt={business_name}
              className="mx-auto mb-3 h-16 w-16 rounded-full object-cover shadow-md"
            />
          )}
          <h1 className="text-2xl font-bold text-gray-900">{business_name}</h1>
          <p className="mt-1 text-gray-500">Califica tu experiencia</p>
        </div>

        {/* Appointment details */}
        <Card className="mb-6 p-5">
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">Servicio</span>
              <span className="font-medium text-gray-900">{appointment.service_name}</span>
            </div>
            {appointment.employee_name && (
              <div className="flex justify-between">
                <span className="text-gray-500">Profesional</span>
                <span className="font-medium text-gray-900">{appointment.employee_name}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-gray-500">Fecha</span>
              <span className="font-medium text-gray-900">
                {dayjs(appointment.appointment_date).format('D [de] MMMM, YYYY')}
              </span>
            </div>
          </div>
        </Card>

        {/* Rating */}
        <div className="mb-6 text-center">
          <p className="mb-3 text-sm font-medium text-gray-700">
            {appointment.employee_name
              ? `¿Cómo fue tu experiencia con ${appointment.employee_name}?`
              : '¿Cómo fue tu experiencia?'}
          </p>
          <div className="flex justify-center">
            <ClickableStars rating={rating} onChange={setRating} />
          </div>
          {rating > 0 && (
            <p className="mt-2 text-sm text-violet-600 font-medium">
              {rating === 1 && 'Muy mala'}
              {rating === 2 && 'Mala'}
              {rating === 3 && 'Regular'}
              {rating === 4 && 'Buena'}
              {rating === 5 && 'Excelente'}
            </p>
          )}
        </div>

        {/* Comment */}
        <div className="mb-6">
          <label
            htmlFor="comment"
            className="mb-2 block text-sm font-medium text-gray-700"
          >
            Comentario (opcional)
          </label>
          <textarea
            id="comment"
            rows={3}
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Cuéntanos más sobre tu experiencia..."
            className="w-full rounded-lg border border-gray-300 px-4 py-3 text-sm text-gray-900 placeholder-gray-400 focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
          />
        </div>

        {/* Submit */}
        <Button
          fullWidth
          size="lg"
          onClick={handleSubmit}
          disabled={rating === 0 || createReview.isPending}
        >
          {createReview.isPending ? 'Enviando...' : 'Enviar calificación'}
        </Button>

        {createReview.isError && (
          <p className="mt-3 text-center text-sm text-red-600">
            Hubo un error al enviar tu calificación. Intenta de nuevo.
          </p>
        )}

        {/* Footer */}
        <div className="mt-8 text-center">
          <p className="text-xs text-gray-400">
            Reservas gestionadas por{' '}
            <a href="/" className="font-semibold text-violet-600 hover:text-violet-700">
              Agendity
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}
