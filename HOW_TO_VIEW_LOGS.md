# كيفية رؤية Logs في Console 🔍

## الطريقة 1: استخدام Flutter Console (الأسهل)

### في Android Studio / VS Code:

1. **شغل التطبيق:**
   ```bash
   flutter run
   ```

2. **افتح Terminal في Android Studio:**
   - Terminal يكون في الأسفل
   - ستشوف كل الـ logs مباشرة

3. **ابحث عن:**
   - `[Azure TTS]` - لتتبع Azure Text-to-Speech
   - `[Groq]` - لتتبع Groq API
   - `[Lobna]` - لتتبع Lobna responses

### مثال على Logs:
```
🔵 [Groq] Sending request with model: llama-3.1-70b-versatile
🔵 [Azure TTS] Generating speech for text: إزيك...
❌ [Groq] Error status 400: Bad request
✅ [Lobna] Reply generated: ...
```

---

## الطريقة 2: استخدام Flutter DevTools (أفضل للتتبع)

### في Android Studio:
1. اضغط على **"Flutter DevTools"** في toolbar (أو شغل `flutter pub global activate devtools`)
2. اضغط على **"Open DevTools"** 
3. اذهب لـ **"Logging"** tab
4. يمكنك فلترة Logs بالبحث عن:
   - `Azure TTS`
   - `Groq`
   - `Lobna`

---

## الطريقة 3: استخدام Android Logcat (للتطبيقات على الهاتف)

### في Android Studio:
1. **افتح Logcat:**
   - من الأسفل اضغط على **"Logcat"** tab
   - أو من **View → Tool Windows → Logcat**

2. **فلتر Logs:**
   - اكتب في Filter box: `flutter` أو `Azure TTS` أو `Groq`

3. **رؤية جميع Logs:**
   - اختر **"No Filters"** لرؤية كل شيء
   - ابحث عن `🔵` أو `❌` أو `✅` للرسائل المهمة

### في Terminal:
```bash
# على Windows (PowerShell):
adb logcat | Select-String -Pattern "flutter|Azure TTS|Groq|Lobna"

# على Mac/Linux:
adb logcat | grep -E "flutter|Azure TTS|Groq|Lobna"
```

---

## الطريقة 4: حفظ Logs في ملف

### في Terminal:
```bash
# حفظ كل الـ logs في ملف
flutter run 2>&1 | tee logs.txt

# أو للـ Android Logcat:
adb logcat > logs.txt
```

ثم افتح `logs.txt` وابحث عن:
- `[Azure TTS]`
- `[Groq]`
- `[Lobna]`
- `❌` (أخطاء)

---

## علامات البحث المهمة 🔍

### للبحث عن أخطاء Azure TTS:
```
[Azure TTS]
❌ [Azure TTS]
⚠️ [Azure TTS]
```

### للبحث عن أخطاء Groq:
```
[Groq]
❌ [Groq]
```

### للبحث عن ردود Lobna:
```
[Lobna]
✅ [Lobna]
```

---

## مثال على Logs عند وجود مشكلة:

### مشكلة في Groq API:
```
❌ [Groq] Error status 400: Bad request
❌ [Groq] Response data: {"error": {"message": "Invalid model"}}
❌ [Lobna] Model error
```

### مشكلة في Azure TTS:
```
❌ [Azure TTS] API Error: 401
❌ [Azure TTS] Error details: Invalid subscription key
⚠️ [Azure TTS] Falling back to device TTS
✅ [Azure TTS] Device TTS fallback successful
```

### نجاح العملية:
```
✅ [Groq] Success! Content length: 50
✅ [Lobna] Reply generated: إزيك...
🔵 [Azure TTS] Generating speech for text: إزيك...
✅ [Azure TTS] Audio generated and saved to: /path/to/file.wav
```

---

## نصائح مهمة 💡

1. **استخدم Filter:** ابحث عن كلمات محددة بدلاً من قراءة كل الـ logs
2. **شغل Debug Mode:** تأكد أنك مشغل التطبيق في debug mode وليس release
3. **انتبه للـ Emojis:** الرسائل المهمة فيها 🔵 (معلومة) أو ❌ (خطأ) أو ✅ (نجاح)
4. **احفظ Logs:** إذا كانت المشكلة معقدة، احفظ الـ logs في ملف

---

## في حالة عدم ظهور Logs:

1. **تأكد من Debug Mode:**
   ```bash
   flutter run --debug
   ```

2. **افتح Logcat في Android Studio:**
   - View → Tool Windows → Logcat

3. **افتح Console في VS Code:**
   - View → Output
   - اختر "Flutter" من القائمة المنسدلة

---

## المساعدة السريعة 🚀

### إذا شفت هذا الخطأ:
```
❌ [Azure TTS] API Error: 401
```
**الحل:** مفتاح Azure غير صحيح أو منتهي

### إذا شفت هذا الخطأ:
```
❌ [Groq] Error status 400
```
**الحل:** مشكلة في النموذج أو البيانات المرسلة

### إذا شفت:
```
⚠️ [Azure TTS] Falling back to device TTS
```
**معنى:** Azure TTS فشل لكن device TTS سيعمل (هذا طبيعي)

