- Always prioritise using a REPL if one is available.
- When the users says "draft" they mean to produce the text to the conversation and wait for explicit confirmation before performing the drafted task
  - This applies to all task including (but not limited to) issue bodies, PR descriptions, commit messages, comments, docs, code
  - Do not invoke the command or agent until the user has given explicit confirmation
  - This holds even when a skill's documented flow (e.g. `chalk new`) goes end-to-end — the user's wording wins
- When communicating multiple things the user might want to respond to (options, suggestions, comments on multiple things we're talking about) use numbers and subnumbers to label them
  - For example:
    1. This
    2.1 Something
    2.2 Else
