import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_texrt_app/home/home_screen_controller.dart';
import 'package:speech_texrt_app/main.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeScreenController homeScreenController =Get.put(HomeScreenController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Text Speech"),
        centerTitle: true,
        actions: [
          Obx(() {
            bool listening = homeScreenController.isListening.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: listening ? 70 : 50,
              height: listening ? 70 : 50,
              decoration: BoxDecoration(
                color: listening
                    ? Colors.redAccent.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () async {
                  var status = await Permission.microphone.status;
                  if (!status.isGranted) {
                    await Permission.microphone.request();
                  }
                  homeScreenController.startListening();
                },
                icon: Icon(
                  Icons.mic_none_outlined,
                  color: listening ? Colors.red : Colors.black,
                  size: listening ? 32 : 28,
                ),
              ),
            );
          }),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController _controller = TextEditingController();
                  return AlertDialog(
                    title: Text("Enter text to speak"),
                    content: TextFormField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(hintText: "Type something..."),
                      onFieldSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          final text = value.trim();
                          homeScreenController.saveSpeechToList(text, isSpoken: false);
                          TTSService.speakText(value.trim());
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.message),
          )
        ],
      ),
      body:  Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: homeScreenController.speechAudioList.length,
                itemBuilder: (context, index) {
                  final item = homeScreenController.speechAudioList[index];
                  final isPlaying = homeScreenController.playingIndex.value == index;
                  final type = item['type'] ?? 'spoken'; // default to spoken
                  final isTyped = type == 'typed';
                  final String displayText = item['text'] ?? '';
                  final bool isLongText = displayText.length > 20;

                  // return Card(
                  //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //   elevation: 5,
                  //   child: ListTile(
                  //     leading: Icon(
                  //       isTyped ? Icons.message_outlined : Icons.mic_none_outlined,
                  //       color: isTyped ? Colors.blueAccent : Colors.green,
                  //     ),
                  //     title: Text(item['text']!, style: const TextStyle(fontSize: 16)),
                  //     trailing: SizedBox(
                  //       width: isTyped ? 140 : 108,
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           if (isTyped)
                  //             IconButton(
                  //               icon: Icon(
                  //                 isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  //                 color: Colors.deepPurple,
                  //                 size: 28,
                  //               ),
                  //               onPressed: () => homeScreenController.playOrPause(index),
                  //             ),
                  //           IconButton(
                  //             icon: const Icon(Icons.copy, color: Colors.grey),
                  //             onPressed: () {
                  //               Clipboard.setData(ClipboardData(text: item['text']!));
                  //               ScaffoldMessenger.of(context).showSnackBar(
                  //                 const SnackBar(content: Text('Text copied')),
                  //               );
                  //             },
                  //           ),
                  //           IconButton(
                  //             icon: const Icon(Icons.share, color: Colors.blueGrey),
                  //             onPressed: () {
                  //               Share.share(item['text']!);
                  //             },
                  //           ),
                  //           IconButton(
                  //             icon: const Icon(Icons.delete, color: Colors.redAccent),
                  //             onPressed: () => homeScreenController.deleteItem(index),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // );
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    child: Column(
                      children: [
                        // First Row: Message/Mic Icon, Text, Play/Pause Button
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0, top: 8.0, right: 8.0),
                          child: Row(
                            children: [
                              // Mic or Message Icon
                              Icon(
                                isTyped ? Icons.messenger_rounded : Icons.mic_outlined,
                                color: isTyped ? Colors.black : Colors.black,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (isLongText) {
                                      showDialog(
                                        context: context, 
                                        builder: (context) => AlertDialog(
                                          title: const Text("Full Message"),
                                          content: Text(item['text']!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(), 
                                              child: const Text("Close"),
                                            )
                                          ],
                                        )
                                      );
                                    }
                                  },
                                  child: isLongText 
                                    ? Text.rich(
                                        TextSpan(
                                          text: displayText.substring(0, 20),
                                          style: const TextStyle(fontSize: 15),
                                          children: [
                                            TextSpan(
                                              text: '..See more',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(255, 4, 68, 121),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        displayText,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                ),
                              ),
                              // Play/Pause Button
                              if (isTyped)
                                Obx(() {
                                  final isPlaying = homeScreenController.playingIndex.value == index;
                                  return IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: isPlaying ? Colors.green : Colors.deepPurple,
                                      size: 32,
                                    ),
                                    onPressed: () => homeScreenController.playOrPause(index),
                                  );
                                }),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 1.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.copy, color: Colors.black, size: 20,),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item['text']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Text copied')),
                                  );
                                }, 
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.black, size: 20,),
                                onPressed: () => homeScreenController.deleteItem(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.share, color: Colors.black, size: 20,),
                                onPressed: () {
                                  Share.share(item['text']!);
                                }, 
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            )
          ],
        ),
      ),
    );
  }
}
