import type { Metadata } from 'next';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://agendity.co';

type Props = {
  params: Promise<{ slug: string }>;
  children: React.ReactNode;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;

  try {
    const res = await fetch(`${API_URL}/api/v1/public/${slug}`, {
      next: { revalidate: 3600 },
    });

    if (!res.ok) return {};

    const { data: business } = await res.json();

    const title = `${business.name} — Reserva tu cita online`;
    const description = business.description
      ? `${business.description.slice(0, 120)}. Reserva online en ${business.name}.`
      : `Reserva tu cita en ${business.name}. Servicios, precios y disponibilidad online.`;

    const ogImageUrl = `${SITE_URL}/${slug}/og`;

    return {
      title,
      description,
      alternates: {
        canonical: `${SITE_URL}/${slug}`,
      },
      openGraph: {
        title,
        description,
        url: `${SITE_URL}/${slug}`,
        images: [{ url: ogImageUrl, width: 1200, height: 630, alt: business.name }],
      },
      twitter: {
        card: 'summary_large_image',
        title,
        description,
        images: [ogImageUrl],
      },
    };
  } catch {
    return {};
  }
}

export default function SlugLayout({ children }: Props) {
  return children;
}
