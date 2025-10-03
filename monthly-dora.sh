#!/bin/bash

# Monthly DORA Metrics Generator
# Usage: ./monthly-dora.sh [config-file]
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

MONTH_START=$(date -v-30d +%Y-%m-%d)
MONTH_NAME=$(date +%B\ %Y)

echo "📈 $TEAM_NAME DORA Metrics for $MONTH_NAME (Last 30 Days)"
echo "Repository: $REPO"
echo "=================================================="

# 1. Deployment Frequency (using merged PRs as proxy)
echo "🚀 DEPLOYMENT FREQUENCY:"
FEATURES=$(gh pr list --repo $REPO --search "${FEATURE_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$MONTH_START" --json number | jq length 2>/dev/null || echo "0")
FIXES=$(gh pr list --repo $REPO --search "${BUGFIX_SEARCH:-$SEARCH_CRITERIA} is:merged merged:>$MONTH_START" --json number | jq length 2>/dev/null || echo "0")
TOTAL_DEPLOYMENTS=$((FEATURES + FIXES))
echo "   Features Deployed: $FEATURES"
echo "   Hotfixes Deployed: $FIXES"
echo "   Total Deployments: $TOTAL_DEPLOYMENTS"

# 2. Lead Time (using standard gh pr list for simpler analysis)
echo -e "\n⏱️  LEAD TIME FOR CHANGES:"
MERGED_PRS=$(gh pr list --repo $REPO --search "$SEARCH_CRITERIA is:merged" --limit 20 --json createdAt,mergedAt,title | jq length 2>/dev/null || echo "0")
echo "   Recently merged PRs: $MERGED_PRS"
echo "   (Full lead time analysis requires advanced tooling)"

# 3. Change Failure Rate (hotfixes as indicator of failures)
echo -e "\n🐛 CHANGE FAILURE RATE:"
if [ $TOTAL_DEPLOYMENTS -gt 0 ]; then
  FAILURE_RATE=$(echo "scale=2; $FIXES * 100 / $TOTAL_DEPLOYMENTS" | bc -l 2>/dev/null || echo "0")
  echo "   Failure Rate: $FAILURE_RATE% ($FIXES hotfixes out of $TOTAL_DEPLOYMENTS deployments)"
else
  echo "   No deployments this month"
  FAILURE_RATE="0"
fi

# 4. Escaped Defects (production bugs)
echo -e "\n🚨 ESCAPED DEFECTS:"
PROD_BUGS=$(gh issue list --repo $REPO --search "${PRODUCTION_SEARCH:-$SEARCH_CRITERIA production in:title}" --json number | jq length 2>/dev/null || echo "0")
echo "   Production Issues: $PROD_BUGS"
echo "   Bug Fixes Merged: $FIXES"

# 5. Team Health Indicators
echo -e "\n💚 TEAM HEALTH:"
FIVE_DAYS_AGO=$(date -v-5d +%Y-%m-%d)
OPEN_PRS=$(gh pr list --repo $REPO --search "$SEARCH_CRITERIA" --json number | jq length 2>/dev/null || echo "0")
STALE_PRS=$(gh pr list --repo $REPO --search "$SEARCH_CRITERIA created:<$FIVE_DAYS_AGO" --json number | jq length 2>/dev/null || echo "0")
echo "   Open PRs: $OPEN_PRS"
echo "   Stale PRs (>5 days): $STALE_PRS"

# Monthly summary
echo -e "\n📋 MONTHLY SUMMARY:"
echo "=================="
echo "This month the $TEAM_NAME team delivered in $REPO:"
echo "- Deployed $FEATURES new features"
echo "- Fixed $FIXES issues in production"
echo "- Maintained a $FAILURE_RATE% change failure rate"
echo "- Has $OPEN_PRS active PRs ($STALE_PRS need attention)"
echo "- Resolved $PROD_BUGS production issues"