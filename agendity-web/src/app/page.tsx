import type { Metadata } from 'next';
import Link from 'next/link';
import {
  Calendar,
  Clock,
  BarChart3,
  Ticket,
  Store,
  DollarSign,
  Users,
  Smartphone,
  ArrowRight,
  CheckCircle,
  Bell,
  MessageCircle,
  Shield,
  Star,
  Zap,
  Gift,
} from 'lucide-react';
import { Suspense } from 'react';
import { Button } from '@/components/ui/button';
import { LandingPricing } from '@/components/landing/landing-pricing';
import { RegisterLink } from '@/components/landing/register-link';
import { RefCapture } from '@/components/landing/ref-capture';

export async function generateMetadata({
  searchParams,
}: {
  searchParams: Promise<{ ref?: string }>;
}): Promise<Metadata> {
  const { ref } = await searchParams;
  const ogImage = ref ? 'https://agendity.co/og-referral.jpg' : 'https://agendity.co/og';

  return {
    title: 'Agendity — Reservas online para tu negocio',
    description:
      'Administra citas, empleados y pagos de tu negocio de servicios. Presencial o virtual. Tus clientes reservan online 24/7. Gratis.',
    keywords: [
      'agenda de citas online',
      'reservas online barbería',
      'sistema de reservas para barbería',
      'administrar barbería online',
      'software citas salón de belleza',
      'gestión de citas Colombia',
      'reservar cita barbería Barranquilla',
      'plataforma reservas online gratis',
      'agenda consultorios médicos',
      'sistema citas psicólogo online',
      'reservas entrenador personal',
      'agenda para coaches y consultores',
    ],
    alternates: {
      canonical: 'https://agendity.co',
    },
    openGraph: {
      title: 'Agendity — Reservas online para tu negocio',
      description:
        'Administra citas, empleados y pagos. Tus clientes reservan online 24/7. 7 días gratis.',
      url: 'https://agendity.co',
      images: [{ url: ogImage, width: 1200, height: 630, alt: 'Agendity' }],
    },
    twitter: {
      card: 'summary_large_image',
      title: 'Agendity — Reservas online para tu negocio',
      description: 'Administra citas, empleados y pagos. Tus clientes reservan online 24/7.',
      images: [ogImage],
    },
  };
}

const FEATURES = [
  {
    icon: Calendar,
    title: 'Agenda inteligente',
    description:
      'Gestiona todas tus citas desde un calendario visual. Sin confusiones, sin libreta.',
  },
  {
    icon: Clock,
    title: 'Reservas online 24/7',
    description:
      'Tus clientes reservan cuando quieran, desde su celular. Tú recibes la cita confirmada.',
  },
  {
    icon: BarChart3,
    title: 'Reportes y métricas',
    description:
      'Conoce tus ingresos, servicios más pedidos y rendimiento de tu equipo en tiempo real.',
  },
  {
    icon: Ticket,
    title: 'Ticket digital VIP',
    description:
      'Cada cita genera un ticket digital con QR. Profesional, rápido y sin papel.',
  },
  {
    icon: MessageCircle,
    title: 'WhatsApp automático',
    description:
      'Confirmaciones y recordatorios por WhatsApp para tus clientes. Menos citas olvidadas, más agenda llena. Disponible en Plan Profesional.',
  },
  {
    icon: Bell,
    title: 'Notificaciones en tiempo real',
    description:
      'Recibe alertas instantáneas de nuevas reservas, pagos y cancelaciones directo en tu dashboard.',
  },
  {
    icon: Shield,
    title: 'Pagos y depósitos',
    description:
      'Cobra anticipos para confirmar citas. Protege tu tiempo de cancelaciones de último minuto.',
  },
];

const STEPS = [
  { number: '1', title: 'Regístrate gratis', description: 'Crea tu cuenta en menos de 2 minutos. Sin tarjeta de crédito.' },
  { number: '2', title: 'Configura tu negocio', description: 'Agrega tus servicios, empleados y horarios de atención.' },
  { number: '3', title: 'Recibe reservas', description: 'Comparte tu link personalizado y empieza a recibir citas automáticas.' },
];

const TESTIMONIALS = [
  {
    name: 'Carlos M.',
    business: 'Barbería Elite',
    city: 'Barranquilla',
    text: 'Antes perdía citas todo el tiempo por el desorden de WhatsApp. Con Agendity tengo todo organizado y mis clientes reservan solos.',
    rating: 5,
  },
  {
    name: 'Andrea S.',
    business: 'Studio Bella',
    city: 'Barranquilla',
    text: 'Lo que más me gusta es que puedo ver mis ingresos del día en tiempo real. Ya no tengo que estar sumando al final del mes.',
    rating: 5,
  },
  {
    name: 'Luis R.',
    business: 'Barbershop LR',
    city: 'Barranquilla',
    text: 'Mis clientes me dicen que les encanta el ticket digital con QR. Se ve profesional y me diferencia de la competencia.',
    rating: 5,
  },
];

const FAQ = [
  {
    question: '¿Agendity es gratis?',
    answer: 'Sí. Tienes 7 días gratis con acceso completo al Plan Inteligente, sin necesidad de tarjeta de crédito. Después eliges el plan que mejor se ajuste a tu negocio.',
  },
  {
    question: '¿Mis clientes necesitan descargar una app?',
    answer: 'No. Tus clientes reservan desde tu link personalizado, directo en el navegador de su celular. Sin descargas, sin crear cuenta. Solo eligen servicio, empleado, fecha y listo.',
  },
  {
    question: '¿Qué tipo de negocios pueden usar Agendity?',
    answer: 'Cualquier negocio de servicios, presencial o virtual: barberías, salones de belleza, spas, centros de estética, clínicas de uñas, consultorios médicos, odontólogos, psicólogos, nutricionistas, coaches, fisioterapeutas, estudios de tatuaje, estudios de fotografía, entrenadores personales, tutores, consultores y más. Si tu negocio atiende por cita, Agendity es para ti.',
  },
  {
    question: '¿Puedo gestionar varios empleados?',
    answer: 'Sí. Cada empleado tiene su propia agenda, servicios asignados y horarios de trabajo. Tú ves todo desde un solo panel y puedes filtrar la agenda por empleado.',
  },
  {
    question: '¿Cómo reciben las citas mis clientes?',
    answer: 'Al reservar, el cliente ve un código de ticket en pantalla. Con el Plan Profesional, además recibe un ticket digital estilo VIP con código QR que puedes escanear cuando llegue al local.',
  },
  {
    question: '¿Cómo funciona el pago de las citas?',
    answer: 'El cliente paga directamente a tu negocio por transferencia o efectivo. Tú configuras tus datos de pago (Nequi, Daviplata, Bancolombia) y el cliente sube el comprobante. Tú lo apruebas desde el dashboard.',
  },
  {
    question: '¿Qué pasa si un cliente cancela?',
    answer: 'Tú defines la política de cancelación de tu negocio: el tiempo límite para cancelar sin penalización y el porcentaje de cobro por no-show. El cliente puede cancelar desde su ticket.',
  },
  {
    question: '¿Puedo ver reportes de mi negocio?',
    answer: 'Sí. Tienes reportes de ingresos por período, servicios más solicitados, empleados más ocupados y clientes frecuentes. Todo en tiempo real desde tu dashboard.',
  },
  {
    question: '¿Funciona en celular?',
    answer: 'Sí. Agendity es una app web que funciona en cualquier celular, tablet o computadora. Puedes instalarla en tu pantalla de inicio como si fuera una app nativa.',
  },
];

// JSON-LD structured data for SEO
const jsonLd = [
  {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'Agendity',
    applicationCategory: 'BusinessApplication',
    operatingSystem: 'Web',
    description:
      'Administra citas, empleados y pagos de tu negocio de servicios. Presencial o virtual. Reservas online 24/7.',
    url: 'https://agendity.co',
    offers: {
      '@type': 'Offer',
      price: '0',
      priceCurrency: 'COP',
      description: '7 días de prueba gratis',
    },
    aggregateRating: {
      '@type': 'AggregateRating',
      ratingValue: '5',
      ratingCount: '3',
      bestRating: '5',
    },
  },
  {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: FAQ.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  },
  {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'Agendity',
    url: 'https://agendity.co',
    sameAs: ['https://www.instagram.com/agendity.co'],
  },
];

export default function Home() {
  return (
    <>
      <Suspense><RefCapture /></Suspense>
      {jsonLd.map((ld, i) => (
        <script
          key={i}
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(ld) }}
        />
      ))}

      <div className="flex min-h-screen flex-col">
        {/* Navbar */}
        <nav className="sticky top-0 z-30 border-b border-gray-100 bg-white/80 backdrop-blur-md">
          <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
            <Link href="/" className="text-xl font-bold text-violet-600">
              Agendity
            </Link>
            <div className="flex items-center gap-3">
              <Link href="/#funciones" className="hidden text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors sm:inline">
                Funciones
              </Link>
              <Link href="/#preguntas" className="hidden text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors sm:inline">
                FAQ
              </Link>
              <Link href="/explore" className="hidden text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors sm:inline">
                Explorar
              </Link>
              <Link
                href="/referral"
                className="inline-flex cursor-pointer items-center gap-1.5 rounded-full bg-amber-50 px-3 py-1.5 text-xs font-semibold text-amber-700 ring-1 ring-inset ring-amber-300 transition-colors hover:bg-amber-100 sm:text-sm"
              >
                <Gift className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Gana dinero</span>
                <span className="sm:hidden">Referidos</span>
              </Link>
              <Link href="/login" className="hidden text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors sm:inline">
                Iniciar sesión
              </Link>
              <Suspense><RegisterLink>
                <Button size="sm">Empieza gratis</Button>
              </RegisterLink></Suspense>
            </div>
          </div>
        </nav>

        {/* Hero */}
        <section className="flex flex-col items-center justify-center gap-8 px-6 py-20 text-center sm:py-28">
          <span className="inline-flex items-center gap-2 rounded-full bg-violet-50 px-4 py-1.5 text-sm font-medium text-violet-700">
            <Zap className="h-4 w-4" />
            7 días gratis — Sin tarjeta de crédito
          </span>
          <h1 className="max-w-3xl text-5xl font-bold tracking-tight text-gray-900 sm:text-6xl">
            Reservas online{' '}
            <span className="text-violet-600">para tu negocio</span>
          </h1>
          <p className="max-w-xl text-lg leading-relaxed text-gray-500 sm:text-xl">
            Administra citas, empleados y pagos de tu negocio de servicios.
            Tus clientes reservan en segundos, tú te enfocas en lo que mejor haces.
          </p>
          <div className="flex flex-col gap-4 sm:flex-row">
            <Suspense><RegisterLink>
              <Button size="lg">
                Empieza gratis
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </RegisterLink></Suspense>
            <Link href="/explore">
              <Button variant="outline" size="lg">
                Explorar negocios
              </Button>
            </Link>
          </div>
          <div className="text-center leading-snug">
            <p className="text-sm text-gray-400">¿No tienes negocio? <Link href="/referral" className="cursor-pointer font-medium text-violet-600 underline underline-offset-2 transition-colors hover:text-violet-700">Gana dinero refiriendo</Link></p>
            <p className="text-xs text-gray-400">Ya lo usan negocios de citas en Barranquilla</p>
          </div>
        </section>

        {/* Features */}
        <section id="funciones" className="bg-gray-50 px-6 py-20">
          <div className="mx-auto max-w-6xl">
            <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
              Todo lo que necesitas para crecer
            </h2>
            <p className="mx-auto mb-12 max-w-2xl text-center text-gray-500">
              Herramientas simples y poderosas para que tu negocio funcione como reloj.
            </p>
            <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
              {FEATURES.map((feature) => (
                <div
                  key={feature.title}
                  className="flex flex-col items-center gap-4 rounded-xl bg-white p-6 text-center shadow-sm"
                >
                  <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-violet-100">
                    <feature.icon className="h-6 w-6 text-violet-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {feature.title}
                  </h3>
                  <p className="text-sm leading-relaxed text-gray-500">
                    {feature.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Business owner CTA */}
        <section className="px-6 py-20">
          <div className="mx-auto max-w-6xl">
            <div className="overflow-hidden rounded-2xl border border-violet-200 bg-white">
              <div className="grid gap-0 lg:grid-cols-2">
                {/* Left: copy */}
                <div className="flex flex-col justify-center p-8 sm:p-12">
                  <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-violet-100">
                    <Store className="h-6 w-6 text-violet-600" />
                  </div>
                  <h2 className="mb-3 text-3xl font-bold text-gray-900">
                    ¿Tienes un negocio que trabaja con citas?
                  </h2>
                  <p className="mb-6 text-lg leading-relaxed text-gray-500">
                    Deja de perder clientes por WhatsApp saturado y agendas en papel.
                    Organiza tu negocio, controla tus ingresos y recibe reservas 24/7.
                  </p>

                  <div className="mb-8 space-y-3">
                    {[
                      { icon: Calendar, text: 'Agenda digital que se llena sola' },
                      { icon: MessageCircle, text: 'Confirmaciones y recordatorios por WhatsApp' },
                      { icon: DollarSign, text: 'Control de ingresos y pagos en tiempo real' },
                      { icon: Users, text: 'Gestión de empleados y horarios' },
                      { icon: Smartphone, text: 'Tus clientes reservan desde el celular' },
                    ].map((item) => (
                      <div key={item.text} className="flex items-center gap-3">
                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-violet-100">
                          <item.icon className="h-4 w-4 text-violet-600" />
                        </div>
                        <span className="text-sm text-gray-700">{item.text}</span>
                      </div>
                    ))}
                  </div>

                  <div className="flex flex-col gap-3 sm:flex-row">
                    <Suspense><RegisterLink>
                      <Button size="lg" className="w-full sm:w-auto">
                        Registra tu negocio gratis
                        <ArrowRight className="ml-2 h-4 w-4" />
                      </Button>
                    </RegisterLink></Suspense>
                  </div>
                  <p className="mt-3 text-xs text-gray-400">
                    7 días gratis. Sin tarjeta de crédito.
                  </p>
                </div>

                {/* Right: social proof / stats */}
                <div className="flex flex-col items-center justify-center bg-violet-50 p-8 sm:p-12">
                  <div className="space-y-6 text-center">
                    <p className="text-sm font-medium uppercase tracking-wider text-violet-600">
                      Lo que logras con Agendity
                    </p>
                    <div className="grid grid-cols-2 gap-6">
                      {[
                        { value: '0', label: 'Citas perdidas', sub: 'Todo organizado' },
                        { value: '24/7', label: 'Reservas online', sub: 'Mientras duermes' },
                        { value: '100%', label: 'Control financiero', sub: 'Ingresos claros' },
                        { value: '5 min', label: 'Setup inicial', sub: 'Rápido y fácil' },
                      ].map((stat) => (
                        <div key={stat.label} className="rounded-xl bg-white p-4 shadow-sm">
                          <p className="text-2xl font-bold text-violet-600">{stat.value}</p>
                          <p className="text-sm font-medium text-gray-900">{stat.label}</p>
                          <p className="text-xs text-gray-500">{stat.sub}</p>
                        </div>
                      ))}
                    </div>
                    <div className="flex flex-col items-center gap-2 pt-4">
                      {[
                        'Barberías',
                        'Salones de belleza',
                        'Spas',
                        'Centros de estética',
                        'Cualquier negocio con citas',
                      ].map((type) => (
                        <div key={type} className="flex items-center gap-2 text-sm text-gray-700">
                          <CheckCircle className="h-4 w-4 text-violet-600" />
                          {type}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* How it works */}
        <section id="como-funciona" className="bg-gray-50 px-6 py-20">
          <div className="mx-auto max-w-4xl">
            <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
              Empieza en 3 pasos
            </h2>
            <p className="mx-auto mb-12 max-w-xl text-center text-gray-500">
              Configura tu negocio y empieza a recibir reservas en minutos, no en días.
            </p>
            <div className="grid gap-8 sm:grid-cols-3">
              {STEPS.map((step) => (
                <div key={step.number} className="flex flex-col items-center gap-3 text-center">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-violet-600 text-lg font-bold text-white">
                    {step.number}
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {step.title}
                  </h3>
                  <p className="text-sm text-gray-500">{step.description}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Testimonials */}
        <section id="testimonios" className="px-6 py-20">
          <div className="mx-auto max-w-6xl">
            <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
              Lo que dicen nuestros clientes
            </h2>
            <p className="mx-auto mb-12 max-w-xl text-center text-gray-500">
              Negocios reales en Barranquilla que ya usan Agendity para gestionar sus citas.
            </p>
            <div className="grid gap-8 sm:grid-cols-3">
              {TESTIMONIALS.map((t) => (
                <article
                  key={t.name}
                  className="flex flex-col gap-4 rounded-xl border border-gray-100 bg-white p-6 shadow-sm"
                >
                  <div className="flex gap-0.5">
                    {Array.from({ length: t.rating }).map((_, i) => (
                      <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                    ))}
                  </div>
                  <blockquote className="flex-1 text-sm leading-relaxed text-gray-600">
                    &ldquo;{t.text}&rdquo;
                  </blockquote>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{t.name}</p>
                    <p className="text-xs text-gray-500">{t.business} — {t.city}</p>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* Pricing — fetched from API */}
        <LandingPricing />

        {/* FAQ */}
        <section id="preguntas" className="bg-gray-50 px-6 py-20">
          <div className="mx-auto max-w-3xl">
            <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
              Preguntas frecuentes
            </h2>
            <p className="mx-auto mb-12 max-w-xl text-center text-gray-500">
              Todo lo que necesitas saber antes de empezar.
            </p>
            <div className="space-y-4">
              {FAQ.map((item) => (
                <details
                  key={item.question}
                  className="group rounded-xl border border-gray-200 bg-white"
                >
                  <summary className="flex cursor-pointer items-center justify-between px-6 py-4 text-sm font-semibold text-gray-900 marker:[content:''] [&::-webkit-details-marker]:hidden">
                    {item.question}
                    <span className="ml-4 shrink-0 text-gray-400 transition-transform group-open:rotate-45">+</span>
                  </summary>
                  <p className="px-6 pb-4 text-sm leading-relaxed text-gray-500">
                    {item.answer}
                  </p>
                </details>
              ))}
            </div>
          </div>
        </section>

        {/* Referral Program */}
        <section className="bg-gray-50 px-6 py-20">
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="mb-4 text-3xl font-bold text-gray-900">
              Programa de Referidos
            </h2>
            <p className="mx-auto mb-10 max-w-2xl text-gray-500">
              Recomienda Agendity y gana comisiones por cada negocio que se suscriba con tu código.
            </p>
            <div className="grid gap-8 sm:grid-cols-3">
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-violet-100 text-2xl font-bold text-violet-600">
                  1
                </div>
                <h3 className="mb-2 font-semibold text-gray-900">Obtén tu código</h3>
                <p className="text-sm text-gray-500">Regístrate gratis y recibe tu código de referido al instante.</p>
              </div>
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-violet-100 text-2xl font-bold text-violet-600">
                  2
                </div>
                <h3 className="mb-2 font-semibold text-gray-900">Comparte</h3>
                <p className="text-sm text-gray-500">Recomienda Agendity a negocios que trabajen con citas.</p>
              </div>
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-violet-100 text-2xl font-bold text-violet-600">
                  3
                </div>
                <h3 className="mb-2 font-semibold text-gray-900">Gana</h3>
                <p className="text-sm text-gray-500">Recibe comisión por cada negocio que se suscriba con tu código.</p>
              </div>
            </div>
            <Link href="/referral" className="mt-8 inline-block">
              <Button variant="outline" size="lg">
                Quiero ser referido
              </Button>
            </Link>
          </div>
        </section>

        {/* Final CTA */}
        <section className="bg-violet-600 px-6 py-20 text-center">
          <div className="mx-auto max-w-2xl">
            <h2 className="mb-4 text-3xl font-bold text-white">
              Empieza tu prueba gratis de 7 días
            </h2>
            <p className="mb-8 text-lg text-violet-200">
              Sin tarjeta de crédito. Sin compromisos. Cancela cuando quieras.
            </p>
            <Suspense><RegisterLink>
              <Button
                size="lg"
                className="bg-white text-violet-600 hover:bg-violet-50"
              >
                Crear cuenta gratis
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </RegisterLink></Suspense>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-gray-200 bg-white px-6 py-12">
          <div className="mx-auto grid max-w-6xl gap-8 sm:grid-cols-4">
            <div className="flex flex-col gap-1">
              <Link href="/" className="text-xl font-bold text-violet-600">Agendity</Link>
              <p className="text-sm text-gray-400">
                Gestiona tu negocio, simplifica tus citas.
              </p>
              <p className="mt-1 text-xs text-gray-300">
                Hecho en Barranquilla, Colombia
              </p>
              <a
                href="https://www.instagram.com/agendity.co"
                target="_blank"
                rel="noopener noreferrer"
                className="mt-2 inline-flex cursor-pointer items-center gap-1.5 text-sm text-gray-400 transition-colors hover:text-violet-600"
              >
                <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
                @agendity.co
              </a>
            </div>
            <nav aria-label="Producto" className="flex flex-col gap-2 text-sm text-gray-500">
              <p className="text-xs font-semibold uppercase tracking-wider text-gray-900">Producto</p>
              <Link href="/#funciones" className="hover:text-gray-900 transition-colors">
                Funciones
              </Link>
              <Link href="/#como-funciona" className="hover:text-gray-900 transition-colors">
                Cómo funciona
              </Link>
              <Link href="/#testimonios" className="hover:text-gray-900 transition-colors">
                Testimonios
              </Link>
              <Link href="/#preguntas" className="hover:text-gray-900 transition-colors">
                Preguntas frecuentes
              </Link>
              <Link href="/explore" className="hover:text-gray-900 transition-colors">
                Explorar negocios
              </Link>
            </nav>
            <nav aria-label="Cuenta" className="flex flex-col gap-2 text-sm text-gray-500">
              <p className="text-xs font-semibold uppercase tracking-wider text-gray-900">Cuenta</p>
              <Link href="/register" className="hover:text-gray-900 transition-colors">
                Crear cuenta gratis
              </Link>
              <Link href="/login" className="hover:text-gray-900 transition-colors">
                Iniciar sesión
              </Link>
              <Link href="/referral" className="hover:text-gray-900 transition-colors">
                Programa de referidos
              </Link>
            </nav>
            <nav aria-label="Legal" className="flex flex-col gap-2 text-sm text-gray-500">
              <p className="text-xs font-semibold uppercase tracking-wider text-gray-900">Legal</p>
              <Link href="/terms" className="hover:text-gray-900 transition-colors">
                Términos y Condiciones
              </Link>
              <Link href="/privacy" className="hover:text-gray-900 transition-colors">
                Política de Privacidad
              </Link>
            </nav>
          </div>
          <div className="mx-auto mt-8 max-w-6xl border-t border-gray-100 pt-6 text-center text-xs text-gray-400">
            &copy; {new Date().getFullYear()} Agendity. Todos los derechos reservados.
          </div>
        </footer>
      </div>
    </>
  );
}
