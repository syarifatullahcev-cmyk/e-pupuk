from sqlalchemy import inspect, text

from app.core.database import engine


MISSING_COLUMNS = {
    "lands": {
        "dokumen_sertifikat_url": "VARCHAR(500) NULL",
        "polygon_coords": "LONGTEXT NULL",
        "luas_verifikasi_m2": "DECIMAL(12, 2) NULL",
        "status_verifikasi": (
            "ENUM('BELUM_DIVERIFIKASI','TERVERIFIKASI',"
            "'PERLU_SURVEI_ULANG','DITOLAK') "
            "DEFAULT 'BELUM_DIVERIFIKASI'"
        ),
        "catatan_verifikasi": "TEXT NULL",
    },
    "field_surveys": {
        "polygon_coords": "LONGTEXT NULL",
    },
    "qr_scans": {
        "foto_pupuk_url": "VARCHAR(500) NULL",
    },
}


def migrate() -> None:
    if engine.dialect.name != "mysql":
        raise RuntimeError(
            f"This migration requires MySQL; configured dialect is {engine.dialect.name}."
        )

    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    with engine.begin() as connection:
        for table_name, columns in MISSING_COLUMNS.items():
            if table_name not in existing_tables:
                raise RuntimeError(f"Required table '{table_name}' does not exist.")

            existing_columns = {
                column["name"] for column in inspector.get_columns(table_name)
            }
            for column_name, definition in columns.items():
                if column_name in existing_columns:
                    print(f"Already present: {table_name}.{column_name}")
                    continue

                statement = (
                    f"ALTER TABLE `{table_name}` ADD COLUMN "
                    f"`{column_name}` {definition}"
                )
                connection.execute(text(statement))
                print(f"Added: {table_name}.{column_name}")

            inspector.clear_cache()

        distribution_indexes = inspector.get_indexes("distributions")
        if not any(
            not index.get("unique")
            and index.get("column_names") == ["application_id"]
            for index in distribution_indexes
        ):
            connection.execute(
                text(
                    "ALTER TABLE `distributions` "
                    "ADD INDEX `ix_distributions_application_id` (`application_id`)"
                )
            )
            print("Added non-unique application index to distributions.")

        inspector.clear_cache()
        distribution_indexes = inspector.get_indexes("distributions")
        for index in distribution_indexes:
            if index.get("unique") and index.get("column_names") == ["application_id"]:
                connection.execute(
                    text(f"ALTER TABLE `distributions` DROP INDEX `{index['name']}`")
                )
                print("Removed unique application constraint from distributions.")
                break

        inspector.clear_cache()
        role_columns = [
            column
            for column in inspector.get_columns("users")
            if column["name"] == "role"
        ]
        if not role_columns:
            raise RuntimeError("Required column 'users.role' does not exist.")
        role_column = role_columns[0]
        role_values = getattr(role_column["type"], "enums", [])
        if "PIMPINAN" in role_values:
            pimpinan_users = connection.execute(
                text("SELECT COUNT(*) FROM `users` WHERE `role` = 'PIMPINAN'")
            ).scalar_one()
            if pimpinan_users:
                raise RuntimeError(
                    f"Cannot remove PIMPINAN role: {pimpinan_users} user account(s) "
                    "still use it. No user records were changed."
                )
            connection.execute(
                text(
                    "ALTER TABLE `users` MODIFY COLUMN `role` "
                    "ENUM('PETANI','PPL','ADMIN') NOT NULL"
                )
            )
            print("Removed unused PIMPINAN role from users.")


if __name__ == "__main__":
    migrate()
