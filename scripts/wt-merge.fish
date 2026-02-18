#!/usr/bin/env fish
#
# Merge completed parallel phase branches back to the current branch.
#
# Usage:
#   fish scripts/wt-merge.fish <branch1> <branch2> [branch3...]
#
# Example:
#   fish scripts/wt-merge.fish phase/02-model-distribution phase/03-app-foundation
#
# Strategy:
#   - Phase planning directories (.planning/phases/NN-*/) — no conflict expected (disjoint)
#   - .planning/STATE.md, .planning/ROADMAP.md — auto-resolve with ours, print reconciliation reminder
#   - Source code conflicts (pubspec.yaml, lib/, etc.) — halt for manual resolution

set -l branches $argv

if test (count $branches) -lt 2
    echo "Usage: fish scripts/wt-merge.fish <branch1> <branch2> [branch3...]"
    echo "Example: fish scripts/wt-merge.fish phase/02-model-distribution phase/03-app-foundation"
    exit 1
end

set -l repo_root (git rev-parse --show-toplevel)
set -l repo_name (basename $repo_root)
set -l current_branch (git branch --show-current)

# Verify clean working tree
if not git diff --quiet; or not git diff --cached --quiet
    echo "Error: Working tree has uncommitted changes. Commit or stash first."
    exit 1
end

# Verify all branches exist
for branch in $branches
    if not git show-ref --verify --quiet "refs/heads/$branch"
        echo "Error: Branch $branch does not exist."
        exit 1
    end
end

echo "Merging into: $current_branch"
echo "Branches: $branches"
echo ""

# Track state files that need reconciliation
set -l needs_reconciliation

for branch in $branches
    echo "--- Merging $branch ---"
    echo ""

    # Attempt the merge
    if git merge --no-edit "$branch" 2>/dev/null
        echo "Merged $branch cleanly."
        echo ""
        continue
    end

    # Merge had conflicts — check what conflicted
    set -l conflicted_files (git diff --name-only --diff-filter=U)

    if test -z "$conflicted_files"
        echo "Error: Merge failed for unknown reason."
        exit 1
    end

    echo "Conflicts in:"
    for f in $conflicted_files
        echo "  $f"
    end
    echo ""

    # Separate state files from source files
    set -l state_files
    set -l source_files

    for f in $conflicted_files
        switch $f
            case '.planning/STATE.md' '.planning/ROADMAP.md'
                set -a state_files $f
            case '*'
                set -a source_files $f
        end
    end

    # Auto-resolve state files with --ours
    if test (count $state_files) -gt 0
        for f in $state_files
            echo "Auto-resolving $f (taking ours — manual reconciliation needed)"
            git checkout --ours "$f"
            git add "$f"
        end
        set -a needs_reconciliation $state_files
        echo ""
    end

    # If source files conflict, halt for manual resolution
    if test (count $source_files) -gt 0
        echo "Source code conflicts require manual resolution:"
        for f in $source_files
            echo "  $f"
        end
        echo ""
        echo "Resolve conflicts, then:"
        echo "  git add <resolved-files>"
        echo "  git commit"
        echo ""
        echo "After resolving, re-run this script for remaining branches (if any)."
        exit 1
    end

    # All conflicts were state files — complete the merge
    git commit --no-edit
    echo "Merge commit created (state files auto-resolved)."
    echo ""
end

echo "=== All branches merged ==="
echo ""

# Reconciliation reminder
if test (count $needs_reconciliation) -gt 0
    # Deduplicate
    set -l unique_files (printf '%s\n' $needs_reconciliation | sort -u)
    echo "RECONCILIATION NEEDED:"
    echo "The following files were auto-resolved (took ours) and need manual update"
    echo "to reflect the work from all merged branches:"
    echo ""
    for f in $unique_files
        echo "  $f"
    end
    echo ""
    echo "Review each branch's version to incorporate their progress updates:"
    for branch in $branches
        echo "  git show $branch:<file>"
    end
    echo ""
end

# Suggest worktree cleanup
echo "CLEANUP (review before running):"
echo ""
for branch in $branches
    # Extract phase number from branch name (phase/02-something -> 02)
    set -l phase_num (string replace -r 'phase/(\d+)-.*' '$1' $branch)
    set -l worktree_dir (dirname $repo_root)/"$repo_name-phase-$phase_num"

    if test -d "$worktree_dir"
        echo "  git worktree remove $worktree_dir && git branch -D $branch"
    else
        echo "  git branch -D $branch"
    end
end
echo ""
