# CLAUDE.md - Lib's Social

This file provides guidance to Claude Code when working with the Libs-Social addon.

## Project Overview

**Lib's Social** is a social management addon for World of Warcraft that provides friend/guild/BNet tracking, social blocking features, and auto-accept functionality. It registers as a LibDataBroker data source for display in any databar addon.

## Architecture

```
Libs-Social/
├── Libs-Social.toc              # Interface 120000, SavedVariables: LibsSocialDB
├── Libs-Social.lua              # AceAddon main + LibAT Logger
├── Core/
│   ├── Database.lua             # AceDB defaults and initialization
│   ├── Events.lua               # Social event handlers (friend list, BNet, guild)
│   └── Friends.lua              # Friend/Guild/BNet data caching and lookup
├── Features/
│   ├── Blocking.lua             # Block duels, invites, friend requests, shared quests
│   ├── AutoAccept.lua           # Auto-accept party invites from friends
│   └── FriendTreatment.lua      # Treat guild/community members as friends
├── UI/
│   ├── DataBroker.lua           # LDB data source + tooltip with BNet/Friends/Guild sections
│   ├── Tooltip.lua              # Helper functions: ColorName, GetStatusString, ColorLevel
│   ├── Options.lua              # AceConfig options panel
│   └── MinimapButton.lua        # LibDBIcon integration
└── libs/                        # Embedded Ace3 + LDB + LibDBIcon (populated by packager)
```

## Key Design Decisions

### Tooltip (Major Feature)
The tooltip shows three fully-detailed sections:
- **Battle.net**: BattleTag (stripped #number), class-colored character name, realm, zone, AFK/DND status
- **Friends**: Class-colored name, difficulty-colored level, class, zone, mobile indicator
- **Guild**: Class-colored name sorted by rank, rank name, zone, mobile indicator
- Deduplicates BNet friends (dual-indexed by accountID and character name)

### Friend Treatment System
- `IsTreatedAsFriend(name)` checks: character friend OR BNet friend OR guild member (if `guildAsFriends` enabled)
- All blocking/auto-accept features use this unified check

### Blocking Logic
When a request arrives: check if blocking enabled for that type → check if sender is treated as friend → if friend, allow; if not, decline.

### Logging
- Logger initialized in `OnInitialize()`: `LibAT.Logger.RegisterAddon('LibsSocial')`
- `self:Log(message, level)` helper wraps logger access
- Slash command responses (`self:Print()`) remain as AceConsole chat output

### API Compatibility (12.x)
- Queue check in AutoAccept uses `GetLFGQueueStats(i)` for i=1..4 (replaces removed `NUM_LE_LFG_CATEGORYS`/`GetLFGMode`)

## Display Formats

Cycleable via right-click: `combined` | `friends` | `guild` | `realid` | `detailed`

## Click Behaviors

| Button | Action |
|--------|--------|
| Left Click | Open Friends Frame |
| Shift+Left | Open Options |
| Right Click | Cycle display format |
| Middle Click | Open Guild Frame |

## WoW API Events

### Friend Data
- `FRIENDLIST_UPDATE`, `BN_FRIEND_INFO_CHANGED`, `BN_FRIEND_ACCOUNT_ONLINE/OFFLINE`
- `GUILD_ROSTER_UPDATE`, `GROUP_ROSTER_UPDATE`

### Blocking
- `DUEL_REQUESTED`, `PET_BATTLE_PVP_DUEL_REQUESTED`, `PARTY_INVITE_REQUEST`
- `BN_FRIEND_INVITE_RECEIVED`, `QUEST_ACCEPT_CONFIRM`

## Slash Commands

- `/social` or `/libssocial` — Open options
- `/social block` — Toggle blocking
- `/social accept` — Toggle auto-accept

## Reference Addons

- `C:\Users\jerem\OneDrive\WoW\Examples\Socialite` — Ace3 social addon with advanced tooltip
- `C:\Users\jerem\OneDrive\WoW\Examples\Frenemy` — Complex social tracking with LibQTip
- `C:\code\Libs-DataBar\Plugins\Libs-DataBar-Friends` — Original plugin this evolved from

## Testing

1. Test blocking: Verify duels/invites from non-friends are declined
2. Test friend exception: Verify requests from friends are allowed through
3. Test guild treatment: Enable `guildAsFriends`, verify guild members not blocked
4. Test auto-accept: Verify friend party invites are auto-accepted (and not when queued)
5. Test tooltip: Verify BNet/Friends/Guild sections render with class colors
6. Test LDB: Verify friend counts update on login/logout events
