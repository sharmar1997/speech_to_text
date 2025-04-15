import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:speech_texrt_app/utils/app_routes.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

void main() async{
  // Ensures that all the bindings for Flutter widgets are initialized before the app runs.
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Speech Text',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<String> synthesizeToMp3(String text) async {
    final uuid = Uuid().v4();
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/$uuid.mp3";

    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    await _flutterTts.synthesizeToFile(text, path); // Generates an MP3
    return path;
  }

  static Future<void> speakText(String text) async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async => _flutterTts.stop();
  static Future<void> pause() async => _flutterTts.pause();
  static void initialize() {
    _flutterTts.setLanguage("en-US");
  }
}

