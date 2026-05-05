class ModuleItem {
  final String title;
  final String topic;
  final String difficulty;
  final int xpReward;
  final String content;

  const ModuleItem({
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.xpReward,
    required this.content,
  });
}

const List<ModuleItem> moduleData = [
  ModuleItem(
    title: "Phishing Awareness",
    topic: "phishing",
    difficulty: "Beginner",
    xpReward: 25,
    content:
        "Phishing is a cyberattack where attackers pretend to be trusted organisations such as banks, universities, or delivery companies. The goal is to trick users into clicking malicious links, entering passwords, or sharing OTP codes. Always check the sender, domain name, spelling, and urgency of the message before taking action.",
  ),
  ModuleItem(
    title: "Spear Phishing & Targeted Attacks",
    topic: "phishing",
    difficulty: "Advanced",
    xpReward: 30,
    content:
        "Spear phishing targets specific individuals using personalised information such as names, class details, university information, or workplace roles. These attacks are harder to detect because the message looks relevant. Users should verify unusual requests through official communication channels.",
  ),
  ModuleItem(
    title: "Password Security",
    topic: "password",
    difficulty: "Beginner",
    xpReward: 25,
    content:
        "A strong password should be unique, long, and difficult to guess. Avoid using names, birth dates, phone numbers, or student IDs. Password managers can help generate and store strong passwords safely.",
  ),
  ModuleItem(
    title: "Password Managers Explained",
    topic: "password",
    difficulty: "Intermediate",
    xpReward: 25,
    content:
        "Password managers help users store different passwords securely. Instead of remembering many passwords, users only need one strong master password. This reduces the risk of password reuse across multiple websites.",
  ),
  ModuleItem(
    title: "Malware & Safe Downloads",
    topic: "malware",
    difficulty: "Intermediate",
    xpReward: 30,
    content:
        "Malware includes viruses, spyware, ransomware, and trojans. It can be hidden inside cracked software, unknown attachments, or suspicious APK files. Users should only download software from official sources and keep devices updated.",
  ),
  ModuleItem(
    title: "Privacy Protection",
    topic: "privacy",
    difficulty: "Beginner",
    xpReward: 20,
    content:
        "Privacy protection means controlling what personal information is shared online. Users should check app permissions, avoid oversharing on social media, and use privacy settings to reduce exposure.",
  ),
  ModuleItem(
    title: "Online Scam Awareness",
    topic: "scam",
    difficulty: "Beginner",
    xpReward: 25,
    content:
        "Online scams often use fake prizes, urgent warnings, job offers, or investment promises. Scammers pressure users to act quickly. Always verify offers through official sources before sharing money or personal data.",
  ),
  ModuleItem(
    title: "Mobile Device Security",
    topic: "mobile",
    difficulty: "Intermediate",
    xpReward: 30,
    content:
        "Mobile devices store sensitive data such as photos, messages, banking apps, and student accounts. Use screen locks, update apps, avoid unknown APKs, and review app permissions regularly.",
  ),
];
