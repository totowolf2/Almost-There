# PRP: Ongoing Location Notification (Almost There!)

## Overview

ฟีเจอร์ **Ongoing Location Notification** จะแสดงการ์ดแจ้งเตือนสถานะการเดินทางแบบคงอยู่ตลอดเวลา คล้าย LINE MAN / Grab โดยอัปเดตระยะทางที่เหลือและ ETA บนแถบแจ้งเตือน Android ขณะเดินทาง และให้ผู้ใช้กด action เช่น Snooze, Hide today, Stop ได้ทันทีจากการ์ด โดยจะใช้ **Foreground Service + Custom Notification Layout** เพื่อให้แจ้งเตือนเด่นและอัปเดตได้แบบ real-time

## Context

### Current State
- ปัจจุบันแอพยังไม่มีระบบแจ้งเตือน ongoing แบบคงอยู่บนแถบ notification
- ไม่มีการติดตามตำแหน่งแบบ real-time ระหว่างเดินทาง
- Notification ปัจจุบันมีเฉพาะตอนเข้า geofence แล้วปลุก

**File references (โครงสร้างปัจจุบัน)**  
```

lib/
├── main.dart
├── screens/
│   ├── alarms\_list.dart
│   ├── alarm\_detail.dart
│   └── settings.dart
├── services/
│   ├── location\_service.dart
│   └── notification\_service.dart
└── utils/
└── constants.dart

```

### Requirements
- แสดง ongoing notification ทันทีเมื่อเริ่มเดินทางไปยังจุดหมาย
- แสดง:
  - ระยะทางที่เหลือ (km/m)
  - ETA โดยประมาณ
  - ไอคอนหมุดแผนที่
- Action button:
  - Snooze (หยุดปลุกชั่วคราว)
  - Hide today (ซ่อนวันนี้)
  - Stop (หยุดทริป)
- ปิดได้จาก:
  - Action button
  - เข้าแอพแล้วกดหยุด
- เปิด/ปิดฟีเจอร์ได้ในโปรไฟล์แต่ละปลุก
- ถ้าเปิดแล้วปิดใน notification แต่โปรไฟล์ยังเปิดไว้ → แอพเปิดใหม่จะเริ่มแสดงอีกครั้ง
- ใช้ได้แม้แอพอยู่เบื้องหลัง
- ไม่กินแบตเกินจำเป็น (อัปเดตทุก 30–60s หรือเคลื่อนที่ >150–250m)

**User Stories**
- ในฐานะผู้ใช้ ฉันต้องการให้แอพเตือนว่าฉันเหลือระยะทางเท่าไหร่ จนกว่าจะถึงจุดหมาย เพื่อไม่ให้ลงผิดป้าย
- ในฐานะผู้ใช้ ฉันต้องสามารถหยุดหรือเลื่อนการปลุกได้จาก notification โดยไม่ต้องเข้าแอพ

### Dependencies
- **Flutter packages**
  - [`geolocator`](https://pub.dev/packages/geolocator) – ใช้ติดตามตำแหน่งและคำนวณระยะทาง
  - [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) – ใช้สร้างและอัปเดต notification
  - [`workmanager`](https://pub.dev/packages/workmanager) หรือ [`android_alarm_manager_plus`](https://pub.dev/packages/android_alarm_manager_plus) – รันงานเบื้องหลัง
- **Android APIs**
  - Foreground Service (`startForeground`)
  - Custom Notification Layout (`RemoteViews`)
  - Ongoing Activity API ([Android Developers](https://developer.android.com/guide/topics/ui/device-activity/ongoing))

## Research Findings

### Codebase Analysis
- `notification_service.dart` มีโค้ดเรียก Flutter Local Notifications แล้ว สามารถขยายให้รองรับ ongoing + custom layout ได้
- `location_service.dart` มีการเรียก geolocator อยู่แล้ว สามารถเพิ่ม stream อัปเดตตำแหน่ง

### External Research
- **Documentation**
  - Flutter Local Notifications: https://pub.dev/packages/flutter_local_notifications
  - Android Foreground Service: https://developer.android.com/guide/components/foreground-services
  - RemoteViews for custom notification: https://developer.android.com/develop/ui/views/notifications/custom-notification
  - Ongoing Activities API: https://developer.android.com/guide/topics/ui/device-activity/ongoing
  - Geolocator: https://pub.dev/packages/geolocator
- **Best practices**
  - ใช้ interval update ตาม movement distance เพื่อลดการกินแบต
  - ใช้ `setOnlyAlertOnce(true)` เพื่อไม่ให้มีเสียง/สั่นทุกครั้งที่อัปเดต
  - ปรับ layout ให้ชัดเจนแม้ในโหมด collapsed
- **Common pitfalls**
  - ลืมขอ permission `ACCESS_BACKGROUND_LOCATION` ทำให้หยุด tracking เมื่อจอปิด
  - Notification channel importance ต่ำ ทำให้ไม่เห็นการ์ด

## Implementation Plan

### Pseudocode/Algorithm
```

On trip start:
startForegroundService()
createNotificationChannel()
while trip\_active:
location = getCurrentLocation()
distance = calcDistance(location, destination)
eta = calcETA(location, destination)
updateNotification(distance, eta)
sleep(interval) # 30–60s or distance >150m

On snooze:
pause updates for X minutes

On hide today:
stopForegroundService()
mark hidden\_today = true

On stop:
stopForegroundService()
trip\_active = false

```

### Tasks (in order)
1. เพิ่ม permission และ service type ใน AndroidManifest
2. สร้าง notification channel ใหม่สำหรับ ongoing location
3. ปรับ `notification_service.dart` ให้รองรับ custom layout
4. เพิ่ม `location_tracking_service.dart` รัน foreground service
5. เชื่อมกับ `geolocator` เพื่อติดตามตำแหน่ง real-time
6. อัปเดต notification ทุก interval
7. เพิ่ม action button (Snooze, Hide, Stop) → ส่ง intent กลับไปยัง service
8. เชื่อมกับ profile setting เพื่อเปิด/ปิดฟีเจอร์
9. ทดสอบการทำงานเมื่อแอพอยู่ foreground, background, ปิดจอ
10. ปรับ UI collapsed/expanded layout ให้เหมือนตัวอย่าง

### File Structure
```

lib/
├── services/
│   ├── location\_tracking\_service.dart
│   └── notification\_service.dart
android/app/src/main/
├── AndroidManifest.xml
├── java/.../LocationTrackingService.kt

````

## Validation Gates

### Syntax/Style Checks
```bash
flutter analyze
flutter format .
````

### Testing Commands

```bash
flutter test
flutter run --release
```

### Manual Validation

* [ ] Notification แสดงทันทีเมื่อเริ่มเดินทาง
* [ ] แสดงระยะทางและ ETA ถูกต้อง
* [ ] Action ปุ่มทำงานครบ
* [ ] ปิด notification แล้วกลับมาใหม่เมื่อเปิดแอพอีกครั้งถ้าฟีเจอร์ยังเปิด
* [ ] ใช้งานได้ทั้ง foreground และ background

## Error Handling

### Common Issues

* **Permission denied** → แสดง dialog ขอ permission
* **Service killed by OS** → ใช้ foreground service + request ignore battery optimizations

### Troubleshooting

* ตรวจ logcat เพื่อดูสาเหตุ service stop
* ทดสอบบนหลายรุ่น เพราะ behavior ของ notification บน lock screen ต่างกัน

## Quality Checklist

* [ ] ใช้ Foreground Service
* [ ] Custom Layout ถูกต้อง
* [ ] อัปเดตข้อมูล real-time
* [ ] ฟีเจอร์เปิด/ปิดได้ตาม profile
* [ ] Battery usage อยู่ในเกณฑ์ต่ำ

## Confidence Score

8/10 – มี library และตัวอย่างพร้อม แต่ต้องทดสอบหลายยี่ห้อเพราะ behavior Android ต่างกัน

## References

* [https://developer.android.com/guide/components/foreground-services](https://developer.android.com/guide/components/foreground-services)
* [https://developer.android.com/develop/ui/views/notifications/custom-notification](https://developer.android.com/develop/ui/views/notifications/custom-notification)
* [https://developer.android.com/guide/topics/ui/device-activity/ongoing](https://developer.android.com/guide/topics/ui/device-activity/ongoing)
* [https://pub.dev/packages/geolocator](https://pub.dev/packages/geolocator)
* [https://pub.dev/packages/flutter\_local\_notifications](https://pub.dev/packages/flutter_local_notifications)

