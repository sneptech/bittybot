/// Comprehensive 70+ language test corpus for BittyBot inference spike.
///
/// Contains all Aya-supported languages with travel phrases for priority
/// languages and reference sentences for standard languages. Every language
/// has a script validator regex.
///
/// Priority languages (mustHave): Chinese Mandarin, Cantonese, Latin American
/// Spanish, English — each with 15+ travel phrase prompts.
///
/// Standard languages (standard): All other Aya-supported languages with 2–3
/// reference sentences each.
library;

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

/// Priority tier for a language in the test corpus.
enum LanguagePriority {
  /// Must-have: Mandarin, Cantonese, Latin American Spanish, English.
  /// These get extensive travel phrase coverage (15+ prompts).
  mustHave,

  /// Standard: All other Aya-supported languages.
  /// These get 2–3 simple reference sentences.
  standard,
}

/// Unicode script family used for output validation.
enum ScriptFamily {
  latin,
  arabic,
  thai,
  cjk,
  japanese,
  korean,
  cyrillic,
  devanagari,
  bengali,
  tamil,
  telugu,
  gujarati,
  gurmukhi,
  khmer,
  lao,
  burmese,
  ethiopic,
  hebrew,
  greek,
}

/// A single translation prompt to send to the model.
class TestPrompt {
  /// Category of this prompt (e.g., "travel_directions", "travel_food",
  /// "travel_emergency", "travel_greetings", "travel_prices",
  /// "travel_basic", "reference").
  final String category;

  /// English source text.
  final String sourceText;

  /// Full prompt string including Aya chat template tokens.
  final String prompt;

  /// Optional regex that expected output should match (e.g., Cantonese
  /// particle check). Null means only the scriptValidator is used.
  final String? expectedPattern;

  const TestPrompt({
    required this.category,
    required this.sourceText,
    required this.prompt,
    this.expectedPattern,
  });
}

/// All test data for a single language.
class LanguageTestData {
  /// Human-readable language name (e.g., "Chinese (Mandarin)").
  final String languageName;

  /// Native name (e.g., "中文 (普通话)").
  final String nativeName;

  /// BCP-47 or informal language code (e.g., "zh-cmn", "yue", "es-419").
  final String languageCode;

  /// Script family used for output validation.
  final ScriptFamily scriptFamily;

  /// Priority tier (mustHave or standard).
  final LanguagePriority priority;

  /// Test prompts for this language.
  final List<TestPrompt> prompts;

  /// Regex to verify output uses the correct script.
  final RegExp scriptValidator;

  const LanguageTestData({
    required this.languageName,
    required this.nativeName,
    required this.languageCode,
    required this.scriptFamily,
    required this.priority,
    required this.prompts,
    required this.scriptValidator,
  });
}

// ---------------------------------------------------------------------------
// Aya chat template helper
// ---------------------------------------------------------------------------

/// System prompt that steers the model toward translation-only output.
///
/// Kept short and direct for a 3.35B model — complex instructions get ignored.
const String _systemPrompt =
    'You are a translator. Translate the text the user gives you into the '
    'requested language. Reply with only the translation, nothing else.';

/// Wraps [text] in the Aya chat template tokens with a system prompt.
String _ayaPrompt(String languageInstruction, String sourceText) {
  return '<|START_OF_TURN_TOKEN|><|SYSTEM_TOKEN|>$_systemPrompt<|END_OF_TURN_TOKEN|>'
      '<|START_OF_TURN_TOKEN|><|USER_TOKEN|>$languageInstruction: '
      '"$sourceText"<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>';
}

/// Builds a translate prompt for [targetLanguage].
TestPrompt _tp(
  String category,
  String sourceText,
  String targetLanguage, {
  String? expectedPattern,
}) {
  return TestPrompt(
    category: category,
    sourceText: sourceText,
    prompt: _ayaPrompt('Translate the following into $targetLanguage', sourceText),
    expectedPattern: expectedPattern,
  );
}

/// Builds a translate prompt with a custom instruction (used for Cantonese).
TestPrompt _tpCustom(
  String category,
  String sourceText,
  String fullInstruction, {
  String? expectedPattern,
}) {
  return TestPrompt(
    category: category,
    sourceText: sourceText,
    prompt: _ayaPrompt(fullInstruction, sourceText),
    expectedPattern: expectedPattern,
  );
}

// ---------------------------------------------------------------------------
// Script validators
// ---------------------------------------------------------------------------

final _latinValidator = RegExp(r'[\u0041-\u024F]');
final _arabicValidator = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');
final _thaiValidator = RegExp(r'[\u0E00-\u0E7F]');
final _cjkValidator = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\u3000-\u303F]');
final _japaneseValidator = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]');
final _koreanValidator = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF]');
final _cyrillicValidator = RegExp(r'[\u0400-\u04FF]');
final _devanagariValidator = RegExp(r'[\u0900-\u097F]');
final _bengaliValidator = RegExp(r'[\u0980-\u09FF]');
final _tamilValidator = RegExp(r'[\u0B80-\u0BFF]');
final _teluguValidator = RegExp(r'[\u0C00-\u0C7F]');
final _gujaratiValidator = RegExp(r'[\u0A80-\u0AFF]');
final _gurmukhiValidator = RegExp(r'[\u0A00-\u0A7F]');
final _khmerValidator = RegExp(r'[\u1780-\u17FF]');
final _laoValidator = RegExp(r'[\u0E80-\u0EFF]');
final _burmeseValidator = RegExp(r'[\u1000-\u109F]');
final _ethiopicValidator = RegExp(r'[\u1200-\u137F]');
final _hebrewValidator = RegExp(r'[\u0590-\u05FF]');
final _greekValidator = RegExp(r'[\u0370-\u03FF]');

// ---------------------------------------------------------------------------
// Cantonese-specific particle pattern
// ---------------------------------------------------------------------------

/// Cantonese-specific particles that distinguish Cantonese from Mandarin.
const String _cantoneseParticlePattern = r'[㗎囉喇嘅咁咋㖖]';

// ---------------------------------------------------------------------------
// Priority language prompts
// ---------------------------------------------------------------------------

/// Chinese Mandarin — extensive travel phrases across 8 categories.
final List<TestPrompt> _mandarinPrompts = [
  // Directions (3)
  _tp('travel_directions', 'Where is the nearest subway station?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_directions', 'How do I get to the airport?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_directions', 'Is this the right way to the city center?', 'Chinese (Mandarin, Simplified Chinese)'),
  // Food (3)
  _tp('travel_food', 'I would like to order the noodles. How much is it?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_food', 'Do you have a menu in English?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_food', 'I am allergic to peanuts.', 'Chinese (Mandarin, Simplified Chinese)'),
  // Emergencies (3)
  _tp('travel_emergency', 'I need help, please call an ambulance.', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_emergency', 'Where is the nearest hospital?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_emergency', 'I lost my passport.', 'Chinese (Mandarin, Simplified Chinese)'),
  // Greetings (3)
  _tp('travel_greetings', 'Hello, nice to meet you.', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_greetings', 'Thank you very much.', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_greetings', 'Excuse me, do you speak English?', 'Chinese (Mandarin, Simplified Chinese)'),
  // Prices (2)
  _tp('travel_prices', 'How much does this cost?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_prices', 'Can I pay with credit card?', 'Chinese (Mandarin, Simplified Chinese)'),
  // Basic sentences (2)
  _tp('travel_basic', 'What time is it?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_basic', 'Where is the bathroom?', 'Chinese (Mandarin, Simplified Chinese)'),
  // Questions (2)
  _tp('travel_basic', 'I do not understand. Can you repeat that?', 'Chinese (Mandarin, Simplified Chinese)'),
  _tp('travel_basic', 'Can you help me find my hotel?', 'Chinese (Mandarin, Simplified Chinese)'),
];

/// Cantonese — same travel categories but with Cantonese-forcing prompt.
///
/// The instruction explicitly requests Cantonese (廣東話/粵語) and NOT Mandarin.
/// Validation checks for Cantonese-specific particles.
const String _cantoneseInstruction =
    'Translate the following into Cantonese (廣東話/粵語, Yue Chinese — '
    'NOT Mandarin Chinese). Include Cantonese-specific vocabulary and particles '
    '(e.g., 㗎, 囉, 喇, 嘅, 咁)';

final List<TestPrompt> _cantonesePrompts = [
  // Directions (3)
  _tpCustom('travel_directions', 'Where is the nearest MTR station?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_directions', 'How do I get to the airport?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_directions', 'Is this the right way to the city center?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Food (3)
  _tpCustom('travel_food', 'I would like to order the wonton noodles. How much is it?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_food', 'Do you have a menu in English?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_food', 'I am allergic to shellfish.', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Emergencies (3)
  _tpCustom('travel_emergency', 'I need help, please call an ambulance.', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_emergency', 'Where is the nearest hospital?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_emergency', 'I lost my passport.', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Greetings (3)
  _tpCustom('travel_greetings', 'Hello, nice to meet you.', _cantoneseInstruction),
  _tpCustom('travel_greetings', 'Thank you very much.', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_greetings', 'Excuse me, do you speak English?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Prices (2)
  _tpCustom('travel_prices', 'How much does this cost?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_prices', 'That is too expensive.', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Basic sentences (2)
  _tpCustom('travel_basic', 'What time is it?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_basic', 'Where is the bathroom?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  // Questions (2)
  _tpCustom('travel_basic', 'I do not understand. Can you repeat that?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
  _tpCustom('travel_basic', 'Can you help me find my hotel?', _cantoneseInstruction, expectedPattern: _cantoneseParticlePattern),
];

/// Latin American Spanish — same categories, explicitly specifying LA Spanish.
const String _laSpanishTarget = 'Latin American Spanish (NOT Castilian/European Spanish)';

final List<TestPrompt> _laSpanishPrompts = [
  // Directions (3)
  _tp('travel_directions', 'Where is the nearest subway station?', _laSpanishTarget),
  _tp('travel_directions', 'How do I get to the airport?', _laSpanishTarget),
  _tp('travel_directions', 'Is this the right way to the city center?', _laSpanishTarget),
  // Food (3)
  _tp('travel_food', 'I would like to order the tacos. How much is it?', _laSpanishTarget),
  _tp('travel_food', 'Do you have a menu in English?', _laSpanishTarget),
  _tp('travel_food', 'I am allergic to gluten.', _laSpanishTarget),
  // Emergencies (3)
  _tp('travel_emergency', 'I need help, please call an ambulance.', _laSpanishTarget),
  _tp('travel_emergency', 'Where is the nearest hospital?', _laSpanishTarget),
  _tp('travel_emergency', 'I lost my passport.', _laSpanishTarget),
  // Greetings (3)
  _tp('travel_greetings', 'Hello, nice to meet you.', _laSpanishTarget),
  _tp('travel_greetings', 'Thank you very much.', _laSpanishTarget),
  _tp('travel_greetings', 'Excuse me, do you speak English?', _laSpanishTarget),
  // Prices (2)
  _tp('travel_prices', 'How much does this cost?', _laSpanishTarget),
  _tp('travel_prices', 'Can I pay with credit card?', _laSpanishTarget),
  // Basic sentences (2)
  _tp('travel_basic', 'What time is it?', _laSpanishTarget),
  _tp('travel_basic', 'Where is the bathroom?', _laSpanishTarget),
  // Questions (2)
  _tp('travel_basic', 'I do not understand. Can you repeat that?', _laSpanishTarget),
  _tp('travel_basic', 'Can you help me find my hotel?', _laSpanishTarget),
];

/// English — paraphrasing and basic travel phrases to verify English output.
final List<TestPrompt> _englishPrompts = [
  // Paraphrase checks (3)
  _tp('travel_directions', 'Where is the nearest subway station?', 'English (paraphrase this naturally)'),
  _tp('travel_food', 'I would like to order a burger. How much does it cost?', 'English (paraphrase this naturally)'),
  _tp('travel_emergency', 'I need help, please call an ambulance.', 'English (paraphrase this naturally)'),
  // Travel phrases (same categories)
  _tp('travel_greetings', 'Hello, nice to meet you.', 'English'),
  _tp('travel_greetings', 'Thank you very much.', 'English'),
  _tp('travel_greetings', 'Excuse me, do you speak Mandarin?', 'English'),
  _tp('travel_prices', 'How much does this cost?', 'English'),
  _tp('travel_prices', 'Can I pay with credit card?', 'English'),
  _tp('travel_basic', 'What time is it?', 'English'),
  _tp('travel_basic', 'Where is the bathroom?', 'English'),
  _tp('travel_basic', 'I do not understand. Can you repeat that please?', 'English'),
  _tp('travel_basic', 'Can you help me find my hotel?', 'English'),
  _tp('travel_directions', 'How do I get to the airport?', 'English'),
  _tp('travel_emergency', 'Where is the nearest hospital?', 'English'),
  _tp('travel_emergency', 'I lost my passport.', 'English'),
  _tp('travel_food', 'Do you have a menu in English?', 'English'),
  _tp('travel_food', 'I am allergic to peanuts.', 'English'),
  _tp('travel_prices', 'That is too expensive. Do you have a discount?', 'English'),
];

// ---------------------------------------------------------------------------
// Standard language prompts helper
// ---------------------------------------------------------------------------

/// Standard reference prompts for a given [languageName].
List<TestPrompt> _stdPrompts(String languageName) => [
      _tp('reference', 'The weather is nice today.', languageName),
      _tp('reference', 'Where is the nearest restaurant?', languageName),
      _tp('reference', 'Please help me find my hotel.', languageName),
    ];

// ---------------------------------------------------------------------------
// Full language corpus
// ---------------------------------------------------------------------------

/// Complete test corpus for all 70+ Aya-supported languages.
final List<LanguageTestData> languageCorpus = [
  // =========================================================================
  // Must-have languages
  // =========================================================================

  LanguageTestData(
    languageName: 'Chinese (Mandarin)',
    nativeName: '中文 (普通话)',
    languageCode: 'zh-cmn',
    scriptFamily: ScriptFamily.cjk,
    priority: LanguagePriority.mustHave,
    prompts: _mandarinPrompts,
    scriptValidator: _cjkValidator,
  ),

  LanguageTestData(
    languageName: 'Cantonese',
    nativeName: '粵語 / 廣東話',
    languageCode: 'yue',
    scriptFamily: ScriptFamily.cjk,
    priority: LanguagePriority.mustHave,
    prompts: _cantonesePrompts,
    // Cantonese output uses CJK characters + Cantonese-specific particles
    scriptValidator: _cjkValidator,
  ),

  LanguageTestData(
    languageName: 'Spanish (Latin American)',
    nativeName: 'Español (Latinoamérica)',
    languageCode: 'es-419',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.mustHave,
    prompts: _laSpanishPrompts,
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'English',
    nativeName: 'English',
    languageCode: 'en',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.mustHave,
    prompts: _englishPrompts,
    scriptValidator: _latinValidator,
  ),

  // =========================================================================
  // Standard languages — Latin script (European)
  // =========================================================================

  LanguageTestData(
    languageName: 'Dutch',
    nativeName: 'Nederlands',
    languageCode: 'nl',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Dutch'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'French',
    nativeName: 'Français',
    languageCode: 'fr',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('French'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Italian',
    nativeName: 'Italiano',
    languageCode: 'it',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Italian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Portuguese',
    nativeName: 'Português',
    languageCode: 'pt',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Portuguese'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Romanian',
    nativeName: 'Română',
    languageCode: 'ro',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Romanian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Czech',
    nativeName: 'Čeština',
    languageCode: 'cs',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Czech'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Polish',
    nativeName: 'Polski',
    languageCode: 'pl',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Polish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Croatian',
    nativeName: 'Hrvatski',
    languageCode: 'hr',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Croatian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Catalan',
    nativeName: 'Català',
    languageCode: 'ca',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Catalan'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Galician',
    nativeName: 'Galego',
    languageCode: 'gl',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Galician'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Welsh',
    nativeName: 'Cymraeg',
    languageCode: 'cy',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Welsh'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Irish',
    nativeName: 'Gaeilge',
    languageCode: 'ga',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Irish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Basque',
    nativeName: 'Euskara',
    languageCode: 'eu',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Basque'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Slovak',
    nativeName: 'Slovenčina',
    languageCode: 'sk',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Slovak'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Slovenian',
    nativeName: 'Slovenščina',
    languageCode: 'sl',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Slovenian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Estonian',
    nativeName: 'Eesti',
    languageCode: 'et',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Estonian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Finnish',
    nativeName: 'Suomi',
    languageCode: 'fi',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Finnish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Hungarian',
    nativeName: 'Magyar',
    languageCode: 'hu',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Hungarian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Danish',
    nativeName: 'Dansk',
    languageCode: 'da',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Danish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Swedish',
    nativeName: 'Svenska',
    languageCode: 'sv',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Swedish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Norwegian',
    nativeName: 'Norsk',
    languageCode: 'no',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Norwegian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'German',
    nativeName: 'Deutsch',
    languageCode: 'de',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('German'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Latvian',
    nativeName: 'Latviešu',
    languageCode: 'lv',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Latvian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Lithuanian',
    nativeName: 'Lietuvių',
    languageCode: 'lt',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Lithuanian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Maltese',
    nativeName: 'Malti',
    languageCode: 'mt',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Maltese'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Turkish',
    nativeName: 'Türkçe',
    languageCode: 'tr',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Turkish'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Azerbaijani',
    nativeName: 'Azərbaycan dili',
    languageCode: 'az',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Azerbaijani'),
    scriptValidator: _latinValidator,
  ),

  // =========================================================================
  // Standard languages — Latin script (Southeast Asian / Pacific)
  // =========================================================================

  LanguageTestData(
    languageName: 'Tagalog',
    nativeName: 'Wikang Tagalog',
    languageCode: 'tl',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Tagalog'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Malay',
    nativeName: 'Bahasa Melayu',
    languageCode: 'ms',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Malay'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    languageCode: 'id',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Indonesian'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Javanese',
    nativeName: 'Basa Jawa',
    languageCode: 'jv',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Javanese'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    languageCode: 'vi',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Vietnamese'),
    scriptValidator: _latinValidator,
  ),

  // =========================================================================
  // Standard languages — Latin script (African)
  // =========================================================================

  LanguageTestData(
    languageName: 'Swahili',
    nativeName: 'Kiswahili',
    languageCode: 'sw',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Swahili'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Hausa',
    nativeName: 'Harshen Hausa',
    languageCode: 'ha',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Hausa'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Igbo',
    nativeName: 'Asụsụ Igbo',
    languageCode: 'ig',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Igbo'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Malagasy',
    nativeName: 'Malagasy',
    languageCode: 'mg',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Malagasy'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Shona',
    nativeName: 'chiShona',
    languageCode: 'sn',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Shona'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Wolof',
    nativeName: 'Wolof',
    languageCode: 'wo',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Wolof'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Xhosa',
    nativeName: 'isiXhosa',
    languageCode: 'xh',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Xhosa'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Yoruba',
    nativeName: 'Èdè Yorùbá',
    languageCode: 'yo',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Yoruba'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Zulu',
    nativeName: 'isiZulu',
    languageCode: 'zu',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Zulu'),
    scriptValidator: _latinValidator,
  ),

  LanguageTestData(
    languageName: 'Somali',
    nativeName: 'Af Soomaali',
    languageCode: 'so',
    scriptFamily: ScriptFamily.latin,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Somali'),
    scriptValidator: _latinValidator,
  ),

  // =========================================================================
  // Standard languages — Arabic script (RTL)
  // =========================================================================

  LanguageTestData(
    languageName: 'Arabic',
    nativeName: 'العربية',
    languageCode: 'ar',
    scriptFamily: ScriptFamily.arabic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Arabic'),
    scriptValidator: _arabicValidator,
  ),

  LanguageTestData(
    languageName: 'Persian',
    nativeName: 'فارسی',
    languageCode: 'fa',
    scriptFamily: ScriptFamily.arabic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Persian'),
    scriptValidator: _arabicValidator,
  ),

  LanguageTestData(
    languageName: 'Urdu',
    nativeName: 'اردو',
    languageCode: 'ur',
    scriptFamily: ScriptFamily.arabic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Urdu'),
    scriptValidator: _arabicValidator,
  ),

  // =========================================================================
  // Standard languages — Thai script
  // =========================================================================

  LanguageTestData(
    languageName: 'Thai',
    nativeName: 'ภาษาไทย',
    languageCode: 'th',
    scriptFamily: ScriptFamily.thai,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Thai'),
    scriptValidator: _thaiValidator,
  ),

  // =========================================================================
  // Standard languages — CJK / East Asian
  // =========================================================================

  LanguageTestData(
    languageName: 'Japanese',
    nativeName: '日本語',
    languageCode: 'ja',
    scriptFamily: ScriptFamily.japanese,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Japanese'),
    scriptValidator: _japaneseValidator,
  ),

  LanguageTestData(
    languageName: 'Korean',
    nativeName: '한국어',
    languageCode: 'ko',
    scriptFamily: ScriptFamily.korean,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Korean'),
    scriptValidator: _koreanValidator,
  ),

  // =========================================================================
  // Standard languages — Cyrillic script
  // =========================================================================

  LanguageTestData(
    languageName: 'Russian',
    nativeName: 'Русский',
    languageCode: 'ru',
    scriptFamily: ScriptFamily.cyrillic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Russian'),
    scriptValidator: _cyrillicValidator,
  ),

  LanguageTestData(
    languageName: 'Ukrainian',
    nativeName: 'Українська',
    languageCode: 'uk',
    scriptFamily: ScriptFamily.cyrillic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Ukrainian'),
    scriptValidator: _cyrillicValidator,
  ),

  LanguageTestData(
    languageName: 'Bulgarian',
    nativeName: 'Български',
    languageCode: 'bg',
    scriptFamily: ScriptFamily.cyrillic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Bulgarian'),
    scriptValidator: _cyrillicValidator,
  ),

  LanguageTestData(
    languageName: 'Serbian',
    nativeName: 'Српски',
    languageCode: 'sr',
    scriptFamily: ScriptFamily.cyrillic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Serbian'),
    scriptValidator: _cyrillicValidator,
  ),

  // =========================================================================
  // Standard languages — Devanagari script
  // =========================================================================

  LanguageTestData(
    languageName: 'Hindi',
    nativeName: 'हिन्दी',
    languageCode: 'hi',
    scriptFamily: ScriptFamily.devanagari,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Hindi'),
    scriptValidator: _devanagariValidator,
  ),

  LanguageTestData(
    languageName: 'Marathi',
    nativeName: 'मराठी',
    languageCode: 'mr',
    scriptFamily: ScriptFamily.devanagari,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Marathi'),
    scriptValidator: _devanagariValidator,
  ),

  LanguageTestData(
    languageName: 'Nepali',
    nativeName: 'नेपाली',
    languageCode: 'ne',
    scriptFamily: ScriptFamily.devanagari,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Nepali'),
    scriptValidator: _devanagariValidator,
  ),

  // =========================================================================
  // Standard languages — Bengali script
  // =========================================================================

  LanguageTestData(
    languageName: 'Bengali',
    nativeName: 'বাংলা',
    languageCode: 'bn',
    scriptFamily: ScriptFamily.bengali,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Bengali'),
    scriptValidator: _bengaliValidator,
  ),

  // =========================================================================
  // Standard languages — Tamil script
  // =========================================================================

  LanguageTestData(
    languageName: 'Tamil',
    nativeName: 'தமிழ்',
    languageCode: 'ta',
    scriptFamily: ScriptFamily.tamil,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Tamil'),
    scriptValidator: _tamilValidator,
  ),

  // =========================================================================
  // Standard languages — Telugu script
  // =========================================================================

  LanguageTestData(
    languageName: 'Telugu',
    nativeName: 'తెలుగు',
    languageCode: 'te',
    scriptFamily: ScriptFamily.telugu,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Telugu'),
    scriptValidator: _teluguValidator,
  ),

  // =========================================================================
  // Standard languages — Gujarati script
  // =========================================================================

  LanguageTestData(
    languageName: 'Gujarati',
    nativeName: 'ગુજરાતી',
    languageCode: 'gu',
    scriptFamily: ScriptFamily.gujarati,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Gujarati'),
    scriptValidator: _gujaratiValidator,
  ),

  // =========================================================================
  // Standard languages — Gurmukhi script (Punjabi)
  // =========================================================================

  LanguageTestData(
    languageName: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    languageCode: 'pa',
    scriptFamily: ScriptFamily.gurmukhi,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Punjabi'),
    scriptValidator: _gurmukhiValidator,
  ),

  // =========================================================================
  // Standard languages — Khmer script
  // =========================================================================

  LanguageTestData(
    languageName: 'Khmer',
    nativeName: 'ភាសាខ្មែរ',
    languageCode: 'km',
    scriptFamily: ScriptFamily.khmer,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Khmer'),
    scriptValidator: _khmerValidator,
  ),

  // =========================================================================
  // Standard languages — Lao script
  // =========================================================================

  LanguageTestData(
    languageName: 'Lao',
    nativeName: 'ພາສາລາວ',
    languageCode: 'lo',
    scriptFamily: ScriptFamily.lao,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Lao'),
    scriptValidator: _laoValidator,
  ),

  // =========================================================================
  // Standard languages — Burmese (Myanmar) script
  // =========================================================================

  LanguageTestData(
    languageName: 'Burmese',
    nativeName: 'မြန်မာဘာသာ',
    languageCode: 'my',
    scriptFamily: ScriptFamily.burmese,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Burmese'),
    scriptValidator: _burmeseValidator,
  ),

  // =========================================================================
  // Standard languages — Ethiopic script
  // =========================================================================

  LanguageTestData(
    languageName: 'Amharic',
    nativeName: 'አማርኛ',
    languageCode: 'am',
    scriptFamily: ScriptFamily.ethiopic,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Amharic'),
    scriptValidator: _ethiopicValidator,
  ),

  // =========================================================================
  // Standard languages — Hebrew script
  // =========================================================================

  LanguageTestData(
    languageName: 'Hebrew',
    nativeName: 'עברית',
    languageCode: 'he',
    scriptFamily: ScriptFamily.hebrew,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Hebrew'),
    scriptValidator: _hebrewValidator,
  ),

  // =========================================================================
  // Standard languages — Greek script
  // =========================================================================

  LanguageTestData(
    languageName: 'Greek',
    nativeName: 'Ελληνικά',
    languageCode: 'el',
    scriptFamily: ScriptFamily.greek,
    priority: LanguagePriority.standard,
    prompts: _stdPrompts('Greek'),
    scriptValidator: _greekValidator,
  ),
];

// ---------------------------------------------------------------------------
// Convenience getters
// ---------------------------------------------------------------------------

/// All languages in the corpus (70+).
List<LanguageTestData> get allLanguages => languageCorpus;

/// Priority languages requiring extensive travel phrase coverage.
/// Always exactly 4: Mandarin, Cantonese, Latin American Spanish, English.
List<LanguageTestData> get mustHaveLanguages =>
    languageCorpus
        .where((l) => l.priority == LanguagePriority.mustHave)
        .toList();

/// Standard languages with reference sentence coverage.
List<LanguageTestData> get standardLanguages =>
    languageCorpus
        .where((l) => l.priority == LanguagePriority.standard)
        .toList();
