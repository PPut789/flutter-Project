# Setup on a New Computer

คู่มือนี้ใช้สำหรับตั้งค่าเครื่องใหม่ที่ยังไม่มีไฟล์โปรเจกต์หรือเครื่องมือพัฒนา

## 1. Install Required Programs

ติดตั้งโปรแกรมเหล่านี้ก่อน:

- Git: https://git-scm.com/download/win
- Flutter SDK: https://docs.flutter.dev/get-started/install/windows
- Visual Studio Code: https://code.visualstudio.com/
- Android Studio: https://developer.android.com/studio
- Node.js LTS: https://nodejs.org/
- uv สำหรับรัน Python backend: https://docs.astral.sh/uv/getting-started/installation/
- Firebase CLI:

```powershell
npm install -g firebase-tools
```

หลังติดตั้ง Flutter ให้ตรวจ:

```powershell
flutter doctor
```

แก้รายการที่ Flutter doctor แจ้ง โดยเฉพาะ Android toolchain และ Android licenses:

```powershell
flutter doctor --android-licenses
```

## 2. Clone Project

อย่าใช้ `git init` ใหม่ ให้ clone จาก GitHub:

```powershell
cd C:\
git clone https://github.com/PPut789/flutter-Project.git
cd C:\flutter-Project\project
```

ถ้าต้องการเก็บใน path เดิมเหมือนเครื่องมหาวิทยาลัย:

```powershell
mkdir C:\flutter\flutter-Project
cd C:\flutter
git clone https://github.com/PPut789/flutter-Project.git
cd C:\flutter\flutter-Project\project
```

## 3. Install Flutter Dependencies

```powershell
flutter pub get
```

## 4. Firebase Login

ใช้บัญชี Firebase เดิมของโปรเจกต์:

```powershell
firebase login
firebase projects:list
```

ควรเห็น project:

```text
travelrecommendation-851e9
```

ไฟล์ Firebase config มีอยู่ใน repo แล้ว:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`
- `firestore.rules`

โดยทั่วไปไม่ต้องรัน `flutterfire configure` ใหม่ เว้นแต่แก้ Firebase project

## 5. Run KNN Backend

เปิด terminal แยกไว้หนึ่งหน้าต่าง:

```powershell
cd C:\flutter\flutter-Project\project
uv run --python 3.12 --with-requirements backend\requirements.txt uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

ตรวจ backend:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

ควรเห็น:

```text
modelFile: travel_recommendation_knn_model_v1.pkl
totalAttractions: 2994
features: 107
```

## 6. Run Flutter Web

เปิด terminal อีกหน้าต่าง:

```powershell
cd C:\flutter\flutter-Project\project
flutter run -d chrome
```

หรือ:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5174
```

เปิด:

```text
http://127.0.0.1:5174/
```

## 7. Run on Android Phone

เสียบมือถือ เปิด USB debugging แล้วตรวจ:

```powershell
flutter devices
```

ถ้ารันบนมือถือจริง backend `127.0.0.1` จะหมายถึงมือถือ ไม่ใช่คอม
ต้องใช้ IP ของคอมในวง Wi-Fi เดียวกัน:

```powershell
ipconfig
```

หา IPv4 Address เช่น `192.168.1.20` แล้วรัน backend:

```powershell
uv run --python 3.12 --with-requirements backend\requirements.txt uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

จากนั้นรัน Flutter:

```powershell
flutter run --dart-define=RECOMMENDATION_API_URL=http://192.168.1.20:8000
```

เปลี่ยน IP ให้ตรงกับเครื่องจริง

## 8. Validate Project

```powershell
flutter analyze
flutter test
flutter build web
```

## 9. Important Files Already Included

Repo นี้มีไฟล์สำคัญพร้อมแล้ว:

- Flutter source code: `lib/`
- Firebase config: `lib/firebase_options.dart`, `android/app/google-services.json`
- Firestore rules: `firestore.rules`
- Dataset JSON: `dataset/attractions.json`
- Enriched Excel: `dataset/#5 finish_attraction_enriched.xlsx`
- Analytics: `dataset/analytics/`
- KNN evaluation: `dataset/model_results/`
- KNN model: `backend/models/travel_recommendation_knn_model_v1.pkl`
- Backend API: `backend/main.py`
- Storage upload tool: `tools/upload_attraction_video_rest.mjs`

## 10. Files Not Included

ไฟล์เหล่านี้ไม่ควรอยู่ใน GitHub และต้องสร้างใหม่จากเครื่องนั้น:

- `build/`
- `.dart_tool/`
- `node_modules/`
- `.codex_run/`
- `tools/media_enrichment.env`

ถ้าต้องใช้ media enrichment API ใหม่ ค่อยสร้าง `tools/media_enrichment.env`
บนเครื่องนั้นเอง เพราะอาจมี API key

## 11. Recommended First Run Checklist

1. `git pull`
2. `flutter pub get`
3. `firebase login`
4. เปิด backend ที่ port `8000`
5. เปิด Flutter web หรือมือถือ
6. Login/Register ด้วย Firebase Auth
7. ตรวจ Home Recommendation
8. ตรวจ TikTok feed
9. ตรวจ Detail, History และ Profile
