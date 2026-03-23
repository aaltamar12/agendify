import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { get, post, put, del } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse } from '@/lib/api/types';

interface BusinessGoal {
  id: number;
  goal_type: string;
  name: string | null;
  target_value: number;
  period: string;
  fixed_costs: number | null;
  active: boolean;
}

interface GoalProgress {
  id: number;
  goal_type: string;
  name: string;
  target_value: number;
  current_value: number;
  progress: number;
  remaining: number;
  status: 'achieved' | 'on_track' | 'behind' | 'at_risk';
  suggestion: string;
}

export function useGoals() {
  return useQuery({
    queryKey: ['goals'],
    queryFn: () => get<ApiResponse<BusinessGoal[]>>(ENDPOINTS.GOALS.list),
    select: (res) => res.data,
  });
}

export function useGoalProgress() {
  return useQuery({
    queryKey: ['goals-progress'],
    queryFn: () => get<ApiResponse<GoalProgress[]>>(ENDPOINTS.GOALS.progress),
    select: (res) => res.data,
  });
}

export function useCreateGoal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<BusinessGoal>) =>
      post<ApiResponse<BusinessGoal>>(ENDPOINTS.GOALS.create, { goal: data }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['goals'] });
      qc.invalidateQueries({ queryKey: ['goals-progress'] });
    },
  });
}

export function useDeleteGoal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => del(ENDPOINTS.GOALS.delete(id)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['goals'] });
      qc.invalidateQueries({ queryKey: ['goals-progress'] });
    },
  });
}

export type { BusinessGoal, GoalProgress };
