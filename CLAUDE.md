# CLAUDE.md - Libs-Social

This file provides guidance to Claude Code when working with the Libs-Social addon.

## Project Overview

**Libs-Social** is a comprehensive social management addon for World of Warcraft that provides friend/guild tracking, social blocking features, and auto-accept functionality. It evolved from the Libs-DataBar-Friends plugin into a standalone addon.

## Reference Addons

Study these addons for implementation patterns:

- `C:\Users\jerem\OneDrive\WoW\Examples\Socialite` - Ace3-based social addon with advanced tooltip
- `C:\Users\jerem\OneDrive\WoW\Examples\Frenemy` - Complex social tracking with LibQTip
- `C:\code\Libs-DataBar\Plugins\Libs-DataBar-Friends` - Original plugin this addon is based on

## Architecture

```
Libs-Social/
├── CLAUDE.md                 # This file
├── Libs-Social.toc           # Addon manifest
├── Libs-Social.lua           # Main addon, AceAddon framework
├── Core/
│   ├── Database.lua          # AceDB setup, defaults
│   ├── Events.lua            # Social event handlers
│   └── Friends.lua           # Friend/Guild/BNet data management
├── Features/
│   ├── Blocking.lua          # Block duels, invites, requests
│   ├── AutoAccept.lua        # Auto-accept from friends
│   └── FriendTreatment.lua   # Guild/community as friends logic
├── UI/
│   ├── DataBroker.lua        # LDB data source
│   ├── Tooltip.lua           # Enhanced tooltip rendering
│   ├── Options.lua           # AceConfig options
│   └── MinimapButton.lua     # LibDBIcon integration
└── libs/                     # Embedded Ace3 libraries
```

## Key Patterns

### LibDataBroker-1.1 Data Source

```lua
local LDB = LibStub('LibDataBroker-1.1')
local dataObject = LDB:NewDataObject("Lib's Social", {
    type = 'data source',
    text = 'Loading...',
    icon = 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon',
    OnClick = function(frame, button) ... end,
    OnTooltipShow = function(tooltip) ... end,
})
```

### AceDB-3.0 Profile Management

```lua
local defaults = {
    profile = {
        blocking = { duels = true, ... },
        autoAccept = { partyFromFriends = true, ... },
        friendTreatment = { guildAsFriends = true, ... },
    },
}
self.db = LibStub('AceDB-3.0'):New('LibsSocialDB', defaults, true)
```

### AceConfig-3.0 Options Panel

```lua
local options = {
    name = "Lib's Social",
    type = 'group',
    args = { ... },
}
LibStub('AceConfig-3.0'):RegisterOptionsTable('LibsSocial', options)
```

## WoW API Events

### Blocking Events
- `DUEL_REQUESTED` - Duel blocking
- `PET_BATTLE_PVP_DUEL_REQUESTED` - Pet duel blocking
- `PARTY_INVITE_REQUEST` - Party invite blocking
- `BN_FRIEND_INVITE_RECEIVED` - Friend request blocking
- `QUEST_ACCEPT_CONFIRM` - Shared quest blocking

### Friend Data Events
- `FRIENDLIST_UPDATE` - Character friends list changed
- `BN_FRIEND_INFO_CHANGED` - Battle.net friend info changed
- `BN_FRIEND_ACCOUNT_ONLINE` - Friend came online
- `BN_FRIEND_ACCOUNT_OFFLINE` - Friend went offline
- `GUILD_ROSTER_UPDATE` - Guild roster changed
- `GROUP_ROSTER_UPDATE` - Group roster changed

## Friend Check Functions

### Is Player a Friend?

```lua
-- Character friend
local isFriend = C_FriendList.IsFriend(name)

-- Battle.net friend (check by name)
local numBNetFriends = BNGetNumFriends()
for i = 1, numBNetFriends do
    local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
    if accountInfo and accountInfo.gameAccountInfo then
        local characterName = accountInfo.gameAccountInfo.characterName
        if characterName == name then
            return true
        end
    end
end

-- Guild member
local numGuildMembers = GetNumGuildMembers()
for i = 1, numGuildMembers do
    local guildName = GetGuildRosterInfo(i)
    if Ambiguate(guildName, 'none') == name then
        return true
    end
end
```

## Blocking Logic

When a request comes in (duel, party invite, etc.):

1. Check if blocking is enabled for this type
2. Check if sender is in friend list (should not block)
3. Check friendTreatment settings:
   - If guildAsFriends is true, check if sender is guild member
   - If communityAsFriends is true, check if sender is community member
4. If sender passes any friend check, allow the request
5. Otherwise, auto-decline the request

## Slash Commands

- `/social` or `/libssocial` - Open options panel
- `/social block` - Toggle blocking
- `/social accept` - Toggle auto-accept

## Integration

### With Libs-DataBar
When Libs-DataBar is available, the addon registers as a LibDataBroker data source that can be displayed on the databar.

### Standalone
When no databar is available, uses LibDBIcon for minimap button access.

## Testing

1. Test blocking: Have someone send you a duel request
2. Test friend exception: Add tester to friends, verify requests not blocked
3. Test guild treatment: Enable guildAsFriends, verify guild members not blocked
4. Test auto-accept: Have friend send party invite, verify auto-accepted
5. Test LDB display: Verify friend counts update correctly
