'use client';

import { Star } from 'lucide-react';
import { cn } from '@/lib/utils/cn';

const sizeClasses = {
  sm: 'h-3.5 w-3.5',
  md: 'h-5 w-5',
} as const;

interface StarRatingProps {
  rating: number;
  size?: keyof typeof sizeClasses;
  showValue?: boolean;
  className?: string;
}

export function StarRating({
  rating,
  size = 'md',
  showValue = false,
  className,
}: StarRatingProps) {
  const stars = [];
  const clamped = Math.max(0, Math.min(5, rating));

  for (let i = 1; i <= 5; i++) {
    const filled = clamped >= i;
    const half = !filled && clamped >= i - 0.5;

    stars.push(
      <span key={i} className="relative inline-block">
        {/* Empty star (background) */}
        <Star
          className={cn(sizeClasses[size], 'text-gray-300')}
          fill="currentColor"
          strokeWidth={0}
        />
        {/* Filled or half-filled star (overlay) */}
        {(filled || half) && (
          <span
            className="absolute inset-0 overflow-hidden"
            style={{ width: filled ? '100%' : '50%' }}
          >
            <Star
              className={cn(sizeClasses[size], 'text-violet-500')}
              fill="currentColor"
              strokeWidth={0}
            />
          </span>
        )}
      </span>,
    );
  }

  return (
    <div className={cn('inline-flex items-center gap-0.5', className)}>
      {stars}
      {showValue && (
        <span className="ml-1 text-sm font-medium text-gray-700">
          {clamped.toFixed(1)}
        </span>
      )}
    </div>
  );
}
