'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';
import { get, post } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface AdBannerData {
  id: number;
  name: string;
  placement: string;
  image_url: string | null;
  link_url: string | null;
  alt_text: string | null;
}

interface AdBannerProps {
  placement: string;
}

export function AdBanner({ placement }: AdBannerProps) {
  const impressionTracked = useRef(false);

  const { data: banner } = useQuery({
    queryKey: ['ad_banner', placement],
    queryFn: async () => {
      const res = await get<ApiResponse<AdBannerData | null>>(
        ENDPOINTS.PUBLIC.adBanners,
        { params: { placement } },
      );
      return res.data;
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Track impression on mount (once per banner)
  useEffect(() => {
    if (banner?.id && !impressionTracked.current) {
      impressionTracked.current = true;
      post(ENDPOINTS.PUBLIC.adBannerImpression(banner.id)).catch(() => {
        // Silently fail — tracking is best-effort
      });
    }
  }, [banner?.id]);

  const handleClick = useCallback(() => {
    if (!banner) return;

    // Track click
    post(ENDPOINTS.PUBLIC.adBannerClick(banner.id)).catch(() => {
      // Silently fail
    });

    // Open link
    if (banner.link_url) {
      window.open(banner.link_url, '_blank', 'noopener,noreferrer');
    }
  }, [banner]);

  if (!banner) return null;

  return (
    <div className="rounded-xl border border-gray-200 bg-gray-50 p-3 transition-colors hover:bg-violet-50/50">
      <p className="mb-1.5 text-[10px] uppercase tracking-wider text-gray-400">
        Publicidad
      </p>
      <button
        type="button"
        onClick={handleClick}
        className="block w-full cursor-pointer text-left"
      >
        {banner.image_url ? (
          <img
            src={banner.image_url}
            alt={banner.alt_text || banner.name}
            className="w-full rounded-lg object-cover"
            loading="lazy"
          />
        ) : (
          <p className="text-sm text-gray-600">{banner.name}</p>
        )}
      </button>
    </div>
  );
}
