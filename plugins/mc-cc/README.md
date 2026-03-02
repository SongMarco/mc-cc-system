# mc-cc

Claude Code development workflow skills - commit, PR, review, DB, deployment, plugin creation, and more.

## Installation

### From marketplace

```bash
/plugin marketplace add <marketplace-source>
/plugin install mc-cc@<marketplace-name>
```

### Local testing

```bash
claude --plugin-dir ./plugins/mc-cc
```

## Components

- **Skills** (17): commit, db-run, feedback-pr, find-aws-logs, hook-creator, pluginize, pr, push, push-n-pr, retro, review-plan, review-pr, skill-creator, slash-command-creator, subagent-creator, ticket-destroyer, youtube-collector
- **Agents** (2): brand-logo-finder, dev-responder
- **Commands** (2): db-query, figma-spec

## Usage

After installation, all skills are available as slash commands with the `mc-cc:` namespace prefix:

```
/mc-cc:commit
/mc-cc:pr
/mc-cc:review-pr
```

## License

MIT
