"""Audio-to-MIDI transcription.

Supports multiple backends:
- Basic Pitch (Spotify): lightweight, multi-instrument, good starting point
- ByteDance piano_transcription: high-accuracy, piano-specific
"""

from pathlib import Path
from typing import Optional

from rich.console import Console

console = Console()


def transcribe_basic_pitch(
    audio_path: Path,
    output_path: Path,
    onset_threshold: float = 0.5,
    frame_threshold: float = 0.3,
    min_note_length_ms: float = 58.0,
    min_frequency: Optional[float] = None,
    max_frequency: Optional[float] = None,
) -> Path:
    """
    Transcribe audio to MIDI using Spotify's Basic Pitch.

    Basic Pitch is lightweight and works with any instrument.
    It's a good default choice, especially for mixed audio.

    Args:
        audio_path: Input audio file.
        output_path: Where to save the MIDI file.
        onset_threshold: Confidence threshold for note onsets (0-1).
            Lower = more notes detected, higher = fewer but more certain.
        frame_threshold: Confidence threshold for note frames (0-1).
        min_note_length_ms: Minimum note duration in milliseconds.
        min_frequency: Filter out notes below this frequency (Hz).
        max_frequency: Filter out notes above this frequency (Hz).

    Returns:
        Path to the generated MIDI file.
    """
    from basic_pitch.inference import predict_and_save

    console.print("[bold blue]Transcribing with Basic Pitch[/]")

    output_dir = output_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)

    predict_and_save(
        audio_path_list=[audio_path],
        output_directory=output_dir,
        save_midi=True,
        sonify_midi=False,
        save_model_outputs=False,
        save_notes=False,
        onset_threshold=onset_threshold,
        frame_threshold=frame_threshold,
        minimum_note_length=min_note_length_ms,
        minimum_frequency=min_frequency,
        maximum_frequency=max_frequency,
    )

    # Basic Pitch saves as {stem}_basic_pitch.mid
    generated = output_dir / f"{audio_path.stem}_basic_pitch.mid"
    if generated.exists() and generated != output_path:
        generated.rename(output_path)

    console.print(f"[green]MIDI saved:[/] {output_path}")
    return output_path


def transcribe_bytedance(
    audio_path: Path,
    output_path: Path,
    device: str = "cpu",
) -> Path:
    """
    Transcribe audio to MIDI using ByteDance's piano transcription model.

    This is more accurate than Basic Pitch for solo piano audio,
    detecting onsets, offsets, velocity, and pedal usage.
    Requires the piano_transcription_inference package:
        pip install piano_transcription_inference

    Args:
        audio_path: Input audio file (should be mostly piano).
        output_path: Where to save the MIDI file.
        device: "cuda" for GPU or "cpu".

    Returns:
        Path to the generated MIDI file.
    """
    try:
        from piano_transcription_inference import PianoTranscription, load_audio, sample_rate
    except ImportError:
        console.print(
            "[red]ByteDance transcriber not installed.[/]\n"
            "Install with: pip install piano_transcription_inference"
        )
        raise

    console.print("[bold blue]Transcribing with ByteDance piano model[/]")

    audio, _ = load_audio(str(audio_path), sr=sample_rate, mono=True)

    transcriptor = PianoTranscription(device=device)
    transcriptor.transcribe(audio, str(output_path))

    console.print(f"[green]MIDI saved:[/] {output_path}")
    return output_path


def transcribe(
    audio_path: Path,
    output_path: Path,
    backend: str = "basic-pitch",
    device: str = "cpu",
    **kwargs,
) -> Path:
    """
    Transcribe audio to MIDI using the specified backend.

    Args:
        audio_path: Input audio file.
        output_path: Where to save the MIDI file.
        backend: "basic-pitch" or "bytedance".
        device: "cuda" or "cpu" (only used by bytedance backend).

    Returns:
        Path to the generated MIDI file.
    """
    if backend == "basic-pitch":
        return transcribe_basic_pitch(audio_path, output_path, **kwargs)
    elif backend == "bytedance":
        return transcribe_bytedance(audio_path, output_path, device=device)
    else:
        raise ValueError(f"Unknown transcription backend: {backend}")
