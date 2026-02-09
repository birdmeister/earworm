"""Source separation using Demucs v4.

Splits a mixed audio file into stems (vocals, drums, bass, other)
so that the transcription model gets a cleaner input signal.
"""

import subprocess
from pathlib import Path
from typing import Optional

from rich.console import Console

console = Console()

# Available Demucs models, from fastest to most accurate
MODELS = {
    "htdemucs": "Hybrid Transformer Demucs v4 (default, good balance)",
    "htdemucs_ft": "Fine-tuned v4 (best quality, 4x slower)",
    "htdemucs_6s": "6-source v4 (adds guitar + piano stems, experimental)",
    "hdemucs_mmi": "Hybrid Demucs v3 (older, faster)",
}

# Standard 4-stem output from Demucs
STEMS = ["vocals", "drums", "bass", "other"]


def separate(
    audio_path: Path,
    output_dir: Path,
    model: str = "htdemucs",
    device: Optional[str] = None,
) -> dict[str, Path]:
    """
    Separate an audio file into stems using Demucs.

    Args:
        audio_path: Path to the input audio file (WAV or MP3).
        output_dir: Directory where stems will be saved.
        model: Demucs model to use (see MODELS dict).
        device: Force "cuda" or "cpu". Auto-detects if None.

    Returns:
        Dictionary mapping stem names to file paths.
        Example: {"vocals": Path("..."), "drums": Path("..."), ...}
    """
    console.print(f"[bold blue]Separating sources[/] using model [cyan]{model}[/]")

    # Build demucs args
    demucs_args = ["-n", model, "-o", str(output_dir)]
    if device:
        demucs_args.extend(["-d", device])
    demucs_args.append(str(audio_path))

    # torchaudio 2.10+ hardcodes torchcodec for save(), which needs
    # FFmpeg shared libs. Patch it to use soundfile instead.
    wrapper = "\n".join([
        "import soundfile as sf, sys, torchaudio",
        "def _save_sf(uri, src, sample_rate, **kw):",
        "    wav = src.cpu().numpy()",
        "    if wav.shape[0] <= 2: wav = wav.T",
        "    sf.write(uri, wav, sample_rate)",
        "torchaudio.save = _save_sf",
        "sys.argv = ['demucs'] + sys.argv[1:]",
        "from demucs.separate import main; main()",
    ])
    cmd = ["python", "-c", wrapper] + demucs_args

    # Run demucs
    subprocess.run(cmd, check=True)

    # Find the output stems
    # Demucs outputs to: output_dir / model / track_name / stem.wav
    track_name = audio_path.stem
    stems_dir = output_dir / model / track_name

    stem_paths = {}
    for stem in STEMS:
        stem_path = stems_dir / f"{stem}.wav"
        if stem_path.exists():
            stem_paths[stem] = stem_path
            console.print(f"  [green]✓[/] {stem}: {stem_path}")
        else:
            console.print(f"  [yellow]✗[/] {stem}: not found")

    return stem_paths


def get_accompaniment(stem_paths: dict[str, Path]) -> Optional[Path]:
    """
    Return the 'other' stem, which typically contains piano, guitar,
    synths, and other melodic/harmonic instruments.

    For transcription purposes, this is usually the most useful stem
    because it removes vocals and drums that would confuse the
    note detection.
    """
    return stem_paths.get("other")


def remix_without_vocals(
    stem_paths: dict[str, Path],
    output_path: Path,
) -> Path:
    """
    Mix all stems except vocals back together.

    This gives a cleaner signal for transcription than the
    'other' stem alone, as it preserves bass lines that might
    be relevant for the piano arrangement.
    """
    import soundfile as sf
    import numpy as np

    stems_to_mix = ["drums", "bass", "other"]
    arrays = []

    for stem_name in stems_to_mix:
        if stem_name in stem_paths:
            data, sr = sf.read(stem_paths[stem_name])
            arrays.append(data)

    if not arrays:
        raise ValueError("No stems available to mix")

    # Sum and normalise
    mixed = sum(arrays)
    max_val = np.max(np.abs(mixed))
    if max_val > 0:
        mixed = mixed / max_val * 0.95

    sf.write(output_path, mixed, sr)
    console.print(f"[green]Instrumental mix saved:[/] {output_path}")
    return output_path
