import Link from 'next/link';
import { BadgeCheck, MapPin } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { StarRating } from '@/components/shared/star-rating';
import type { Business } from '@/lib/api/types';

const TYPE_LABELS: Record<string, string> = {
  barbershop: 'Barbería',
  salon: 'Salón',
  spa: 'Spa',
  nails: 'Uñas',
  other: 'Otro',
};

interface BusinessCardProps {
  business: Business;
}

export function BusinessCard({ business }: BusinessCardProps) {
  const typeLabel = TYPE_LABELS[business.business_type] ?? business.business_type;

  return (
    <Link
      href={`/${business.slug}`}
      className="group block overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow hover:shadow-md"
    >
      {/* Cover image or gradient placeholder */}
      <div className="relative h-40 w-full overflow-hidden">
        {business.cover_url ? (
          <img
            src={business.cover_url}
            alt={business.name}
            className="h-full w-full object-cover transition-transform group-hover:scale-105"
          />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-violet-500 to-violet-700" />
        )}

        {/* Logo overlay */}
        {business.logo_url && (
          <div className="absolute bottom-3 left-3">
            <img
              src={business.logo_url}
              alt=""
              className="h-10 w-10 rounded-full border-2 border-white object-cover shadow"
            />
          </div>
        )}
      </div>

      {/* Content */}
      <div className="flex flex-col gap-2 p-4">
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <h3 className="text-lg font-semibold text-gray-900 group-hover:text-violet-600 transition-colors truncate">
              {business.name}
            </h3>
            {business.verified && (
              <BadgeCheck className="h-5 w-5 shrink-0 text-blue-500" aria-label="Verificado" />
            )}
            {business.featured && (
              <span className="shrink-0 inline-flex items-center rounded-full bg-violet-100 px-2 py-0.5 text-xs font-medium text-violet-700">
                Destacado
              </span>
            )}
          </div>
          <Badge>{typeLabel}</Badge>
        </div>

        <div className="flex items-center gap-1.5">
          <StarRating rating={Number(business.rating_average) || 0} size="sm" showValue />
          {business.total_reviews > 0 && (
            <span className="text-xs text-gray-400">
              ({business.total_reviews} {business.total_reviews === 1 ? 'reseña' : 'reseñas'})
            </span>
          )}
        </div>

        {business.address && (
          <p className="flex items-center gap-1 text-sm text-gray-500">
            <MapPin className="h-3.5 w-3.5 shrink-0" />
            <span className="truncate">
              {business.address}
              {business.city ? `, ${business.city}` : ''}
            </span>
          </p>
        )}

        <span className="mt-1 text-sm font-medium text-violet-600 group-hover:underline">
          Ver negocio
        </span>
      </div>
    </Link>
  );
}
