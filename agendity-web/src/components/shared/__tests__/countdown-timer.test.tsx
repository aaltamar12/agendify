import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, cleanup, act } from '@testing-library/react';
import { CountdownTimer } from '../countdown-timer';

afterEach(cleanup);

describe('CountdownTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows "Tu cita es ahora" for a past date', () => {
    vi.setSystemTime(new Date('2026-03-26T12:00:00Z'));
    const pastDate = new Date('2026-03-26T11:00:00Z').toISOString();
    render(<CountdownTimer targetDate={pastDate} />);
    expect(screen.getByText(/Tu cita es ahora/)).toBeInTheDocument();
  });

  it('shows countdown for a future date', () => {
    vi.setSystemTime(new Date('2026-03-26T10:00:00Z'));
    const futureDate = new Date('2026-03-26T12:30:00Z').toISOString();
    render(<CountdownTimer targetDate={futureDate} />);

    expect(screen.getByText(/2h/)).toBeInTheDocument();
    expect(screen.getByText(/para tu cita/)).toBeInTheDocument();
  });

  it('transitions to expired state when time runs out', () => {
    vi.setSystemTime(new Date('2026-03-26T10:00:00Z'));
    const target = new Date('2026-03-26T10:00:02Z').toISOString();
    render(<CountdownTimer targetDate={target} />);

    // Initially shows countdown
    expect(screen.getByText(/para tu cita/)).toBeInTheDocument();

    // Advance past the target
    act(() => {
      vi.advanceTimersByTime(3000);
    });

    expect(screen.getByText(/Tu cita es ahora/)).toBeInTheDocument();
  });

  it('shows formatted minutes and seconds', () => {
    vi.setSystemTime(new Date('2026-03-26T10:00:00Z'));
    // 5 minutes 30 seconds from now
    const target = new Date('2026-03-26T10:05:30Z').toISOString();
    render(<CountdownTimer targetDate={target} />);

    expect(screen.getByText(/05m/)).toBeInTheDocument();
  });
});
