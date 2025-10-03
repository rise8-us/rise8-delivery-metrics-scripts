#!/bin/bash

# SonarQube Code Quality Metrics Script
# Usage: ./sonarqube-metrics.sh [config-file] [format]
# config-file: path to configuration file (default: config.sh)
# format: json, table, summary (default: summary)

# Load configuration
CONFIG_FILE="${1:-config.sh}"
FORMAT="${2:-summary}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file '$CONFIG_FILE' not found!"
    echo "💡 Copy config.template.sh to $CONFIG_FILE and customize it for your team."
    exit 1
fi

source "$CONFIG_FILE"

# Validate required configuration
if [[ -z "$SONAR_URL" || -z "$SONAR_PROJECT_KEY" || -z "$SONAR_USERNAME" ]]; then
    echo "❌ Missing SonarQube configuration in $CONFIG_FILE"
    echo "   Required: SONAR_URL, SONAR_PROJECT_KEY, SONAR_USERNAME"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to make SonarQube API calls
sonar_api() {
    local endpoint="$1"
    curl -s -u "$SONAR_USERNAME:$SONAR_PASSWORD" "$SONAR_URL/api/$endpoint"
}

# Function to get metric value
get_metric() {
    local metric_key="$1"
    local json_data="$2"
    echo "$json_data" | jq -r ".component.measures[] | select(.metric == \"$metric_key\") | .value // \"N/A\""
}

# Function to format percentage
format_percentage() {
    local value="$1"
    if [[ "$value" == "N/A" ]]; then
        echo "N/A"
    else
        printf "%.1f%%" "$value"
    fi
}

# Function to format number with commas
format_number() {
    local value="$1"
    if [[ "$value" == "N/A" ]]; then
        echo "N/A"
    else
        printf "%'d" "$value" 2>/dev/null || echo "$value"
    fi
}

# Function to get quality gate status
get_quality_gate() {
    sonar_api "qualitygates/project_status?projectKey=$SONAR_PROJECT_KEY" | jq -r '.projectStatus.status'
}

# Function to get detailed metrics  
get_metrics() {
    # Using metric keys that exist in SonarQube 2025
    local metrics="bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,lines,ncloc,complexity,cognitive_complexity,sqale_rating,reliability_rating,security_rating,sqale_index"
    sonar_api "measures/component?component=$SONAR_PROJECT_KEY&metricKeys=$metrics"
}

# Main execution
echo -e "${BLUE}🔍 SonarQube Code Quality Report${NC}"
echo -e "${BLUE}Team: $TEAM_NAME${NC}"
echo -e "${BLUE}Repository: $REPO${NC}"
echo -e "${BLUE}Project: $SONAR_PROJECT_KEY${NC}"
echo -e "${BLUE}Generated: $(date)${NC}"
echo "=================================="


# Get quality gate status
echo -n "⏳ Fetching quality gate status..."
QUALITY_GATE=$(get_quality_gate)
if [[ "$QUALITY_GATE" == "OK" ]]; then
    echo -e " ${GREEN}✅ PASSED${NC}"
elif [[ "$QUALITY_GATE" == "ERROR" ]]; then
    echo -e " ${RED}❌ FAILED${NC}"
else
    echo -e " ${YELLOW}⚠️ $QUALITY_GATE${NC}"
fi

# Get detailed metrics
echo -n "⏳ Fetching code metrics..."
METRICS_JSON=$(get_metrics)
echo " ✅ Done"
echo ""


if [[ "$FORMAT" == "json" ]]; then
    echo "$METRICS_JSON" | jq '.'
    exit 0
fi

# Extract individual metrics
BUGS=$(get_metric "bugs" "$METRICS_JSON")
VULNERABILITIES=$(get_metric "vulnerabilities" "$METRICS_JSON")
CODE_SMELLS=$(get_metric "code_smells" "$METRICS_JSON")
COVERAGE=$(get_metric "coverage" "$METRICS_JSON")
DUPLICATED_LINES=$(get_metric "duplicated_lines_density" "$METRICS_JSON")
TOTAL_LINES=$(get_metric "lines" "$METRICS_JSON")
CODE_LINES=$(get_metric "ncloc" "$METRICS_JSON")
COMPLEXITY=$(get_metric "complexity" "$METRICS_JSON")
COGNITIVE_COMPLEXITY=$(get_metric "cognitive_complexity" "$METRICS_JSON")
MAINTAINABILITY_RATING=$(get_metric "sqale_rating" "$METRICS_JSON")
RELIABILITY_RATING=$(get_metric "reliability_rating" "$METRICS_JSON")
SECURITY_RATING=$(get_metric "security_rating" "$METRICS_JSON")
TECHNICAL_DEBT=$(get_metric "sqale_index" "$METRICS_JSON")

# Convert ratings to letter grades
rating_to_letter() {
    case "$1" in
        "1.0") echo "A" ;;
        "2.0") echo "B" ;;
        "3.0") echo "C" ;;
        "4.0") echo "D" ;;
        "5.0") echo "E" ;;
        *) echo "$1" ;;
    esac
}

# Convert technical debt minutes to hours/days
format_technical_debt() {
    local minutes="$1"
    if [[ "$minutes" == "N/A" ]]; then
        echo "N/A"
    elif (( $(echo "$minutes < 60" | bc -l 2>/dev/null || echo 0) )); then
        echo "${minutes}m"
    elif (( $(echo "$minutes < 1440" | bc -l 2>/dev/null || echo 0) )); then
        printf "%.1fh" $(echo "$minutes / 60" | bc -l 2>/dev/null || echo 0)
    else
        printf "%.1fd" $(echo "$minutes / 1440" | bc -l 2>/dev/null || echo 0)
    fi
}

if [[ "$FORMAT" == "table" ]]; then
    echo "| Metric | Value |"
    echo "|--------|--------|"
    echo "| Quality Gate | $QUALITY_GATE |"
    echo "| Bugs | $(format_number $BUGS) |"
    echo "| Vulnerabilities | $(format_number $VULNERABILITIES) |"
    echo "| Code Smells | $(format_number $CODE_SMELLS) |"
    echo "| Test Coverage | $(format_percentage $COVERAGE) |"
    echo "| Code Duplication | $(format_percentage $DUPLICATED_LINES) |"
    echo "| Lines of Code | $(format_number $CODE_LINES) |"
    echo "| Total Lines | $(format_number $TOTAL_LINES) |"
    echo "| Cyclomatic Complexity | $(format_number $COMPLEXITY) |"
    echo "| Cognitive Complexity | $(format_number $COGNITIVE_COMPLEXITY) |"
    echo "| Maintainability | $(rating_to_letter $MAINTAINABILITY_RATING) |"
    echo "| Reliability | $(rating_to_letter $RELIABILITY_RATING) |"
    echo "| Security | $(rating_to_letter $SECURITY_RATING) |"
    echo "| Technical Debt | $(format_technical_debt $TECHNICAL_DEBT) |"
else
    # Summary format (default)
    echo "🏆 QUALITY OVERVIEW:"
    echo "==================="
    echo -e "Quality Gate: ${QUALITY_GATE}"
    echo -e "Maintainability: $(rating_to_letter $MAINTAINABILITY_RATING)"
    echo -e "Reliability: $(rating_to_letter $RELIABILITY_RATING)"  
    echo -e "Security: $(rating_to_letter $SECURITY_RATING)"
    echo ""
    
    echo "🐛 ISSUES:"
    echo "=========="
    echo -e "Bugs: $(format_number $BUGS)"
    echo -e "Vulnerabilities: $(format_number $VULNERABILITIES)"
    echo -e "Code Smells: $(format_number $CODE_SMELLS)"
    echo ""
    
    echo "📊 CODE METRICS:"
    echo "================"
    echo -e "Test Coverage: $(format_percentage $COVERAGE)"
    echo -e "Code Duplication: $(format_percentage $DUPLICATED_LINES)"
    echo -e "Lines of Code: $(format_number $CODE_LINES)"
    echo -e "Cyclomatic Complexity: $(format_number $COMPLEXITY)"
    echo -e "Cognitive Complexity: $(format_number $COGNITIVE_COMPLEXITY)"
    echo -e "Technical Debt: $(format_technical_debt $TECHNICAL_DEBT)"
    echo ""
    
    # Quality assessment
    echo "📈 ASSESSMENT:"
    echo "=============="
    
    # Coverage assessment
    if [[ "$COVERAGE" != "N/A" ]] && (( $(echo "$COVERAGE >= 80" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "${GREEN}✅ Good test coverage ($(format_percentage $COVERAGE))${NC}"
    elif [[ "$COVERAGE" != "N/A" ]] && (( $(echo "$COVERAGE >= 60" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "${YELLOW}⚠️ Moderate test coverage ($(format_percentage $COVERAGE)) - aim for >80%${NC}"
    elif [[ "$COVERAGE" != "N/A" ]]; then
        echo -e "${RED}❌ Low test coverage ($(format_percentage $COVERAGE)) - needs improvement${NC}"
    else
        echo -e "${YELLOW}⚠️ Test coverage data not available${NC}"
    fi
    
    # Duplication assessment
    if [[ "$DUPLICATED_LINES" != "N/A" ]] && (( $(echo "$DUPLICATED_LINES <= 3" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "${GREEN}✅ Low code duplication ($(format_percentage $DUPLICATED_LINES))${NC}"
    elif [[ "$DUPLICATED_LINES" != "N/A" ]] && (( $(echo "$DUPLICATED_LINES <= 5" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "${YELLOW}⚠️ Moderate code duplication ($(format_percentage $DUPLICATED_LINES))${NC}"
    elif [[ "$DUPLICATED_LINES" != "N/A" ]]; then
        echo -e "${RED}❌ High code duplication ($(format_percentage $DUPLICATED_LINES)) - consider refactoring${NC}"
    fi
    
    # Issues assessment
    if [[ "$BUGS" != "N/A" ]] && [[ "$BUGS" -eq 0 ]]; then
        echo -e "${GREEN}✅ No bugs detected${NC}"
    elif [[ "$BUGS" != "N/A" ]] && [[ "$BUGS" -gt 0 ]]; then
        echo -e "${RED}❌ $BUGS bugs found - needs attention${NC}"
    fi
    
    if [[ "$VULNERABILITIES" != "N/A" ]] && [[ "$VULNERABILITIES" -eq 0 ]]; then
        echo -e "${GREEN}✅ No security vulnerabilities${NC}"
    elif [[ "$VULNERABILITIES" != "N/A" ]] && [[ "$VULNERABILITIES" -gt 0 ]]; then
        echo -e "${RED}🔒 $VULNERABILITIES security vulnerabilities - fix immediately${NC}"
    fi
fi

echo ""
echo "🔗 View detailed report: $SONAR_URL/dashboard?id=$SONAR_PROJECT_KEY"