'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button, Input } from '@/components/ui';
import {
  employeeSchema,
  type EmployeeFormData,
} from '@/lib/validations/onboarding';
import { useCreateEmployee } from '@/lib/hooks/use-onboarding';

interface AddedEmployee {
  id?: number;
  name: string;
  phone?: string;
  email?: string;
}

interface StepEmployeesProps {
  onNext: () => void;
  onBack: () => void;
}

export function StepEmployees({ onNext, onBack }: StepEmployeesProps) {
  const [employees, setEmployees] = useState<AddedEmployee[]>([]);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<EmployeeFormData>({
    resolver: zodResolver(employeeSchema),
  });

  const mutation = useCreateEmployee();

  const onAddEmployee = (data: EmployeeFormData) => {
    mutation.mutate(data, {
      onSuccess: (response) => {
        setEmployees((prev) => [
          ...prev,
          { ...data, id: response.data.id },
        ]);
        reset();
      },
    });
  };

  const removeEmployee = (index: number) => {
    setEmployees((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">Empleados</h3>
      <p className="text-sm text-gray-500">
        Agrega a las personas que atienden. Necesitas al menos 1 para
        continuar.
      </p>

      {/* List of added employees */}
      {employees.length > 0 && (
        <div className="space-y-2">
          {employees.map((employee, index) => (
            <div
              key={index}
              className="flex items-center justify-between rounded-lg border border-gray-200 p-3"
            >
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {employee.name}
                </p>
                {employee.phone && (
                  <p className="text-xs text-gray-500">{employee.phone}</p>
                )}
              </div>
              <button
                type="button"
                onClick={() => removeEmployee(index)}
                className="text-sm text-red-500 hover:text-red-700"
              >
                Eliminar
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add employee form */}
      <form
        onSubmit={handleSubmit(onAddEmployee)}
        className="space-y-3 rounded-lg border border-dashed border-gray-300 p-4"
      >
        <Input
          label="Nombre"
          placeholder="Nombre del empleado"
          error={errors.name?.message}
          {...register('name')}
        />

        <Input
          label="Teléfono (opcional)"
          type="tel"
          placeholder="300 123 4567"
          error={errors.phone?.message}
          {...register('phone')}
        />

        <Input
          label="Correo (opcional)"
          type="email"
          placeholder="empleado@correo.com"
          error={errors.email?.message}
          {...register('email')}
        />

        {mutation.isError && (
          <p className="text-sm text-red-600">
            Error al agregar. Intenta de nuevo.
          </p>
        )}

        <Button
          type="submit"
          variant="outline"
          size="sm"
          loading={mutation.isPending}
        >
          Agregar empleado
        </Button>
      </form>

      <div className="flex items-center justify-between pt-2">
        <Button type="button" variant="ghost" onClick={onBack}>
          Anterior
        </Button>
        <Button
          type="button"
          onClick={onNext}
          disabled={employees.length === 0}
        >
          Siguiente
        </Button>
      </div>
    </div>
  );
}
