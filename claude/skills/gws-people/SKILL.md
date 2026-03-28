---
name: gws-people
version: 1.0.0
description: Use when managing Google contacts and directory profiles.
metadata:
  openclaw:
    category: "productivity"
    requires:
      bins: ["gws"]
    cliHelp: "gws people --help"
---

# people (v1)

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

```bash
gws people <resource> <method> [flags]
```

## API Resources

### contactGroups

  - `batchGet` — Get a list of contact groups owned by the authenticated user.
  - `create` — Create a new contact group owned by the authenticated user.
  - `delete` — Delete an existing contact group owned by the authenticated user.
  - `get` — Get a specific contact group owned by the authenticated user.
  - `list` — List all contact groups owned by the authenticated user.
  - `update` — Update the name of an existing contact group owned by the authenticated user.
  - `members` — Operations on the 'members' resource

### otherContacts

  - `copyOtherContactToMyContactsGroup` — Copies an "Other contact" to a new contact in the user's "myContacts" group.
  - `list` — List all "Other contacts" (auto-created contacts not in a contact group).
  - `search` — Search the user's other contacts that match the search query.

### people

  - `batchCreateContacts` — Create a batch of new contacts.
  - `batchUpdateContacts` — Update a batch of contacts.
  - `createContact` — Create a new contact and return the person resource.
  - `deleteContactPhoto` — Delete a contact's photo.
  - `get` — Provides information about a person by specifying a resource name. Use `people/me` for the authenticated user.
  - `getBatchGet` — Provides information about a list of specific people.
  - `listDirectoryPeople` — Provides a list of domain profiles and domain contacts in the authenticated user's domain directory.
  - `searchContacts` — Search the user's grouped contacts that match the search query.
  - `searchDirectoryPeople` — Search domain profiles and contacts in the authenticated user's domain directory.
  - `updateContact` — Update contact data for an existing contact person.
  - `updateContactPhoto` — Update a contact's photo.
  - `connections` — Operations on the 'connections' resource

## Discovering Commands

Before calling any API method, inspect it:

```bash
# Browse resources and methods
gws people --help

# Inspect a method's required params, types, and defaults
gws schema people.<resource>.<method>
```

Use `gws schema` output to build your `--params` and `--json` flags.
