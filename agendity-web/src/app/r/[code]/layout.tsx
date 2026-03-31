import type { Metadata } from 'next';

export const metadata: Metadata = {
  openGraph: {
    images: [{ url: 'https://www.agendity.co/og-referral.jpg', width: 1200, height: 630, alt: 'Agendity' }],
  },
  twitter: {
    images: ['https://www.agendity.co/og-referral.jpg'],
  },
};

export default function ReferralCodeLayout({ children }: { children: React.ReactNode }) {
  return children;
}
