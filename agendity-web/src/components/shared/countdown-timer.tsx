'use client';

import { useState, useEffect } from 'react';
import { Clock } from 'lucide-react';
import { cn } from '@/lib/utils/cn';

interface CountdownTimerProps {
  /** Target date/time as ISO string or Date */
  targetDate: string | Date;
  /** Use dark theme (for VIP ticket on dark background) */
  dark?: boolean;
}

export function CountdownTimer({ targetDate, dark = false }: CountdownTimerProps) {
  const [timeLeft, setTimeLeft] = useState<{ hours: number; minutes: number; seconds: number } | null>(null);
  const [isExpired, setIsExpired] = useState(false);

  useEffect(() => {
    function calculate() {
      const target = new Date(targetDate);
      const now = new Date();
      const diff = target.getTime() - now.getTime();

      if (diff <= 0) {
        setIsExpired(true);
        setTimeLeft(null);
        return;
      }

      setTimeLeft({
        hours: Math.floor(diff / (1000 * 60 * 60)),
        minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60)),
        seconds: Math.floor((diff % (1000 * 60)) / 1000),
      });
    }

    calculate();
    const interval = setInterval(calculate, 1000);
    return () => clearInterval(interval);
  }, [targetDate]);

  if (isExpired) {
    return (
      <div className={cn(
        'flex items-center gap-2 rounded-lg px-4 py-3 text-sm font-medium',
        dark
          ? 'bg-violet-500/10 text-violet-300'
          : 'bg-violet-100 text-violet-800'
      )}>
        <Clock className="h-4 w-4" />
        ¡Tu cita es ahora!
      </div>
    );
  }

  if (!timeLeft) return null;

  const { hours, minutes, seconds } = timeLeft;

  return (
    <div className={cn(
      'flex items-center gap-3 rounded-lg border px-4 py-3',
      dark
        ? 'bg-gray-800/50 border-gray-700'
        : 'bg-gray-50 border-gray-200'
    )}>
      <Clock className={cn('h-4 w-4 shrink-0', dark ? 'text-violet-400' : 'text-violet-600')} />
      <div className="flex-1">
        <p className={cn('text-sm font-medium', dark ? 'text-white' : 'text-gray-900')}>
          {hours > 0 && `${hours}h `}{String(minutes).padStart(2, '0')}m {String(seconds).padStart(2, '0')}s
        </p>
        <p className={cn('text-xs', dark ? 'text-gray-400' : 'text-gray-500')}>para tu cita</p>
      </div>
    </div>
  );
}
