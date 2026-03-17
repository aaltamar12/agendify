'use client';

import { useState, useRef, useEffect } from 'react';
import { Eye, Search, Building2, Loader2 } from 'lucide-react';
import { useAdminBusinesses, useImpersonate } from '@/lib/hooks/use-admin';
import { useAuthStore } from '@/lib/stores/auth-store';
import { useImpersonationStore } from '@/lib/stores/impersonation-store';
import { BUSINESS_TYPES } from '@/lib/constants';
import type { BusinessType } from '@/lib/api/types';

export function AdminImpersonateDropdown() {
  const { user } = useAuthStore();
  const { isImpersonating } = useImpersonationStore();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const dropdownRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const { data, isLoading } = useAdminBusinesses(search);
  const impersonate = useImpersonate();

  // Only show for admins who are NOT currently impersonating
  if (user?.role !== 'admin' || isImpersonating) return null;

  const businesses = data?.data ?? [];

  const handleSelect = (businessId: number) => {
    impersonate.mutate(businessId);
    setOpen(false);
    setSearch('');
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => {
          setOpen(!open);
          // Focus input when opening
          setTimeout(() => inputRef.current?.focus(), 100);
        }}
        className="flex items-center gap-1.5 rounded-lg border border-amber-300 bg-amber-50 px-3 py-1.5 text-sm font-medium text-amber-700 transition-colors hover:bg-amber-100"
        title="Observar como un negocio"
      >
        <Eye className="h-4 w-4" />
        <span className="hidden sm:inline">Observar como...</span>
      </button>

      {open && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-30"
            onClick={() => {
              setOpen(false);
              setSearch('');
            }}
          />

          {/* Dropdown */}
          <div className="absolute right-0 top-full z-40 mt-2 w-80 rounded-xl border border-gray-200 bg-white shadow-xl">
            {/* Search input */}
            <div className="border-b border-gray-100 p-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  ref={inputRef}
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Buscar negocio..."
                  className="w-full rounded-lg border border-gray-200 bg-gray-50 py-2 pl-9 pr-3 text-sm placeholder:text-gray-400 focus:border-violet-300 focus:bg-white focus:outline-none focus:ring-2 focus:ring-violet-100"
                />
              </div>
            </div>

            {/* Results */}
            <div className="max-h-64 overflow-y-auto p-1">
              {isLoading && (
                <div className="flex items-center justify-center gap-2 py-4">
                  <Loader2 className="h-4 w-4 animate-spin text-gray-400" />
                  <span className="text-xs text-gray-400">Cargando...</span>
                </div>
              )}

              {!isLoading && businesses.length === 0 && (
                <p className="px-3 py-4 text-center text-xs text-gray-400">
                  No se encontraron negocios
                </p>
              )}

              {businesses.map((biz) => (
                <button
                  key={biz.id}
                  onClick={() => handleSelect(biz.id)}
                  disabled={impersonate.isPending}
                  className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-sm transition-colors hover:bg-gray-50 disabled:opacity-50"
                >
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-50">
                    <Building2 className="h-4 w-4 text-violet-600" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-gray-900">
                      {biz.name}
                    </p>
                    <p className="text-xs text-gray-500">
                      {BUSINESS_TYPES[biz.business_type as BusinessType] ?? biz.business_type}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
