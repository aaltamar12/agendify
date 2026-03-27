'use client';

import { Suspense, useEffect, useState, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { QRCodeSVG } from 'qrcode.react';
import { Copy, Check, Users, DollarSign, Clock, ExternalLink, Save, Share2, Download, Banknote, FileText } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Spinner } from '@/components/ui/spinner';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

interface Referrer {
  name: string;
  email: string;
  phone: string;
  code: string;
  bank_name: string;
  bank_account: string;
  breb_key: string;
  commission_percentage: number;
}

interface Stats {
  total_referrals: number;
  active_subscriptions: number;
  total_earned: number;
  pending_commission: number;
  paid_commission: number;
}

interface ReferralEntry {
  business_name: string;
  business_type: string;
  registered_at: string;
  trial_ends_at: string;
  trial_days_remaining: number;
  trial_expired: boolean;
  has_subscription: boolean;
  plan_name: string | null;
  referral_status: string;
  commission_amount: number;
  disbursement_requested_at: string | null;
  disbursement_paid_at: string | null;
  disbursement_proof_url: string | null;
  disbursement_notes: string | null;
}

interface DisbursementEntry {
  referral_id: number;
  business_name: string;
  amount: number;
  status: string;
  requested_at: string | null;
  paid_at: string | null;
  proof_url: string | null;
  notes: string | null;
}

interface DashboardData {
  referrer: Referrer;
  stats: Stats;
  referrals: ReferralEntry[];
  disbursements: DisbursementEntry[];
  referral_link: string;
  conditions: string;
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', minimumFractionDigits: 0 }).format(amount);
}

export default function ReferralDashboardPage() {
  return (
    <Suspense fallback={<div className="flex min-h-screen items-center justify-center"><Spinner size="lg" /></div>}>
      <DashboardContent />
    </Suspense>
  );
}

function DashboardContent() {
  const searchParams = useSearchParams();
  const code = searchParams.get('code') || '';

  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState(false);

  // Editable form
  const [editForm, setEditForm] = useState({
    referrer_name: '',
    referrer_email: '',
    referrer_phone: '',
    bank_name: '',
    bank_account: '',
    breb_key: '',
  });
  const [saving, setSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');

  // Disbursement request
  const [requestingDisbursement, setRequestingDisbursement] = useState(false);
  const [disbursementMessage, setDisbursementMessage] = useState('');

  const fetchDashboard = useCallback(async () => {
    if (!code) {
      setError('No se proporcionó un código de referido.');
      setLoading(false);
      return;
    }

    try {
      const res = await fetch(`${API_URL}/api/v1/public/referral_codes/${code}/dashboard`);
      const json = await res.json();

      if (!res.ok) {
        setError(json.error || 'Código no encontrado.');
        return;
      }

      setData(json.data);
      setEditForm({
        referrer_name: json.data.referrer.name || '',
        referrer_email: json.data.referrer.email || '',
        referrer_phone: json.data.referrer.phone || '',
        bank_name: json.data.referrer.bank_name || '',
        bank_account: json.data.referrer.bank_account || '',
        breb_key: json.data.referrer.breb_key || '',
      });
    } catch {
      setError('Error de conexión. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  }, [code]);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard]);

  const handleCopy = async (text: string) => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleEditChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setEditForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setSaveMessage('');

    try {
      const res = await fetch(`${API_URL}/api/v1/public/referral_codes/${code}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editForm),
      });

      const json = await res.json();

      if (!res.ok) {
        setSaveMessage(json.error || 'Error al guardar.');
        return;
      }

      setSaveMessage('Información actualizada correctamente.');
      // Refresh dashboard data
      await fetchDashboard();
    } catch {
      setSaveMessage('Error de conexión.');
    } finally {
      setSaving(false);
    }
  };

  const handleRequestDisbursement = async () => {
    setRequestingDisbursement(true);
    setDisbursementMessage('');

    try {
      const res = await fetch(`${API_URL}/api/v1/public/referral_codes/${code}/request_disbursement`, {
        method: 'POST',
      });
      const json = await res.json();

      if (!res.ok) {
        setDisbursementMessage(json.error || 'Error al solicitar desembolso.');
        return;
      }

      setDisbursementMessage(json.data.message);
      await fetchDashboard();
    } catch {
      setDisbursementMessage('Error de conexion.');
    } finally {
      setRequestingDisbursement(false);
    }
  };

  // Check if there are activated referrals without disbursement request
  const hasRequestableCommissions = data?.referrals.some(
    (r) => r.referral_status === 'activated' && !r.disbursement_requested_at
  ) ?? false;

  const renderTrialBadge = (referral: ReferralEntry) => {
    if (referral.has_subscription) {
      return <Badge variant="success">Suscrito ({referral.plan_name})</Badge>;
    }

    if (referral.trial_expired) {
      const daysAgo = Math.abs(referral.trial_days_remaining);
      return (
        <Badge variant="error">
          Trial vencido hace {daysAgo} {daysAgo === 1 ? 'dia' : 'dias'}
        </Badge>
      );
    }

    return (
      <Badge variant="warning">
        Trial: {referral.trial_days_remaining} {referral.trial_days_remaining === 1 ? 'dia' : 'dias'} restantes
      </Badge>
    );
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner size="lg" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 px-6">
        <p className="text-lg text-red-600">{error}</p>
        <Link href="/referral">
          <Button variant="outline">Volver al programa de referidos</Button>
        </Link>
      </div>
    );
  }

  if (!data) return null;

  const { referrer, stats, referrals, disbursements, referral_link, conditions } = data;

  return (
    <div className="flex min-h-screen flex-col bg-gray-50">
      {/* Navbar */}
      <nav className="sticky top-0 z-30 border-b border-gray-100 bg-white/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
          <Link href="/" className="text-xl font-bold text-violet-600">
            Agendity
          </Link>
          <Link href="/referral" className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors">
            Programa de Referidos
          </Link>
        </div>
      </nav>

      <main className="mx-auto w-full max-w-5xl px-6 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900 sm:text-3xl">
            Hola, {referrer.name}
          </h1>
          <p className="mt-1 text-gray-500">
            Tu codigo de referido:{' '}
            <span className="font-mono font-bold text-violet-600">{referrer.code}</span>
          </p>
        </div>

        {/* Referral link + QR */}
        <Card className="mb-8">
          <div className="flex flex-col items-center gap-6 sm:flex-row">
            <div className="flex-1">
              <h2 className="mb-2 text-lg font-semibold text-gray-900">Tu enlace de referido</h2>
              <div className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3">
                <span className="flex-1 truncate text-sm text-gray-600">{referral_link}</span>
                <button
                  onClick={() => handleCopy(referral_link)}
                  className="flex shrink-0 items-center gap-1 rounded-md bg-violet-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-violet-700 transition-colors"
                >
                  {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
                  {copied ? 'Copiado' : 'Copiar'}
                </button>
              </div>
            </div>
            <div className="flex flex-col items-center gap-3">
              <div id="referral-qr" className="rounded-lg bg-white p-3">
                <QRCodeSVG value={referral_link} size={120} />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={async () => {
                    const canvas = document.querySelector('#referral-qr svg') as SVGElement;
                    if (!canvas) return;
                    // Convert SVG to PNG blob
                    const svgData = new XMLSerializer().serializeToString(canvas);
                    const img = new Image();
                    img.onload = async () => {
                      const c = document.createElement('canvas');
                      c.width = 400; c.height = 400;
                      const ctx = c.getContext('2d')!;
                      ctx.fillStyle = '#ffffff';
                      ctx.fillRect(0, 0, 400, 400);
                      ctx.drawImage(img, 20, 20, 360, 360);
                      const blob = await new Promise<Blob>((r) => c.toBlob((b) => r(b!), 'image/png'));
                      if (navigator.share) {
                        const file = new File([blob], 'agendity-referido.png', { type: 'image/png' });
                        navigator.share({ title: 'Agendity - Código de referido', text: `Registrate con mi código y obtén 25 días gratis: ${referral_link}`, files: [file] }).catch(() => {});
                      } else {
                        const url = URL.createObjectURL(blob);
                        const a = document.createElement('a');
                        a.href = url; a.download = 'agendity-referido.png'; a.click();
                        URL.revokeObjectURL(url);
                      }
                    };
                    img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgData)));
                  }}
                  className="inline-flex items-center gap-1.5 rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-violet-700"
                >
                  <Share2 className="h-3.5 w-3.5" />
                  Compartir QR
                </button>
              </div>
            </div>
          </div>
        </Card>

        {/* Stat cards */}
        <div className="mb-8 grid gap-4 sm:grid-cols-3">
          <Card>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-violet-100">
                <Users className="h-5 w-5 text-violet-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Total referidos</p>
                <p className="text-2xl font-bold text-gray-900">{stats.total_referrals}</p>
              </div>
            </div>
          </Card>

          <Card>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
                <DollarSign className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Comisiones ganadas</p>
                <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats.total_earned)}</p>
              </div>
            </div>
          </Card>

          <Card>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100">
                <Clock className="h-5 w-5 text-amber-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Comisiones pendientes</p>
                <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats.pending_commission)}</p>
              </div>
            </div>
          </Card>
        </div>

        {/* Conditions note */}
        <div className="mb-8 rounded-lg border border-violet-200 bg-violet-50 px-4 py-3">
          <p className="text-sm text-violet-700">{conditions}</p>
        </div>

        {/* Referrals table */}
        <Card className="mb-8">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Negocios referidos</h2>
          {referrals.length === 0 ? (
            <p className="py-8 text-center text-gray-400">
              Aun no tienes referidos. Comparte tu enlace para empezar a ganar comisiones.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                    <th className="pb-3 pr-4">Negocio</th>
                    <th className="pb-3 pr-4">Tipo</th>
                    <th className="pb-3 pr-4">Registro</th>
                    <th className="pb-3 pr-4">Estado</th>
                    <th className="pb-3 pr-4">Desembolso</th>
                    <th className="pb-3 text-right">Comision</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {referrals.map((referral, i) => (
                    <tr key={i} className="hover:bg-gray-50">
                      <td className="py-3 pr-4 font-medium text-gray-900">{referral.business_name}</td>
                      <td className="py-3 pr-4 text-gray-500 capitalize">{referral.business_type}</td>
                      <td className="py-3 pr-4 text-gray-500">{referral.registered_at}</td>
                      <td className="py-3 pr-4">
                        <div className="flex flex-col gap-1">
                          {renderTrialBadge(referral)}
                          {referral.trial_expired && !referral.has_subscription && (
                            <span className="text-xs text-red-500">Recuerdale renovar!</span>
                          )}
                        </div>
                      </td>
                      <td className="py-3 pr-4">
                        {referral.referral_status === 'paid' ? (
                          <Badge variant="success">Pagado</Badge>
                        ) : referral.disbursement_requested_at ? (
                          <Badge variant="warning">Solicitado</Badge>
                        ) : referral.referral_status === 'activated' ? (
                          <span className="text-xs text-gray-400">Pendiente</span>
                        ) : (
                          <span className="text-xs text-gray-300">—</span>
                        )}
                      </td>
                      <td className="py-3 text-right font-medium text-gray-900">
                        {referral.commission_amount ? formatCurrency(referral.commission_amount) : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        {/* Disbursement request button */}
        {hasRequestableCommissions && (
          <Card className="mb-8">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Solicitar desembolso</h2>
                <p className="text-sm text-gray-500">
                  Tienes comisiones activadas listas para solicitar su pago.
                </p>
              </div>
              <Button onClick={handleRequestDisbursement} loading={requestingDisbursement}>
                <Banknote className="h-4 w-4" />
                Solicitar desembolso
              </Button>
            </div>
            {disbursementMessage && (
              <p className={`mt-3 rounded-lg px-4 py-2 text-sm ${disbursementMessage.includes('Error') || disbursementMessage.includes('error') ? 'bg-red-50 text-red-600' : 'bg-green-50 text-green-600'}`}>
                {disbursementMessage}
              </p>
            )}
          </Card>
        )}

        {/* Disbursements history */}
        {disbursements && disbursements.length > 0 && (
          <Card className="mb-8">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">Historial de desembolsos</h2>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                    <th className="pb-3 pr-4">Negocio</th>
                    <th className="pb-3 pr-4">Monto</th>
                    <th className="pb-3 pr-4">Fecha solicitud</th>
                    <th className="pb-3 pr-4">Fecha pago</th>
                    <th className="pb-3 pr-4">Estado</th>
                    <th className="pb-3 pr-4">Comprobante</th>
                    <th className="pb-3">Notas</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {disbursements.map((d) => (
                    <tr key={d.referral_id} className="hover:bg-gray-50">
                      <td className="py-3 pr-4 font-medium text-gray-900">{d.business_name}</td>
                      <td className="py-3 pr-4 text-gray-900">{formatCurrency(d.amount)}</td>
                      <td className="py-3 pr-4 text-gray-500">{d.requested_at || '—'}</td>
                      <td className="py-3 pr-4 text-gray-500">{d.paid_at || '—'}</td>
                      <td className="py-3 pr-4">
                        {d.status === 'paid' ? (
                          <Badge variant="success">Pagado</Badge>
                        ) : (
                          <Badge variant="warning">Solicitado</Badge>
                        )}
                      </td>
                      <td className="py-3 pr-4">
                        {d.proof_url ? (
                          <a
                            href={d.proof_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-violet-600 hover:text-violet-700 text-xs font-medium"
                          >
                            <FileText className="h-3.5 w-3.5" />
                            Ver
                          </a>
                        ) : (
                          <span className="text-gray-300">—</span>
                        )}
                      </td>
                      <td className="py-3 text-sm text-gray-500">{d.notes || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}

        {/* Edit section */}
        <Card className="mb-8">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Tu informacion</h2>
          <p className="mb-4 text-sm text-gray-500">
            Actualiza tus datos de contacto y pago para recibir tus comisiones.
          </p>

          <form onSubmit={handleSave} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <Input
                label="Nombre completo"
                name="referrer_name"
                value={editForm.referrer_name}
                onChange={handleEditChange}
                required
              />
              <Input
                label="Email"
                name="referrer_email"
                type="email"
                value={editForm.referrer_email}
                onChange={handleEditChange}
                required
              />
              <Input
                label="Telefono"
                name="referrer_phone"
                type="tel"
                value={editForm.referrer_phone}
                onChange={handleEditChange}
              />
            </div>

            <hr className="my-2 border-gray-100" />
            <p className="text-xs font-medium uppercase tracking-wider text-gray-400">Datos de pago</p>

            <div className="grid gap-4 sm:grid-cols-2">
              <Input
                label="Banco"
                name="bank_name"
                value={editForm.bank_name}
                onChange={handleEditChange}
                placeholder="Bancolombia, Nequi, Daviplata..."
              />
              <Input
                label="Cuenta bancaria"
                name="bank_account"
                value={editForm.bank_account}
                onChange={handleEditChange}
                placeholder="Numero de cuenta"
              />
              <Input
                label="Llave Bre-B"
                name="breb_key"
                value={editForm.breb_key}
                onChange={handleEditChange}
                placeholder="Tu llave Bre-B"
              />
            </div>

            {saveMessage && (
              <p className={`rounded-lg px-4 py-2 text-sm ${saveMessage.includes('Error') ? 'bg-red-50 text-red-600' : 'bg-green-50 text-green-600'}`}>
                {saveMessage}
              </p>
            )}

            <Button type="submit" loading={saving}>
              <Save className="h-4 w-4" />
              Guardar cambios
            </Button>
          </form>
        </Card>
      </main>

      {/* Footer */}
      <footer className="mt-auto border-t border-gray-200 bg-white px-6 py-8">
        <div className="mx-auto max-w-6xl text-center text-xs text-gray-400">
          &copy; {new Date().getFullYear()} Agendity. Todos los derechos reservados.
        </div>
      </footer>
    </div>
  );
}
