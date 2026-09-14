# council-review 호출 (스텝 검증)

> 스텝 구현을 끝내고 검증 3종이 green 인 뒤에 쓴다. 리뷰는 편집을 하지 않는다.

---

`/council-review <REVIEW-TARGET>`

`<REVIEW-TARGET>` 은 셋 중 하나 — 비우면 trunk 대비 현재 브랜치 전체:

- (비움) — `git merge-base HEAD origin/<TRUNK>`...HEAD
- 브랜치명 · PR 번호/URL · 커밋 범위 `A...B`

운영·배포·gitops·공개 API 를 건드렸으면 `--with hightower,abramov` 를 붙인다.

## 결과 처리

1. **합의 지적**(2인 이상)은 고친다. 고친 뒤 검증 명령을 다시 돌린다.
2. **불일치 지적**(1인)은 채택 여부를 결정하고, 버렸으면 버린 이유를 남긴다.
3. 판정과 처리 결과를 `<ADR-PATH>` 의 `## Verification` 절에 적는다:

   ```
   - 리뷰: /council-review <REVIEW-TARGET> → 판정 <머지 가능|수정 필요>
     - 합의: <지적> → <고친 커밋 hash 또는 대응>
     - 불일치(<렌즈>): <지적> → <채택|보류 + 이유>
   ```

4. `수정 필요` 판정이면 머지·배포로 넘어가지 않는다. 수정은 **다음 스텝**으로 끊는다.
