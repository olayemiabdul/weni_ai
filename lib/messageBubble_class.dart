import 'dart:io';
import 'dart:typed_data';

class Attachment {
  final String id;
  Uint8List bytes;
  String path;
  final String name;
  final String mimeType;
  final String url;

  Attachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.path,
    required this.url,
  });
}

class MessageContent {
  String? text;
  final bool fromUser;
  final Attachment? attachment;

  MessageContent({
    this.text,
    required this.fromUser,
    this.attachment,
  });
}

class DiagnosisMessageClass extends MessageContent {
  final List<Diagnosis> problems;

  DiagnosisMessageClass({
    required List<dynamic> problemsList,
    Attachment? attachment,
    bool fromUser = false,
  })  : problems = problemsList.map((problem) {
    var prob = problem as Map<String, dynamic>;
    var problemTitle = prob['problem'] as String? ?? 'Unknown Problem';
    var problemSolution =
        prob['solution'] as String? ?? 'No solution provided';
    return Diagnosis(problem: problemTitle, solution: problemSolution);
  }).toList(),
        super(
        text: null,
        fromUser: fromUser,
        attachment: attachment,
      );
}

class Diagnosis {
  String problem;
  String solution;
  Diagnosis({required this.problem, required this.solution});
}


const String systemPrompt = """
You are an expert automotive diagnostic assistant with deep knowledge of vehicle systems, common problems, and repair solutions.

RESPONSE FORMAT:
Always respond in JSON format. Use one of these two response types:

1. For general conversation or non-diagnostic questions:
{
  "type": "message",
  "response": "Your conversational response here"
}

2. For diagnostic responses (symptoms, problems, or troubleshooting):
{
  "type": "diagnosis",
  "response": [
    {
      "problem": "Clear problem title",
      "solution": "Detailed step-by-step solution with safety warnings"
    }
  ]
}

DIAGNOSTIC GUIDELINES:
- Ask clarifying questions about: vehicle make/model/year, symptoms, when problem started, warning lights, sounds, smells
- Always prioritize safety first
- Provide clear, actionable steps
- Recommend professional help for complex/dangerous issues
- Group related problems together
- Include estimated difficulty level and cost range when relevant

SAFETY PRIORITIES:
- Never recommend unsafe DIY repairs for brake systems, fuel systems, or structural components
- Always mention safety equipment needed (gloves, eye protection, etc.)
- Warn about risks of working with hot engines, electrical systems, or under vehicles

If asked about non-automotive topics, politely redirect to car-related assistance.
""";

