// import 'dart:convert';

// import 'package:firebase_vertexai/firebase_vertexai.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:weni_ai/diagnosis_Message.dart';

// import 'package:weni_ai/messageBubble_class.dart';
// import 'package:weni_ai/video.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   //final List<MessageContent> _chatHistory = [];
//   final TextEditingController _messageController = TextEditingController();
//   late ChatSession chat;
//   final List<MessageContent> generatedContent = <MessageContent>[];
//   final ImagePicker picker = ImagePicker();
//   Attachment? attachment;

//   sendChatMessage(String message) async {
//     if (message.isEmpty && attachment == null) return;

//     final attachedFile = attachment;
//     setState(() {
//       generatedContent.add(MessageContent(
//           attachment: attachment, text: message, fromUser: true));
//       _messageController.clear();
//       attachment = null;
//     });

//     GenerateContentResponse response;
//     try {
//       if (attachedFile != null) {
//         response = await chat.sendMessage(Content.multi([
//           TextPart(message),
//           InlineDataPart(attachedFile.mimeType, attachedFile.bytes),
//         ]));
//       } else {
//         response = await chat.sendMessage(Content.text(message));
//       }

//       setState(() {
//         var text = response.text;
//         var obj = jsonDecode(text!) as Map<String, dynamic>;
//         if (obj['type'] == 'diagnosis') {
//           var answer = obj['response'] as List<dynamic>;
//           generatedContent.add(DiagnosisMessageClass(
//             problemsList: answer,
//             fromUser: false,
//           ));
//         } else {
//           var answer = obj['response'] as String;
//           generatedContent.add(
//             MessageContent(text: answer, fromUser: false),
//           );
//         }
//       });
//     } catch (e) {
//       // Handle any errors gracefully
//       setState(() {
//         generatedContent.add(MessageContent(
//             text: 'Sorry, did yu have issue with your car?.', fromUser: false));
//       });
//     }
//   }

//   void attachMedia() async {
//     if (attachment != null) {
//       showDialog(
//           context: context,
//           builder: (context) {
//             return const AlertDialog(
//               title: Text('You have already selected an attachment'),
//             );
//           });
//       return;
//     }

//     // Show media selection bottom sheet
//     final result = await showModalBottomSheet<Map<String, dynamic>>(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Choose from Gallery'),
//                 onTap: () => Navigator.of(context).pop({
//                   'source': ImageSource.gallery,
//                   'type': 'image',
//                 }),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take a Photo'),
//                 onTap: () => Navigator.of(context).pop({
//                   'source': ImageSource.camera,
//                   'type': 'image',
//                 }),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.video_library),
//                 title: const Text('Choose Video'),
//                 onTap: () => Navigator.of(context).pop({
//                   'source': ImageSource.gallery,
//                   'type': 'video',
//                 }),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.videocam),
//                 title: const Text('Record Video'),
//                 onTap: () => Navigator.of(context).pop({
//                   'source': ImageSource.camera,
//                   'type': 'video',
//                 }),
//               ),
//             ],
//           ),
//         );
//       },
//     );

//     if (result == null) return;

//     XFile? picked;
//     try {
//       if (result['type'] == 'video') {
//         picked = result['source'] == ImageSource.camera
//             ? await picker.pickVideo(source: ImageSource.camera)
//             : await picker.pickVideo(source: ImageSource.gallery);
//       } else {
//         picked = result['source'] == ImageSource.camera
//             ? await picker.pickImage(source: ImageSource.camera)
//             : await picker.pickImage(source: ImageSource.gallery);
//       }
//     } catch (e) {
//       print('Error picking media: $e');
//       return;
//     }

//     if (picked == null) return;

//     // Show caption dialog
//     String? caption = await showDialog<String>(
//       context: context,
//       builder: (context) {
//         final TextEditingController captionController = TextEditingController();
//         return AlertDialog(
//           title: const Text('Add Caption'),
//           content: TextField(
//             controller: captionController,
//             decoration: const InputDecoration(
//               hintText: 'Enter a caption (optional)',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () =>
//                   Navigator.of(context).pop(captionController.text),
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );

//     final String? mime = picked.mimeType;
//     final String path = picked.path;
//     final selectedFile = await picked.readAsBytes();

//     if (mime == null) return;

//     setState(() {
//       attachment = Attachment(
//         id: '',
//         name: caption ?? '', // Use caption as name
//         mimeType: mime,
//         bytes: selectedFile,
//         path: path,
//         url: '',
//       );
//     });
//   }

//   final GenerativeModel generativeModel = FirebaseVertexAI.instance
//       .generativeModel(
//           model: 'gemini-1.5-flash',
//           systemInstruction: Content.text(systemPrompt),
//           generationConfig:
//               GenerationConfig(responseMimeType: 'application/json'));

//   @override
//   void initState() {
//     // TODO: implement initState
//     chat = generativeModel.startChat();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final attachedFile = attachment;
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat with Vertex AI'),
//       ),
//       body: Column(
//         children: [
//           // Chat history
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               itemCount: generatedContent.length,
//               itemBuilder: (context, index) {
//                 var message = generatedContent[index];

//                 if (message.runtimeType == DiagnosisMessageClass) {
//                   var diagnosisMessage = message as DiagnosisMessageClass;
//                   return DiagnosisMessage(
//                     carProblems: diagnosisMessage.problems,
//                   );
//                 }

//                 return MessageBubble(
//                   text: message.text!,
//                   isSender: message.fromUser,
//                   attachment: message.attachment,
//                 ).animate().fadeIn();
//               },
//             ),
//           ),
//           if (attachedFile != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               child: Stack(
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (['image/jpeg', 'image/png']
//                           .contains(attachedFile.mimeType))
//                         Container(
//                           height: 200,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             image: DecorationImage(
//                               fit: BoxFit.cover,
//                               image: MemoryImage(attachedFile.bytes),
//                             ),
//                           ),
//                         ),
//                       if (['video/quicktime', 'video/mp4']
//                           .contains(attachedFile.mimeType))
//                         SizedBox(
//                           height: 200,
//                           child: VideoPreview(path: attachedFile.path),
//                         ),
//                       if (attachedFile.name.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Text(
//                             attachedFile.name,
//                             style: Theme.of(context).textTheme.bodySmall,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                     ],
//                   ),
//                   Positioned(
//                     top: 0,
//                     right: 0,
//                     child: IconButton(
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.black54,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           attachment = null;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           // Input bar
//           Container(
//             color: Theme.of(context).colorScheme.surfaceBright,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: attachMedia,
//                     icon: const Icon(FontAwesomeIcons.image),
//                   ),
//                   const SizedBox.square(
//                     dimension: 8,
//                   ),
//                   Expanded(
//                     child: TextField(
//                       controller: _messageController,
//                       maxLines: 3,
//                       minLines: 1,
//                       decoration: const InputDecoration(
//                         hintText: 'Type your message...',
//                         border: OutlineInputBorder(borderSide: BorderSide.none),
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       // If attachment is not null, use its name, otherwise use an empty string
//                       String messageText = _messageController.text;
//                       if (messageText.isNotEmpty) {
//                         sendChatMessage(messageText);
//                       }
//                     },
//                     icon: const Icon(Icons.send),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final String text;
//   final bool isSender;
//   final Attachment? attachment;

//   const MessageBubble({
//     super.key,
//     required this.text,
//     required this.isSender,
//     this.attachment,
//   });

//   @override
//   Widget build(BuildContext context) {
//     var width = MediaQuery.of(context).size.width;
//     return Align(
//       alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//         padding: const EdgeInsets.all(10),
//         constraints: BoxConstraints(maxWidth: width * 0.6),
//         decoration: BoxDecoration(
//           color: isSender ? Colors.blueAccent : Colors.grey[300],
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(12),
//             topRight: const Radius.circular(12),
//             bottomLeft: isSender ? const Radius.circular(12) : Radius.zero,
//             bottomRight: isSender ? Radius.zero : const Radius.circular(12),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               text,
//               style: TextStyle(
//                 color: isSender ? Colors.white : Colors.black,
//               ),
//             ),
//             if (attachment != null) ...[
//               const SizedBox(height: 8),
//               GestureDetector(
//                 onTap: () {
//                   debugPrint('Attachment clicked: ${attachment!.url}');
//                 },
//                 child: attachment!.mimeType.startsWith('image/')
//                     ? Image.network(
//                         attachment!.url,
//                         height: 150,
//                         width: 150,
//                         fit: BoxFit.cover,
//                       )
//                     : Row(
//                         children: [
//                           const Icon(Icons.attach_file),
//                           const SizedBox(width: 5),
//                           Text(
//                             attachment!.name,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:weni_ai/diagnosis_Message.dart';

import 'package:weni_ai/messageBubble_class.dart';
import 'package:weni_ai/video.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //final List<MessageContent> _chatHistory = [];
  final TextEditingController _messageController = TextEditingController();
  late ChatSession chat;
  final List<MessageContent> generatedContent = <MessageContent>[];
  final ImagePicker picker = ImagePicker();
  Attachment? attachment;

  String getMimeType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.mp4')) return 'video/mp4';
    if (path.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream'; // Default MIME type
  }

  sendChatMessage(String message) async {
    final attachedFile = attachment;
    setState(() {
      generatedContent.add(MessageContent(
          attachment: attachment, text: message, fromUser: true));
      _messageController.clear();
      attachment = null;
    });
    GenerateContentResponse response;
    if (attachedFile != null) {
      response = await chat.sendMessage(Content.multi([
        TextPart(message),
        InlineDataPart(attachedFile.mimeType, attachedFile.bytes),
      ]));
    } else {
      response = await chat.sendMessage(Content.text(message));
    }
    setState(() {
      var text = response.text;
      var obj = jsonDecode(text!) as Map<String, dynamic>;
      if (obj['type'] == 'diagnosis') {
        var answer = obj['response'] as List<dynamic>;
        generatedContent.add(DiagnosisMessageClass(
          problemsList: answer,
          fromUser: false,
        ));
      } else {
        var answer = obj['response'] as String;
        generatedContent.add(
          MessageContent(text: answer, fromUser: false),
        );
      }
    });
  }

  void attachMedia() async {
    if (attachment != null) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            title: Text('You have already selected an attachment'),
          );
        },
      );
      return;
    }

    final XFile? picked = await picker.pickMedia();
    if (picked == null) return;

    final String mime = picked.mimeType ?? getMimeType(picked.path);
    final Uint8List selectedFile = await picked.readAsBytes();

    if (!['image/jpeg', 'image/png', 'video/mp4', 'video/quicktime']
        .contains(mime)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Unsupported Media Type'),
            content: Text('The selected file has an unsupported type: $mime'),
          );
        },
      );
      return;
    }

    setState(() {
      attachment = Attachment(
        id: '',
        name: '',
        mimeType: mime,
        bytes: selectedFile,
        path: picked.path,
        url: '',
      );
    });
  }

  final GenerativeModel generativeModel = FirebaseVertexAI.instance
      .generativeModel(
          model: 'gemini-1.5-flash',
          systemInstruction: Content.text(systemPrompt),
          generationConfig:
              GenerationConfig(responseMimeType: 'application/json'));

  @override
  void initState() {
    // TODO: implement initState
    chat = generativeModel.startChat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final attachedFile = attachment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weni Car Assistance'),
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: generatedContent.length,
              itemBuilder: (context, index) {
                var message = generatedContent[index];

                if (message.runtimeType == DiagnosisMessageClass) {
                  var diagnosisMessage = message as DiagnosisMessageClass;
                  return DiagnosisMessage(
                    carProblems: diagnosisMessage.problems,
                  );
                }

                return MessageBubble(
                  text: message.text!,
                  isSender: message.fromUser,
                  attachment: message.attachment,
                ).animate().fadeIn();
              },
            ),
          ),
          if (attachedFile != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(children: [
                if (['image/jpeg', 'image/png'].contains(attachedFile.mimeType))
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                          fit: BoxFit.cover,
                          image: MemoryImage(attachedFile.bytes)),
                    ),
                  ),
                if (['video/quicktime', 'video/mp4']
                    .contains(attachedFile.mimeType))
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: VideoPreview(path: attachedFile.path),
                  ),
              ]),
            ),

          // Input bar
          Container(
            color: Theme.of(context).colorScheme.surfaceBright,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: attachMedia,
                    icon: const Icon(FontAwesomeIcons.image),
                  ),
                  const SizedBox.square(
                    dimension: 8,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // If attachment is not null, use its name, otherwise use an empty string
                      String messageText = _messageController.text;
                      if (messageText.isNotEmpty) {
                        sendChatMessage(messageText);
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final Attachment? attachment;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isSender,
    this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: width * 0.6),
        decoration: BoxDecoration(
          color: isSender ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isSender ? const Radius.circular(12) : Radius.zero,
            bottomRight: isSender ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black,
              ),
            ),
            if (attachment != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  debugPrint('Attachment clicked: ${attachment!.url}');
                },
                child: attachment!.mimeType.startsWith('image/')
                    ? (attachment!.url.isNotEmpty
                        ? Image.network(
                            attachment!.url,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image);
                            },
                          )
                        : Image.memory(
                            attachment!.bytes,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ))
                    : Row(
                        children: [
                          const Icon(Icons.attach_file),
                          const SizedBox(width: 5),
                          Text(
                            attachment!.name.isNotEmpty
                                ? attachment!.name
                                : "Attachment",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
