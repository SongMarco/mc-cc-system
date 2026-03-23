
# Kiro CLI shell hook disabled to avoid completion conflicts.
# [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# zsh completion stack
if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi

source "${HOME}/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

autoload -Uz compinit
compinit

source "${HOME}/.zsh/fzf-tab/fzf-tab.plugin.zsh"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'



# Worktree aliases
alias w1='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt1 && claude --dangerously-skip-permissions'
alias w2='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt2 && claude --dangerously-skip-permissions'
alias w3='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt3 && claude --dangerously-skip-permissions'
alias w4='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt4 && claude --dangerously-skip-permissions'
alias w5='cd /Users/youngchansong/Documents/projects/korea-monitor && claude --dangerously-skip-permissions'
alias c1='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt1 && codex --dangerously-bypass-approvals-and-sandbox'
alias c2='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt2 && codex --dangerously-bypass-approvals-and-sandbox'
alias c3='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt3 && codex --dangerously-bypass-approvals-and-sandbox'
alias c4='cd /Users/youngchansong/Documents/projects/friendly-pharmacist-platform.worktrees/wt4 && codex --dangerously-bypass-approvals-and-sandbox'
alias c5='cd /Users/youngchansong/Documents/projects/korea-monitor && codex --dangerously-bypass-approvals-and-sandbox'
alias jfc='cd /Users/youngchansong/Documents/projects/job-finder && claude --dangerously-skip-permissions'
alias jfx='cd /Users/youngchansong/Documents/projects/job-finder && codex --dangerously-bypass-approvals-and-sandbox'
alias pf='cd /Users/youngchansong/Documents/projects/pharma_bros_fe && claude --dangerously-skip-permissions'
alias sz='source ~/.zshrc'


export PATH="$PATH:/Applications/IntelliJ IDEA.app/Contents/MacOS"

# tmux 세션 관리
tmux-start() {
  tmuxinator start company
  tmuxinator start personal
}

tmux-stop() {
  tmuxinator stop company
  tmuxinator stop personal
}


# Kiro CLI shell hook disabled to avoid completion conflicts.
# [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$(npm bin -g):$PATH"
