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
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { LandingPricing } from '@/components/landing/landing-pricing';

export const metadata: Metadata = {
  title: 'Agendity — Agenda de citas para tu negocio | Reservas online 24/7',
  description:
    'Software de gestión de citas para barberías, salones, consultorios y cualquier negocio que trabaje con reservas. Reservas online 24/7, agenda digital, control de ingresos, recordatorios automáticos y reportes. 25 días gratis.',
  keywords: [
    'agenda de citas para negocios',
    'reservas online barbería',
    'software gestión de citas',
    'sistema de citas online',
    'agenda digital para negocios',
    'gestión de citas Colombia',
    'reservar cita online',
    'app reservas negocios',
  ],
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'Agendity — Tu negocio, siempre lleno',
    description:
      'Gestiona las citas de tu negocio. Tus clientes reservan en segundos, tú te enfocas en lo que mejor haces. Empieza gratis.',
    url: '/',
  },
};

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
    answer: 'Sí. Tienes 25 días gratis con acceso completo al Plan Inteligente, sin necesidad de tarjeta de crédito. Después eliges el plan que mejor se ajuste a tu negocio.',
  },
  {
    question: '¿Mis clientes necesitan descargar una app?',
    answer: 'No. Tus clientes reservan desde tu link personalizado, directo en el navegador de su celular. Sin descargas, sin crear cuenta. Solo eligen servicio, empleado, fecha y listo.',
  },
  {
    question: '¿Qué tipo de negocios pueden usar Agendity?',
    answer: 'Barberías, salones de belleza, spas, centros de estética, clínicas de uñas y cualquier negocio que trabaje con citas.',
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
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'Agendity',
  applicationCategory: 'BusinessApplication',
  operatingSystem: 'Web',
  description:
    'Software de gestión de citas para negocios que trabajan con reservas. Reservas online 24/7, agenda digital, control de ingresos y reportes.',
  url: 'https://agendity.co',
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'COP',
    description: '25 días de prueba gratis',
  },
  aggregateRating: {
    '@type': 'AggregateRating',
    ratingValue: '5',
    ratingCount: '3',
    bestRating: '5',
  },
};

export default function Home() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

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
              <Link href="/login" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">
                Iniciar sesión
              </Link>
              <Link href="/register">
                <Button size="sm">Empieza gratis</Button>
              </Link>
            </div>
          </div>
        </nav>

        {/* Hero */}
        <section className="flex flex-col items-center justify-center gap-8 px-6 py-20 text-center sm:py-28">
          <span className="inline-flex items-center gap-2 rounded-full bg-violet-50 px-4 py-1.5 text-sm font-medium text-violet-700">
            <Zap className="h-4 w-4" />
            25 días gratis — Sin tarjeta de crédito
          </span>
          <h1 className="max-w-3xl text-5xl font-bold tracking-tight text-gray-900 sm:text-6xl">
            Tu negocio,{' '}
            <span className="text-violet-600">siempre lleno</span>
          </h1>
          <p className="max-w-xl text-lg leading-relaxed text-gray-500 sm:text-xl">
            Agendity gestiona las citas de tu negocio.
            Tus clientes reservan en segundos, tú te enfocas en lo que mejor haces.
          </p>
          <div className="flex flex-col gap-4 sm:flex-row">
            <Link href="/register">
              <Button size="lg">
                Empieza gratis
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Link href="/explore">
              <Button variant="outline" size="lg">
                Explorar negocios
              </Button>
            </Link>
          </div>
          <p className="text-sm text-gray-400">
            Ya lo usan negocios de citas en Barranquilla
          </p>
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
                    <Link href="/register">
                      <Button size="lg" className="w-full sm:w-auto">
                        Registra tu negocio gratis
                        <ArrowRight className="ml-2 h-4 w-4" />
                      </Button>
                    </Link>
                  </div>
                  <p className="mt-3 text-xs text-gray-400">
                    25 días gratis. Sin tarjeta de crédito.
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

        {/* Final CTA */}
        <section className="bg-violet-600 px-6 py-20 text-center">
          <div className="mx-auto max-w-2xl">
            <h2 className="mb-4 text-3xl font-bold text-white">
              Empieza tu prueba gratis de 25 días
            </h2>
            <p className="mb-8 text-lg text-violet-200">
              Sin tarjeta de crédito. Sin compromisos. Cancela cuando quieras.
            </p>
            <Link href="/register">
              <Button
                size="lg"
                className="bg-white text-violet-600 hover:bg-violet-50"
              >
                Crear cuenta gratis
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-gray-200 bg-white px-6 py-12">
          <div className="mx-auto grid max-w-6xl gap-8 sm:grid-cols-3">
            <div className="flex flex-col gap-1">
              <Link href="/" className="text-xl font-bold text-violet-600">Agendity</Link>
              <p className="text-sm text-gray-400">
                Gestiona tu negocio, simplifica tus citas.
              </p>
              <p className="mt-1 text-xs text-gray-300">
                Hecho en Barranquilla, Colombia
              </p>
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
