'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { MapPin, Navigation, Search } from 'lucide-react';
import { Modal } from '@/components/ui/modal';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

interface LocationPickerProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (lat: number, lng: number) => void;
  initialLat?: number | null;
  initialLng?: number | null;
  businessAddress?: string;
}

export function LocationPicker({
  open,
  onClose,
  onConfirm,
  initialLat,
  initialLng,
  businessAddress,
}: LocationPickerProps) {
  const mapRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.Marker | null>(null);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const [coords, setCoords] = useState<{ lat: number; lng: number }>({
    lat: Number(initialLat) || 10.9878,
    lng: Number(initialLng) || -74.7889,
  });
  const [searchQuery, setSearchQuery] = useState('');
  const [isMapReady, setIsMapReady] = useState(false);

  // Initialize map when modal opens
  useEffect(() => {
    if (!open || !mapContainerRef.current) return;

    // Dynamic import of Leaflet (client-only)
    let cancelled = false;

    const initMap = async () => {
      const L = (await import('leaflet')).default;
      // @ts-expect-error -- CSS import for side effects
      await import('leaflet/dist/leaflet.css');

      if (cancelled || !mapContainerRef.current) return;

      // Clean up existing map
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }

      const startLat = Number(initialLat) || 10.9878;
      const startLng = Number(initialLng) || -74.7889;

      const map = L.map(mapContainerRef.current, {
        center: [startLat, startLng],
        zoom: 16,
        zoomControl: true,
      });

      L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
        maxZoom: 20,
        subdomains: 'abcd',
      }).addTo(map);

      // Custom violet marker icon
      const markerIcon = L.divIcon({
        html: `<div style="
          background: #7C3AED;
          width: 32px;
          height: 32px;
          border-radius: 50% 50% 50% 0;
          transform: rotate(-45deg);
          border: 3px solid white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          margin-left: -16px;
          margin-top: -32px;
        "></div>`,
        className: '',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
      });

      const marker = L.marker([startLat, startLng], {
        icon: markerIcon,
        draggable: true,
      }).addTo(map);

      // Update coords when marker is dragged
      marker.on('dragend', () => {
        const pos = marker.getLatLng();
        setCoords({ lat: pos.lat, lng: pos.lng });
      });

      // Click on map to move marker
      map.on('click', (e: L.LeafletMouseEvent) => {
        marker.setLatLng(e.latlng);
        setCoords({ lat: e.latlng.lat, lng: e.latlng.lng });
      });

      mapRef.current = map;
      markerRef.current = marker;
      setCoords({ lat: startLat, lng: startLng });
      setIsMapReady(true);

      // Force resize after render
      setTimeout(() => map.invalidateSize(), 100);
    };

    // Small delay to let modal animation finish
    const timer = setTimeout(initMap, 200);

    return () => {
      cancelled = true;
      clearTimeout(timer);
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
        markerRef.current = null;
        setIsMapReady(false);
      }
    };
  }, [open, initialLat, initialLng]);

  // Search by address using Nominatim (free, no API key)
  const handleSearch = useCallback(async () => {
    let query = searchQuery || businessAddress;
    if (!query) return;

    // Always append city context from business address
    if (searchQuery && businessAddress) {
      const parts = businessAddress.split(',').map(p => p.trim());
      const cityCountry = parts.slice(1).join(', ');
      if (cityCountry) {
        query = `${searchQuery}, ${cityCountry}`;
      }
    }

    try {
      // Use Photon which handles neighborhoods/zones well
      const res = await fetch(
        `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=5`
      );
      const data = await res.json();

      if (data.features?.length > 0) {
        const [lng, lat] = data.features[0].geometry.coordinates;
        setCoords({ lat, lng });
        if (mapRef.current && markerRef.current) {
          mapRef.current.setView([lat, lng], 17);
          markerRef.current.setLatLng([lat, lng]);
        }
        return;
      }

      // Fallback: Nominatim with structured query
      const nomRes = await fetch(
        `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1`,
        { headers: { 'User-Agent': 'Agendify/1.0' } }
      );
      const nomData = await nomRes.json();
      if (nomData.length > 0) {
        const lat = parseFloat(nomData[0].lat);
        const lng = parseFloat(nomData[0].lon);
        setCoords({ lat, lng });
        if (mapRef.current && markerRef.current) {
          mapRef.current.setView([lat, lng], 17);
          markerRef.current.setLatLng([lat, lng]);
        }
      }
    } catch {
      // Silently fail
    }
  }, [searchQuery, businessAddress]);

  const handleConfirm = () => {
    onConfirm(coords.lat, coords.lng);
    onClose();
  };

  return (
    <Modal open={open} onClose={onClose} title="Selecciona la ubicación de tu negocio" size="lg">
      <div className="space-y-4">
        {/* Instructions */}
        <p className="text-sm text-gray-600">
          Haz clic en el mapa o arrastra el marcador hasta la ubicación exacta de tu negocio.
        </p>

        {/* Map container */}
        <div
          ref={mapContainerRef}
          className="h-[400px] w-full rounded-xl border border-gray-200 overflow-hidden bg-gray-100"
        />

        {/* Coords display */}
        <div className="flex items-center justify-between">
          <p className="text-xs text-gray-400">
            <MapPin className="mr-1 inline h-3 w-3" />
            {Number(coords.lat).toFixed(6)}, {Number(coords.lng).toFixed(6)}
          </p>
          <Button onClick={handleConfirm}>
            <Navigation className="mr-2 h-4 w-4" />
            Confirmar ubicación
          </Button>
        </div>
      </div>
    </Modal>
  );
}
