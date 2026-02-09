# Earworm 🎵🐛

**Turn any song into a piano lesson — at your level.**

Earworm takes a YouTube URL, transcribes the music into piano MIDI, generates multiple difficulty levels, and lets you practice along on your own MIDI keyboard (like a Yamaha P-45) with real-time feedback.

Think of it as an open-source alternative to apps like Flowkey, but for *any* song you want to learn.

## How it works

```
YouTube URL
    │
    ▼
┌──────────────┐
│  Audio fetch  │  yt-dlp
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Source      │  Demucs v4 — isolate vocals, drums, bass
│   separation  │  to get a cleaner instrumental signal
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Audio →     │  Basic Pitch / ByteDance piano_transcription
│   MIDI        │  detect notes, timing, velocity
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Difficulty   │  Rule-based + AI simplification
│  levels       │  beginner / intermediate / advanced
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Play along   │  Web MIDI API — real-time feedback
│  interface    │  from your MIDI keyboard
└──────────────┘
```

## Current status

**🚧 Early development — proof of concept**

The core pipeline (YouTube → source separation → MIDI transcription) is functional as a CLI tool. Difficulty generation and the play-along interface are next.

## Quick start

### Requirements

- Python 3.10+
- FFmpeg (for audio processing)
- A CUDA-capable GPU is recommended but not required

### Installation

```bash
git clone https://github.com/yourname/earworm.git
cd earworm
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### Usage

Process a YouTube video into MIDI:

```bash
python -m earworm.pipeline.process "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

This will create a folder in `output/` with:
- The extracted audio (WAV)
- Separated stems (vocals, drums, bass, other)
- A transcribed MIDI file

### Options

```bash
python -m earworm.pipeline.process --help

Options:
  --output-dir PATH      Output directory (default: ./output)
  --skip-separation      Skip source separation, transcribe raw audio
  --transcriber TEXT     Choose transcriber: "basic-pitch" or "bytedance" (default: basic-pitch)
  --device TEXT          Device for ML models: "cuda" or "cpu" (default: auto-detect)
```

## Project structure

```
earworm/
├── earworm/
│   ├── __init__.py
│   ├── pipeline/              # Core processing pipeline
│   │   ├── __init__.py
│   │   ├── process.py         # Main CLI entry point
│   │   ├── fetch.py           # YouTube audio download
│   │   ├── separate.py        # Source separation (Demucs)
│   │   └── transcribe.py      # Audio-to-MIDI transcription
│   ├── difficulty/            # Difficulty level generation
│   │   ├── __init__.py
│   │   ├── simplify.py        # Rule-based simplification
│   │   └── analyse.py         # Difficulty estimation
│   └── web/                   # Play-along web interface (future)
│       └── __init__.py
├── tests/
├── docs/
├── examples/
├── output/                    # Generated files end up here
├── requirements.txt
├── pyproject.toml
└── README.md
```

## Technology stack

### Audio pipeline (Python)

| Component | Tool | Licence | Purpose |
|-----------|------|---------|---------|
| Audio fetch | [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Unlicense | Download audio from YouTube |
| Source separation | [Demucs v4](https://github.com/adefossez/demucs) | MIT | Isolate vocals, drums, bass, other |
| Transcription (lightweight) | [Basic Pitch](https://github.com/spotify/basic-pitch) | Apache 2.0 | Audio-to-MIDI, multi-instrument |
| Transcription (accurate) | [ByteDance piano_transcription](https://github.com/bytedance/piano_transcription) | Apache 2.0 | High-accuracy piano-specific |
| Music analysis | [music21](https://github.com/cuthbertLab/music21) | BSD | MIDI ↔ MusicXML conversion |
| Difficulty adjustment | [diff2diff](https://pramoneda.github.io/diff2diff/) | TBD | AI-based score simplification |

### Play-along interface (web, planned)

| Component | Tool | Licence | Purpose |
|-----------|------|---------|---------|
| MIDI keyboard input | [Web MIDI API](https://developer.mozilla.org/en-US/docs/Web/API/Web_MIDI_API) | Browser standard | Connect hardware MIDI keyboard |
| MIDI library | [MIDIVal](https://github.com/midival) | MIT | High-level MIDI in JS/TS |
| Sheet music rendering | [VexFlow](https://github.com/0xfe/vexflow) | MIT | Render notation as SVG |
| Audio playback | [Tone.js](https://github.com/Tonejs/Tone.js) | MIT | Play MIDI in browser |
| UI framework | React or Svelte | MIT | Frontend framework |

### Inspiration and reference

- [PianoBooster](https://github.com/pianobooster/PianoBooster) — open-source MIDI piano trainer (GPL, C++)
- [Midiano](https://midiano.com) — web-based falling-notes MIDI player
- [Flowkey](https://flowkey.com) — commercial piano learning app (the UX benchmark)

## Roadmap

- [x] Audio extraction from YouTube
- [x] Source separation with Demucs
- [x] Audio-to-MIDI transcription
- [ ] Rule-based difficulty simplification (3 levels)
- [ ] AI-based difficulty adjustment (diff2diff integration)
- [ ] Web interface with falling-notes visualisation
- [ ] Web MIDI API integration for real-time keyboard feedback
- [ ] Wait mode (pause until correct note is played)
- [ ] Loop and slow-motion practice modes
- [ ] Hand separation (left/right hand practice)

## Tested hardware

- Yamaha P-45 (USB-MIDI) — confirmed working

If you've tested Earworm with your MIDI keyboard, please open a PR to add it to this list.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

Key areas where help is needed:
- **Audio/ML**: improving transcription accuracy for non-piano sources
- **Music theory**: better algorithms for difficulty simplification
- **Frontend**: building the play-along web interface
- **Testing**: trying different genres and MIDI keyboards

## Licence

MIT — see [LICENCE](LICENCE) for details.

## Acknowledgements

Earworm is built on the shoulders of excellent open-source projects. Special thanks to the teams behind Demucs, Basic Pitch, ByteDance piano_transcription, music21, and PianoBooster.
