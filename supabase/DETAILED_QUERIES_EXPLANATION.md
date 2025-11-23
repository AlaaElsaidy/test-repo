📚 شرح مفصّل لكل كويري في السوبابيز
====================================

---

🔹 **QUERY 1: إنشاء الجداول**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الملف:
📄 supabase/migrations/20251122_create_tracking_tables.sql

يحتوي على:
1. جدول safe_zones (المناطق الآمنة)
2. جدول location_updates (تحديثات الموقع)
3. جدول location_history (السجل التاريخي)
4. جدول emergency_contacts (جهات الطوارئ)

كل جدول يحتوي على:
✓ أعمدة البيانات
✓ RLS Policies (سياسات أمان)
✓ Constraints (قيود)
✓ Foreign Keys (علاقات)

الخطوات:
1. Copy الملف كاملاً (300+ سطر)
2. اذهب: https://app.supabase.com
3. اختر المشروع
4. SQL Editor
5. New Query
6. Paste
7. Execute (اضغط الزر الأسود)

النتيجة:
- سترى: "Successfully executed"
- الجداول ستظهر في Table Editor

---

🔹 **QUERY 2: تفعيل Real-time**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE safe_zones;
ALTER PUBLICATION supabase_realtime ADD TABLE location_updates;
ALTER PUBLICATION supabase_realtime ADD TABLE location_history;
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_contacts;
```

ماذا يفعل؟
- يفعّل البث المباشر (Real-time Stream)
- يسمح للتطبيق باستقبال التحديثات فوريًا
- بدونه، التحديثات لن تصل فوريًا

الخطوات:
1. Copy الـ 4 أسطر أعلاه
2. SQL Editor → New Query
3. Paste
4. Execute

النتيجة:
- سترى: "Successfully executed"
- الآن التحديثات ستأتي فوريًا

---

🔹 **QUERY 3: التحقق من الجداول**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'safe_zones', 
  'location_updates', 
  'location_history', 
  'emergency_contacts'
);
```

ماذا يفعل؟
- يتحقق من وجود الجداول الـ 4
- يؤكد نجاح تطبيق Migration

الخطوات:
1. Copy الكويري أعلاه
2. SQL Editor → New Query
3. Paste
4. Execute

النتيجة المتوقعة:
```
table_name
─────────────────────
emergency_contacts
location_history
location_updates
safe_zones
```

إذا حصلت على هذه النتيجة = كل شيء تمام ✓

---

🔹 **QUERY 4: التحقق من RLS Policies (اختياري)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN (
  'safe_zones', 
  'location_updates', 
  'location_history', 
  'emergency_contacts'
)
ORDER BY tablename, policyname;
```

ماذا يفعل؟
- يتحقق من سياسات الأمان (RLS)
- يؤكد أن كل مستخدم يرى بيانته فقط

النتيجة المتوقعة:
```
schemaname | tablename          | policyname
─────────────────────────────────────────────
public     | emergency_contacts | delete_own
public     | emergency_contacts | insert_own
public     | emergency_contacts | select_own
public     | emergency_contacts | update_own
public     | location_history   | delete_own
public     | location_history   | insert_own
public     | location_history   | select_own
public     | location_history   | update_own
public     | location_updates   | insert_own
public     | location_updates   | select_own
public     | safe_zones         | delete_own
public     | safe_zones         | insert_own
public     | safe_zones         | select_own
public     | safe_zones         | update_own
```

إجمالي: 13 سياسة أمان

---

🔹 **QUERY 5: التحقق من Indexes (اختياري)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT indexname FROM pg_indexes 
WHERE tablename IN (
  'safe_zones', 
  'location_updates', 
  'location_history', 
  'emergency_contacts'
)
ORDER BY indexname;
```

ماذا يفعل؟
- يتحقق من الفهارس (Indexes)
- الفهارس تسرّع البحث عن البيانات

النتيجة المتوقعة:
```
indexname
──────────────────────────────────────
idx_emergency_contacts_patient_id
idx_location_history_arrived_at
idx_location_history_patient_id
idx_location_updates_created_at
idx_location_updates_patient_id
idx_safe_zones_patient_id
pk_safe_zones (Primary Key)
pk_location_updates (Primary Key)
pk_location_history (Primary Key)
pk_emergency_contacts (Primary Key)
```

إجمالي: 10 indexes على الأقل

---

🔹 **QUERY 6: إضافة منطقة آمنة (اختياري)**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
INSERT INTO safe_zones (
  id, 
  patient_id, 
  name, 
  address, 
  latitude, 
  longitude, 
  radius_meters, 
  is_active, 
  created_at, 
  updated_at
)
VALUES (
  gen_random_uuid(),
  'ce4aee1d-0084-4953-997d-ddea1fdb4a50',  -- patient_id
  'البيت',                                   -- name
  'القاهرة',                                 -- address
  30.0444,                                   -- latitude
  31.2357,                                   -- longitude
  500,                                       -- radius_meters
  true,                                      -- is_active
  NOW(),                                     -- created_at
  NOW()                                      -- updated_at
)
ON CONFLICT DO NOTHING;
```

ماذا يفعل؟
- يضيف منطقة آمنة للاختبار
- ON CONFLICT DO NOTHING = لا تخطأ إذا موجودة

الخطوات:
1. Copy الكويري
2. استبدل patient_id بـ patient_id فعلي
3. Execute

النتيجة:
```
Query returned no results
```

(هذا معناه تم الإدراج بنجاح)

---

🔹 **QUERY 7: جلب المناطق الآمنة**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT * FROM safe_zones 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
ORDER BY created_at DESC;
```

ماذا يفعل؟
- جلب جميع المناطق الآمنة لمريض معين
- هذا الكويري يستخدمه التطبيق

النتيجة:
- جدول بجميع المناطق الآمنة
- محرّبة من الأقدم للأحدث

---

🔹 **QUERY 8: جلب آخر موقع**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT * FROM location_updates 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
ORDER BY created_at DESC
LIMIT 1;
```

ماذا يفعل؟
- جلب آخر موقع معروف للمريض
- LIMIT 1 = سجل واحد فقط

النتيجة:
- موقع واحد (الأحدث)
- يحتوي على: latitude, longitude, address, accuracy

---

🔹 **QUERY 9: جلب السجل التاريخي**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

الكود:
```sql
SELECT * FROM location_history 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
AND arrived_at >= NOW() - INTERVAL '7 days'
ORDER BY arrived_at DESC;
```

ماذا يفعل؟
- جلب السجل التاريخي (آخر 7 أيام)
- يحتوي على: مكان، وقت الوصول، وقت المغادرة

النتيجة:
- جدول بجميع الأماكن التي زارها المريض
- مرتب من الأحدث للأقدم

---

📊 **ملخص الكويرز:**

| الكويري | الهدف | المدخلات | المخرجات |
|--------|-------|---------|---------|
| 1 | إنشاء الجداول | Migration file | 4 جداول + RLS |
| 2 | تفعيل Real-time | 4 أوامر ALTER | WebSocket enabled |
| 3 | التحقق من الجداول | SELECT query | ✓ 4 جداول |
| 4 | التحقق من RLS | SELECT query | ✓ 13 سياسة |
| 5 | التحقق من Indexes | SELECT query | ✓ 10 indexes |
| 6 | إضافة بيانات | INSERT | منطقة آمنة |
| 7 | جلب المناطق | SELECT | جميع المناطق |
| 8 | جلب آخر موقع | SELECT | موقع واحد |
| 9 | جلب السجل | SELECT | سجل الزيارات |

---

✅ **الخطوات الإجمالية:**

1. تطبيق Query 1 (Migration)
2. تطبيق Query 2 (Real-time)
3. تطبيق Query 3 (التحقق)
4. (اختياري) تطبيق Queries 4-5
5. (اختياري) تطبيق Query 6 (بيانات اختبار)
6. الآن التطبيق جاهز للاستخدام!

**الوقت الإجمالي: ~20 دقيقة** ⏱️
