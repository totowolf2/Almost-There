## FEATURE:
ทำ "ปลุกก่อนถึง" ให้เหมือนปลุกนาฬิกา

### 1) ใช้ **Full-Screen Intent Notification**

นี่คือวิธีทำให้ตอนปลุก แอพเราเปิดหน้าจอขึ้นมาเต็มจอ (แม้เครื่องจะล็อกอยู่) พร้อมเสียงปลุกและปุ่มหยุด/งีบ

* ต้องสร้าง Notification ที่มี:

  * **`setCategory(Notification.CATEGORY_ALARM)`**
  * **Full-screen intent** → ใช้ `setFullScreenIntent(PendingIntent, true)`
  * **Channel importance = IMPORTANCE\_HIGH / IMPORTANCE\_MAX**
* ระบบจะเปิด Activity ของเราทันทีตอนแจ้งเตือน (แทนที่จะอยู่ใน status bar เฉย ๆ)

📖 Docs:

* [Show an urgent message](https://developer.android.com/develop/ui/views/notifications/build-notification#urgent-message)
* [Permissions changes for fullscreen intents](https://developer.android.com/about/versions/10/behavior-changes-10?utm_source=chatgpt.com#full-screen-intents)
* [Notification categories](https://developer.android.com/develop/ui/views/notifications/channels#importance)

---

### 2) ให้ Activity ปลุกแสดงบน Lock Screen

เพื่อให้แสดงทับ lock screen:

* ใน Activity ปลุก:

  ```java
  setShowWhenLocked(true);
  setTurnScreenOn(true);
  ```

  หรือใช้ flags:

  ```java
  getWindow().addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                       WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
  ```

📖 Docs:

* [Screen Wake Lock API](https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API?utm_source=chatgpt.com)

---

### 3) เล่นเสียงปลุกและสั่น

* ใช้ `AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)` เพื่อให้เสียงเข้าหมวด Alarm
* เปิดลูปเสียงจนผู้ใช้กดหยุด
* เพิ่ม vibration pattern เพื่อเสริมการปลุก
* สามารถใช้เสียงจาก MediaPlayer หรือ RingtoneManager

📖 Docs:

* [Audio attributes](https://developer.android.com/reference/android/media/AudioAttributes)
* [Vibration effect](https://developer.android.com/reference/android/os/VibrationEffect)

---

### 4) ให้ปลุกทำงานแม้จอปิดหรือแอพถูกปัดออก

* ปลุกจะมาจาก **Geofence Trigger** → ตอนเข้าเขตปลุก ให้เปิด **Foreground Service** และยิง Notification full-screen
* ใช้ `foregroundServiceType="location"` ใน manifest เพื่อให้ location ทำงานต่อแม้แอพไม่อยู่ foreground

📖 Docs:

* [Foreground services overview](https://developer.android.com/develop/background-work/services/fgs)
* [GeofencingClient](https://developer.android.com/develop/sensors-and-location/location/geofencing)

---

### 5) ทำให้ทะลุโหมด DND (Do Not Disturb)

* Android จัดหมวด **CATEGORY\_ALARM** เป็นประเภทที่สามารถทะลุ DND ได้ *ถ้า* ผู้ใช้อนุญาต
* ใน Android 13+ และบางยี่ห้อ ผู้ใช้ต้องไปที่ **Settings → Notifications → Alarms & reminders** แล้วเปิดให้แอพเรา
* เราควรทำหน้าชี้นำ (in-app) ให้ผู้ใช้เปิดสิทธิ์นี้

📖 Docs:

* [Request Do Not Disturb access](https://developer.android.com/guide/topics/ui/notifiers/notifications#dnd)
* [Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)

---

### 6) UX Behavior แนะนำ

1. Geofence trigger → Service ตรวจว่า profile ปลุกยังเปิดอยู่
2. สร้าง Notification full-screen + เล่นเสียง + สั่น
3. เปิด Activity ปลุกที่มีปุ่ม **Snooze** และ **Dismiss**
4. ถ้า Snooze → ตั้ง geofence ใหม่รัศมีเล็กลง/หน่วงเวลา
5. ถ้า Dismiss → ปิดเสียง ปิด notification และ service
6. ถ้า one-time → mark ปิดโปรไฟล์ทันทีหลังปลุก

---

### 7) ตัวอย่าง Flow Diagram

```text
[เข้าสู่รัศมีปลุก] 
   ↓
ตรวจ profile → ถ้าเปิด
   ↓
Foreground Service → Full-Screen Notification
   ↓
Activity ปลุก (เสียง+สั่น)
   ↓
ผู้ใช้ Snooze หรือ Dismiss
   ↓
Stop service / Set next alarm
```

