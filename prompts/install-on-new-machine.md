# 새 머신 설치 프롬프트

새 머신에서 mc-cc-system을 체크아웃한 직후 Claude Code에 **아래 code block 전체를 복사해서 붙여넣으면** 됩니다.
Claude Code가 이 레포의 스킬을 인식해 필요한 파일을 `~/.claude/`에 복사·설정합니다.

---

````text
방금 mc-cc-system 레포를 체크아웃했어. 이 레포는 현재 작업 디렉터리(CWD)로 열려 있다고 가정해.
아래 항목을 순서대로 처리해줘.

## 1. Claude Code statusline 세팅 (setup-statusline 스킬)

이 레포의 `.claude/skills/setup-statusline/SKILL.md` 절차를 그대로 따라:

1) `.claude/skills/setup-statusline/statusline-command.sh`를 `~/.claude/statusline-command.sh`로 복사하고 실행권한 부여
2) `~/.claude/settings.json`의 `statusLine` 키를 다음으로 설정(없으면 빈 `{}`로 생성 후 추가):
   ```json
   { "type": "command", "command": "bash <HOME>/.claude/statusline-command.sh" }
````

(jq로 `$ENV.HOME`을 주입해 절대경로로 저장) 3) 샘플 JSON을 스크립트에 파이프해서 ANSI 이스케이프(`\033[...m`)가 포함된 한 줄 출력이 나오는지 확인 4) 완료 후 Claude Code 재시작 또는 `/reload-plugins` 실행 안내

## 2. 프로젝트 로컬 스킬 자동 로드 확인

이 레포의 `.claude/skills/*`는 CWD가 mc-cc-system일 때 Claude Code가 자동 인식해. 별도 설치 불필요.
전역(`~/.claude/skills/`)으로도 쓰고 싶은 스킬이 있으면 나한테 이름을 알려주면 심링크/복사해줄게.

## 3. 검증 보고

- statusline-command.sh 경로·권한
- settings.json의 statusLine 값
- 드라이런 한 줄 출력
- 현재 인식되는 이 레포의 스킬 개수(대략이라도)

위 네 가지를 짧게 보고하고 끝.

```

---

## 참고

- `setup-statusline` 스킬 절차 원본: `.claude/skills/setup-statusline/SKILL.md`
- statusline 스크립트: `.claude/skills/setup-statusline/statusline-command.sh`
- 커스터마이즈 포인트(색/임계치/길이)는 SKILL.md의 "커스터마이즈 포인트" 섹션 참고.
```
