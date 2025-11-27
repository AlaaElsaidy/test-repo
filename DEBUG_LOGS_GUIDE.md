# دليل عرض Logs في Console 🔍

## طرق عرض Logs حسب IDE

### 1. Android Studio / IntelliJ IDEA

#### خطوات العرض:
1. **افتح Android Studio**
2. **شغل التطبيق:**
   - اضغط `Run` (Shift + F10) أو
   - من Terminal في Android Studio: `flutter run`
3. **افتح Run Tab:**
   - في الأسفل ستجد تبويب "Run" أو "Debug"
   - كل الـ logs ستظهر هناك
4. **فلترة Logs:**
   - استخدم search box للبحث عن:
     - `[Azure TTS]` - لـ Azure Text-to-Speech
     - `[Groq]` - لـ Groq API
     - `[Lobna]` - لـ Lobna responses
     - `❌` - للأخطاء
     - `✅` - للنجاح

#### مثال:
```
🔵 [Groq] Sending request with model: llama-3.1-70b-versatile
❌ [Groq] Error status 400: Invalid API key
❌ [Lobna] Failed to generate reply
```

---

### 2. VS Code

#### خطوات العرض:
1. **افتح VS Code**
2. **شغل التطبيق:**
   - اضغط `F5` أو
   - من Terminal: `flutter run`
3. **افتح Debug Console:**
   - اضغط `Ctrl + Shift + Y` (أو View > Debug Console)
   - أو شوف Terminal في الأسفل
4. **فلترة Logs:**
   - استخدم search في Debug Console
   - ابحث عن `[Azure TTS]` أو `[Groq]`

---

### 3. Terminal / Command Line

#### خطوات العرض:
1. **افتح Terminal / Command Prompt / PowerShell**
2. **روح للمشروع:**
   ```bash
   cd "E:\test repo alla\repootast\test-repo"
   ```
3. **شغل التطبيق:**
   ```bash
   flutter run
   ```
4. **شوف الـ Output:**
   - كل الـ logs ستظهر مباشرة في Terminal
   - الـ `debugPrint()` ستظهر بالكامل

---

### 4. Android Logcat (للمشاكل المتقدمة)

#### خطوات العرض:
1. **افتح Android Studio**
2. **افتح Logcat:**
   - View > Tool Windows > Logcat
   - أو من الأسفل اضغط على تبويب "Logcat"
3. **فلترة حسب Tag:**
   - في search box اكتب:
     - `flutter` - لجميع Flutter logs
     - `Azure` - لـ Azure TTS logs
     - `Groq` - لـ Groq logs

---

## ما تبحث عنه في Logs 🔎

### 1. Azure TTS Logs
ابحث عن:
```
🔵 [Azure TTS] Generating speech for text: ...
🔵 [Azure TTS] Endpoint: https://eastus.tts.speech.microsoft.com/...
✅ [Azure TTS] Audio generated and saved to: ...
❌ [Azure TTS] API Error: 401
⚠️ [Azure TTS] Falling back to device TTS
```

### 2. Groq API Logs
ابحث عن:
```
🔵 [Groq] Sending request with model: llama-3.1-70b-versatile
✅ [Groq] Response status: 200
✅ [Groq] Success! Content length: 50
❌ [Groq] Error status 400: Invalid request
❌ [Groq] DioException: Connection timeout
```

### 3. Lobna Response Logs
ابحث عن:
```
✅ [Lobna] Reply generated: إزيك...
❌ [Lobna] Failed to generate reply
❌ [Lobna] Error: خطأ من Groq (401): Invalid API key
```

---

## أمثلة على الأخطاء الشائعة 📋

### خطأ 1: Azure TTS API Key غير صحيح
```
❌ [Azure TTS] API Error: 401
❌ [Azure TTS] Error details: Unauthorized
```
**الحل:** تحقق من `AZURE_TTS_API_KEY` في `.env` أو `main.dart`

### خطأ 2: Groq API Key غير صحيح
```
❌ [Groq] Error status 401: Invalid API key
❌ [Lobna] API Key invalid or unauthorized
```
**الحل:** تحقق من `GROQ_API_KEY` في `.env` أو `main.dart`

### خطأ 3: Connection Timeout
```
❌ [Groq] DioException: Connection timeout
❌ [Lobna] Timeout error
```
**الحل:** تحقق من الاتصال بالإنترنت

### خطأ 4: Azure TTS Endpoint غير صحيح
```
❌ [Azure TTS] API Error: 404
❌ [Azure TTS] Error details: Not Found
```
**الحل:** تحقق من `AZURE_TTS_ENDPOINT` أو Region

---

## نصائح مفيدة 💡

1. **استخدم Filter:**
   - في Android Studio: اكتب في search box `[Azure TTS]` أو `❌`
   - في VS Code: استخدم search في Debug Console

2. **احفظ Logs:**
   - في Android Studio: File > Save Log to File
   - في Terminal: `flutter run > logs.txt 2>&1`

3. **Clear Logs:**
   - في Android Studio: اضغط على Clear icon في Logcat
   - في Terminal: اضغط `Ctrl + L`

4. **Real-time Monitoring:**
   - شغل التطبيق واترك الـ logs مفتوحة
   - جرب الميزات وشوف الـ logs تظهر فوراً

---

## مثال عملي 🎯

### عند اختبار صوت Lobna:

1. **شغل التطبيق:**
   ```bash
   flutter run
   ```

2. **ابحث في Logs عن:**
   ```
   [Azure TTS] Generating speech
   ```

3. **إذا شفت:**
   ```
   ✅ [Azure TTS] Audio generated
   ```
   → **معناه Azure TTS شغال! ✅**

4. **إذا شفت:**
   ```
   ❌ [Azure TTS] API Error: 401
   ⚠️ [Azure TTS] Falling back to device TTS
   ```
   → **معناه Azure TTS فشل، لكن device TTS شغال ✅**

---

## إذا لم تظهر Logs 🔧

1. **تأكد من Debug Mode:**
   ```bash
   flutter run --debug
   ```

2. **تحقق من verbose logging:**
   ```bash
   flutter run -v
   ```

3. **في Android Studio:**
   - تأكد أن Run Configuration مضبوطة على Debug
   - View > Tool Windows > Run

---

## مساعدة إضافية 🆘

إذا واجهت مشكلة:
1. **انسخ Logs** التي تظهر
2. **ابحث عن:**
   - `❌` - للأخطاء
   - `[Azure TTS]` - لـ Azure
   - `[Groq]` - لـ Groq
   - `[Lobna]` - لـ Lobna responses

3. **أرسل Logs** للمطور لتحليلها

---

## روابط مفيدة 🔗

- [Flutter Debugging Guide](https://docs.flutter.dev/testing/best-practices)
- [Android Studio Logcat](https://developer.android.com/studio/debug/logcat)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

