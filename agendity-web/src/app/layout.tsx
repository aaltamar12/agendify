import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import AppProviders from "@/providers/app-providers";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || "https://www.agendity.co";

export const viewport: Viewport = {
  themeColor: "#7C3AED",
  width: "device-width",
  initialScale: 1,
};

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Agendity — Agenda de citas para tu negocio",
    template: "%s | Agendity",
  },
  description:
    "Gestiona las citas de tu negocio. Reservas online 24/7, agenda digital, control de ingresos y reportes. Empieza gratis.",
  manifest: "/manifest.json",
  keywords: [
    "agenda de citas",
    "reservas online negocios",
    "software gestión de citas",
    "gestión de citas",
    "agenda digital para negocios",
    "sistema de reservas",
    "agenda de citas Colombia",
    "reservas online Colombia",
    "Agendity",
  ],
  authors: [{ name: "Agendity", url: SITE_URL }],
  creator: "Agendity",
  openGraph: {
    type: "website",
    locale: "es_CO",
    siteName: "Agendity",
    title: "Agendity — Agenda de citas para tu negocio",
    description:
      "Tus clientes reservan en segundos, tú te enfocas en lo que mejor haces. Reservas online 24/7, control de ingresos y reportes.",
    url: SITE_URL,
    images: [
      {
        url: "/og-image.jpg",
        width: 1200,
        height: 630,
        alt: "Agendity — Gestiona tu negocio, simplifica tus citas",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Agendity — Agenda de citas para tu negocio",
    description:
      "Tus clientes reservan en segundos, tú te enfocas en lo que mejor haces. Empieza gratis.",
    images: ["/og-image.jpg"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  alternates: {
    canonical: SITE_URL,
  },
  icons: {
    icon: "/favicon.ico",
    apple: "/icons/apple-touch-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className={inter.variable}>
      <body className="min-h-screen bg-gray-50 text-gray-900 antialiased" suppressHydrationWarning>
        <AppProviders>{children}</AppProviders>
        <Analytics />
      </body>
    </html>
  );
}
