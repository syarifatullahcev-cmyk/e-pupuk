import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'epupuk.db')
print(f"Connecting to database: {db_path}")

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# 1. Periksa kolom lands
lands_cols = [row[1] for row in cur.execute("PRAGMA table_info(lands);").fetchall()]
print(f"Existing lands columns: {lands_cols}")

new_lands_cols = [
    ("dokumen_sertifikat_url", "VARCHAR(500)"),
    ("polygon_coords", "TEXT"),
    ("luas_verifikasi_m2", "NUMERIC(12, 2)"),
    ("status_verifikasi", "VARCHAR(30) DEFAULT 'BELUM_DIVERIFIKASI'"),
    ("catatan_verifikasi", "TEXT"),
]

for col_name, col_type in new_lands_cols:
    if col_name not in lands_cols:
        print(f"Adding column '{col_name}' to table 'lands'...")
        cur.execute(f"ALTER TABLE lands ADD COLUMN {col_name} {col_type};")
    else:
        print(f"Column '{col_name}' already exists in 'lands'.")

# 2. Periksa kolom field_surveys
surveys_cols = [row[1] for row in cur.execute("PRAGMA table_info(field_surveys);").fetchall()]
print(f"\nExisting field_surveys columns: {surveys_cols}")

if "polygon_coords" not in surveys_cols:
    print("Adding column 'polygon_coords' to table 'field_surveys'...")
    cur.execute("ALTER TABLE field_surveys ADD COLUMN polygon_coords TEXT;")
else:
    print("Column 'polygon_coords' already exists in 'field_surveys'.")

# Set default status_verifikasi untuk data yang sudah ada jika nilainya NULL
cur.execute("UPDATE lands SET status_verifikasi = 'BELUM_DIVERIFIKASI' WHERE status_verifikasi IS NULL;")

conn.commit()
print("\nMigration completed successfully!")

# Verifikasi ulang
print("\n--- UPDATED LANDS COLUMNS ---")
for col in cur.execute("PRAGMA table_info(lands);").fetchall():
    print(col)

print("\n--- UPDATED FIELD_SURVEYS COLUMNS ---")
for col in cur.execute("PRAGMA table_info(field_surveys);").fetchall():
    print(col)

conn.close()
