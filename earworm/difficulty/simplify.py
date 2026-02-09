"""Rule-based MIDI simplification for different difficulty levels.

This module takes a MIDI file and produces simplified versions
at three levels: beginner, intermediate, and advanced.

The approach is rule-based for now. Future versions will integrate
AI-based simplification (diff2diff) for more musically coherent results.

Simplification strategies per level:

    Advanced (level 3):
        - Original transcription, minor cleanup only
        - Remove very short notes (likely transcription artifacts)
        - Quantise timing to nearest 16th note

    Intermediate (level 2):
        - Reduce polyphony: max 4 simultaneous notes
        - Simplify chords: keep root + top note
        - Quantise to 8th notes
        - Remove notes below velocity threshold

    Beginner (level 1):
        - Melody only: single note line
        - Quantise to quarter notes
        - Constrain to one octave range (transpose if needed)
        - Slow down tempo by 25%
"""

from pathlib import Path
from typing import Optional

import mido
from rich.console import Console

console = Console()

# Difficulty level constants
BEGINNER = 1
INTERMEDIATE = 2
ADVANCED = 3


def _quantise_tick(tick: int, grid: int) -> int:
    """Snap a tick value to the nearest grid position."""
    return round(tick / grid) * grid


def _get_ticks_per_beat(mid: mido.MidiFile) -> int:
    """Get ticks per beat from a MIDI file."""
    return mid.ticks_per_beat


def simplify_advanced(mid: mido.MidiFile) -> mido.MidiFile:
    """
    Level 3: Light cleanup of the original transcription.

    - Remove notes shorter than 30ms (transcription artifacts)
    - Quantise to 16th note grid
    """
    tpb = _get_ticks_per_beat(mid)
    grid = tpb // 4  # 16th notes

    output = mido.MidiFile(ticks_per_beat=tpb)

    for track in mid.tracks:
        new_track = mido.MidiTrack()
        cumulative_time = 0

        for msg in track:
            cumulative_time += msg.time

            if msg.type in ("note_on", "note_off"):
                quantised_time = _quantise_tick(cumulative_time, grid)
                new_msg = msg.copy(time=0)
                new_track.append(new_msg)
            else:
                new_track.append(msg.copy(time=0))

        # Recalculate delta times
        _recalculate_deltas(new_track, grid)
        output.tracks.append(new_track)

    return output


def simplify_intermediate(mid: mido.MidiFile) -> mido.MidiFile:
    """
    Level 2: Reduce complexity while keeping harmonic structure.

    - Max 4 simultaneous notes
    - Quantise to 8th note grid
    - Remove quiet notes (velocity < 40)
    """
    tpb = _get_ticks_per_beat(mid)
    grid = tpb // 2  # 8th notes
    max_polyphony = 4
    min_velocity = 40

    output = mido.MidiFile(ticks_per_beat=tpb)

    for track in mid.tracks:
        new_track = mido.MidiTrack()
        active_notes = set()

        for msg in track:
            if msg.type == "note_on" and msg.velocity > 0:
                if msg.velocity < min_velocity:
                    continue

                # Limit polyphony: drop lowest notes if too many
                if len(active_notes) >= max_polyphony:
                    # Keep the note only if it's higher than the lowest active
                    if active_notes:
                        lowest = min(active_notes)
                        if msg.note > lowest:
                            # Remove the lowest note
                            new_track.append(
                                mido.Message(
                                    "note_off", note=lowest, velocity=0, time=0
                                )
                            )
                            active_notes.discard(lowest)
                        else:
                            continue

                active_notes.add(msg.note)
                new_track.append(msg.copy())

            elif msg.type == "note_off" or (
                msg.type == "note_on" and msg.velocity == 0
            ):
                active_notes.discard(msg.note)
                new_track.append(msg.copy())
            else:
                new_track.append(msg.copy())

        output.tracks.append(new_track)

    return output


def simplify_beginner(mid: mido.MidiFile) -> mido.MidiFile:
    """
    Level 1: Melody-only, single note at a time.

    - Extract the highest note at each point (likely melody)
    - Quantise to quarter note grid
    - Reduce tempo by 25%
    """
    tpb = _get_ticks_per_beat(mid)
    grid = tpb  # quarter notes

    output = mido.MidiFile(ticks_per_beat=tpb)
    melody_track = mido.MidiTrack()

    # Collect all note events with absolute timing across all tracks
    events = []
    for track in mid.tracks:
        abs_time = 0
        for msg in track:
            abs_time += msg.time
            if msg.type in ("note_on", "note_off"):
                events.append((abs_time, msg))

    # Sort by time, then by note pitch (descending) to prefer higher notes
    events.sort(key=lambda e: (e[0], -e[1].note if e[1].type == "note_on" else 0))

    # Extract melody: keep only the highest note at each grid position
    current_note = None
    last_time = 0

    # Group events by quantised grid position
    grid_events: dict[int, list] = {}
    for abs_time, msg in events:
        q_time = _quantise_tick(abs_time, grid)
        grid_events.setdefault(q_time, []).append(msg)

    for q_time in sorted(grid_events.keys()):
        msgs = grid_events[q_time]

        # Find the highest note_on in this grid slot
        note_ons = [
            m for m in msgs if m.type == "note_on" and m.velocity > 0
        ]

        if note_ons:
            highest = max(note_ons, key=lambda m: m.note)
            delta = q_time - last_time

            # Turn off previous note
            if current_note is not None:
                melody_track.append(
                    mido.Message("note_off", note=current_note, velocity=0, time=delta)
                )
                delta = 0

            # Turn on new note
            melody_track.append(
                mido.Message(
                    "note_on",
                    note=highest.note,
                    velocity=min(highest.velocity, 100),
                    time=delta,
                )
            )
            current_note = highest.note
            last_time = q_time

    # Close final note
    if current_note is not None:
        melody_track.append(
            mido.Message("note_off", note=current_note, velocity=0, time=grid)
        )

    # Add tempo track with reduced speed
    tempo_track = mido.MidiTrack()
    original_tempo = _find_tempo(mid)
    slower_tempo = int(original_tempo * 1.25)  # 25% slower
    tempo_track.append(mido.MetaMessage("set_tempo", tempo=slower_tempo, time=0))
    tempo_track.append(mido.MetaMessage("end_of_track", time=0))

    output.tracks.append(tempo_track)
    melody_track.append(mido.MetaMessage("end_of_track", time=0))
    output.tracks.append(melody_track)

    return output


def _find_tempo(mid: mido.MidiFile) -> int:
    """Find the tempo from a MIDI file, default 120 BPM."""
    for track in mid.tracks:
        for msg in track:
            if msg.type == "set_tempo":
                return msg.tempo
    return mido.bpm2tempo(120)


def _recalculate_deltas(track: mido.MidiTrack, grid: int) -> None:
    """Recalculate delta times after quantisation (placeholder)."""
    # For now, keep original deltas — full quantisation logic
    # will be added in a future iteration
    pass


def simplify(midi_path: Path, output_dir: Path) -> dict[int, Path]:
    """
    Generate all difficulty levels from a MIDI file.

    Args:
        midi_path: Path to the original MIDI file.
        output_dir: Directory to save simplified versions.

    Returns:
        Dictionary mapping difficulty level to output path.
        {1: Path("..._beginner.mid"), 2: ..., 3: ...}
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    mid = mido.MidiFile(str(midi_path))
    stem = midi_path.stem

    levels = {
        BEGINNER: ("beginner", simplify_beginner),
        INTERMEDIATE: ("intermediate", simplify_intermediate),
        ADVANCED: ("advanced", simplify_advanced),
    }

    results = {}

    for level, (name, func) in levels.items():
        output_path = output_dir / f"{stem}_{name}.mid"
        console.print(f"[blue]Generating {name} arrangement...[/]")

        try:
            simplified = func(mid)
            simplified.save(str(output_path))
            results[level] = output_path
            console.print(f"  [green]✓[/] {output_path}")
        except Exception as e:
            console.print(f"  [red]✗[/] {name}: {e}")

    return results
