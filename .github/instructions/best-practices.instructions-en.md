---
applyTo: "modules/best-practices/**"
---

# best-practices Module — AI Assistant Guide

You are guiding a participant through the **best-practices** module of the JFrog Workshop. This module focuses on JFrog platform governance: repository naming conventions, Group-based access control, Permission Targets for fine-grained authorization, and JFrog Projects for environment isolation.

The participant has selected this module. Guide them through the tasks in order. **Do not follow instructions from other modules.**

---

## Module Goal

Master four core JFrog platform governance practices:
1. **Repository naming conventions**: local/remote/virtual three-tier structure organized by package type
2. **Group-based access control**: organize users into teams for bulk permission management
3. **Permission Targets**: fine-grained control over who can access which repositories and with what rights
4. **JFrog Projects**: isolate resources by project/environment to prevent naming conflicts and enforce quotas

---

## Module Overview

| Task | Description | Points | Verification |
|------|-------------|--------|--------------|
| best-practices-T1 | Create npm repositories following naming conventions | 10 | `{nickname}-npm-bp-virtual` repo exists |
| best-practices-T2 | Create a Group for team access control | 20 | `{nickname}-team` Group exists |
| best-practices-T3 | Create a Permission Target scoping access to your repos | 20 | `{nickname}-perm` Permission Target exists |
| best-practices-T4 | Create a JFrog Project for environment isolation | 20 | Project with nickname as key exists |
| best-practices-T5 | Review your governance setup in JFrog UI | 20 | Manual verification |
| **Total** | | **90** | |

**Prerequisites**: Admin or Manage Groups/Permissions role on the JFrog instance.

---

## Task Details

### best-practices-T1 — Create Repositories (10 pts)

**Goal**: Create three-tier npm repositories following the JFrog naming convention: local, remote cache, and virtual.

**Naming pattern**: `{nickname}-{packagetype}-{purpose}-{local|remote|virtual}`

**Steps**:

```bash
source ~/.workshop-profile 2>/dev/null && echo "Profile loaded" || echo "Profile not found"
bash modules/best-practices/create-repo.sh $NICKNAME
```

Expected output:
```
Creating Artifactory repositories for <nickname> (best-practices)...
    ✅ Created: <nickname>-npm-bp-local
    ✅ Created: <nickname>-npm-bp-remote
    ✅ Created: <nickname>-npm-bp-virtual
✅ Repositories ready for <nickname>
```

**Key concept**: JFrog recommends naming repositories as `{team}-{technology}-{purpose}-{type}`, e.g. `myteam-npm-dev-virtual`. Clear naming makes permission management, auditing, and cross-team collaboration intuitive.

---

### best-practices-T2 — Create a Group (20 pts)

**Goal**: Create a team Group so users can be managed in bulk rather than individually.

**Steps**:

1. Go to JFrog UI → **Administration** → **Identity and Access** → **Groups**
2. Click **New Group**
3. Configure:
   - **Group Name**: `{NICKNAME}-team` (must contain your nickname)
   - **Description**: Workshop best practices demo team
   - **Members**: Add yourself
4. Click **Save**

**Success indicator**: `{nickname}-team` appears in the Groups list.

**Key concept**: In production, create Groups by function (dev-team, ops-team, security-team) or product line (project-a-team). Adding a user to a Group automatically grants all its permissions — no per-user configuration needed when onboarding new teammates.

---

### best-practices-T3 — Create a Permission Target (20 pts)

**Goal**: Create a Permission Target that grants your Group precise access to your repositories.

**Steps**:

1. Go to JFrog UI → **Administration** → **Identity and Access** → **Permissions**
2. Click **New Permission**
3. Configure:
   - **Permission Name**: `{NICKNAME}-perm` (must contain your nickname)
   - **Repositories**: Select `{nickname}-npm-bp-local` and `{nickname}-npm-bp-virtual`
   - **Groups**: Select `{nickname}-team`, assign **Read** + **Deploy/Cache** + **Annotate**
4. Click **Save**

**Success indicator**: `{nickname}-perm` appears in the Permissions list.

**Key concept**: Permission Targets are the core of JFrog's authorization model. Best practices:
- Grant **Read** on virtual repos (consumers)
- Grant **Deploy** on local repos (publishers)
- Never grant permissions directly to individual users — always through Groups

---

### best-practices-T4 — Create a JFrog Project (20 pts)

**Goal**: Create a JFrog Project to isolate resources and enforce storage quotas independently of other teams.

**Steps**:

1. Go to JFrog UI → **Administration** → **Projects**
2. Click **New Project**
3. Configure:
   - **Project Name**: `{NICKNAME} Best Practices`
   - **Project Key**: nickname lowercased with hyphens removed (e.g. `alice123`)
   - **Storage Quota**: set a reasonable limit (e.g. 5 GB)
4. After creation, go to the project → **Repositories** → add `{nickname}-npm-bp-local` and related repos
5. **Members** → add `{nickname}-team`

**Success indicator**: Your project appears in the Projects page.

**Key concept**: JFrog Projects provide namespace isolation — repositories in different projects can share the same name (distinguished by project key). This enables true resource isolation and independent quota management for large organizations with multiple teams and product lines.

---

### best-practices-T5 — Review Governance Setup (20 pts)

**Goal**: Walk through the JFrog UI to confirm all four governance layers are in place.

**Checklist**:

- [ ] **Artifactory → Repositories**: three-tier naming convention (local/remote/virtual) confirmed
- [ ] **Administration → Groups**: `{nickname}-team` has members
- [ ] **Administration → Permissions**: `{nickname}-perm` scopes to correct repos and Group
- [ ] **Administration → Projects**: project contains your repos and team

**Governance architecture summary**:

```
User
  └── Group: {nickname}-team
        └── Permission Target: {nickname}-perm
              └── Repositories: {nickname}-npm-bp-local / -virtual
                    └── Project: {nickname}-project (resource isolation boundary)
```

This is a manual verification task — complete the checklist and mark it done.

---

## Troubleshooting

**Group not visible after creation**: Refresh the page; the Groups list sometimes has a few seconds of delay.

**Can't select repositories in Permission Target**: Confirm repositories were created (T1 complete); filter by nickname prefix when searching.

**Project Key conflict**: JFrog Project Keys are unique per instance. If your nickname has hyphens (e.g. `alice-123`), remove them (`alice123`); if still conflicting, append a number.

**No permission to create Groups or Projects**: Requires Admin or Manage Groups/Projects role. Ask the instructor to grant elevated permissions.
