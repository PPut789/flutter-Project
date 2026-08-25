# Tourist Attraction KNN Backend

FastAPI service สำหรับให้ Flutter ใช้โมเดล Content-Based KNN ที่เทรนและ
export จาก Colab แล้ว

## Model Artifact

Backend โหลดไฟล์:

```text
backend/models/travel_recommendation_knn_model_v2.pkl
```

ไฟล์ v2 เป็น artifact ที่มี fitted `NearestNeighbors` model จริงจาก
`model.fit(...)` แล้ว ไม่ใช่แค่ feature matrix สำหรับคำนวณชั่วคราว

แนวทาง feature ของ v2:

- One-hot: `region`, `province`, `category`, `type`
- Multi-label: `activity`
- TF-IDF: `nameTh`, `nameEn`, `description`, `highlight`, `tags`
- Weight: region 2.0, province 2.5, category 3.0, type 3.0, activity 4.0, text 1.4

Artifact เก็บ 2 โมเดล:

- `model_with_province` ใช้เมื่อผู้ใช้เลือกจังหวัด
- `model_without_province` ใช้เมื่อผู้ใช้ไม่เลือกจังหวัด เพื่อให้จังหวัดเป็น optional ตาม flow ของแอป

ไฟล์ `.pkl` export จาก Colab โดยใช้ `scikit-learn 1.6.1` ดังนั้น dependency
ถูกล็อกให้ตรงกับไฟล์โมเดล

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
  "activities": ["ชมวิว", "ถ่ายรูป"],
  "keywords": ["ทะเล", "วิวสวย"],
  "limit": 20
}
```

ถ้าไม่เลือกจังหวัดให้ส่ง:

```json
"provinces": []
```

ถ้าต้องการให้การค้นหาด้วย input เดิมไม่เจอสถานที่เดิม ให้ส่ง `sourceRow`
ของสถานที่ที่เคยเห็นแล้วมาใน `exclude_source_rows`:

```json
{
  "regions": ["ภาคใต้"],
  "provinces": [],
  "categories": ["ธรรมชาติ"],
  "types": ["จุดชมวิว"],
  "activities": ["ชมวิว", "ถ่ายรูป"],
  "exclude_source_rows": [403, 549, 1129],
  "limit": 20
}
```

API ใช้ KNN จัดอันดับจากความคล้ายคลึงของ feature และ text keywords
แต่ยังล็อกพื้นที่ตาม `region` และ `province` ที่ผู้ใช้เลือก จากนั้นส่ง
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
