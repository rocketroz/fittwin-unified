# FitTwin Development Log System

**Version**: 1.0.0  
**Last Updated**: 2024-11-09

---

## Overview

The FitTwin Development Log System is an **automated documentation system** that tracks all development activities, commits, and technical decisions in a structured, searchable format.

### Purpose

- **For Developers**: Understand project history and recent changes
- **For AI Agents** (Codex, Claude, GPT, etc.): Maintain context across sessions
- **For Project Managers**: Track progress and technical decisions
- **For Future Maintainers**: Understand why decisions were made

### Key Features

✅ **Automatic**: Updates on every Git commit  
✅ **Structured**: Consistent format for easy parsing  
✅ **Comprehensive**: Includes code changes, rationale, and testing  
✅ **Searchable**: Markdown format with clear sections  
✅ **AI-Friendly**: Designed for LLM context windows  

---

## Quick Start

### For New Team Members

```bash
# 1. Clone the repository
git clone https://github.com/rocketroz/fittwin-unified.git
cd fittwin-unified

# 2. Run setup script
./scripts/setup-devlog.sh

# 3. Start developing!
# DEVLOG.md will auto-update on every commit
```

### For Existing Team Members

If you cloned before the devlog system was added:

```bash
# Pull latest changes
git pull origin main

# Run setup
./scripts/setup-devlog.sh
```

---

## How It Works

### Architecture

```
┌─────────────────┐
│  Git Commit     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  post-commit    │  ← Git Hook
│  Hook Triggers  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Extract Commit │
│  Metadata       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Generate Log   │
│  Entry          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update         │
│  DEVLOG.md      │
└─────────────────┘
```

### Components

1. **DEVLOG.md** - Main log file (repository root)
2. **post-commit hook** - Git hook that runs after each commit
3. **setup-devlog.sh** - Setup script for new clones
4. **DEVLOG_SYSTEM.md** - This documentation

---

## Log Entry Format

Each commit generates a structured entry:

```markdown
### [YYYY-MM-DD HH:MM] - Commit: <hash> - <type>: <summary>

**Branch**: <branch_name>
**Author**: <author>
**Files Changed**: <count> files (+<additions> -<deletions>)

#### Changes
- **Added**: `file1.swift`
- **Updated**: `file2.ts`
- **Deleted**: `file3.md`

#### Commit Message
```
<full commit message>
```

#### Technical Details
<!-- Add implementation details here -->

#### Rationale
<!-- Add why this change was made -->

#### Testing
<!-- Add how to test this change -->

#### Related
- Commit: <hash>
- Branch: <branch>
- Issue #: <number>
- PR #: <number>
```

---

## Best Practices

### Writing Commit Messages

Use **conventional commits** for better auto-generated entries:

```bash
# Good
git commit -m "feat: Add LiDAR depth processing to pose detection"

# Better (with body)
git commit -m "feat: Add LiDAR depth processing to pose detection

- Implemented enhanceLandmarksWithDepth() function
- Extracts real Z-depth values from AVDepthData
- Improves circumference accuracy by 15%

Closes #123"
```

**Commit Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### Enhancing Auto-Generated Entries

After committing, **edit DEVLOG.md** to add:

1. **Technical Details**: Implementation specifics, algorithms used
2. **Rationale**: Why this approach was chosen
3. **Testing**: How to test, expected outcomes
4. **Related**: Links to issues, PRs, documentation

**Example workflow**:

```bash
# 1. Make changes
git add .
git commit -m "feat: Add measurement caching"

# 2. DEVLOG.md is auto-updated

# 3. Edit DEVLOG.md to add details
vim DEVLOG.md

# 4. Commit the enhanced entry
git add DEVLOG.md
git commit -m "docs: Enhance devlog entry for measurement caching"
```

---

## For AI Agents

### Reading the Log

**When starting a new session**:

1. Read `DEVLOG.md` from top (most recent entries)
2. Look for entries related to your current task
3. Check "Technical Details" for implementation specifics
4. Review "Rationale" for decision context
5. Note "Known Limitations" to avoid repeating mistakes

**Example prompt for AI**:

```
Read DEVLOG.md and summarize:
1. Recent changes to the iOS measurement module
2. Technical decisions made in the last week
3. Known limitations or issues
4. Testing procedures for new features
```

### Writing to the Log

**When making changes**:

1. Commit your changes with detailed message
2. Post-commit hook auto-generates entry
3. **Important**: Add technical details, rationale, testing
4. Commit the enhanced DEVLOG.md

**Example workflow for AI agents**:

```python
# 1. Make code changes
write_file("PoseDetector.swift", code)

# 2. Commit with detailed message
git_commit(
    message="feat: Optimize depth map processing",
    body="""
    - Reduced memory allocation by 40%
    - Implemented pixel buffer caching
    - Added error handling for invalid depth data
    
    Performance improvement: 120ms → 75ms per frame
    """
)

# 3. Read auto-generated entry
devlog_entry = read_file("DEVLOG.md", lines=(1, 50))

# 4. Enhance with technical details
enhanced_entry = add_technical_details(
    devlog_entry,
    algorithm="Pixel buffer caching with LRU eviction",
    rationale="Depth map processing was bottleneck (profiled with Instruments)",
    testing="Run performance test suite: npm run test:perf"
)

# 5. Update DEVLOG.md
write_file("DEVLOG.md", enhanced_entry)

# 6. Commit enhanced entry
git_commit(message="docs: Add technical details to devlog")
```

---

## Maintenance

### Updating the Hook

If you need to modify the post-commit hook:

```bash
# 1. Edit the hook
vim .git/hooks/post-commit

# 2. Test it
git commit --allow-empty -m "test: Testing devlog hook"

# 3. Check DEVLOG.md
cat DEVLOG.md | head -50

# 4. If working, update the setup script
vim scripts/setup-devlog.sh
```

### Regenerating from History

To regenerate DEVLOG.md from Git history:

```bash
# Backup current log
cp DEVLOG.md DEVLOG.md.backup

# Create new log with header
cat > DEVLOG.md << 'EOF'
# FitTwin Development Log
...
## Development History
EOF

# Replay all commits
git log --reverse --pretty=format:"%H" | while read commit; do
    git checkout $commit
    .git/hooks/post-commit
done

# Return to latest
git checkout main
```

### Archiving Old Entries

When DEVLOG.md gets too large (>10,000 lines):

```bash
# 1. Create archive directory
mkdir -p docs/devlog-archive

# 2. Split by year
grep -n "### \[2024-" DEVLOG.md | tail -1 | cut -d: -f1
# Note the line number

# 3. Split file
head -n <line_number> DEVLOG.md > docs/devlog-archive/DEVLOG-2024.md
tail -n +<line_number> DEVLOG.md > DEVLOG-new.md

# 4. Update main log
mv DEVLOG-new.md DEVLOG.md

# 5. Add link to archive
echo "[View 2024 Archive](docs/devlog-archive/DEVLOG-2024.md)" >> DEVLOG.md
```

---

## Troubleshooting

### Hook Not Running

**Problem**: DEVLOG.md not updating after commit

**Solutions**:

```bash
# Check if hook exists
ls -la .git/hooks/post-commit

# Check if executable
chmod +x .git/hooks/post-commit

# Test manually
.git/hooks/post-commit

# Check for errors
bash -x .git/hooks/post-commit
```

### DEVLOG.md Corrupted

**Problem**: DEVLOG.md format broken

**Solutions**:

```bash
# Restore from backup
git checkout HEAD~1 -- DEVLOG.md

# Or regenerate from Git history
./scripts/setup-devlog.sh

# Or restore from archive
cp docs/devlog-archive/DEVLOG-2024.md DEVLOG.md
```

### Merge Conflicts

**Problem**: DEVLOG.md has merge conflicts

**Solutions**:

```bash
# Accept both changes (ours and theirs)
git checkout --ours DEVLOG.md
git checkout --theirs DEVLOG.md.tmp

# Manually merge entries
cat DEVLOG.md.tmp >> DEVLOG.md
rm DEVLOG.md.tmp

# Or regenerate
git checkout main -- DEVLOG.md
./scripts/setup-devlog.sh
```

---

## Integration with Tools

### VS Code

Add to `.vscode/settings.json`:

```json
{
  "files.associations": {
    "DEVLOG.md": "markdown"
  },
  "markdown.extension.toc.levels": "2..3",
  "markdown.extension.toc.updateOnSave": true
}
```

### GitHub Actions

Auto-commit DEVLOG.md changes:

```yaml
name: Update DEVLOG

on:
  push:
    branches: [main, develop]

jobs:
  update-devlog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check for DEVLOG changes
        run: |
          if [ -n "$(git status --porcelain DEVLOG.md)" ]; then
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git add DEVLOG.md
            git commit -m "docs: Auto-update DEVLOG.md [skip ci]"
            git push
          fi
```

### Slack/Discord Notifications

Post new entries to team chat:

```bash
# Add to post-commit hook
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"📝 New commit: $COMMIT_MESSAGE\n\nView: https://github.com/rocketroz/fittwin-unified/blob/main/DEVLOG.md\"}" \
  $WEBHOOK_URL
```

---

## Statistics

### Current Stats

- **Total Commits Logged**: 5
- **Total Lines**: ~2,500
- **Average Entry Length**: 500 lines
- **Oldest Entry**: 2024-11-09
- **Most Active Branch**: feature/ios-measurement-poc

### Tracking Metrics

The system automatically tracks:

- Total commits
- Total file changes
- Total additions/deletions
- Active branches
- Last update time

View in `DEVLOG.md` under "## Statistics"

---

## FAQ

### Q: Do I need to manually update DEVLOG.md?

**A**: No, it updates automatically. But you **should** add technical details for better documentation.

### Q: What if I forget to run setup-devlog.sh?

**A**: The hook won't run, but you can run setup anytime. It won't affect existing commits.

### Q: Can I disable the auto-update?

**A**: Yes, remove or rename `.git/hooks/post-commit`

### Q: How do AI agents use this?

**A**: They read DEVLOG.md at the start of each session to understand recent changes and maintain context.

### Q: What if DEVLOG.md gets too large?

**A**: Archive old entries (see "Archiving Old Entries" section)

### Q: Can I customize the entry format?

**A**: Yes, edit `.git/hooks/post-commit` and `scripts/setup-devlog.sh`

---

## Future Enhancements

### Planned Features

- [ ] **Search command**: `./scripts/search-devlog.sh "LiDAR"`
- [ ] **Statistics dashboard**: Generate charts from log data
- [ ] **AI summary**: Auto-generate weekly summaries
- [ ] **Jira integration**: Link commits to tickets
- [ ] **Code review assistant**: Suggest reviewers based on log
- [ ] **Changelog generator**: Auto-generate CHANGELOG.md from DEVLOG.md

### Contributing

To suggest improvements:

1. Open an issue on GitHub
2. Describe the enhancement
3. Provide use case
4. Submit PR with implementation

---

## References

- **Git Hooks**: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Markdown Guide**: https://www.markdownguide.org/

---

## Support

**Questions?** Ask in:
- GitHub Discussions
- Team Slack #dev-tools
- Email: dev@fittwin.com

**Issues?** Report on:
- GitHub Issues: https://github.com/rocketroz/fittwin-unified/issues

---

**Last Updated**: 2024-11-09  
**Version**: 1.0.0  
**Maintainer**: FitTwin Dev Team
