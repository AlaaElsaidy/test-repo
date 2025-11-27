class LobnaDialectAdapter {
  LobnaDialectAdapter._();

  // قاموس شامل للتحويل من الفصيح إلى المصري
  static const Map<String, String> _phraseReplacements = {
    // تحيات وردود
    'لا تقلق': 'ما تقلقش',
    'لا بأس': 'مفيش مشكلة',
    'حسناً': 'تمام',
    'طيب': 'تمام',
    'نعم': 'آه',
    'أجل': 'آه',
    'كيف حالك': 'إزيك',
    'كيف أنت': 'إزيك',
    'مرحبا': 'أهلاً',
    'أهلاً وسهلاً': 'أهلاً وسهلاً',
    'شكراً': 'شكراً',
    'شكراً لك': 'شكراً',
    'عفواً': 'العفو',
    
    // أفعال
    'سأقوم': 'هعمل',
    'سوف أقوم': 'هعمل',
    'أحاول': 'بحاول',
    'سأساعدك': 'هساعدك',
    'أساعدك': 'أقدر أساعدك',
    'سأفعل': 'هعمل',
    'سأحاول': 'هحاول',
    'اذكر': 'افتكر',
    'تذكر': 'افتكر',
    'تأكد': 'اتأكد',
    'سأتصل': 'هكلم',
    'سأتحدث': 'هكلم',
    
    // كلمات الاستعطاف
    'الرجاء': 'لو سمحت',
    'من فضلك': 'لو سمحت',
    'أرجوك': 'لو سمحت',
    
    // إيجابيات
    'جيد جداً': 'عظيم',
    'ممتاز': 'عظيم',
    'رائع': 'عظيم',
    'ممتاز جداً': 'عظيم جداً',
    
    // أسئلة
    'أخبرني': 'قُولي',
    'أخبر': 'قُول',
    'قل لي': 'قُولي',
    'ماذا': 'إيه',
    'كيف': 'إزاي',
    'متى': 'امتى',
    'أين': 'فين',
    'لماذا': 'ليه',
    'من': 'مين',
    
    // اتصال وعلاقات
    'اتصل': 'كلم',
    'اتصل بـ': 'كلم',
    'صديق': 'صاحبك',
    'صديقي': 'صاحبي',
    'عائلة': 'عيلتك',
    'أهلك': 'عيلتك',
    'مريض': 'المريض',
    'المريض': 'المريض',
    
    // زمن
    'الآن': 'دلوقتي',
    'في هذه اللحظة': 'دلوقتي',
    'حالياً': 'دلوقتي',
    'اليوم': 'النهاردة',
    'غداً': 'بكرة',
    'أمس': 'امبارح',
    'بعد قليل': 'بعد شوية',
    'قريباً': 'قريب',
    
    // أفعال مهمة
    'أريد': 'عايز',
    'أحتاج': 'محتاج',
    'يمكن': 'ينفع',
    'يستطيع': 'يقدر',
    'أريد أن': 'عايز',
    'أرغب في': 'عايز',
    
    // نفي
    'لا': 'لأ',
    'ليس': 'مش',
    'لست': 'مش',
    'ليس لدي': 'معنديش',
    'لا أعرف': 'مش عارف',
    'لا أريد': 'مش عايز',
    
    // كلمات مساعدة
    'يبدو': 'شكله',
    'ربما': 'يمكن',
    'قد يكون': 'يمكن',
    'على الأرجح': 'غالباً',
    
    // طلب مساعدة
    'أحتاج مساعدة': 'محتاج مساعدة',
    'ساعدني': 'ساعدني',
    'أحتاج مساعدتك': 'محتاج مساعدتك',
  };

  // عبارات مصرية شائعة
  static const List<String> _masriFillers = [
    'ما تقلقش',
    'خلينا ناخدها واحدة واحدة',
    'لو محتاجني أنا معاكي',
    'أنا جنبك',
    'مش مشكلة',
    'كل حاجة هتمشي تمام',
  ];

  // Patterns للتحويل (جاهزة للاستخدام المستقبلي)
  // static final List<Map<String, String>> _patterns = [
  //   {'pattern': r'أنا (.+)', 'replace': r'أنا \1'},
  //   {'pattern': r'أنت (.+)', 'replace': r'إنت \1'},
  //   {'pattern': r'هو (.+)', 'replace': r'هو \1'},
  //   {'pattern': r'هي (.+)', 'replace': r'هي \1'},
  // ];

  static String ensureMasri(String input) {
    if (input.trim().isEmpty) return input;
    
    var output = input;
    
    // أولاً: تحويل الجمل الشائعة
    final commonPhrases = {
      'لم أفهم': 'مش فاهم',
      'لم أفهمك': 'مش فاهمك',
      'لم أفهم كويس': 'مش فاهم كويس',
      'لا أفهم': 'مش فاهم',
      'لا أفهمك': 'مش فاهمك',
      'جرب مرة أخرى': 'جرب تاني',
      'جرب مرة أخرى بعد قليل': 'جرب تاني بعد شوية',
      'حاول مرة أخرى': 'جرب تاني',
      'أخبرني': 'قُولي',
      'أخبرني عن': 'قُولي عن',
      'أريد أن': 'عايز',
      'أريد': 'عايز',
      'أحتاج': 'محتاج',
      'أحتاج إلى': 'محتاج',
      'يمكنك': 'تقدر',
      'يمكن أن': 'ينفع',
      'سأساعدك': 'هساعدك',
      'سأساعد': 'هساعد',
      'سأفعل': 'هعمل',
      'سأقوم': 'هعمل',
      'سأحاول': 'هحاول',
      'بالتأكيد': 'أكيد',
      'بالطبع': 'طبعاً',
      'حسناً': 'تمام',
      'جيد': 'كويس',
      'ممتاز': 'عظيم',
      'رائع': 'عظيم',
      'الآن': 'دلوقتي',
      'في الوقت الحالي': 'دلوقتي',
      'حالياً': 'دلوقتي',
      'اليوم': 'النهاردة',
      'غداً': 'بكرة',
      'أمس': 'امبارح',
    };
    
    commonPhrases.forEach((from, to) {
      output = output.replaceAll(RegExp(from, caseSensitive: false), to);
    });
    
    // ثانياً: تطبيق replacements المفردة
    _phraseReplacements.forEach((from, to) {
      // تحويل كلمات كاملة أولاً
      output = output.replaceAll(RegExp('\\b$from\\b', caseSensitive: false), to);
      // ثم تحويل جميع الحالات
      output = output.replaceAll(RegExp(from, caseSensitive: false), to);
    });
    
    // ثالثاً: تحويل الضمائر
    output = output.replaceAll(RegExp(r'\bأنت\b', caseSensitive: false), 'إنت');
    output = output.replaceAll(RegExp(r'\bأنتِ\b', caseSensitive: false), 'إنت');
    output = output.replaceAll(RegExp(r'\bأنتَ\b', caseSensitive: false), 'إنت');
    
    // رابعاً: تحويل النفي
    output = output.replaceAll(RegExp(r'\bلا\s+', caseSensitive: false), 'مش ');
    output = output.replaceAll(RegExp(r'\bليس\b', caseSensitive: false), 'مش');
    output = output.replaceAll(RegExp(r'\blست\b', caseSensitive: false), 'مش');
    
    // خامساً: تحويل الأسئلة
    output = output.replaceAll(RegExp(r'\bماذا\b', caseSensitive: false), 'إيه');
    output = output.replaceAll(RegExp(r'\bماذا\s+', caseSensitive: false), 'إيه ');
    output = output.replaceAll(RegExp(r'\bكيف\b', caseSensitive: false), 'إزاي');
    output = output.replaceAll(RegExp(r'\bكيف\s+', caseSensitive: false), 'إزاي ');
    output = output.replaceAll(RegExp(r'\bأين\b', caseSensitive: false), 'فين');
    output = output.replaceAll(RegExp(r'\bأين\s+', caseSensitive: false), 'فين ');
    output = output.replaceAll(RegExp(r'\bمتى\b', caseSensitive: false), 'امتى');
    output = output.replaceAll(RegExp(r'\bمتى\s+', caseSensitive: false), 'امتى ');
    output = output.replaceAll(RegExp(r'\bلماذا\b', caseSensitive: false), 'ليه');
    output = output.replaceAll(RegExp(r'\bلماذا\s+', caseSensitive: false), 'ليه ');
    output = output.replaceAll(RegExp(r'\bمن\b', caseSensitive: false), 'مين');
    output = output.replaceAll(RegExp(r'\bمن\s+', caseSensitive: false), 'مين ');
    
    // سادساً: تنظيف المسافات
    output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
    output = output.replaceAll('،', '، ').replaceAll('  ', ' ').trim();
    
    // سابعاً: التحقق من الصوت المصري
    if (!_soundsMasri(output)) {
      // إذا كان النص لا يزال فصيحاً، نحاول تحويله أكثر
      output = _convertToMasriHard(output);
      
      // إذا لم يبدو مصرياً بعد، نضيف filler
      if (!_soundsMasri(output)) {
        final filler = _masriFillers[0];
        if (!output.endsWith('.') && !output.endsWith('!') && !output.endsWith('؟')) {
          output = '$output. $filler';
        } else {
          output = '$output $filler';
        }
      }
    }
    
    return output;
  }

  // تحويل قوي للهجة المصرية
  static String _convertToMasriHard(String text) {
    var result = text;
    
    // تحويل الأفعال
    result = result.replaceAll(RegExp(r'\bسأفعل\b', caseSensitive: false), 'هعمل');
    result = result.replaceAll(RegExp(r'\bسأقوم\b', caseSensitive: false), 'هعمل');
    result = result.replaceAll(RegExp(r'\bسأساعد\b', caseSensitive: false), 'هساعد');
    result = result.replaceAll(RegExp(r'\bسأحاول\b', caseSensitive: false), 'هحاول');
    result = result.replaceAll(RegExp(r'\bسأقوم\s+بـ\b', caseSensitive: false), 'هعمل');
    
    // تحويل "أريد" و "أرغب"
    result = result.replaceAll(RegExp(r'\bأريد\b', caseSensitive: false), 'عايز');
    result = result.replaceAll(RegExp(r'\bأرغب\b', caseSensitive: false), 'عايز');
    result = result.replaceAll(RegExp(r'\bأرغب\s+في\b', caseSensitive: false), 'عايز');
    
    // تحويل "يمكن" و "يستطيع"
    result = result.replaceAll(RegExp(r'\bيمكن\b', caseSensitive: false), 'ينفع');
    result = result.replaceAll(RegExp(r'\bيستطيع\b', caseSensitive: false), 'يقدر');
    result = result.replaceAll(RegExp(r'\bيمكنك\b', caseSensitive: false), 'تقدر');
    
    // تحويل "أخبر" و "أخبرني"
    result = result.replaceAll(RegExp(r'\bأخبرني\b', caseSensitive: false), 'قُولي');
    result = result.replaceAll(RegExp(r'\bأخبر\b', caseSensitive: false), 'قُول');
    result = result.replaceAll(RegExp(r'\bقل\s+لي\b', caseSensitive: false), 'قُولي');
    
    return result;
  }

  static bool _soundsMasri(String text) {
    final lowered = text.toLowerCase();
    
    // كلمات مصرية شائعة
    final masriIndicators = [
      'ما',
      'إزي',
      'إزاي',
      'أهلاً',
      'يا',
      'دلوقتي',
      'عايز',
      'محتاج',
      'مش',
      'مفيش',
      'ينفع',
      'قُول',
      'قُولي',
      'فين',
      'امتى',
      'ليه',
      'مين',
      'النهد',
      'بكرة',
      'امبارح',
      'شوية',
      'بعد',
      'معنديش',
      'عظيم',
      'تمام',
      'قُولي',
      'كلم',
      'إنت',
      'أنا',
      'شكله',
    ];
    
    // التحقق من وجود مؤشرات مصرية
    for (final indicator in masriIndicators) {
      if (lowered.contains(indicator)) {
        return true;
      }
    }
    
    return false;
  }
}


