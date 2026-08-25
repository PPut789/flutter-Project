# สรุปอัปเดตข้อมูลโปรเจกต์สำหรับทำรายงานบทที่ 1-5

เอกสารนี้ทำขึ้นเพื่อส่งต่อให้ผู้ที่จะช่วยปรับรายงานบทที่ 1-5 ของโครงงาน
**ระบบแนะนำสถานที่ท่องเที่ยวตามความสนใจส่วนบุคคลโดยใช้เทคนิคปัญญาประดิษฐ์**
โดยอ้างอิงจากรายงานเดิมบทที่ 1-3 และสถานะโปรเจกต์ Flutter/Firebase ปัจจุบัน

> สถานะที่ควรใช้เขียนรายงาน: ระบบแอปพลิเคชันหลักพัฒนาใกล้เสร็จแล้วในส่วน Mobile App, Firebase, User flow, Profile, History, Video Upload และ UI หลัก ส่วน Machine Learning/KNN มี pipeline และไฟล์ `.pkl` รุ่นทดลองแล้ว แต่ยังต้องกลับไปเทรน `NearestNeighbors.fit()` จริงอีกครั้งก่อนถือว่าโมเดล KNN production เสร็จสมบูรณ์

## 1. ภาพรวมโปรเจกต์ล่าสุด

ชื่อโปรเจกต์ภาษาอังกฤษ:

**Personalized Tourist Attraction Recommendation System Using Artificial Intelligence**

ชื่อโปรเจกต์ภาษาไทย:

**ระบบแนะนำสถานที่ท่องเที่ยวตามความสนใจส่วนบุคคลโดยใช้เทคนิคปัญญาประดิษฐ์**

แนวคิดหลักของระบบคือ Mobile Application ที่พัฒนาด้วย Flutter สำหรับแนะนำสถานที่ท่องเที่ยวในประเทศไทยตามความสนใจของผู้ใช้ โดยใช้ข้อมูลความสนใจ เช่น ภูมิภาค จังหวัด หมวดหมู่ ประเภทสถานที่ และกิจกรรม มาเปรียบเทียบกับคุณลักษณะของสถานที่ท่องเที่ยวในฐานข้อมูล แล้วจัดอันดับสถานที่ที่เหมาะสมกับผู้ใช้

ระบบปัจจุบันเปลี่ยนจาก prototype ที่อ่านข้อมูลจากไฟล์ JSON ในเครื่อง ไปเป็นระบบที่เชื่อม Firebase จริงแล้ว โดยมี Firebase Authentication สำหรับบัญชีผู้ใช้, Cloud Firestore สำหรับข้อมูลสถานที่และข้อมูลผู้ใช้ และ Firebase Storage สำหรับรูปโปรไฟล์และวิดีโอที่ผู้ใช้อัปโหลด

## 2. สถานะปัจจุบันที่ต้องเขียนในรายงาน

ระบบที่ทำเสร็จแล้วในแอป:

- หน้าเริ่มต้น Start Page
- หน้า Login/Register เชื่อม Firebase Auth
- ระบบจำ session ผู้ใช้ ถ้าเคย login แล้วไม่ต้อง login ใหม่ทุกครั้ง
- ระบบ Forgot Password สำหรับส่งอีเมลรีเซ็ตรหัสผ่าน
- หน้าเลือกพื้นที่ท่องเที่ยว โดยเลือกได้เฉพาะภาคเหนือและภาคใต้
- จังหวัดเป็น optional ถ้าไม่เลือกจังหวัด ระบบจะแนะนำทั้งภาค
- หน้าเลือกความสนใจ Category, Type, Activity
- ระบบบันทึก preference ของผู้ใช้ลง Firestore
- กลับมาแก้ Preference แล้วแสดงค่าที่เคยเลือกไว้ ไม่รีเซ็ตใหม่
- หน้า Home แสดงสถานที่แนะนำจาก preference
- Search ใช้งานได้จริง โดยค้นจากข้อมูลสถานที่ทั้งหมด
- หน้า Detail แสดงรูปภาพ, รายละเอียด, YouTube, Google Maps
- หน้า Video Feed สำหรับวิดีโอที่ผู้ใช้อัปโหลดเอง
- หน้า Upload Video ให้ผู้ใช้อัปโหลดวิดีโอและผูกกับสถานที่ 1 คลิปต่อ 1 สถานที่
- ถ้าสถานที่อยู่ในแอป เลือกจากฐานข้อมูลสถานที่ได้
- ถ้าสถานที่ไม่มีในแอป กรอกลิงก์ Google Maps แทนได้
- วิดีโอที่อัปโหลดแสดงใน feed ทันที ไม่ต้องรออนุมัติ
- ผู้ใช้ทุกคนเห็นวิดีโอร่วมกัน
- เจ้าของคลิปสามารถแก้ไขรายละเอียดและลบคลิปของตัวเองได้
- หน้า Profile แสดงรูปโปรไฟล์, username, email, History, My Videos, About App, Settings, Logout
- ผู้ใช้เปลี่ยนรูปโปรไฟล์ได้
- หน้า History เก็บประวัติสถานที่ที่เข้าชม และไม่เพิ่มสถานที่ซ้ำ
- หน้า My Videos แสดงวิดีโอของผู้ใช้แบบ grid 2 คอลัมน์ คล้าย TikTok profile
- หน้า Settings มีการตั้งค่าเกี่ยวกับวิดีโอและประวัติการเข้าชม
- หน้า About App มีข้อมูลโครงการและเทคโนโลยีที่ใช้
- UI ปรับเป็นแนว Minimal โทนขาว-ม่วง ตาม design จาก Figma

ระบบ backend/recommendation:

- มี FastAPI backend สำหรับ recommendation
- Flutter สามารถเรียก backend ผ่าน `RECOMMENDATION_API_URL`
- มีไฟล์ `.pkl` รุ่นทดลองอยู่ที่ `backend/models/travel_recommendation_knn_model_v1.pkl`
- ไฟล์ `.pkl` ปัจจุบันเก็บ feature matrix, metadata, feature columns, weights และ evaluation
- backend ปัจจุบันยังคำนวณ cosine similarity จาก matrix โดยตรง
- งานที่ยังต้องทำคือเทรน `sklearn.neighbors.NearestNeighbors(metric='cosine', algorithm='brute')` ด้วย `.fit(feature_matrix)` แล้ว export `.pkl` ใหม่ เพื่อให้เรียกว่าเป็นโมเดล KNN ที่เทรนจริงอย่างสมบูรณ์

## 3. Firebase ปัจจุบัน

ข้อมูล Firebase ที่ควรใส่ในรายงาน:

- Firebase Project name: `TravelRecommendation`
- Project ID: `travelrecommendation-851e9`
- Project number: `1051392765409`
- Firestore location: `asia-southeast1`
- Storage bucket: `travelrecommendation-851e9.firebasestorage.app`
- Main collection: `attractions`
- จำนวน documents ใน `attractions`: 2,994 documents

Collection หลักที่ใช้:

- `attractions` เก็บข้อมูลสถานที่ท่องเที่ยวทั้งหมด
- `users` เก็บข้อมูลบัญชีผู้ใช้, username, email, photoUrl, preferences, settings
- `users/{uid}/history` หรือ path ประวัติของผู้ใช้ เก็บสถานที่ที่เคยเข้าชม
- `videos` เก็บ metadata ของวิดีโอที่ผู้ใช้อัปโหลด

Storage path หลัก:

- `profile_images/{uid}/avatar.jpg` สำหรับรูปโปรไฟล์
- `user_videos/{uid}/{videoId}.mp4` สำหรับวิดีโอที่ผู้ใช้อัปโหลด
- `attraction_videos/...` เคยใช้สำหรับคลิป demo ของสถานที่ แต่ปัจจุบันแนวทางหลักเปลี่ยนเป็น user-uploaded video

Security rules:

- Firestore rules จำกัดให้ผู้ใช้อ่าน/แก้ข้อมูลบัญชีและ history ของตัวเองได้
- วิดีโออ่านได้แบบ shared feed
- เจ้าของวิดีโอแก้ไข/ลบวิดีโอของตัวเองได้
- ป้องกันการแก้ owner, storage path, video URL, status และ createdAt โดยไม่ได้รับอนุญาต
- Storage rules จำกัด path, owner, content type และขนาดไฟล์สำหรับ profile image/video

## 4. Dataset ปัจจุบัน

Dataset หลัก:

- ไฟล์ Excel ในโปรเจกต์: `C:\flutter\flutter-Project\project\dataset\#5 finish_attraction_enriched.xlsx`
- JSON copy สำหรับอ้างอิง/เครื่องมือ: `C:\flutter\flutter-Project\project\dataset\attractions.json`
- ข้อมูล runtime จริงในแอป: Cloud Firestore collection `attractions`

จำนวนข้อมูล:

- 2,994 แถว/สถานที่
- ครอบคลุมภาคเหนือและภาคใต้
- ประมาณ 31 จังหวัด
- 3 หมวดหมู่หลัก
- 52 ประเภทสถานที่
- 18 รูปแบบกิจกรรม

Field สำคัญ:

- `sourceRow`
- `id`
- `documentId`
- `nameTh`
- `nameEn`
- `description`
- `telephone`
- `email`
- `highlight`
- `location`
- `latitude`
- `longitude`
- `region`
- `province`
- `district`
- `subdistrict`
- `category`
- `type`
- `activity`
- `images`
- `youtubeUrl`
- `youtubeUrls`
- `tiktokUrls`
- `videoUrls`
- `tags`
- `updatedAt`

หมายเหตุเรื่อง ID:

เดิม dataset มี field `id` ซ้ำหรืออยู่ในรูปแบบที่ Excel แสดงเป็น scientific notation ได้ จึงไม่ใช้ `id` เป็น document ID โดยตรง ตอน import เข้า Firestore ใช้ document ID รูปแบบใหม่ เช่น `att_0001_20250620152816000` และเก็บ `sourceRow` สำหรับอ้างอิงแถวเดิม

ตัวอย่าง document:

```text
attractions/att_0001_20250620152816000
  sourceRow: 1
  id: "20250620152816000"
  nameTh: "เมืองเก่าอุทัยธานี"
  nameEn: "Uthai Thani Old Town"
  province: "อุทัยธานี"
  region: "ภาคเหนือ"
  category: "ประวัติศาสตร์และวัฒนธรรม"
  type: "โบราณสถาน"
  activity: "เรียนรู้ประวัติศาสตร์, ถ่ายรูป"
  images: [...]
  youtubeUrls: [...]
  videoUrls: [...]
```

ไฟล์ analytics ที่มีแล้ว:

- `C:\flutter\flutter-Project\project\dataset\analytics\dataset_analytics_summary.xlsx`
- `C:\flutter\flutter-Project\project\dataset\analytics\feature_transform_table.xlsx`
- `C:\flutter\flutter-Project\project\dataset\analytics\dataset_analytics_summary.json`
- `C:\flutter\flutter-Project\project\dataset\model_results\knn_evaluation_results_v1.csv`
- `C:\flutter\flutter-Project\project\dataset\model_results\knn_evaluation_50_cases_threshold_07.csv`
- `C:\flutter\flutter-Project\project\dataset\model_results\knn_all_ranked_results_50_cases_threshold_07.csv`

ข้อมูล analytics ใช้เขียนบทที่ 4 ได้ เช่น จำนวนข้อมูลทั้งหมด จำนวนจังหวัด จำนวน category/type/activity ความครบถ้วนของรูปภาพ/YouTube และผล evaluation ของ recommendation รุ่นทดลอง

## 5. ตารางเปลี่ยนจากอะไรเป็นอะไร

| หัวข้อ | เดิมในรายงาน/ต้นแบบ | สถานะใหม่ที่ต้องอัปเดต |
|---|---|---|
| แหล่งข้อมูลสถานที่ | อ่านจาก `assets/data/attractions.json` | อ่านจาก Cloud Firestore collection `attractions` จำนวน 2,994 documents |
| ไฟล์ JSON | เป็น runtime data หลักของ Flutter | ไม่ใช่ runtime หลักแล้ว เหลือเป็น dataset copy/reference ใน `dataset/attractions.json` |
| Firebase | ระบุเป็นฐานข้อมูลที่จะใช้ | ใช้จริงแล้วทั้ง Auth, Firestore, Storage |
| Login/Register | เป็น mockup กดแล้วเข้า flow ได้ | เชื่อม Firebase Auth Email/Password แล้ว |
| การจำ login | ต้อง login ใหม่ทุกครั้ง | ใช้ auth state ของ Firebase ถ้า login แล้วจะเข้า Home/Preference ต่อได้ |
| Preference | เลือกแล้วใช้ใน session | บันทึกลง `users/{uid}` และโหลดกลับมาแก้ไขได้ |
| จังหวัด | เคยวางเป็นตัวเลือกประกอบ | ยังคง optional ถ้าไม่เลือกจังหวัด ระบบแนะนำตามภูมิภาค |
| Home | แสดง recommendation จาก local scoring | เรียก FastAPI KNN-style ได้ และ fallback เป็น local scoring ถ้า backend ไม่พร้อม |
| Search | ค้นจากข้อมูล local | ค้นจากข้อมูลที่โหลดจาก Firestore ทั้ง dataset |
| Favorites ใน Navbar | เคยมี/เคยคิดไว้ | เปลี่ยนเป็น Video ตามข้อเสนอแนะอาจารย์ |
| TikTok | เคยเป็น TikTok tab และ local MP4 demo | เปลี่ยนเป็น Video Feed สำหรับ user-uploaded videos |
| คลิปวิดีโอ | ใช้ local asset หรือคลิป demo บางรายการ | ผู้ใช้ upload วิดีโอเอง เก็บไฟล์ใน Firebase Storage และ metadata ใน Firestore |
| การอนุมัติวิดีโอ | ยังไม่มี | อัปโหลดแล้วแสดงทันทีใน feed |
| เจ้าของคลิป | ยังไม่มีระบบจัดการ | เจ้าของคลิปแก้ไขรายละเอียดและลบคลิปได้ |
| Profile | เป็น placeholder | แสดง username/email/photo, เปลี่ยนรูป, History, My Videos, About, Settings, Logout |
| History | ยังไม่มีหรือเป็น mockup | เก็บประวัติการเข้าชมจริง และไม่เพิ่มสถานที่ซ้ำ |
| My Videos | ยังไม่มี | มีหน้า grid 2 คอลัมน์สำหรับดูวิดีโอของผู้ใช้ |
| Settings | ยังไม่ชัดเจน | มี setting สำหรับ autoplay video, mute, save history, clear history, reset settings |
| Detail Page | มีรูป/YouTube/Maps แบบ prototype | มี gallery หลายรูป, thumbnail, YouTube ใน About, Google Maps icon ข้างชื่อสถานที่ |
| รูปภาพสถานที่ | ใช้ URL จาก Google Places ที่เติมมา | พบปัญหา URL เก่าบางส่วน 403 จึงมี fallback placeholder/thumbnail และต้องกลับมาทำระบบรูปถาวรทีหลัง |
| UI | Prototype หลายหน้า | ปรับเป็น Minimal ขาว-ม่วงตาม Figma หลายหน้าแล้ว แต่ยังพักงาน UX/UI ไว้ก่อน |
| KNN | อธิบายว่าจะใช้ KNN | มี pipeline และ `.pkl` artifact แล้ว แต่ยังต้องเทรน `NearestNeighbors.fit()` จริงอีกครั้ง |
| Evaluation | ยังไม่มีในรายงานเดิม | มีผลทดลอง 50 preference cases: precision@10, recall@10, f1@10, hit_rate@10 |
| User-interest dataset | ยังไม่มี dataset เฉพาะพฤติกรรมผู้ใช้ | ควรเพิ่มเป็นงานเสริม/แนวทางทดลอง โดยใช้ external dataset หรือเก็บจาก history จริงของแอปในอนาคต |

## 6. สิ่งที่ต้องอัปเดตในบทที่ 1

บทที่ 1 เดิมมีเนื้อหาเรื่องความเป็นมา วัตถุประสงค์ กรอบแนวคิด ขอบเขต และประโยชน์ที่คาดว่าจะได้รับ โดยยังเขียนในภาพกว้างว่าระบบจะใช้ Flutter, Python, Firebase และ KNN

สิ่งที่ควรแก้:

### 6.1 ความเป็นมาและความสำคัญ

ควรเพิ่มว่า ปัจจุบันผู้ใช้ไม่เพียงต้องการค้นหาสถานที่จากข้อมูลทั่วไปเท่านั้น แต่ยังต้องการประสบการณ์ที่เป็นส่วนตัวมากขึ้น เช่น การเลือกตามภูมิภาค จังหวัด ความสนใจ ประเภทสถานที่ และกิจกรรม รวมถึงการดูวิดีโอจากผู้ใช้คนอื่นเพื่อช่วยตัดสินใจ

ควรเปลี่ยนจากการกล่าวถึงวิดีโอจากแพลตฟอร์มออนไลน์อย่างเดียว เป็นระบบที่รองรับทั้ง YouTube ในหน้ารายละเอียดสถานที่ และวิดีโอที่ผู้ใช้อัปโหลดเองในหน้า Video Feed

### 6.2 วัตถุประสงค์

วัตถุประสงค์ควรปรับให้ตรงกับระบบล่าสุด:

1. เพื่อออกแบบและพัฒนาแอปพลิเคชันแนะนำสถานที่ท่องเที่ยวในประเทศไทยตามความสนใจของผู้ใช้ โดยมุ่งเน้นพื้นที่ภาคเหนือและภาคใต้
2. เพื่อพัฒนาระบบจัดเก็บและเรียกใช้ข้อมูลสถานที่ท่องเที่ยวผ่าน Firebase Cloud Firestore
3. เพื่อพัฒนาระบบสมาชิกผู้ใช้ด้วย Firebase Authentication และจัดเก็บข้อมูลส่วนบุคคล เช่น profile, preferences, history และ settings
4. เพื่อพัฒนาระบบแนะนำสถานที่ท่องเที่ยวแบบ Content-Based Recommendation/KNN-style โดยใช้คุณลักษณะของสถานที่และความสนใจของผู้ใช้
5. เพื่อพัฒนาระบบวิดีโอท่องเที่ยวที่ผู้ใช้สามารถอัปโหลด แก้ไข ลบ และผูกวิดีโอกับสถานที่ท่องเที่ยวหรือ Google Maps ได้
6. เพื่อออกแบบ UI/UX ของแอปให้ใช้งานง่าย ทันสมัย และเหมาะกับแอปท่องเที่ยวบนอุปกรณ์เคลื่อนที่

### 6.3 ขอบเขตของระบบ

ขอบเขตเดิมควรอัปเดตจากภาพกว้างเป็นขอบเขตที่ทำจริง:

- ระบบลงทะเบียน เข้าสู่ระบบ และรีเซ็ตรหัสผ่าน
- ระบบจัดการข้อมูลผู้ใช้และรูปโปรไฟล์
- ระบบเลือกความสนใจ เช่น ภูมิภาค จังหวัด หมวดหมู่ ประเภท และกิจกรรม
- ระบบบันทึกความสนใจของผู้ใช้
- ระบบแนะนำสถานที่ท่องเที่ยวตามความสนใจ
- ระบบค้นหาสถานที่ท่องเที่ยว
- ระบบแสดงรายละเอียดสถานที่ รูปภาพ YouTube และ Google Maps
- ระบบบันทึกประวัติการเข้าชม
- ระบบอัปโหลดวิดีโอท่องเที่ยวโดยผู้ใช้
- ระบบจัดการวิดีโอของตนเอง
- ระบบตั้งค่าการใช้งานเบื้องต้น

สิ่งที่ควรระบุว่าไม่อยู่ในขอบเขต:

- ยังไม่ครอบคลุมสถานที่ท่องเที่ยวทั่วประเทศไทยทั้งหมด เน้นภาคเหนือและภาคใต้
- ยังไม่ใช้ Deep Learning
- ยังไม่ใช้ระบบอนุมัติวิดีโอโดยผู้ดูแล
- ยังไม่มี Web Admin Dashboard production
- ยังไม่ deploy backend KNN บน server สาธารณะ
- ระบบรูปภาพถาวรยังต้องพัฒนาต่อ เนื่องจาก Google Places photo URL บางส่วนมีอายุ/สิทธิ์การเข้าถึงจำกัด

### 6.4 ประโยชน์ที่คาดว่าจะได้รับ

ควรเพิ่มประโยชน์ด้านประสบการณ์ผู้ใช้:

- ผู้ใช้ได้รับคำแนะนำสถานที่ที่สอดคล้องกับความสนใจ
- ลดเวลาในการค้นหาสถานที่ท่องเที่ยว
- สามารถดูข้อมูลสถานที่ รูปภาพ วิดีโอ และตำแหน่งได้ในแอปเดียว
- ผู้ใช้สามารถแบ่งปันวิดีโอแนะนำสถานที่ให้ผู้อื่นได้
- ระบบสามารถนำ history และ interaction ไปต่อยอด recommendation ในอนาคต

## 7. สิ่งที่ต้องอัปเดตในบทที่ 2

บทที่ 2 เดิมมีหัวข้อหลัก:

- Machine Learning
- Data Mining
- K-Nearest Neighbors
- Recommender Systems
- Content-Based Filtering
- งานวิจัยที่เกี่ยวข้อง

หัวข้อเหล่านี้ยังใช้ได้ แต่ควรเพิ่ม/ปรับให้ตรงกับงานจริงมากขึ้น

### 7.1 เพิ่ม Firebase และ Cloud Database

ควรเพิ่มหัวข้อเกี่ยวกับ:

- Firebase
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Security Rules

เหตุผล: ระบบปัจจุบันไม่ได้เป็น prototype local data แล้ว แต่ใช้ Firebase เป็นโครงสร้างหลักของระบบจริง

### 7.2 เพิ่ม Mobile Application Development ด้วย Flutter

ควรเพิ่ม/ขยายหัวข้อ Flutter:

- Flutter เป็น cross-platform framework
- ใช้ Dart
- รองรับ Android, Web และ platform อื่น
- เหมาะกับการทำ prototype และ mobile app ที่มี UI หลายหน้า

### 7.3 ปรับ KNN ให้เป็น recommendation ไม่ใช่ classification

จุดสำคัญ: ถ้าเขียนเรื่อง accuracy แบบ classification ต้องระวัง เพราะระบบนี้เป็น recommendation/ranking ไม่ใช่ classification โดยตรง

ควรใช้ metric เช่น:

- Precision@10
- Recall@10
- F1@10
- Hit Rate@10
- Cosine Similarity

ถ้าจะพูดเรื่อง Weka หรือ Accuracy ให้เขียนว่าเป็นการทดลองเปรียบเทียบ/การทดลอง classification เสริม ไม่ใช่ metric หลักของระบบแนะนำ

### 7.4 เพิ่ม User-interest / Interaction Dataset

ตอนนี้ dataset หลักของเราคือ attraction dataset แต่ยังไม่มี dataset พฤติกรรมผู้ใช้จริงจำนวนมาก เช่น rating, click, save, view, watch time

ควรเพิ่มแนวคิดในบทที่ 2 ว่า:

- ระบบแนะนำสามารถใช้ข้อมูล content-based จาก feature ของสถานที่ได้
- หากมี interaction dataset เช่น ประวัติการเข้าชม การกดถูกใจ การดูวิดีโอ หรือ rating จะสามารถต่อยอดเป็น behavior-based หรือ hybrid recommendation ได้
- งานปัจจุบันใช้ explicit preference จากผู้ใช้เป็น input หลัก
- ในอนาคตสามารถเพิ่ม user-interest dataset จาก external dataset หรือจาก log ของแอปจริง

### 7.5 เพิ่ม Video/User-generated Content

ควรเพิ่มแนวคิดเกี่ยวกับวิดีโอสั้นในแอปท่องเที่ยว:

- วิดีโอช่วยให้ผู้ใช้เห็นบรรยากาศของสถานที่จริง
- User-generated content ช่วยเพิ่มความน่าเชื่อถือและความสดใหม่ของข้อมูล
- ในระบบนี้วิดีโอไม่ได้จำเป็นต้องมาจาก TikTok แต่เป็นวิดีโอท่องเที่ยวที่ผู้ใช้อัปโหลดเอง

## 8. สิ่งที่ต้องอัปเดตในบทที่ 3

บทที่ 3 เดิมมีแผนดำเนินงาน เครื่องมือ ขั้นตอน และวิธีทดสอบระบบ ควรอัปเดตให้ตรงกับ architecture ใหม่

### 8.1 เครื่องมือด้านซอฟต์แวร์

ควรเขียนเครื่องมือใหม่ให้ครบ:

- Flutter / Dart สำหรับ Mobile Application
- Firebase Core สำหรับเชื่อม Firebase
- Firebase Authentication สำหรับ Login/Register/Forgot Password
- Cloud Firestore สำหรับฐานข้อมูลสถานที่ ผู้ใช้ ประวัติ และวิดีโอ
- Firebase Storage สำหรับเก็บรูปโปรไฟล์และไฟล์วิดีโอ
- Python สำหรับ dataset preparation, analytics และ KNN experiment
- FastAPI สำหรับ recommendation backend
- Scikit-learn สำหรับ KNN/cosine similarity
- Pandas สำหรับจัดการ dataset
- Google Colab สำหรับทดลองและ export model artifact
- Google Places/YouTube API สำหรับ media enrichment บางส่วน
- Figma สำหรับออกแบบ UI/UX
- Git/GitHub สำหรับ version control

### 8.2 โครงสร้างระบบใหม่

ควรแก้ diagram/คำอธิบาย architecture เป็น:

```text
User
  -> Flutter Mobile App
      -> Firebase Authentication
      -> Cloud Firestore
          -> attractions
          -> users
          -> history
          -> videos
      -> Firebase Storage
          -> profile_images
          -> user_videos
      -> FastAPI Recommendation Backend
          -> KNN / Cosine Similarity .pkl artifact
```

### 8.3 Flow การใช้งานปัจจุบัน

ควรเขียน flow ใหม่:

```text
Start
-> Login/Register
-> ถ้ามี preferences แล้ว ไป Home
-> ถ้ายังไม่มี preferences ไป Location
-> เลือกภูมิภาค/จังหวัด
-> เลือก Category/Type/Activity
-> Home Recommendation
-> Detail
-> Video Feed
-> Upload Video
-> Profile
-> History/My Videos/Settings/About/Logout
```

### 8.4 Data Flow การแนะนำสถานที่

ควรเขียนว่า:

1. ผู้ใช้เลือก region/province/category/type/activity
2. ระบบบันทึก preference ลง Firestore
3. Flutter โหลดข้อมูลสถานที่จาก Firestore
4. Flutter ส่ง preference ไปยัง FastAPI recommendation backend
5. backend โหลด `.pkl` artifact และคำนวณ similarity/ranking
6. backend ส่งผลลัพธ์อันดับสถานที่กลับมา
7. Flutter นำ `sourceRow` หรืออันดับที่ได้ไป match กับข้อมูลสถานที่จาก Firestore
8. ถ้า backend ไม่พร้อมใช้งาน แอป fallback เป็น scoring/filtering ใน Flutter

### 8.5 Data Flow การอัปโหลดวิดีโอ

ควรเพิ่ม flow:

1. ผู้ใช้กดปุ่ม `+` ใน bottom navigation
2. เลือกไฟล์วิดีโอ
3. เลือกสถานที่จากในแอป 1 แห่ง หรือกรอก Google Maps link
4. กรอกคำบรรยาย
5. Upload file ไป Firebase Storage
6. สร้าง document metadata ใน Firestore collection `videos`
7. Video Feed แสดงวิดีโอทันที
8. เจ้าของคลิปสามารถ edit/delete ได้

### 8.6 Database Design

ควรเพิ่ม schema อย่างน้อย 4 ส่วน:

`attractions`

```text
sourceRow, id, nameTh, nameEn, description, region, province,
category, type, activity, images, youtubeUrls, videoUrls,
latitude, longitude, tags
```

`users/{uid}`

```text
displayName, email, photoUrl, preferences, settings,
createdAt, updatedAt
```

`history`

```text
placeDocumentId, sourceRow, viewedAt, placeSnapshot
```

`videos`

```text
videoUrl, storagePath, caption, placeMode, attractionId,
attractionName, province, region, googleMapsUrl,
uploadedByUid, uploadedByName, uploadedByEmail, uploadedByPhotoUrl,
status, createdAt, updatedAt
```

### 8.7 วิธีการทดสอบระบบ

ควรเพิ่ม test case ให้ตรงกับฟีเจอร์จริง:

- Register ด้วย Email/Password
- Login และ session persistence
- Forgot password
- เลือก preference ครั้งแรก
- กลับมาแก้ preference แล้วข้อมูลเดิมยังอยู่
- Home แสดง recommendation
- Search ค้นสถานที่ได้
- Detail เปิดรูป/YouTube/Google Maps ได้
- History เพิ่มสถานที่เมื่อเข้าชม และไม่ซ้ำ
- Upload Video ด้วยสถานที่จากในแอป
- Upload Video ด้วย Google Maps link
- Video Feed แสดงวิดีโอที่อัปโหลด
- เจ้าของวิดีโอ edit/delete ได้
- Profile เปลี่ยนรูปได้
- My Videos แสดงเฉพาะวิดีโอของผู้ใช้
- Settings เปิด/ปิด autoplay/mute/history ได้
- Firestore/Storage rules ป้องกันการแก้ข้อมูลของผู้อื่น

## 9. แนวทางเขียนบทที่ 4

บทที่ 4 ควรเป็นผลการพัฒนาและผลการทดสอบระบบ โดยแนะนำให้แบ่งดังนี้

### 9.1 ผลการพัฒนาแอปพลิเคชัน

ใส่ screenshot และอธิบายแต่ละหน้า:

- หน้า Start
- หน้า Login
- หน้า Register
- หน้า Forgot Password
- หน้า Location Preference
- หน้า Interest Preference
- หน้า Home
- หน้า Detail
- หน้า Video Feed
- หน้า Upload Video
- หน้า Profile
- หน้า History
- หน้า My Videos
- หน้า Settings
- หน้า About App

### 9.2 ผลการเชื่อม Firebase

ควรใส่:

- Firebase Project
- Firestore collection `attractions` จำนวน 2,994 documents
- Auth provider Email/Password enabled
- Storage bucket created
- ตัวอย่าง document ใน `attractions`
- ตัวอย่าง document ใน `videos`
- ตัวอย่าง document ใน `users`

### 9.3 ผลการจัดการ Dataset

ควรใส่:

- จำนวนสถานที่ 2,994
- ภาคเหนือ/ภาคใต้
- จังหวัด 31 จังหวัด
- category 3
- type 52
- activity 18
- ตารางความครบถ้วนของข้อมูล
- ไฟล์ analytics
- ตัวอย่าง feature transform table

### 9.4 ผลการทดลอง Recommendation

ควรเขียนตามสถานะจริง:

- ใช้ feature: region, province, category, type, activity
- ใช้ one-hot encoding
- แยก activity ที่มีหลายค่า
- weight:
  - region = 2.0
  - province = 2.5
  - category = 3.0
  - type = 3.0
  - activity = 4.0
- feature matrix ขนาด 2,994 x 107
- ทดลอง 50 preference cases
- ใช้ metric: precision@10, recall@10, f1@10, hit_rate@10
- มีผลลัพธ์ใน `dataset/model_results`

หมายเหตุสำคัญสำหรับบทที่ 4:

ตอนนี้ยังไม่ควรเขียนว่า KNN model production เสร็จสมบูรณ์จนกว่าจะเทรน `NearestNeighbors.fit()` และ export `.pkl` ใหม่ แต่สามารถเขียนว่าได้สร้าง KNN-style recommendation pipeline และ evaluation เบื้องต้นแล้ว

### 9.5 ผลการทดสอบฟังก์ชันระบบ

ทำตาราง test case:

| ลำดับ | กรณีทดสอบ | ผลที่คาดหวัง | ผลลัพธ์ |
|---|---|---|---|
| 1 | สมัครสมาชิก | สร้างบัญชีใน Firebase Auth ได้ | ผ่าน |
| 2 | เข้าสู่ระบบ | เข้าสู่ Home/Preference ได้ | ผ่าน |
| 3 | บันทึก Preference | โหลดค่ากลับมาได้ | ผ่าน |
| 4 | ค้นหาสถานที่ | แสดงผลตามคำค้น | ผ่าน |
| 5 | เปิด Detail | แสดงข้อมูลสถานที่ | ผ่าน |
| 6 | Upload Video | Storage/Firestore สร้างข้อมูล | ผ่าน |
| 7 | Delete Video | ลบเฉพาะคลิปตัวเอง | ผ่าน |
| 8 | History | ไม่บันทึกสถานที่ซ้ำ | ผ่าน |
| 9 | Settings | บันทึกค่าได้ | ผ่าน |

## 10. แนวทางเขียนบทที่ 5

บทที่ 5 ควรมี 3 ส่วนหลัก:

### 10.1 สรุปผลการดำเนินงาน

สรุปว่าโครงงานสามารถพัฒนาแอปพลิเคชันแนะนำสถานที่ท่องเที่ยวตามความสนใจส่วนบุคคลได้ โดยระบบรองรับการสมัครสมาชิก เลือกความสนใจ แนะนำสถานที่ ค้นหาสถานที่ ดูรายละเอียด ดูวิดีโอ อัปโหลดวิดีโอ จัดการโปรไฟล์ ประวัติ และตั้งค่า

### 10.2 ปัญหาและอุปสรรค

ควรใส่:

- Google Places photo URL บางส่วนหมดอายุหรือเข้าถึงไม่ได้ ทำให้ต้องมี fallback image
- YouTube embed บน mobile/web มีข้อจำกัดเรื่อง platform view และ error บางกรณี
- การอัปโหลดวิดีโอจริงต้องใช้ Firebase Storage และเปิด billing
- KNN recommendation ต้องระวังเรื่อง metric เพราะเป็น ranking ไม่ใช่ classification
- ต้องเทรน `.pkl` ใหม่ให้เป็น estimator ที่ fit แล้ว
- การทดสอบบนมือถือจริงยังเลื่อนไว้ก่อนจนระบบหลักนิ่ง

### 10.3 ข้อเสนอแนะและงานในอนาคต

ควรใส่:

- เทรน KNN model จริงและ export `.pkl` ใหม่
- เพิ่ม user-interest/interaction dataset จากประวัติการใช้งานจริง
- ทดลอง hybrid recommendation โดยใช้ content + behavior
- ทำระบบรูปภาพถาวร เช่นเก็บรูปที่ Firebase Storage/CDN แทนพึ่ง Google Places URL โดยตรง
- เพิ่มระบบ admin dashboard สำหรับจัดการสถานที่/วิดีโอ
- เพิ่มระบบ moderation สำหรับ user-uploaded video
- ทดสอบบนมือถือจริงและ build APK
- เปลี่ยน logo, graphic, app name เป็น final design

## 11. สถานะ KNN และ User-interest Dataset

### 11.1 KNN ปัจจุบัน

สิ่งที่ทำแล้ว:

- เตรียมข้อมูลจาก attraction dataset
- เลือก feature: region, province, category, type, activity
- ทำ one-hot encoding
- แยก activity หลายค่า
- กำหนด weight
- สร้าง feature matrix
- ทดลอง cosine similarity
- ทดลอง optional province
- ประเมินผล 50 preference cases
- export artifact `.pkl` รุ่นทดลอง

สิ่งที่ยังต้องทำ:

- สร้าง sklearn `NearestNeighbors`
- เทรนด้วย `model.fit(feature_matrix)`
- export `.pkl` ใหม่ที่มี estimator จริง
- แก้ backend จากคำนวณ cosine เองให้ใช้ `model.kneighbors()`
- ทดสอบผลกับ Flutter end-to-end

### 11.2 User-interest / Interaction Dataset

ตอนนี้ยังไม่มี dataset พฤติกรรมผู้ใช้จริงของแอป เช่น rating, click, favorite, watch time หรือ visit log จำนวนมาก เพราะแอปยังไม่ได้เปิดใช้งานกับผู้ใช้จริง

แนวทางที่แนะนำ:

1. ใช้ preference ที่ผู้ใช้เลือกในแอปเป็น explicit interest dataset เบื้องต้น
2. ใช้ history/video interaction ในแอปเป็น implicit interaction dataset ในอนาคต
3. หา external dataset ด้าน tourism review/rating มาเป็นข้อมูลเสริมเพื่ออธิบายแนวคิด user-interest
4. clean external dataset ให้ map เข้ากับ field ของเรา เช่น category, type, activity, region/province
5. ใช้ external dataset เป็นส่วนทดลอง ไม่ควรแทน dataset สถานที่ไทย 2,994 รายการ เพราะ dataset หลักของแอปต้องเป็นข้อมูลสถานที่ในประเทศไทย

ตัวอย่าง field ที่ควรเก็บใน interaction dataset หากสร้างเอง:

```text
userId
placeId
eventType: view/search/detail_open/video_watch/save/rating
category
type
activity
region
province
timestamp
durationSeconds
rating
```

## 12. ไฟล์และโฟลเดอร์สำคัญที่เพื่อนควรรู้

Root project:

```text
C:\flutter\flutter-Project\project
```

Flutter source:

```text
C:\flutter\flutter-Project\project\lib
```

หน้าหลัก:

```text
C:\flutter\flutter-Project\project\lib\pages\start_page.dart
C:\flutter\flutter-Project\project\lib\pages\login_page.dart
C:\flutter\flutter-Project\project\lib\pages\register_page.dart
C:\flutter\flutter-Project\project\lib\pages\location_page.dart
C:\flutter\flutter-Project\project\lib\pages\interest_page.dart
C:\flutter\flutter-Project\project\lib\pages\home_page.dart
C:\flutter\flutter-Project\project\lib\pages\detail_page.dart
C:\flutter\flutter-Project\project\lib\pages\tiktok_page.dart
C:\flutter\flutter-Project\project\lib\pages\upload_video_page.dart
C:\flutter\flutter-Project\project\lib\pages\profile_page.dart
C:\flutter\flutter-Project\project\lib\pages\history_page.dart
C:\flutter\flutter-Project\project\lib\pages\my_videos_page.dart
C:\flutter\flutter-Project\project\lib\pages\settings_page.dart
C:\flutter\flutter-Project\project\lib\pages\about_app_page.dart
```

Repository/data layer:

```text
C:\flutter\flutter-Project\project\lib\data\place_repository.dart
C:\flutter\flutter-Project\project\lib\data\recommendation_repository.dart
C:\flutter\flutter-Project\project\lib\data\user_repository.dart
C:\flutter\flutter-Project\project\lib\data\history_repository.dart
C:\flutter\flutter-Project\project\lib\data\video_repository.dart
```

Backend:

```text
C:\flutter\flutter-Project\project\backend\main.py
C:\flutter\flutter-Project\project\backend\models\travel_recommendation_knn_model_v1.pkl
C:\flutter\flutter-Project\project\backend\README.md
```

Dataset:

```text
C:\flutter\flutter-Project\project\dataset\#5 finish_attraction_enriched.xlsx
C:\flutter\flutter-Project\project\dataset\attractions.json
C:\flutter\flutter-Project\project\dataset\analytics
C:\flutter\flutter-Project\project\dataset\model_results
C:\flutter\flutter-Project\project\dataset\youtube
```

Firebase rules:

```text
C:\flutter\flutter-Project\project\firestore.rules
C:\flutter\flutter-Project\project\storage.rules
```

เอกสารสถานะ:

```text
C:\flutter\flutter-Project\project\README.md
C:\flutter\flutter-Project\project\PROJECT_STATUS.md
C:\flutter\flutter-Project\project\CODEX_HANDOFF.md
C:\flutter\flutter-Project\project\SETUP_HOME_PC.md
```

## 13. คำสั่งที่ใช้รันและตรวจสอบ

ติดตั้ง dependency:

```powershell
cd C:\flutter\flutter-Project\project
flutter pub get
```

รันแอป:

```powershell
flutter run
```

รัน web:

```powershell
flutter run -d chrome
```

รัน backend:

```powershell
cd C:\flutter\flutter-Project\project\backend
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

รัน Flutter พร้อม backend URL:

```powershell
cd C:\flutter\flutter-Project\project
flutter run -d chrome --dart-define=RECOMMENDATION_API_URL=http://127.0.0.1:8000
```

ตรวจ code:

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## 14. งานที่ยังเหลือก่อนส่งเล่มสมบูรณ์

งานระบบที่ยังเหลือ:

1. เทรน KNN `.pkl` ใหม่ให้มี `NearestNeighbors.fit()` จริง
2. แก้ FastAPI ให้ใช้ `model.kneighbors()`
3. ทดสอบ recommendation end-to-end หลังเปลี่ยน `.pkl`
4. พิจารณา external user-interest/interaction dataset เพื่อใช้เสริมในรายงานหรือการทดลอง
5. แก้ระบบรูปภาพสถานที่ให้ถาวรหรือเลือกแนวทาง fallback ที่เหมาะสม
6. ทดสอบบนมือถือจริง หลังระบบหลักนิ่ง
7. Build APK สำหรับส่ง/สาธิต
8. ทำ logo, graphic, app name final ตามที่ผู้พัฒนาจะออกแบบเอง
9. เก็บ screenshot final สำหรับบทที่ 4
10. commit/push GitHub ให้ครบก่อนย้ายเครื่องหรือส่งงาน

งานเอกสารที่ทำได้เลย:

1. อัปเดตบทที่ 1 ตามขอบเขตระบบล่าสุด
2. อัปเดตบทที่ 2 เพิ่ม Firebase, Flutter, Storage, Video Feed, Evaluation metrics, User-interest dataset
3. อัปเดตบทที่ 3 เพิ่ม architecture, data flow, database schema, test cases
4. เริ่มเขียนบทที่ 4 ด้วย screenshot และผลการพัฒนา
5. ร่างบทที่ 5 โดยใส่สรุปผล ปัญหา และงานในอนาคต

งานเอกสารที่ควรรอข้อมูลเพิ่ม:

1. ผล KNN final หลังเทรน `.pkl` ใหม่
2. Screenshot UI final หลังจบงานตกแต่ง
3. ผลทดสอบบนมือถือจริง
4. ผล build APK final
5. ชื่อแอป/logo/graphic final

## 15. ข้อความสรุปสั้นสำหรับส่งให้เพื่อน

โปรเจกต์นี้พัฒนาจาก prototype Flutter ที่อ่านข้อมูลจาก local JSON ไปเป็นแอปพลิเคชันที่เชื่อม Firebase จริงแล้ว โดยข้อมูลสถานที่ท่องเที่ยวจำนวน 2,994 รายการถูก import เข้า Cloud Firestore collection `attractions` และแอปอ่านข้อมูลจาก Firestore เป็นหลัก ระบบ Login/Register เปลี่ยนจาก mockup เป็น Firebase Authentication และมีการบันทึกข้อมูลผู้ใช้ เช่น preferences, profile, settings และ history ลง Firestore

ด้านฟีเจอร์ แอปมี flow ครบตั้งแต่ Start, Login/Register, เลือกภูมิภาค/จังหวัด, เลือกความสนใจ, Home Recommendation, Search, Detail, Video Feed, Upload Video, Profile, History, My Videos, Settings และ About App โดยฟีเจอร์ TikTok เดิมถูกเปลี่ยนเป็น Video Feed ที่ให้ผู้ใช้อัปโหลดวิดีโอท่องเที่ยวเอง วิดีโอถูกเก็บใน Firebase Storage และ metadata ถูกเก็บใน Firestore collection `videos` เจ้าของคลิปสามารถแก้ไขรายละเอียดและลบคลิปได้

ด้าน recommendation มีการสร้าง KNN-style content-based recommendation pipeline แล้ว โดยใช้ feature ได้แก่ region, province, category, type และ activity มีการทำ one-hot encoding, ใส่ weight, คำนวณ cosine similarity และประเมินผลด้วย precision@10, recall@10, f1@10 และ hit_rate@10 จาก preference cases จำนวน 50 เคส อย่างไรก็ตามไฟล์ `.pkl` ปัจจุบันยังเป็น artifact รุ่นทดลองที่เก็บ matrix และ metadata ยังไม่ใช่ sklearn `NearestNeighbors` estimator ที่ fit แล้ว จึงต้องเทรนและ export `.pkl` ใหม่ก่อนปิดงาน Machine Learning อย่างสมบูรณ์

ด้านรายงาน บทที่ 1 ต้องแก้ขอบเขตให้ตรงกับระบบจริงที่มี Firebase Auth/Firestore/Storage และ Video Upload บทที่ 2 ต้องเพิ่มหัวข้อ Firebase, Flutter, Cloud Storage, Video/User-generated Content, Recommendation Metrics และ User-interest Dataset บทที่ 3 ต้องแก้ architecture, data flow, database schema และ test cases ให้ตรงกับระบบปัจจุบัน บทที่ 4 สามารถเริ่มเขียนผลการพัฒนาและผลการทดสอบจากแอปได้แล้ว ส่วนบทที่ 5 สามารถร่างสรุป ปัญหา และงานในอนาคตได้ โดยเว้นส่วน KNN final และ mobile test ไว้อัปเดตภายหลัง

