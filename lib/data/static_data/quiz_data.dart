class QuizItem {
  final String topic;
  final String difficulty;
  final String scenario;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int xpReward;

  const QuizItem({
    required this.topic,
    required this.difficulty,
    required this.scenario,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.xpReward = 15,
  });
}

const List<QuizItem> quizData = [
  QuizItem(
    topic: "Phishing Awareness",
    difficulty: "Intermediate",
    scenario:
        '"Urgent: Your Maybank account has been temporarily locked. Click the link below to verify your identity within 24 hours."',
    question:
        'A URL reads "http://maybank-secure-login.com/verify". What is the biggest red flag?',
    options: [
      'The message says "urgent"',
      'The domain is not maybank2u.com.my — it is a lookalike',
      'The URL is too long',
      'Nothing — it looks legitimate',
    ],
    correctIndex: 1,
    explanation:
        "The official Maybank2u domain is maybank2u.com.my. A lookalike domain is a common phishing tactic.",
  ),
  QuizItem(
    topic: "Password Security",
    difficulty: "Beginner",
    scenario:
        "You want to create a password for your student portal. You are thinking of using your name or student ID.",
    question: "Which password is the safest?",
    options: [
      "farhana2002",
      "2023213904",
      "Password123",
      "F@rh4na!Cyber#2026",
    ],
    correctIndex: 3,
    explanation:
        "A strong password uses mixed characters and avoids personal information.",
  ),
  QuizItem(
    topic: "Social Engineering",
    difficulty: "Intermediate",
    scenario:
        "Someone on Telegram claims to be your lecturer and asks for your student email password to verify class registration.",
    question: "What should you do first?",
    options: [
      "Send the password quickly",
      "Ask friends only",
      "Verify through official university email or lecturer contact",
      "Ignore all lecturer messages forever",
    ],
    correctIndex: 2,
    explanation:
        "Requests for passwords should always be verified through official channels.",
  ),
  QuizItem(
    topic: "Malware & Safe Downloads",
    difficulty: "Beginner",
    scenario:
        'You found a free cracked software file named "assignment_tool_free.exe" in a Telegram group.',
    question: "Why is this risky?",
    options: [
      "The file name is too short",
      "Cracked software can contain malware or spyware",
      "Telegram files are always safe",
      "It only affects old computers",
    ],
    correctIndex: 1,
    explanation:
        "Cracked software is often used to spread malware and steal user data.",
  ),
  QuizItem(
    topic: "Privacy Protection",
    difficulty: "Beginner",
    scenario:
        "A photo editing app asks for contacts, location, microphone, storage, and camera access.",
    question: "What is the safest action?",
    options: [
      "Allow all permissions",
      "Only allow permissions needed for the app function",
      "Delete all apps",
      "Share your location first",
    ],
    correctIndex: 1,
    explanation:
        "Apps should only receive permissions that match their actual function.",
  ),
];