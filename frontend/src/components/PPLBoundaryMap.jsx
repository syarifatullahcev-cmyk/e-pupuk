import { CircleMarker, MapContainer, Polygon, TileLayer, useMapEvents } from 'react-leaflet';

function BoundaryClickHandler({ onAddPoint }) {
  useMapEvents({
    click(event) {
      onAddPoint([event.latlng.lat, event.latlng.lng]);
    },
  });

  return null;
}

export default function PPLBoundaryMap({ center, points, onAddPoint }) {
  const mapCenter = center || points[0];
  if (!mapCenter) {
    return (
      <div className="flex h-72 items-center justify-center rounded-xl border border-dashed border-amber-300 bg-amber-50 p-6 text-center text-xs text-amber-800">
        Koordinat lahan belum tersedia. Rekam titik GPS aktual terlebih dahulu untuk menampilkan peta pengukuran.
      </div>
    );
  }

  return (
    <div className="h-72 overflow-hidden rounded-xl border border-slate-300">
      <MapContainer
        center={mapCenter}
        zoom={17}
        scrollWheelZoom
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <BoundaryClickHandler onAddPoint={onAddPoint} />
        {points.length >= 3 && <Polygon positions={points} pathOptions={{ color: '#059669' }} />}
        {points.map((point, index) => (
          <CircleMarker
            key={`${point[0]}-${point[1]}-${index}`}
            center={point}
            radius={6}
            pathOptions={{ color: '#fff', fillColor: '#059669', fillOpacity: 1, weight: 2 }}
          />
        ))}
      </MapContainer>
    </div>
  );
}
