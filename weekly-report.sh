#!/bin/bash

# Weekly Report Generator
# Usage: ./weekly-report.sh [config-file]
# config-file: path to configuration file (default: config.sh)

# Load configuration
CONFIG_FILE="${1:-config.sh}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file '$CONFIG_FILE' not found!"
    echo "💡 Copy config.template.sh to $CONFIG_FILE and customize it for your team."
    exit 1
fi

source "$CONFIG_FILE"

# Validate required configuration
if [[ -z "$REPO" || -z "$TEAM_NAME" || -z "$SEARCH_CRITERIA" ]]; then
    echo "❌ Missing required configuration in $CONFIG_FILE"
    echo "   Required: REPO, TEAM_NAME, SEARCH_CRITERIA"
    exit 1
fi

WEEK_START=$(date -v-7d +%Y-%m-%d)
WEEK_END=$(date +%Y-%m-%d)
REPORT_FILE="${REPORT_PREFIX:-weekly-report}-$(date +%Y-W%U).md"

cat > $REPORT_FILE << EOF
# $TEAM_NAME Weekly Report
**Repository: $REPO**  
**Week of $WEEK_START to $WEEK_END**

## 🎯 Key Metrics Summary

### Velocity
EOF

# Add merged PRs count (features + fixes) using configured search patterns
MERGED_FEATURES=$(gh pr list --repo $REPO --search "${FEATURE_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$WEEK_START" --json number | jq length 2>/dev/null || echo "0")
MERGED_FIXES=$(gh pr list --repo $REPO --search "${BUGFIX_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$WEEK_START" --json number | jq length 2>/dev/null || echo "0")
TOTAL_MERGED=$((MERGED_FEATURES + MERGED_FIXES))

echo "- **Features Merged**: $MERGED_FEATURES" >> $REPORT_FILE
echo "- **Bug Fixes Merged**: $MERGED_FIXES" >> $REPORT_FILE
echo "- **Total PRs Merged**: $TOTAL_MERGED" >> $REPORT_FILE

echo "- **Issues Closed**: (See details below)" >> $REPORT_FILE

# Add detailed sections
cat >> $REPORT_FILE << EOF

## 📊 Detailed Metrics

### Features Merged This Week
EOF

if [[ $MERGED_FEATURES -gt 0 ]]; then
    gh pr list --repo $REPO --search "${FEATURE_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$WEEK_START" --json title,url,mergedAt | jq -r '.[] | "- [\(.title)](\(.url)) (merged \(.mergedAt | split("T")[0]))"' >> $REPORT_FILE
else
    echo "No features merged this week." >> $REPORT_FILE
fi

cat >> $REPORT_FILE << EOF

### Bug Fixes Merged This Week
EOF

if [[ $MERGED_FIXES -gt 0 ]]; then
    gh pr list --repo $REPO --search "${BUGFIX_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$WEEK_START" --json title,url,mergedAt | jq -r '.[] | "- [\(.title)](\(.url)) (merged \(.mergedAt | split("T")[0]))"' >> $REPORT_FILE
else
    echo "No bug fixes merged this week." >> $REPORT_FILE
fi

cat >> $REPORT_FILE << EOF

### Open Items Needing Attention
EOF

# Critical items
echo "**Critical Items:**" >> $REPORT_FILE
gh pr list --repo $REPO --search "${CRITICAL_SEARCH:-$SEARCH_CRITERIA critical in:title}" --limit 5 >> $REPORT_FILE
gh issue list --repo $REPO --search "${CRITICAL_SEARCH:-$SEARCH_CRITERIA critical in:title}" --limit 5 >> $REPORT_FILE

# Stale PRs
THREE_DAYS_AGO=$(date -v-3d +%Y-%m-%d)
echo "" >> $REPORT_FILE
echo "**Stale PRs (older than 3 days):**" >> $REPORT_FILE
gh pr list --repo $REPO --search "$SEARCH_CRITERIA created:<$THREE_DAYS_AGO" --limit 5 >> $REPORT_FILE

# Open PRs summary
echo "" >> $REPORT_FILE
echo "**All Open PRs:**" >> $REPORT_FILE
gh pr list --repo $REPO --search "$SEARCH_CRITERIA" --limit 10 >> $REPORT_FILE

# Note: For multiple repositories, run this script separately for each repo
# with different config files (e.g., config-frontend.sh, config-backend.sh)

echo "✅ Weekly report generated: $REPORT_FILE"
cat $REPORT_FILE