'use client';

import { useEffect, useRef, useState, useMemo } from 'react';
import { BadgeCheck, Navigation, Star, MapPin } from 'lucide-react';
import { BUSINESS_TYPES } from '@/lib/constants';
import { formatPhone } from '@/lib/utils/format';
import type { Business, BusinessType } from '@/lib/api/types';

interface ExploreMapProps {
  businesses: Business[];
  selectedId: number | null;
  onSelect: (id: number) => void;
}

// Default center: Barranquilla
const DEFAULT_CENTER: [number, number] = [10.9878, -74.7889];
const DEFAULT_ZOOM = 13;

const NORMAL_MARKER_COLOR = '#7C3AED';
const SELECTED_MARKER_COLOR = '#DC2626';
const NORMAL_SIZE = 28;
const SELECTED_SIZE = 38;

function createMarkerIcon(
  L: typeof import('leaflet'),
  initial: string,
  options?: { selected?: boolean },
) {
  const selected = options?.selected ?? false;
  const color = selected ? SELECTED_MARKER_COLOR : NORMAL_MARKER_COLOR;
  const size = selected ? SELECTED_SIZE : NORMAL_SIZE;
  const half = size / 2;
  const borderWidth = selected ? 4 : 3;
  const fontSize = selected ? 13 : 10;

  return L.divIcon({
    html: `<div style="
      background: ${color};
      width: ${size}px;
      height: ${size}px;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      border: ${borderWidth}px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,${selected ? 0.5 : 0.3});
      margin-left: -${half}px;
      margin-top: -${size}px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
      ${selected ? 'z-index: 1000 !important;' : ''}
    "><span style="
      transform: rotate(45deg);
      color: white;
      font-size: ${fontSize}px;
      font-weight: bold;
    ">${initial}</span></div>`,
    className: selected ? 'selected-marker' : '',
    iconSize: [size, size],
    iconAnchor: [half, size],
  });
}

function createPopupContent(biz: Business) {
  return `
    <div style="min-width: 180px; font-family: inherit;">
      <strong style="font-size: 14px;">${biz.name}</strong><br/>
      <span style="font-size: 12px; color: #6B7280;">
        ${biz.address || ''}${biz.city ? ', ' + biz.city : ''}
      </span>
    </div>
  `;
}

export function ExploreMap({ businesses, selectedId, onSelect }: ExploreMapProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<number, L.Marker>>(new Map());
  const leafletRef = useRef<typeof import('leaflet') | null>(null);
  const businessesDataRef = useRef<Map<number, Business>>(new Map());
  const onSelectRef = useRef(onSelect);
  const [ready, setReady] = useState(false);

  // Keep onSelect ref fresh to avoid stale closures in marker click handlers
  onSelectRef.current = onSelect;

  // Stable key derived from business IDs — changes only when the actual
  // set of businesses changes, avoiding false negatives from array identity.
  const businessKey = useMemo(
    () => businesses.map((b) => b.id).sort().join(','),
    [businesses],
  );

  // Initialize map once
  useEffect(() => {
    if (!mapContainerRef.current) return;

    let cancelled = false;

    const initMap = async () => {
      const L = await import('leaflet');

      // Inject Leaflet CSS via link tag (dynamic CSS imports fail in production)
      if (!document.getElementById('leaflet-css')) {
        const link = document.createElement('link');
        link.id = 'leaflet-css';
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        document.head.appendChild(link);
      }

      if (cancelled || !mapContainerRef.current) return;

      leafletRef.current = L;

      const map = L.map(mapContainerRef.current, {
        center: DEFAULT_CENTER,
        zoom: DEFAULT_ZOOM,
        zoomControl: true,
      });

      L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
        maxZoom: 20,
        subdomains: 'abcd',
      }).addTo(map);

      mapRef.current = map;
      setReady(true);

      setTimeout(() => map.invalidateSize(), 100);
    };

    const timer = setTimeout(initMap, 100);

    return () => {
      cancelled = true;
      clearTimeout(timer);
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
        leafletRef.current = null;
        markersRef.current.clear();
        businessesDataRef.current.clear();
        setReady(false);
      }
    };
  }, []);

  // Update markers and fit bounds when businesses change
  useEffect(() => {
    const map = mapRef.current;
    const L = leafletRef.current;
    if (!ready || !map || !L) return;

    // Stop any ongoing fly animation so the new one takes effect
    map.stop();

    // Remove old markers
    markersRef.current.forEach((marker) => {
      marker.remove();
    });
    markersRef.current.clear();
    businessesDataRef.current.clear();

    // Add new markers
    const bounds: [number, number][] = [];

    businesses.forEach((biz) => {
      const lat = Number(biz.latitude);
      const lng = Number(biz.longitude);
      if (!lat || !lng || isNaN(lat) || isNaN(lng)) return;

      bounds.push([lat, lng]);
      businessesDataRef.current.set(biz.id, biz);

      const markerIcon = createMarkerIcon(L, biz.name.charAt(0));
      const marker = L.marker([lat, lng], { icon: markerIcon }).addTo(map);

      marker.bindPopup(createPopupContent(biz), { closeButton: false });

      marker.on('click', () => {
        onSelectRef.current(biz.id);
      });

      markersRef.current.set(biz.id, marker);
    });

    // Fit bounds to show all new markers
    if (bounds.length === 1) {
      map.flyTo(bounds[0], 15, { duration: 0.8 });
    } else if (bounds.length > 1) {
      const latLngBounds = L.latLngBounds(bounds as L.LatLngTuple[]);
      map.flyToBounds(latLngBounds, {
        padding: [40, 40],
        maxZoom: 15,
        duration: 0.8,
      });
    }

    // Invalidate size to handle any layout shifts
    setTimeout(() => map.invalidateSize(), 200);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessKey, ready]);

  // Highlight selected marker and center on it
  useEffect(() => {
    const map = mapRef.current;
    const L = leafletRef.current;
    if (!map || !L) return;

    // Reset all markers to normal style
    markersRef.current.forEach((marker, id) => {
      const biz = businessesDataRef.current.get(id);
      if (biz) {
        marker.setIcon(createMarkerIcon(L, biz.name.charAt(0), { selected: false }));
        marker.setZIndexOffset(0);
      }
    });

    if (!selectedId) return;

    const marker = markersRef.current.get(selectedId);
    const biz = businessesDataRef.current.get(selectedId);
    if (marker && biz) {
      // Apply selected style (larger, red marker)
      marker.setIcon(createMarkerIcon(L, biz.name.charAt(0), { selected: true }));
      marker.setZIndexOffset(1000);

      // Center map on the selected marker
      const latLng = marker.getLatLng();
      map.flyTo(latLng, Math.max(map.getZoom(), 15), { duration: 0.5 });

      // Open popup after a short delay so flyTo animation starts first
      setTimeout(() => {
        marker.openPopup();
      }, 300);
    }
  }, [selectedId]);

  return (
    <div
      ref={mapContainerRef}
      className="h-full w-full rounded-xl border border-gray-200 overflow-hidden bg-gray-100"
      style={{ minHeight: 500 }}
    />
  );
}

// Sidebar card for map view
export function ExploreMapCard({
  business,
  isSelected,
  onSelect,
}: {
  business: Business;
  isSelected: boolean;
  onSelect: () => void;
}) {
  const cardRef = useRef<HTMLButtonElement>(null);
  const lat = Number(business.latitude);
  const lng = Number(business.longitude);
  const hasCoords = lat && lng && !isNaN(lat) && !isNaN(lng);

  // Auto-scroll the selected card into view within the sidebar
  useEffect(() => {
    if (isSelected && cardRef.current) {
      cardRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }, [isSelected]);

  const directionsUrl = hasCoords
    ? `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`
    : `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
        [business.address, business.city, business.country].filter(Boolean).join(', ')
      )}`;

  return (
    <button
      ref={cardRef}
      onClick={onSelect}
      className={`w-full text-left rounded-xl border p-3 transition-all ${
        isSelected
          ? 'border-violet-400 bg-violet-50 shadow-md ring-2 ring-violet-300'
          : 'border-gray-200 bg-white hover:border-violet-200 hover:shadow-sm'
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1.5">
            <h3 className="text-sm font-semibold text-gray-900 truncate">
              {business.name}
            </h3>
            {business.verified && (
              <BadgeCheck className="h-4 w-4 shrink-0 text-blue-500" aria-label="Verificado" />
            )}
            {business.featured && (
              <span className="shrink-0 inline-flex items-center rounded-full bg-violet-100 px-1.5 py-0.5 text-[10px] font-medium text-violet-700">
                Destacado
              </span>
            )}
          </div>
          <p className="mt-0.5 text-xs text-gray-500">
            {BUSINESS_TYPES[business.business_type as BusinessType] ?? business.business_type}
          </p>
        </div>
        {business.rating_average > 0 && (
          <div className="flex items-center gap-0.5 shrink-0">
            <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
            <span className="text-xs font-medium text-gray-700">
              {Number(business.rating_average).toFixed(1)}
            </span>
          </div>
        )}
      </div>

      {business.address && (
        <p className="mt-1.5 flex items-start gap-1 text-xs text-gray-500">
          <MapPin className="mt-0.5 h-3 w-3 shrink-0 text-gray-400" />
          {business.address}{business.city ? `, ${business.city}` : ''}
        </p>
      )}

      {business.phone && (
        <p className="mt-1 text-xs text-gray-500">
          {formatPhone(business.phone)}
        </p>
      )}

      <div className="mt-2 flex items-center gap-2">
        <a
          href={`/${business.slug}`}
          onClick={(e) => e.stopPropagation()}
          className="text-xs font-medium text-violet-600 hover:text-violet-700"
        >
          Ver negocio
        </a>
        <a
          href={directionsUrl}
          target="_blank"
          rel="noopener noreferrer"
          onClick={(e) => e.stopPropagation()}
          className="inline-flex items-center gap-1 text-xs font-medium text-violet-600 hover:text-violet-700"
        >
          <Navigation className="h-3 w-3" />
          Cómo llegar
        </a>
      </div>
    </button>
  );
}
