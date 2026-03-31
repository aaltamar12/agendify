import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Programa de Referidos — Gana dinero con Agendity',
  description:
    'Refiere negocios a Agendity y gana el 10% de cada suscripción. Sin límite de referidos, comisiones recurrentes.',
  alternates: {
    canonical: 'https://www.agendity.co/referral',
  },
  openGraph: {
    title: 'Gana dinero refiriendo negocios — Agendity',
    description: 'Refiere negocios y gana el 10% de cada suscripción. Comisiones recurrentes.',
    url: 'https://www.agendity.co/referral',
    images: [{ url: '/og-referral.jpg', width: 1200, height: 630, alt: 'Agendity — Programa de Referidos' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Gana dinero refiriendo negocios — Agendity',
    description: 'Refiere negocios y gana el 10% de cada suscripción. Comisiones recurrentes.',
    images: ['/og-referral.jpg'],
  },
};

export default function ReferralLayout({ children }: { children: React.ReactNode }) {
  return children;
}
