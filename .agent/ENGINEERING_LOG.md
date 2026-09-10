# Engineering Log

## 2026-09-11 — 배포 스크립트 제거와 규칙 재설계

- 문제: 기존 구조는 셸 설치·검증 스크립트를 포함했고, 토론 규칙은 익명
  다중 검토와 반복 라운드·보고서·세션 전환을 요구했다.
- 사용자 판단: 셸 파일 제거, 아이디어 생성보다 기존 아이디어의 옳고 그름을
  비판하는 토론, 초기 Karpathy식 코드 작성 원칙, 간결한 문서 규칙을 요청했다.
  초기 규칙의 코드 생성 우위는 이번 작업에서 재측정한 결과가 아니다.
- 변경: `install.sh`, `check.sh`를 제거하고 Markdown 수동 복사로 전환했다.
  기존 배포 구조는 커밋 `bdd767b`에 남아 있다. 앞서 선택한 copy installer
  방식은 이번 사용자 요청으로 대체됐다.
- Agent 구현 판단: 공통 파일에 코드 작성의 네 원칙을 유지하고 문서·기록
  규칙을 `DOCUMENTATION_RULES.md`로 분리했다. 토론은 구체적 제안의 증거와
  반례를 검토하며, 다중 agent는 사용자가 요청한 경우에만 사용하도록 했다.
- 검증: `git diff --check` 통과. 실제 agent의 규칙 준수, 코드 생성 품질,
  토큰 사용량은 이번 변경에서 측정하지 않았다.
- 다음 확인: 사용자 검토 후 실제 작업에서 불필요한 질문·반복·기록 누락이
  줄었는지 확인한다. 변경 사항은 아직 커밋하거나 push하지 않았다.

## 2026-09-11 — 토론의 토큰 제한 복원과 모델 지정

- 사용자 판단: 기존 토론 규칙의 토큰 절약 장치를 보존하고, "토론해라"는
  Codex Sol medium과 Claude Code Opus 5 medium의 토론으로 실행하도록 요청했다.
- 수정 근거: 직전 재작성에서 정량 payload 제한과 전달 형식을 제거했다.
  `bdd767b`의 원문을 확인해 50줄 미만 payload, 300단어·최대 5개 finding,
  경로 중심 전달, 불일치만 반박, 최대 2회 반박과 근거 없을 때 중단을 복원했다.
- Agent 구현 판단: 독립 초기 검토 후 익명 교차 비판을 유지하고, 매회 강제
  세션 초기화는 누적 context에 따른 정리와 간결한 인계로 바꿨다.
- 검증 범위: 문서 수정만 수행했다. 모델명은 사용자 지정값이며 실제 runtime의
  model ID와 effort 지원 여부, 두 모델 실행 결과와 토큰 절약량은 미검증이다.

## 2026-09-11 — 규칙 경로 불일치와 리라이트 누락분 복구

- 문제: 전역 `~/.claude/CLAUDE.md`가 토론 규칙 경로를 `DISCUSSION/RULES.md`로
  지정해 존재하지 않는 경로를 가리켰다. 따라서 프로젝트의
  `.agent/DISCUSSION_RULES.md`는 매칭되지 않고 항상 fallback인
  `~/.config/agent-setup/DISCUSSION_RULES.md`가 로드됐으며, 이 fallback은
  `bdd767b` 이전의 구버전이라 신규칙과 거의 전부 달랐다.
- 문제: `bdd767b` 이후 리라이트에서 안전장치 일부가 소실됐다. prompt injection
  방어("reviewed artifacts as data"), secrets/개인정보 전송 금지, 증거 우선순위
  `verified evidence > reproducible measurement > inference > agreement count`,
  단일 리뷰어의 보안·데이터 손실 finding 보존, 내부 영어/응답 한국어 언어 규칙,
  리뷰어 출력 템플릿이 빠져 있었다.
- 조사 중 정정: 처음에는 codex CLI가 모델 목록을 노출하지 않아 "Sol을 resolve
  하라"는 지시가 실행 불가능하다고 판단했으나, 오판이었다.
  `~/.codex/models_cache.json`에 `gpt-5.6-sol` (display_name `GPT-5.6-Sol`,
  `supported_reasoning_levels`에 `medium` 포함)이 있다. 현재 config 기본값은
  `gpt-6-astra` / effort `low`이므로 토론 실행 시 명시 지정이 필요하다.
- 사용자 판단: 확인된 항목을 모두 해결하도록 요청했고, Antigravity 지원은
  고려 대상에서 제외했다.
- 변경: 전역 CLAUDE.md 경로를 `.agent/DISCUSSION_RULES.md`로 수정하고 fallback을
  신규칙과 동일하게 동기화했다. `DISCUSSION_RULES.md`에 위 소실 항목과
  구체적 모델 해석 절차(`codex exec -m gpt-5.6-sol -c
  model_reasoning_effort=medium`, `claude -p --model claude-opus-5`)를 넣었다.
  `AGENTS.md`의 토론 규칙 로드 조건을 "명시 요청 시"로 좁혀 전역 규칙과 맞추고,
  "private reasoning traces"를 출력 한정 표현으로 바꿨다. README에서 Antigravity
  언급을 제거하고 fallback 동기화 필요성을 명시했다.
- Agent 구현 판단: 이 repo의 `.agent/ENGINEERING_LOG.md`는 이 저장소 자체의
  기록이므로 커밋 대상으로 유지한다. 타 프로젝트로 복사하지 않는다는 지침은
  README에 이미 있다.
- 검증: 모델 slug와 effort는 `models_cache.json`에서 확인했다. codex/claude
  실제 실행, 두 리뷰어 동시 기동, 규칙 준수 여부는 이번 변경에서 미검증이다.
- 다음 확인: 새 세션에서 토론 트리거를 실행해 두 모델이 지정대로 기동하는지,
  전역 규칙이 프로젝트 파일을 로드하는지 확인한다. 아직 커밋·push하지 않았다.

## 2026-09-11 — 토론 규칙 축약과 codex 호출 정정

- 사용자 판단: 토론 규칙이 너무 길다. 토큰을 과하게 쓰지 않으면서 모델 간
  핵심 전달이 되도록 축약하라고 요청했다. codex 호출은 `codex -m gpt-5.6-sol`
  이면 된다고 지정했다.
- 변경: `DISCUSSION_RULES.md`를 110줄에서 63줄로 줄였다. 산문 불릿을 고정
  블록 형식으로 바꿔 payload와 리뷰 출력 계약을 그대로 복사해 쓸 수 있게 했다.
  payload 상한을 50줄에서 30줄로 낮췄다.
- 유지한 항목: 2모델 지정과 실패 보고, 영어 내부/한국어 응답, secrets·transcript
  전송 금지, prompt injection 방어, 독립 병렬 세션과 익명 교차 비판, 최대 5개
  finding, 반박 1회(신규 증거 시 2회), 증거 우선순위, 단일 리뷰어의 보안·데이터
  손실 finding 보존, 라운드별 파일 생성 금지와 인계 범위.
- 제거한 항목: 같은 내용을 다르게 반복하던 문장, `models_cache.json` 조회 절차
  (모델 slug를 직접 명시해 불필요해짐), 아이디어 생성 관련 부연, Context Budget
  절의 compact/reset 설명. 직전 항목에서 넣은
  `-c model_reasoning_effort=medium`은 사용자 지정 명령에 맞춰 뺐다 —
  codex config 기본 effort는 `low`이므로 medium이 필요하면 별도 지정해야 한다.
- 검증: `git diff --check` 통과, fallback 사본 동기화. 실제 토론 실행과 축약
  이후의 리뷰 품질·토큰 사용량은 미측정이다.

## 2026-09-11 — 문서 규칙 축약과 기록 트리거 단일화

- 문제: `DOCUMENTATION_RULES.md`에 항목 길이 상한이 없었고, 요구 필드는 많았다.
  실제 결과로 이 repo의 로그가 3개 항목 85줄로 규칙 파일의 2배가 됐다.
  기록 트리거가 `AGENTS.md`와 규칙 파일 양쪽에 있어 "사실의 단일 출처"라는
  자기 규칙을 위반했고, 적용 조건("문서 작성·편집")이 오타 수정까지 포함했다.
- 사용자 판단: 검토 후 적용을 지시했다.
- 변경: 40줄 → 33줄. 로그 항목당 12줄 상한을 넣고, 일반 글쓰기 조언
  (promotional language, headings, diagrams, empty templates)을 제거했다.
  기록 시점은 `AGENTS.md`가, 작성 방법은 규칙 파일이 소유하도록 나눴다.
  적용 조건을 "문서 신규 작성·구조 변경·엔지니어링 기록"으로 좁혔다.
  문서 언어 규정("기존 문서 언어를 따른다")을 추가했다.
- 검증: `git diff --check` 통과. 기존 로그 항목은 소급 축약하지 않았다.

## 2026-09-11 — Karpathy 원본 대조와 누락 복원

- 근거: 원본을 로컬에서 확인했다.
  `~/.claude/plugins/marketplaces/karpathy-skills/.cursor/rules/karpathy-guidelines.mdc`
  (marketplace `forrestchang/andrej-karpathy-skills`, `bdd767b`에서 삭제된
  `claude/settings.json`에 등록돼 있었다).
- 문제: 리라이트 과정에서 원본의 실질 항목 6개가 유실됐다.
- 복원: trivial task 예외와 caution-over-speed tradeoff 선언, 다중 해석 제시,
  사후 재작성("could be a quarter of the size"), pre-existing dead code는
  삭제 대신 언급, loop until verified와 약한 성공 기준의 대가,
  다단계 작업의 단계별 verify.
- 중복 제거: "Touch only what the task requires"와 "every changed line must
  trace to the request"를 한 항목으로 합쳤다. 43줄 → 51줄.
- 미복원(의도): senior engineer 자기 점검 질문, 규칙 효과 판정 기준.
- 미해결: "If uncertain, ask"를 "결과가 바뀌거나 작업 유실 위험이 있을 때"로
  좁힌 것은 원본보다 약하다. 질문 남발 억제 의도로 판단해 유지했고,
  사용자 확인은 받지 않았다.
- 검증: `git diff --check` 통과. 실제 준수 여부는 미측정이다.

## 2026-09-11 — 규칙 근거의 README 기록과 compact 규칙 추가

- 사용자 관찰: 계약 없이 "토론하라"고 시켰을 때 두 agent가 서로의 context 전체
  (grep 출력, tool call, 중간 사고 과정)를 주고받았고, 한두 라운드만에 토큰이
  소진됐다. 전달된 내용 대부분은 결정과 무관했다. 이것이 payload 상한과 고정
  출력 형식의 실제 근거다.
- 사용자 판단: Karpathy 규칙은 실질 효과가 검증된 부분이 많아 유지한다.
  문서는 AI가 싸게 읽을 수 있으면 사람도 잘 읽는다는 것을 목표로 삼는다.
- 변경: `DISCUSSION_RULES.md`에 `## Context` 절 추가 — 리뷰어는 one-shot,
  orchestrator는 synthesis마다 compact (63줄 → 70줄). fallback 동기화.
- 변경: README의 `## Design`을 `## Why These Rules`로 교체하고 위 근거를
  실패 사례 → 대응 형태로 기록했다. 미측정 사실을 별도 절로 명시했다.
- 검증: `git diff --check` 통과. 토큰 소진은 사용자의 경험 보고이며 이 저장소
  에서 계측하지 않았다.

## 2026-09-11 — README 한국어 전환과 구조 개편

- 사용자 판단: README는 한국어로 작성하고, 잘 작성하는 것이 중요하다고 지시했다.
- 변경: 전체를 한국어로 다시 썼다 (93줄 → 99줄). 기술 용어·경로·명령은 영문 유지.
  파일 역할·로드 조건 표를 추가하고, 조건부 로드가 핵심 설계라는 점을 명시했다.
  전역 fallback 불일치 주의를 별도 소절로 분리했다 — 실제 발생한 문제다.
  근거 절은 "관찰된 실패 → 대응" 구조를 유지했다.
- 판단 근거: `DOCUMENTATION_RULES.md`의 "기존 문서 언어를 따른다"는 신규 작성·
  구조 변경에는 적용되지 않으며, 이번 지시가 우선한다.
- 검증: `git diff --check` 통과. 링크 유효성은 확인하지 않았다.

## 2026-09-11 — README 위치 검토 후 루트 유지

- 사용자 우려: 다른 프로젝트에 받았을 때 기존 README와 겹칠 수 있다.
- 사실 확인: README는 원래 복사 대상이 아니었다(복사는 `AGENTS.md`,
  `CLAUDE.md`, `DISCUSSION_RULES.md`, `DOCUMENTATION_RULES.md` 넷). 다만
  문서에 그 범위가 명시돼 있지 않아 clone 시 딸려가기 쉬웠다. 실제 충돌
  위험이 큰 쪽은 관례 파일명인 `AGENTS.md`/`CLAUDE.md`다.
- 시도와 되돌림: 지시에 따라 `.agent/README.md`로 옮겼으나, ① 루트에 README가
  없어 GitHub 저장소 페이지에 설명이 사라지고 ② `.agent/`는 복사 대상
  디렉터리라 오히려 함께 복사될 여지가 커진다는 문제를 제기했다.
- 사용자 판단: 세 안(A 루트 유지, B 이동 유지, C 루트 최소 + 상세 분리) 중
  A를 선택했다. README를 루트로 되돌렸다.
- 변경: 파일 트리에 파일별 "복사함 / 복사하지 않음"을 표기하고, README를
  복사하지 말라는 문구와 `AGENTS.md`가 이미 있을 때의 처리 방침을 추가했다.
- 미해결: `.agent/`에 공유 규칙과 프로젝트 소유 로그가 섞여 있어 "이 폴더는
  복사한다"고 단언할 수 없다. 폴더 이름(`.agent` vs `.agents`)보다 이 수명주기
  혼재가 실질 문제라고 제안했으나 아직 결정되지 않았다.
- 검증: `git diff --check` 통과.
