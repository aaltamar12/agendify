'use client';

import { useState } from 'react';
import { Users, Plus, Phone } from 'lucide-react';
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
  const { addToast } = useUIStore();

  const [modalOpen, setModalOpen] = useState(false);
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
          <div className="mt-4 border-t border-gray-200 pt-4">
            <Button
              variant="destructive"
              size="sm"
              loading={deleteEmployee.isPending}
              onClick={() => handleDelete(editingEmployee.id)}
            >
              Eliminar empleado
            </Button>
          </div>
        )}
      </Modal>
    </div>
  );
}
