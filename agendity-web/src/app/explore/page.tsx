'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { Search, LayoutGrid, Map } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { EmptyState } from '@/components/ui/empty-state';
import { BusinessCard } from '@/components/shared/business-card';
import { ExploreMap, ExploreMapCard } from '@/components/shared/explore-map';
import { useExploreBusinesses, useCities, useSearchSuggestions } from '@/lib/hooks/use-explore';

type ViewMode = 'list' | 'map';

const TYPE_FILTERS = [
  { label: 'Todas', value: '' },
  { label: 'Barberías', value: 'barbershop' },
  { label: 'Salones', value: 'salon' },
  { label: 'Spa', value: 'spa' },
  { label: 'Uñas', value: 'nails' },
];

const BUSINESS_TYPE_LABELS: Record<string, string> = {
  barbershop: 'Barbería',
  salon: 'Salón',
  spa: 'Spa',
  nails: 'Uñas',
  other: 'Otro',
};

function SkeletonCard() {
  return (
    <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
      <Skeleton className="h-40 w-full rounded-none" />
      <div className="flex flex-col gap-3 p-4">
        <div className="flex items-start justify-between">
          <Skeleton className="h-5 w-32" />
          <Skeleton className="h-5 w-16 rounded-full" />
        </div>
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-48" />
      </div>
    </div>
  );
}

export default function ExplorePage() {
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [city, setCity] = useState('');
  const [type, setType] = useState('');
  const [page, setPage] = useState(1);

  // Suggestions dropdown — disabled because debounce already filters
  // the list/map in real time, making the dropdown redundant.
  // Set to true to re-enable if needed in a different context.
  const enableSuggestions = false;
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [inputFocused, setInputFocused] = useState(false);
  const searchContainerRef = useRef<HTMLDivElement>(null);

  const { data: citiesData } = useCities();
  const cities = citiesData ?? [];

  const { data, isLoading } = useExploreBusinesses({
    search: debouncedSearch || undefined,
    city: city || undefined,
    type: type || undefined,
    page,
  });

  const { data: suggestions } = useSearchSuggestions(enableSuggestions ? search : '');

  const [selectedBusinessId, setSelectedBusinessId] = useState<number | null>(null);

  const businesses = data?.data ?? [];
  const meta = data?.meta;

  // Debounce search input using window pattern
  const handleSearchChange = (value: string) => {
    setSearch(value);
    const w = window as unknown as { __exploreSearchTimer?: ReturnType<typeof setTimeout> };
    clearTimeout(w.__exploreSearchTimer);
    w.__exploreSearchTimer = setTimeout(() => {
      setDebouncedSearch(value);
      setPage(1);
    }, 400);
  };

  // Show suggestions when input is focused and has 2+ chars with results
  useEffect(() => {
    if (!enableSuggestions) return;
    setShowSuggestions(inputFocused && search.length >= 2 && (suggestions?.length ?? 0) > 0);
  }, [enableSuggestions, inputFocused, search, suggestions]);

  // Click outside handler to close suggestions
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (
        searchContainerRef.current &&
        !searchContainerRef.current.contains(e.target as Node)
      ) {
        setShowSuggestions(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Immediate search on form submit (Enter / button click)
  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const w = window as unknown as { __exploreSearchTimer?: ReturnType<typeof setTimeout> };
    clearTimeout(w.__exploreSearchTimer);
    setDebouncedSearch(search);
    setPage(1);
    setShowSuggestions(false);
  }

  // Handle keyboard events on the search input
  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Escape') {
      setShowSuggestions(false);
    }
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Explorar negocios</h1>
        <p className="mt-2 text-gray-500">
          Encuentra la mejor barbería o salón cerca de ti y reserva en segundos.
        </p>
      </div>

      {/* Search bar */}
      <form onSubmit={handleSearch} className="mb-6 flex flex-col gap-3 sm:flex-row">
        <div ref={searchContainerRef} className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Buscar por nombre..."
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            onFocus={() => setInputFocused(true)}
            onBlur={() => {
              // Delay to allow click on suggestion
              setTimeout(() => setInputFocused(false), 150);
            }}
            onKeyDown={handleKeyDown}
            className="pl-10"
            autoComplete="off"
          />

          {/* Suggestions dropdown */}
          {showSuggestions && suggestions && suggestions.length > 0 && (
            <div className="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-lg border border-gray-200 bg-white shadow-lg">
              {suggestions.map((biz, index) => (
                <Link
                  key={biz.id}
                  href={`/${biz.slug}`}
                  onClick={() => setShowSuggestions(false)}
                  className={`flex flex-col px-4 py-3 transition-colors hover:bg-violet-50 ${
                    index < suggestions.length - 1 ? 'border-b border-gray-100' : ''
                  }`}
                >
                  <span className="text-sm font-medium text-gray-900">{biz.name}</span>
                  <span className="text-xs text-gray-500">
                    {BUSINESS_TYPE_LABELS[biz.business_type] ?? biz.business_type}
                    {biz.city ? ` · ${biz.city}` : ''}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>
        <select
          value={city}
          onChange={(e) => {
            setCity(e.target.value);
            setPage(1);
          }}
          className="rounded-lg border border-gray-300 bg-white px-3 py-2 pr-8 text-sm text-gray-700 appearance-none focus:border-violet-600 focus:outline-none focus:ring-2 focus:ring-violet-600/20 sm:w-48"
        >
          <option value="">Todas las ciudades</option>
          {cities.map((c) => (
            <option key={c.name} value={c.name}>
              {c.name} ({c.count})
            </option>
          ))}
        </select>
        <Button type="submit">Buscar</Button>
      </form>

      {/* Type filter pills + view toggle */}
      <div className="mb-8 flex items-center justify-between gap-4">
        <div className="flex flex-wrap gap-2">
          {TYPE_FILTERS.map((filter) => (
            <button
              key={filter.value}
              onClick={() => {
                setType(filter.value);
                setPage(1);
              }}
              className={`rounded-full px-4 py-1.5 text-sm font-medium transition-colors ${
                type === filter.value
                  ? 'bg-violet-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {filter.label}
            </button>
          ))}
        </div>

        {/* View mode toggle */}
        <div className="flex shrink-0 rounded-lg border border-gray-200 bg-white p-0.5">
          <button
            onClick={() => setViewMode('list')}
            className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
              viewMode === 'list'
                ? 'bg-violet-600 text-white'
                : 'text-gray-600 hover:text-gray-900'
            }`}
            title="Vista de lista"
          >
            <LayoutGrid className="h-4 w-4" />
            <span className="hidden sm:inline">Lista</span>
          </button>
          <button
            onClick={() => setViewMode('map')}
            className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
              viewMode === 'map'
                ? 'bg-violet-600 text-white'
                : 'text-gray-600 hover:text-gray-900'
            }`}
            title="Vista de mapa"
          >
            <Map className="h-4 w-4" />
            <span className="hidden sm:inline">Mapa</span>
          </button>
        </div>
      </div>

      {/* Map view — sidebar + interactive map */}
      {viewMode === 'map' && (
        <div className="flex gap-4" style={{ height: 'calc(100vh - 300px)', minHeight: 500 }}>
          {/* Left: business list */}
          <div className="w-80 shrink-0 space-y-2 overflow-y-auto pr-1">
            {isLoading && (
              <div className="space-y-2">
                {Array.from({ length: 4 }).map((_, i) => (
                  <Skeleton key={i} className="h-28 w-full rounded-xl" />
                ))}
              </div>
            )}

            {!isLoading && businesses.length === 0 && (
              <div className="py-8 text-center text-sm text-gray-500">
                No se encontraron negocios
              </div>
            )}

            {!isLoading && businesses.map((biz) => (
              <ExploreMapCard
                key={biz.id}
                business={biz}
                isSelected={selectedBusinessId === biz.id}
                onSelect={() => setSelectedBusinessId(biz.id)}
              />
            ))}
          </div>

          {/* Right: Leaflet map with markers */}
          <div className="flex-1">
            <ExploreMap
              businesses={businesses}
              selectedId={selectedBusinessId}
              onSelect={setSelectedBusinessId}
            />
          </div>
        </div>
      )}

      {/* List view */}
      {viewMode === 'list' && (
        <>
          {/* Loading skeletons */}
          {isLoading && (
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <SkeletonCard key={i} />
              ))}
            </div>
          )}

          {/* Results grid */}
          {!isLoading && businesses.length > 0 && (
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {businesses.map((business) => (
                <BusinessCard key={business.id} business={business} />
              ))}
            </div>
          )}

          {/* Empty state */}
          {!isLoading && businesses.length === 0 && (
            <EmptyState
              title="No se encontraron negocios"
              description="Intenta con otros filtros o una búsqueda diferente."
            />
          )}

          {/* Pagination */}
          {meta && meta.total_pages > 1 && (
            <div className="mt-10 flex items-center justify-center gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                Anterior
              </Button>
              <span className="px-3 text-sm text-gray-600">
                Página {meta.current_page} de {meta.total_pages}
              </span>
              <Button
                variant="outline"
                size="sm"
                disabled={page >= meta.total_pages}
                onClick={() => setPage((p) => p + 1)}
              >
                Siguiente
              </Button>
            </div>
          )}
        </>
      )}

      {/* Business owner CTA */}
      <div className="mt-12 rounded-xl border border-violet-200 bg-violet-50 p-6 text-center">
        <p className="mb-2 text-lg font-bold text-gray-900">
          ¿Tienes un negocio que trabaja con citas?
        </p>
        <p className="mb-4 text-sm text-gray-600">
          Registra tu negocio en Agendity, organiza tu agenda, controla tus finanzas y aparece en esta lista.
        </p>
        <a
          href="/register"
          className="inline-flex items-center gap-2 rounded-lg bg-violet-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-violet-700 transition-colors"
        >
          Registra tu negocio gratis
        </a>
      </div>
    </div>
  );
}
