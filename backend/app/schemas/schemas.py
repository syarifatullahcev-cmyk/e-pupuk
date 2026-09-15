from typing import Optional, List, Any
from datetime import datetime, date
from decimal import Decimal
from pydantic import BaseModel, EmailStr, Field

# --- Auth ---
class LoginRequest(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    username: str
    nama: Optional[str] = None
    farmer_id: Optional[int] = None

class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None

# --- User ---
class UserBase(BaseModel):
    username: str
    email: EmailStr
    role: str
    is_active: bool = True

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# --- Farmer Group ---
class FarmerGroupResponse(BaseModel):
    id: int
    nama_kelompok: str
    wilayah: str
    ketua_id: Optional[int] = None

    class Config:
        from_attributes = True

# --- Commodity & Fertilizer ---
class CommodityResponse(BaseModel):
    id: int
    nama_komoditas: str
    standar_kebutuhan_kg_per_ha: Decimal

    class Config:
        from_attributes = True

class FertilizerResponse(BaseModel):
    id: int
    nama_pupuk: str
    satuan: str

    class Config:
        from_attributes = True

# --- Farmer ---
class FarmerBase(BaseModel):
    nama: str
    nik: str
    kontak: Optional[str] = None
    alamat: str
    farmer_group_id: Optional[int] = None

class FarmerCreate(FarmerBase):
    user_id: int
    foto_ktp_url: Optional[str] = None

class FarmerUpdate(BaseModel):
    nama: Optional[str] = None
    kontak: Optional[str] = None
    alamat: Optional[str] = None
    farmer_group_id: Optional[int] = None

class FarmerResponse(FarmerBase):
    id: int
    user_id: int
    foto_ktp_url: Optional[str] = None
    tanggal_registrasi: Optional[date] = None
    farmer_group: Optional[FarmerGroupResponse] = None

    class Config:
        from_attributes = True

# --- Land ---
class LandBase(BaseModel):
    lokasi_deskripsi: Optional[str] = None
    alamat_lahan: str
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    luas_m2: Decimal
    commodity_id: Optional[int] = None
    status_kepemilikan: str = "MILIK"

class LandCreate(LandBase):
    farmer_id: Optional[int] = None
    foto_lahan_url: Optional[str] = None

class LandUpdate(BaseModel):
    lokasi_deskripsi: Optional[str] = None
    alamat_lahan: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    luas_m2: Optional[Decimal] = None
    commodity_id: Optional[int] = None
    status_kepemilikan: Optional[str] = None
    foto_lahan_url: Optional[str] = None

class LandResponse(LandBase):
    id: int
    farmer_id: int
    foto_lahan_url: Optional[str] = None
    tanggal_registrasi: Optional[date] = None
    commodity: Optional[CommodityResponse] = None

    class Config:
        from_attributes = True

# --- Field Survey ---
class FieldSurveyCreate(BaseModel):
    kondisi_fisik_lahan: str # BAIK, CUKUP, TIDAK_LAYAK
    keterangan_fisik_lahan: Optional[str] = None
    kondisi_tanaman: str # SESUAI, TIDAK_SESUAI
    keterangan_tanaman: Optional[str] = None
    luas_lahan_aktual_m2: Optional[Decimal] = None
    catatan_ppl: Optional[str] = None
    rekomendasi: str # SETUJU, TOLAK
    foto_survei_urls: Optional[List[str]] = []

class FieldSurveyResponse(BaseModel):
    id: int
    application_id: int
    ppl_id: int
    tanggal_survei: datetime
    kondisi_fisik_lahan: str
    keterangan_fisik_lahan: Optional[str] = None
    kondisi_tanaman: str
    keterangan_tanaman: Optional[str] = None
    luas_lahan_aktual_m2: Optional[Decimal] = None
    foto_survei_urls: Optional[Any] = None
    catatan_ppl: Optional[str] = None
    rekomendasi: str
    ppl_nama: Optional[str] = None

    class Config:
        from_attributes = True

# --- Application ---
class ApplicationCreate(BaseModel):
    land_id: int
    fertilizer_id: int
    jumlah_diajukan: Decimal
    alamat_lahan: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None

class ApplicationAdminVerifyRequest(BaseModel):
    action: str # APPROVE, PERBAIKAN, TOLAK
    catatan: Optional[str] = None

class ApplicationAssignPPLRequest(BaseModel):
    ppl_id: int
    catatan: Optional[str] = None

class ApplicationFinalApproveRequest(BaseModel):
    action: str # APPROVE, REJECT
    jumlah_disetujui: Optional[Decimal] = None
    catatan: Optional[str] = None

class ApplicationResponse(BaseModel):
    id: int
    farmer_id: int
    land_id: int
    fertilizer_id: int
    jumlah_diajukan: Decimal
    kuota_maksimal: Optional[Decimal] = None
    status: str
    foto_ktp_snapshot_url: Optional[str] = None
    foto_lahan_snapshot_url: Optional[str] = None
    alamat_lahan: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    tanggal_pengajuan: datetime
    admin_verifier_id: Optional[int] = None
    admin_verified_at: Optional[datetime] = None
    catatan_admin_berkas: Optional[str] = None
    assigned_ppl_id: Optional[int] = None
    assigned_at: Optional[datetime] = None
    catatan_penugasan: Optional[str] = None
    final_approver_id: Optional[int] = None
    final_approved_at: Optional[datetime] = None
    jumlah_disetujui: Optional[Decimal] = None
    catatan_final_admin: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    # Nested objects
    farmer: Optional[FarmerResponse] = None
    land: Optional[LandResponse] = None
    fertilizer: Optional[FertilizerResponse] = None
    survey: Optional[FieldSurveyResponse] = None

    class Config:
        from_attributes = True

# --- Distribution & QR ---
class DistributionResponse(BaseModel):
    id: int
    application_id: int
    batch_id: Optional[int] = None
    jumlah_disalurkan: Decimal
    status_penyaluran: str
    qr_code_hash: str
    tanggal_penyaluran: Optional[datetime] = None
    created_at: datetime
    application: Optional[ApplicationResponse] = None

    class Config:
        from_attributes = True

class QRScanRequest(BaseModel):
    qr_token: str
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None

class QRScanResponse(BaseModel):
    success: bool
    status: str
    message: str
    distribution: Optional[DistributionResponse] = None

# --- Notification ---
class NotificationResponse(BaseModel):
    id: int
    judul: str
    pesan: str
    tipe: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# --- Audit Log ---
class AuditLogResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    action: str
    resource: str
    resource_id: Optional[int] = None
    details: Optional[str] = None
    ip_address: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- Dashboard Stats ---
class DashboardStatsAdmin(BaseModel):
    total_pengajuan: int
    menunggu_verifikasi_berkas: int
    perlu_survei_ppl: int
    menunggu_persetujuan_akhir: int
    disetujui: int
    ditolak: int
    total_petani: int
    total_lahan_m2: Decimal
    kuota_urea_kg: Decimal
    kuota_npk_kg: Decimal

class DashboardStatsPetani(BaseModel):
    total_pengajuan: int
    aktif: int
    disetujui: int
    tersalurkan: int
    total_lahan: int
    kuota_tersedia_urea: Decimal
    kuota_tersedia_npk: Decimal
