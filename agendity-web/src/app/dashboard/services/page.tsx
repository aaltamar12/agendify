'use client';

import { useState } from 'react';
import { Scissors, Plus, Clock } from 'lucide-react';
import { Button, Card, Badge, Modal, Skeleton, EmptyState } from '@/components/ui';
import { ServiceForm } from '@/components/forms/service-form';
import {
  useServices,
  useCreateService,
  useUpdateService,
  useDeleteService,
} from '@/lib/hooks/use-services';
import { useUIStore } from '@/lib/stores/ui-store';
import { formatCurrency } from '@/lib/utils/format';
import type { Service } from '@/lib/api/types';

export default function ServicesPage() {
  const { data: services, isLoading } = useServices();
  const createService = useCreateService();
  const updateService = useUpdateService();
  const deleteService = useDeleteService();
  const { addToast } = useUIStore();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingService, setEditingService] = useState<Service | null>(null);

  const openCreate = () => {
    setEditingService(null);
    setModalOpen(true);
  };

  const openEdit = (service: Service) => {
    setEditingService(service);
    setModalOpen(true);
  };

  const handleSubmit = async (data: {
    name: string;
    description?: string;
    price: number;
    duration_minutes: number;
    active: boolean;
  }) => {
    try {
      if (editingService) {
        await updateService.mutateAsync({ id: editingService.id, data });
        addToast({ type: 'success', message: 'Servicio actualizado' });
      } else {
        await createService.mutateAsync(data);
        addToast({ type: 'success', message: 'Servicio creado' });
      }
      setModalOpen(false);
    } catch {
      addToast({ type: 'error', message: 'Error al guardar el servicio' });
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteService.mutateAsync(id);
      addToast({ type: 'success', message: 'Servicio eliminado' });
      setModalOpen(false);
    } catch {
      addToast({ type: 'error', message: 'Error al eliminar el servicio' });
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Servicios</h1>
        <Button onClick={openCreate}>
          <Plus className="h-4 w-4" />
          Nuevo servicio
        </Button>
      </div>

      {/* Loading state */}
      {isLoading && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-36 w-full" />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!services || services.length === 0) && (
        <EmptyState
          icon={Scissors}
          title="No hay servicios"
          description="Crea tu primer servicio para que tus clientes puedan reservar citas."
          action={
            <Button onClick={openCreate}>
              <Plus className="h-4 w-4" />
              Crear servicio
            </Button>
          }
        />
      )}

      {/* Service cards */}
      {!isLoading && services && services.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {services.map((service) => (
            <Card
              key={service.id}
              className="cursor-pointer transition-shadow hover:shadow-md"
              onClick={() => openEdit(service)}
            >
              <div className="flex items-start justify-between">
                <div className="min-w-0 flex-1">
                  <h3 className="truncate text-base font-semibold text-gray-900">
                    {service.name}
                  </h3>
                  {service.description && (
                    <p className="mt-1 line-clamp-2 text-sm text-gray-500">
                      {service.description}
                    </p>
                  )}
                </div>
                <Badge variant={service.active ? 'success' : 'default'}>
                  {service.active ? 'Activo' : 'Inactivo'}
                </Badge>
              </div>
              <div className="mt-4 flex items-center gap-4 text-sm text-gray-600">
                <span className="font-semibold text-gray-900">
                  {formatCurrency(service.price)}
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="h-3.5 w-3.5" />
                  {service.duration_minutes} min
                </span>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingService ? 'Editar servicio' : 'Nuevo servicio'}
        size="md"
      >
        <ServiceForm
          service={editingService}
          onSubmit={handleSubmit}
          loading={createService.isPending || updateService.isPending}
        />
        {editingService && (
          <div className="mt-4 border-t border-gray-200 pt-4">
            <Button
              variant="destructive"
              size="sm"
              loading={deleteService.isPending}
              onClick={() => handleDelete(editingService.id)}
            >
              Eliminar servicio
            </Button>
          </div>
        )}
      </Modal>
    </div>
  );
}
