---
name: setup-ui
description: Configure rawcode UI customization — installs tweakcc and applies the rawcode theme
---

Set up rawcode's UI customization for this machine.

## Steps

1. **Check if tweakcc is installed**
   ```bash
   npm list -g tweakcc 2>/dev/null || echo "not installed"
   ```

2. **Install tweakcc if missing**
   ```bash
   npm install -g tweakcc
   ```

3. **Apply rawcode theme via tweakcc**
   Run tweakcc with these preferences:
   - Input box: dark background (#1a1a2e), subtle border (#30304a)
   - User messages: clean, no heavy borders
   - Assistant messages: minimal styling
   - Accent color: #e06c75 (rawcode red)

4. **Set Claude Code theme to dark**
   Suggest the user run `/config` and select the dark theme.

5. **Verify status line is active**
   Check that `~/.claude/plugins/rawcode/statusline.sh` exists and is executable.

6. **Report what was configured**
   List all changes made, one per line.

$ARGUMENTS
