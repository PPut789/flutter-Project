import 'package:flutter/material.dart';

import '../widgets/app_chrome.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MinimalHeader(title: 'เกี่ยวกับแอป'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
                children: const [
                  _AboutLogo(),
                  SizedBox(height: 30),
                  _AboutTextSection(
                    title: 'ชื่อโครงการ',
                    body:
                        'แอปพลิเคชันแนะนำสถานที่ท่องเที่ยวในประเทศไทยตามความสนใจส่วนบุคคลด้วย AI',
                  ),
                  _AboutTextSection(
                    title: 'ข้อมูลสถานที่',
                    body:
                        'ครอบคลุมสถานที่ท่องเที่ยว 2,994 แห่ง ใน 31 จังหวัดทั่วประเทศไทย เพื่อให้คุณได้ค้นพบสถานที่ที่ตรงกับความต้องการของคุณมากที่สุด',
                  ),
                  _AboutTextSection(
                    title: 'ระบบแนะนำอัจฉริยะ',
                    body:
                        'K-Nearest Neighbors (KNN): ระบบใช้ Algorithm KNN เพื่อวิเคราะห์ความสนใจและประวัติการเข้าชมของคุณ เพื่อเปรียบเทียบและค้นหาสถานที่ที่คล้ายคลึงกัน\n\nFirebase: ใช้ในการจัดการฐานข้อมูลและรองรับการใช้งานแบบเรียลไทม์',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLogo extends StatelessWidget {
  const _AboutLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: appPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'TT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'TravelThai',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text('เวอร์ชัน 1.0.0', style: TextStyle(color: appTextMuted)),
      ],
    );
  }
}

class _AboutTextSection extends StatelessWidget {
  final String title;
  final String body;

  const _AboutTextSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF5D5260),
              height: 1.7,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
