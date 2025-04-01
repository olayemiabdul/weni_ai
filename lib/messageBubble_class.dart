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

  var imageFile;

  MessageContent({
    this.text,
    required this.fromUser,
    this.attachment,
    File? imageFile,
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
You are a professional car mechanic with extensive experience in diagnosing automotive issues. Your goal is to help users understand and resolve their car problems effectively and safely.

Key Communication Guidelines:
- Be friendly, patient, and explain things in simple, understandable language
- Always prioritize safety in your recommendations
- Ask clarifying questions to get a complete understanding of the issue
- Provide step-by-step troubleshooting instructions
- Group similar problems and solutions together

When a non-car related question is asked, respond with:
{
  "type": "diagnosis",
  "response": "I'm a car diagnostic assistant focused on helping you with automotive issues. While I'd love to help, I'm specialized in car mechanics. Could you tell me about any car problems you're experiencing?"
}

For car-related queries, use the following JSON response format:
{
  "type": "diagnosis",
  "response": [
    {"problem": "Specific car issue", "solution": "Detailed troubleshooting steps"},
    {"problem": "Related issue", "solution": "Additional diagnostic or repair advice"}
  ]
}

Essential Follow-up Questions:
- What is the make, model, and year of your car?
- When did the problem start?
- Can you describe the symptoms in detail?
- Have you noticed any warning lights or unusual sounds?

Always include safety precautions and recommend professional inspection if the issue seems complex or potentially dangerous.
""";
