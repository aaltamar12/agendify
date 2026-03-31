import type { Metadata } from 'next';

// Override ALL openGraph and twitter from root layout
export const metadata: Metadata = {
  title: 'Agendity — Plataforma de gestión para negocios de servicios',
  description:
    'Administra citas, empleados y pagos de tu negocio de servicios. Presencial o virtual. Tus clientes reservan online 24/7. Gratis.',
  openGraph: {
    title: 'Agendity — Plataforma de gestión para negocios de servicios',
    description: 'Administra citas, empleados y pagos. Tus clientes reservan online 24/7. 7 días gratis.',
    siteName: 'Agendity',
    locale: 'es_CO',
    type: 'website',
    url: 'https://www.agendity.co',
    images: [
      {
        url: 'https://www.agendity.co/og-referral.jpg',
        width: 1200,
        height: 630,
        alt: 'Agendity — Programa de Referidos',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Agendity — Plataforma de gestión para negocios de servicios',
    description: 'Administra citas, empleados y pagos. Tus clientes reservan online 24/7.',
    images: [
      {
        url: 'https://www.agendity.co/og-referral.jpg',
        width: 1200,
        height: 630,
        alt: 'Agendity — Programa de Referidos',
      },
    ],
  },
};

export default function ReferralCodeLayout({ children }: { children: React.ReactNode }) {
  return children;
}
