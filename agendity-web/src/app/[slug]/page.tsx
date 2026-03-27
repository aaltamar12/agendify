'use client';

import { useState } from 'react';
import { useParams, useSearchParams } from 'next/navigation';
import {
  MapPin,
  Phone,
  Clock,
  Star,
  Instagram,
  Facebook,
  Globe,
  ChevronRight,
  Navigation,
  ShieldOff,
} from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button, Card, Badge, Avatar, Spinner } from '@/components/ui';
import { StarRating } from '@/components/shared/star-rating';
import { MapEmbed } from '@/components/shared/map-embed';
import { BookingFlow } from '@/components/booking/booking-flow';
import { usePublicBusiness } from '@/lib/hooks/use-public';
import { WelcomeModal } from '@/components/shared/welcome-modal';
import { formatCurrency, formatPhone, truncate } from '@/lib/utils/format';
import { DAYS_OF_WEEK, BUSINESS_TYPES, DEFAULT_TRIAL_DAYS } from '@/lib/constants';
import type { DayOfWeek } from '@/lib/api/types';

export default function BusinessPage() {
  const params = useParams<{ slug: string }>();
  const searchParams = useSearchParams();
  const slug = params.slug;
  const isSharedRef = searchParams.get('ref') === 'shared';

  const { data, isLoading, error } = usePublicBusiness(slug);
  const [showBooking, setShowBooking] = useState(false);

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner size="lg" />
      </div>
    );
  }

  if (error || !data) {
    // Check if it's a 403 (business suspended/inactive)
    const axiosError = error as { response?: { status?: number } } | null;
    const isForbidden = axiosError?.response?.status === 403;

    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-4">
        <div className="mx-auto mb-2 flex h-14 w-14 items-center justify-center rounded-full bg-gray-100">
          <ShieldOff className="h-7 w-7 text-gray-400" />
        </div>
        <h1 className="text-xl font-bold text-gray-900">
          {isForbidden
            ? 'Este negocio no está disponible'
            : 'Negocio no encontrado'}
        </h1>
        <p className="text-gray-500 text-center max-w-sm">
          {isForbidden
            ? 'Este negocio no está disponible en este momento. Intenta más tarde.'
            : 'El enlace puede ser incorrecto o el negocio ya no está disponible.'}
        </p>
        <a
          href="/explore"
          className="mt-2 inline-flex items-center gap-2 rounded-lg bg-violet-600 px-5 py-2 text-sm font-medium text-white hover:bg-violet-700 transition-colors"
        >
          Explorar negocios
        </a>
      </div>
    );
  }

  const {
    business,
    services,
    employees,
    reviews,
    business_hours,
    average_rating,
    total_reviews,
  } = data;

  const isIndependent = !!business.independent;

  // Sort business hours by day
  const sortedHours = [...business_hours].sort(
    (a, b) => a.day_of_week - b.day_of_week,
  );

  const dayLabels = Object.fromEntries(
    DAYS_OF_WEEK.map((d) => [d.value, d.label]),
  ) as Record<DayOfWeek, string>;

  if (showBooking) {
    return (
      <div className="mx-auto max-w-lg px-4 py-6">
        {/* Header */}
        <div className="mb-6 flex items-center gap-3">
          {business.logo_url && (
            <img
              src={business.logo_url}
              alt={business.name}
              className="h-10 w-10 rounded-full object-cover"
            />
          )}
          <div>
            <h1 className="font-bold text-gray-900">{business.name}</h1>
            <p className="text-xs text-gray-500">
              {isIndependent ? `Agenda tu cita con ${business.name}` : 'Reserva tu cita'}
            </p>
          </div>
        </div>

        <BookingFlow
          slug={slug}
          business={business}
          services={services}
          employees={employees}
          onClose={() => setShowBooking(false)}
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Welcome modal for shared link / QR visitors */}
      {isSharedRef && <WelcomeModal slug={slug} />}

      {/* Cover / Header */}
      <div className="relative">
        {business.cover_url ? (
          <div className="h-48 w-full sm:h-56">
            <img
              src={business.cover_url}
              alt=""
              className="h-full w-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
          </div>
        ) : (
          <div className="h-48 w-full bg-gradient-to-br from-violet-600 to-violet-900 sm:h-56" />
        )}

        {/* Business info overlay */}
        <div className="absolute bottom-0 left-0 right-0 px-4 pb-4 text-white">
          <div className="mx-auto flex max-w-2xl items-end gap-4">
            {business.logo_url ? (
              <img
                src={business.logo_url}
                alt={business.name}
                className="h-16 w-16 shrink-0 rounded-xl border-2 border-white object-cover shadow-lg sm:h-20 sm:w-20"
              />
            ) : (
              <Avatar
                name={business.name}
                size="lg"
                className="h-16 w-16 border-2 border-white shadow-lg sm:h-20 sm:w-20"
              />
            )}
            <div className="flex-1 min-w-0">
              <h1 className="text-xl font-bold drop-shadow-sm sm:text-2xl">
                {business.name}
              </h1>
              <div className="mt-1 flex items-center gap-2 text-sm text-white/90">
                {!isIndependent && (
                  <Badge
                    className="bg-white/20 text-white border-0"
                  >
                    {BUSINESS_TYPES[business.business_type]}
                  </Badge>
                )}
                {isIndependent && (
                  <Badge className="bg-violet-500/30 text-white border-0">
                    Profesional independiente
                  </Badge>
                )}
                {total_reviews > 0 && (
                  <span className="flex items-center gap-1">
                    <Star className="h-3.5 w-3.5 fill-yellow-400 text-yellow-400" />
                    {average_rating.toFixed(1)} ({total_reviews})
                  </span>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="mx-auto max-w-2xl space-y-6 px-4 py-6">
        {/* CTA */}
        <Button
          fullWidth
          size="lg"
          onClick={() => setShowBooking(true)}
        >
          {isIndependent ? `Agenda tu cita con ${business.name}` : 'Reservar cita'}
        </Button>

        {/* About */}
        {business.description && (
          <Card>
            <h2 className="font-semibold text-gray-900">{isIndependent ? 'Sobre mí' : 'Sobre nosotros'}</h2>
            <p className="mt-2 text-sm text-gray-600 leading-relaxed">
              {business.description}
            </p>
          </Card>
        )}

        {/* Location map — right after "Sobre nosotros" (hidden for independent professionals) */}
        {!isIndependent && (business.address || business.latitude) && (
          <div className="space-y-3">
            <h2 className="font-semibold text-gray-900">
              <MapPin className="mr-2 inline-block h-4 w-4 text-violet-600" />
              Ubicación
            </h2>
            <MapEmbed
              address={
                [business.address, business.city, business.country]
                  .filter(Boolean)
                  .join(', ')
              }
              latitude={business.latitude}
              longitude={business.longitude}
              height={250}
            />
            <div className="flex items-center justify-between">
              {business.address && (
                <p className="text-sm text-gray-500">
                  {business.address}{business.city && `, ${business.city}`}
                </p>
              )}
              <a
                href={
                  business.latitude && business.longitude
                    ? `https://www.google.com/maps/dir/?api=1&destination=${business.latitude},${business.longitude}`
                    : `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
                        [business.address, business.city, business.country].filter(Boolean).join(', ')
                      )}`
                }
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-lg bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-700 transition-colors shrink-0"
              >
                <Navigation className="h-4 w-4" />
                Cómo llegar
              </a>
            </div>
          </div>
        )}

        {/* Contact info + social links */}
        <Card className="space-y-3">
          {business.phone && (
            <div className="flex items-center gap-3 text-sm">
              <Phone className="h-4 w-4 shrink-0 text-violet-600" />
              <a
                href={`tel:${business.phone}`}
                className="text-gray-700 hover:text-violet-600"
              >
                {formatPhone(business.phone)}
              </a>
            </div>
          )}
          {business.instagram_url && (
            <div className="flex items-center gap-3 text-sm">
              <Instagram className="h-4 w-4 shrink-0 text-violet-600" />
              <a
                href={business.instagram_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-700 hover:text-violet-600"
              >
                Instagram
              </a>
            </div>
          )}
          {business.facebook_url && (
            <div className="flex items-center gap-3 text-sm">
              <Facebook className="h-4 w-4 shrink-0 text-violet-600" />
              <a
                href={business.facebook_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-700 hover:text-violet-600"
              >
                Facebook
              </a>
            </div>
          )}
          {business.website_url && (
            <div className="flex items-center gap-3 text-sm">
              <Globe className="h-4 w-4 shrink-0 text-violet-600" />
              <a
                href={business.website_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-700 hover:text-violet-600"
              >
                Sitio web
              </a>
            </div>
          )}
        </Card>

        {/* Services */}
        <div className="space-y-3">
          <h2 className="font-semibold text-gray-900">Servicios</h2>
          <div className="space-y-2">
            {services
              .filter((s) => s.active)
              .map((service) => (
                <Card
                  key={service.id}
                  className="flex cursor-pointer items-center justify-between p-4 hover:shadow-md transition-shadow"
                  onClick={() => setShowBooking(true)}
                >
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-gray-900">
                      {service.name}
                    </h3>
                    {service.description && (
                      <p className="mt-0.5 text-sm text-gray-500">
                        {truncate(service.description, 60)}
                      </p>
                    )}
                    <div className="mt-1 flex items-center gap-3 text-sm">
                      <span className="font-semibold text-violet-600">
                        {formatCurrency(service.price)}
                      </span>
                      <span className="text-gray-400">
                        {service.duration_minutes} min
                      </span>
                    </div>
                  </div>
                  <ChevronRight className="h-5 w-5 shrink-0 text-gray-400" />
                </Card>
              ))}
          </div>
        </div>

        {/* Business hours */}
        {sortedHours.length > 0 && (
          <Card>
            <h2 className="mb-3 font-semibold text-gray-900">
              <Clock className="mr-2 inline-block h-4 w-4 text-violet-600" />
              Horarios
            </h2>
            <div className="space-y-2">
              {sortedHours.map((bh) => (
                <div
                  key={bh.id}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="font-medium text-gray-700">
                    {dayLabels[bh.day_of_week] ?? `Día ${bh.day_of_week}`}
                  </span>
                  {bh.closed ? (
                    <span className="text-gray-400">Cerrado</span>
                  ) : (
                    <span className="text-gray-600">
                      {bh.open_time.slice(0, 5)} - {bh.close_time.slice(0, 5)}
                    </span>
                  )}
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* Reviews */}
        {reviews.length > 0 && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold text-gray-900">Reseñas</h2>
              {total_reviews > 0 && (
                <div className="flex items-center gap-2">
                  <StarRating rating={average_rating} size="sm" />
                  <span className="text-sm text-gray-500">
                    ({total_reviews})
                  </span>
                </div>
              )}
            </div>

            <div className="space-y-3">
              {reviews.slice(0, 5).map((review) => (
                <Card key={review.id} className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-2">
                      <Avatar
                        name={review.customer?.name || 'Usuario'}
                        size="sm"
                      />
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {review.customer?.name || 'Usuario'}
                        </p>
                        <StarRating rating={review.rating} size="sm" />
                      </div>
                    </div>
                  </div>
                  {review.comment && (
                    <p className="mt-2 text-sm text-gray-600 leading-relaxed">
                      {review.comment}
                    </p>
                  )}
                </Card>
              ))}
            </div>
          </div>
        )}

        {/* Business owner CTA */}
        <div className="rounded-xl border border-violet-200 bg-violet-50 p-6 text-center">
          <p className="mb-2 text-lg font-bold text-gray-900">
            ¿Eres negocio o independiente? ¡Organízate así!
          </p>
          <p className="mb-4 text-sm text-gray-600">
            Optimiza tu agenda, controla tus finanzas y recibe reservas online 24/7.
          </p>
          <a
            href="/register"
            className="inline-flex items-center gap-2 rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-violet-700 transition-colors"
          >
            Registra tu negocio gratis
          </a>
          <p className="mt-2 text-xs text-gray-500">
            {DEFAULT_TRIAL_DAYS} días gratis — Sin tarjeta de crédito
          </p>
        </div>

        {/* Footer */}
        <div className="border-t border-gray-200 pt-6 text-center">
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
