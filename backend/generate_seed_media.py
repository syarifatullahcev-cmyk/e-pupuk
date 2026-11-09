"""Generate clearly labeled fictional media for local demonstrations only."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
DEFAULT_OUTPUT_DIR = BASE_DIR / "demo_media"

SEED_MEDIA = (
    ("ktp", "sample_ktp_budi.jpg"),
    ("ktp", "sample_ktp_siti.jpg"),
    ("lahan", "sample_sawah_mojosari.jpg"),
    ("lahan", "sample_jagung_trowulan.jpg"),
    ("survei", "sample_survei_lahan1.jpg"),
)


def _draw_dummy_banner(draw: ImageDraw.ImageDraw, text: str, bounds: tuple[int, int, int, int]) -> None:
    left, top, right, bottom = bounds
    draw.rectangle(bounds, fill="#b91c1c")
    draw.text(
        (left + 12, top + 8),
        text,
        fill="#ffffff",
        font=ImageFont.load_default(),
    )


def create_ktp_image(
    filename: Path,
    name: str,
    nik: str,
    address: str,
) -> None:
    img = Image.new("RGB", (800, 500), color="#0f766e")
    draw = ImageDraw.Draw(img)
    draw.rectangle([20, 20, 780, 480], fill="#e0f2fe", outline="#0369a1", width=4)
    draw.rectangle([20, 20, 780, 90], fill="#0284c7")
    draw.text((250, 30), "REPUBLIK INDONESIA", fill="#ffffff")
    draw.text((230, 55), "PROVINSI JAWA TIMUR - KAB. MOJOKERTO", fill="#fef08a")
    draw.rectangle([580, 120, 750, 360], fill="#bae6fd", outline="#0284c7", width=3)
    draw.ellipse([630, 160, 700, 230], fill="#0284c7")
    draw.polygon([(600, 340), (665, 250), (730, 340)], fill="#0284c7")
    draw.text((615, 370), "ILUSTRASI", fill="#0369a1")
    draw.text((50, 120), f"NIK            : {nik}", fill="#0f172a")
    draw.text((50, 165), f"Nama           : {name}", fill="#0f172a")
    draw.text((50, 210), "Tempat/Tgl Lahir: CONTOH", fill="#0f172a")
    draw.text((50, 255), "Jenis Kelamin  : CONTOH", fill="#0f172a")
    draw.text((50, 300), f"Alamat         : {address}", fill="#0f172a")
    draw.text((50, 345), "Data lain      : TIDAK VALID", fill="#0f172a")
    _draw_dummy_banner(
        draw,
        "DUMMY / CONTOH - BUKAN KTP RESMI - DILARANG UNTUK VERIFIKASI",
        (20, 425, 780, 480),
    )
    filename.parent.mkdir(parents=True, exist_ok=True)
    img.save(filename, quality=92)


def create_landscape_image(
    filename: Path,
    title: str,
    subtitle: str,
    bg_color: str = "#15803d",
) -> None:
    img = Image.new("RGB", (900, 600), color=bg_color)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 900, 250], fill="#7dd3fc")
    draw.ellipse([700, 40, 800, 140], fill="#fde047")
    draw.polygon([(50, 250), (250, 120), (450, 250)], fill="#047857")
    draw.polygon([(350, 250), (600, 90), (850, 250)], fill="#065f46")
    draw.polygon([(0, 250), (900, 250), (900, 600), (0, 600)], fill="#16a34a")
    for y in range(280, 580, 35):
        draw.line([(0, y), (900, y + 20)], fill="#15803d", width=5)

    draw.rectangle([40, 460, 860, 560], fill="#0f172a")
    draw.text((60, 480), title, fill="#22c55e")
    draw.text((60, 515), subtitle, fill="#f8fafc")
    _draw_dummy_banner(
        draw,
        "DUMMY / CONTOH - ILUSTRASI, BUKAN BUKTI LAPANGAN",
        (0, 0, 900, 55),
    )
    filename.parent.mkdir(parents=True, exist_ok=True)
    img.save(filename, quality=90)


def generate_seed_media(output_dir: Path) -> None:
    output_dir = output_dir.resolve()
    existing_files = [
        output_dir / category / filename
        for category, filename in SEED_MEDIA
        if (output_dir / category / filename).exists()
    ]
    if existing_files:
        paths = "\n".join(f"  - {path}" for path in existing_files)
        raise FileExistsError(
            "Refusing to overwrite existing files. Choose a new empty output "
            f"directory:\n{paths}"
        )

    print(
        "PERINGATAN: aset fiktif untuk demo lokal; tidak sah untuk verifikasi "
        "dan bukan bukti identitas atau lapangan."
    )
    for category in ("ktp", "lahan", "survei"):
        (output_dir / category).mkdir(parents=True, exist_ok=True)

    create_ktp_image(
        output_dir / "ktp" / "sample_ktp_budi.jpg",
        "PETANI CONTOH 1",
        "0000000000000001",
        "ALAMAT CONTOH 1",
    )
    create_ktp_image(
        output_dir / "ktp" / "sample_ktp_siti.jpg",
        "PETANI CONTOH 2",
        "0000000000000002",
        "ALAMAT CONTOH 2",
    )
    create_landscape_image(
        output_dir / "lahan" / "sample_sawah_mojosari.jpg",
        "DUMMY - ILUSTRASI LAHAN PERTANIAN",
        "Data lokasi dan luas hanya contoh, bukan hasil pengukuran.",
        bg_color="#14532d",
    )
    create_landscape_image(
        output_dir / "lahan" / "sample_jagung_trowulan.jpg",
        "DUMMY - ILUSTRASI KEBUN",
        "Data lokasi dan luas hanya contoh, bukan bukti kepemilikan.",
        bg_color="#166534",
    )
    create_landscape_image(
        output_dir / "survei" / "sample_survei_lahan1.jpg",
        "DUMMY - ILUSTRASI SURVEI",
        "Bukan dokumentasi petugas atau survei lapangan nyata.",
        bg_color="#1e3a5f",
    )


def validate_output_directory(output_dir: Path, allow_uploads: bool = False) -> Path:
    resolved_dir = output_dir.resolve()
    try:
        resolved_dir.relative_to(UPLOAD_DIR.resolve())
    except ValueError:
        return resolved_dir

    if not allow_uploads:
        raise ValueError(
            "output directory is inside backend/uploads; choose a separate "
            "demo directory or explicitly allow an isolated demo upload folder"
        )
    return resolved_dir


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate explicitly fictional demo media. Never use for "
            "verification or production."
        )
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Target directory; defaults to {DEFAULT_OUTPUT_DIR}.",
    )
    parser.add_argument(
        "--allow-uploads",
        action="store_true",
        help="Allow writing seed-compatible demo files under backend/uploads.",
    )
    args = parser.parse_args()
    try:
        output_dir = validate_output_directory(args.output_dir, args.allow_uploads)
        generate_seed_media(output_dir)
    except (FileExistsError, ValueError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
