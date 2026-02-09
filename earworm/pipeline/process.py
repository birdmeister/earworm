"""
Earworm processing pipeline — main entry point.

Usage:
    python -m earworm.pipeline.process "https://youtube.com/watch?v=..."

This chains together:
    1. Audio fetch (yt-dlp)
    2. Source separation (Demucs)
    3. Audio-to-MIDI transcription (Basic Pitch or ByteDance)
"""

import sys
import time
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from earworm.pipeline.fetch import fetch_audio
from earworm.pipeline.separate import separate, get_accompaniment
from earworm.pipeline.transcribe import transcribe

console = Console()


def detect_device() -> str:
    """Auto-detect whether CUDA is available."""
    try:
        import torch

        if torch.cuda.is_available():
            name = torch.cuda.get_device_name(0)
            console.print(f"[green]GPU detected:[/] {name}")
            return "cuda"
    except ImportError:
        pass
    console.print("[yellow]No GPU detected, using CPU[/] (this will be slower)")
    return "cpu"


@click.command()
@click.argument("url")
@click.option(
    "--output-dir",
    default="./output",
    type=click.Path(),
    help="Output directory (default: ./output)",
)
@click.option(
    "--skip-separation",
    is_flag=True,
    default=False,
    help="Skip source separation, transcribe the raw audio directly.",
)
@click.option(
    "--transcriber",
    type=click.Choice(["basic-pitch", "bytedance"]),
    default="basic-pitch",
    help="Transcription backend to use.",
)
@click.option(
    "--device",
    type=click.Choice(["cuda", "cpu", "auto"]),
    default="auto",
    help="Device for ML models.",
)
@click.option(
    "--demucs-model",
    default="htdemucs",
    help="Demucs model to use for source separation.",
)
def process(
    url: str,
    output_dir: str,
    skip_separation: bool,
    transcriber: str,
    device: str,
    demucs_model: str,
) -> None:
    """Process a YouTube URL into piano MIDI.

    URL is a YouTube video link, e.g.:
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    """
    start_time = time.time()

    console.print(
        Panel(
            "[bold]Earworm[/] — turn any song into a piano lesson",
            style="blue",
        )
    )

    output_path = Path(output_dir)
    if device == "auto":
        device = detect_device()

    # Step 1: Fetch audio
    console.print("\n[bold]Step 1/3:[/] Fetching audio")
    audio_path = fetch_audio(url, output_path / "audio")

    # Step 2: Source separation
    if skip_separation:
        console.print("\n[bold]Step 2/3:[/] Skipping source separation")
        transcription_input = audio_path
    else:
        console.print("\n[bold]Step 2/3:[/] Separating sources")
        stems = separate(
            audio_path,
            output_path / "stems",
            model=demucs_model,
            device=device,
        )
        # Use the 'other' stem (contains piano, guitar, synths)
        accompaniment = get_accompaniment(stems)
        if accompaniment:
            transcription_input = accompaniment
            console.print(f"[blue]Using 'other' stem for transcription[/]")
        else:
            console.print("[yellow]Could not find 'other' stem, using full audio[/]")
            transcription_input = audio_path

    # Step 3: Transcribe to MIDI
    console.print("\n[bold]Step 3/3:[/] Transcribing to MIDI")
    midi_path = output_path / "midi" / f"{audio_path.stem}.mid"
    transcribe(
        transcription_input,
        midi_path,
        backend=transcriber,
        device=device,
    )

    # Summary
    elapsed = time.time() - start_time

    table = Table(title="Output files")
    table.add_column("Type", style="cyan")
    table.add_column("Path", style="green")

    table.add_row("Audio", str(audio_path))
    if not skip_separation:
        table.add_row("Stems", str(output_path / "stems"))
    table.add_row("MIDI", str(midi_path))

    console.print()
    console.print(table)
    console.print(f"\n[bold green]Done[/] in {elapsed:.1f}s")
    console.print(
        "\n[dim]Next steps: open the MIDI file in a DAW, or wait for the "
        "Earworm play-along interface.[/]"
    )


if __name__ == "__main__":
    process()
