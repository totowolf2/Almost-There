# Almost There! – Location Alarm App

**App icon**: `icon.png` (วางข้าง README)  
**คำอธิบายสั้น**: แอพปลุกแจ้งเตือนเมื่อใกล้ถึงจุดหมาย ใช้งานง่ายเหมือนนาฬิกาปลุก สามารถตั้งปลุกหลายจุด, ทั้งแบบครั้งเดียวและแบบประจำ, พร้อมการ์ดระยะทางบนหน้าล็อกสกรีน

---

## รายละเอียดการทำงาน

### ฟีเจอร์หลัก
- **ปลุกแบบครั้งเดียว (One-time / Trip)**  
  ใช้ในบางโอกาส เช่น ทริปพิเศษ กดเปิดเมื่อเริ่มเดินทาง ทริกเกอร์ครั้งเดียวแล้วปิดเอง
- **ปลุกแบบประจำ (Recurring / General)**  
  ใช้งานทุกวัน หรือในวันที่เลือก กำหนดได้ว่าจะทำงานอัตโนมัติทุกครั้ง หรือกดเปิดเอง
- **หลายปลุกพร้อมกัน**: เปิดหลายรายการได้, จัดการทับซ้อนด้วยการยิงตัวที่ใกล้ที่สุดก่อน และมี cool-off
- **การ์ดระยะทาง (Live Card)**: แสดงระยะถึงจุดหมายและจุดเตือนบนหน้าล็อกสกรีน อัปเดตตามการเคลื่อนที่ ปิด/เปิดได้ทั้งระบบ, รายโปรไฟล์, หรือปิดชั่วคราว
- **ตั้งรัศมีเตือน**: ปรับเป็นเมตร (ค่าเริ่ม 300 ม.)
- **เลือกเสียง**: Default + เสียงเพิ่มเติมในแอพ
- **Snooze**: ระงับปลุกชั่วคราว (ค่าเริ่ม 5 นาที)
- **จัดกลุ่ม**: รวมปลุกเป็นหมวด เช่น ขาไปทำงาน, ขากลับบ้าน
- **จัดการง่ายเหมือนแอพนาฬิกา**: แตะเพื่อแก้ไข, กดค้างเพื่อเปิดเมนูการกระทำด้านล่าง
- **ป้องกันการกินแบต**: ใช้ Android Geofencing API + Fused Location Provider แบบ balanced สำหรับ Live Card

### เงื่อนไขการทำงาน
- ปลุกที่ **enabled=true** จะลงทะเบียน geofence อัตโนมัติ (สำหรับ recurring-auto และ recurring-manual/one-time ที่กดเปิด)
- หลังบูตเครื่อง แอพลงทะเบียนคืนเฉพาะปลุกที่ `enabled` และเป็น recurring-auto หรือ recurring-manual ที่เปิดก่อนรีบูต
- one-time จะถูกปิดหลังทริกเกอร์ หรือหมดอายุรอทริกเกอร์ (24 ชม.)

---

## UX / UI

### หน้าหลัก: Alarms List
- แสดงรายการปลุกทั้งหมด, สวิตช์เปิด/ปิดอยู่ด้านซ้าย, ไม่มีปุ่มแก้ไข/ลบบนรายการ
- **แตะ**: แก้ไขปลุก
- **กดค้าง**: เปิด **Bottom Action Sheet**:
  - เปิด/ปิดปลุก
  - จัดกลุ่ม
  - ลบ
  - เลือกหลายรายการ
  - ทำซ้ำ
  - แชร์พิกัด (ถ้าอนุญาต)
- โหมด **Multi-select**: แถบล่างมี [เพิ่มเข้ากลุ่ม] [เปิดทั้งหมด] [ปิดทั้งหมด] [ลบ]

### เพิ่ม/แก้ไขปลุก (Add/Edit)
- Label
- Type: One-time / Recurring
- วันทำงาน (ถ้า recurring)
- Pick on Map → Map Picker
- Radius slider
- Sound selector + preview
- Snooze selector
- Live Card toggle
- Enabled toggle
- Save / Cancel

### Map Picker
- OSM map + pin center
- Search box
- Radius slider
- Confirm / Cancel

### Settings
- Defaults (type, radius, snooze, sound)
- Live Card (global toggle, update interval, min distance)
- Overlap & limits (max active, cool-off, debounce, suppression)
- Permissions status
- Battery tips

### Onboarding / Permissions
- Precise Location → Background Location → Notifications (Android 13+)
- อธิบายเหตุผลการใช้สิทธิ์สั้นๆ

### Battery Tips
- แนะนำยกเว้นแบตเตอรี่
- ลิงก์ไปตั้งค่าเฉพาะยี่ห้อ

### Live Card (Ongoing Notification)
- หัวข้อ: `<label> — เหลือ <ระยะ>`
- รายละเอียด: จุดเตือน, ETA
- ปุ่ม: Snooze, Hide for today, Stop

### Trigger Notification
- หัวข้อ: ถึงใกล้ `<label>` แล้ว
- เนื้อหา: ระยะ, ETA
- ปุ่ม: Snooze, Dismiss, Open Map

---

## Theme – โทนธรรมชาติอบอุ่นเหมือนดูแผนที่

### พาเลตหลัก (Light)
- Primary: `#C8664F` (Terracotta)
- On Primary: `#FFFFFF`
- Secondary: `#6F8E6B` (Sage)
- On Secondary: `#0D1A10`
- Tertiary: `#4C768D` (River)
- Background: `#F6F1E6` (Sand)
- Surface: `#FFF9F0` (Parchment)
- Surface Variant: `#EFE6D7` (Map Paper)
- Outline: `#BDAA95`
- Error: `#B3261E` / On Error: `#FFFFFF`

### พาเลต (Dark)
- Primary: `#E08D7C` / On Primary: `#2D0F0A`
- Secondary: `#8FB28A` / On Secondary: `#112016`
- Background: `#191612`
- Surface: `#201C17`
- Surface Variant: `#2A241D`
- Outline: `#8C7A66`

### การใช้งานสี
- ปุ่มหลัก = Primary
- ระยะทาง/ETA = Tertiary
- การ์ด/พื้นหลัง list = Surface/Surface Variant
- วง geofence = Secondary (โปร่ง 48% fill + 100% stroke)

### ตัวอักษร
- ฟอนต์: Noto Sans Thai / Inter
- ขนาด: Title 20–24, Body 14–16, Label 12–14
- Line-height: 1.4–1.6

---

## ตัวอย่าง UX/UI (Markdown Wireframe)

### Alarms List
```text
+--------------------------------------------------+
|  Almost There!                                   |
|  [ + Add ]                         [ ⋯ More ]    |
+--------------------------------------------------+
| [on] บ้าน           one_time 300m                |
|      Lat 13.7, Lon 100.5   Sound: Default        |
+--------------------------------------------------+
| [off] ที่ทำงาน     recurring 300m                |
|      Days: M T W T F   showCard: ON              |
+--------------------------------------------------+
````

(กดค้าง → Bottom Sheet: เปิด/ปิด, จัดกลุ่ม, ลบ, เลือกหลาย, ทำซ้ำ, แชร์พิกัด)

### Bottom Action Sheet

```text
บ้าน
────────────────────────
• เปิด/ปิดปลุก
• จัดกลุ่ม...
• ลบรายการ
────────────────────────
• เลือกหลายรายการ...
• ทำซ้ำ
• แชร์พิกัด
[ยกเลิก]
```

### Add/Edit Alarm

```text
Label: [___________]
Type: (•) One-time   ( ) Recurring
Days: M T W T F S S
Location: [Pick on Map >]
Radius: ---|====   300m
Sound: [Default v] ▶
Snooze: [5 min v]
Live Card: ON
Enabled: ON
[Save] [Cancel]
```

### Map Picker

```text
[ Search box                  ]
[ OSM Map with center pin      ]
[ Radius slider: 300 m         ]
[Confirm] [Cancel]
```

### Settings

```text
Defaults:
 - New alarm type: One-time
 - Radius: 300 m
 - Snooze: 5 min
 - Sound: Default
Live Card:
 - Global: ON
 - Interval: 45 sec
 - Min distance: 200 m
Overlap & Limits:
 - Max active: 30
 - Cool-off: 10 min
 - Debounce: 120 s
 - Suppression: 15 s
Permissions & Battery
 - View permissions
 - Battery optimization tips
```

### Live Card

```text
[🔔] บ้าน — เหลือ 2.3 กม.
จุดเตือน: 300 ม. | ETA ~8 นาที
[Snooze 5m] [Hide today] [Stop]
```

### Trigger Notification

```text
[🚍] ถึงใกล้ "บ้าน" แล้ว — ลงป้ายถัดไป
ภายในรัศมี: 300 ม. เหลือ ~150 ม.
[Snooze 5m] [Dismiss] [Open Map]
```

---

## เอกสาร API / Library ที่ใช้

### Flutter Packages

* flutter\_map (OSM): [https://docs.fleaflet.dev/](https://docs.fleaflet.dev/)
* geolocator: [https://pub.dev/packages/geolocator](https://pub.dev/packages/geolocator)
* flutter\_local\_notifications: [https://pub.dev/packages/flutter\_local\_notifications](https://pub.dev/packages/flutter_local_notifications)
* hive: [https://pub.dev/packages/hive](https://pub.dev/packages/hive)
* riverpod: [https://riverpod.dev/docs/introduction/why_riverpod](https://riverpod.dev/docs/introduction/why_riverpod)

### Android APIs (Native)

* GeofencingClient (Play services): [https://developers.google.com/android/reference/com/google/android/gms/location/GeofencingClient](https://developers.google.com/android/reference/com/google/android/gms/location/GeofencingClient)
* Create & monitor geofences: [https://developer.android.com/develop/sensors-and-location/location/geofencing](https://developer.android.com/develop/sensors-and-location/location/geofencing)
* FusedLocationProviderClient: [https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient](https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient)
* Request location updates: [https://developer.android.com/training/location/request-updates](https://developer.android.com/training/location/request-updates)
* Background location guidelines: [https://developer.android.com/training/location/background](https://developer.android.com/training/location/background)
* POST\_NOTIFICATIONS (Android 13+): [https://developer.android.com/develop/ui/views/notifications/notification-permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
* Foreground services overview: [https://developer.android.com/develop/background-work/services/fgs](https://developer.android.com/develop/background-work/services/fgs)
* Foreground service types (Android 14+): [https://developer.android.com/about/versions/14/changes/fgs-types-required](https://developer.android.com/about/versions/14/changes/fgs-types-required)

### OSM Usage

* Tile Usage Policy: [https://operations.osmfoundation.org/policies/tiles/](https://operations.osmfoundation.org/policies/tiles/)

---

## Metadata

* **App name**: Almost There!
* **Theme**: โทนธรรมชาติอบอุ่น เหมือนแผนที่กระดาษ
* **Icon**: icon.png
* **Target**: Android (minSdk 24, targetSdk 34)
* **Language**: Flutter + Native Android (Kotlin)

