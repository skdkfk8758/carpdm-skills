#!/usr/bin/env python3
"""Smallest check that fails if validate_issue_body.py stops enforcing its contract.

Run: python3 skills/linear-register/scripts/test_validate_issue_body.py
"""

from __future__ import annotations

import unittest

from validate_issue_body import validate

FEATURE_OK = """## 목적
x

## 작업 내용
- a

## 완료 조건
- [ ] GET /api/x 가 200 + 빈 배열을 반환한다
- [ ] 권한 없는 사용자는 403
"""


class ValidateIssueBody(unittest.TestCase):
    def test_valid_feature_passes(self) -> None:
        self.assertEqual(validate(FEATURE_OK, "feature", 1600), [])

    def test_missing_required_heading(self) -> None:
        body = FEATURE_OK.replace("## 작업 내용\n- a\n\n", "")
        self.assertTrue(any("missing required" in e for e in validate(body, "feature", 1600)))

    def test_subjective_completion_rejected(self) -> None:
        body = FEATURE_OK.replace("권한 없는 사용자는 403", "에러가 잘 처리된다")
        self.assertTrue(any("judgeable" in e for e in validate(body, "feature", 1600)))

    def test_forbidden_section_rejected(self) -> None:
        body = FEATURE_OK + "\n## 추천\n- /forge\n"
        errors = validate(body, "feature", 1600)
        self.assertTrue(any("recommended section" in e for e in errors))

    def test_checkbox_count_bounds(self) -> None:
        body = FEATURE_OK.replace("- [ ] 권한 없는 사용자는 403\n", "")
        self.assertTrue(any("2 to 6" in e for e in validate(body, "feature", 1600)))


if __name__ == "__main__":
    unittest.main()
