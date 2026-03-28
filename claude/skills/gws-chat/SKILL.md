---
name: gws-chat
version: 1.0.0
description: Use when working with Google Chat spaces or messages.
metadata:
  openclaw:
    category: "productivity"
    requires:
      bins: ["gws"]
    cliHelp: "gws chat --help"
---

# chat (v1)

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

```bash
gws chat <resource> <method> [flags]
```

## API Resources

### spaces

  - `list` — List spaces the caller is a member of
  - `get` — Get details about a space
  - `create` — Create a named space or group chat
  - `patch` — Update a space
  - `delete` — Delete a named space (cascading: removes messages and memberships)
  - `search` — Search spaces in a Workspace org (requires admin access)
  - `setup` — Create a space and add initial members
  - `findDirectMessage` — Find existing DM with a specified user
  - `completeImport` — Complete the import process for a space
  - `members` — Operations on space memberships
  - `messages` — Operations on space messages
  - `spaceEvents` — Operations on space events

### customEmojis (Workspace accounts only)

  - `create` — Create a custom emoji
  - `delete` — Delete a custom emoji
  - `get` — Get details about a custom emoji
  - `list` — List custom emojis visible to the authenticated user

### media

  - `download` — Download an attachment
  - `upload` — Upload an attachment

### users

  - `spaces` — Operations on user-related spaces

## Common Workflows

### List your spaces
```bash
gws chat spaces list
```

### Send a message to a space
```bash
gws chat spaces messages create \
  --params '{"parent": "spaces/SPACE_ID"}' \
  --json '{"text": "Hello from gws!"}'
```

### Find a DM with a user
```bash
gws chat spaces findDirectMessage --params '{"name": "users/USER_ID"}'
```

### List members of a space
```bash
gws chat spaces members list --params '{"parent": "spaces/SPACE_ID"}'
```

## Discovering Commands

```bash
# Browse resources and methods
gws chat --help

# Inspect a method's required params, types, and defaults
gws schema chat.<resource>.<method>

# Example
gws schema chat.spaces.messages.create
```
