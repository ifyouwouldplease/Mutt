-- Mutt - Macro Update Target Tool
-- Tuill of Pagle
-- Revisions:
-- 0.1 - Initial copy of Telegraph (by Tuill) source
-- 0.2 - First running test
-- 0.3 - Shared as private beta
-- 0.32 - Undid move of combat lockdown test
-- 0.40 - Upload as alpha to WowAce
-- 0.52 - Fix to support macro names with spaces
-- 0.53 - Fixed incorrect pattern match when Mutt called with no options
-- 0.54 - Clarification in "no target=" error message
-- 0.55 - Update interface for 3.3 and refresh libs
-- 0.56 - Update this revision list, Change Curse name to "Mutt Macro Patcher" and refresh libs
-- 0.57 - Bump interface version and refresh libs
-- 0.58 - Update for 4.3 and refresh libs
        -- Update for new behavior of EditMacro, using nil for texture param to keep previous icon
        -- Change to @ notation from target= for option targeting on macro rewrite
        -- Added alert at patch time if target= notation is being replaced in user's macro
        -- Change docs to refer to @ rather than target=
-- 0.59 - Update for Mists, bump interface and refresh libs
-- 0.60 - Replace usage of GetNum[Party|Raid]Members() with GetNumGroupMembers()
-- 0.61 - Bump interface and refresh libs
-- 0.62 - Adjust test for no @targets in macro, thanks to addon testers on Greymane-US
-- 0.63 - Bump interface and refresh libs
-- 0.64 - Bump interface and refresh libs
-- 0.65 - Update for Warlords, bump interface and refresh libs
-- 0.66 - Added 'name' member to Ace3 options table to fix nil error
        -- Added double call to InterfaceOptionsFrame_OpenToCategory to fix
        -- glitch where on 1st call that only ESC > Interface frame is shown
-- 0.67 - Added a UI group to the config page to help with readability
        -- Increased font size to medium on config page
        -- Added button and pop-up for example macro at top of config page for TL;DR
-- 0.68 -- Bump interface for 6.2, refresh libs
-- 0.69 -- Bump interface for 7.0, refresh libs
-- 0.70 -- Bump interface for 7.2, refresh libs
-- 0.71 -- Bump interface for 7.3, refresh libs
-- 0.72 -- Bump interface for 8.0, refresh libs
-- 0.73 -- Bump interdace for 8.1, refresh libs
-- 0.74 -- Bump interface for 1.13 Classic, refresh libs
-- 0.75 -- Fix download archive names, added name tag in pkgmeta
-- 0.76 -- Try to correct Classic version # in Twitch client
-- 0.77 -- ibid.
-- 0.78 -- Add /umt and /uma commands to update /target and /assist targets
-- 0.79 -- Updated Interface Option /umt example macro to end with /targetlasttarget
-- 0.80 -- Bump interface for 1.13.3 Classic, refresh libs
-- 0.81 -- Bump interface for 1.13.4 Classic, refresh libs, switch to markdown changelog file
-- 0.82 -- Bump interface for 1.13.5 Classic, refresh libs
-- 0.83 -- Bump interface for 1.13.6 Classic, refresh libs
-- 0.85 -- Bump simply to see if package auto-builds yet in post-Overwolf milieu
-- 0.86 -- Bump and tag to confirm Overwolf fix for auto build
-- 0.87 -- No-op bump and tag to confirm Overwolf fix for auto build
-- 0.88 -- Bump interface for 1.13.7 TBC Classic pre-pre-patch, refresh libs
-- 0.89 -- Bump interface for 2.5.2, refresh libs
-- 0.90 -- Bump interface for 2.5.3, refresh libs
-- 0.91 -- Bump interface for 2.5.4, refresh libs
-- 0.92 -- Bump interface for 3.4.1, refresh libs
-- 0.93 -- Bump interface for 1.14.4 classic, 3.4.3 wrath classic, refresh libs
-- 0.94 -- Bump interface for 1.15.0 classic, 3.4.3 wrath classic, refresh libs, re-add .pkgmeta to troubleshoot Curse changelog
-- 0.95 -- Initial release for Cata Classic, refresh libs. UPDATE - Bump interface for Classic-Classic. UPDATE - Bump again 1.15.4.

-- Many sources of inspiration (== blatant copy/pastes)
-- All comments by Tuill
-- I recommend a Lua-aware editor like SciTE that provides syntactic highlighting.

-- No global for now
-- Mutt = LibStub("AceAddon-3.0"):NewAddon("Mutt", "AceConsole-3.0")

-- local scope identifier for performance and template-ability
local ourAddon = LibStub("AceAddon-3.0"):NewAddon("Mutt", "AceConsole-3.0")

-- local scope identifiers for util functions
local strlower = strlower
local tonumber = tonumber
local string_gsub = string.gsub
local table_insert = table.insert
local asMutt = 1
local asTarget = 2
local asAssist = 3

-- Fetch version & notes from TOC file
local ourVersion = GetAddOnMetadata("Mutt", "Version")
local ourNotes = GetAddOnMetadata("Mutt", "Notes")

-- Multi-line string for the help text, color codes inline
local helpUsing = [[Examples:

|cff999999# The /umt amd /uma commands (at their simplest) just
# update the first occurrance of /target and /assist in a
# macro to the name of your current target.
# If you have a macro named "chain fear" that looks like:|r
/target Murloc Hunter
/cast Fear()
/targetlasttarget

|cff999999# ...and you're targeting a Defias Bandit, then:|r
/umt "chain fear"

|cff999999# ... will update your "chain fear" macro to be:|r
/target Defias Bandit
/cast Fear()
/targetlasttarget

|cff999999# /uma works exactly the same, updating /assist in your macros.

# /mutt works similarly but is only intended to adjust @ targets to
# the positions of party or raid members.

|cff999999# Assuming you have a macro named "hlight" that looks like:|r
/cast [@raid4] Holy Light

|cff999999# ...and that you're targeting the player in position raid23, then|r
/mutt hlight

|cff999999# ...would patch the hlight macro to look like:|r
/cast [@raid23] Holy Light

|cff999999# Mutt observes macro options, so you can even do:|r
/mutt [button:3] hlight
/cast [nobutton:3,@raid2] Holy Light

|cff999999# ...to have a macro patch itself(!)|r

|cffEE4444# WARNING!|r
|cff999999
# Be advised! If you try this macro-patching-itself trick,
# make absolutely certain that the Mutt slash-command is the
# first line of the macro, and that you use macro options to
# make it mutually-exclusive from the rest of your macro
# or else your results will be unpredictable.|r

Modifiers:
|cff999999
# Mutt modifiers can be added after the name of the macro. If
# no modifiers are provided, Mutt will patch the first @
# that it finds (unless it's part of a /mutt command, see
# below) and set it to the raid position of the currently
# targeted raid member.

# Adding numbers after the name of the macro tells Mutt to
# change those instances of @ in the macro, so:|r
/mutt hlight 2
|cff999999
# ...would change the second @ in your macro. In case
# you want to change the last @ and don't want to count
# how many come before it, Mutt understands negative numbers
# to mean that you want to count backward from the end, so:|r
/mutt hlight -2
|cff999999
# ...would be the next-to-last @ in your macro.

# Placing|r all |cff999999as an modifier in your Mutt command tells Mutt to
# change all instances of @ in your macro to what Mutt
# received as the current target (more on targeting below).

# By default Mutt will replace everything after the selected
# @ but there are cases, like macros where you want the
# target's target, where you wouldn't want that. Mutt provides
# the |rkeep|cffBBBB88something|cff999999 modifier to let you preserve a target chain
# after your initial target (I say preserve here, but Mutt will
# add the provided chain if it's not already present).
# Since having to specify a modifier like |rkeeptargetpettarget|cff999999
# would eat valuable macro space, Mutt understands |rk|cff999999
# plus combinations of |rp|cff999999 and |rt|cff999999 to be a short version of this
# modifier, so |rktpt|cff999999 could be used in place of the modifier above.

# By default Mutt won't count or change any @ that are
# part of a Mutt command in a macro. You can change this
# behavior if you wish by including the|r mutt |cff999999modifier, and the
# @ in your Mutt commands will be treated like those in
# the rest of your macro. Please note the |cffCC8888warning |cff999999above that
# unpredictable/undesired behavior may result from this.

# The raid position that Mutt writes in your updated macro
# is determined by your current target or by macro options
# in your Mutt command if you provide them, so if you used:|r
/mutt [@focus] hlight
|cff999999
# ...and your focus target was the player in raid position 14,
# then raid14 would be the new target written in your macro.
|r
More Examples:
|cff999999
# Update all @ (including those in Mutt slash commands)
# in macro |cffBBBB88off-tank|cff999999 to the group position of my current target:|r
/mutt off-tank all mutt
|cff999999
# Update second @ in macro |cffBBBB88off-tank|cff999999 to current target's
# group position on a regular click, on a shift/ctrl/alt click
# change all @ (except those in Mutt slash commands) in
# macro |cffBBBB88main-tank|cff999999 to the group position of my current focus:|r
/mutt [nomodifier] off-tank 2; [@focus] main-tank all
|cff999999
# Macro |cffBBBB88shield-mutt|cff999999: Cast Sacred Shield on player if not in
# group, on group member if in a group, update macro target
# on middle mouse button click:|r
/mutt [button:3] shield-mutt 2
/stopmacro [button:3]
/cast [nogroup:raid/party, @player] [@raid1] Sacred Shield
|cff999999
# Macro |cffBBBB88weaken-mutt|cff999999: Cast Curse of Weakness on group
# member's target, update macro target on middle mouse
# button click, preserving the "target" suffixed to the
# updated macro target:
|r
/mutt [button:3] weaken-mutt keeptarget
/stopmacro [button:3]
/cast [@raid1target] Curse of Weakness

|r

Caveats:

* Mutt works by editing macros, and macros can't be edited in
combat.

* The default WoW macro editing window doesn't understand
anything about Mutt, so if you run Mutt commands with the
WoW macro window open you won't see any changes to your
macro and WoW will overwrite any of Mutt's changes when the
window closes.

* If your macro has spaces in the name then you must enclose
the name in double-quotes, a-la:
|r
/mutt [button:3] "mutt macro" 2
]]

ourAddon.muttExampleText = [[
/mutt [button:3] hlight
/stopmacro [button:3]
/cast [@raid2] Holy Light
]]

ourAddon.muttUmtExampleText = [[
/umt [button:3] "chain cc"
/stopmacro [button:3]
/target Defias Trapper
/cast Fear()
/targetlasttarget
]]

ourAddon.muttUmaExampleText = [[
/uma [button:3] "follow lead"
/stopmacro [button:3]
/assist Hitches
/cast Shadowbolt()
]]

StaticPopupDialogs["MUTT_EXAMPLE"] = {
  text = 'Example - Update macro named "hlight"',
  button1 = "OK",
  OnShow = function (self, data)
    self.editBox:SetMultiLine(true)
    self.editBox:SetHeight(90)
    self.editBox:DisableDrawLayer("BACKGROUND")
    self.editBox:SetText(ourAddon.muttExampleText)
    self.editBox:HighlightText()
    self:Show()
  end,
  hasEditBox = true,
  hasWideEditBox = true,
  editBoxWidth = 220,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MUTT_UMT_EXAMPLE"] = {
  text = 'Example - Update macro named "chain cc"',
  button1 = "OK",
  OnShow = function (self, data)
    self.editBox:SetMultiLine(true)
    self.editBox:SetHeight(90)
    self.editBox:DisableDrawLayer("BACKGROUND")
    self.editBox:SetText(ourAddon.muttUmtExampleText)
    self.editBox:HighlightText()
    self:Show()
  end,
  hasEditBox = true,
  hasWideEditBox = true,
  editBoxWidth = 220,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MUTT_UMA_EXAMPLE"] = {
  text = 'Example - Update macro named "follow lead"',
  button1 = "OK",
  OnShow = function (self, data)
    self.editBox:SetMultiLine(true)
    self.editBox:SetHeight(90)
    self.editBox:DisableDrawLayer("BACKGROUND")
    self.editBox:SetText(ourAddon.muttUmaExampleText)
    self.editBox:HighlightText()
    self:Show()
  end,
  hasEditBox = true,
  hasWideEditBox = true,
  editBoxWidth = 220,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

-- Ace3 options table
-- RegisterOptionsTable can take a function ref for the options arg
-- Taking advantage of this in case we decide to dynamically adjust
-- at use-time
local function ourOptions()
  local options = {
   name = "Mutt",
   type = 'group',
   args = {
    general = {
      type = 'group',
      name = "Settings",
      args = {
            header1 =
            {
                order = 1,
                type = "header",
                name = "",
            },
            version =
            {
                order = 2,
                type = "description",
                name = "Version " .. ourVersion .. "\n",
            },
            usage =
            {
                type = "group",
                name = "Usage",
                desc = "Usage",
                guiInline = true,
                order = 3,
                args =
                {
                    example =
                    {
                        order = 4,
                        type = "execute",
                        name = "Example /mutt Macro",
                        desc = "",
                        descStyle = "inline",
                        func = function() StaticPopup_Show("MUTT_EXAMPLE") end,
                    },
                    example2 =
                    {
                        order = 5,
                        type = "execute",
                        name = "Example /umt Macro",
                        desc = "",
                        descStyle = "inline",
                        func = function() StaticPopup_Show("MUTT_UMT_EXAMPLE") end,
                    },
                    example3 =
                    {
                        order = 6,
                        type = "execute",
                        name = "Example /uma Macro",
                        desc = "",
                        descStyle = "inline",
                        func = function() StaticPopup_Show("MUTT_UMA_EXAMPLE") end,
                    },
                    about =
                    {
                        order = 7,
                        type = "description",
                        name = ourNotes.."\n",
                        fontSize = "medium",
                    },
                    about2 =
                    {
                        order = 8,
                        type = "description",
                        name = helpUsing,
                        fontSize = "medium",
                    },
                },
            },
        },
    }, -- end using
   }, -- top args
  } -- end table
 return options
end

function ourAddon:OnInitialize()

    local ourConfig = LibStub("AceConfig-3.0")
    local ourConfigDialog = LibStub("AceConfigDialog-3.0") -- For snapping into the ESC menu addons list

    ourConfig:RegisterOptionsTable("Mutt", ourOptions)

    self.optionsFrames = {}
    self.optionsFrames.general = ourConfigDialog:AddToBlizOptions("Mutt", "Mutt", nil, "general")

    -- Create slash commands
    self:RegisterChatCommand("mutt", "SlashHandler")
    self:RegisterChatCommand("umt", "SlashHandler2")
    self:RegisterChatCommand("uma", "SlashHandler3")
--  self:RegisterChatCommand("muttdebug", "MDebugHandler")
end


function ourAddon:SlashHandler(input)
  if input == "" then
    self:HowTo()
  else
    self:TargetUpdate(asMutt, input)
  end
end

function ourAddon:SlashHandler2(input)
  if input == "" then
    self:HowTo()
  else
    self:TargetUpdate(asTarget, input)
  end
end

function ourAddon:SlashHandler3(input)
  if input == "" then
    self:HowTo()
  else
    self:TargetUpdate(asAssist, input)
  end
end

function ourAddon:HowTo()
  -- Show addon config dialog as help if no args, we verify we're not in combat
  -- so it should be too annoying (better than just a blurt in the chat pane...)
    if InCombatLockdown() then
      self:Print("In combat, declining to show Mutt help dialog.")
    else
      -- Cheeseball fix for issue with 1st call to display Interface > Mutt
      -- frame only showing ESC menu, just call twice-in-a-row
      InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
      InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
    end
end

-- Functions defined in a do block so we could have pseudo-static variables
do

  function ourAddon:TargetUpdate(flag, args)
  -- Declare variables
    local ourArgs, alterMutt, targetCount, ourTarget, macroIndex
    local inaParty, inaRaid, groupMember, totalMembers
    local groupName, targetingSelf, targetingSelfPet, petTag
    local flagToSlash = {"/mutt", "/umt", "/uma" }

    -- Initialize and object we'll use to represent this /mutt command
    local muttCall = { macroMutts = 0, groupNumber = nil, countTargets = 0, alterAll = false, ourMacro = nil, ourMuttlines = {}, alterTargets = {}, preserveTag = false, mt = {}, altering = "@" }
    setmetatable(muttCall, muttCall.mt)
    -- Extract macro to patch and target
    ourArgs, ourTarget = SecureCmdOptionParse(args)
    --self:Print("Saw ourArgs as: >>"..ourArgs.."<<")
    if ((ourArgs == nil) or (ourArgs == "")) then
      --self:Print("ourArgs was nil or empy string...")
      -- No macro, so stop here
      -- If we're calling with macro options, ourArgs will
      -- be nil/empty in cases where there's no tests-true option,
      -- so correct behavior here is to silently return (do nothing).
      return
    end
    -- Check for combat
    if InCombatLockdown() then
      self:Print("Can't adjust macros in combat.")
      return
    end

    -- Step over args provided, pick out the macro name first
    if ourArgs:find('"') then
      _, _, muttCall.ourMacro, ourArgs = ourArgs:find('^(%b"")%s*(.*)')
      muttCall.ourMacro = muttCall.ourMacro:gsub('"', "")
    else
      _, _, muttCall.ourMacro, ourArgs = ourArgs:find('^(%S+)%s*(.*)')
    end
    if ourArgs:len() > 0 then
      --self:Print("DEBUG - Call to mutt was:>>"..args.."<<, stanza chosen by opts was: >>"..ourArgs:len().."<<")
      for step in ourArgs:gmatch("%S+") do
        step = strlower(step)
        if tonumber(step) then
          table_insert(muttCall.alterTargets, tonumber(step))
        elseif step == "all" then
          muttCall.alterAll = true
        elseif step == "mutt" then
          if flag == asMutt then
              alterMutt = true
          else
              self:Print("|cffeeee33Warning: |rmutt |cffccccccoption only valid for the |r/mutt |cffcccccccommand, ignoring.|r")
          end
        elseif step:find("^k") then
          if flag == asMutt then
              --self:Print("DEBUG - Saw the k-option to preserve suffix...")
              local longStyle
              step, longStyle = step:gsub("keep", "")
              if not (longStyle > 0) then
                -- Short style of modifier, need to expand.
                step = step:gsub(".", { k = "", p = "pet", t = "target" })
              end
              muttCall.preserveTag = step
          else
              self:Print("|cffeeee33Warning: |rkeep|cffcccccc / |rk |cffccccccoptions only valid for the |r/mutt |cffcccccccommand, ignoring.|r")
          end
        end
      end
    end
    -- Target not provided or not understood, default to player's target
    if not (ourTarget) then
      ourTarget = "target"
    end
    -- No recognized target
    if not (UnitExists(ourTarget)) then
      self:Print("|cffeeee33Warning: |cffccccccNothing targeted or can't determine target, no update to macro |r"..muttCall.ourMacro)
      return
    end
    macroIndex = GetMacroIndexByName(muttCall.ourMacro)
    if macroIndex == 0 then
      -- Didn't find such a macro, notify the user.
      self:Print("|cffeeee33Warning: |cffccccccCan't find macro |r"..muttCall.ourMacro.."|cffcccccc, did you create it before using |r"..flagToSlash[flag].." |cffcccccc(or is it an add-on macro not a WoW macro)..?")
      return
    end

    -- Begin Mutt-relevant section
    if flag == asMutt then
        -- Addon Lesson #102:
        --	A call to UnitInParty("player") always returns true,
        --  so we test for party1 to see if we're in a party
        inaParty = UnitExists("party1")
        inaRaid = UnitInRaid("player")
        targetingSelf = UnitIsUnit(ourTarget, "player")
        targetingSelfPet = UnitIsUnit(ourTarget, "playerpet")

          -- Choose biggest grouping if none specified
        if inaRaid then
            groupMember = UnitPlayerOrPetInRaid(ourTarget)
            totalMembers = GetNumGroupMembers()
            groupName = "raid"
        elseif inaParty then
            groupMember = UnitPlayerOrPetInParty(ourTarget)
            totalMembers = GetNumGroupMembers()
            groupName = "party"
        else
            self:Print("Not in a group, can only reassign target to group positions.")
            return
        end

        if (groupMember or targetingSelfPet) and (not UnitIsPlayer(ourTarget)) then
          -- targeting a pet
          petTag = "pet"
        else
          petTag = ""
        end

        -- If we're here we have an existing target
        if groupMember or targetingSelf or targetingSelfPet then
          local targetGUID = UnitGUID(ourTarget)
          for step = 1, totalMembers do
            -- This builds a name like 'party2' or 'raid4pet'
            muttCall.groupNumber = groupName..step..petTag
            if UnitGUID(muttCall.groupNumber) == targetGUID then
              -- Found the target's group name, no need to search more
              break
            else
              muttCall.groupNumber = nil
            end
          end
          -- Special case in a party group for player and the player's pet
          if (not muttCall.groupNumber) and (targetingSelf or targetingSelfPet) then
              self:Print("You and your pet have no party# ID, defaulting to 'player"..petTag.."'")
              muttCall.groupNumber = "player"..petTag
          end

          if not muttCall.groupNumber then
            -- Bad!!
            self:Print("Didn't get a valid group position for unit.")
          else
            local initial, targetEquals, remainder

            -- Get current info from provided macro
            local ourName, ourTexture, ourMacroBody, isLocal  = GetMacroInfo(macroIndex)

            -- Munge /mutt lines unless option is set to include them in count
            if not alterMutt then
              -- We get string.gsub for free, so make the most of it
              -- Read the Lua docs for string.gsub and the index event if you don't understand these lines
              muttCall.mt.__index = ourAddon.muttMunge
              ourMacroBody = string_gsub(ourMacroBody, "/mutt%s+([^\n]+)", muttCall)
            end

            -- Substitute old-style target= for @ in the macro body if present.
            --- I guess this is bad manners to ham-handedly make a style change to
            --- the user's macro, but I don't see any return on investing the time
            --- to implement a way to catch, save and replace possibly mixed usage
            --- of target= and @ in the same positions where they were used, using
            --- only Lua's string pattern matching </handwashing>
            -- Test for use of target=
            if strmatch(ourMacroBody, "target=") then
              self:Print("Substituting uses of target= with @ in macro "..ourName)
              ourMacroBody = string_gsub(ourMacroBody, "target=", "@")
            end
            -- Calling string.gsub for the side-effect of getting a match count
            _, targetCount = string_gsub(ourMacroBody, "(@)(%w+)", {})
            if (targetCount > 0) then
              if (#muttCall.alterTargets == 0) and (not muttCall.alterAll) then
                -- No explicit @ specified, default to 1st
                table_insert(muttCall.alterTargets, 1)
              end

              -- Step over targets to change, reconciling any negative numbers
              local tempTable = {}
              for ourKey, ourValue in pairs(muttCall.alterTargets) do
                if ourValue < 0 then
                  ourValue = targetCount + 1 + ourValue
                end
                -- Eliminate out-of-bounds target instances,
                -- Build a working table with keys for valid target instances
                if (ourValue < 1) or (ourValue > targetCount) then
                  self:Print("Invalid target instance of "..ourValue.." provided, discarding...")
                else
                  tempTable[ourValue] = true
                end
              end
              muttCall.alterTargets = tempTable

              -- Do the substitution
              muttCall.mt.__index = ourAddon.muttTargetSub
              ourMacroBody = string_gsub(ourMacroBody, "@(%w+)", muttCall)

              -- De-munge /mutt lines if we did so
              if not alterMutt then
                ourMacroBody = string_gsub(ourMacroBody, "/mutt%s+([^\n]+)", muttCall.ourMuttlines)
              end

              -- Save our work
              EditMacro(macroIndex, ourName, nil, ourMacroBody, isLocal)
            else
              self:Print("Couldn't find a predefined target (@something) in macro "..ourName)
            end
          end
        else
          -- We're targeting something outside our group
          self:Print("We're not in a group with "..ourTarget)
          return
        end
    -- End Mutt-relevant section
    else
        -- Calling as /ut or /ua
        local slashAcquire
        if flag == asAssist then
            slashAcquire = "/assist"
        elseif flag == asTarget then
            slashAcquire = "/target"
        end
        muttCall.altering = slashAcquire.." "
        -- local targetGUID = UnitGUID(ourTarget)
        local unitName, _ = UnitName(ourTarget)
        muttCall.groupNumber = unitName
        -- Get current info from provided macro
        local ourName, ourTexture, ourMacroBody, isLocal  = GetMacroInfo(macroIndex)
        -- ourMacroBody = string_gsub(ourMacroBody, "target=", "@")
        -- Calling string.gsub for the side-effect of getting a match count
        _, targetCount = string_gsub(ourMacroBody, "("..slashAcquire..")(%s+)", {})
        if (targetCount > 0) then
          if (#muttCall.alterTargets == 0) and (not muttCall.alterAll) then
            -- No explicit @ specified, default to 1st
            table_insert(muttCall.alterTargets, 1)
          end

          -- Step over targets to change, reconciling any negative numbers
          local tempTable = {}
          for ourKey, ourValue in pairs(muttCall.alterTargets) do
            if ourValue < 0 then
              ourValue = targetCount + 1 + ourValue
            end
            -- Eliminate out-of-bounds target instances,
            -- Build a working table with keys for valid target instances
            if (ourValue < 1) or (ourValue > targetCount) then
              self:Print("Invalid target instance of "..ourValue.." provided, discarding...")
            else
              tempTable[ourValue] = true
            end
          end
          muttCall.alterTargets = tempTable

          -- Do the substitution
          muttCall.mt.__index = ourAddon.muttTargetSub
          ourMacroBody = string_gsub(ourMacroBody, slashAcquire.."%s+([^\n]+)", muttCall)


          -- Save our work
          EditMacro(macroIndex, ourName, nil, ourMacroBody, isLocal)
        else
          self:Print("Couldn't find a an instance of "..slashAcquire.." in macro "..ourName)
        end
    end -- End calling as /ut or /ua
  end

  function ourAddon.muttMunge(slashCall, muttTarget)
    slashCall.macroMutts = slashCall.macroMutts + 1
    muttKey = "###"..slashCall.macroMutts
    slashCall.ourMuttlines[muttKey] = "/mutt "..muttTarget
    return "/mutt "..muttKey
  end

  function ourAddon.muttTargetSub(slashCall, prevTarget)
    slashCall.countTargets = slashCall.countTargets + 1
    local foo = slashCall.countTargets
    local ourReturn = slashCall.groupNumber
    if (slashCall.alterTargets[foo]) or (slashCall.alterAll) then
      if slashCall.preserveTag then
        ourReturn = ourReturn..slashCall.preserveTag
      end
      ourAddon:Print("|cffccccccPatching target instance |r"..slashCall.countTargets.."|cffcccccc in macro |r"..slashCall.ourMacro.."|cffcccccc from |r"..slashCall.altering..prevTarget.."|cffcccccc to |r"..slashCall.altering..ourReturn)
      return slashCall.altering..ourReturn
    else
      return nil
    end
  end

end
