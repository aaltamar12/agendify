'use client';

import { useState, useEffect } from 'react';
import { X, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui';

interface WelcomeModalProps {
  slug: string;
}

/**
 * Welcome modal shown when a user visits a business page via a shared link/QR.
 * Displays once per slug — dismissal is stored in localStorage.
 */
export function WelcomeModal({ slug }: WelcomeModalProps) {
  const [visible, setVisible] = useState(false);
  const storageKey = `agendity_welcomed_${slug}`;

  useEffect(() => {
    // Only show if not previously dismissed
    if (typeof window !== 'undefined' && !localStorage.getItem(storageKey)) {
      setVisible(true);
    }
  }, [storageKey]);

  const handleDismiss = () => {
    localStorage.setItem(storageKey, '1');
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4 animate-in fade-in duration-200">
      <div className="relative w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl animate-in zoom-in-95 slide-in-from-bottom-4 duration-300">
        {/* Close button */}
        <button
          onClick={handleDismiss}
          className="absolute right-3 top-3 rounded-full p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
          aria-label="Cerrar"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Icon */}
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-violet-100">
          <Sparkles className="h-7 w-7 text-violet-600" />
        </div>

        {/* Content */}
        <h2 className="mb-2 text-center text-lg font-bold text-gray-900">
          ¡Nos actualizamos!
        </h2>
        <p className="mb-6 text-center text-sm leading-relaxed text-gray-600">
          Agendar es mucho más fácil y rápido. Llena un pequeño formulario,
          selecciona tu horario y forma de pago, ¡y listo!
        </p>

        {/* CTA */}
        <Button fullWidth onClick={handleDismiss}>
          Entendido
        </Button>
      </div>
    </div>
  );
}
