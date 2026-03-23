'use client';

import { useState, useRef, useCallback } from 'react';
import { Check, Upload, CheckCircle, Clock, CreditCard } from 'lucide-react';
import { Button, Card, Spinner } from '@/components/ui';
import {
  useSubscriptionPlans,
  usePaymentInfo,
  useSubscriptionCheckout,
  useSubscriptionStatus,
} from '@/lib/hooks/use-checkout';
import { formatCurrency } from '@/lib/utils/format';
import type { Plan } from '@/lib/api/types';

export default function CheckoutPage() {
  const [selectedPlanId, setSelectedPlanId] = useState<number | null>(null);
  const [proof, setProof] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const { data: plans, isLoading: plansLoading } = useSubscriptionPlans();
  const { data: paymentInfo, isLoading: paymentInfoLoading } = usePaymentInfo();
  const { data: status, isLoading: statusLoading } = useSubscriptionStatus();
  const checkout = useSubscriptionCheckout();

  const selectedPlan = plans?.find((p) => p.id === selectedPlanId) ?? null;

  // File handling
  function handleFileSelect(file: File) {
    if (!file.type.startsWith('image/')) return;
    setProof(file);
    setPreviewUrl(URL.createObjectURL(file));
  }

  function handleFileInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFileSelect(file);
  }

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) handleFileSelect(file);
  }, []);

  function removeFile() {
    setProof(null);
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  function handleSubmit() {
    if (!selectedPlanId || !proof) return;
    checkout.mutate(
      { plan_id: selectedPlanId, proof },
      {
        onSuccess: () => setSubmitted(true),
      },
    );
  }

  // Loading state
  if (plansLoading || statusLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner />
      </div>
    );
  }

  // Already submitted / pending order
  if (status?.pending_order) {
    return (
      <div className="mx-auto max-w-lg py-12 text-center">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-yellow-100">
          <Clock className="h-8 w-8 text-yellow-600" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900">
          Comprobante en revision
        </h1>
        <p className="mt-2 text-gray-500">
          Tu comprobante de pago esta siendo revisado por nuestro equipo.
          Te notificaremos cuando sea aprobado.
        </p>
      </div>
    );
  }

  // Success state after submitting
  if (submitted) {
    return (
      <div className="mx-auto max-w-lg py-12 text-center">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100">
          <CheckCircle className="h-8 w-8 text-green-600" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900">
          Comprobante enviado exitosamente
        </h1>
        <p className="mt-2 text-gray-500">
          Nuestro equipo lo revisara pronto. Te notificaremos cuando tu
          suscripcion este activa.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Elige tu plan</h1>
        <p className="mt-1 text-gray-500">
          Selecciona el plan que mejor se ajuste a tu negocio y sube el
          comprobante de pago.
        </p>
      </div>

      {/* Plan selector */}
      <div className="mb-8 grid gap-4 sm:grid-cols-3">
        {plans?.map((plan) => (
          <PlanCard
            key={plan.id}
            plan={plan}
            selected={selectedPlanId === plan.id}
            onSelect={() => setSelectedPlanId(plan.id)}
          />
        ))}
      </div>

      {/* Payment info + upload (shown when a plan is selected) */}
      {selectedPlan && (
        <div className="space-y-6">
          {/* Payment instructions */}
          <Card className="p-6">
            <div className="mb-4 flex items-center gap-2">
              <CreditCard className="h-5 w-5 text-violet-600" />
              <h2 className="text-lg font-semibold text-gray-900">
                Datos de pago
              </h2>
            </div>
            <p className="mb-4 text-sm text-gray-500">
              Realiza la transferencia por{' '}
              <span className="font-semibold text-gray-900">
                {formatCurrency(selectedPlan.price_monthly)}
              </span>
              {selectedPlan.price_monthly_usd && (
                <span className="text-gray-400">
                  {' '}(~${selectedPlan.price_monthly_usd} USD)
                </span>
              )}
              {' '}a cualquiera de estas cuentas:
            </p>

            {paymentInfoLoading ? (
              <div className="flex justify-center py-4">
                <Spinner />
              </div>
            ) : (
              <div className="space-y-3">
                {paymentInfo?.nequi && (
                  <PaymentMethod label="Nequi" value={paymentInfo.nequi} />
                )}
                {paymentInfo?.bancolombia && (
                  <PaymentMethod
                    label="Bancolombia"
                    value={paymentInfo.bancolombia}
                  />
                )}
                {paymentInfo?.daviplata && (
                  <PaymentMethod
                    label="Daviplata"
                    value={paymentInfo.daviplata}
                  />
                )}
                {paymentInfo?.instructions && (
                  <p className="mt-3 text-sm text-gray-500">
                    {paymentInfo.instructions}
                  </p>
                )}
              </div>
            )}
          </Card>

          {/* Upload proof */}
          <Card className="p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Sube tu comprobante de pago
            </h2>
            <div
              className="relative cursor-pointer rounded-xl border-2 border-dashed border-gray-300 p-6 transition-colors hover:border-violet-500"
              onClick={() => fileInputRef.current?.click()}
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleDrop}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={handleFileInputChange}
              />

              {previewUrl ? (
                <div className="flex flex-col items-center gap-3">
                  <img
                    src={previewUrl}
                    alt="Comprobante de pago"
                    className="max-h-48 rounded-lg object-contain"
                  />
                  <p className="text-sm text-gray-500">{proof?.name}</p>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      removeFile();
                    }}
                    className="text-sm font-medium text-red-600 hover:text-red-700"
                  >
                    Eliminar
                  </button>
                </div>
              ) : (
                <div className="flex flex-col items-center gap-2 text-center">
                  <Upload className="h-8 w-8 text-gray-400" />
                  <p className="text-sm font-medium text-gray-700">
                    Arrastra tu comprobante aqui o haz clic para seleccionar
                  </p>
                  <p className="text-xs text-gray-400">
                    PNG, JPG o JPEG. Maximo 10 MB.
                  </p>
                </div>
              )}
            </div>
          </Card>

          {/* Submit button */}
          <Button
            fullWidth
            size="lg"
            disabled={!proof || checkout.isPending}
            loading={checkout.isPending}
            onClick={handleSubmit}
          >
            Enviar comprobante de pago
          </Button>

          {checkout.isError && (
            <p className="text-center text-sm text-red-600">
              Hubo un error al enviar el comprobante. Intenta de nuevo.
            </p>
          )}
        </div>
      )}
    </div>
  );
}

// --- Sub-components ---

function PlanCard({
  plan,
  selected,
  onSelect,
}: {
  plan: Plan;
  selected: boolean;
  onSelect: () => void;
}) {
  const isPopular = plan.slug === 'professional' || plan.slug === 'profesional';

  return (
    <div
      className={`relative flex cursor-pointer flex-col rounded-2xl border-2 bg-white p-5 transition-all ${
        selected
          ? 'border-violet-600 shadow-lg ring-1 ring-violet-600'
          : 'border-gray-200 hover:border-gray-300'
      }`}
      onClick={onSelect}
    >
      {isPopular && (
        <span className="absolute -top-3 right-4 rounded-full bg-violet-100 px-3 py-0.5 text-xs font-semibold text-violet-700">
          Popular
        </span>
      )}

      <h3 className="text-lg font-semibold text-gray-900">{plan.name}</h3>
      {plan.description && (
        <p className="mt-1 text-sm text-gray-500">{plan.description}</p>
      )}

      <div className="mt-3">
        <span className="text-3xl font-bold text-gray-900">
          {formatCurrency(plan.price_monthly)}
        </span>
        <span className="text-sm text-gray-500"> /mes</span>
        {plan.price_monthly_usd && (
          <p className="mt-0.5 text-xs text-gray-400">
            ~${plan.price_monthly_usd} USD/mes
          </p>
        )}
      </div>

      {plan.features && plan.features.length > 0 && (
        <ul className="mt-4 flex-1 space-y-2">
          {plan.features.map((feature) => (
            <li
              key={feature}
              className="flex items-start gap-2 text-sm text-gray-600"
            >
              <Check className="mt-0.5 h-4 w-4 shrink-0 text-violet-600" />
              {feature}
            </li>
          ))}
        </ul>
      )}

      <Button
        variant={selected ? 'primary' : 'outline'}
        fullWidth
        className="mt-4"
        onClick={(e) => {
          e.stopPropagation();
          onSelect();
        }}
      >
        {selected ? 'Seleccionado' : 'Seleccionar'}
      </Button>
    </div>
  );
}

function PaymentMethod({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center justify-between rounded-lg bg-gray-50 px-4 py-3">
      <span className="text-sm font-medium text-gray-700">{label}</span>
      <span className="font-mono text-sm text-gray-900">{value}</span>
    </div>
  );
}
