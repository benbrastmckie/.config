#!/usr/bin/env bash
# Example: Complete artifact creation workflow
# Demonstrates end-to-end artifact creation with registry integration

set -euo pipefail

# Setup
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"

# ==============================================================================
# Example 1: Basic Artifact Creation Workflow
# ==============================================================================

echo "=== Example 1: Basic Artifact Creation ==="
echo

# Step 1: Create artifact directory from workflow description
workflow="Implement user authentication system"
read -r project_name artifact_dir next_number <<< "$(create_artifact_directory "$workflow")"

echo "Project: $project_name"
echo "Directory: $artifact_dir"
echo "Next number: $next_number"
echo

# Step 2: Generate artifact path
research_topic="JWT vs session-based authentication patterns"
artifact_name="authentication_patterns"
artifact_path="specs/artifacts/${project_name}/${next_number}_${artifact_name}.md"

echo "Artifact path: $artifact_path"
echo

# Step 3: Generate invocation prompt (for agent)
echo "--- Invocation Prompt (first 20 lines) ---"
generate_artifact_invocation "$artifact_path" "$research_topic" "$workflow" | head -20
echo "..."
echo

# Step 4: Write artifact (fallback if agent doesn't write)
research_findings="
JWT (JSON Web Tokens) and session-based authentication represent two fundamentally
different approaches to managing user authentication state in web applications.

JWT advantages:
- Stateless: Server doesn't need to store session data
- Scalable: Works well with distributed systems and microservices
- Cross-domain: Can be used across multiple domains
- Mobile-friendly: Easy to implement in mobile apps

Session advantages:
- Server control: Can invalidate sessions immediately
- Smaller payload: Only session ID transmitted
- More secure by default: Less risk of token theft
- Simpler implementation: Built into most frameworks

For this implementation, JWT is recommended for the API layer (stateless, scalable)
while sessions work better for the web interface (immediate invalidation, simpler).
A hybrid approach using both may be optimal.
"

echo "Writing artifact with fallback function..."
write_artifact_file "$research_findings" "$artifact_path" '{"topic":"Authentication Patterns","workflow":"User authentication"}'
echo "Artifact written to: $artifact_path"
echo

# Step 5: Register artifact in registry
echo "Registering artifact..."
# Build JSON metadata (single line to avoid jq errors)
metadata_json="{\"topic\":\"$research_topic\",\"workflow\":\"$workflow\",\"project\":\"$project_name\",\"number\":\"$next_number\"}"
artifact_id=$(register_artifact "research" "$artifact_path" "$metadata_json")

echo "Artifact registered with ID: $artifact_id"
echo

# Step 6: Verify registry entry
registry_file="$CLAUDE_PROJECT_DIR/.claude/registry/${artifact_id}.json"
if [ -f "$registry_file" ]; then
  echo "Registry entry contents:"
  cat "$registry_file" | jq '.'
fi
echo

# ==============================================================================
# Example 2: Multiple Artifacts in Same Topic
# ==============================================================================

echo "=== Example 2: Multiple Artifacts (Auto-Increment) ==="
echo

# Create second artifact in same topic
next_number2=$(get_next_artifact_number "$artifact_dir")
echo "Next number after first artifact: $next_number2"

artifact_path2="specs/artifacts/${project_name}/${next_number2}_password_hashing.md"
write_artifact_file "Brief findings on bcrypt vs argon2 for password hashing..." "$artifact_path2" '{"topic":"Password Hashing"}'

metadata_json2="{\"topic\":\"Password hashing strategies\",\"workflow\":\"$workflow\",\"project\":\"$project_name\",\"number\":\"$next_number2\"}"
artifact_id2=$(register_artifact "research" "$artifact_path2" "$metadata_json2")

echo "Second artifact ID: $artifact_id2"
echo

# Create third artifact
next_number3=$(get_next_artifact_number "$artifact_dir")
echo "Next number after second artifact: $next_number3"
echo

# ==============================================================================
# Example 3: Query Registry
# ==============================================================================

echo "=== Example 3: Query Registry ==="
echo

# Query all research artifacts
echo "All research artifacts:"
query_artifacts "research" | jq -r '.[] | "  - \(.artifact_path) (created: \(.created_at))"'
echo

# Query artifacts for this project
echo "Artifacts for project '$project_name':"
query_artifacts "research" "*authentication*" | jq -r '.[] | "  - \(.metadata.topic)"'
echo

# ==============================================================================
# Cleanup
# ==============================================================================

echo "=== Cleanup ==="
echo "Removing example artifacts and registry entries..."
rm -rf "$artifact_dir"
rm -f "$CLAUDE_PROJECT_DIR/.claude/registry/research_${next_number}_*.json"
rm -f "$CLAUDE_PROJECT_DIR/.claude/registry/research_${next_number2}_*.json"
echo "Cleanup complete"
echo

echo "=== Workflow Complete ==="
echo
echo "Summary:"
echo "  - Created artifact directory from workflow description"
echo "  - Auto-incremented artifact numbers (001, 002, 003)"
echo "  - Wrote variable-length artifacts with metadata"
echo "  - Registered artifacts in .claude/registry/"
echo "  - Queried registry by type and pattern"
echo
echo "This demonstrates the complete artifact creation workflow for"
echo "integration with research agents and future cross-referencing."
