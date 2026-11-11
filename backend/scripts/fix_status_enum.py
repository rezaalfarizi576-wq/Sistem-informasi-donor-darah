import os
import sys
sys.path.insert(0, os.path.abspath('backend'))
from app.database import engine
from sqlalchemy import text

with engine.connect() as conn:
    # 1. Update ENUM definition to include 'selesai'
    conn.execute(text("ALTER TABLE blood_requests MODIFY COLUMN status ENUM('menunggu','diproses','terpenuhi','kedaluwarsa','dibatalkan','selesai') NOT NULL DEFAULT 'menunggu'"))
    
    # 2. Update record 4 to 'selesai'
    conn.execute(text("UPDATE blood_requests SET status = 'selesai' WHERE id = 4"))
    
    conn.commit()
    print("SUCCESS: blood_requests status updated and enum altered.")

    res = conn.execute(text("SELECT id, status, patient_name FROM blood_requests")).fetchall()
    print("CURRENT ROWS:", res)

