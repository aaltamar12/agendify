// Generates a pleasant notification chime using Web Audio API
// No external audio file needed — pure synthesis

export function playNotificationSound() {
  try {
    const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();

    // Pleasant two-tone chime (like a doorbell)
    const notes = [
      { freq: 587.33, start: 0, duration: 0.15 }, // D5
      { freq: 880, start: 0.15, duration: 0.3 }, // A5
    ];

    notes.forEach(({ freq, start, duration }) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.value = freq;

      gain.gain.setValueAtTime(0.3, ctx.currentTime + start);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + start + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(ctx.currentTime + start);
      osc.stop(ctx.currentTime + start + duration);
    });

    // Close context after sound plays
    setTimeout(() => ctx.close(), 1000);
  } catch {
    // Audio not available — silent fail
  }
}
