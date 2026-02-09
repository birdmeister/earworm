"""Tests for the difficulty simplification and analysis modules.

These tests use programmatically generated MIDI files,
so they don't require any external audio or ML models.
"""

import tempfile
from pathlib import Path

import mido
import pytest

from earworm.difficulty.simplify import (
    BEGINNER,
    INTERMEDIATE,
    ADVANCED,
    simplify,
    simplify_beginner,
    simplify_intermediate,
    simplify_advanced,
)
from earworm.difficulty.analyse import analyse, DifficultyReport


def _make_test_midi(
    notes: list[tuple[int, int, int]],
    ticks_per_beat: int = 480,
    tempo_bpm: int = 120,
) -> mido.MidiFile:
    """
    Create a simple test MIDI file.

    Args:
        notes: List of (pitch, velocity, duration_ticks) tuples.
        ticks_per_beat: MIDI resolution.
        tempo_bpm: Tempo in BPM.

    Returns:
        A mido.MidiFile object.
    """
    mid = mido.MidiFile(ticks_per_beat=ticks_per_beat)

    # Tempo track
    tempo_track = mido.MidiTrack()
    tempo_track.append(
        mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(tempo_bpm), time=0)
    )
    tempo_track.append(mido.MetaMessage("end_of_track", time=0))
    mid.tracks.append(tempo_track)

    # Note track
    track = mido.MidiTrack()
    for pitch, velocity, duration in notes:
        track.append(mido.Message("note_on", note=pitch, velocity=velocity, time=0))
        track.append(mido.Message("note_off", note=pitch, velocity=0, time=duration))
    track.append(mido.MetaMessage("end_of_track", time=0))
    mid.tracks.append(track)

    return mid


def _save_and_load(mid: mido.MidiFile) -> Path:
    """Save a MIDI file to a temp path and return the path."""
    tmp = tempfile.NamedTemporaryFile(suffix=".mid", delete=False)
    mid.save(tmp.name)
    return Path(tmp.name)


class TestSimplifyBeginner:
    """Test beginner-level simplification."""

    def test_reduces_to_single_notes(self):
        """Beginner mode should produce a monophonic melody."""
        # Create a chord (3 simultaneous notes)
        mid = mido.MidiFile(ticks_per_beat=480)
        track = mido.MidiTrack()
        # C major chord: C4, E4, G4 simultaneously
        track.append(mido.Message("note_on", note=60, velocity=80, time=0))
        track.append(mido.Message("note_on", note=64, velocity=80, time=0))
        track.append(mido.Message("note_on", note=67, velocity=80, time=0))
        track.append(mido.Message("note_off", note=60, velocity=0, time=480))
        track.append(mido.Message("note_off", note=64, velocity=0, time=0))
        track.append(mido.Message("note_off", note=67, velocity=0, time=0))
        track.append(mido.MetaMessage("end_of_track", time=0))
        mid.tracks.append(track)

        result = simplify_beginner(mid)

        # Count simultaneous note_ons (should be max 1 at any point)
        active = 0
        max_active = 0
        for track in result.tracks:
            for msg in track:
                if msg.type == "note_on" and msg.velocity > 0:
                    active += 1
                elif msg.type == "note_off" or (
                    msg.type == "note_on" and msg.velocity == 0
                ):
                    active = max(0, active - 1)
                max_active = max(max_active, active)

        assert max_active <= 1, "Beginner mode should be monophonic"


class TestSimplifyIntermediate:
    """Test intermediate-level simplification."""

    def test_limits_polyphony(self):
        """Intermediate mode should limit simultaneous notes to 4."""
        mid = mido.MidiFile(ticks_per_beat=480)
        track = mido.MidiTrack()
        # 6 simultaneous notes
        for note in [48, 52, 55, 60, 64, 67]:
            track.append(mido.Message("note_on", note=note, velocity=80, time=0))
        for note in [48, 52, 55, 60, 64, 67]:
            track.append(mido.Message("note_off", note=note, velocity=0, time=480 if note == 48 else 0))
        track.append(mido.MetaMessage("end_of_track", time=0))
        mid.tracks.append(track)

        result = simplify_intermediate(mid)

        # Count max simultaneous notes
        active = set()
        max_active = 0
        for track in result.tracks:
            for msg in track:
                if msg.type == "note_on" and msg.velocity > 0:
                    active.add(msg.note)
                elif msg.type == "note_off" or (
                    msg.type == "note_on" and msg.velocity == 0
                ):
                    active.discard(msg.note)
                max_active = max(max_active, len(active))

        assert max_active <= 4, f"Expected max 4 simultaneous notes, got {max_active}"

    def test_filters_quiet_notes(self):
        """Intermediate mode should remove very quiet notes."""
        notes = [
            (60, 80, 480),   # normal velocity — keep
            (64, 20, 480),   # very quiet — should be removed
            (67, 90, 480),   # normal velocity — keep
        ]
        mid = _make_test_midi(notes)
        result = simplify_intermediate(mid)

        output_notes = []
        for track in result.tracks:
            for msg in track:
                if msg.type == "note_on" and msg.velocity > 0:
                    output_notes.append(msg.note)

        assert 64 not in output_notes, "Quiet note (velocity 20) should be filtered"


class TestAnalyse:
    """Test difficulty analysis."""

    def test_simple_melody_is_easy(self):
        """A simple single-note melody should be rated as easy."""
        notes = [(60, 80, 480), (62, 80, 480), (64, 80, 480), (65, 80, 480)]
        mid = _make_test_midi(notes, tempo_bpm=100)
        path = _save_and_load(mid)

        report = analyse(path)

        assert report.level <= 3, f"Simple melody should be easy, got level {report.level}"
        assert report.total_notes == 4
        assert report.avg_polyphony <= 1.5

    def test_empty_midi(self):
        """An empty MIDI file should return level 1."""
        mid = mido.MidiFile(ticks_per_beat=480)
        track = mido.MidiTrack()
        track.append(mido.MetaMessage("end_of_track", time=0))
        mid.tracks.append(track)
        path = _save_and_load(mid)

        report = analyse(path)

        assert report.level == 1
        assert report.total_notes == 0

    def test_report_str(self):
        """DifficultyReport should have a readable string representation."""
        report = DifficultyReport(
            level=5,
            label="intermediate",
            notes_per_second=4.2,
            avg_polyphony=2.1,
            pitch_range=36,
            max_hand_span=12,
            total_notes=200,
            duration_seconds=47.5,
        )
        text = str(report)
        assert "intermediate" in text
        assert "4.2" in text


class TestSimplifyPipeline:
    """Test the full simplify pipeline."""

    def test_produces_three_levels(self):
        """simplify() should produce files for all three levels."""
        notes = [
            (60, 80, 240), (64, 75, 240), (67, 85, 240),
            (72, 90, 240), (60, 70, 480),
        ]
        mid = _make_test_midi(notes)
        path = _save_and_load(mid)

        with tempfile.TemporaryDirectory() as tmpdir:
            results = simplify(path, Path(tmpdir))

            assert BEGINNER in results
            assert INTERMEDIATE in results
            assert ADVANCED in results

            # All output files should exist and be valid MIDI
            for level, output_path in results.items():
                assert output_path.exists(), f"Level {level} file missing"
                loaded = mido.MidiFile(str(output_path))
                assert len(loaded.tracks) > 0, f"Level {level} has no tracks"
