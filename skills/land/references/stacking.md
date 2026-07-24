# Stacking & rebase 복구

discover 단계가 **stacked PR**(base 가 다른 열린 PR 의 head 인 PR)을 찾거나
살아남은 브랜치 rebase 가 **conflict** 를 만났을 때 이 파일을 로드하라. 전부
독립 PR 이면 이 중 어느 것도 필요 없다.

## stack 감지

`gh pr list ... --json number,headRefName,baseRefName` 후 `base → head` 엣지를
만든다. 어떤 PR 의 `baseRefName` 이 다른 열린 PR 의 `headRefName` 이면 그 위에
stacked 된 것이다. 체인은 둘보다 길 수 있다 (A ← B ← C). 기본 브랜치를 base 로
하는 PR 이 먼저 머지되도록 topological sort 하라.

예:
```
#43 head=rate-limit-mw  base=master        ← stack bottom (base is default)
#44 head=rate-limit-ui  base=rate-limit-mw ← sits on #43
```
머지 순서: #43, 그 다음 #44.

## 숨은 stack 감지 (둘 다 base=default)

`baseRefName` 만으로는 못 잡는 위험한 케이스가 있다 — 실제로는 stacked 인 두
브랜치를 **둘 다 base=default 로** 올린 경우다(실측 #430/#431). base 엣지로는
독립 2건처럼 보이지만, 부모를 squash 머지하면 GitHub 이 자식을 **CLOSED**(머지
아님) 처리해 작업이 소실된다.

그래서 base 가 default 인 PR 이 2건 이상이면 **커밋 포함 관계**를 추가로 검사한다:

```
git merge-base --is-ancestor <headA> <headB>   # exit 0 → A 가 B 의 조상
# 또는
git rev-list --count <headB>..<headA>          # 0 → A 의 커밋이 전부 B 에 포함
```

A 가 B 의 조상이면(A ⊂ B) A 가 부모, B 가 자식인 **숨은 stack** 이다. 이때는 위
`re-pointing 동작` 그대로 처리한다 — 부모(A)를 먼저 머지하고, 자식(B)의 base 를
default 로 re-point 한 뒤 머지한다. 최소한 Confirm 플랜에 `⚠ 숨은 stack: #A ⊂ #B`
경고를 박아 부모 단독 머지가 자식을 닫지 않게 한다.

## re-pointing 동작

GitHub 은 부모 PR 이 머지될 때 자식 PR 의 base 를 자동으로 옮기지 **않는다**.
#43 을 기본 브랜치로 squash 한 다음 #44 를 그대로 머지하려 하면, #44 의 diff 가
이제 삭제된 `rate-limit-mw` 브랜치에 대해 계산된다 — 틀리거나 깨진다.

그러므로 stack 레벨마다, 아래에서 위로:

1. 맨 아래 PR 을 머지: `gh pr merge 43 --squash --auto --delete-branch`. `MERGED` 까지 대기.
2. 자식을 기본 브랜치로 다시 가리킴: `gh pr edit 44 --base <default>`.
   GitHub 이 #44 의 diff 를 default 에 대해 재계산한다; #43 의 변경이 이제
   default 에 있으므로 #44 는 자기 delta 만 보여준다.
3. #44 의 머지 가능성과 CI 재확인 — re-pointing 은 체크를 다시 트리거할 수 있고,
   부모 위에 있는 동안 숨겨졌던 conflict 를 드러낼 수 있다. green 까지 대기.
4. #44 머지. #44 위에 stacked 된 PR 이 있으면 반복.

3 단계가 conflict 를 보이면(자식이 새 base 위에 깨끗이 적용되지 않으면) 이
레벨에서 stack 을 중단하고 보고하라 — 유저(또는 요청 시 당신)가 자식 브랜치를
업데이트해야 한다. force-merge 하지 말 것.

## Squash vs stack

Squash 머지가 프로젝트 기본이고 stack 에도 괜찮다 — **레벨 사이에 re-point 하는
한**(위 참조). 한 가지 함정: squash 후 자식의 커밋들은 default 의 단일 squash
커밋과 달라 보여서, 자식의 *로컬* 브랜치를 default 위로 평범하게 `git rebase`
하면 이미 머지된 변경을 conflict 로 재생할 수 있다. stacked 자식을 부모가
머지되기 전에 로컬에서 rebase 하기보다 PR base 를 re-point 하는 것을
선호하라(GitHub 이 diff 를 처리한다).

## 살아남은 것 rebase conflict (5.4 단계)

랜딩되지 **않은** 로컬 브랜치에 대해 `git rebase <default>` 가 최신으로
끌어올린다. conflict 시:

- `git rebase <default>` 가 conflict 난 경로와 함께 멈추고 브랜치는 rebase
  중간에 남는다 (`.git/rebase-merge` 존재, `git status` 가 "rebase in progress" 표시).
- **거기 그대로 두라.** 보고: 어떤 브랜치인지, 어떤 파일이 conflict 인지
  (`git diff --name-only --diff-filter=U`), 그리고 rebase 중간에 멈춰 있다는 것.
- 유저 요청 없이 `git rebase --abort`(부분 진척을 버림) 또는 `--skip`(커밋을
  조용히 떨굼) 하지 말 것 — 둘 다 작업을 잃을 수 있다.
- 유저가 해결하고 `git rebase --continue` 하거나 당신에게 요청할 수 있다. 빠져나가고
  싶으면 `git rebase --abort` 가 브랜치를 rebase 이전 상태로 안전하게 되돌린다.

살아남은 게 여럿이면 독립적으로 rebase 하라; conflict 난 브랜치 하나가 나머지
rebase 를 막아선 안 된다. 각각 따로 보고하라.

## Dirty 워크트리 가드

워크트리에 체크아웃된 브랜치를 rebase 하기 전에, 그 워크트리가 깨끗한지
확인하라 (`git -C <path> status --porcelain` 이 비어 있음). dirty 면 커밋되지
않은 로컬 작업을 의미한다 — 그 브랜치는 rebase 하지 말고 보고하라. (워크트리
제거 자체는 land 의 일이 아니다 — `wt-sweep` 참조.)
