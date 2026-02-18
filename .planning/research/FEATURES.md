# Feature Landscape

**Domain:** Offline-first multilingual translation/chat mobile app (travel)
**Project:** BittyBot
**Researched:** 2026-02-19
**Model:** Cohere Tiny Aya Global 3.35B (on-device, 70+ languages)

---

## Table Stakes

Features users expect. Missing = product feels incomplete or users abandon immediately.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Text translation (type and translate) | Core function every translation app has; zero tolerance for absence | Low | Bidirectional; language auto-detection is a nice-to-have but not required |
| Language selector (source + target) | Users cannot use the app without picking languages | Low | Should persist last-used pair across sessions |
| Works fully offline, zero data required | The entire value prop for travelers; if it needs the network it fails at the moment of need | Medium | Aya model must be bundled or downloadable once on first launch |
| Offline model download / onboarding flow | Users need to know the model is ready before they travel | Medium | Show download progress, storage size (~2 GB), clear "ready to go offline" state |
| Copy translated text to clipboard | Universal expectation; used constantly for pasting into maps, messages | Low | Single tap on result |
| Swap source/target languages | Every translation app has a swap button; absence is jarring | Low | Single icon tap, keeps current text |
| Clear/reset input | Fast path to start over; critical when phone is in a pocket and text is garbled | Low | X button in input field |
| Translation history / recent translations | Users re-use translations repeatedly (same hotel name, same dish) | Low-Medium | Persist locally, reverse-chronological |
| Chat interface (multi-turn) | On-device LLM chat is now expected when an AI is powering the app; single-shot translation only feels under-built | Medium | Distinct from translation mode; conversational not just Q&A |
| Dark mode (default) | Project spec requires it; travelers use phones in low light constantly (restaurants, night markets, planes) | Low | System preference respected; green accent on dark background |
| Large, legible tap targets | Travelers are stressed, tired, using app one-handed | Low | Minimum 48x48dp (Android) / 44pt (iOS) per platform guidelines |
| Font size legibility | Street/restaurant scenarios: bright sun, stress, distance; small text fails | Low | Body text minimum 16sp; avoid thin weights on dark background |
| Persistent language preference | Re-selecting language on every open is a dealbreaker for repeated use | Low | Store last-used source+target pair in local storage |
| Basic error messaging | "Translation failed" with no explanation breaks trust | Low | Human-readable errors: no model loaded, input too long, etc. |

---

## Differentiators

Features that set BittyBot apart from Google Translate / Apple Translate / DeepL. Not universally expected, but valued — especially for the on-device LLM angle.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Conversational AI with LLM context | Aya is a chat model, not just a lookup table; users can ask "how do I say this more politely?" or "what does this sign mean culturally?" — Google Translate cannot do this | Medium | Leverage the model's instruction-following; frame as "chat with a travel assistant" |
| 70+ language support including low-resource languages | Google Translate offline covers ~50 languages; Aya covers 70+ including African, South Asian, Pacific languages — huge for travelers in less-touristed regions | Low (model handles it) | Surface language list prominently; this is a genuine differentiator |
| Full privacy — nothing leaves the device | DeepL offline requires Pro subscription; Google Translate shares data across Google services; BittyBot is zero-network by design | Low (architecture, not feature) | Make this explicit in onboarding: "Your translations never leave your phone" |
| Chat history drawer with named sessions | On-device LLM apps (MLC Chat, Private LLM) frequently omit or poorly implement history; a well-designed drawer beats competition | Medium | Swipe-to-open drawer; sessions named by date or first phrase; search within history |
| Phrasebook / starred translations | iTranslate built a custom phrasebook that users love; travelers repeatedly use the same phrases | Low-Medium | Star icon on any translation; dedicated Phrasebook tab; works entirely offline |
| Web URL / page translation (v2) | Unique for an offline-first app; read foreign-language sites while on Wi-Fi, store translation locally for offline reading | High | V2 scope; requires network fetch + local LLM processing |
| Camera OCR translation (v2) | Menu scanning is the #1 camera use case for travelers; Waygo proved niche viability; Google does it well online | High | V2 scope; requires ML Kit or on-device OCR + LLM translation pipeline |
| Conversation / dialogue mode | Two-person back-and-forth: user speaks/types in English, local partner types/speaks in target language; split-screen view | High | Google and Apple both have this; differentiates from pure chat-LLM apps; requires careful UX |
| Voice input and TTS playback | Tap microphone, speak phrase, hear translated output spoken aloud; travelers show phone to locals | Medium | STT: platform APIs (iOS/Android native); TTS: platform native voices; model handles translation |
| Text-to-speech (listen to translation) | Travelers need to hear pronunciation to say phrases correctly | Low-Medium | Platform TTS APIs; no on-device model needed for audio |
| Transliteration (romanization) | For scripts like Arabic, Thai, Japanese: show how to pronounce in Latin characters | Medium | Many travelers cannot read target scripts; bridges the pronunciation gap |

---

## Anti-Features

Features to deliberately NOT build. Inclusion would add complexity, hurt the core experience, or contradict the offline-first / traveler-focused positioning.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Subscription / paywall on core functionality | DeepL gates offline behind Pro; users resent it; BittyBot's advantage is "download once, yours forever" — a paywall destroys that narrative | Monetize via one-time purchase or open source; keep model bundled |
| Accounts / user registration | Travelers don't want to create accounts to translate a menu; account friction kills activation; data privacy contradiction for an on-device app | All data stays local; no sign-in required |
| Cloud sync of chat history | Contradicts offline-first; adds backend complexity; users who care about privacy (BittyBot's audience) will be alarmed | Local storage only; export-to-file as optional power-user feature |
| Social features (sharing sessions, community phrases) | Not travel-translator behavior; adds backend; misaligns with privacy positioning | Focus on single-user offline excellence |
| Gamification / streaks / hearts | Duolingo-pattern; frustrating for travelers who just need to communicate, not learn; wrong user mental model | Use "recents" and "favorites" instead of engagement mechanics |
| In-app ads | Ad networks require internet; ads break the offline-first experience; degrade trust for a privacy-focused app | Alternative monetization: one-time purchase, tip jar |
| Language learning mode | Flashcards, quizzes, lessons — out of scope; travelers need communication, not courses; dilutes product identity | Stay focused: translate and chat |
| News / content feed | Some translation apps add travel content; it's bloat; travelers need utility, not editorial | Focus on translation quality and speed |
| Multiple simultaneous model downloads | Complexity without clear user benefit; Aya Global handles 70+ languages in one model | Single model, single download; language is selected, not downloaded per language |
| Real-time streaming to server fallback | If offline fails, silently falling back to a server API contradicts the privacy and offline-first promise | Fail explicitly with clear error; no silent network calls |

---

## Feature Dependencies

```
Model Download Complete
  → Text Translation (requires model)
  → Chat Interface (requires model)
  → All LLM-powered features

Text Translation
  → Translation History (history stores translation results)
  → Phrasebook / Favorites (star from any translation result)
  → Copy to Clipboard (copies translation result)

Chat Interface
  → Chat History Drawer (stores chat sessions)
  → Voice Input → TTS Playback (voice in, audio out pipeline)

Language Selector
  → Translation (drives source/target)
  → Voice TTS (drives language of audio output)
  → Transliteration (only relevant for specific script families)

Camera OCR (v2)
  → Text Translation (OCR output feeds translation input)
  → Model Download Complete

Web URL Translation (v2)
  → Network Access (fetch URL content)
  → Text Translation (translate fetched content)
  → Local Storage (store translated page for offline reading)
```

---

## MVP Recommendation

Prioritize for v1 (launch with these or don't ship):

1. **Model onboarding + offline readiness indicator** — Without this, nothing else works; users need confidence the model is ready before they travel
2. **Text translation with language selector** — The core loop; language persistence, swap button, copy to clipboard all included
3. **Chat interface (multi-turn)** — This is the LLM differentiator; a translation-only app with Aya underneath is wasted potential
4. **Chat history drawer** — Users lose context without it; chat without history feels disposable
5. **Translation history (recent translations)** — Travelers reuse translations; recency list is the minimum viable memory
6. **Dark theme with green accents** — Project requirement; also genuinely better for low-light travel environments
7. **Large tap targets + legible typography** — Non-negotiable for usability; cannot be retrofitted cleanly

Defer to v2:
- **Camera OCR** — High complexity, requires ML Kit integration, separate model pipeline; deliver as named v2 feature
- **Web URL translation** — High complexity, network + storage coordination; deliver as named v2 feature
- **Conversation / dialogue mode** — Polished two-person UX requires significant design work; MVP chat covers the need partially
- **Voice input + TTS** — Useful but platform APIs are straightforward; can add post-launch without architecture changes
- **Transliteration** — Valuable but secondary; add once core translation is solid
- **Phrasebook / favorites** — Useful but history covers 80% of the need for v1; star feature can come in v1.1

---

## Confidence Assessment

| Finding | Confidence | Source |
|---------|------------|--------|
| Table stakes features (text, offline, history) | HIGH | Google Translate, Apple Translate, DeepL official docs + user reviews |
| 70+ language coverage via Aya | HIGH | Cohere official announcement (Feb 2026) |
| Privacy as differentiator | HIGH | Multiple comparison articles confirm Google data sharing concerns |
| Anti-features (paywall, accounts) | MEDIUM | User review patterns + DeepL Pro gating confirmed; app market conventions |
| On-device LLM UX gaps (history, polish) | MEDIUM | MLC Chat App Store reviews, Private LLM v2 release notes, community feedback |
| Chat UX best practices | MEDIUM | Multiple UX articles; standards are consistent across sources |
| Camera OCR complexity estimate | MEDIUM | Pattern from Google Translate implementation; specific Flutter ML Kit complexity unverified |

---

## Sources

- [Google Translate offline features](https://support.google.com/translate/answer/6142473?hl=en&co=GENIE.Platform%3DiOS)
- [Google Translate offline improvement blog post](https://blog.google/products/translate/offline-translation/)
- [Apple Translate offline support](https://support.apple.com/en-me/guide/iphone/iphd74cb450f/ios)
- [DeepL Android app features](https://www.deepl.com/en/android-app)
- [Offline Translator Apps comparison 2025/2026 — Timekettle](https://www.timekettle.co/blogs/tips-and-tricks/offline-translator-apps)
- [Translation Apps for Travelers 2025 — Simology](https://simology.io/blog/translation-apps-travelers-2025-google-apple-deepl-microsoft)
- [Cohere Tiny Aya launch — TechCrunch](https://techcrunch.com/2026/02/17/cohere-launches-a-family-of-open-multilingual-models/)
- [Cohere Tiny Aya on-device details — Dataconomy](https://dataconomy.com/2026/02/17/cohere-launches-tiny-aya-multilingual-ai-models-for-70-languages/)
- [MLC Chat App Store listing](https://apps.apple.com/us/app/mlc-chat/id6448482937)
- [Private LLM App Store listing](https://apps.apple.com/us/app/private-llm-local-ai-chat/id6448106860)
- [On-device AI on Android — Towards AI](https://pub.towardsai.net/on-device-ai-chat-translate-on-android-qualcomm-genie-mlc-webllm-your-phone-your-llm-49594aff3b9f)
- [Chat UI design best practices 2025 — CometChat](https://www.cometchat.com/blog/chat-app-design-best-practices)
- [16 Chat UI design patterns 2025 — Bricxlabs](https://bricxlabs.com/blogs/message-screen-ui-deisgn)
- [Dark mode UX 2025 — Alter Square](https://www.altersquare.io/dark-mode-vs-light-mode-the-complete-ux-guide-for-2025/)
- [Mobile accessibility tap targets 2025](https://moldstud.com/articles/p-comprehensive-guide-to-accessibility-in-mobile-app-design-key-considerations-for-inclusive-ux)
- [Best camera translation apps — OpenL Blog](https://blog.openl.io/best-camera-translator-apps-for-your-next-trip/)
- [Travel translation app pros and cons — AFAR](https://www.afar.com/magazine/the-pros-and-cons-of-using-translation-apps-during-travel)
