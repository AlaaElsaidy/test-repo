-- 🔧 Supabase Setup - الكويرز اللي تحتاج تشغلها بالترتيب

-- ============================================
-- 1️⃣ تفعيل Real-time للجداول
-- ============================================

-- شغّل هذا الأمر مرة واحدة فقط لتفعيل Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE safe_zones;
ALTER PUBLICATION supabase_realtime ADD TABLE location_updates;
ALTER PUBLICATION supabase_realtime ADD TABLE location_history;
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_contacts;

-- ============================================
-- 2️⃣ التحقق من أن الجداول موجودة
-- ============================================

-- اختبر أن جميع الجداول تم إنشاؤها بنجاح
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts');

-- النتيجة المتوقعة: 4 جداول

-- ============================================
-- 3️⃣ التحقق من RLS Policies
-- ============================================

-- تحقق من أن السياسات موجودة
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts')
ORDER BY tablename, policyname;

-- النتيجة المتوقعة: 13 سياسة (3-4 لكل جدول)

-- ============================================
-- 4️⃣ إضافة بيانات اختبار (اختياري)
-- ============================================

-- أضف منطقة آمنة اختبارية
INSERT INTO safe_zones (id, patient_id, name, address, latitude, longitude, radius_meters, is_active, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'ce4aee1d-0084-4953-997d-ddea1fdb4a50',  -- استبدل بـ patient_id الفعلي
  'البيت',
  'القاهرة',
  30.0444,
  31.2357,
  500,
  true,
  NOW(),
  NOW()
)
ON CONFLICT DO NOTHING;

-- أضف موقع اختباري
INSERT INTO location_updates (id, patient_id, latitude, longitude, address, accuracy, created_at)
VALUES (
  gen_random_uuid(),
  'ce4aee1d-0084-4953-997d-ddea1fdb4a50',  -- استبدل بـ patient_id الفعلي
  30.0444,
  31.2357,
  'القاهرة - برج العرب',
  10.5,
  NOW()
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 5️⃣ اختبار Query جلب البيانات
-- ============================================

-- جلب جميع المناطق الآمنة لمريض معين
SELECT * FROM safe_zones 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
ORDER BY created_at DESC;

-- جلب آخر موقع معروف
SELECT * FROM location_updates 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
ORDER BY created_at DESC
LIMIT 1;

-- جلب السجل التاريخي (آخر 7 أيام)
SELECT * FROM location_history 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
AND arrived_at >= NOW() - INTERVAL '7 days'
ORDER BY arrived_at DESC;

-- جلب جهات الطوارئ
SELECT * FROM emergency_contacts 
WHERE patient_id = 'ce4aee1d-0084-4953-997d-ddea1fdb4a50'
ORDER BY is_primary DESC, created_at DESC;

-- ============================================
-- 6️⃣ اختبار Realtime (في Flutter Console)
-- ============================================

-- هذا ستختبره من التطبيق، لكن الكويري يكون:
-- supabase
--   .from('location_updates')
--   .stream(primaryKey: ['id'])
--   .eq('patient_id', 'patient-id')
--   .listen((List<Map<String, dynamic>> data) {
--     // سيتم استقبال التحديثات الفورية هنا
--   });

-- ============================================
-- 7️⃣ اختبار RLS Security (تأكد أن السياسات تعمل)
-- ============================================

-- جرّب جلب بيانات مريض آخر (يجب أن يرجع empty)
-- SELECT * FROM safe_zones WHERE patient_id = 'other-patient-id';

-- ستحصل على خطأ "Rows do not exist" إذا كانت RLS تعمل بشكل صحيح

-- ============================================
-- 8️⃣ Indexes للأداء (إذا لم تكن موجودة)
-- ============================================

-- تحقق من الـ indexes
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('safe_zones', 'location_updates', 'location_history', 'emergency_contacts')
ORDER BY indexname;

-- إذا كانت ناقصة، أضفها يدويًا:
CREATE INDEX IF NOT EXISTS idx_safe_zones_patient_id ON safe_zones(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_updates_patient_id ON location_updates(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_updates_created_at ON location_updates(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_history_patient_id ON location_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_history_arrived_at ON location_history(arrived_at DESC);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_patient_id ON emergency_contacts(patient_id);

-- ============================================
-- ✅ انتهيت! النظام جاهز الآن
-- ============================================

-- الخطوة التالية:
-- 1. شغّل flutter pub get
-- 2. دمج Cubit في الشاشات
-- 3. اختبر التطبيق
