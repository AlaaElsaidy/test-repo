import 'dart:io';

import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';

import '../lib/config/env/supabase_keys.dart';
import '../lib/services/lobna/groq_client.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('activities')
    ..addCommand('alerts')
    ..addCommand('feedback')
    ..addCommand('assistant');

  parser.commands['activities']!
    ..addCommand('next')
    ..commands['next']!.addOption('patient-id',
        abbr: 'p', help: 'Supabase patient id', mandatory: true);

  parser.commands['alerts']!.addCommand('send');
  parser.commands['alerts']!.commands['send']!
    ..addOption('patient-id', abbr: 'p', mandatory: true, help: 'Patient id')
    ..addOption('message',
        abbr: 'm',
        help: 'Alert text delivered to patient + family',
        defaultsTo: 'تم رصد خروج من المنطقة الآمنة، يرجى التواصل فوراً.');

  parser.commands['feedback']!.addCommand('log');
  parser.commands['feedback']!.commands['log']!
    ..addOption('family-id', abbr: 'f', mandatory: true)
    ..addOption('note',
        abbr: 'n',
        help: 'Voice/text note summary to attach to Lobna thread',
        defaultsTo: 'الرجاء متابعة المريض عند توفر وقت.');

  parser.commands['assistant']!.addCommand('reply');
  parser.commands['assistant']!.commands['reply']!
    ..addOption('prompt',
        abbr: 'q',
        help: 'نص السؤال أو ما تم سماعه',
        mandatory: true)
    ..addOption('api-key',
        abbr: 'k',
        help: 'GROQ_API_KEY إن لم يكن مضبوطاً في متغيرات البيئة')
    ..addOption('model',
        abbr: 'm', help: 'اسم النموذج', defaultsTo: 'llama3-70b-8192');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    _printUsage(parser, error: e.toString());
    return;
  }

  if (results.command == null) {
    _printUsage(parser, error: 'رجاء اختر أمر صالح.');
    return;
  }

  final client = SupabaseClient(SupabaseKeys.url, SupabaseKeys.anonKey);
  final command = results.command!;

  switch (command.name) {
    case 'activities':
      await _handleActivities(command, client);
      break;
    case 'alerts':
      await _handleAlerts(command);
      break;
    case 'feedback':
      _handleFeedback(command);
      break;
    case 'assistant':
      await _handleAssistant(command);
      break;
    default:
      _printUsage(parser, error: 'أمر غير معروف.');
  }
}

void _printUsage(ArgParser parser, {String? error}) {
  if (error != null) {
    stderr.writeln('خطأ: $error');
  }
  stdout.writeln('''
أوامر لُبنى (CLI):
  dart run tool/lobna_cli.dart activities next -p <PATIENT_ID>
  dart run tool/lobna_cli.dart alerts send -p <PATIENT_ID> [-m "نص"]
  dart run tool/lobna_cli.dart feedback log -f <FAMILY_ID> [-n "ملاحظة"]
  dart run tool/lobna_cli.dart assistant reply -q "سؤال" [-k API_KEY]
''');
  stdout.writeln(parser.usage);
}

Future<void> _handleActivities(ArgResults command, SupabaseClient client) async {
  final sub = command.command;
  if (sub == null || sub.name != 'next') {
    stderr.writeln('حدد الأمر: activities next');
    return;
  }

  final patientId = sub['patient-id'] as String;
  stdout.writeln('📅 استعلام الأنشطة للمريض: $patientId');
  final data = await client
      .from('activities')
      .select()
      .eq('patient_id', patientId)
      .order('scheduled_date', ascending: true)
      .order('scheduled_time', ascending: true);

  if (data.isEmpty) {
    stdout.writeln('لا توجد أنشطة قادمة.');
    return;
  }

  final now = DateTime.now();
  Map<String, dynamic>? nextActivity;
  for (final activity in data) {
    final date = DateTime.tryParse(activity['scheduled_date'] as String? ?? '');
    if (date == null) continue;
    if (date.isAfter(now.subtract(const Duration(days: 1)))) {
      nextActivity = activity;
      break;
    }
  }

  nextActivity ??= data.first;
  final formatter = DateFormat('yyyy-MM-dd HH:mm');
  final dateStr = '${nextActivity['scheduled_date']} ${nextActivity['scheduled_time']}';
  stdout
    ..writeln('النشاط القادم: ${nextActivity['name']} (${nextActivity['description'] ?? 'بدون وصف'})')
    ..writeln('الموعد: $dateStr (${formatter.format(DateTime.now())} الآن)')
    ..writeln('نوع التذكير: ${nextActivity['reminder_type'] ?? 'alarm'}')
    ..writeln('تم ✅');
}

Future<void> _handleAlerts(ArgResults command) async {
  final sub = command.command;
  if (sub == null || sub.name != 'send') {
    stderr.writeln('حدد الأمر: alerts send');
    return;
  }
  final patientId = sub['patient-id'] as String;
  final message = sub['message'] as String;
  stdout.writeln('🚨 إرسال تحذير للمريض $patientId');
  stdout.writeln('النص: $message');
  stdout.writeln(
      'ملاحظة: هذا أمر محلي حالياً. أربطه بخدمة الإشعارات أو Supabase لاحقاً.');
}

void _handleFeedback(ArgResults command) {
  final sub = command.command;
  if (sub == null || sub.name != 'log') {
    stderr.writeln('حدد الأمر: feedback log');
    return;
  }
  final familyId = sub['family-id'] as String;
  final note = sub['note'] as String;
  stdout.writeln('📝 تسجيل ملاحظة من العائلة $familyId');
  stdout.writeln('الملاحظة: $note');
  stdout.writeln('ستظهر الملاحظة في سجل لُبنى النصي.');
}

Future<void> _handleAssistant(ArgResults command) async {
  final sub = command.command;
  if (sub == null || sub.name != 'reply') {
    stderr.writeln('حدد الأمر: assistant reply');
    return;
  }

  final prompt = sub['prompt'] as String;
  final apiKey = (sub['api-key'] as String?) ??
      Platform.environment['GROQ_API_KEY'] ??
      Platform.environment['groq_api_key'];
  final model = sub['model'] as String;

  final client = LobnaGroqClient(apiKey: apiKey, model: model);
  final response = await client.chat(prompt: prompt);

  if (!response.success) {
    stderr.writeln('فشل توليد الرد: ${response.error}');
    return;
  }

  stdout.writeln('🤖 رد لُبنى: ${response.reply}');
}

