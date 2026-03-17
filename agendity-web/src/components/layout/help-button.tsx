'use client';

import { useState, useRef, useEffect } from 'react';
import { HelpCircle, Mail, Phone, MessageCircle, Lock } from 'lucide-react';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useCurrentBusiness } from '@/lib/hooks/use-business';
import {
  SUPPORT_CONFIG,
  SUPPORT_CHANNELS_BY_PLAN,
  PLAN_DISPLAY,
} from '@/lib/constants';

// Channel definitions with metadata
const CHANNEL_DEFINITIONS = {
  email: {
    key: 'email',
    label: 'Email',
    description: 'soporte@agendity.com',
    icon: Mail,
    colorClass: 'text-blue-600',
    bgClass: 'bg-blue-100',
    href: `mailto:${SUPPORT_CONFIG.email}`,
    minPlan: 'Básico',
  },
  whatsapp: {
    key: 'whatsapp',
    label: 'WhatsApp',
    description: 'Chat directo',
    icon: Phone,
    colorClass: 'text-green-600',
    bgClass: 'bg-green-100',
    href: SUPPORT_CONFIG.whatsappUrl,
    minPlan: 'Profesional',
  },
  chat: {
    key: 'chat',
    label: 'Chat en vivo',
    description: 'Soporte prioritario',
    icon: MessageCircle,
    colorClass: 'text-violet-600',
    bgClass: 'bg-violet-100',
    href: null, // Built dynamically with business name
    minPlan: 'Inteligente',
  },
} as const;

const ALL_CHANNELS = ['email', 'whatsapp', 'chat'] as const;

export function HelpButton() {
  const [open, setOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const { planSlug, planLabel } = useCurrentSubscription();
  const { data: business } = useCurrentBusiness();

  const availableChannels = SUPPORT_CHANNELS_BY_PLAN[planSlug] ?? ['email'];
  const display = PLAN_DISPLAY[planSlug];

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    if (open) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [open]);

  function getChatHref(): string {
    const businessName = business?.name ?? 'Mi Negocio';
    const message = encodeURIComponent(
      `Soporte prioritario - ${businessName}`
    );
    return `${SUPPORT_CONFIG.whatsappUrl}?text=${message}`;
  }

  function handleChannelClick(channelKey: string) {
    const def = CHANNEL_DEFINITIONS[channelKey as keyof typeof CHANNEL_DEFINITIONS];
    if (!def) return;

    const href = channelKey === 'chat' ? getChatHref() : def.href;
    if (href) {
      window.open(href, '_blank', 'noopener,noreferrer');
    }
    setOpen(false);
  }

  return (
    <div ref={dropdownRef} className="relative">
      {/* Help button */}
      <button
        onClick={() => setOpen((prev) => !prev)}
        className="relative rounded-lg p-2 text-gray-600 transition-colors hover:bg-gray-100"
        aria-label="Ayuda y soporte"
      >
        <HelpCircle className="h-5 w-5" />
      </button>

      {/* Dropdown panel */}
      {open && (
        <div className="absolute right-0 top-full z-50 mt-2 w-72 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-lg sm:w-80">
          {/* Header */}
          <div className="border-b border-gray-100 px-4 py-3">
            <h3 className="text-sm font-semibold text-gray-900">
              ¿Necesitas ayuda?
            </h3>
            <p className="mt-0.5 text-xs text-gray-500">
              Elige un canal de soporte
            </p>
          </div>

          {/* Channel list */}
          <div className="divide-y divide-gray-50 py-1">
            {ALL_CHANNELS.map((channelKey) => {
              const def =
                CHANNEL_DEFINITIONS[channelKey as keyof typeof CHANNEL_DEFINITIONS];
              if (!def) return null;

              const isAvailable = availableChannels.includes(channelKey);
              const Icon = def.icon;

              if (isAvailable) {
                return (
                  <button
                    key={channelKey}
                    onClick={() => handleChannelClick(channelKey)}
                    className="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-gray-50"
                  >
                    <div
                      className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full ${def.bgClass}`}
                    >
                      <Icon className={`h-4 w-4 ${def.colorClass}`} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-gray-900">
                        {def.label}
                      </p>
                      <p className="text-xs text-gray-500">
                        {def.description}
                      </p>
                    </div>
                  </button>
                );
              }

              // Locked channel
              return (
                <div
                  key={channelKey}
                  className="flex items-center gap-3 px-4 py-3 opacity-50"
                >
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gray-100">
                    <Lock className="h-4 w-4 text-gray-400" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-gray-500">
                      {def.label}
                    </p>
                    <p className="text-xs text-gray-400">
                      Disponible en Plan {def.minPlan}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Footer */}
          <div className="border-t border-gray-100 px-4 py-2.5">
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-500">
                Tu plan:{' '}
                <span
                  className={`inline-flex items-center rounded-full px-1.5 py-0.5 text-xs font-medium ${display.bgClass} ${display.textClass}`}
                >
                  {display.badge}
                </span>
              </span>
              <a
                href="/dashboard/settings#plan"
                onClick={() => setOpen(false)}
                className="text-xs font-medium text-violet-600 transition-colors hover:text-violet-700"
              >
                Ver planes
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
