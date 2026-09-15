import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import { MapPin, Navigation } from 'lucide-react';

// Custom SVG marker pin to prevent missing asset issues
const customMarkerIcon = new L.DivIcon({
  className: 'custom-leaflet-marker',
  html: `
    <div style="display: flex; align-items: center; justify-content: center; width: 36px; height: 36px; border-radius: 50%; background: #16a34a; border: 3px solid #ffffff; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3);">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
        <circle cx="12" cy="10" r="3"></circle>
      </svg>
    </div>
  `,
  iconSize: [36, 36],
  iconAnchor: [18, 36],
});

function LocationMarker({ position, setPosition, readOnly }) {
  useMapEvents({
    click(e) {
      if (!readOnly) {
        setPosition([e.latlng.lat, e.latlng.lng]);
      }
    },
  });

  return position ? (
    <Marker
      position={position}
      icon={customMarkerIcon}
      draggable={!readOnly}
      eventHandlers={{
        dragend: (e) => {
          const marker = e.target;
          const pos = marker.getLatLng();
          setPosition([pos.lat, pos.lng]);
        },
      }}
    />
  ) : null;
}

export default function MapPicker({
  initialLat = -7.4726,
  initialLng = 112.4381,
  onChange,
  readOnly = false,
  height = '260px',
}) {
  const [position, setPosition] = useState(
    initialLat && initialLng ? [parseFloat(initialLat), parseFloat(initialLng)] : [-7.4726, 112.4381]
  );

  useEffect(() => {
    if (initialLat && initialLng) {
      setPosition([parseFloat(initialLat), parseFloat(initialLng)]);
    }
  }, [initialLat, initialLng]);

  const handlePositionChange = (newPos) => {
    setPosition(newPos);
    if (onChange) {
      onChange({
        latitude: parseFloat(newPos[0].toFixed(7)),
        longitude: parseFloat(newPos[1].toFixed(7)),
      });
    }
  };

  const handleUseCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          handlePositionChange([pos.coords.latitude, pos.coords.longitude]);
        },
        () => {
          alert('Tidak dapat mendeteksi lokasi saat ini. Silakan tentukan pin langsung pada peta.');
        }
      );
    }
  };

  return (
    <div className="w-full">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-700">
          <MapPin className="w-3.5 h-3.5 text-emerald-600" />
          <span>Titik Koordinat GPS Lahan</span>
        </div>
        {!readOnly && (
          <button
            type="button"
            onClick={handleUseCurrentLocation}
            className="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100 px-2 py-1 rounded-md transition-colors"
          >
            <Navigation className="w-3 h-3" /> Lokasi Saya
          </button>
        )}
      </div>

      <div
        className="w-full rounded-xl overflow-hidden border border-slate-300 shadow-xs relative"
        style={{ height }}
      >
        <MapContainer
          center={position}
          zoom={13}
          scrollWheelZoom={false}
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <LocationMarker
            position={position}
            setPosition={handlePositionChange}
            readOnly={readOnly}
          />
        </MapContainer>
      </div>

      <div className="mt-2 flex items-center justify-between text-[11px] text-slate-500">
        <span>
          Lat: <strong className="text-slate-700">{position[0]?.toFixed(6)}</strong> | Lng:{' '}
          <strong className="text-slate-700">{position[1]?.toFixed(6)}</strong>
        </span>
        {!readOnly && <span>Klik atau geser penanda untuk memilih titik lahan</span>}
      </div>
    </div>
  );
}
