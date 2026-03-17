import { useQuery } from '@tanstack/react-query';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { PaginatedResponse, Review } from '@/lib/api/types';

export function useReviews(page: number = 1) {
  return useQuery({
    queryKey: ['reviews', page],
    queryFn: () =>
      get<PaginatedResponse<Review>>(ENDPOINTS.REVIEWS.list, {
        params: { page },
      }),
  });
}
