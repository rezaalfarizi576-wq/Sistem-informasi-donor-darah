# Backend - Donor Darah Lamongan

Modul backend berbasis FastAPI, SQLAlchemy ORM, dan MySQL untuk sistem Donor Darah Lamongan.

## Struktur Direktori

```text
backend/
├── app/                      # Aplikasi utama yang di-deploy
│   ├── main.py               # FastAPI entry point
│   ├── config.py             # Konfigurasi & pembaca .env
│   ├── database.py           # Engine & Session SQLAlchemy
│   ├── models.py             # Model tabel SQLAlchemy
│   ├── schemas.py            # Model Pydantic untuk request & response
│   ├── auth.py               # Utilitas hashing, JWT token, dan RBAC
│   └── routers/              # Modular API routers
│       ├── auth_router.py    # Endpoint autentikasi (/auth)
│       └── admin_router.py   # Endpoint admin (/admin)
│
├── mock_pmi_api/             # Mock service untuk simulasi API PMI Pusat
│   └── main.py
│
├── scripts/                  # Skrip utilitas database & CLI
│   ├── generate_dummy_pmi_dataset.py
│   ├── pmi_schema.py
│   └── import_pmi_dataset.py
│
├── dummy_pmi_donors.json     # Data contoh pendonor PMI
├── setup_database.sql        # Script pembuatan skema database MySQL
├── requirements.txt          # Dependensi Python
├── .env.example              # Template variabel lingkungan
└── README.md
```

## Persiapan & Instalasi

1. **Buat Virtual Environment:**
   ```bash
   python -m venv venv
   # Aktifkan di Windows:
   venv\Scripts\activate
   # Aktifkan di Linux/macOS:
   source venv/bin/activate
   ```

2. **Install Dependensi:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Konfigurasi Database:**
   - Salin `.env.example` ke `.env`:
     ```bash
     copy .env.example .env
     ```
   - Sesuaikan konfigurasi database MySQL di `.env`.
   - Jalankan script SQL `setup_database.sql` pada server MySQL Anda.

4. **Menjalankan Server:**
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```
   Buka dokumentasi Swagger di: `http://localhost:8000/docs`

5. **Menjalankan Mock API PMI (Opsional):**
   ```bash
   uvicorn mock_pmi_api.main:app --reload --port 8001
   ```
