#!/usr/bin/env python3
"""Register all agents in the registry"""

import json
import os
import re
from datetime import datetime
from pathlib import Path

AGENTS_DIR = Path(".claude/agents")
REGISTRY_FILE = Path(".claude/agents/agent-registry.json")

def extract_frontmatter(content):
    """Extract YAML frontmatter from content"""
    lines = content.split('\n')
    if lines[0].strip() != '---':
        return {}

    frontmatter = {}
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == '---':
            break
        if ':' in line:
            key, value = line.split(':', 1)
            frontmatter[key.strip()] = value.strip().strip('"\'')

    return frontmatter

def extract_tools(content):
    """Extract tools mentioned in the content"""
    tools = set()
    tool_names = ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "WebSearch", "WebFetch", "Task"]
    for tool in tool_names:
        if tool in content:
            tools.add(tool)
    return sorted(list(tools))

def categorize_agent(name, content):
    """Determine agent category"""
    if 'research' in name:
        return 'research'
    elif 'plan' in name:
        return 'planning'
    elif any(x in name for x in ['code', 'implementation', 'writer']):
        return 'implementation'
    elif 'debug' in name:
        return 'debugging'
    elif 'doc' in name:
        return 'documentation'
    elif any(x in name for x in ['metrics', 'complexity', 'spec', 'estimator']):
        return 'analysis'
    elif any(x in name for x in ['coordinator', 'supervisor']):
        return 'coordination'
    else:
        # Check content
        content_lower = content.lower()
        if 'research' in content_lower or 'investigate' in content_lower:
            return 'research'
        elif 'plan' in content_lower or 'design' in content_lower:
            return 'planning'
        elif 'implement' in content_lower or 'code' in content_lower:
            return 'implementation'
        elif 'debug' in content_lower:
            return 'debugging'
        elif 'document' in content_lower:
            return 'documentation'
        else:
            return 'research'

def extract_agent_metadata(agent_file):
    """Extract metadata from agent file"""
    content = agent_file.read_text()
    agent_name = agent_file.stem

    frontmatter = extract_frontmatter(content)

    # Get description
    description = frontmatter.get('description', '')
    if not description:
        # Extract from first paragraph
        lines = [l for l in content.split('\n') if l.strip() and not l.startswith('#') and not l.startswith('-')]
        if lines:
            description = lines[0][:200]
        else:
            description = f"Agent: {agent_name}"

    # Get tools
    tools = []
    if 'allowed-tools' in frontmatter:
        tools = [t.strip() for t in frontmatter['allowed-tools'].split(',')]
    else:
        tools = extract_tools(content)

    # Determine type
    agent_type = 'hierarchical' if any(x in content.lower() for x in ['hierarchical', 'coordinator', 'supervisor']) else 'specialized'

    # Determine category
    category = categorize_agent(agent_name, content)

    return {
        'type': agent_type,
        'category': category,
        'description': description,
        'tools': tools,
        'metrics': {
            'total_invocations': 0,
            'successful_invocations': 0,
            'failed_invocations': 0,
            'average_duration_seconds': 0.0,
            'last_invocation': None
        },
        'dependencies': [],
        'behavioral_file': str(agent_file)
    }

def main():
    # Load registry
    with REGISTRY_FILE.open() as f:
        registry = json.load(f)

    # Find all agent files
    agent_files = [f for f in AGENTS_DIR.glob("*.md")
                   if f.name != "README.md" and not f.name.endswith("-usage.md")]

    registered = 0
    skipped = 0

    print("Registering agents...")
    print()

    for agent_file in sorted(agent_files):
        agent_name = agent_file.stem

        if agent_name in registry['agents']:
            print(f"  ⊙ {agent_name} (already registered)")
            skipped += 1
            continue

        print(f"  Processing: {agent_name}")

        try:
            metadata = extract_agent_metadata(agent_file)
            registry['agents'][agent_name] = metadata
            print(f"    ✓ Type: {metadata['type']}, Category: {metadata['category']}")
            registered += 1
        except Exception as e:
            print(f"    ✗ Error: {e}")

    # Update timestamp
    registry['last_updated'] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    # Save registry
    with REGISTRY_FILE.open('w') as f:
        json.dump(registry, f, indent=2)
        f.write('\n')

    print()
    print("=" * 50)
    print(f"Registered: {registered} agents")
    print(f"Skipped: {skipped} agents (already registered)")
    print(f"Total in registry: {len(registry['agents'])} agents")
    print("=" * 50)

if __name__ == '__main__':
    main()
