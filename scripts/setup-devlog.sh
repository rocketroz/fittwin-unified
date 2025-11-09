#!/bin/bash
# Setup script for FitTwin Development Log automation
# Run this after cloning the repository

set -e

echo "🔧 Setting up FitTwin Development Log automation..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository root"
    echo "   Please run this script from the repository root directory"
    exit 1
fi

# Check if DEVLOG.md exists
if [ ! -f "DEVLOG.md" ]; then
    echo "⚠️  DEVLOG.md not found"
    echo "   Creating initial DEVLOG.md..."
    
    cat > DEVLOG.md << 'EOF'
# FitTwin Development Log

**Purpose**: Automated log of all development activities, commits, and technical decisions.

**Audience**: Developers, AI agents (Codex, Claude, etc.), project managers, and future maintainers.

---

## Development History

<!-- Entries will be auto-generated here by Git post-commit hook -->

---

## Statistics

**Total Commits**: 0  
**Total Files Changed**: 0  
**Total Additions**: +0 lines  
**Total Deletions**: -0 lines  
**Active Branch**: main  
**Last Updated**: $(date '+%Y-%m-%d %H:%M') UTC

---

**Last Entry**: N/A  
**Next Update**: Automatic on next commit
EOF
    
    echo "✅ Created DEVLOG.md"
fi

# Install post-commit hook
echo "📝 Installing Git post-commit hook..."

if [ -f ".git/hooks/post-commit" ]; then
    echo "⚠️  Existing post-commit hook found"
    echo "   Backing up to post-commit.backup"
    mv .git/hooks/post-commit .git/hooks/post-commit.backup
fi

cat > .git/hooks/post-commit << 'HOOK_EOF'
#!/bin/bash
# FitTwin Automatic Development Log Generator
# Runs after every commit to update DEVLOG.md

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📝 Updating DEVLOG.md...${NC}"

# Get commit information
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_DATE=$(git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M')
COMMIT_AUTHOR=$(git log -1 --format='%an')
COMMIT_MESSAGE=$(git log -1 --format='%s')
COMMIT_BODY=$(git log -1 --format='%b')
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Get file statistics
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l | tr -d ' ')
ADDITIONS=$(git diff-tree --no-commit-id --numstat -r HEAD | awk '{add+=$1} END {print add+0}')
DELETIONS=$(git diff-tree --no-commit-id --numstat -r HEAD | awk '{del+=$2} END {print del+0}')

# Get list of changed files with their changes
CHANGED_FILES=$(git diff-tree --no-commit-id --name-status -r HEAD)

# Extract commit type from conventional commit format
COMMIT_TYPE=$(echo "$COMMIT_MESSAGE" | grep -oE '^[a-z]+' | head -1)
if [ -z "$COMMIT_TYPE" ]; then
    COMMIT_TYPE="chore"
fi
COMMIT_SUMMARY=$(echo "$COMMIT_MESSAGE" | sed 's/^[a-z]*: //')

# Create log entry
LOG_ENTRY="
### [$COMMIT_DATE] - Commit: $COMMIT_HASH - $COMMIT_TYPE: $COMMIT_SUMMARY

**Branch**: $BRANCH_NAME  
**Author**: $COMMIT_AUTHOR  
**Files Changed**: $FILES_CHANGED files (+$ADDITIONS -$DELETIONS)

#### Changes
$(echo "$CHANGED_FILES" | while read status file; do
    case $status in
        A) echo "- **Added**: \`$file\`" ;;
        M) echo "- **Updated**: \`$file\`" ;;
        D) echo "- **Deleted**: \`$file\`" ;;
        R*) echo "- **Renamed**: \`$file\`" ;;
    esac
done)

#### Commit Message
\`\`\`
$COMMIT_MESSAGE
$([ -n "$COMMIT_BODY" ] && echo "$COMMIT_BODY")
\`\`\`

#### Technical Details
<!-- Auto-generated entry. Add technical details manually or via commit body. -->

#### Rationale
<!-- Add rationale for this change. -->

#### Testing
<!-- Add testing instructions. -->

#### Related
- Commit: $COMMIT_HASH
- Branch: $BRANCH_NAME

---
"

# Check if DEVLOG.md exists
if [ ! -f "DEVLOG.md" ]; then
    echo -e "${YELLOW}⚠️  DEVLOG.md not found. Skipping auto-update.${NC}"
    echo -e "${YELLOW}   Run 'scripts/setup-devlog.sh' to initialize.${NC}"
    exit 0
fi

# Find the "## Development History" section and insert after it
if grep -q "## Development History" DEVLOG.md; then
    # Create temporary file
    TEMP_FILE=$(mktemp)
    
    # Insert new entry after "## Development History"
    awk -v entry="$LOG_ENTRY" '
        /## Development History/ {
            print
            print ""
            print entry
            next
        }
        {print}
    ' DEVLOG.md > "$TEMP_FILE"
    
    # Replace original file
    mv "$TEMP_FILE" DEVLOG.md
    
    # Update statistics
    TOTAL_COMMITS=$(git rev-list --count HEAD)
    TOTAL_ADDITIONS=$(git log --numstat --pretty="%H" | awk 'NF==3 {plus+=$1} END {printf("%d", plus)}')
    TOTAL_DELETIONS=$(git log --numstat --pretty="%H" | awk 'NF==3 {minus+=$2} END {printf("%d", minus)}')
    
    # Update statistics section
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/\*\*Total Commits\*\*: [0-9]*/\*\*Total Commits\*\*: $TOTAL_COMMITS/" DEVLOG.md
        sed -i '' "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $COMMIT_DATE UTC/" DEVLOG.md
        sed -i '' "s/\*\*Last Entry\*\*: .*/\*\*Last Entry\*\*: $COMMIT_DATE UTC/" DEVLOG.md
    else
        # Linux
        sed -i "s/\*\*Total Commits\*\*: [0-9]*/\*\*Total Commits\*\*: $TOTAL_COMMITS/" DEVLOG.md
        sed -i "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $COMMIT_DATE UTC/" DEVLOG.md
        sed -i "s/\*\*Last Entry\*\*: .*/\*\*Last Entry\*\*: $COMMIT_DATE UTC/" DEVLOG.md
    fi
    
    echo -e "${GREEN}✅ DEVLOG.md updated successfully!${NC}"
    echo -e "${BLUE}📊 Entry added for commit $COMMIT_HASH${NC}"
    echo -e "${YELLOW}💡 Tip: Edit DEVLOG.md to add technical details, rationale, and testing notes${NC}"
    
else
    echo -e "${YELLOW}⚠️  Could not find '## Development History' section in DEVLOG.md${NC}"
    exit 1
fi

exit 0
HOOK_EOF

chmod +x .git/hooks/post-commit

echo "✅ Git post-commit hook installed"
echo ""

# Test the setup
echo "🧪 Testing setup..."
if [ -x ".git/hooks/post-commit" ]; then
    echo "✅ Hook is executable"
else
    echo "❌ Hook is not executable"
    exit 1
fi

if [ -f "DEVLOG.md" ]; then
    echo "✅ DEVLOG.md exists"
else
    echo "❌ DEVLOG.md not found"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📚 How it works:"
echo "   1. Make changes and commit as usual"
echo "   2. Post-commit hook automatically updates DEVLOG.md"
echo "   3. Review the auto-generated entry"
echo "   4. Edit DEVLOG.md to add technical details (optional)"
echo "   5. Commit DEVLOG.md separately or amend your commit"
echo ""
echo "💡 Tips:"
echo "   - Use conventional commit messages: feat:, fix:, docs:, etc."
echo "   - Add detailed commit body for better auto-generated entries"
echo "   - Review DEVLOG.md after each commit"
echo "   - Edit entries to add context for AI agents and developers"
echo ""
echo "📖 Read DEVLOG.md for full documentation"
echo ""
