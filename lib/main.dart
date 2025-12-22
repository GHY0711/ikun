import 'package:flutter/material.dart';
import 'services/supabase_client.dart';
import 'modules/moodCategory/mood_category_page.dart';
import 'modules/moodTypes/mood_types_page.dart';
import 'modules/moodRecords/mood_records_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MoodRecordsPage(),
    );
  }
}
