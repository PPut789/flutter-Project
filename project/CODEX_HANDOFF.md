# Codex Handoff Note

เอกสารนี้สรุปสถานะโปรเจกต์สำหรับเปิดทำงานต่อใน Codex บนเครื่องอื่น
เพราะประวัติแชทอาจไม่ตามไปเสมอ

## Current Status

- Flutter app prototype ทำงานครบ flow หลักแล้ว
- Firebase Auth ใช้งาน Email/Password แล้ว
- Firestore collection `attractions` มีข้อมูล 2,994 documents
- Flutter โหลด attraction data จาก Firestore
- Preferences ของ user ถูกบันทึกใน `users/{uid}`
- หน้า Home ใช้ FastAPI backend เรียกโมเดล KNN `.pkl`
- ถ้า backend ไม่เปิด หน้า Home fallback ไปใช้ local scoring เดิม
- Profile, History, About App, Logout ทำแล้ว
- TikTok feed เล่นวิดีโอจาก `videoUrls` ใน Firestore/Storage แล้ว

## Firebase

- Project name: TravelRecommendation
- Project ID: `travelrecommendation-851e9`
- Firestore location: `asia-southeast1`
- Storage bucket: `travelrecommendation-851e9.firebasestorage.app`
- Main collection: `attractions`

## KNN Model

Model artifact:

```text
backend/models/travel_recommendation_knn_model_v1.pkl
```

Backend command:

```powershell
uv run --python 3.12 --with-requirements backend\requirements.txt uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

Evaluation summary:

- Precision@10: 0.6300
- Recall@10: 0.6708
- F1@10: 0.4278
- Hit Rate@10: 1.0000

## Video Feed Demo Places

Firebase Storage + Firestore `videoUrls` ถูกตั้งไว้แล้วสำหรับ:

- เมืองเก่าอุทัยธานี
- อ่าวมาหยา
- วัดร่องขุ่น
- อุทยานแห่งชาติดอยอินทนนท์

## How to Continue in a New Codex Chat

ถ้าเปิด Codex บนเครื่องใหม่แล้วไม่เห็นแชทเดิม ให้เริ่มแชทใหม่และบอกว่า:

```text
ช่วยอ่าน project/PROJECT_STATUS.md, project/README.md,
project/SETUP_HOME_PC.md และ project/CODEX_HANDOFF.md
แล้วทำงานต่อจากสถานะล่าสุดของโปรเจกต์ Flutter TravelRecommendation
```

หรือส่ง context สั้น ๆ:

```text
โปรเจกต์อยู่ที่ C:\flutter\flutter-Project\project
เป็น Flutter + Firebase + FastAPI KNN recommendation app
ตอนนี้ต้องทำงานต่อจาก README, PROJECT_STATUS และ CODEX_HANDOFF
```

## Remaining Work

- ทดสอบ end-to-end บนมือถือจริง
- ถ้าจะใช้นอก local network ต้อง deploy FastAPI backend
- เปลี่ยน logo/graphic เป็นงานที่ผู้ใช้ทำเอง
- ตรวจ UI รอบสุดท้าย
- Build APK
- เตรียมภาพ screenshot และเนื้อหารายงาน
