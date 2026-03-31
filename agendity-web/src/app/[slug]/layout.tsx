import type { Metadata } from 'next';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

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

    return {
      title,
      description,
      alternates: {
        canonical: `https://agendity.co/${slug}`,
      },
      openGraph: {
        title,
        description,
        url: `https://agendity.co/${slug}`,
        ...(business.cover_url && {
          images: [{ url: business.cover_url, width: 1200, height: 630 }],
        }),
      },
      twitter: {
        card: 'summary_large_image',
        title,
        description,
        ...(business.cover_url && { images: [business.cover_url] }),
      },
    };
  } catch {
    return {};
  }
}

export default function SlugLayout({ children }: Props) {
  return children;
}
