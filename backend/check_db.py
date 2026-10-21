import sqlite3

conn = sqlite3.connect('epupuk.db')
cur = conn.cursor()

print("--- LANDS COLUMNS ---")
for col in cur.execute("PRAGMA table_info(lands);").fetchall():
    print(col)

print("\n--- FIELD_SURVEYS COLUMNS ---")
for col in cur.execute("PRAGMA table_info(field_surveys);").fetchall():
    print(col)

lands_count = cur.execute("SELECT count(*) FROM lands;").fetchone()[0]
surveys_count = cur.execute("SELECT count(*) FROM field_surveys;").fetchone()[0]
apps_count = cur.execute("SELECT count(*) FROM applications;").fetchone()[0]
print(f"\nStats: lands={lands_count}, surveys={surveys_count}, apps={apps_count}")
conn.close()
