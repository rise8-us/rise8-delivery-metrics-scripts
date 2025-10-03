#!/bin/bash

# Mission Workup Service Team Configuration
# Based on the existing RMW team setup

# ======================
# REPOSITORY CONFIGURATION
# ======================
REPO_ORG="kahless"
REPO_NAME="mission-workup-service"
REPO="${REPO_ORG}/${REPO_NAME}"

# ======================
# TEAM/PROJECT CONFIGURATION
# ======================
TEAM_NAME="Mission Workup Team"

# ======================
# SEARCH CRITERIA
# ======================
# Main search criteria for identifying Mission Workup team's work
SEARCH_CRITERIA="RMW-"

# Specific patterns for different types of work
FEATURE_SEARCH="feat(RMW-"
BUGFIX_SEARCH="fix(RMW-"
CRITICAL_SEARCH="RMW- critical in:title"
PRODUCTION_SEARCH="RMW- production in:title"

# ======================
# SONARQUBE CONFIGURATION
# ======================
SONAR_URL="https://faker.sonarqube.server"
SONAR_PROJECT_KEY="kahless-mission-workup-service"
# Using user token (for API access, token goes in username field, password empty)
SONAR_USERNAME="squ_your_token_here"
SONAR_PASSWORD=""

# ======================
# REPORT SETTINGS
# ======================
# File naming (will include repo name)
REPORT_PREFIX="rmw-mission-workup-service"