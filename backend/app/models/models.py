import datetime
from sqlalchemy import (
    Column, Integer, String, Text, Numeric, Boolean,
    DateTime, Date, ForeignKey, Enum as SQLEnum, JSON
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class UserRole:
    PETANI = "PETANI"
    PPL = "PPL"
    ADMIN = "ADMIN"
    PIMPINAN = "PIMPINAN"

class ApplicationStatus:
    DIAJUKAN = "DIAJUKAN"
    MENUNGGU_VERIFIKASI_BERKAS = "MENUNGGU_VERIFIKASI_BERKAS"
    PERLU_PERBAIKAN_BERKAS = "PERLU_PERBAIKAN_BERKAS"
    BERKAS_TERVERIFIKASI = "BERKAS_TERVERIFIKASI"
    DITUGASKAN_KE_PPL = "DITUGASKAN_KE_PPL"
    SURVEI_LAPANGAN = "SURVEI_LAPANGAN"
    MENUNGGU_PERSETUJUAN_AKHIR = "MENUNGGU_PERSETUJUAN_AKHIR"
    DISETUJUI = "DISETUJUI"
    DITOLAK_BERKAS = "DITOLAK_BERKAS"
    DITOLAK_LAPANGAN = "DITOLAK_LAPANGAN"
    DIJADWALKAN_DISTRIBUSI = "DIJADWALKAN_DISTRIBUSI"
    TERSALURKAN = "TERSALURKAN"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(150), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(SQLEnum(UserRole.PETANI, UserRole.PPL, UserRole.ADMIN, UserRole.PIMPINAN), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    farmer_profile = relationship("Farmer", back_populates="user", uselist=False)
    assigned_surveys = relationship("FieldSurvey", back_populates="ppl")
    notifications = relationship("Notification", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="user")

class FarmerGroup(Base):
    __tablename__ = "farmer_groups"

    id = Column(Integer, primary_key=True, index=True)
    nama_kelompok = Column(String(150), nullable=False)
    ketua_id = Column(Integer, nullable=True)
    wilayah = Column(String(200), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    farmers = relationship("Farmer", back_populates="farmer_group")

class Farmer(Base):
    __tablename__ = "farmers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    nama = Column(String(150), nullable=False)
    nik = Column(String(20), unique=True, nullable=False, index=True)
    kontak = Column(String(20), nullable=True)
    alamat = Column(Text, nullable=False)
    foto_ktp_url = Column(String(500), nullable=True)
    tanggal_registrasi = Column(Date, server_default=func.current_date())
    farmer_group_id = Column(Integer, ForeignKey("farmer_groups.id", ondelete="SET NULL"), nullable=True)

    # Relationships
    user = relationship("User", back_populates="farmer_profile")
    farmer_group = relationship("FarmerGroup", back_populates="farmers")
    lands = relationship("Land", back_populates="farmer", cascade="all, delete-orphan")
    applications = relationship("Application", back_populates="farmer")

class Commodity(Base):
    __tablename__ = "commodities"

    id = Column(Integer, primary_key=True, index=True)
    nama_komoditas = Column(String(100), nullable=False)
    standar_kebutuhan_kg_per_ha = Column(Numeric(10, 2), nullable=False)

    lands = relationship("Land", back_populates="commodity")

class Fertilizer(Base):
    __tablename__ = "fertilizers"

    id = Column(Integer, primary_key=True, index=True)
    nama_pupuk = Column(String(100), nullable=False)
    satuan = Column(String(20), default="kg")

    batches = relationship("FertilizerBatch", back_populates="fertilizer")
    applications = relationship("Application", back_populates="fertilizer")

class Land(Base):
    __tablename__ = "lands"

    id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmers.id", ondelete="CASCADE"), nullable=False)
    lokasi_deskripsi = Column(String(300), nullable=True)
    alamat_lahan = Column(Text, nullable=False)
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    luas_m2 = Column(Numeric(12, 2), nullable=False)
    commodity_id = Column(Integer, ForeignKey("commodities.id", ondelete="SET NULL"), nullable=True)
    status_kepemilikan = Column(SQLEnum("MILIK", "GARAP", "SEWA"), default="MILIK")
    foto_lahan_url = Column(String(500), nullable=True)
    tanggal_registrasi = Column(Date, server_default=func.current_date())

    # Relationships
    farmer = relationship("Farmer", back_populates="lands")
    commodity = relationship("Commodity", back_populates="lands")
    applications = relationship("Application", back_populates="land")

class Application(Base):
    __tablename__ = "applications"

    id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmers.id", ondelete="CASCADE"), nullable=False)
    land_id = Column(Integer, ForeignKey("lands.id", ondelete="CASCADE"), nullable=False)
    fertilizer_id = Column(Integer, ForeignKey("fertilizers.id"), nullable=False)
    jumlah_diajukan = Column(Numeric(10, 2), nullable=False)
    kuota_maksimal = Column(Numeric(10, 2), nullable=True)
    status = Column(
        SQLEnum(
            ApplicationStatus.DIAJUKAN,
            ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
            ApplicationStatus.PERLU_PERBAIKAN_BERKAS,
            ApplicationStatus.BERKAS_TERVERIFIKASI,
            ApplicationStatus.DITUGASKAN_KE_PPL,
            ApplicationStatus.SURVEI_LAPANGAN,
            ApplicationStatus.MENUNGGU_PERSETUJUAN_AKHIR,
            ApplicationStatus.DISETUJUI,
            ApplicationStatus.DITOLAK_BERKAS,
            ApplicationStatus.DITOLAK_LAPANGAN,
            ApplicationStatus.DIJADWALKAN_DISTRIBUSI,
            ApplicationStatus.TERSALURKAN
        ),
        default=ApplicationStatus.MENUNGGU_VERIFIKASI_BERKAS,
        nullable=False,
        index=True
    )
    foto_ktp_snapshot_url = Column(String(500), nullable=True)
    foto_lahan_snapshot_url = Column(String(500), nullable=True)
    alamat_lahan = Column(Text, nullable=True)
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    tanggal_pengajuan = Column(DateTime, server_default=func.now())
    admin_verifier_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    admin_verified_at = Column(DateTime, nullable=True)
    catatan_admin_berkas = Column(Text, nullable=True)
    assigned_ppl_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    assigned_at = Column(DateTime, nullable=True)
    catatan_penugasan = Column(Text, nullable=True)
    final_approver_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    final_approved_at = Column(DateTime, nullable=True)
    jumlah_disetujui = Column(Numeric(10, 2), nullable=True)
    catatan_final_admin = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    farmer = relationship("Farmer", back_populates="applications")
    land = relationship("Land", back_populates="applications")
    fertilizer = relationship("Fertilizer", back_populates="applications")
    admin_verifier = relationship("User", foreign_keys=[admin_verifier_id])
    assigned_ppl = relationship("User", foreign_keys=[assigned_ppl_id])
    final_approver = relationship("User", foreign_keys=[final_approver_id])
    survey = relationship("FieldSurvey", back_populates="application", uselist=False, cascade="all, delete-orphan")
    distribution = relationship("Distribution", back_populates="application", uselist=False, cascade="all, delete-orphan")

class FieldSurvey(Base):
    __tablename__ = "field_surveys"

    id = Column(Integer, primary_key=True, index=True)
    application_id = Column(Integer, ForeignKey("applications.id", ondelete="CASCADE"), unique=True, nullable=False)
    ppl_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    tanggal_survei = Column(DateTime, server_default=func.now())
    kondisi_fisik_lahan = Column(SQLEnum("BAIK", "CUKUP", "TIDAK_LAYAK"), nullable=False)
    keterangan_fisik_lahan = Column(Text, nullable=True)
    kondisi_tanaman = Column(SQLEnum("SESUAI", "TIDAK_SESUAI"), nullable=False)
    keterangan_tanaman = Column(Text, nullable=True)
    luas_lahan_aktual_m2 = Column(Numeric(12, 2), nullable=True)
    foto_survei_urls = Column(JSON, nullable=True)
    catatan_ppl = Column(Text, nullable=True)
    rekomendasi = Column(SQLEnum("SETUJU", "TOLAK"), nullable=False)

    # Relationships
    application = relationship("Application", back_populates="survey")
    ppl = relationship("User", back_populates="assigned_surveys")

class FertilizerBatch(Base):
    __tablename__ = "fertilizer_batches"

    id = Column(Integer, primary_key=True, index=True)
    batch_code = Column(String(50), unique=True, nullable=False)
    fertilizer_id = Column(Integer, ForeignKey("fertilizers.id"), nullable=False)
    production_date = Column(Date, nullable=True)
    expired_date = Column(Date, nullable=False)
    stok_kg = Column(Numeric(12, 2), default=0)

    fertilizer = relationship("Fertilizer", back_populates="batches")
    distributions = relationship("Distribution", back_populates="batch")

class Distribution(Base):
    __tablename__ = "distributions"

    id = Column(Integer, primary_key=True, index=True)
    application_id = Column(Integer, ForeignKey("applications.id", ondelete="CASCADE"), unique=True, nullable=False)
    batch_id = Column(Integer, ForeignKey("fertilizer_batches.id", ondelete="SET NULL"), nullable=True)
    jumlah_disalurkan = Column(Numeric(10, 2), nullable=False)
    status_penyaluran = Column(SQLEnum("MENUNGGU_PENGAMBILAN", "SELESAI", "BATAL"), default="MENUNGGU_PENGAMBILAN")
    qr_code_hash = Column(String(255), unique=True, nullable=False)
    tanggal_penyaluran = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    application = relationship("Application", back_populates="distribution")
    batch = relationship("FertilizerBatch", back_populates="distributions")
    scans = relationship("QRScan", back_populates="distribution", cascade="all, delete-orphan")

class QRScan(Base):
    __tablename__ = "qr_scans"

    id = Column(Integer, primary_key=True, index=True)
    distribution_id = Column(Integer, ForeignKey("distributions.id", ondelete="CASCADE"), nullable=False)
    scanner_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    scan_timestamp = Column(DateTime, server_default=func.now())
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    validation_status = Column(SQLEnum("VALID", "EXPIRED", "ALREADY_CLAIMED", "INVALID"), nullable=False)

    distribution = relationship("Distribution", back_populates="scans")
    scanner = relationship("User")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    judul = Column(String(200), nullable=False)
    pesan = Column(Text, nullable=False)
    tipe = Column(SQLEnum("INFO", "WARNING", "SUCCESS", "DANGER"), default="INFO")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="notifications")

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String(100), nullable=False)
    resource = Column(String(100), nullable=False)
    resource_id = Column(Integer, nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="audit_logs")
