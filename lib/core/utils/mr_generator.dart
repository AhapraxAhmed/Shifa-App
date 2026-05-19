import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MRGenerator {
  static Future<String> generateMR() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    
    int counter = prefs.getInt('mr_counter_$dateStr') ?? 0;
    counter++;
    await prefs.setInt('mr_counter_$dateStr', counter);
    
    final counterStr = counter.toString().padLeft(3, '0');
    return 'MR$dateStr-$counterStr';
  }
}