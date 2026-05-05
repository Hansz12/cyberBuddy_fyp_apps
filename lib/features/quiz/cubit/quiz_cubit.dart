import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/cubit/home_state.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit() : super(const QuizState());

  void loadQuiz({HomeState? homeState}) {
    final allQuestions = _getQuestions();

    String weakTopic = "phishing";

    if (homeState != null) {
      weakTopic = _detectWeakTopic(homeState);
    }

    final weakQuestions =
        allQuestions.where((q) => _topicKey(q.topic) == weakTopic).toList()
          ..shuffle();

    final otherQuestions =
        allQuestions.where((q) => _topicKey(q.topic) != weakTopic).toList()
          ..shuffle();

    final selectedQuestions = [
      ...weakQuestions.take(3),
      ...otherQuestions.take(2),
    ]..shuffle();

    final finalQuestions = selectedQuestions.map(_shuffleOptions).toList();

    emit(
      state.copyWith(
        questions: finalQuestions,
        currentIndex: 0,
        score: 0,
        totalXp: 0,
        clearSelectedIndex: true,
        isAnswered: false,
        isFinished: false,
      ),
    );
  }

  String _detectWeakTopic(HomeState homeState) {
    String weakest = "phishing";
    double lowest = homeState.topicScores["phishing"] ?? 0.5;

    homeState.topicScores.forEach((topic, score) {
      if (score < lowest) {
        weakest = topic;
        lowest = score;
      }
    });

    return weakest;
  }

  QuizQuestion _shuffleOptions(QuizQuestion q) {
    final options = List<String>.from(q.options);
    final correctAnswer = q.options[q.correctIndex];

    options.shuffle();

    final newCorrectIndex = options.indexOf(correctAnswer);

    return QuizQuestion(
      topic: q.topic,
      difficulty: q.difficulty,
      scenario: q.scenario,
      question: q.question,
      options: options,
      correctIndex: newCorrectIndex,
      explanation: q.explanation,
      xpReward: q.xpReward,
    );
  }

  String _topicKey(String topic) {
    final lower = topic.toLowerCase();

    if (lower.contains("phishing")) return "phishing";
    if (lower.contains("password")) return "password";
    if (lower.contains("social")) return "social";
    if (lower.contains("privacy")) return "social";
    if (lower.contains("malware")) return "malware";
    if (lower.contains("scam")) return "scam";
    if (lower.contains("mobile")) return "mobile";

    return "phishing";
  }

  void answerQuestion(int selectedIndex) {
    if (state.isAnswered) return;

    final isCorrect = selectedIndex == state.currentQuestion.correctIndex;

    emit(
      state.copyWith(
        selectedIndex: selectedIndex,
        isAnswered: true,
        score: isCorrect ? state.score + 1 : state.score,
        totalXp: isCorrect
            ? state.totalXp + state.currentQuestion.xpReward
            : state.totalXp,
      ),
    );
  }

  void nextQuestion() {
    if (state.currentIndex == state.questions.length - 1) {
      emit(state.copyWith(isFinished: true));
    } else {
      emit(
        state.copyWith(
          currentIndex: state.currentIndex + 1,
          clearSelectedIndex: true,
          isAnswered: false,
        ),
      );
    }
  }

  void restartQuiz({HomeState? homeState}) {
    loadQuiz(homeState: homeState);
  }

  List<QuizQuestion> _getQuestions() {
    return const [
      QuizQuestion(
        topic: 'Phishing Awareness',
        difficulty: 'Intermediate',
        scenario:
            '"Urgent: Your Maybank account has been temporarily locked. Click the link below to verify within 24 hours."',
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
            'The real Maybank2u domain is maybank2u.com.my. A lookalike domain is a phishing red flag.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Phishing Awareness',
        difficulty: 'Beginner',
        scenario:
            'You receive an email claiming your university email storage is full. It asks you to click a link and login immediately.',
        question: 'What is the safest first action?',
        options: [
          'Click the link and login',
          'Forward the email to all friends',
          'Check the official university email portal manually',
          'Reply with your password',
        ],
        correctIndex: 2,
        explanation:
            'Do not click login links from suspicious emails. Open the official portal manually and verify.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Phishing Awareness',
        difficulty: 'Advanced',
        scenario:
            'A message says: “Your parcel is held. Pay RM1.00 redelivery fee here: delivery-my-secure.com”.',
        question: 'What makes this suspicious?',
        options: [
          'The payment amount is small',
          'The domain looks unofficial and creates urgency',
          'Parcel companies never send messages',
          'RM1.00 is too expensive',
        ],
        correctIndex: 1,
        explanation:
            'Scammers often use small payment amounts and fake delivery domains to steal card details.',
        xpReward: 20,
      ),

      QuizQuestion(
        topic: 'Password Security',
        difficulty: 'Beginner',
        scenario:
            'You want to create a password using your name, birth year or student ID because it is easy to remember.',
        question: 'Which password is safest?',
        options: [
          'farhana2002',
          '2023213904',
          'Password123',
          'F@rh4na!Cyber#2026',
        ],
        correctIndex: 3,
        explanation:
            'Strong passwords use mixed characters and avoid personal information.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Password Security',
        difficulty: 'Intermediate',
        scenario:
            'You use the same password for Instagram, student portal and email.',
        question: 'Why is this dangerous?',
        options: [
          'It makes login slower',
          'If one account leaks, attackers can try the same password elsewhere',
          'It uses too much internet',
          'It blocks notifications',
        ],
        correctIndex: 1,
        explanation:
            'Password reuse increases risk because one leaked password can compromise multiple accounts.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Password Security',
        difficulty: 'Advanced',
        scenario:
            'A website offers to store your passwords in plain text notes so you can copy them easily.',
        question: 'What is the best alternative?',
        options: [
          'Use a trusted password manager',
          'Save passwords in WhatsApp chat',
          'Use one password for all accounts',
          'Write password in public bio',
        ],
        correctIndex: 0,
        explanation:
            'A trusted password manager stores passwords securely and reduces password reuse.',
        xpReward: 20,
      ),

      QuizQuestion(
        topic: 'Social Engineering',
        difficulty: 'Intermediate',
        scenario:
            'Someone claims to be your lecturer on Telegram and asks for your student email password.',
        question: 'What should you do?',
        options: [
          'Send password',
          'Ask friends only',
          'Verify via official channel',
          'Ignore all lecturer messages forever',
        ],
        correctIndex: 2,
        explanation:
            'Always verify unusual requests through official communication channels.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Social Engineering',
        difficulty: 'Beginner',
        scenario:
            'A caller says they are from the bank and asks for your OTP to “cancel a transaction”.',
        question: 'What should you do?',
        options: [
          'Give the OTP quickly',
          'End the call and contact the bank using official number',
          'Share half of the OTP',
          'Ask them to call later and then give OTP',
        ],
        correctIndex: 1,
        explanation:
            'Never share OTP. Contact the bank using official channels.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Privacy Protection',
        difficulty: 'Beginner',
        scenario:
            'A photo editing app asks for contacts, microphone, location, storage and camera access.',
        question: 'What is the safest action?',
        options: [
          'Allow all permissions',
          'Only allow permissions needed for the app function',
          'Delete all apps',
          'Share your location first',
        ],
        correctIndex: 1,
        explanation: 'Only give permissions needed for the app function.',
        xpReward: 15,
      ),

      QuizQuestion(
        topic: 'Malware',
        difficulty: 'Beginner',
        scenario: 'You download cracked software from a Telegram group.',
        question: 'Why is this risky?',
        options: [
          'File name is too short',
          'Cracked software can contain malware or spyware',
          'Telegram files are always safe',
          'It only affects old computers',
        ],
        correctIndex: 1,
        explanation:
            'Cracked software is a common source of malware and credential theft.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Malware',
        difficulty: 'Intermediate',
        scenario:
            'Your friend sends an APK file named “premium_movie_app.apk” outside the official app store.',
        question: 'What is the safest response?',
        options: [
          'Install it immediately',
          'Disable security settings to install it',
          'Avoid installing unknown APK files',
          'Send it to more friends',
        ],
        correctIndex: 2,
        explanation:
            'Unknown APK files may contain malware. Use official app stores whenever possible.',
        xpReward: 15,
      ),

      QuizQuestion(
        topic: 'Online Scam',
        difficulty: 'Beginner',
        scenario:
            'You see an online post offering RM500 reward if you register your IC number and bank details.',
        question: 'What is the biggest warning sign?',
        options: [
          'It offers money in exchange for sensitive personal data',
          'The reward amount is not RM1000',
          'The post has colourful design',
          'It uses Malay and English',
        ],
        correctIndex: 0,
        explanation:
            'Requests for bank details and IC in exchange for rewards are common scam indicators.',
        xpReward: 15,
      ),
      QuizQuestion(
        topic: 'Mobile Security',
        difficulty: 'Intermediate',
        scenario:
            'Your phone asks to install a “security update” from a random website.',
        question: 'What should you do?',
        options: [
          'Install it quickly',
          'Only update through official system settings or app store',
          'Share the link',
          'Turn off all security features',
        ],
        correctIndex: 1,
        explanation:
            'System and app updates should come from official settings or official app stores.',
        xpReward: 15,
      ),
    ];
  }
}
