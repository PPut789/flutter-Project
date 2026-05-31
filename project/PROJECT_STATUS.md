# Personalized Tourist Attraction Recommendation System using Machine Learning

ระบบแนะนำสถานที่ท่องเที่ยวตามความสนใจส่วนบุคคลโดยใช้การเรียนรู้ของเครื่อง

## 1. ภาพรวมโปรเจค

โปรเจคนี้เป็น Mobile Application ที่พัฒนาด้วย Flutter สำหรับแนะนำสถานที่ท่องเที่ยวในประเทศไทย โดยอ้างอิงจากความสนใจที่ผู้ใช้เลือกเอง เช่น ภูมิภาค จังหวัด หมวดหมู่ ประเภทสถานที่ และกิจกรรมที่สนใจ

แนวคิดหลักของระบบคือ Personalized Tourist Attraction Recommendation System using Machine Learning โดยใช้ Content-Based KNN / Cosine Similarity เปรียบเทียบ preference ของผู้ใช้กับ feature ของสถานที่ ปัจจุบัน Flutter เชื่อม Firebase และเรียก FastAPI ที่โหลดโมเดล `.pkl` สำหรับจัดอันดับ recommendation แล้ว โดยมี scoring ภายในแอปเป็น fallback เฉพาะกรณี backend ไม่พร้อมใช้งาน

## 2. Tech Stack

- Mobile App: Flutter / Dart
- Dataset ต้นทาง: Excel จาก TAT Catalog Dataset
- Cloud database ปัจจุบัน: Firebase Cloud Firestore
- Media enrichment: Python script + Google APIs
- Image source ปัจจุบัน: Google Places Photos
- YouTube source ปัจจุบัน: YouTube Data API v3
- Runtime app data: Firestore collection `attractions`
- Authentication: Firebase Auth (Email/Password)
- Storage: Firebase Storage สำหรับ short video prototype
- Recommendation model: Python + Pandas + Scikit-learn, export เป็น `.pkl`
- Recommendation API: FastAPI
- Map: Google Maps ผ่าน `url_launcher`
- Video: YouTube embed และ short-video feed จาก `videoUrls`

## 3. Dataset ปัจจุบัน

Excel ต้นทาง:

`C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction.xlsx`

Runtime data ที่ Flutter ใช้งาน:

Firebase Cloud Firestore collection `attractions`

Dataset copy ที่รวม media แล้วในโปรเจค:

`C:\flutter\flutter-Project\project\dataset\#5 finish_attraction_enriched.xlsx`

JSON copy สำหรับอ้างอิง/เครื่องมือ dataset:

`C:\flutter\flutter-Project\project\dataset\attractions.json`

ข้อมูลมีประมาณ:

- 2,994 rows
- ภาคเหนือ + ภาคใต้
- 31 จังหวัด
- category 3 กลุ่ม
- type 52 ประเภท
- activity 18 รูปแบบ

Column สำคัญจาก dataset:

- `ATT_ID`
- `ATT_NAME_TH`
- `ATT_NAME_EN`
- `ATT_DETAIL_TH`
- `ATT_ACTIVITY`
- `ATT_LOCATION`
- `REGION_NAME_TH`
- `PROVINCE_NAME_TH`
- `DISTRICT_NAME_TH`
- `SUBDISTRICT_NAME_TH`
- `ATT_CATEGORY_LABEL`
- `ATT_TYPE_LABEL`

Column ที่เพิ่ม/ใช้สำหรับ media:

- `IMAGE_URLS`
- `YOUTUBE_URLS`
- `GOOGLE_PLACE_ID`

หมายเหตุ:

- `IMAGE_URLS` เก็บหลายรูปใน column เดียว โดยคั่นแต่ละ URL ด้วย `|`
- `YOUTUBE_URLS` เก็บหลายคลิปใน column เดียว โดยคั่นแต่ละ URL ด้วย `|`
- `GOOGLE_PLACE_ID` ใช้ช่วยอ้างอิงสถานที่จาก Google Places สำหรับการค้นหารูป
- Excel ต้นฉบับใน OneDrive ยังไม่ถูกเขียนทับ ไฟล์ที่ควรใช้ต่อคือ enriched copy ในโฟลเดอร์ `dataset` ของโปรเจค

## 4. โครงสร้าง Asset ใน Flutter

โครงสร้าง asset ปัจจุบัน:

```text
assets/
  backgrounds/
    start_background.png
  images/
    maya_bay.jpg
  logos/
    app_logo.png
  video/
    prototype_tiktok_feed.mp4
```

ใน `pubspec.yaml` มีการ register assets แล้ว:

```yaml
assets:
  - assets/images/
  - assets/backgrounds/
  - assets/logos/
  - assets/video/
```

ถ้าสถานที่ไม่มีรูปจริง แอปจะ fallback ไปใช้ placeholder:

`assets/images/maya_bay.jpg`

## 5. โครงสร้าง Flutter ปัจจุบัน

```text
lib/
  main.dart
  data/
    place_repository.dart
  models/
    place_model.dart
    recommendation_preferences.dart
  pages/
    start_page.dart
    login_page.dart
    register_page.dart
    location_page.dart
    interest_page.dart
    home_page.dart
    detail_page.dart
  widgets/
    auth_background.dart
```

## 6. Flow ของแอปปัจจุบัน

```text
Start
-> Login / Register
-> Select Region / Province
-> Select Category / Type / Activity
-> Home Recommendation
-> Detail Page
```

### Start Page

- ใช้ `assets/backgrounds/start_background.png` เป็นพื้นหลัง
- มี card logo ตรงกลาง
- ปุ่ม `Get Start` ไปหน้า Register
- ปุ่ม `Sign in` ไปหน้า Login

### Login / Register

- ยังเป็น placeholder UI
- ยังไม่เชื่อม Firebase Auth
- กด Sign in / Sign up แล้วไปหน้าเลือก Location ได้เลย
- แก้แล้ว: link ด้านล่างกดได้เฉพาะคำว่า `Sign in` หรือ `Sign up`
- แก้แล้ว: ปุ่มซ่อน/แสดงรหัสผ่านใช้งานได้

### Location Page

- ใช้เลือกพื้นที่ที่อยากเที่ยว
- ต้องเลือกอย่างน้อย 1 ภาค
- จังหวัดเป็น optional
- ถ้าเลือกภาคเหนือ จะแสดงเฉพาะจังหวัดภาคเหนือ
- ถ้าเลือกภาคใต้ จะแสดงเฉพาะจังหวัดภาคใต้
- ถ้าไม่เลือกจังหวัด Home จะกรองจากภาคอย่างเดียว
- ถ้าเลือกจังหวัด Home จะกรองแคบลงตามจังหวัด
- แก้แล้ว: ไม่มีปุ่มย้อนกลับ
- แก้แล้ว: Region เปลี่ยนเป็น card 2 ใบ คือ ภาคเหนือ และ ภาคใต้

### Interest Page

- ต้องเลือกอย่างน้อยหัวข้อละ 1 อย่าง:
  - Category
  - Type
  - Activity
- ถ้ายังเลือกไม่ครบ ปุ่ม Generate Recommendation จะกดไม่ได้

### Home Page

มีส่วนหลัก:

- Header
- Search bar
- Profile icon placeholder
- Recommended for You
- Card สถานที่จาก dataset จริง
- Bottom Navigation: Home, Preferences, Favorites, Profile

Card หน้า Home แสดง:

- รูปสถานที่จริงจาก `images` ถ้ามี
- รูป placeholder ถ้าไม่มีรูป
- ชื่อสถานที่
- จังหวัด + ภาค
- รายละเอียดย่อ
- tags จาก category/type/activity

ปุ่ม Preferences ใน bottom nav จะพากลับไปเลือก region/province ใหม่

### Detail Page

รองรับ:

- หลายรูปภาพผ่าน `images`
- เลื่อนรูปซ้าย/ขวาได้ตามจำนวนรูปจริงของสถานที่นั้น
- thumbnail gallery ด้านล่าง
- เลือกรูปจาก thumbnail ได้
- หลาย YouTube URL ผ่าน `youtubeUrls`
- แสดง YouTube ทีละ 1 คลิป
- ถ้ามีมากกว่า 1 คลิป สามารถเลื่อนซ้าย/ขวาได้
- ถ้าไม่มีคลิป จะไม่แสดง YouTube section
- About / description
- Google Maps button ผ่าน `url_launcher`

หมายเหตุ:

- ตอนนี้การเล่น YouTube ในแอปยังไม่ได้ embed player จริง
- ปัจจุบันคลิปเป็น URL สำหรับเปิดดูภายนอกหรือเตรียมต่อยอดเป็น embedded player ภายหลัง

## 7. Recommendation Logic ปัจจุบัน

ตอนนี้ยังไม่ใช่ production KNN model จริง

ปัจจุบันใช้ content-based scoring/filtering ใน Flutter ก่อน เพื่อให้แอปทำงานครบ:

การกรอง:

- ภาคต้องตรงกับที่ผู้ใช้เลือก
- จังหวัดจะกรองเฉพาะถ้าผู้ใช้เลือกจังหวัด
- Search ค้นจากชื่อสถานที่ จังหวัด ประเภท และกิจกรรม

การให้คะแนน:

- category ตรง +3
- type ตรง +3
- activity match แบบ contains +4

ตัวอย่าง:

- ถ้าเลือก `ถ่ายรูป`
- ระบบสามารถ match กับ activity ที่มีคำใกล้เคียง เช่น `ชมวิว, ถ่ายรูป`

## 8. สถานะ YouTube Enrichment

เราเริ่มเติม `YOUTUBE_URLS` จากชื่อสถานที่โดยใช้ YouTube Data API v3

วิธีที่ใช้:

1. อ่านชื่อสถานที่จาก Excel
2. ค้นหาด้วย YouTube Data API v3
3. ใช้ชื่อภาษาไทยก่อน
4. ถ้าต้องการรอบต่อไปสามารถใช้ `ATT_NAME_EN` เป็น fallback สำหรับแถวที่ยังว่าง
5. บันทึก URL คลิปลง column `YOUTUBE_URLS`
6. merge จาก Excel กลับเข้า `dataset/attractions.json`

สถานะปัจจุบัน:

- เติม YouTube sample ไปแล้วประมาณ 50 แถวแรก
- ใน JSON มี `youtubeUrls` สำหรับ sample ที่หาเจอแล้ว
- YouTube section ในแอปแสดงเฉพาะสถานที่ที่มีคลิป
- ถ้ามีหลายคลิป จะแสดงทีละ 1 คลิปและเลื่อนได้

ข้อจำกัด:

- YouTube Data API มี quota จำกัด
- วันที่ทดลองรัน เจอ quota เต็ม จึงยังเติมทั้ง dataset ไม่ได้
- งาน YouTube ควรรันต่อแบบเป็น batch วันละบางส่วน
- ควรใช้ fallback ภาษาอังกฤษเฉพาะแถวที่ยังไม่มีคลิป เพื่อลดจำนวน request

Script ที่เกี่ยวข้อง:

- `tools/enrich_attraction_media.py`
- `tools/merge_excel_media_to_json.py`

## 9. สถานะ Image Enrichment

เราเริ่มเติมรูปภาพจริงเพื่อลดการใช้ placeholder

วิธีที่ใช้:

1. ใช้ Google Places API / Places Photos
2. อ่านชื่อสถานที่จาก Excel
3. ค้นหาสถานที่จาก Google Places Text Search
4. ดึง `place_id`
5. เรียก Place Details เพื่อเอา photo references
6. แปลง photo references เป็น image URLs
7. เก็บรูปลง column `IMAGE_URLS` โดยคั่น URL ด้วย `|`
8. เก็บ `GOOGLE_PLACE_ID` ไว้ช่วยตรวจสอบ/อ้างอิง
9. merge `IMAGE_URLS` เข้า `dataset/attractions.json`

จำนวนรูปที่ตั้งไว้:

- น้อยสุดที่ต้องการ: 2 รูป
- มากสุด: 8 รูปต่อสถานที่
- ถ้า Google Places มีรูปไม่ถึง 8 รูป จะใส่เท่าที่เจอจริง
- ถ้าหาไม่เจอรูปเลย สถานที่นั้นจะยังใช้ placeholder

สถานะล่าสุด:

- รันเติมรูปครบถึงแถวที่ 2994 แล้ว
- ใน JSON ทั้งหมด 2,994 รายการ
- มีรูปแล้วทั้งหมด 2,885 รายการ
- ยังไม่มีรูป 109 รายการ
- ส่วนใหญ่ของรายการที่เจอรูป ได้ครบ 8 รูป

สรุปจำนวนรูปใน JSON ปัจจุบัน:

```text
1 รูป: 15 รายการ
2 รูป: 20 รายการ
3 รูป: 21 รายการ
4 รูป: 16 รายการ
5 รูป: 14 รายการ
6 รูป: 15 รายการ
7 รูป: 10 รายการ
8 รูป: 2,774 รายการ
```

Script ที่เกี่ยวข้อง:

- `tools/enrich_attraction_places_images.py`
- `tools/run_places_image_batches.py`
- `tools/merge_excel_media_to_json.py`

Log ที่เกี่ยวข้อง:

- `tools/places_batch_run.log`
- `tools/places_batch_501_1000.log`

## 10. สถานะการทดสอบล่าสุด

ตรวจแล้วผ่าน:

```text
flutter analyze
No issues found

flutter test
All tests passed

flutter build web
Built build\web
```

## 11. สถานะ Data Analytic / Feature Transform

สร้างไฟล์วิเคราะห์ dataset และตาราง transform สำหรับเตรียมทำ Data Mining/KNN แล้ว

ไฟล์ script:

`C:\flutter\flutter-Project\project\tools\dataset_analytics.py`

ไฟล์ output:

```text
C:\flutter\flutter-Project\project\dataset\analytics\dataset_analytics_summary.xlsx
C:\flutter\flutter-Project\project\dataset\analytics\feature_transform_table.xlsx
C:\flutter\flutter-Project\project\dataset\analytics\dataset_analytics_summary.json
```

ผลสรุปล่าสุด:

```text
Total attractions: 2,994
Regions: 2
Provinces: 31
Categories: 3
Types: 52
Activities: 19
Rows with images: 2,885 (96.36%)
Rows with YouTube: 50 (1.67%)
Top province: เชียงใหม่
Top category: ประวัติศาสตร์และวัฒนธรรม
Top type: วัดและศาสนสถาน
Top activity: ถ่ายรูป
```

ไฟล์ `feature_transform_table.xlsx` ใช้อธิบายการแปลงข้อมูลเป็น binary/one-hot features เช่น `activity_ถ่ายรูป = 1` ถ้าสถานที่นั้นมีกิจกรรมถ่ายรูป และ `0` ถ้าไม่มี

ข้อมูลส่วนนี้สามารถนำไปต่อยอดเป็น Web Admin / Data Analytic Dashboard ได้ในอนาคต

## 12. สถานะ KNN / Machine Learning

สร้างโมเดล Content-Based KNN / Cosine Similarity ใน Google Colab แล้ว โดยผู้พัฒนาเป็นผู้รันขั้นตอนการเตรียมข้อมูล แปลง feature ทดสอบผล และ export artifact ด้วยตนเอง

- Feature: region, province, category, type, activity
- Transformation: one-hot encoding และ multi-hot encoding สำหรับ activity
- Feature weights: region 2.0, province 2.5, category 3.0, type 3.0, activity 4.0
- Feature matrix: 2,994 rows x 107 features
- Model artifact: `backend/models/travel_recommendation_knn_model_v1.pkl`
- Evaluation: 50 preference cases ทั้งแบบเลือกจังหวัดและไม่เลือกจังหวัด
- Average Precision@10: 0.6300
- Average Recall@10: 0.6708
- Average F1@10: 0.4278
- Average Hit Rate@10: 1.0000

FastAPI โหลด `.pkl` และ Flutter ใช้ผลอันดับจาก API แล้ว โดย `sourceRow` ใช้เชื่อมอันดับกลับเข้าข้อมูล Firestore ปัจจุบัน

## 13. สิ่งที่ยังไม่ได้ทำ

### Recommendation / Machine Learning

- ทดสอบ recommendation end-to-end ใน Flutter ขณะเปิด backend บนเครื่อง
- พิจารณา deploy FastAPI เพื่อใช้งานจากมือถือจริงนอกเครื่องพัฒนา
- ยังไม่ได้ทำ user-history based recommendation

### Dataset / Media

- เติมรูปอัตโนมัติครบทั้ง 2,994 rows แล้ว
- ยังมี 109 รายการที่ Google Places หา image ไม่เจอ
- รายการที่ยังไม่มีรูปจะยัง fallback ไปใช้ placeholder ในแอป
- ยังเติม YouTube ได้แค่ sample เพราะติด quota
- ยังไม่ได้ตรวจคุณภาพรูปทีละรายการ
- รูปจาก Google Places เป็นการค้นหาอัตโนมัติ จึงควรมีรอบ review ความถูกต้อง

### Firebase

- ยังไม่เชื่อม Firebase Auth
- เชื่อม Firestore แล้ว และโหลด attraction จาก collection `attractions`
- ยังไม่เชื่อม Firebase Storage
- ยังไม่มี user profile จริง
- ยังไม่มีระบบ favorites จริง
- ยังไม่มี history ของผู้ใช้

### Web Admin / Data Analytic

- ยังไม่ได้ทำหน้า Web Admin
- มีไฟล์ Data Analytic output แล้ว แต่ยังไม่ได้นำไปแสดงใน Web Admin
- ตัวชี้วัดที่ควรใช้ใน Web Admin ได้แก่ จำนวนสถานที่ทั้งหมด จำนวนภาค จำนวนจังหวัด จำนวน category/type/activity อัตราความครบถ้วนของรูปภาพ อัตราความครบถ้วนของ YouTube จังหวัดที่มีสถานที่มากที่สุด activity ที่พบบ่อยที่สุด และ category ที่พบบ่อยที่สุด

### Login / Profile

- Login/Register ยังเป็น placeholder
- ยังไม่มี username จริงจากระบบสมัครสมาชิก
- หน้า Home ยังไม่ได้ดึง username จาก account จริง
- Profile ยังเป็น placeholder
- ยังไม่มีรูปโปรไฟล์

### App Features

- Favorites ยังเป็น placeholder
- Profile ยังเป็น placeholder
- Search ยังเป็น local search
- Detail page ยังไม่ได้ embed YouTube player จริง
- ยังไม่มี map view ในแอป เป็นการเปิด Google Maps ผ่าน URL
- ยังไม่มีระบบบันทึก preference ถาวร

## 14. Roadmap แนะนำต่อจากนี้

### ขั้นที่ 1: ทำ KNN / Data Mining ด้วยตัวเอง

ควรทำโมเดลด้วยตัวเองก่อน เพื่อให้เห็นภาพและมีหลักฐานสำหรับรายงาน

งานที่ควรทำ:

- อ่าน dataset enriched
- วิเคราะห์ feature ที่จะใช้
- transform ข้อมูลเป็นตัวเลข
- ทดลอง KNN / cosine similarity หรือ Weka ตามที่เลือก
- บันทึกผลลัพธ์ top-N recommendation
- เตรียมไฟล์ output ที่มี `ATT_ID` หรือชื่อสถานที่เพื่อให้ Flutter ใช้ต่อ

### ขั้นที่ 2: Evaluation

- สร้าง sample preference 20-50 ชุด
- คำนวณ Precision@10 หรือ Hit Rate@10
- ตรวจว่าผลลัพธ์ตรงกับ category/type/activity ที่ผู้ใช้เลือกกี่รายการ
- ใช้ผลนี้เขียนในรายงานแทน accuracy แบบ classification

ถ้าทำ classification ทดลองใน Weka สามารถรายงาน accuracy/confusion matrix ได้ แต่ต้องแยกให้ชัดว่านั่นคือการทดลอง classification ไม่ใช่ metric หลักของ recommendation

### ขั้นที่ 3: เชื่อมโมเดลเข้ากับ Flutter

- ให้ Flutter ส่ง preference ที่ผู้ใช้เลือก
- ใช้ผลลัพธ์ `ATT_ID` / `nameTh` จากโมเดลเพื่อจัดอันดับสถานที่
- ช่วง prototype อาจให้โมเดล export JSON ก่อน
- ขั้น production ค่อยทำเป็น API

### ขั้นที่ 4: เติม Media ต่อ

- ตรวจ review รายการที่ยังไม่มีรูป 109 รายการ
- ถ้าต้องการให้ครบ 100% อาจเติมรูปเองหรือใช้แหล่งข้อมูลอื่นสำหรับรายการที่ Google Places หาไม่เจอ
- เติม `YOUTUBE_URLS` ต่อแบบ batch หลัง quota reset
- ใช้ชื่ออังกฤษ `ATT_NAME_EN` เป็น fallback สำหรับแถวที่ยังหาไม่เจอ
- ทำรายชื่อแถวที่ไม่มีรูป/คลิป เพื่อ review ทีหลัง

### ขั้นที่ 5: Firebase

ควรทำหลังจาก flow หลักและ model เริ่มนิ่ง

Firebase ใช้สำหรับ:

- Firebase Auth: login/register จริง
- Firestore: user profile, preferences, favorites, history
- Firebase Storage: profile image หรือรูปที่ต้อง upload เอง

สิ่งที่ควรเก็บใน Firestore:

- users
- preferences
- favorites
- recommendation_history
- attraction metadata ถ้าจะย้ายจาก local JSON ไป database

### ขั้นที่ 6: Behavior-Based Recommendation

ทำเป็น future work หลังจากมี user history

ใช้ข้อมูลเช่น:

- สถานที่ที่ผู้ใช้กดดู
- สถานที่ที่ favorite
- category/type/activity ที่ดูบ่อย
- จังหวัดที่สนใจบ่อย

แล้วนำไปปรับ recommendation ให้เป็น personalized มากขึ้น

### ขั้นที่ 7: Web Admin / Data Analytic Dashboard

ทำ Web Admin สำหรับดูแลและวิเคราะห์ข้อมูลแอปพลิเคชัน โดยเริ่มจาก dashboard สรุป dataset เช่น:

- จำนวนสถานที่ทั้งหมด
- จำนวนภาคและจังหวัด
- จำนวน category, type, activity
- จำนวนและเปอร์เซ็นต์สถานที่ที่มีรูปภาพ
- จำนวนและเปอร์เซ็นต์สถานที่ที่มี YouTube
- จังหวัดที่มีสถานที่มากที่สุด
- activity ที่พบบ่อยที่สุด
- category ที่พบบ่อยที่สุด
- รายการสถานที่ที่ยังไม่มีรูปหรือวิดีโอ

## 15. สิ่งที่สามารถอธิบายอาจารย์ได้ตอนนี้

ระบบนี้เป็น Personalized Tourist Attraction Recommendation System using Machine Learning ที่ออกแบบให้ใช้ความสนใจของผู้ใช้เป็น input หลัก เช่น ภูมิภาค จังหวัด หมวดหมู่ ประเภท และกิจกรรม จากนั้นนำ preference เหล่านี้ไปเปรียบเทียบกับ feature ของสถานที่ท่องเที่ยวใน dataset

สถานะปัจจุบันของโปรเจคใช้ dataset จริงจาก Firestore และใช้โมเดล Content-Based KNN / Cosine Similarity ที่ export เป็น `.pkl` ผ่าน FastAPI เพื่อจัดอันดับสถานที่ตาม preference ของผู้ใช้ แอปรองรับจังหวัดแบบ optional ตามการออกแบบเดิม

นอกจากนี้ โปรเจคเริ่มทำ media enrichment แล้ว โดยใช้ Google Places Photos เพื่อเติมรูปภาพจริงให้สถานที่ท่องเที่ยว และใช้ YouTube Data API v3 เพื่อเติมลิงก์วิดีโอใน dataset ทำให้หน้า Detail ของแอปสามารถแสดงรูปภาพและคลิปตามข้อมูลจริงมากขึ้น แทนการใช้ placeholder ทั้งหมด

## 16. สถานะล่าสุดแบบสั้น

- App flow หลักทำงานครบแล้ว
- Runtime dataset อ่านจาก Firestore จำนวน 2,994 documents แล้ว
- มี Data Analytic output และ Feature Transform table แล้ว
- Flutter เรียก FastAPI ที่โหลด KNN `.pkl` แล้ว และมี local scoring เป็น fallback
- KNN artifact และผล evaluation ถูกเก็บในโปรเจคแล้ว
- Login/Register เชื่อม Firebase Auth แล้ว
- Detail page รองรับหลายรูปและหลาย YouTube URLs แล้ว
- TikTok feed รองรับ `videoUrls` จาก Firebase Storage แล้ว
- รูปภาพเติมอัตโนมัติด้วย Google Places Photos ครบถึงแถวที่ 2994 แล้ว
- YouTube เติม sample แล้ว แต่ต้องรอต่อเพราะ quota
- Tests/build ผ่านล่าสุด
