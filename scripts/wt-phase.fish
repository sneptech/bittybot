#!/usr/bin/env fish
#
# Create a git worktree for parallel phase execution.
#
# Usage:
#   fish scripts/wt-phase.fish <phase-number> <phase-slug>
#
# Example:
#   fish scripts/wt-phase.fish 02 model-distribution
#
# Creates:
#   Branch:    phase/02-model-distribution (from current HEAD)
#   Directory: ../bittybot-phase-02/

set -l phase_num $argv[1]
set -l phase_slug $argv[2]

if test (count $argv) -lt 2
    echo "Usage: fish scripts/wt-phase.fish <phase-number> <phase-slug>"
    echo "Example: fish scripts/wt-phase.fish 02 model-distribution"
    exit 1
end

# Derive names
set -l branch "phase/$phase_num-$phase_slug"
set -l repo_root (git rev-parse --show-toplevel)
set -l repo_name (basename $repo_root)
set -l worktree_dir (dirname $repo_root)/"$repo_name-phase-$phase_num"

# Guard: worktree already exists
if test -d "$worktree_dir"
    echo "Error: Directory $worktree_dir already exists."
    echo "To remove it: git worktree remove $worktree_dir && git branch -D $branch"
    exit 1
end

# Guard: branch already exists
if git show-ref --verify --quiet "refs/heads/$branch"
    echo "Error: Branch $branch already exists."
    echo "To remove it: git branch -D $branch"
    exit 1
end

# Create worktree with new branch from HEAD
echo "Creating worktree..."
echo "  Branch:    $branch"
echo "  Directory: $worktree_dir"
echo ""

git worktree add -b "$branch" "$worktree_dir"
or begin
    echo "Error: Failed to create worktree."
    exit 1
end

# Run flutter pub get if pubspec.yaml exists
if test -f "$worktree_dir/pubspec.yaml"
    echo ""
    echo "Running flutter pub get..."
    pushd "$worktree_dir"
    flutter pub get
    popd
end

echo ""
echo "Worktree ready. To start working:"
echo ""
echo "  cd $worktree_dir && claude"
echo ""
set -l phase_int (string replace -r '^0+' '' $phase_num)
echo "Then in Claude Code:"
echo "  /gsd:discuss-phase $phase_int"
echo "  /gsd:plan-phase $phase_int"
echo "  /gsd:execute-phase $phase_int"
