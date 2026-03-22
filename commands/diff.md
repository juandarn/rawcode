---
description: Show formatted diff with brief analysis of each change
---

Show the current diff with analysis:

1. Run `git diff` to get all unstaged changes
2. Run `git diff --staged` to get staged changes
3. For each changed file, provide a one-line summary of what changed and why it matters

Format as:
```
filename.ext — what changed
filename2.ext — what changed
```

Keep analysis factual and under 1 line per file. No praise, no suggestions.
