# Implementation Plan: ProtonMail Bridge systemd Autostart

- **Task**: 52 - protonmail_bridge_systemd_autostart
- **Status**: [COMPLETE]
- **Effort**: 1-2 hours
- **Dependencies**: None (NixOS changes handled in ~/.dotfiles task #24)
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: general

## Overview

This plan covers verification, integration testing, and documentation for the ProtonMail Bridge systemd user service. The actual NixOS/home-manager configuration is being implemented separately in `~/.dotfiles` (task #24 there). This plan focuses on post-configuration verification, email stack integration testing, and creating comprehensive documentation for the setup.

### Research Integration

Research report identified:
- ProtonMail Bridge v3.21.2 installed at `/home/benjamin/.nix-profile/bin/protonmail-bridge`
- Existing mbsync configured for 127.0.0.1:1143, Himalaya for 127.0.0.1:1025
- Password stored in GNOME keyring via `secret-tool`
- Recommended `--noninteractive --log-level info` flags for service operation

## Goals and Non-Goals

**Goals**:
- Verify systemd user service is running correctly after NixOS changes
- Confirm email stack integration (mbsync, himalaya) works with the service
- Create comprehensive documentation in the nvim config docs/
- Document troubleshooting procedures and failure recovery

**Non-Goals**:
- Modifying home.nix (handled in ~/.dotfiles)
- Running `home-manager switch` (user responsibility)
- Changing ProtonMail Bridge authentication or account settings

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Service not starting after NixOS changes | High | Low | Detailed verification phase with clear diagnostics |
| Keyring access failure | Medium | Low | Document re-authentication procedures |
| Port binding conflict | Medium | Low | Check for conflicts before verification |

## Implementation Phases

### Phase 1: Service Verification [COMPLETED]

**Goal**: Verify the ProtonMail Bridge systemd user service is running correctly after the user applies NixOS changes.

**Prerequisites**: User must have already run `home-manager switch` after adding service to ~/.dotfiles/home.nix.

**Tasks**:
- [x] Check service status with `systemctl --user status protonmail-bridge`
- [x] Verify service is enabled with `systemctl --user is-enabled protonmail-bridge`
- [x] Confirm ports 1143 (IMAP) and 1025 (SMTP) are listening with `ss -tlnp`
- [x] Check service logs with `journalctl --user -u protonmail-bridge --no-pager -n 50`
- [x] Verify vault.enc exists at `~/.config/protonmail/bridge-v3/vault.enc`

**Timing**: 15 minutes

**Files to create**:
- None (verification only)

**Verification**:
- Service shows "active (running)" status
- Both ports show in `ss` output bound to 127.0.0.1
- Logs show successful startup without authentication errors

---

### Phase 2: Email Stack Integration Testing [COMPLETED]

**Goal**: Verify mbsync and himalaya work correctly with the running ProtonMail Bridge service.

**Tasks**:
- [x] Test mbsync connection with `mbsync -V logos-inbox`
- [x] Test full sync with `mbsync logos`
- [x] Test himalaya list with `himalaya envelope list -a logos`
- [x] Test himalaya email read (pick any email from list)
- [x] Verify SMTP by checking himalaya config can connect

**Timing**: 15 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- mbsync reports successful sync without connection errors
- himalaya lists emails from logos account
- No SSL/TLS or authentication errors in any operation

---

### Phase 3: Create Documentation [COMPLETED]

**Goal**: Create comprehensive documentation for the ProtonMail Bridge systemd setup in the nvim config docs.

**Tasks**:
- [x] Create `docs/protonmail-bridge-setup.md` with overview and architecture
- [x] Document service management commands (start, stop, restart, status)
- [x] Document log inspection commands
- [x] Add verification checklist section
- [x] Cross-reference with mbsync and himalaya configuration

**Timing**: 30 minutes

**Files to create**:
- `docs/protonmail-bridge-setup.md` - Main documentation file

**Verification**:
- Documentation covers all service management scenarios
- Commands are accurate and tested
- Architecture diagram or description included

---

### Phase 4: Create Troubleshooting Guide [COMPLETED]

**Goal**: Document failure recovery procedures and common issues.

**Tasks**:
- [x] Document service startup failure diagnosis
- [x] Document keyring/authentication recovery procedure
- [x] Document port conflict resolution
- [x] Document re-authentication steps via CLI and GUI
- [x] Add common error messages and solutions

**Timing**: 30 minutes

**Files to modify**:
- `docs/protonmail-bridge-setup.md` - Add troubleshooting section

**Verification**:
- All documented recovery procedures are accurate
- Error messages match actual ProtonMail Bridge output
- Re-authentication steps are complete and correct

## Testing and Validation

- [x] Service survives reboot (test after documentation complete)
- [x] mbsync scheduled sync still works (if cron/timer configured)
- [x] Documentation accurately reflects current setup
- [x] All commands in documentation produce expected output

## Artifacts and Outputs

- `docs/protonmail-bridge-setup.md` - Comprehensive setup and troubleshooting documentation
- `specs/052_protonmail_bridge_systemd_autostart/summaries/implementation-summary-YYYYMMDD.md` - Implementation summary

## Rollback/Contingency

If verification fails:
1. Check service logs for specific error messages
2. Verify home.nix changes were applied correctly in ~/.dotfiles
3. Confirm `home-manager switch` completed successfully
4. Test interactive mode: `protonmail-bridge --cli` then run `info` command
5. If authentication lost: re-run GUI or CLI login flow

Documentation can be created even if service has issues - the troubleshooting section will be especially valuable in that case.
