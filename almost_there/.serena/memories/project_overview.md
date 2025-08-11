# Almost There! - Location Alarm App

## Project Purpose
"Almost There!" เป็นแอพแจ้งเตือนเมื่อใกล้ถึงจุดหมาย ใช้งานง่ายเหมือนนาฬิกาปลุก สามารถตั้งปลุกหลายจุด ทั้งแบบครั้งเดียว (One-time/Trip) และแบบประจำ (Recurring/General) พร้อมการ์ดระยะทางบนหน้าล็อกสกรีน

## Tech Stack
- **Frontend**: Flutter with Dart
- **State Management**: Riverpod
- **Local Storage**: Hive (NoSQL database)
- **Maps**: OpenStreetMap with flutter_map
- **Location Services**: geolocator, geocoding
- **Notifications**: flutter_local_notifications
- **Audio**: just_audio for sound preview
- **Native Android**: Kotlin for geofencing services

## Key Features
1. **One-time Alarms**: สำหรับทริปพิเศษ ทริกเกอร์ครั้งเดียวแล้วปิดเอง
2. **Recurring Alarms**: ใช้งานทุกวัน หรือในวันที่เลือก
3. **Multiple Active Alarms**: รองรับหลายปลุกพร้อมกัน
4. **Live Distance Cards**: แสดงระยะถึงจุดหมายบน notification
5. **Geofencing**: ใช้ Android Geofencing API + Fused Location Provider
6. **Customizable**: เลือกเสียง, รัศมีเตือน, snooze

## Architecture
- **lib/**: Flutter/Dart code
  - **data/**: Models, services, repositories
  - **presentation/**: UI screens, widgets, providers, theme
  - **platform/**: Platform channels (geofencing_platform.dart)
  - **core/**: Constants, errors, utilities
- **android/**: Native Android code (Kotlin)
  - Geofencing services and receivers
  - Notification management
  - Location tracking services