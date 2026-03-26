'use client';

import { useState } from 'react';
import { Scissors, Plus, Clock, X, Pencil, Tag } from 'lucide-react';
import { Button, Card, Badge, Modal, Skeleton, EmptyState } from '@/components/ui';
import { ServiceForm } from '@/components/forms/service-form';
import {
  useServices,
  useCreateService,
  useUpdateService,
  useDeleteService,
  useServiceCategories,
  useRenameCategory,
  useDeleteCategory,
} from '@/lib/hooks/use-services';
import { useUIStore } from '@/lib/stores/ui-store';
import { formatCurrency } from '@/lib/utils/format';
import type { Service } from '@/lib/api/types';

export default function ServicesPage() {
  const { data: services, isLoading } = useServices();
  const { data: categories = [] } = useServiceCategories();
  const createService = useCreateService();
  const updateService = useUpdateService();
  const deleteService = useDeleteService();
  const renameCategory = useRenameCategory();
  const deleteCategory = useDeleteCategory();
  const { addToast } = useUIStore();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingService, setEditingService] = useState<Service | null>(null);
  const [renamingCategory, setRenamingCategory] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState('');
  const [showCategories, setShowCategories] = useState(true);

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
    category?: string;
  }) => {
    try {
      const payload = {
        ...data,
        category: data.category?.trim() || null,
      };
      if (editingService) {
        await updateService.mutateAsync({ id: editingService.id, data: payload });
        addToast({ type: 'success', message: 'Servicio actualizado' });
      } else {
        await createService.mutateAsync(payload);
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

  const handleRenameCategory = async (oldName: string) => {
    const newName = renameValue.trim();
    if (!newName || newName === oldName) {
      setRenamingCategory(null);
      return;
    }
    try {
      await renameCategory.mutateAsync({ oldName, newName });
      addToast({ type: 'success', message: `Categoría renombrada a "${newName}"` });
      setRenamingCategory(null);
    } catch {
      addToast({ type: 'error', message: 'Error al renombrar la categoría' });
    }
  };

  const handleDeleteCategory = async (name: string) => {
    try {
      await deleteCategory.mutateAsync(name);
      addToast({ type: 'success', message: `Categoría "${name}" eliminada` });
    } catch {
      addToast({ type: 'error', message: 'Error al eliminar la categoría' });
    }
  };

  const getCategoryCount = (cat: string) =>
    services?.filter((s) => s.category === cat).length ?? 0;

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

      {/* Category management chips */}
      {categories.length > 0 && (
        <div className="mb-6">
          <button
            type="button"
            onClick={() => setShowCategories(!showCategories)}
            className="mb-3 flex items-center gap-2 text-sm font-medium text-gray-700 hover:text-gray-900 transition-colors"
          >
            <Tag className="h-4 w-4" />
            Categorías ({categories.length})
          </button>

          {showCategories && (
            <div className="flex flex-wrap gap-2">
              {categories.map((cat) => (
                <div
                  key={cat}
                  className="group flex items-center gap-1.5 rounded-full border border-gray-200 bg-gray-50 px-3 py-1.5 text-sm text-gray-700"
                >
                  {renamingCategory === cat ? (
                    <input
                      type="text"
                      value={renameValue}
                      onChange={(e) => setRenameValue(e.target.value)}
                      onBlur={() => handleRenameCategory(cat)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') handleRenameCategory(cat);
                        if (e.key === 'Escape') setRenamingCategory(null);
                      }}
                      className="w-24 rounded border border-violet-300 bg-white px-2 py-0.5 text-sm focus:outline-none focus:ring-1 focus:ring-violet-500"
                      autoFocus
                    />
                  ) : (
                    <>
                      <span>{cat}</span>
                      <span className="text-xs text-gray-400">
                        ({getCategoryCount(cat)})
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          setRenamingCategory(cat);
                          setRenameValue(cat);
                        }}
                        className="ml-1 rounded p-0.5 text-gray-400 opacity-0 transition-opacity hover:text-violet-600 group-hover:opacity-100"
                        title="Renombrar categoría"
                      >
                        <Pencil className="h-3 w-3" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteCategory(cat)}
                        className="rounded p-0.5 text-gray-400 opacity-0 transition-opacity hover:text-red-600 group-hover:opacity-100"
                        title="Eliminar categoría"
                      >
                        <X className="h-3 w-3" />
                      </button>
                    </>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

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
                <div className="flex flex-col items-end gap-1">
                  <Badge variant={service.active ? 'success' : 'default'}>
                    {service.active ? 'Activo' : 'Inactivo'}
                  </Badge>
                  {service.category && (
                    <span className="rounded-full bg-violet-50 px-2 py-0.5 text-xs font-medium text-violet-700">
                      {service.category}
                    </span>
                  )}
                </div>
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
