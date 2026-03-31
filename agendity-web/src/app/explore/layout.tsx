import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Explorar negocios — Reserva tu cita online',
  description:
    'Encuentra barberías, salones de belleza y profesionales cerca de ti en Barranquilla. Reserva tu cita en segundos sin llamar.',
  keywords: [
    'barbería Barranquilla',
    'salón de belleza Barranquilla',
    'reservar cita barbería',
    'agendar cita salón',
    'negocios cerca de mí',
  ],
  alternates: {
    canonical: 'https://www.agendity.co/explore',
  },
  openGraph: {
    title: 'Explorar negocios — Agendity',
    description: 'Encuentra profesionales cerca de ti y reserva tu cita en segundos.',
    url: 'https://www.agendity.co/explore',
  },
};

export default function ExploreLayout({ children }: { children: React.ReactNode }) {
  return children;
}
