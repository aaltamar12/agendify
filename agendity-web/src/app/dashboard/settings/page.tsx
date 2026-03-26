'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useState, useRef, useCallback, useEffect } from 'react';
import { MapPin, Upload, Loader2, Bell, Volume2, VolumeX, Clock, Coffee, Timer, Image, Search, X, Camera } from 'lucide-react';
import { Button, Card, Input, Textarea, Select, Skeleton } from '@/components/ui';
import { MapEmbed } from '@/components/shared/map-embed';
import { LocationPicker } from '@/components/shared/location-picker';
import { UpgradeBanner } from '@/components/shared/upgrade-banner';
import {
  useCurrentBusiness,
  useUpdateBusiness,
  useUploadLogo,
  useUploadCover,
  useCoverGallery,
  useSelectCover,
  useBusinessHours,
  useUpdateBusinessHours,
} from '@/lib/hooks/use-business';
import { useCurrentSubscription } from '@/lib/hooks/use-subscription';
import { useCountries, useStates, useCities } from '@/lib/hooks/use-locations';
import { useUIStore } from '@/lib/stores/ui-store';
import { DAYS_OF_WEEK, BRAND_CUSTOMIZATION_PLANS, MAX_FILE_SIZE_MB } from '@/lib/constants';
import type { PlanSlug } from '@/lib/constants';
import type { BusinessHour } from '@/lib/api/types';

// --- Business profile schema ---
const profileSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  description: z.string().optional(),
  phone: z.string().min(1, 'El teléfono es requerido'),
  address: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  country: z.string().optional(),
  instagram_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
  facebook_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
  website_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
  google_maps_url: z
    .string()
    .url('Ingresa una URL válida')
    .optional()
    .or(z.literal('')),
  nit: z.string().optional(),
  legal_representative_name: z.string().optional(),
  legal_representative_document: z.string().optional(),
  legal_representative_document_type: z.string().optional(),
});

type ProfileFormData = z.infer<typeof profileSchema>;

// --- Payment schema ---
const paymentSchema = z.object({
  nequi_phone: z.string().optional(),
  daviplata_phone: z.string().optional(),
  bancolombia_account: z.string().optional(),
  breb_key: z.string().optional(),
});

type PaymentFormData = z.infer<typeof paymentSchema>;

// --- Cancellation schema ---
const cancellationSchema = z.object({
  cancellation_policy_pct: z.string(),
  cancellation_deadline_hours: z
    .number({ error: 'Ingresa un número válido' })
    .min(1, 'Mínimo 1 hora')
    .max(72, 'Máximo 72 horas'),
});

type CancellationFormData = z.infer<typeof cancellationSchema>;

// --- Time options for schedule ---
const timeOptions = Array.from({ length: 30 }, (_, i) => {
  const hour = Math.floor(i / 2) + 6;
  const min = i % 2 === 0 ? '00' : '30';
  const value = `${String(hour).padStart(2, '0')}:${min}`;
  return { value, label: value };
});

export default function SettingsPage() {
  const { data: business, isLoading: loadingBusiness } = useCurrentBusiness();
  const { data: hours, isLoading: loadingHours } = useBusinessHours();
  const updateBusiness = useUpdateBusiness();
  const uploadLogo = useUploadLogo();
  const uploadCover = useUploadCover();
  const selectCover = useSelectCover();
  const updateHours = useUpdateBusinessHours();
  const { addToast } = useUIStore();
  const { planSlug } = useCurrentSubscription();

  const canCustomizeBrand = BRAND_CUSTOMIZATION_PLANS.includes(planSlug);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Configuración</h1>

      <div className="space-y-6">
        {/* Logo / Profile photo upload */}
        {loadingBusiness ? (
          <Skeleton className="h-40 w-full" />
        ) : (
          business && (
            <LogoSection
              logoUrl={business.logo_url}
              businessName={business.name}
              isIndependent={!!business.independent}
              onUpload={async (file) => {
                try {
                  await uploadLogo.mutateAsync(file);
                  addToast({ type: 'success', message: business.independent ? 'Foto de perfil actualizada' : 'Logo actualizado' });
                } catch {
                  addToast({ type: 'error', message: business.independent ? 'Error al subir la foto de perfil' : 'Error al subir el logo' });
                }
              }}
              loading={uploadLogo.isPending}
            />
          )
        )}

        {/* Cover image — hidden for independent professionals */}
        {!business?.independent && (
          loadingBusiness ? (
            <Skeleton className="h-48 w-full" />
          ) : business && (
            <CoverSection
              coverUrl={business.cover_url}
              coverSource={business.cover_source}
              businessType={business.business_type}
              onUpload={async (file) => {
                try {
                  await uploadCover.mutateAsync(file);
                  addToast({ type: 'success', message: 'Portada actualizada' });
                } catch {
                  addToast({ type: 'error', message: 'Error al subir la portada' });
                }
              }}
              onSelectFromGallery={async (url) => {
                try {
                  await selectCover.mutateAsync(url);
                  addToast({ type: 'success', message: 'Portada seleccionada' });
                } catch {
                  addToast({ type: 'error', message: 'Error al seleccionar la portada' });
                }
              }}
              loading={uploadCover.isPending || selectCover.isPending}
            />
          )
        )}

        {/* Business Profile */}
        {loadingBusiness ? (
          <Skeleton className="h-72 w-full" />
        ) : (
          business && (
            <ProfileSection
              business={business}
              onSave={async (data) => {
                try {
                  await updateBusiness.mutateAsync(data);
                  addToast({ type: 'success', message: 'Perfil actualizado' });
                } catch {
                  addToast({ type: 'error', message: 'Error al actualizar el perfil' });
                }
              }}
              onSaveCoords={async (lat, lng) => {
                try {
                  await updateBusiness.mutateAsync({ latitude: lat, longitude: lng } as any);
                  addToast({ type: 'success', message: 'Ubicación actualizada' });
                } catch {
                  addToast({ type: 'error', message: 'Error al actualizar la ubicación' });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        )}

        {/* Business Hours */}
        {loadingHours ? (
          <Skeleton className="h-64 w-full" />
        ) : (
          <HoursSection
            hours={hours ?? []}
            onSave={async (data) => {
              try {
                await updateHours.mutateAsync(data);
                addToast({ type: 'success', message: 'Horarios actualizados' });
              } catch {
                addToast({ type: 'error', message: 'Error al actualizar horarios' });
              }
            }}
            loading={updateHours.isPending}
          />
        )}

        {/* Scheduling configuration */}
        {loadingBusiness ? (
          <Skeleton className="h-48 w-full" />
        ) : (
          business && (
            <SchedulingSection
              business={business}
              onSave={async (data) => {
                try {
                  await updateBusiness.mutateAsync(data as unknown as Partial<typeof business>);
                  addToast({ type: 'success', message: 'Configuración de agenda actualizada' });
                } catch {
                  addToast({
                    type: 'error',
                    message: 'Error al actualizar la configuración de agenda',
                  });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        )}

        {/* Payment methods */}
        {loadingBusiness ? (
          <Skeleton className="h-48 w-full" />
        ) : (
          business && (
            <PaymentSection
              business={business}
              onSave={async (data) => {
                try {
                  await updateBusiness.mutateAsync(data);
                  addToast({ type: 'success', message: 'Métodos de pago actualizados' });
                } catch {
                  addToast({
                    type: 'error',
                    message: 'Error al actualizar métodos de pago',
                  });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        )}

        {/* Cancellation policy */}
        {loadingBusiness ? (
          <Skeleton className="h-48 w-full" />
        ) : (
          business && (
            <CancellationSection
              business={business}
              onSave={async (data) => {
                try {
                  await updateBusiness.mutateAsync(
                    data as unknown as Partial<typeof business>
                  );
                  addToast({ type: 'success', message: 'Política de cancelación actualizada' });
                } catch {
                  addToast({
                    type: 'error',
                    message: 'Error al actualizar la política',
                  });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        )}


        {/* Credits & Cashback toggle */}
        {loadingBusiness ? (
          <Skeleton className="h-32 w-full" />
        ) : (
          business && (
            <CreditsToggleSection
              enabled={business.credits_enabled !== false}
              onToggle={async (enabled) => {
                try {
                  await updateBusiness.mutateAsync({ credits_enabled: enabled } as any);
                  addToast({ type: 'success', message: enabled ? 'Créditos activados' : 'Créditos desactivados' });
                } catch {
                  addToast({ type: 'error', message: 'Error al actualizar la configuración de créditos' });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        )}

        {/* Notification preferences */}
        {loadingBusiness ? (
          <Skeleton className="h-48 w-full" />
        ) : (
          <NotificationSection />
        )}

        {/* Brand customization (colors) — Profesional+ only */}
        {loadingBusiness ? (
          <Skeleton className="h-48 w-full" />
        ) : canCustomizeBrand ? (
          business && (
            <ColorSection
              business={business}
              onSave={async (data) => {
                try {
                  await updateBusiness.mutateAsync(data);
                  addToast({ type: 'success', message: 'Colores actualizados' });
                } catch {
                  addToast({ type: 'error', message: 'Error al actualizar colores' });
                }
              }}
              loading={updateBusiness.isPending}
            />
          )
        ) : (
          <Card>
            <h2 className="mb-4 text-lg font-semibold text-gray-900">
              Personalización
            </h2>
            <UpgradeBanner
              feature="personalización de marca"
              message="Personaliza los colores de tu negocio"
            />
          </Card>
        )}
      </div>
    </div>
  );
}

// ============================================================
// Sub-components for each settings section
// ============================================================

function LogoSection({
  logoUrl,
  businessName,
  isIndependent,
  onUpload,
  loading,
}: {
  logoUrl: string | null;
  businessName: string;
  isIndependent: boolean;
  onUpload: (file: File) => Promise<void>;
  loading: boolean;
}) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      return;
    }

    // Validate file size
    if (file.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
      return;
    }

    onUpload(file);

    // Reset input so the same file can be re-selected
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  // Independent professional: circular profile photo layout
  if (isIndependent) {
    return (
      <Card>
        <h2 className="text-lg font-semibold text-gray-900">Foto de perfil</h2>
        <p className="mt-1 text-sm text-gray-500">Esta foto se muestra en tu página de reservas</p>
        <div className="mt-4 flex items-center gap-4">
          {/* Circular photo preview */}
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="group relative h-24 w-24 shrink-0 overflow-hidden rounded-full border-2 border-gray-200 hover:border-violet-400 transition-colors"
            disabled={loading}
          >
            {logoUrl ? (
              <img
                src={logoUrl}
                alt={businessName}
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-gray-100 text-gray-400 group-hover:text-violet-500">
                <Camera className="h-8 w-8" />
              </div>
            )}

            {/* Overlay on hover */}
            {!loading && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity rounded-full">
                <Camera className="h-5 w-5 text-white" />
              </div>
            )}

            {/* Loading spinner */}
            {loading && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-full">
                <Loader2 className="h-5 w-5 animate-spin text-white" />
              </div>
            )}
          </button>

          <div>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => fileInputRef.current?.click()}
              loading={loading}
            >
              Cambiar foto
            </Button>
            <p className="mt-1.5 text-xs text-gray-500">
              JPG, PNG o WebP. Máximo {MAX_FILE_SIZE_MB}MB.
            </p>
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="hidden"
          />
        </div>
      </Card>
    );
  }

  // Establishment: standard logo layout
  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">Logo</h2>
      <div className="flex items-center gap-6">
        {/* Logo preview */}
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          className="group relative h-20 w-20 shrink-0 overflow-hidden rounded-full border-2 border-dashed border-gray-300 hover:border-violet-400 transition-colors"
          disabled={loading}
        >
          {logoUrl ? (
            <img
              src={logoUrl}
              alt={businessName}
              className="h-full w-full object-cover"
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center bg-gray-50 text-gray-400 group-hover:text-violet-500">
              <Upload className="h-6 w-6" />
            </div>
          )}

          {/* Overlay on hover */}
          {!loading && (
            <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity rounded-full">
              <Upload className="h-5 w-5 text-white" />
            </div>
          )}

          {/* Loading spinner */}
          {loading && (
            <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-full">
              <Loader2 className="h-5 w-5 animate-spin text-white" />
            </div>
          )}
        </button>

        <div>
          <p className="text-sm font-medium text-gray-700">
            {logoUrl ? 'Cambiar logo' : 'Subir logo'}
          </p>
          <p className="mt-1 text-xs text-gray-500">
            JPG, PNG o WebP. Máximo {MAX_FILE_SIZE_MB}MB.
          </p>
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="mt-2"
            onClick={() => fileInputRef.current?.click()}
            loading={loading}
          >
            Seleccionar archivo
          </Button>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          className="hidden"
        />
      </div>
    </Card>
  );
}

function CoverSection({
  coverUrl,
  coverSource,
  businessType,
  onUpload,
  onSelectFromGallery,
  loading,
}: {
  coverUrl: string | null;
  coverSource: string | null;
  businessType: string;
  onUpload: (file: File) => Promise<void>;
  onSelectFromGallery: (url: string) => Promise<void>;
  loading: boolean;
}) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [activeTab, setActiveTab] = useState<'upload' | 'gallery'>('upload');
  const [searchQuery, setSearchQuery] = useState(businessType === 'barbershop' ? 'barbershop' : 'beauty salon');
  const { data: photos, isLoading: loadingPhotos } = useCoverGallery(
    activeTab === 'gallery' ? searchQuery : '',
  );

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !file.type.startsWith('image/')) return;
    if (file.size > MAX_FILE_SIZE_MB * 1024 * 1024) return;
    onUpload(file);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">Portada del negocio</h2>

      {/* Preview */}
      {coverUrl && (
        <div className="mb-4 overflow-hidden rounded-lg border border-gray-200">
          <img
            src={coverUrl}
            alt="Portada"
            className="h-32 w-full object-cover sm:h-40"
          />
          <p className="bg-gray-50 px-3 py-1.5 text-xs text-gray-500">
            {coverSource === 'pexels' ? 'Imagen de Pexels' : 'Imagen subida'}
          </p>
        </div>
      )}

      {/* Tabs */}
      <div className="mb-4 flex gap-2">
        <button
          type="button"
          onClick={() => setActiveTab('upload')}
          className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${
            activeTab === 'upload'
              ? 'bg-violet-100 text-violet-700'
              : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <Upload className="mr-1.5 inline h-4 w-4" />
          Subir imagen
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('gallery')}
          className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${
            activeTab === 'gallery'
              ? 'bg-violet-100 text-violet-700'
              : 'text-gray-600 hover:bg-gray-100'
          }`}
        >
          <Image className="mr-1.5 inline h-4 w-4" />
          Banco de imágenes
        </button>
      </div>

      {activeTab === 'upload' ? (
        <div>
          <p className="mb-3 text-sm text-gray-500">
            Dimensiones recomendadas: <strong>1200 x 400 px</strong> (ratio 3:1). Formatos: JPG, PNG, WebP.
          </p>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => fileInputRef.current?.click()}
            loading={loading}
          >
            Seleccionar archivo
          </Button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileChange}
            className="hidden"
          />
        </div>
      ) : (
        <div>
          {/* Search */}
          <div className="mb-3 flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Buscar imágenes..."
                className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
              />
            </div>
          </div>

          {/* Gallery grid */}
          {loadingPhotos ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-6 w-6 animate-spin text-violet-600" />
            </div>
          ) : photos && photos.length > 0 ? (
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {photos.map((photo) => (
                <button
                  key={photo.id}
                  type="button"
                  disabled={loading}
                  onClick={() => onSelectFromGallery(photo.url_large)}
                  className="group relative overflow-hidden rounded-lg border border-gray-200 transition-all hover:border-violet-400 hover:shadow-md"
                >
                  <img
                    src={photo.url_small}
                    alt={photo.alt || 'Pexels photo'}
                    className="h-24 w-full object-cover sm:h-28"
                  />
                  <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 transition-opacity group-hover:opacity-100">
                    <span className="rounded-full bg-white px-3 py-1 text-xs font-medium text-gray-900">
                      Seleccionar
                    </span>
                  </div>
                </button>
              ))}
            </div>
          ) : (
            <p className="py-4 text-center text-sm text-gray-500">
              No se encontraron imágenes. Intenta con otra búsqueda.
            </p>
          )}
          <p className="mt-2 text-xs text-gray-400">Imágenes proporcionadas por Pexels</p>
        </div>
      )}
    </Card>
  );
}

function ColorSection({
  business,
  onSave,
  loading,
}: {
  business: {
    primary_color: string;
    secondary_color: string;
  };
  onSave: (data: { primary_color: string; secondary_color: string }) => Promise<void>;
  loading: boolean;
}) {
  const [primaryColor, setPrimaryColor] = useState(business.primary_color || '#7C3AED');
  const [secondaryColor, setSecondaryColor] = useState(business.secondary_color || '#1A1A2E');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({ primary_color: primaryColor, secondary_color: secondaryColor });
  };

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">
        Personalización
      </h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">
              Color primario
            </label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={primaryColor}
                onChange={(e) => setPrimaryColor(e.target.value)}
                className="h-10 w-14 cursor-pointer rounded-lg border border-gray-300 p-1"
              />
              <input
                type="text"
                value={primaryColor}
                onChange={(e) => setPrimaryColor(e.target.value)}
                className="w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm uppercase focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                maxLength={7}
              />
            </div>
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-gray-700">
              Color secundario
            </label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={secondaryColor}
                onChange={(e) => setSecondaryColor(e.target.value)}
                className="h-10 w-14 cursor-pointer rounded-lg border border-gray-300 p-1"
              />
              <input
                type="text"
                value={secondaryColor}
                onChange={(e) => setSecondaryColor(e.target.value)}
                className="w-28 rounded-lg border border-gray-300 px-3 py-2 text-sm uppercase focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                maxLength={7}
              />
            </div>
          </div>
        </div>

        {/* Preview */}
        <div className="flex items-center gap-3">
          <span className="text-sm text-gray-500">Vista previa:</span>
          <div
            className="h-8 w-8 rounded-full border border-gray-200"
            style={{ backgroundColor: primaryColor }}
            title="Primario"
          />
          <div
            className="h-8 w-8 rounded-full border border-gray-200"
            style={{ backgroundColor: secondaryColor }}
            title="Secundario"
          />
        </div>

        <div className="flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar colores
          </Button>
        </div>
      </form>
    </Card>
  );
}

function ProfileSection({
  business,
  onSave,
  onSaveCoords,
  loading,
}: {
  business: {
    name: string;
    description: string | null;
    phone: string | null;
    address: string | null;
    city?: string | null;
    state?: string | null;
    country?: string | null;
    latitude?: number | null;
    longitude?: number | null;
    instagram_url?: string | null;
    facebook_url?: string | null;
    website_url?: string | null;
    google_maps_url?: string | null;
    independent?: boolean;
    nit?: string | null;
    legal_representative_name?: string | null;
    legal_representative_document?: string | null;
    legal_representative_document_type?: string | null;
  };
  onSave: (data: ProfileFormData) => Promise<void>;
  onSaveCoords: (lat: number, lng: number) => Promise<void>;
  loading: boolean;
}) {
  const isIndependent = !!business.independent;
  const [showLocationPicker, setShowLocationPicker] = useState(false);
  const [pickedCoords, setPickedCoords] = useState<{ lat: number; lng: number } | null>(
    business.latitude && business.longitude
      ? { lat: Number(business.latitude), lng: Number(business.longitude) }
      : null
  );

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<ProfileFormData>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      name: business.name,
      description: business.description ?? '',
      phone: business.phone ?? '',
      address: business.address ?? '',
      city: business.city ?? '',
      state: business.state ?? '',
      country: business.country ?? 'CO',
      instagram_url: business.instagram_url ?? '',
      facebook_url: business.facebook_url ?? '',
      website_url: business.website_url ?? '',
      google_maps_url: business.google_maps_url ?? '',
      nit: business.nit ?? '',
      legal_representative_name: business.legal_representative_name ?? '',
      legal_representative_document: business.legal_representative_document ?? '',
      legal_representative_document_type: business.legal_representative_document_type ?? '',
    },
  });

  const currentAddress = watch('address');

  // Location cascading selects (values are codes: "CO", "ATL", city is name)
  const watchedCountry = watch('country');
  const watchedState = watch('state');
  const { data: countriesData } = useCountries();
  const { data: statesData } = useStates(watchedCountry ?? '');
  const { data: citiesData } = useCities(watchedCountry ?? '', watchedState ?? '');

  const handleSaveWithCoords = async (data: ProfileFormData) => {
    // Include picked coordinates if available
    const payload: Record<string, unknown> = { ...data };
    if (pickedCoords) {
      payload.latitude = pickedCoords.lat;
      payload.longitude = pickedCoords.lng;
    }
    await onSave(payload as ProfileFormData);
  };

  const currentCity = watch('city');
  const currentCountry = watch('country');

  // Build full address for map — uses live form values
  const mapAddress = [currentAddress, currentCity, currentCountry]
    .filter(Boolean)
    .join(', ');

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">
        {isIndependent ? 'Tu perfil profesional' : 'Perfil del negocio'}
      </h2>
      <form onSubmit={handleSubmit(handleSaveWithCoords)} className="space-y-4">
        <Input
          label={isIndependent ? 'Tu nombre' : 'Nombre del negocio'}
          error={errors.name?.message}
          {...register('name')}
        />
        <Textarea
          label="Descripción"
          rows={3}
          error={errors.description?.message}
          {...register('description')}
        />
        <div className={`grid grid-cols-1 gap-4 ${isIndependent ? '' : 'sm:grid-cols-2'}`}>
          <Input
            label="Teléfono"
            error={errors.phone?.message}
            {...register('phone')}
          />
          {!isIndependent && (
            <Input
              label="Dirección"
              placeholder="Calle 84 #53-120"
              error={errors.address?.message}
              {...register('address')}
            />
          )}
        </div>
        {!isIndependent && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <Select
            key={`country-${countriesData?.data?.length ?? 0}`}
            label="País"
            options={[
              { value: '', label: 'Seleccionar país...' },
              ...(countriesData?.data?.map((c) => ({
                value: c.code!,
                label: c.name,
              })) ?? []),
            ]}
            error={errors.country?.message}
            {...register('country', {
              onChange: () => {
                setValue('state', '');
                setValue('city', '');
              },
            })}
          />
          <Select
            key={`state-${statesData?.data?.length ?? 0}`}
            label="Departamento / Estado"
            options={[
              { value: '', label: 'Seleccionar...' },
              ...(statesData?.data?.map((s) => ({
                value: s.code!,
                label: s.name,
              })) ?? []),
            ]}
            error={errors.state?.message}
            {...register('state', {
              onChange: () => {
                setValue('city', '');
              },
            })}
          />
          <Select
            key={`city-${citiesData?.data?.length ?? 0}`}
            label="Ciudad"
            options={[
              { value: '', label: 'Seleccionar ciudad...' },
              ...(citiesData?.data?.map((c) => ({
                value: c.name,
                label: c.name,
              })) ?? []),
            ]}
            error={errors.city?.message}
            {...register('city')}
          />
        </div>
        )}

        {!isIndependent && (
        <>
        {/* Location picker */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-700">
              <MapPin className="mr-1 inline h-4 w-4 text-violet-600" />
              Ubicación en el mapa
            </p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setShowLocationPicker(true)}
            >
              {pickedCoords ? 'Cambiar ubicación' : 'Seleccionar ubicación'}
            </Button>
          </div>

          {/* Map preview */}
          {(pickedCoords || currentAddress) && (
            <div
              className="cursor-pointer rounded-xl overflow-hidden border border-gray-200 hover:border-violet-300 transition-colors"
              onClick={() => setShowLocationPicker(true)}
            >
              <MapEmbed
                address={mapAddress}
                latitude={pickedCoords?.lat ?? business.latitude}
                longitude={pickedCoords?.lng ?? business.longitude}
                height={200}
                zoom={16}
              />
            </div>
          )}

          {pickedCoords && (
            <p className="text-xs text-gray-400">
              Coordenadas: {Number(pickedCoords.lat).toFixed(6)}, {Number(pickedCoords.lng).toFixed(6)}
            </p>
          )}

          {!pickedCoords && (
            <p className="text-xs text-amber-600">
              Selecciona la ubicación exacta para que tus clientes puedan usar &quot;Cómo llegar&quot;.
            </p>
          )}
        </div>

        {/* Location Picker Modal */}
        <LocationPicker
          open={showLocationPicker}
          onClose={() => setShowLocationPicker(false)}
          onConfirm={async (lat, lng) => {
            setPickedCoords({ lat, lng });
            await onSaveCoords(lat, lng);
          }}
          initialLat={pickedCoords?.lat ?? Number(business.latitude)}
          initialLng={pickedCoords?.lng ?? Number(business.longitude)}
          businessAddress={mapAddress}
        />

        {/* Google Maps URL (optional, for "Cómo llegar" link) */}
        <Input
          label="Link de Google Maps (opcional)"
          placeholder="https://maps.app.goo.gl/..."
          {...register('google_maps_url')}
        />
        </>
        )}

        {/* Legal / identity info */}
        {isIndependent ? (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Select
              label="Tipo de documento"
              options={[
                { value: '', label: 'Seleccionar...' },
                { value: 'CC', label: 'Cédula de ciudadanía' },
                { value: 'CE', label: 'Cédula de extranjería' },
                { value: 'passport', label: 'Pasaporte' },
              ]}
              {...register('legal_representative_document_type')}
            />
            <Input
              label="Número de documento"
              placeholder="1.234.567.890"
              {...register('legal_representative_document')}
            />
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Input
                label="NIT"
                placeholder="900.123.456-7"
                {...register('nit')}
              />
              <Input
                label="Representante legal"
                placeholder="Nombre completo"
                {...register('legal_representative_name')}
              />
            </div>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Select
                label="Tipo de documento"
                options={[
                  { value: '', label: 'Seleccionar...' },
                  { value: 'CC', label: 'Cédula de ciudadanía' },
                  { value: 'CE', label: 'Cédula de extranjería' },
                  { value: 'passport', label: 'Pasaporte' },
                ]}
                {...register('legal_representative_document_type')}
              />
              <Input
                label="Número de documento"
                placeholder="1.234.567.890"
                {...register('legal_representative_document')}
              />
            </div>
          </>
        )}

        {/* Social links */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            label="Instagram (URL)"
            placeholder="https://instagram.com/tu-negocio"
            {...register('instagram_url')}
          />
          <Input
            label="Sitio web"
            placeholder="https://tu-sitio.com"
            {...register('website_url')}
          />
        </div>

        <div className="flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar
          </Button>
        </div>
      </form>
    </Card>
  );
}

function HoursSection({
  hours,
  onSave,
  loading,
}: {
  hours: BusinessHour[];
  onSave: (
    data: { day_of_week: number; open_time: string; close_time: string; closed: boolean }[]
  ) => Promise<void>;
  loading: boolean;
}) {
  // Build local state from existing hours
  const defaultRows = DAYS_OF_WEEK.map((day) => {
    const existing = hours.find((h) => h.day_of_week === day.value);
    return {
      day_of_week: day.value,
      label: day.label,
      open_time: existing?.open_time ?? '08:00',
      close_time: existing?.close_time ?? '18:00',
      closed: existing?.closed ?? day.value === 0,
    };
  });

  const {
    register,
    handleSubmit,
    watch,
  } = useForm({
    defaultValues: { rows: defaultRows },
  });

  const rows = watch('rows');

  const handleSave = (data: { rows: typeof defaultRows }) => {
    onSave(
      data.rows.map(({ label, ...rest }) => rest)
    );
  };

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">Horarios</h2>
      <form onSubmit={handleSubmit(handleSave)}>
        <div className="space-y-3">
          {rows.map((row, idx) => (
            <div
              key={row.day_of_week}
              className="flex flex-wrap items-center gap-3 rounded-lg border border-gray-100 p-3"
            >
              <div className="w-24">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    {...register(`rows.${idx}.closed`)}
                    className="h-4 w-4 rounded border-gray-300 text-violet-600 focus:ring-violet-600"
                  />
                  <span className="text-sm font-medium text-gray-700">
                    {row.label}
                  </span>
                </label>
              </div>
              {!rows[idx].closed ? (
                <div className="flex items-center gap-2">
                  <select
                    {...register(`rows.${idx}.open_time`)}
                    className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                  >
                    {timeOptions.map((t) => (
                      <option key={t.value} value={t.value}>
                        {t.label}
                      </option>
                    ))}
                  </select>
                  <span className="text-sm text-gray-500">a</span>
                  <select
                    {...register(`rows.${idx}.close_time`)}
                    className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                  >
                    {timeOptions.map((t) => (
                      <option key={t.value} value={t.value}>
                        {t.label}
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <span className="text-sm text-gray-400">Cerrado</span>
              )}
            </div>
          ))}
        </div>
        <div className="mt-4 flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar horarios
          </Button>
        </div>
      </form>
    </Card>
  );
}

function PaymentSection({
  business,
  onSave,
  loading,
}: {
  business: {
    nequi_phone: string | null;
    daviplata_phone: string | null;
    bancolombia_account: string | null;
    breb_key: string | null;
  };
  onSave: (data: PaymentFormData) => Promise<void>;
  loading: boolean;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<PaymentFormData>({
    resolver: zodResolver(paymentSchema),
    defaultValues: {
      nequi_phone: business.nequi_phone ?? '',
      daviplata_phone: business.daviplata_phone ?? '',
      bancolombia_account: business.bancolombia_account ?? '',
      breb_key: business.breb_key ?? '',
    },
  });

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">Métodos de pago</h2>
      <form onSubmit={handleSubmit(onSave)} className="space-y-4">
        <Input
          label="Nequi (teléfono)"
          placeholder="300 123 4567"
          error={errors.nequi_phone?.message}
          {...register('nequi_phone')}
        />
        <Input
          label="Daviplata (teléfono)"
          placeholder="300 123 4567"
          error={errors.daviplata_phone?.message}
          {...register('daviplata_phone')}
        />
        <Input
          label="Cuenta Bancolombia"
          placeholder="Número de cuenta"
          error={errors.bancolombia_account?.message}
          {...register('bancolombia_account')}
        />
        <Input
          label="Llave Bre-B"
          placeholder="Ej: ABC123DEF456"
          error={errors.breb_key?.message}
          {...register('breb_key')}
        />
        <div className="flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar
          </Button>
        </div>
      </form>
    </Card>
  );
}

function CreditsToggleSection({
  enabled,
  onToggle,
  loading,
}: {
  enabled: boolean;
  onToggle: (enabled: boolean) => Promise<void>;
  loading: boolean;
}) {
  return (
    <Card>
      <h2 className="text-lg font-semibold text-gray-900">Créditos y Cashback</h2>
      <p className="mt-1 text-sm text-gray-500">
        Controla si tus clientes pueden acumular y usar créditos en tu negocio
      </p>

      <div className="mt-4 flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-700">
            {enabled ? 'Activado' : 'Desactivado'}
          </p>
          {!enabled && (
            <p className="mt-1 text-xs text-amber-600">
              Al desactivar, tus clientes no podrán usar créditos ni acumular cashback
            </p>
          )}
        </div>
        <label className="relative inline-flex cursor-pointer items-center">
          <input
            type="checkbox"
            className="peer sr-only"
            checked={enabled}
            disabled={loading}
            onChange={() => onToggle(!enabled)}
          />
          <div className="peer h-6 w-11 rounded-full bg-gray-200 peer-checked:bg-violet-600 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-violet-300 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:shadow after:transition-all after:content-[''] peer-checked:after:translate-x-full" />
        </label>
      </div>
    </Card>
  );
}

function NotificationSection() {
  const { notificationSoundEnabled, toggleNotificationSound } = useUIStore();
  // Initialize as 'default' to avoid hydration mismatch (server has no Notification API)
  const [permissionState, setPermissionState] = useState<NotificationPermission | 'unsupported'>('default');

  // Sync actual permission state after mount (client-only)
  useEffect(() => {
    if (typeof window === 'undefined' || !('Notification' in window)) {
      setPermissionState('unsupported');
    } else {
      setPermissionState(Notification.permission);
    }
  }, []);

  const handleRequestPermission = useCallback(async () => {
    if (!('Notification' in window)) return;
    const result = await Notification.requestPermission();
    setPermissionState(result);
  }, []);

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">
        <Bell className="mr-2 inline h-5 w-5 text-violet-600" />
        Notificaciones
      </h2>

      <div className="space-y-4">
        {/* Browser notification permission */}
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-700">
              Notificaciones del navegador
            </p>
            <p className="text-xs text-gray-500">
              Recibe alertas cuando llegan reservas, pagos y más
            </p>
          </div>
          {permissionState === 'granted' ? (
            <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
              Activadas
            </span>
          ) : permissionState === 'denied' ? (
            <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700">
              Bloqueadas
            </span>
          ) : permissionState === 'unsupported' ? (
            <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-500">
              No disponible
            </span>
          ) : (
            <Button variant="outline" size="sm" onClick={handleRequestPermission}>
              Activar
            </Button>
          )}
        </div>

        {permissionState === 'denied' && (
          <p className="text-xs text-amber-600">
            Las notificaciones están bloqueadas. Actívalas en la configuración de tu navegador.
          </p>
        )}

        {/* Sound toggle */}
        <div className="flex items-center justify-between border-t border-gray-100 pt-4">
          <div>
            <p className="text-sm font-medium text-gray-700">
              Sonido de notificaciones
            </p>
            <p className="text-xs text-gray-500">
              Reproduce un sonido cuando llega una nueva reserva o pago
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={notificationSoundEnabled}
            onClick={toggleNotificationSound}
            className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
              notificationSoundEnabled ? 'bg-violet-600' : 'bg-gray-300'
            }`}
          >
            <span
              className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform ${
                notificationSoundEnabled ? 'translate-x-6' : 'translate-x-1'
              }`}
            />
          </button>
        </div>

        <div className="flex items-center gap-2 text-xs text-gray-400">
          {notificationSoundEnabled ? (
            <>
              <Volume2 className="h-3.5 w-3.5" />
              Sonido activado
            </>
          ) : (
            <>
              <VolumeX className="h-3.5 w-3.5" />
              Sonido desactivado
            </>
          )}
        </div>
      </div>
    </Card>
  );
}

// --- Scheduling time options (every 30 min from 06:00 to 20:00) ---
const lunchTimeOptions = Array.from({ length: 29 }, (_, i) => {
  const hour = Math.floor(i / 2) + 6;
  const min = i % 2 === 0 ? '00' : '30';
  const value = `${String(hour).padStart(2, '0')}:${min}`;
  return { value, label: value };
});

function SchedulingSection({
  business,
  onSave,
  loading,
}: {
  business: {
    lunch_enabled: boolean;
    lunch_start_time: string;
    lunch_end_time: string;
    slot_interval_minutes: number;
    gap_between_appointments_minutes: number;
  };
  onSave: (data: {
    lunch_enabled: boolean;
    lunch_start_time: string;
    lunch_end_time: string;
    slot_interval_minutes: number;
    gap_between_appointments_minutes: number;
  }) => Promise<void>;
  loading: boolean;
}) {
  const [lunchEnabled, setLunchEnabled] = useState(business.lunch_enabled ?? true);
  const [lunchStart, setLunchStart] = useState(business.lunch_start_time || '12:00');
  const [lunchEnd, setLunchEnd] = useState(business.lunch_end_time || '13:00');
  const [slotInterval, setSlotInterval] = useState(String(business.slot_interval_minutes || 30));
  const [gap, setGap] = useState(String(business.gap_between_appointments_minutes || 0));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      lunch_enabled: lunchEnabled,
      lunch_start_time: lunchStart,
      lunch_end_time: lunchEnd,
      slot_interval_minutes: Number(slotInterval),
      gap_between_appointments_minutes: Number(gap),
    });
  };

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">
        <Clock className="mr-2 inline h-5 w-5 text-violet-600" />
        Configuraci&oacute;n de agenda
      </h2>
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Lunch break */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-700">
                <Coffee className="mr-1 inline h-4 w-4 text-violet-600" />
                Hora de almuerzo
              </p>
              <p className="text-xs text-gray-500">
                Aplica a todos los empleados todos los d&iacute;as
              </p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={lunchEnabled}
              onClick={() => setLunchEnabled(!lunchEnabled)}
              className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                lunchEnabled ? 'bg-violet-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform ${
                  lunchEnabled ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          {lunchEnabled && (
            <div className="flex items-center gap-2 pl-1">
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Inicio</label>
                <select
                  value={lunchStart}
                  onChange={(e) => setLunchStart(e.target.value)}
                  className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                >
                  {lunchTimeOptions.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </select>
              </div>
              <span className="mt-5 text-sm text-gray-500">a</span>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Fin</label>
                <select
                  value={lunchEnd}
                  onChange={(e) => setLunchEnd(e.target.value)}
                  className="rounded-lg border border-gray-300 bg-white px-2 py-1.5 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
                >
                  {lunchTimeOptions.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          )}
        </div>

        {/* Slot interval */}
        <div className="space-y-1">
          <label className="text-sm font-medium text-gray-700">
            <Timer className="mr-1 inline h-4 w-4 text-violet-600" />
            Mostrar horarios cada:
          </label>
          <select
            value={slotInterval}
            onChange={(e) => setSlotInterval(e.target.value)}
            className="block w-full max-w-xs rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
          >
            <option value="15">15 minutos</option>
            <option value="20">20 minutos</option>
            <option value="30">30 minutos</option>
            <option value="45">45 minutos</option>
            <option value="60">60 minutos</option>
          </select>
          <p className="text-xs text-gray-500">
            Determina cada cu&aacute;ntos minutos se muestran opciones de horario al reservar
          </p>
        </div>

        {/* Gap between appointments */}
        <div className="space-y-1">
          <label className="text-sm font-medium text-gray-700">
            Tiempo entre citas:
          </label>
          <select
            value={gap}
            onChange={(e) => setGap(e.target.value)}
            className="block w-full max-w-xs rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20"
          >
            <option value="0">0 min (sin descanso)</option>
            <option value="5">5 minutos</option>
            <option value="10">10 minutos</option>
            <option value="15">15 minutos</option>
          </select>
          <p className="text-xs text-gray-500">
            Tiempo de preparaci&oacute;n entre una cita y la siguiente
          </p>
        </div>

        <div className="flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar configuraci&oacute;n
          </Button>
        </div>
      </form>
    </Card>
  );
}

function CancellationSection({
  business,
  onSave,
  loading,
}: {
  business: { cancellation_policy_pct: number; cancellation_deadline_hours: number };
  onSave: (data: CancellationFormData) => Promise<void>;
  loading: boolean;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<CancellationFormData>({
    resolver: zodResolver(cancellationSchema),
    defaultValues: {
      cancellation_policy_pct: String(business.cancellation_policy_pct ?? 0),
      cancellation_deadline_hours: business.cancellation_deadline_hours ?? 24,
    },
  });

  return (
    <Card>
      <h2 className="mb-4 text-lg font-semibold text-gray-900">
        Política de cancelación
      </h2>
      <form onSubmit={handleSubmit(onSave)} className="space-y-4">
        <Select
          label="Porcentaje de penalización"
          options={[
            { value: '0', label: 'Sin penalización (0%)' },
            { value: '30', label: '30%' },
            { value: '50', label: '50%' },
            { value: '100', label: '100%' },
          ]}
          error={errors.cancellation_policy_pct?.message}
          {...register('cancellation_policy_pct')}
        />
        <Input
          label="Plazo mínimo para cancelar (horas)"
          type="number"
          min={1}
          max={72}
          error={errors.cancellation_deadline_hours?.message}
          {...register('cancellation_deadline_hours', { valueAsNumber: true })}
        />
        <div className="flex justify-end">
          <Button type="submit" loading={loading}>
            Guardar
          </Button>
        </div>
      </form>
    </Card>
  );
}
