# Tourist Attraction KNN Backend

FastAPI service สำหรับให้ Flutter ใช้โมเดล Content-Based KNN ที่เทรนและ
export จาก Colab แล้ว

## Model Artifact

Backend โหลดไฟล์:

```text
backend/models/travel_recommendation_knn_model_v1.pkl
```

ไฟล์นี้บันทึก feature matrix, encoder, weights, metadata และผล evaluation
จาก Colab โดยใช้ `scikit-learn 1.6.1` ดังนั้น dependency ถูกล็อกให้ตรงกับ
ไฟล์ `.pkl`

## Run

รันจาก project root:

```powershell
uv run --python 3.12 --with-requirements backend\requirements.txt uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

API จะเปิดที่:

```text
http://127.0.0.1:8000
```

## Endpoints

ตรวจว่า model โหลดสำเร็จ:

```text
GET http://127.0.0.1:8000/health
```

ขอผลแนะนำ:

```text
POST http://127.0.0.1:8000/recommend
```

ตัวอย่าง body รองรับหลายตัวเลือกและจังหวัด optional:

```json
{
  "regions": ["ภาคใต้"],
  "provinces": ["ภูเก็ต"],
  "categories": ["ธรรมชาติ"],
  "types": ["จุดชมวิว"],
  "activities": ["ชมวิว", "ถ่ายรูป"]
}
```

ถ้าไม่เลือกจังหวัดให้ส่ง:

```json
"provinces": []
```

API จัดอันดับสถานที่ทั้งหมดที่ตรงความสนใจในพื้นที่ที่เลือก และส่ง
`sourceRow` กลับไปให้ Flutter หยิบข้อมูลปัจจุบันจาก Firestore จึงยังใช้รูป
YouTube และ `videoUrls` ที่อัปเดตใน Firebase ได้

## Flutter URL

Flutter web ที่รันบนคอมจะใช้ค่าปริยาย:

```text
http://127.0.0.1:8000
```

เมื่อลองบนมือถือจริง ให้ระบุ IP ของคอมที่มือถือเข้าถึงได้:

```powershell
flutter run --dart-define=RECOMMENDATION_API_URL=http://YOUR_COMPUTER_IP:8000
```
