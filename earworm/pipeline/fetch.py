"""Fetch audio from a YouTube URL using yt-dlp."""

import subprocess
import re
from pathlib import Path

from rich.console import Console

console = Console()


def sanitise_filename(title: str) -> str:
    """Create a filesystem-safe name from a video title."""
    clean = re.sub(r"[^\w\s-]", "", title)
    clean = re.sub(r"\s+", "_", clean).strip("_")
    return clean[:80]  # Limit length


def get_video_info(url: str) -> dict:
    """Retrieve video metadata without downloading."""
    result = subprocess.run(
        [
            "yt-dlp",
            "--dump-json",
            "--no-playlist",
            url,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    import json

    return json.loads(result.stdout)


def fetch_audio(url: str, output_dir: Path) -> Path:
    """
    Download audio from a YouTube URL as a WAV file.

    Args:
        url: YouTube video URL.
        output_dir: Directory to save the audio file.

    Returns:
        Path to the downloaded WAV file.
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    console.print(f"[bold blue]Fetching audio from:[/] {url}")

    # Get video info for a clean filename
    info = get_video_info(url)
    title = info.get("title", "unknown")
    safe_name = sanitise_filename(title)
    output_path = output_dir / f"{safe_name}.wav"

    if output_path.exists():
        console.print(f"[yellow]Audio already exists:[/] {output_path}")
        return output_path

    # Download and convert to WAV (44.1kHz mono, good for ML models)
    subprocess.run(
        [
            "yt-dlp",
            "--no-playlist",
            "--extract-audio",
            "--audio-format",
            "wav",
            "--postprocessor-args",
            "ffmpeg:-ar 44100 -ac 1",
            "-o",
            str(output_path),
            url,
        ],
        check=True,
    )

    console.print(f"[green]Audio saved:[/] {output_path}")
    return output_path
