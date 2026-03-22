'use client';

import { useState } from 'react';
import { Users, Plus, Phone, Mail, CheckCircle, Link2, Send } from 'lucide-react';
import {
  Button,
  Card,
  Badge,
  Avatar,
  Modal,
  Skeleton,
  EmptyState,
} from '@/components/ui';
import { EmployeeForm } from '@/components/forms/employee-form';
import {
  useEmployees,
  useCreateEmployee,
  useUpdateEmployee,
  useDeleteEmployee,
  useInviteEmployee,
} from '@/lib/hooks/use-employees';
import { useUIStore } from '@/lib/stores/ui-store';
import { formatPhone } from '@/lib/utils/format';
import type { Employee, EmployeeSchedule } from '@/lib/api/types';
import type { ScheduleEntry } from '@/lib/hooks/use-employees';

export default function EmployeesPage() {
  const { data: employees, isLoading } = useEmployees();
  const createEmployee = useCreateEmployee();
  const updateEmployee = useUpdateEmployee();
  const deleteEmployee = useDeleteEmployee();
  const inviteEmployee = useInviteEmployee();
  const { addToast } = useUIStore();

  const [modalOpen, setModalOpen] = useState(false);
  const [inviteMenuOpen, setInviteMenuOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<
    (Employee & { service_ids?: number[]; schedules?: EmployeeSchedule[] }) | null
  >(null);

  const openCreate = () => {
    setEditingEmployee(null);
    setModalOpen(true);
  };

  const openEdit = (employee: Employee) => {
    setEditingEmployee(employee);
    setModalOpen(true);
  };

  const handleSubmit = async (data: {
    name: string;
    phone?: string;
    email?: string;
    active: boolean;
    service_ids: number[];
    schedules: ScheduleEntry[];
  }) => {
    try {
      if (editingEmployee) {
        await updateEmployee.mutateAsync({ id: editingEmployee.id, data });
        addToast({ type: 'success', message: 'Empleado actualizado' });
      } else {
        await createEmployee.mutateAsync(data);
        addToast({ type: 'success', message: 'Empleado creado' });
      }
      setModalOpen(false);
    } catch {
      addToast({ type: 'error', message: 'Error al guardar el empleado' });
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteEmployee.mutateAsync(id);
      addToast({ type: 'success', message: 'Empleado eliminado' });
      setModalOpen(false);
    } catch {
      addToast({ type: 'error', message: 'Error al eliminar el empleado' });
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Empleados</h1>
        <Button onClick={openCreate}>
          <Plus className="h-4 w-4" />
          Nuevo empleado
        </Button>
      </div>

      {/* Loading state */}
      {isLoading && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-32 w-full" />
          ))}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && (!employees || employees.length === 0) && (
        <EmptyState
          icon={Users}
          title="No hay empleados"
          description="Agrega empleados para asignarles servicios y gestionar sus horarios."
          action={
            <Button onClick={openCreate}>
              <Plus className="h-4 w-4" />
              Agregar empleado
            </Button>
          }
        />
      )}

      {/* Employee cards */}
      {!isLoading && employees && employees.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {employees.map((employee) => (
            <Card
              key={employee.id}
              className="cursor-pointer transition-shadow hover:shadow-md"
              onClick={() => openEdit(employee)}
            >
              <div className="flex items-start gap-3">
                <Avatar
                  name={employee.name}
                  src={employee.avatar_url}
                  size="lg"
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <h3 className="truncate text-base font-semibold text-gray-900">
                      {employee.name}
                    </h3>
                    <Badge variant={employee.active ? 'success' : 'default'}>
                      {employee.active ? 'Activo' : 'Inactivo'}
                    </Badge>
                  </div>
                  {employee.phone && (
                    <p className="mt-1 flex items-center gap-1 text-sm text-gray-500">
                      <Phone className="h-3.5 w-3.5" />
                      {formatPhone(employee.phone)}
                    </p>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingEmployee ? 'Editar empleado' : 'Nuevo empleado'}
        size="lg"
      >
        <EmployeeForm
          employee={editingEmployee}
          onSubmit={handleSubmit}
          loading={createEmployee.isPending || updateEmployee.isPending}
        />
        {editingEmployee && (
          <div className="mt-4 flex items-center justify-between border-t border-gray-200 pt-4">
            <Button
              variant="destructive"
              size="sm"
              loading={deleteEmployee.isPending}
              onClick={() => handleDelete(editingEmployee.id)}
            >
              Eliminar empleado
            </Button>
            {editingEmployee.has_account ? (
              <span className="flex items-center gap-1 text-xs font-medium text-green-600">
                <CheckCircle className="h-3.5 w-3.5" />
                Cuenta vinculada
              </span>
            ) : (
              <div className="relative">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setInviteMenuOpen(!inviteMenuOpen)}
                >
                  <Mail className="mr-1.5 h-3.5 w-3.5" />
                  Invitar a Agendity
                </Button>

                {inviteMenuOpen && (
                  <>
                    <div className="fixed inset-0 z-10" onClick={() => setInviteMenuOpen(false)} />
                    <div className="absolute bottom-full right-0 z-20 mb-2 w-56 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-lg">
                      <button
                        type="button"
                        className="flex w-full cursor-pointer items-center gap-3 px-4 py-3 text-left text-sm hover:bg-gray-50"
                        onClick={async () => {
                          const email = editingEmployee.email || prompt('Email del empleado:');
                          if (!email) return;
                          setInviteMenuOpen(false);
                          try {
                            await inviteEmployee.mutateAsync({ id: editingEmployee.id, email });
                            addToast({ type: 'success', message: 'Invitacion enviada por email' });
                          } catch {
                            addToast({ type: 'error', message: 'Error al enviar invitacion' });
                          }
                        }}
                      >
                        <Send className="h-4 w-4 text-violet-600" />
                        <div>
                          <p className="font-medium text-gray-900">Enviar por email</p>
                          <p className="text-xs text-gray-500">Se envia un correo con el link</p>
                        </div>
                      </button>
                      <button
                        type="button"
                        className="flex w-full cursor-pointer items-center gap-3 border-t border-gray-100 px-4 py-3 text-left text-sm hover:bg-gray-50"
                        onClick={async () => {
                          const email = editingEmployee.email || prompt('Email del empleado:');
                          if (!email) return;
                          setInviteMenuOpen(false);
                          try {
                            const result = await inviteEmployee.mutateAsync({ id: editingEmployee.id, email, send_email: false } as never);
                            const url = (result as { data: { register_url?: string } }).data?.register_url;
                            if (url) {
                              await navigator.clipboard.writeText(url);
                              addToast({ type: 'success', message: 'Link copiado al portapapeles' });
                            }
                          } catch {
                            addToast({ type: 'error', message: 'Error al generar link' });
                          }
                        }}
                      >
                        <Link2 className="h-4 w-4 text-violet-600" />
                        <div>
                          <p className="font-medium text-gray-900">Copiar link</p>
                          <p className="text-xs text-gray-500">Copia el enlace para compartir</p>
                        </div>
                      </button>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
