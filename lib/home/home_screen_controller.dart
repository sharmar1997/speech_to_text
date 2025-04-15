import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_texrt_app/main.dart';

class HomeScreenController extends GetxController {
  final SpeechToText _speech = SpeechToText();
  final RxString recoganizeText = ''.obs;
  final RxBool isListening = false.obs;
  final RxList<Map<String, String>> speechAudioList = <Map<String, String>>[].obs;
  final RxInt playingIndex = (-1).obs;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    final stored = box.read<List<dynamic>>('speechAudioList');
    if (stored != null) {
      speechAudioList.assignAll(stored.map((e) => Map<String, String>.from(e)));
    }
    TTSService.initialize();
  }

  void startListening() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      if (!(await Permission.microphone.request()).isGranted) return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'listening') {
          isListening.value = true;
        } else if (status == 'done') {
          stopListening();
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      _speech.listen(
        onResult: (result) async {
          recoganizeText.value = result.recognizedWords;
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            await saveSpeechToList(result.recognizedWords, isSpoken: true);
            recoganizeText.value = '';
          }
        },
      );
      isListening.value = true;
    }
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
  }

  Future<void> saveSpeechToList(String text, {bool isSpoken = false}) async {
    String path = await TTSService.synthesizeToMp3(text);
    speechAudioList.add({
      'text': text,
      'type' : isSpoken ? 'spoken' : 'typed',
      'path': path
    });
    box.write('speechAudioList', speechAudioList.toList());
  }

  Future<void> playOrPause(int index) async {
    try {
      final filePath = speechAudioList[index]['path'];
      if (filePath == null || filePath.isEmpty) {
        print("Invalid audio path for index $index");
        return;
      }

      if (playingIndex.value == index) {
        await _audioPlayer.pause();
        playingIndex.value = -1;
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(filePath));
        playingIndex.value = index;

        _audioPlayer.onPlayerComplete.listen((_) {
          playingIndex.value = -1;
        });
      }
    } catch (e) {
      print("Error playing audio at index $index: $e");
    }
  }

  void deleteItem(int index) {
    if (index < 0 || index >= speechAudioList.length)
    return;

    speechAudioList.removeAt(index);
    box.write('speechAudioList', speechAudioList.toList());

    if (playingIndex.value == index) {
      stopPlayback();
    } else if (playingIndex.value > index) {
      playingIndex.value -= 1;
    }
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    playingIndex.value = -1;
  }
}
