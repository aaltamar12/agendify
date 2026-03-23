'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Input, Card, Avatar, Button, Spinner } from '@/components/ui';
import { ArrowRight } from 'lucide-react';
import { get } from '@/lib/api/client';
import { useBookingStore } from '@/lib/stores/booking-store';
import {
  customerInfoSchema,
  type CustomerInfoFormData,
} from '@/lib/validations/booking';
import {
  getSavedCustomer,
  saveCustomer,
  clearSavedCustomer,
  type SavedCustomer,
} from '@/lib/utils/saved-customer';

const emailLookupSchema = z.object({
  email: z.string().min(1, 'Ingresa tu correo').email('Correo no válido'),
});

type EmailLookupFormData = z.infer<typeof emailLookupSchema>;

type FormMode = 'saved' | 'form' | 'recover';

interface CustomerFormProps {
  slug: string;
}

export function CustomerForm({ slug }: CustomerFormProps) {
  const { customerInfo, setCustomerInfo, nextStep } = useBookingStore();

  const [saved, setSaved] = useState<SavedCustomer | null>(null);
  const [mode, setMode] = useState<FormMode>('form');
  const [wasCleared, setWasCleared] = useState(false);
  const [lookupLoading, setLookupLoading] = useState(false);

  // Load saved customer on mount
  useEffect(() => {
    const data = getSavedCustomer();
    if (data) {
      setSaved(data);
      setMode('saved');
    }
  }, []);

  // --- Main form ---
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset: resetForm,
  } = useForm<CustomerInfoFormData>({
    resolver: zodResolver(customerInfoSchema),
    defaultValues: {
      name: customerInfo?.name ?? '',
      email: customerInfo?.email ?? '',
      phone: customerInfo?.phone ?? '',
    },
  });

  // --- Email lookup form ---
  const {
    register: registerLookup,
    handleSubmit: handleLookupSubmit,
    formState: { errors: lookupErrors },
    setError: setLookupError,
  } = useForm<EmailLookupFormData>({
    resolver: zodResolver(emailLookupSchema),
  });

  function onSubmit(data: CustomerInfoFormData) {
    saveCustomer({ name: data.name, email: data.email, phone: data.phone });
    setCustomerInfo({
      name: data.name,
      email: data.email,
      phone: data.phone,
    });
    nextStep();
  }

  function handleContinueWithSaved() {
    if (!saved) return;
    setCustomerInfo({
      name: saved.name,
      email: saved.email,
      phone: saved.phone,
    });
    nextStep();
  }

  function handleNotMe() {
    clearSavedCustomer();
    setSaved(null);
    setWasCleared(true);
    setMode('form');
    resetForm({ name: '', email: '', phone: '' });
  }

  async function handleRecoverLookup(data: EmailLookupFormData) {
    // First check localStorage
    const stored = getSavedCustomer();
    if (stored && stored.email.toLowerCase() === data.email.toLowerCase()) {
      setSaved(stored);
      setMode('saved');
      return;
    }

    // Search in backend
    setLookupLoading(true);
    try {
      const res = await get<{ data: { name: string; email: string; phone: string; credit_balance?: number } }>(
        `/api/v1/public/customer_lookup?email=${encodeURIComponent(data.email)}&slug=${encodeURIComponent(slug)}`
      );
      const customer = res.data;
      // Save to localStorage for next time
      saveCustomer({ name: customer.name, email: customer.email, phone: customer.phone });
      setSaved({ name: customer.name, email: customer.email, phone: customer.phone });
      // Store credit balance for use in confirmation step
      if (customer.credit_balance && customer.credit_balance > 0) {
        const { setCreditBalance } = await import('@/lib/stores/booking-store').then(m => ({ setCreditBalance: m.useBookingStore.getState().setCreditBalance }));
        setCreditBalance(customer.credit_balance);
      }
      setMode('saved');
    } catch {
      // Not found — pre-fill email and show form
      setLookupError('email', {
        message: 'No encontramos una reserva anterior con ese correo. Ingresa tus datos.',
      });
    } finally {
      setLookupLoading(false);
    }
  }

  // --- Mode: Returning user with saved data ---
  if (mode === 'saved' && saved) {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">Tus datos</h2>
          <p className="mt-1 text-sm text-gray-500">
            Confirma tu información para continuar
          </p>
        </div>

        <Card className="p-4">
          <div className="flex items-center gap-3">
            <Avatar name={saved.name} size="md" />
            <div className="min-w-0">
              <p className="font-semibold text-gray-900 truncate">
                Hola, {saved.name.split(' ')[0]}!
              </p>
              <p className="text-sm text-gray-500 truncate">{saved.email}</p>
              <p className="text-sm text-gray-500">{saved.phone}</p>
            </div>
          </div>
        </Card>

        <div className="flex flex-col gap-3">
          <Button size="sm" onClick={handleContinueWithSaved}>
            Continuar con estos datos
            <ArrowRight className="ml-1 h-4 w-4" />
          </Button>

          <button
            type="button"
            onClick={handleNotMe}
            className="text-sm text-violet-600 hover:text-violet-700 transition-colors"
          >
            ¿No eres tú?
          </button>
        </div>
      </div>
    );
  }

  // --- Mode: Email recovery ---
  if (mode === 'recover') {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">
            Recuperar datos
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            Ingresa el correo con el que reservaste antes
          </p>
        </div>

        <form
          onSubmit={handleLookupSubmit(handleRecoverLookup)}
          className="space-y-4"
        >
          <Input
            label="Correo electrónico"
            type="email"
            placeholder="Ej: juan@email.com"
            error={lookupErrors.email?.message}
            {...registerLookup('email')}
          />

          <Button type="submit" size="sm" fullWidth loading={lookupLoading}>
            Buscar mis datos
          </Button>
        </form>

        <button
          type="button"
          onClick={() => setMode('form')}
          className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
        >
          Volver al formulario
        </button>
      </div>
    );
  }

  // --- Mode: Empty form (new user or cleared session) ---
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-gray-900">Tus datos</h2>
        <p className="mt-1 text-sm text-gray-500">
          Ingresa tu información para confirmar la reserva
        </p>
        <button
          type="button"
          onClick={() => setMode('recover')}
          className="mt-1 text-sm text-violet-600 hover:text-violet-700 transition-colors"
        >
          ¿Ya reservaste antes? Usa tu correo registrado →
        </button>
      </div>

      <form
        id="customer-form"
        onSubmit={handleSubmit(onSubmit)}
        className="space-y-4"
      >
        <Input
          label="Nombre completo"
          placeholder="Ej: Juan Pérez"
          error={errors.name?.message}
          {...register('name')}
        />

        <Input
          label="Correo electrónico"
          type="email"
          placeholder="Ej: juan@email.com"
          error={errors.email?.message}
          {...register('email')}
        />

        <Input
          label="Teléfono"
          type="tel"
          placeholder="Ej: 3001234567"
          error={errors.phone?.message}
          {...register('phone')}
        />
      </form>

      <Button type="submit" form="customer-form" size="sm" fullWidth>
        Continuar
        <ArrowRight className="ml-1 h-4 w-4" />
      </Button>

      <p className="text-xs text-gray-400">
        Tu información se usará únicamente para gestionar tu cita.
      </p>

    </div>
  );
}
