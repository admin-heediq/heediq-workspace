{
  "env": {
    "CLAUDE_CODE_DISABLE_1M_CONTEXT": "1"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"MANDATORY: Before responding to anything, read __WORKSPACE_ROOT__/heediq-workspace/CLAUDE.md (the canonical Heediq workspace rules). This applies regardless of which file or directory is open in the editor. The workspace root is __WORKSPACE_ROOT__ and ALL rules, decisions, and memory live under heediq-workspace/.\"}}}'"
          }
        ]
      }
    ]
  }
}
