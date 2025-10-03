# Team Metrics Scripts

A collection of configurable scripts for tracking team metrics across GitHub repositories and SonarQube projects.

## 📋 Overview

These scripts provide automated reporting for:
- **SonarQube Code Quality Metrics** - Technical debt, coverage, bugs, vulnerabilities
- **Weekly Team Reports** - PR activity, feature delivery, issue tracking
- **Monthly DORA Metrics** - Deployment frequency, lead time, failure rates

## 🚀 Quick Start

### 1. Create Your Configuration

Copy the template and customize for your team:

```bash
cp config.template.sh config-your-repo.sh
```

Edit `config-your-repo.sh` with your team's settings:
- Repository information
- Search criteria for your team's work
- SonarQube project details (if applicable)

### 2. Run the Scripts

```bash
# Generate SonarQube quality report
./sonarqube-metrics.sh config-your-repo.sh

# Create weekly team report
./weekly-report.sh config-your-repo.sh

# Generate monthly DORA metrics
./monthly-dora.sh config-your-repo.sh
```

## 📁 Files

- `config.template.sh` - Configuration template (copy this for each repo)
- `sonarqube-metrics.sh` - Code quality metrics from SonarQube
- `weekly-report.sh` - Weekly team activity report
- `monthly-dora.sh` - Monthly DORA metrics analysis

## ⚙️ Configuration Guide

### Repository Settings
```bash
REPO_ORG="your-org"
REPO_NAME="your-repo-name"
REPO="${REPO_ORG}/${REPO_NAME}"
TEAM_NAME="Your Team Name"
```

### Search Criteria Examples

**Prefix-based (default):**
```bash
SEARCH_CRITERIA="TEAM-"
FEATURE_SEARCH="feat(TEAM-"
BUGFIX_SEARCH="fix(TEAM-"
```

**Label-based:**
```bash
SEARCH_CRITERIA="label:backend"
FEATURE_SEARCH="feat label:backend"
BUGFIX_SEARCH="fix label:backend"
```

**Author-based:**
```bash
SEARCH_CRITERIA="author:teamname"
FEATURE_SEARCH="feat author:teamname"
BUGFIX_SEARCH="fix author:teamname"
```

**Milestone-based:**
```bash
SEARCH_CRITERIA="milestone:sprint-1"
FEATURE_SEARCH="feat milestone:sprint-1"
BUGFIX_SEARCH="fix milestone:sprint-1"
```

### SonarQube Settings
```bash
SONAR_URL="https://your-sonarqube-instance.com"
SONAR_PROJECT_KEY="your-project-key"
SONAR_USERNAME="your_token_here"  # User token goes here
SONAR_PASSWORD=""                 # Leave empty for token auth
```

## 📊 Multi-Repository Setup

For teams working across multiple repositories, create separate config files:

```bash
# Backend repository
cp config.template.sh config-backend.sh
# Edit config-backend.sh

# Frontend repository  
cp config.template.sh config-frontend.sh
# Edit config-frontend.sh

# Generate reports for each repo
./weekly-report.sh config-backend.sh
./weekly-report.sh config-frontend.sh
```

## 🔧 Script Options

### SonarQube Metrics
```bash
./sonarqube-metrics.sh [config-file] [format]
```
- `format`: `summary` (default), `table`, `json`

Examples:
```bash
./sonarqube-metrics.sh config-backend.sh summary
./sonarqube-metrics.sh config-frontend.sh json
```

### Weekly Reports
```bash
./weekly-report.sh [config-file]
```
Generates markdown file: `{REPORT_PREFIX}-YYYY-WWW.md`

### Monthly DORA Metrics
```bash
./monthly-dora.sh [config-file]
```
Console output with deployment frequency, lead time, failure rates, and team health indicators.

## 📈 Sample Output

### Weekly Report Structure
```markdown
# Team Name Weekly Report
**Repository: org/repo**
**Week of 2024-01-01 to 2024-01-07**

## 🎯 Key Metrics Summary
- **Features Merged**: 5
- **Bug Fixes Merged**: 2
- **Total PRs Merged**: 7

## 📊 Detailed Metrics
### Features Merged This Week
- [feat(TEAM-123): Add new dashboard](link) (merged 2024-01-05)

### Open Items Needing Attention
**Critical Items:**
**Stale PRs (older than 3 days):**
```

### DORA Metrics Output
```
🚀 DEPLOYMENT FREQUENCY:
   Features Deployed: 15
   Hotfixes Deployed: 3
   Total Deployments: 18

⏱️ LEAD TIME FOR CHANGES:
   Recently merged PRs: 20

🐛 CHANGE FAILURE RATE:
   Failure Rate: 16.67% (3 hotfixes out of 18 deployments)
```

## 🔍 Prerequisites

### Required Tools
- `gh` (GitHub CLI) - [Installation Guide](https://cli.github.com/manual/installation)
- `jq` (JSON processor) - `brew install jq` or `apt-get install jq`
- `curl` (for SonarQube API calls)
- `bc` (basic calculator for DORA calculations)

### GitHub Authentication
```bash
gh auth login
```

### Permissions Needed
- Read access to target repositories
- SonarQube project access (for quality metrics)

**SonarQube connection fails**
- Verify `SONAR_URL` is accessible
- Check `SONAR_USERNAME` token has project permissions
- Test: `curl -u "token:" "$SONAR_URL/api/projects/search"`

## 🤝 Contributing

When adding new metrics or features:
1. Update the configuration template if new settings are needed
2. Maintain backward compatibility
3. Update this README with new options
4. Test with multiple repository configurations

## 📝 Customization Tips

### Custom Search Patterns
GitHub search supports complex queries:
```bash
# Multiple labels
SEARCH_CRITERIA="label:backend label:urgent"

# Date ranges
SEARCH_CRITERIA="created:>2024-01-01"

# Multiple authors
SEARCH_CRITERIA="author:dev1 author:dev2"

# Combine criteria
SEARCH_CRITERIA="label:feature author:teamlead created:>2024-01-01"
```

### Custom Metrics
Add team-specific metrics by extending the scripts:
```bash
# In your config file
CUSTOM_LABEL_SEARCH="label:performance"
HOTFIX_SEARCH="hotfix("

# Use in scripts
PERFORMANCE_PRS=$(gh pr list --repo $REPO --search "$CUSTOM_LABEL_SEARCH" ...)
```