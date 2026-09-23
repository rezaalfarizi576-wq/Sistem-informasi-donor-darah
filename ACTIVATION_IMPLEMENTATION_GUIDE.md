# Panduan Implementasi Account Activation dengan NIK

## Perubahan yang Telah Dilakukan

### 1. Data Layer (dummy_pmi_donors.json)
- Semua 150 donor data ditambahkan field `nik` dengan format Lamongan: `3524XXXXXXXXXXXX`
- Contoh:
  - Donor 1: NIK `3524000000000001`
  - Donor 2: NIK `3524000000000002`
  - Donor 150: NIK `3524000000000150`

### 2. Backend Model (app/models.py)
- Tambahkan kolom `nik` ke tabel `users`:
```python
nik = Column(String(16), unique=True, nullable=True, index=True)
```
- NIK bersifat unique dan indexed untuk pencarian cepat

### 3. Backend Schema (app/schemas.py)
- Update `ActivateAccount` schema:
```python
class ActivateAccount(BaseModel):
    nik: str = Field(..., min_length=16, max_length=16)
    email: EmailStr
    phone: str = Field(..., min_length=8, max_length=20)
    password: str = Field(..., min_length=6)
```

### 4. Backend Endpoint (app/routers/auth_router.py)
- Update `/auth/activate` untuk:
  - Validasi NIK (bukan email + no_hp lagi)
  - Update email donor
  - Update phone (no_hp) donor
  - Set password baru
  - Mark akun sebagai activated

### 5. Frontend Repository (auth_repository.dart)
- Update payload untuk mengirim:
  - `nik` (16 digit)
  - `email` (baru dari form)
  - `phone` (baru dari form)
  - `password` (baru dari form)

### 6. Import Script (scripts/import_pmi_dataset.py)
- Update script untuk import dummy data dengan NIK

---

## Testing Steps

### Step 1: Prepare Database
```bash
cd backend
python scripts/import_pmi_dataset.py
```
Output yang diharapkan:
```
Proses impor selesai: 150 pendonor diimpor, 0 dilewati (sudah terdaftar).
```

### Step 2: Test via Postman/cURL

**Endpoint:** `POST /auth/activate`

**Request Body:**
```json
{
  "nik": "3524000000000001",
  "email": "ahmad.new@gmail.com",
  "phone": "082123456789",
  "password": "password123"
}
```

**Expected Success Response (200):**
```json
{
  "id": 1,
  "nama": "Ahmad Rahayu",
  "email": "ahmad.new@gmail.com",
  "no_hp": "082123456789",
  "role": "donor",
  "sumber_data": "pmi_pusat",
  "is_activated": true,
  "status_aktif": true,
  "blood_type": "O",
  "rhesus": "+"
}
```

**Test Error Cases:**

1. NIK tidak ditemukan:
```json
{
  "detail": "NIK tidak ditemukan di data terdaftar PMI Lamongan"
}
```

2. Akun sudah diaktivasi:
```json
{
  "detail": "Akun sudah pernah diaktivasi, silakan login"
}
```

3. Email sudah terdaftar:
```json
{
  "detail": "Email sudah terdaftar di sistem"
}
```

### Step 3: Test Login Setelah Activation
```bash
POST /auth/login
Content-Type: application/x-www-form-urlencoded

username=ahmad.new@gmail.com&password=password123
```

Expected response:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "nama": "Ahmad Rahayu",
    "email": "ahmad.new@gmail.com"
  }
}
```

### Step 4: Test Flutter App

1. Buka Activate Account Screen
2. Input data:
   - NIK: `3524000000000001` (atau dari list donor terdaftar)
   - Email: Email baru (belum terdaftar)
   - No HP: Nomor HP baru (belum terdaftar)
   - Password: Minimal 6 karakter
3. Klik "Aktivasi Akun"
4. Expected: Success snackbar + pop back to login
5. Login dengan email dan password baru

---

## Complete Flow Diagram

```
Flutter App (Activate Screen)
    |
    +-- Input: NIK + Email Baru + Phone Baru + Password
    |
    v
POST /auth/activate
    |
    +-- Backend Steps:
    |   1. Find donor by NIK
    |   2. Validate: sumber_data == "pmi_pusat"
    |   3. Validate: is_activated == False
    |   4. Check email tidak duplikat
    |   5. Check phone tidak duplikat
    |   6. Update email, no_hp, password_hash
    |   7. Set is_activated = True
    |   8. Save to DB
    |
    v
Response: UserModel (activated)
    |
    v
Flutter: Show success + navigate to login
    |
    v
POST /auth/login (dengan email dan password baru)
    |
    v
Response: JWT Token
    |
    v
User berhasil login dan bisa akses aplikasi sebagai donor
```

---

## Sample Test NIK Data

| No | NIK | Nama |
|----|-----|------|
| 1 | 3524000000000001 | Ahmad Rahayu |
| 2 | 3524000000000002 | Bayu Pratama |
| 3 | 3524000000000003 | Eko Handoko |
| ... | ... | ... |
| 150 | 3524000000000150 | [Last donor] |

---

## Important Notes

1. NIK adalah identifier utama untuk aktivasi akun donor dari PMI
2. Email dan phone akan di-update selama proses aktivasi
3. Akun hanya bisa diaktivasi 1x - setelah itu harus login langsung
4. Password baru akan menggantikan password dummy dari impor
5. sumber_data = "pmi_pusat" menandakan akun berasal dari impor PMI

---

## Next Steps

1. Run `python scripts/import_pmi_dataset.py` untuk populate database
2. Test via Postman/cURL sesuai dokumentasi di atas
3. Test via Flutter app
4. Verify database records menggunakan phpMyAdmin atau MySQL CLI
