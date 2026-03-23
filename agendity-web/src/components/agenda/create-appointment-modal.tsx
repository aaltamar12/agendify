'use client';

import { useEffect, useState, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
import { Clock, Search, UserPlus, X } from 'lucide-react';
import { Modal } from '@/components/ui/modal';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { get } from '@/lib/api/client';
import { ENDPOINTS } from '@/lib/api/endpoints';
import type { ApiResponse, Service, Employee, Customer, DayOfWeek } from '@/lib/api/types';
import {
  createAppointmentSchema,
  type CreateAppointmentFormData,
} from '@/lib/validations/appointment';
import { useCreateAppointment } from '@/lib/hooks/use-appointments';
import { useBusinessHours } from '@/lib/hooks/use-business';
import { useUIStore } from '@/lib/stores/ui-store';

interface Slot {
  time: string;
  available: boolean;
}

interface CreateAppointmentModalProps {
  open: boolean;
  onClose: () => void;
  defaultDate?: string;
  defaultTime?: string;
}

export function CreateAppointmentModal({
  open,
  onClose,
  defaultDate,
  defaultTime,
}: CreateAppointmentModalProps) {
  const addToast = useUIStore((s) => s.addToast);
  const createAppointment = useCreateAppointment();
  const { data: businessHours } = useBusinessHours();

  // Days the business is closed (for date picker validation)
  const closedDays = (businessHours || [])
    .filter((h) => h.closed)
    .map((h) => h.day_of_week);
  const [manualTime, setManualTime] = useState(false);
  const [customerSearch, setCustomerSearch] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [showNewCustomer, setShowNewCustomer] = useState(false);
  const searchTimeoutRef = useRef<ReturnType<typeof setTimeout>>(null);

  const {
    register,
    handleSubmit,
    watch,
    reset,
    setValue,
    formState: { errors },
  } = useForm<CreateAppointmentFormData>({
    resolver: zodResolver(createAppointmentSchema),
    defaultValues: {
      appointment_date: defaultDate ?? '',
      start_time: defaultTime ?? '',
      notes: '',
      customer_email: '',
    },
  });

  useEffect(() => {
    if (open) {
      reset({
        appointment_date: defaultDate ?? '',
        start_time: defaultTime ?? '',
        notes: '',
        customer_email: '',
        service_id: undefined,
        employee_id: undefined,
        customer_name: '',
        customer_phone: '',
      });
      setManualTime(false);
      setCustomerSearch('');
      setSelectedCustomer(null);
      setShowNewCustomer(false);
    }
  }, [open, defaultDate, defaultTime, reset]);

  // Debounced customer search
  const [debouncedSearch, setDebouncedSearch] = useState('');
  useEffect(() => {
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);
    searchTimeoutRef.current = setTimeout(() => {
      setDebouncedSearch(customerSearch);
    }, 300);
    return () => { if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current); };
  }, [customerSearch]);

  const { data: customerResults, isLoading: searchingCustomers } = useQuery({
    queryKey: ['customers-search', debouncedSearch],
    queryFn: () => get<{ data: Customer[]; meta: unknown }>(ENDPOINTS.CUSTOMERS.list, { params: { search: debouncedSearch, per_page: 5 } }),
    enabled: debouncedSearch.length >= 2 && !selectedCustomer,
    select: (res) => res.data,
  });

  const handleSelectCustomer = (customer: Customer) => {
    setSelectedCustomer(customer);
    setCustomerSearch('');
    setValue('customer_name', customer.name, { shouldValidate: true });
    setValue('customer_phone', customer.phone || '', { shouldValidate: true });
    setValue('customer_email', customer.email || '');
  };

  const handleClearCustomer = () => {
    setSelectedCustomer(null);
    setShowNewCustomer(false);
    setCustomerSearch('');
    setDebouncedSearch('');
    setValue('customer_name', '');
    setValue('customer_phone', '');
    setValue('customer_email', '');
  };

  // Fetch services
  const { data: servicesData } = useQuery({
    queryKey: ['services'],
    queryFn: () => get<ApiResponse<Service[]>>(ENDPOINTS.SERVICES.list),
    enabled: open,
  });

  // Fetch employees
  const { data: employeesData } = useQuery({
    queryKey: ['employees'],
    queryFn: () => get<ApiResponse<Employee[]>>(ENDPOINTS.EMPLOYEES.list),
    enabled: open,
  });

  const services = servicesData?.data ?? [];
  const employees = employeesData?.data ?? [];
  const selectedServiceId = watch('service_id');
  const selectedEmployeeId = watch('employee_id');
  const selectedDate = watch('appointment_date');
  const selectedTime = watch('start_time');

  const filteredEmployees = employees.filter((e) => e.active);

  // Fetch available slots when service + date are selected
  const slotsEnabled = !!(selectedServiceId && selectedDate && !manualTime);
  const { data: slotsData, isLoading: slotsLoading } = useQuery({
    queryKey: ['available-slots', selectedServiceId, selectedEmployeeId, selectedDate],
    queryFn: () =>
      get<ApiResponse<Slot[]>>(ENDPOINTS.APPOINTMENTS.availableSlots, {
        params: {
          service_id: selectedServiceId,
          employee_id: selectedEmployeeId || undefined,
          date: selectedDate,
        },
      }),
    enabled: slotsEnabled,
  });

  const slots = slotsData?.data ?? [];

  const serviceOptions = services
    .filter((s) => s.active)
    .map((s) => ({
      value: String(s.id),
      label: `${s.name} (${s.duration_minutes} min - $${s.price.toLocaleString()})`,
    }));

  const employeeOptions = filteredEmployees.map((e) => ({
    value: String(e.id),
    label: e.name,
  }));

  async function onSubmit(data: CreateAppointmentFormData) {
    try {
      await createAppointment.mutateAsync(data);
      addToast({ type: 'success', message: 'Cita creada exitosamente' });
      onClose();
    } catch {
      addToast({ type: 'error', message: 'Error al crear la cita' });
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Nueva cita" size="lg">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Service */}
        <Select
          label="Servicio"
          placeholder="Selecciona un servicio"
          options={serviceOptions}
          error={errors.service_id?.message}
          {...register('service_id', { valueAsNumber: true })}
        />

        {/* Employee */}
        <Select
          label="Empleado"
          placeholder="Selecciona un empleado"
          options={employeeOptions}
          error={errors.employee_id?.message}
          disabled={!selectedServiceId}
          {...register('employee_id', { valueAsNumber: true })}
        />

        {/* Customer info */}
        <div className="border-t border-gray-200 pt-4">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-gray-700">
              Cliente
            </h3>
            {!selectedCustomer && !showNewCustomer && (
              <button
                type="button"
                onClick={() => setShowNewCustomer(true)}
                className="flex cursor-pointer items-center gap-1 text-xs font-medium text-violet-600 hover:text-violet-700"
              >
                <UserPlus className="h-3.5 w-3.5" />
                Nuevo cliente
              </button>
            )}
            {(selectedCustomer || showNewCustomer) && (
              <button
                type="button"
                onClick={handleClearCustomer}
                className="flex cursor-pointer items-center gap-1 text-xs font-medium text-gray-500 hover:text-gray-700"
              >
                <X className="h-3.5 w-3.5" />
                Cambiar
              </button>
            )}
          </div>

          {selectedCustomer ? (
            /* Selected customer card */
            <div className="flex items-center gap-3 rounded-lg border border-violet-200 bg-violet-50 p-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-violet-600 text-sm font-medium text-white">
                {selectedCustomer.name.charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-gray-900">{selectedCustomer.name}</p>
                <p className="text-xs text-gray-500">
                  {selectedCustomer.phone}
                  {selectedCustomer.email && ` · ${selectedCustomer.email}`}
                </p>
              </div>
            </div>
          ) : !showNewCustomer ? (
            /* Customer search */
            <div className="relative">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  value={customerSearch}
                  onChange={(e) => setCustomerSearch(e.target.value)}
                  placeholder="Buscar por nombre, teléfono o correo..."
                  className="w-full rounded-lg border border-gray-300 py-2.5 pl-9 pr-3 text-sm focus:border-violet-500 focus:outline-none focus:ring-1 focus:ring-violet-500"
                />
              </div>
              {/* Search results dropdown */}
              {debouncedSearch.length >= 2 && !selectedCustomer && (
                <div className="absolute left-0 right-0 top-full z-10 mt-1 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-lg">
                  {searchingCustomers ? (
                    <div className="px-4 py-3 text-sm text-gray-500">Buscando...</div>
                  ) : customerResults && customerResults.length > 0 ? (
                    <ul className="max-h-48 overflow-y-auto">
                      {customerResults.map((c) => (
                        <li key={c.id}>
                          <button
                            type="button"
                            onClick={() => handleSelectCustomer(c)}
                            className="flex w-full cursor-pointer items-center gap-3 px-4 py-2.5 text-left hover:bg-gray-50"
                          >
                            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-medium text-violet-600">
                              {c.name.charAt(0).toUpperCase()}
                            </div>
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-medium text-gray-900">{c.name}</p>
                              <p className="text-xs text-gray-500">
                                {c.phone}{c.email && ` · ${c.email}`}
                                {c.total_visits > 0 && ` · ${c.total_visits} visitas`}
                              </p>
                            </div>
                          </button>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <div className="px-4 py-3">
                      <p className="text-sm text-gray-500">No se encontraron clientes</p>
                      <button
                        type="button"
                        onClick={() => { setShowNewCustomer(true); setCustomerSearch(''); }}
                        className="mt-1 cursor-pointer text-xs font-medium text-violet-600 hover:text-violet-700"
                      >
                        Crear nuevo cliente
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          ) : (
            /* New customer form */
            <div className="space-y-3">
              <Input
                label="Nombre"
                placeholder="Nombre del cliente"
                error={errors.customer_name?.message}
                {...register('customer_name')}
              />
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                <Input
                  label="Teléfono"
                  placeholder="3001234567"
                  type="tel"
                  error={errors.customer_phone?.message}
                  {...register('customer_phone')}
                />
                <Input
                  label="Correo (opcional)"
                  placeholder="correo@ejemplo.com"
                  type="email"
                  error={errors.customer_email?.message}
                  {...register('customer_email')}
                />
              </div>
            </div>
          )}
        </div>

        {/* Date and time */}
        <div className="border-t border-gray-200 pt-4">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-gray-700">
              Fecha y hora
            </h3>
            <button
              type="button"
              onClick={() => setManualTime(!manualTime)}
              className="cursor-pointer text-xs font-medium text-violet-600 hover:text-violet-700"
            >
              {manualTime ? 'Ver horarios disponibles' : 'Ingresar hora manual'}
            </button>
          </div>

          <div>
            <Input
              label="Fecha"
              type="date"
              error={errors.appointment_date?.message}
              {...register('appointment_date', {
                validate: (value) => {
                  if (!value) return 'La fecha es requerida';
                  const date = new Date(value + 'T00:00:00');
                  if (closedDays.includes(date.getDay() as DayOfWeek)) {
                    return 'El negocio no opera este dia';
                  }
                  return true;
                },
              })}
            />
            {closedDays.length > 0 && (
              <p className="mt-1 text-xs text-gray-400">
                Dias cerrados: {closedDays.map((d) => ['Dom','Lun','Mar','Mie','Jue','Vie','Sab'][d]).join(', ')}
              </p>
            )}
          </div>

          {manualTime ? (
            <div className="mt-3">
              <Input
                label="Hora"
                type="time"
                step="900"
                error={errors.start_time?.message}
                {...register('start_time')}
              />
            </div>
          ) : (
            <div className="mt-3">
              {!selectedServiceId || !selectedDate ? (
                <p className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
                  <Clock className="h-4 w-4" />
                  Selecciona un servicio y fecha para ver horarios disponibles
                </p>
              ) : slotsLoading ? (
                <div className="flex items-center gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-violet-600 border-t-transparent" />
                  Cargando horarios...
                </div>
              ) : slots.length === 0 ? (
                <p className="rounded-lg border border-orange-200 bg-orange-50 p-3 text-sm text-orange-700">
                  No hay horarios disponibles para esta fecha.
                </p>
              ) : (
                <div>
                  <label className="mb-2 block text-sm font-medium text-gray-700">
                    Horarios disponibles
                  </label>
                  <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
                    {slots.map((slot) => (
                      <button
                        key={slot.time}
                        type="button"
                        disabled={!slot.available}
                        onClick={() => setValue('start_time', slot.time, { shouldValidate: true })}
                        className={`rounded-lg border px-2 py-2 text-sm font-medium transition-colors ${
                          !slot.available
                            ? 'cursor-not-allowed border-gray-100 bg-gray-50 text-gray-300'
                            : selectedTime === slot.time
                              ? 'cursor-pointer border-violet-600 bg-violet-600 text-white'
                              : 'cursor-pointer border-gray-200 bg-white text-gray-700 hover:border-violet-300 hover:bg-violet-50'
                        }`}
                      >
                        {slot.time}
                      </button>
                    ))}
                  </div>
                  {errors.start_time && (
                    <p className="mt-1 text-sm text-red-600">{errors.start_time.message}</p>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Notes */}
        <Textarea
          label="Notas (opcional)"
          placeholder="Notas adicionales sobre la cita..."
          rows={3}
          {...register('notes')}
        />

        {/* Actions */}
        <div className="flex justify-end gap-3 border-t border-gray-200 pt-4">
          <Button type="button" variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button type="submit" loading={createAppointment.isPending}>
            Crear cita
          </Button>
        </div>
      </form>
    </Modal>
  );
}
