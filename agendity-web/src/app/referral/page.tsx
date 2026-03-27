'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowRight, Copy, Check, Users, DollarSign, Share2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

const STEPS = [
  {
    icon: Share2,
    title: 'Comparte',
    description: 'Comparte tu enlace de referido con negocios que trabajen con citas.',
  },
  {
    icon: Users,
    title: 'Ganan',
    description: 'Cuando un negocio se registra con tu enlace y activa su suscripcion, ambos ganan.',
  },
  {
    icon: DollarSign,
    title: 'Cobra',
    description: 'Recibe el 10% de comision por cada negocio que se suscriba con tu referido.',
  },
];

export default function ReferralPage() {
  const [form, setForm] = useState({
    referrer_name: '',
    referrer_email: '',
    referrer_phone: '',
    bank_name: '',
    bank_account: '',
    breb_key: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<{ code: string; message: string } | null>(null);
  const [copied, setCopied] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await fetch(`${API_URL}/api/v1/public/referral_codes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || 'Ocurrio un error. Intenta de nuevo.');
        return;
      }

      setResult(data.data);
    } catch {
      setError('Error de conexion. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  };

  const referralLink = result
    ? `${typeof window !== 'undefined' ? window.location.origin : ''}/register?ref=${result.code}`
    : '';

  const handleCopy = async (text: string) => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="flex min-h-screen flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-30 border-b border-gray-100 bg-white/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
          <Link href="/" className="text-xl font-bold text-violet-600">
            Agendity
          </Link>
          <div className="flex items-center gap-3">
            <Link href="/login" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">
              Iniciar sesion
            </Link>
            <Link href="/register">
              <Button size="sm">Empieza gratis</Button>
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="flex flex-col items-center justify-center gap-6 px-6 py-16 text-center sm:py-20">
        <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl">
          Programa de{' '}
          <span className="text-violet-600">Referidos</span>
        </h1>
        <p className="max-w-xl text-lg leading-relaxed text-gray-500">
          Recomienda Agendity a negocios que trabajen con citas y gana una comision por cada negocio que se suscriba.
        </p>
      </section>

      {/* How it works */}
      <section className="bg-gray-50 px-6 py-16">
        <div className="mx-auto max-w-4xl">
          <h2 className="mb-12 text-center text-2xl font-bold text-gray-900">
            Asi funciona
          </h2>
          <div className="grid gap-8 sm:grid-cols-3">
            {STEPS.map((step, i) => (
              <div key={step.title} className="flex flex-col items-center gap-4 text-center">
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-violet-100">
                  <step.icon className="h-7 w-7 text-violet-600" />
                </div>
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-violet-600 text-sm font-bold text-white">
                  {i + 1}
                </div>
                <h3 className="text-lg font-semibold text-gray-900">{step.title}</h3>
                <p className="text-sm text-gray-500">{step.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Form / Result */}
      <section className="px-6 py-16">
        <div className="mx-auto max-w-lg">
          {result ? (
            <div className="rounded-2xl border border-violet-200 bg-white p-8 text-center shadow-sm">
              <div className="mb-4 flex h-16 w-16 mx-auto items-center justify-center rounded-full bg-green-100">
                <Check className="h-8 w-8 text-green-600" />
              </div>
              <h2 className="mb-2 text-2xl font-bold text-gray-900">{result.message}</h2>
              <p className="mb-6 text-gray-500">Comparte tu enlace con negocios que trabajen con citas:</p>

              {/* Code */}
              <div className="mb-4 rounded-xl bg-violet-50 p-4">
                <p className="mb-1 text-xs font-medium uppercase tracking-wider text-violet-600">Tu codigo</p>
                <p className="text-3xl font-bold tracking-widest text-violet-700">{result.code}</p>
              </div>

              {/* Link */}
              <div className="mb-6 flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3">
                <span className="flex-1 truncate text-sm text-gray-600">{referralLink}</span>
                <button
                  onClick={() => handleCopy(referralLink)}
                  className="flex shrink-0 items-center gap-1 rounded-md bg-violet-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-violet-700 transition-colors"
                >
                  {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
                  {copied ? 'Copiado' : 'Copiar'}
                </button>
              </div>

              <p className="mb-4 text-sm text-gray-500">
                Revisa tu email para mas detalles sobre el programa.
              </p>

              <div className="flex flex-col gap-3 sm:flex-row sm:justify-center">
                <Link href={`/referral/dashboard?code=${result.code}`}>
                  <Button>Ver mi dashboard</Button>
                </Link>
                <Link href="/">
                  <Button variant="outline">Volver al inicio</Button>
                </Link>
              </div>
            </div>
          ) : (
            <div className="rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
              <h2 className="mb-2 text-2xl font-bold text-gray-900">Obten tu codigo de referido</h2>
              <p className="mb-6 text-sm text-gray-500">
                Completa el formulario y obtendras tu codigo al instante.
              </p>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="referrer_name" className="mb-1 block text-sm font-medium text-gray-700">
                    Nombre completo *
                  </label>
                  <input
                    id="referrer_name"
                    name="referrer_name"
                    type="text"
                    required
                    value={form.referrer_name}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="Tu nombre"
                  />
                </div>

                <div>
                  <label htmlFor="referrer_email" className="mb-1 block text-sm font-medium text-gray-700">
                    Email *
                  </label>
                  <input
                    id="referrer_email"
                    name="referrer_email"
                    type="email"
                    required
                    value={form.referrer_email}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="tu@email.com"
                  />
                </div>

                <div>
                  <label htmlFor="referrer_phone" className="mb-1 block text-sm font-medium text-gray-700">
                    Telefono
                  </label>
                  <input
                    id="referrer_phone"
                    name="referrer_phone"
                    type="tel"
                    value={form.referrer_phone}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="+57 300 000 0000"
                  />
                </div>

                <hr className="my-2 border-gray-100" />
                <p className="text-xs font-medium text-gray-400 uppercase tracking-wider">Datos de pago (opcional)</p>

                <div>
                  <label htmlFor="bank_name" className="mb-1 block text-sm font-medium text-gray-700">
                    Banco
                  </label>
                  <input
                    id="bank_name"
                    name="bank_name"
                    type="text"
                    value={form.bank_name}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="Bancolombia, Nequi, Daviplata..."
                  />
                </div>

                <div>
                  <label htmlFor="bank_account" className="mb-1 block text-sm font-medium text-gray-700">
                    Cuenta bancaria
                  </label>
                  <input
                    id="bank_account"
                    name="bank_account"
                    type="text"
                    value={form.bank_account}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="Numero de cuenta"
                  />
                </div>

                <div>
                  <label htmlFor="breb_key" className="mb-1 block text-sm font-medium text-gray-700">
                    Llave Bre-B
                  </label>
                  <input
                    id="breb_key"
                    name="breb_key"
                    type="text"
                    value={form.breb_key}
                    onChange={handleChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-sm outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-colors"
                    placeholder="Tu llave Bre-B"
                  />
                </div>

                {error && (
                  <p className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600">{error}</p>
                )}

                <Button type="submit" className="w-full" size="lg" disabled={loading}>
                  {loading ? 'Creando...' : 'Obtener mi codigo de referido'}
                  {!loading && <ArrowRight className="ml-2 h-4 w-4" />}
                </Button>
              </form>
            </div>
          )}
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-auto border-t border-gray-200 bg-white px-6 py-8">
        <div className="mx-auto max-w-6xl text-center text-xs text-gray-400">
          &copy; {new Date().getFullYear()} Agendity. Todos los derechos reservados.
        </div>
      </footer>
    </div>
  );
}
