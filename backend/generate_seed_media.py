import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"

(UPLOAD_DIR / "ktp").mkdir(parents=True, exist_ok=True)
(UPLOAD_DIR / "lahan").mkdir(parents=True, exist_ok=True)
(UPLOAD_DIR / "survei").mkdir(parents=True, exist_ok=True)

def create_ktp_image(filename, name, nik, address):
    img = Image.new('RGB', (800, 500), color='#0f766e')
    draw = ImageDraw.Draw(img)
    # Background card
    draw.rectangle([20, 20, 780, 480], fill='#e0f2fe', outline='#0369a1', width=4)
    # Header
    draw.rectangle([20, 20, 780, 90], fill='#0284c7')
    draw.text((250, 30), "REPUBLIK INDONESIA", fill="#ffffff")
    draw.text((230, 55), "PROVINSI JAWA TIMUR - KAB. MOJOKERTO", fill="#fef08a")
    # Photo box
    draw.rectangle([580, 120, 750, 360], fill='#bae6fd', outline='#0284c7', width=3)
    draw.ellipse([630, 160, 700, 230], fill='#0284c7')
    draw.polygon([(600, 340), (665, 250), (730, 340)], fill='#0284c7')
    draw.text((615, 370), "PAS FOTO RESMI", fill="#0369a1")
    # Details
    draw.text((50, 120), f"NIK            : {nik}", fill="#0f172a")
    draw.text((50, 165), f"Nama           : {name}", fill="#0f172a")
    draw.text((50, 210), "Tempat/Tgl Lahir: Mojokerto, 12-08-1980", fill="#0f172a")
    draw.text((50, 255), "Jenis Kelamin  : Laki-laki    Gol. Darah: O", fill="#0f172a")
    draw.text((50, 300), f"Alamat         : {address}", fill="#0f172a")
    draw.text((50, 345), "Agama          : Islam", fill="#0f172a")
    draw.text((50, 390), "Pekerjaan      : Petani / Pekebun", fill="#0f172a")
    draw.text((50, 435), "Kewarganegaraan: WNI         Berlaku: SEUMUR HIDUP", fill="#0f172a")
    
    img.save(filename, quality=92)
    print(f"Created {filename}")

def create_landscape_image(filename, title, subtitle, bg_color='#15803d'):
    img = Image.new('RGB', (900, 600), color=bg_color)
    draw = ImageDraw.Draw(img)
    # Sky
    draw.rectangle([0, 0, 900, 250], fill='#7dd3fc')
    # Sun
    draw.ellipse([700, 40, 800, 140], fill='#fde047')
    # Mountains
    draw.polygon([(50, 250), (250, 120), (450, 250)], fill='#047857')
    draw.polygon([(350, 250), (600, 90), (850, 250)], fill='#065f46')
    # Farm fields
    draw.polygon([(0, 250), (900, 250), (900, 600), (0, 600)], fill='#16a34a')
    # Rows / crops pattern
    for y in range(280, 580, 35):
        draw.line([(0, y), (900, y + 20)], fill='#15803d', width=5)
    
    # Overlay badge
    draw.rectangle([40, 460, 860, 560], fill='#0f172acc')
    draw.text((60, 480), title, fill='#22c55e')
    draw.text((60, 515), subtitle, fill='#f8fafc')
    
    img.save(filename, quality=90)
    print(f"Created {filename}")

if __name__ == "__main__":
    create_ktp_image(str(UPLOAD_DIR / "ktp" / "sample_ktp_budi.jpg"), "BUDI SANTOSO", "3516011208800001", "Dsn. Sumberarum RT 02 RW 01, Mojosari")
    create_ktp_image(str(UPLOAD_DIR / "ktp" / "sample_ktp_siti.jpg"), "SITI AMINAH", "3516025505850002", "Dsn. Kemasan RT 03 RW 02, Trowulan")
    create_landscape_image(
        str(UPLOAD_DIR / "lahan" / "sample_sawah_mojosari.jpg"),
        "DOKUMENTASI FOTO LAHAN PERTANIAN - SAWAH PADI",
        "Lokasi: Mojosari, Kab. Mojokerto | Luas: 12.000 m² | Komoditas: Padi Ciherang",
        bg_color='#14532d'
    )
    create_landscape_image(
        str(UPLOAD_DIR / "lahan" / "sample_jagung_trowulan.jpg"),
        "DOKUMENTASI FOTO LAHAN PERTANIAN - LADANG JAGUNG",
        "Lokasi: Trowulan, Kab. Mojokerto | Luas: 8.500 m² | Komoditas: Jagung Hibrida",
        bg_color='#166534'
    )
    create_landscape_image(
        str(UPLOAD_DIR / "survei" / "sample_survei_lahan1.jpg"),
        "HASIL SURVEI FISIK LAPANGAN PPL PERTANIAN",
        "Status: Fisik Lahan Baik, Tanaman Sesuai Musim Tanam 1 | Verifikasi Petugas PPL",
        bg_color='#1e3a5f'
    )
