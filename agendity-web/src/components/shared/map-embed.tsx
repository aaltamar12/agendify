'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils/cn';
import { Skeleton } from '@/components/ui/skeleton';

interface MapEmbedProps {
  /** Full address string (used if no lat/lng) */
  address?: string;
  /** Latitude coordinate */
  latitude?: number | null;
  /** Longitude coordinate */
  longitude?: number | null;
  /** Map zoom level (default 15) */
  zoom?: number;
  /** Iframe height in px (default 300) */
  height?: number;
  /** Additional CSS classes for the wrapper */
  className?: string;
}

/**
 * Google Maps embed using the free iframe version (no API key required).
 * If lat/lng are provided, centers on coordinates. Otherwise uses address string.
 */
export function MapEmbed({
  address,
  latitude,
  longitude,
  zoom = 15,
  height = 300,
  className,
}: MapEmbedProps) {
  const [isLoaded, setIsLoaded] = useState(false);

  // Build the query parameter
  let query: string;
  if (latitude && longitude) {
    query = `${latitude},${longitude}`;
  } else if (address) {
    query = encodeURIComponent(address);
  } else {
    return null;
  }

  const src = `https://www.google.com/maps?q=${query}&z=${zoom}&output=embed`;

  return (
    <div className={cn('relative overflow-hidden rounded-xl', className)}>
      {/* Loading skeleton */}
      {!isLoaded && (
        <Skeleton
          className="absolute inset-0 rounded-xl"
        />
      )}
      <iframe
        src={src}
        width="100%"
        height={height}
        style={{ border: 0, borderRadius: '12px' }}
        allowFullScreen
        loading="lazy"
        referrerPolicy="no-referrer-when-downgrade"
        title="Ubicación en Google Maps"
        onLoad={() => setIsLoaded(true)}
      />
    </div>
  );
}
