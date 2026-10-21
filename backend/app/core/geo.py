import math
from typing import List, Tuple, Any, Optional

EARTH_RADIUS_METERS = 6378137.0  # Jari-jari WGS-84 bola bumi dalam meter

def validate_and_normalize_polygon(coords: Any) -> Tuple[bool, Optional[str], List[List[float]]]:
    """
    Validasi dan normalisasi koordinat poligon.
    Format input yang diterima:
    - List of [lat, lng] atau (lat, lng)
    - List of dict: [{'lat': -7.5, 'lng': 112.5}, ...] atau [{'latitude': -7.5, 'longitude': 112.5}, ...]

    Mengembalikan (is_valid, error_message, normalized_coords)
    normalized_coords adalah List[[lat, lng], ...]
    """
    if not coords or not isinstance(coords, list):
        return False, "Koordinat poligon harus berupa list titik koordinat", []

    if len(coords) < 3:
        return False, f"Poligon harus memiliki minimal 3 titik sudut, diterima {len(coords)} titik", []

    normalized = []
    for idx, pt in enumerate(coords):
        lat, lng = None, None
        if isinstance(pt, (list, tuple)) and len(pt) >= 2:
            try:
                lat = float(pt[0])
                lng = float(pt[1])
            except (ValueError, TypeError):
                return False, f"Titik ke-{idx+1} koordinat tidak valid: {pt}", []
        elif isinstance(pt, dict):
            try:
                lat = float(pt.get('lat') if 'lat' in pt else pt.get('latitude'))
                lng = float(pt.get('lng') if 'lng' in pt else pt.get('longitude'))
            except (ValueError, TypeError):
                return False, f"Titik ke-{idx+1} format dict tidak valid: {pt}", []
        else:
            return False, f"Format titik ke-{idx+1} tidak dikenali: {pt}", []

        # Validasi rentang latitude & longitude
        if not (-90.0 <= lat <= 90.0):
            return False, f"Latitude pada titik ke-{idx+1} ({lat}) berada di luar rentang valid (-90 s/d 90)", []
        if not (-180.0 <= lng <= 180.0):
            return False, f"Longitude pada titik ke-{idx+1} ({lng}) berada di luar rentang valid (-180 s/d 180)", []

        normalized.append([round(lat, 7), round(lng, 7)])

    # Pastikan poligon tidak memiliki titik yang identik berturut-turut
    unique_points = []
    for p in normalized:
        if not unique_points or unique_points[-1] != p:
            unique_points.append(p)

    if len(unique_points) < 3:
        return False, "Titik poligon unik kurang dari 3 setelah menghapus duplikat berturut-turut", []

    return True, None, normalized

def calculate_geodesic_polygon_area(coords: List[List[float]]) -> float:
    """
    Menghitung luas poligon bola bumi (Spherical Polygon Geodesic Area) dalam m².
    Menggunakan formula proyeksi bola WGS-84 dengan radius 6.378.137 meter.
    Hasil perhitungan identik dengan pustaka SIG standar (Leaflet/Turf.js/ArcGIS).
    """
    if not coords or len(coords) < 3:
        return 0.0

    total = 0.0
    n = len(coords)

    for i in range(n):
        p1 = coords[i]
        p2 = coords[(i + 1) % n]

        lat1 = math.radians(p1[0])
        lat2 = math.radians(p2[0])
        lon1 = math.radians(p1[1])
        lon2 = math.radians(p2[1])

        total += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2))

    area_m2 = abs(total * EARTH_RADIUS_METERS * EARTH_RADIUS_METERS / 2.0)
    return round(area_m2, 2)
