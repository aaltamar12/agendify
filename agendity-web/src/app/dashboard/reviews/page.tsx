'use client';

import { useState } from 'react';
import { Star, MessageSquare, ChevronLeft, ChevronRight } from 'lucide-react';
import { Card, Button, Skeleton, EmptyState } from '@/components/ui';
import { useReviews } from '@/lib/hooks/use-reviews';
import { useCanAccessFeature } from '@/lib/hooks/use-subscription';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={`h-4 w-4 ${
            i < rating
              ? 'fill-yellow-400 text-yellow-400'
              : 'fill-gray-200 text-gray-200'
          }`}
        />
      ))}
    </div>
  );
}

function BigStarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-1">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={`h-6 w-6 ${
            i < Math.round(rating)
              ? 'fill-yellow-400 text-yellow-400'
              : 'fill-gray-200 text-gray-200'
          }`}
        />
      ))}
    </div>
  );
}

function ReviewSkeleton() {
  return (
    <Card>
      <div className="flex items-start gap-3">
        <Skeleton className="h-10 w-10 rounded-full" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-full" />
        </div>
      </div>
    </Card>
  );
}

export default function ReviewsPage() {
  const [page, setPage] = useState(1);
  const { data: response, isLoading } = useReviews(page);
  const canAccessReviews = useCanAccessFeature('/dashboard/reviews');

  const reviews = response?.data;
  const meta = response?.meta;

  // Calculate average rating from current page data
  const avgRating =
    reviews && reviews.length > 0
      ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
      : 0;

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('es-CO', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  };

  return (
    <div>
      {/* Header with average rating */}
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reseñas</h1>
          {meta && (
            <p className="mt-1 text-sm text-gray-500">
              {meta.total_count} reseña{meta.total_count !== 1 ? 's' : ''} en total
            </p>
          )}
        </div>

        {!isLoading && reviews && reviews.length > 0 && (
          <Card className="flex items-center gap-3 py-3 px-4">
            <span className="text-3xl font-bold text-gray-900">
              {avgRating.toFixed(1)}
            </span>
            <div>
              <BigStarRating rating={avgRating} />
              <p className="mt-0.5 text-xs text-gray-500">Promedio</p>
            </div>
          </Card>
        )}
      </div>

      {/* Upgrade banner for restricted plans */}
      {!canAccessReviews && (
        <UpgradeBanner
          feature="reseñas"
          targetPlan="Profesional"
          className="mb-6"
        />
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="space-y-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <ReviewSkeleton key={i} />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!reviews || reviews.length === 0) && (
        <EmptyState
          icon={MessageSquare}
          title="No hay reseñas"
          description="Las reseñas de tus clientes aparecerán aquí después de completar sus citas."
        />
      )}

      {/* Review list */}
      {!isLoading && reviews && reviews.length > 0 && (
        <div className="space-y-4">
          {reviews.map((review) => (
            <Card key={review.id}>
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-violet-100 text-sm font-semibold text-violet-600">
                    {(review.customer?.name ?? 'A').charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="font-medium text-gray-900">
                      {review.customer?.name ?? 'Anónimo'}
                    </p>
                    <StarRating rating={review.rating} />
                  </div>
                </div>
                <span className="whitespace-nowrap text-xs text-gray-400">
                  {formatDate(review.created_at)}
                </span>
              </div>
              {review.comment && (
                <p className="mt-3 text-sm leading-relaxed text-gray-600">
                  {review.comment}
                </p>
              )}
            </Card>
          ))}
        </div>
      )}

      {/* Pagination */}
      {meta && meta.total_pages > 1 && (
        <div className="mt-6 flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Página {meta.current_page} de {meta.total_pages}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
              Anterior
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= meta.total_pages}
              onClick={() => setPage((p) => p + 1)}
            >
              Siguiente
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
