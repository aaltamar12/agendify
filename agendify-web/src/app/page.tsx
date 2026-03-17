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
} from 'lucide-react';
import { Button } from '@/components/ui/button';

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
];

const STEPS = [
  { number: '1', title: 'Regístrate', description: 'Crea tu cuenta gratis en menos de 2 minutos.' },
  { number: '2', title: 'Configura', description: 'Agrega tus servicios, empleados y horarios.' },
  { number: '3', title: 'Recibe reservas', description: 'Comparte tu link y empieza a recibir citas.' },
];

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col">
      {/* Hero */}
      <section className="flex flex-col items-center justify-center gap-8 px-6 py-24 text-center sm:py-32">
        <h1 className="max-w-3xl text-5xl font-bold tracking-tight text-gray-900 sm:text-6xl">
          Tu negocio,{' '}
          <span className="text-violet-600">siempre lleno</span>
        </h1>
        <p className="max-w-xl text-lg leading-relaxed text-gray-500 sm:text-xl">
          Agendify gestiona las citas de tu barbería o salón. Tus clientes reservan en segundos,
          tú te enfocas en lo que mejor haces.
        </p>
        <div className="flex flex-col gap-4 sm:flex-row">
          <Link href="/register">
            <Button size="lg">Empieza gratis</Button>
          </Link>
          <Link href="/explore">
            <Button variant="outline" size="lg">
              Explorar negocios
            </Button>
          </Link>
        </div>
      </section>

      {/* Features */}
      <section className="bg-gray-50 px-6 py-20">
        <div className="mx-auto max-w-6xl">
          <h2 className="mb-4 text-center text-3xl font-bold text-gray-900">
            Todo lo que necesitas para crecer
          </h2>
          <p className="mx-auto mb-12 max-w-2xl text-center text-gray-500">
            Herramientas simples y poderosas para que tu negocio funcione como reloj.
          </p>
          <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
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
                  ¿Tienes una barbería, salón o negocio de citas?
                </h2>
                <p className="mb-6 text-lg leading-relaxed text-gray-500">
                  Deja de perder clientes por WhatsApp saturado y agendas en papel.
                  Organiza tu negocio, controla tus ingresos y recibe reservas 24/7.
                </p>

                <div className="mb-8 space-y-3">
                  {[
                    { icon: Calendar, text: 'Agenda digital que se llena sola' },
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
                  30 días gratis. Sin tarjeta de crédito.
                </p>
              </div>

              {/* Right: social proof / stats */}
              <div className="flex flex-col items-center justify-center bg-violet-50 p-8 sm:p-12">
                <div className="space-y-6 text-center">
                  <p className="text-sm font-medium uppercase tracking-wider text-violet-600">
                    Lo que logras con Agendify
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
      <section className="bg-gray-50 px-6 py-20">
        <div className="mx-auto max-w-4xl">
          <h2 className="mb-12 text-center text-3xl font-bold text-gray-900">
            ¿Cómo funciona?
          </h2>
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

      {/* CTA */}
      <section className="bg-violet-600 px-6 py-20 text-center">
        <div className="mx-auto max-w-2xl">
          <h2 className="mb-4 text-3xl font-bold text-white">
            Empieza tu prueba gratis de 30 días
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
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-200 bg-white px-6 py-12">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-6 sm:flex-row sm:justify-between">
          <div className="flex flex-col items-center gap-1 sm:items-start">
            <span className="text-xl font-bold text-violet-600">Agendify</span>
            <span className="text-sm text-gray-400">
              Hecho en Barranquilla, Colombia
            </span>
          </div>
          <nav className="flex gap-6 text-sm text-gray-500">
            <Link href="/explore" className="hover:text-gray-900 transition-colors">
              Explorar
            </Link>
            <Link href="/register" className="hover:text-gray-900 transition-colors">
              Registrarse
            </Link>
            <Link href="/login" className="hover:text-gray-900 transition-colors">
              Iniciar sesión
            </Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
