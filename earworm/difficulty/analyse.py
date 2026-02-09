"""Estimate the difficulty level of a MIDI piano arrangement.

Uses heuristics based on musical complexity metrics.
Future versions will integrate the CIPI difficulty prediction model.

Metrics considered:
    - Note density (notes per second)
    - Polyphony (average simultaneous notes)
    - Pitch range (span in semitones)
    - Rhythmic complexity (variety of note durations)
    - Hand span required (max interval in simultaneous notes)
"""

from dataclasses import dataclass
from pathlib import Path

import mido


@dataclass
class DifficultyReport:
    """Summary of a MIDI file's difficulty characteristics."""

    level: int  # 1 (beginner) to 10 (concert)
    label: str  # Human-readable label
    notes_per_second: float
    avg_polyphony: float
    pitch_range: int  # in semitones
    max_hand_span: int  # in semitones
    total_notes: int
    duration_seconds: float

    def __str__(self) -> str:
        return (
            f"Difficulty: {self.label} (level {self.level}/10)\n"
            f"  Notes/sec:      {self.notes_per_second:.1f}\n"
            f"  Avg polyphony:  {self.avg_polyphony:.1f}\n"
            f"  Pitch range:    {self.pitch_range} semitones\n"
            f"  Max hand span:  {self.max_hand_span} semitones\n"
            f"  Total notes:    {self.total_notes}\n"
            f"  Duration:       {self.duration_seconds:.1f}s"
        )


LEVEL_LABELS = {
    1: "beginner",
    2: "beginner+",
    3: "easy",
    4: "easy+",
    5: "intermediate",
    6: "intermediate+",
    7: "advanced",
    8: "advanced+",
    9: "expert",
    10: "concert",
}


def analyse(midi_path: Path) -> DifficultyReport:
    """
    Analyse a MIDI file and estimate its difficulty level.

    Args:
        midi_path: Path to a MIDI file.

    Returns:
        DifficultyReport with metrics and estimated level.
    """
    mid = mido.MidiFile(str(midi_path))
    duration = mid.length  # seconds

    # Collect all note-on events
    note_events = []
    for track in mid.tracks:
        abs_time = 0
        for msg in track:
            abs_time += msg.time
            if msg.type == "note_on" and msg.velocity > 0:
                note_events.append((abs_time, msg.note))

    if not note_events or duration == 0:
        return DifficultyReport(
            level=1,
            label="beginner",
            notes_per_second=0,
            avg_polyphony=0,
            pitch_range=0,
            max_hand_span=0,
            total_notes=0,
            duration_seconds=duration,
        )

    total_notes = len(note_events)
    notes_per_second = total_notes / max(duration, 0.1)

    # Pitch range
    pitches = [n[1] for n in note_events]
    pitch_range = max(pitches) - min(pitches)

    # Polyphony: group notes by time bucket (50ms window)
    tpb = mid.ticks_per_beat
    window = tpb // 8  # ~50ms at 120bpm
    buckets: dict[int, list[int]] = {}
    for t, note in note_events:
        bucket = int(t // window)
        buckets.setdefault(bucket, []).append(note)

    polyphonies = [len(notes) for notes in buckets.values()]
    avg_polyphony = sum(polyphonies) / len(polyphonies) if polyphonies else 0

    # Max hand span (max interval in simultaneous notes)
    max_span = 0
    for notes in buckets.values():
        if len(notes) > 1:
            span = max(notes) - min(notes)
            max_span = max(max_span, span)

    # Estimate difficulty level (1-10)
    level = _estimate_level(notes_per_second, avg_polyphony, pitch_range, max_span)

    return DifficultyReport(
        level=level,
        label=LEVEL_LABELS.get(level, "unknown"),
        notes_per_second=notes_per_second,
        avg_polyphony=avg_polyphony,
        pitch_range=pitch_range,
        max_hand_span=max_span,
        total_notes=total_notes,
        duration_seconds=duration,
    )


def _estimate_level(
    nps: float,
    polyphony: float,
    pitch_range: int,
    hand_span: int,
) -> int:
    """
    Estimate difficulty level based on musical metrics.

    This is a rough heuristic. The boundaries are based on
    analysis of graded piano repertoire (approximate values).
    """
    score = 0

    # Notes per second scoring
    if nps < 2:
        score += 1
    elif nps < 4:
        score += 3
    elif nps < 7:
        score += 5
    elif nps < 10:
        score += 7
    else:
        score += 9

    # Polyphony scoring
    if polyphony < 1.5:
        score += 1
    elif polyphony < 2.5:
        score += 3
    elif polyphony < 4:
        score += 5
    else:
        score += 8

    # Pitch range scoring
    if pitch_range < 24:  # 2 octaves
        score += 1
    elif pitch_range < 36:  # 3 octaves
        score += 3
    elif pitch_range < 48:  # 4 octaves
        score += 5
    else:
        score += 7

    # Hand span scoring
    if hand_span < 8:  # less than octave
        score += 1
    elif hand_span < 12:
        score += 3
    elif hand_span < 15:
        score += 5
    else:
        score += 7

    # Average and clamp to 1-10
    level = round(score / 4)
    return max(1, min(10, level))
