
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';


import 'package:weni_ai/messageBubble_class.dart';
import 'package:weni_ai/video.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatSession chat;
  final List<MessageContent> generatedContent = <MessageContent>[];
  final ImagePicker picker = ImagePicker();
  Attachment? attachment;
  bool _isLoading = false;

  // Updated model to gemini-2.5-flash (latest stable version)
  final GenerativeModel generativeModel = FirebaseVertexAI.instance
      .generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
      ));

  @override
  void initState() {
    super.initState();
    chat = generativeModel.startChat();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      generatedContent.add(MessageContent(
        text:
        "👋 Hello! I'm your car diagnostic assistant. I can help you:\n\n"
            "• Diagnose car problems\n"
            "• Explain warning lights\n"
            "• Guide you through repairs\n"
            "• Answer maintenance questions\n\n"
            "You can also attach photos or videos of your car issue. What's troubling your vehicle today?",
        fromUser: false,
      ));
    });
  }

  String getMimeType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.mp4')) return 'video/mp4';
    if (path.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty && attachment == null) return;

    final attachedFile = attachment;
    setState(() {
      generatedContent.add(MessageContent(
          attachment: attachment, text: message, fromUser: true));
      _messageController.clear();
      attachment = null;
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      GenerateContentResponse response;
      if (attachedFile != null) {
        response = await chat.sendMessage(Content.multi([
          TextPart(message.isEmpty
              ? "Please analyze this image/video and diagnose any car problems you see."
              : message),
          InlineDataPart(attachedFile.mimeType, attachedFile.bytes),
        ]));
      } else {
        response = await chat.sendMessage(Content.text(message));
      }

      setState(() {
        _isLoading = false;
        var text = response.text;
        if (text == null || text.isEmpty) {
          generatedContent.add(MessageContent(
            text: "I apologize, but I couldn't generate a response. Please try again.",
            fromUser: false,
          ));
          return;
        }

        try {
          var obj = jsonDecode(text) as Map<String, dynamic>;

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
        } catch (e) {
          // If JSON parsing fails, treat as plain text
          generatedContent.add(
            MessageContent(text: text, fromUser: false),
          );
        }
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        generatedContent.add(MessageContent(
          text: "Sorry, I encountered an error: ${e.toString()}. Please try again.",
          fromUser: false,
        ));
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void attachMedia() async {
    if (attachment != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Attachment Already Selected'),
            content: const Text(
                'Please send the current attachment first or remove it before selecting a new one.'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    attachment = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Remove'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      return;
    }

    final XFile? picked = await picker.pickMedia();
    if (picked == null) return;

    final String mime = picked.mimeType ?? getMimeType(picked.path);
    final Uint8List selectedFile = await picked.readAsBytes();

    // Expanded supported formats
    if (!['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']
        .contains(mime)) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Unsupported Media Type'),
              content: Text(
                  'The selected file has an unsupported type: $mime\n\nSupported formats:\n• Images: JPEG, PNG, WebP\n• Videos: MP4, MOV'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    setState(() {
      attachment = Attachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: picked.name,
        mimeType: mime,
        bytes: selectedFile,
        path: picked.path,
        url: '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachedFile = attachment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Car Diagnostic Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'AI-Powered Car Diagnostic Assistant\n\n'
                        'Powered by Gemini 2.5 Flash\n\n'
                        'This assistant can help diagnose car problems, '
                        'explain symptoms, and guide you through repairs. '
                        'Always consult a professional mechanic for serious issues.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: generatedContent.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == generatedContent.length && _isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing...'),
                      ],
                    ),
                  );
                }

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

          // Attachment preview
          if (attachedFile != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  if (['image/jpeg', 'image/png', 'image/webp']
                      .contains(attachedFile.mimeType))
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attachedFile.name.isNotEmpty
                          ? attachedFile.name
                          : 'Attachment',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        attachment = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            color: Theme.of(context).colorScheme.surfaceBright,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : attachMedia,
                    icon: const Icon(FontAwesomeIcons.image),
                    tooltip: 'Attach photo or video',
                  ),
                  const SizedBox.square(dimension: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isLoading,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Describe your car problem...',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty || attachment != null) {
                          sendChatMessage(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      String messageText = _messageController.text;
                      if (messageText.isNotEmpty || attachment != null) {
                        sendChatMessage(messageText);
                      }
                    },
                    icon: const Icon(Icons.send),
                    tooltip: 'Send message',
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
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: width * 0.75),
        decoration: BoxDecoration(
          color: isSender ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSender ? const Radius.circular(16) : Radius.zero,
            bottomRight: isSender ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(500),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            if (attachment != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: attachment!.mimeType.startsWith('image/')
                    ? Image.memory(
                  attachment!.bytes,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                )
                    : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, size: 20),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          attachment!.name.isNotEmpty
                              ? attachment!.name
                              : "Video",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSender ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DiagnosisMessage extends StatelessWidget {
  const DiagnosisMessage({
    super.key,
    required this.carProblems,
  });
  final List<Diagnosis> carProblems;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: SizedBox(
        height: 400,
        child: PageView.builder(
          itemCount: carProblems.length,
          itemBuilder: (context, index) => DiagnosticCard(
            problem: carProblems[index].problem,
            solution: carProblems[index].solution,
            index: index + 1,
            total: carProblems.length,
          ),
        ),
      ),
    );
  }
}

class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard({
    super.key,
    required this.problem,
    required this.solution,
    required this.index,
    required this.total,
  });

  final String problem;
  final String solution;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    var windowWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(10),
      child: Container(
        width: windowWidth * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔍 Diagnosis $index of $total',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Problem Section
            Expanded(
              child: ListView(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Problem',
                              style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              problem,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Solution Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.build_circle_rounded,
                          color: Colors.green[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solution',
                              style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              solution,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
