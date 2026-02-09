# CLAUDE.md — Earworm project context

## What is this project?

Earworm turns any YouTube video into a playable piano lesson at multiple difficulty levels, with real-time MIDI keyboard feedback. Open-source alternative to Flowkey.

## Pipeline architecture (5 stages)

1. **Audio fetch** — yt-dlp extracts audio from YouTube URL → WAV
2. **Source separation** — Demucs v4 splits into vocals/drums/bass/other stems
3. **Audio-to-MIDI transcription** — ByteDance piano_transcription (default, PyTorch) or Basic Pitch (optional, TensorFlow)
4. **Difficulty generation** — Rule-based simplification into beginner/intermediate/advanced MIDI files
5. **Play-along interface** — Web MIDI API connects to hardware keyboard (planned, not yet built)

## Current status

- Stages 1-3: implemented as CLI (`earworm/pipeline/`)
- Stage 4: rule-based simplification implemented (`earworm/difficulty/`), AI-based (diff2diff) planned
- Stage 5: not started (`earworm/web/`)
- 7 passing tests in `tests/test_difficulty.py`
- Not yet tested end-to-end with real audio (dependencies just got working)

## Key technical decisions

- **Python 3.12** — required because TensorFlow/ML ecosystem doesn't fully support 3.13 yet
- **uv** for package management, not pip/venv
- **ByteDance transcriber is default** — Basic Pitch (Spotify) requires TensorFlow which causes `tensorflow-macos` hell on macOS. Basic Pitch is deliberately excluded from pyproject.toml. Users can install it manually if needed.
- **PyTorch only** in core deps — Demucs and ByteDance both use PyTorch
- **MIT licence**

## Project structure

```
earworm/
├── earworm/
│   ├── __init__.py
│   ├── pipeline/
│   │   ├── process.py     # CLI entry point (click)
│   │   ├── fetch.py       # yt-dlp wrapper
│   │   ├── separate.py    # Demucs wrapper
│   │   └── transcribe.py  # Basic Pitch + ByteDance backends
│   ├── difficulty/
│   │   ├── simplify.py    # Rule-based beginner/intermediate/advanced
│   │   └── analyse.py     # Difficulty estimation heuristics
│   └── web/               # Planned: play-along interface
├── tests/
│   └── test_difficulty.py
├── docs/
│   └── CONTRIBUTING.md    # In Dutch
├── pyproject.toml
├── LICENCE
└── README.md
```

## Commands

```bash
uv sync --extra dev          # Install dependencies
uv run pytest                # Run tests
uv run earworm "URL"         # Process a YouTube URL
uv run earworm --help        # CLI options
```

## Hardware

Owner uses a Yamaha P-45 (USB-MIDI) for testing.

## Open-source tools used

- **yt-dlp** — YouTube audio extraction
- **Demucs v4** (github.com/adefossez/demucs) — source separation, MIT
- **ByteDance piano_transcription** (github.com/bytedance/piano_transcription) — piano-specific transcription, Apache 2.0
- **Basic Pitch** (github.com/spotify/basic-pitch) — multi-instrument transcription, Apache 2.0 (optional, not in deps)
- **mido** — MIDI file I/O
- **music21** — MIDI/MusicXML conversion, music theory operations
- **click** + **rich** — CLI

## Planned next steps

1. End-to-end test with real YouTube audio
2. diff2diff integration for AI-based difficulty simplification (pramoneda.github.io/diff2diff)
3. Web interface with falling-notes visualisation (React or Svelte)
4. Web MIDI API integration for real-time keyboard input
5. Wait mode, loop mode, hand separation, tempo control

## Style notes

- Docstrings and code in English
- CONTRIBUTING.md in Dutch
- Owner prefers informal, B1-level Dutch communication
- Owner's name is Martin