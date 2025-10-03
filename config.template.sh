#!/bin/bash

# Single Repository Metrics Configuration Template
# Copy this to config-[repo-name].sh and customize for each repository you want to track

# ======================
# REPOSITORY CONFIGURATION
# ======================
REPO_ORG="your-org"
REPO_NAME="your-repo-name"
REPO="${REPO_ORG}/${REPO_NAME}"

# ======================
# TEAM/PROJECT CONFIGURATION
# ======================
TEAM_NAME="Your Team Name"

# ======================
# SEARCH CRITERIA
# ======================
# Define your search patterns based on how your team labels/names issues and PRs
# Examples:
#   - "RMW-" (prefix-based)
#   - "label:backend" (label-based)
#   - "author:teamname" (author-based)
#   - "milestone:sprint-1" (milestone-based)
#   - "[TEAM]" (tag-based)
#   - Any GitHub search syntax: https://docs.github.com/en/search-github/searching-on-github

# Main search criteria for identifying your team's work
SEARCH_CRITERIA="RMW-"

# Specific patterns for different types of work
FEATURE_SEARCH="feat(RMW-"
BUGFIX_SEARCH="fix(RMW-"
CRITICAL_SEARCH="RMW- critical in:title"
PRODUCTION_SEARCH="RMW- production in:title"

# ======================
# SONARQUBE CONFIGURATION (if applicable)
# ======================
SONAR_URL="https://your-sonarqube-instance.com"
SONAR_PROJECT_KEY="your-project-key"
# SonarQube authentication (user token goes in username field, password empty)
SONAR_USERNAME="your_sonarqube_token_here"
SONAR_PASSWORD=""

# ======================
# REPORT SETTINGS
# ======================
# File naming (will include repo name)
REPORT_PREFIX="${TEAM_NAME,,}-${REPO_NAME}"  # e.g., "rmw-mission-workup-service"