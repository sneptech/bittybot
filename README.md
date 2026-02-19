<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="BittyBot icon">
</p>

<h1 align="center">BittyBot</h1>

<p align="center">
  Offline multilingual chat and translation for travelers
</p>

> **Work in progress** — BittyBot is under active development and not yet ready for general use.

## What is BittyBot?

BittyBot is a mobile chat and translation app that runs entirely on your device with no internet required. It's built for travelers who need to communicate across languages in places with limited or no connectivity — reading signs, talking to locals, translating menus, or summarizing foreign-language content.

The app runs [Cohere's Tiny Aya Global 3.35B](https://huggingface.co/CohereLabs/tiny-aya-global) language model on-device via [llama.cpp](https://github.com/ggml-org/llama.cpp), supporting 70+ languages including low-resource ones that major translation apps often handle poorly.

## Features (planned)

- **Fully offline** — the model downloads once on first launch (~2 GB), then everything works without internet
- **70+ languages** — broad multilingual support including Arabic, Hindi, Japanese, Korean, and many more
- **Chat interface** — familiar ChatGPT-style conversation UI
- **Translation and summarization** — paste foreign text and get useful responses
- **Chat history** — persistent local storage with configurable auto-clear
- **Web search mode** — paste a URL to translate/summarize a webpage (when online)
- **Privacy-first** — no accounts, no cloud sync, no data leaves your device

## Tech stack

- **Flutter** (iOS and Android from a single codebase)
- **llama.cpp** for on-device inference
- **Riverpod** for state management
- **Drift** (SQLite) for local storage

## License

The app code is open source. The Tiny Aya Global model is licensed under [CC-BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) by Cohere.
