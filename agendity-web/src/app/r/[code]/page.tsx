import type { Metadata } from 'next';
import { ClientRedirect } from './client-redirect';

type Props = {
  params: Promise<{ code: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { code } = await params;

  return {
    title: 'Agendity — Reservas online para tu negocio',
    description:
      'Administra citas, empleados y pagos de tu negocio de servicios. Presencial o virtual. Tus clientes reservan online 24/7. Gratis.',
    openGraph: {
      title: 'Agendity — Plataforma de gestión para negocios de servicios',
      description:
        'Administra citas, empleados y pagos. Tus clientes reservan online 24/7. 7 días gratis.',
      url: `https://www.agendity.co/r/${code}`,
      images: [{ url: 'https://www.agendity.co/og-referral.png', width: 1200, height: 630, alt: 'Agendity' }],
    },
    twitter: {
      card: 'summary_large_image',
      title: 'Agendity — Plataforma de gestión para negocios de servicios',
      description: 'Administra citas, empleados y pagos. Tus clientes reservan online 24/7.',
      images: ['https://www.agendity.co/og-referral.png'],
    },
  };
}

export default async function ReferralRedirectPage({ params }: Props) {
  const { code } = await params;
  return <ClientRedirect code={code} />;
}
