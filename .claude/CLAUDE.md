# Example Project CLAUDE.md

This is an example project-level CLAUDE.md file. Place this in your project root.

## Project Overview

[Brief description of your project - what it does, tech stack]

## Critical Rules

### 1. Code Organization

- Many small files over few large files
- High cohesion, low coupling
- 200-400 lines typical, 800 max per file
- Organize by feature/domain, not by type

### 2. Code Style

- No emojis in code, comments, or documentation
- Immutability always - never mutate objects or arrays
- No console.log in production code
- Proper error handling with try/catch
- Input validation with Zod or similar

### 3. Testing

- TDD: Write tests first
- 80% minimum coverage
- Unit tests for utilities
- Integration tests for APIs
- E2E tests for critical flows

### 4. Security

- No hardcoded secrets
- Environment variables for sensitive data
- Validate all user inputs
- Parameterized queries only
- CSRF protection enabled

## File Structure

```
src/
|-- app/              # Next.js app router
|-- components/       # Reusable UI components
|-- hooks/            # Custom React hooks
|-- lib/              # Utility libraries
|-- types/            # TypeScript definitions
```

## Key Patterns

### API Response Format

```typescript
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
```

### Error Handling

```typescript
try {
  const result = await operation();
  return { success: true, data: result };
} catch (error) {
  console.error("Operation failed:", error);
  return { success: false, error: "User-friendly message" };
}
```

## Environment Variables

```bash
# Required
DATABASE_URL=
API_KEY=

# Optional
DEBUG=false
```

## Available Commands

| 커맨드                          | 설명                                     | 위치    |
| ------------------------------- | ---------------------------------------- | ------- |
| `/commit`                       | conventional commit 기반 한국어 커밋     | skill   |
| `/pr [base]`                    | PR 생성                                  | skill   |
| `/push`                         | 스모크 테스트 후 푸시                    | skill   |
| `/push-n-pr [base]`             | 푸시 + PR 생성 일괄 수행                 | skill   |
| `/review-pr`                    | PR 리뷰                                  | skill   |
| `/feedback-pr`                  | PR 인라인 코멘트 피드백                  | skill   |
| `/db-run`                       | 개발 DB SQL 쿼리 실행                    | skill   |
| `/skill-creator`                | 새로운 skill 생성/검증                   | skill   |
| `/review-plan`                  | 구현 계획을 staff engineer 관점에서 리뷰 | skill   |
| `/ticket-destroyer [plan\|fix]` | 이슈 분석, plan 시 계획, fix 시 수정+PR  | skill   |
| `/find-aws-logs`                | ECS CloudWatch 로그 검색                 | skill   |
| `/hook-creator`                 | Claude Code hook 생성                    | skill   |
| `/slash-command-creator`        | 슬래시 커맨드 생성                       | skill   |
| `/subagent-creator`             | 서브에이전트 생성                        | skill   |
| `/youtube-collector`            | YouTube 채널 영상 수집                   | skill   |
| `/db-query`                     | SQL 쿼리 파일 생성                       | command |
| `/figma-spec`                   | Figma 디자인 -> 백엔드 명세서            | command |

## Git Workflow

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Never commit to main directly
- PRs require review
- All tests must pass before merge
