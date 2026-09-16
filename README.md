# Donor Darah Lamongan

Sistem informasi dan koordinasi donor darah untuk wilayah Lamongan, menghubungkan pendonor, pemohon darah (requester), dan admin PMI.

## Arsitektur Modular

Repository ini menggunakan pendekatan monorepo sederhana dengan pemisahan modular antara Backend dan Frontend:

```text
donor-darah-lamongan/                        ← Root repository
│
├── backend/                                 ← Python + FastAPI + MySQL
│   ├── app/                                 Aplikasi utama (yang di-deploy)
│   │   ├── main.py                          Entry point FastAPI
│   │   ├── config.py                        Konfigurasi & pembaca .env
│   │   ├── database.py                      Koneksi SQLAlchemy & SessionLocal
│   │   ├── models.py                        Model ORM database
│   │   ├── schemas.py                       Skema validasi Pydantic
│   │   ├── auth.py                          Hashing, JWT, & RBAC
│   │   └── routers/                         Endpoint router modular
│   │       ├── auth_router.py               Route autentikasi (/auth/*)
│   │       └── admin_router.py              Route manajemen admin (/admin/*)
│   │
│   ├── mock_pmi_api/                        Simulasi API PMI Pusat
│   │   └── main.py
│   │
│   ├── scripts/                             Skrip CLI & utility data
│   │   ├── generate_dummy_pmi_dataset.py
│   │   ├── pmi_schema.py
│   │   └── import_pmi_dataset.py
│   │
│   ├── dummy_pmi_donors.json
│   ├── setup_database.sql
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
│
└── frontend/                                ← Flutter (Android, iOS, Web)
    ├── lib/
    │   ├── main.dart                        Entry point Flutter & bootstrap
    │   ├── core/                            Infrastruktur & konfigurasi teknis
    │   ├── data/                            Model data & repositori API
    │   ├── features/                        Fitur berbasis peran (auth, requester, donor, admin)
    │   ├── shared/                          Shared widgets, constants, and enums
    │   └── routes/app_router.dart           Pengaturan rute & navigasi
    │
    ├── assets/
    ├── test/
    ├── pubspec.yaml
    └── .env.example
```

## Memulai Proyek

### 1. Backend
Lihat panduan lengkap di [backend/README.md](file:///backend/README.md).
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 2. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```
