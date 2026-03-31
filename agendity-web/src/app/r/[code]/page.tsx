import type { Metadata } from 'next';

type Props = {
  params: Promise<{ code: string }>;
};

export async function generateMetadata(): Promise<Metadata> {
  return {
    title: 'Agendity — Plataforma de gestión para negocios de servicios',
    description:
      'Administra citas, empleados y pagos de tu negocio de servicios. Presencial o virtual. Tus clientes reservan online 24/7. Gratis.',
    openGraph: {
      title: 'Agendity — Plataforma de gestión para negocios de servicios',
      description:
        'Administra citas, empleados y pagos. Tus clientes reservan online 24/7. 7 días gratis.',
      siteName: 'Agendity',
      type: 'website',
      images: [{ url: 'https://www.agendity.co/og-referral.jpg', width: 1200, height: 630, alt: 'Agendity' }],
    },
    twitter: {
      card: 'summary_large_image',
      title: 'Agendity — Plataforma de gestión para negocios de servicios',
      description: 'Administra citas, empleados y pagos. Tus clientes reservan online 24/7.',
      images: ['https://www.agendity.co/og-referral.jpg'],
    },
  };
}

export default async function ReferralRedirectPage({ params }: Props) {
  const { code } = await params;

  return (
    <>
      {/* Save ref code and redirect via client JS */}
      <script
        dangerouslySetInnerHTML={{
          __html: `
            localStorage.setItem('agendity_ref_code', '${code.replace(/'/g, "\\'")}');
            window.location.replace('/?ref=${code.replace(/'/g, "\\'")}');
          `,
        }}
      />
      <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center' }}>
        <p style={{ color: '#6b7280', fontSize: 14 }}>Redirigiendo...</p>
      </div>
    </>
  );
}
