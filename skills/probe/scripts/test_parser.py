#!/usr/bin/env python3
"""Parser unit tests for real_env_probe — fixture-based, no claude calls.

Pins the B1/B6 extraction contract against saved raw stream-json fixtures so
the parser can't silently regress into a false 0/100 if the CLI schema drifts.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from real_env_probe import extract_triggered_skills, classify_state, normalize_skill

FIX = Path(__file__).parent.parent / "references" / "fixtures"


def load(name):
    return FIX.joinpath(name).read_text().splitlines()


def test_trigger_real_fixture():
    # Real captured stream: query triggers deep-interview (Skill + Reads of its refs).
    triggered, unknown, parse_error = extract_triggered_skills(load("trigger_deep-interview.jsonl"))
    assert not parse_error, "real fixture must parse cleanly"
    assert "deep-interview" in triggered, triggered
    assert all(s == "deep-interview" for s in triggered), f"no sibling expected: {triggered}"
    assert classify_state(triggered, "deep-interview") == "target_only"


def test_zero_trigger():
    triggered, unknown, parse_error = extract_triggered_skills(load("zero_trigger.jsonl"))
    assert triggered == [], triggered
    assert classify_state(triggered, "deep-interview") == "none"


def test_sibling_hijack():
    triggered, unknown, parse_error = extract_triggered_skills(load("multi_sibling.jsonl"))
    assert set(triggered) == {"forge", "hunt"}, triggered
    assert classify_state(triggered, "deep-interview") == "sibling_only"


def test_classify_target_plus_sibling():
    assert classify_state(["deep-interview", "forge"], "deep-interview") == "target_plus_sibling"


def test_normalize_skill():
    assert normalize_skill("/Users/x/.claude/skills/hunt/SKILL.md") == "hunt"
    assert normalize_skill("/a/b/skills/probe/references/m.md") == "probe"
    assert normalize_skill("/etc/passwd") is None
    assert normalize_skill("") is None


def test_parse_error_flag():
    triggered, unknown, parse_error = extract_triggered_skills(['{"type":"assistant"', "not json"])
    assert parse_error is True


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"PASS {t.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL {t.__name__}: {e}")
        except Exception as e:
            failed += 1
            print(f"ERROR {t.__name__}: {type(e).__name__}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    sys.exit(1 if failed else 0)
