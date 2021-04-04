# Mutt
Use macros? Miss focus? **Mutt** (**M**acro **U**pdate **T**arget **T**ool) is a *World of Warcraft* add-on that provides slash commands that can patch (silently edit) a chosen macro, replacing the targets of **/target** or **/assist**; or substituting the party or raid position of a targeted group member for macro option @ targets.
### WoW Classic & @focus:

By letting you update a macro before combat with the name of a targeted mob, Mutt can help overcome the lack of **/focus** and **@focus** in Classic by using **/target**. However, you'll only get useful results if the mob name is unique in your targeting range; if there are multiple mobs with the same name you’ll see a tab-target-like behavior as each call to /target rotates through them. This behavior is normal for Classic, it's not a problem with Mutt.
### Examples:

The **/umt** amd **/uma** commands (at their simplest) just update the first occurrence of **/target** and **/assist** in a macro to the name of your current target.

If you have a macro named "chain cc" that looks like:

```
/target Murloc Hunter
/cast Fear()
/targetlasttarget
```
...and you're targeting a Defias Bandit, then:
```
/umt "chain cc"
```

... will update your "chain cc" macro to be:
```
/target Defias Bandit
/cast Fear()
/targetlasttarget
```
 

**/uma** works exactly the same, updating **/assist** in your macros.


**/mutt **works similarly but is only intended to adjust @ targets to the positions of party or raid members.

Assuming you have a macro named "hlight" that looks like:
```
/cast [@raid4] Holy Light
```
...and that you're targeting the player in position raid23, then
```
/mutt hlight
```
...would patch the hlight macro to look like:
```
/cast [@raid23] Holy Light
```

The Mutt commands observe macro options, so you can even do:
```
/mutt [button:3] hlight
/stopmacro [button:3]
/cast [@raid2] Holy Light
```

...to have a macro patch itself(!)

### WARNING!

**Be advised!** If you try this macro-patching-itself trick, make absolutely certain that the Mutt slash-command is the first line of the macro, and that you use macro options to make it mutually-exclusive from the rest of your macro or else your results will be unpredictable.

 
### Modifiers:

Mutt modifiers can be added after the name of the macro. If no modifiers are provided, Mutt will patch the first @ target that it finds (unless it's part of a **/mutt** command, see below) and set it to the group position of the currently targeted group member.

Adding numbers after the name of the macro tells Mutt to change those instances of @ target in the macro, so:
```
/mutt hlight 2
```

...would change the second @ target in your macro. In case you want to change the last @ target and don't want to count how many come before it, Mutt understands negative numbers to mean that you want to count backward from the end, so:
```
/mutt hlight -2
```

...would change the next-to-last @ target in your macro.

Placing **all** as an modifier in your Mutt command tells Mutt to change all instances of @ target in your macro to what Mutt received as the current target (more on targeting below).

By default Mutt will replace everything after the selected @ target but there are cases, like macros where you want the target's target, where you wouldn't want that. Mutt provides the **keep*something*** modifier to let you preserve a target chain after your initial target (I say preserve here, but Mutt will add the provided chain if it's not already present). Since having to specify a modifier like **keeptargetpettarget** would eat valuable macro space, Mutt understands **k** plus combinations of **p** and **t** to be a short version of this modifier, so **ktpt** could be used in place of the modifier above.

By default Mutt won't count or change any @ target that is part of a Mutt command in a macro. You can change this behavior if you wish by including the mutt modifier, and the @ target in your Mutt commands will be treated like those in the rest of your macro. Please note the warning above that unpredictable/undesired behavior may result from this.
### Targeting:

The group position that Mutt writes in your updated macro is determined by your current target or by macro options in your Mutt command if you provide them, so if you used:
```
/mutt [@focus] hlight
```

...and your focus target was the player in raid position 14, then raid14 would be the new target written in your macro.
### More Examples:

Update all @ targets (including those in Mutt slash commands) in macro off-tank to the group position of my current target:
```
/mutt off-tank all mutt
```
Update second @ target in macro off-tank to current target's group position on a regular click, on a shift/ctrl/alt click changes all @ targets (except those in Mutt slash commands) in macro main-tank to the group position of my current focus:
```
/mutt [nomodifier] off-tank 2; [@focus] main-tank all
```

Macro shield-mutt: Cast Sacred Shield on player if not in group, on group member if in a group, update macro target on middle mouse button click:
```
/mutt [button:3] shield-mutt 2
/stopmacro [button:3]
/cast [nogroup:raid/party, @player] [@raid1] Sacred Shield
```
 

Macro weaken-mutt: Cast Curse of Weakness on group member's target, update macro target on middle mouse button click, preserving the "target" suffixed to the updated macro target.
```
/mutt [button:3] weaken-mutt keeptarget
/stopmacro [button:3]
/cast [@raid1target] Curse of Weakness
```
 
### Caveats:

- Mutt works by editing macros, and macros can't be edited in combat.
- The default WoW macro editing window doesn't understand anything about Mutt, so if you run Mutt commands with the WoW macro window open you won't see any changes to your macro and WoW will overwrite any of Mutt's changes when the window closes.
- Mutt has been updated to use @ rather than target= in macro options, if your existing macro has instances of target= in it you'll see an alert at patch time that they are being replaced to use @ targeting instead.
- If your macro has spaces in the name then you must enclose the name in double-quotes, a-la:
```
/mutt [button:3] "mutt macro" 2
```

### FAQ:
*What would I use this for?*
- Mutt is intended to make up for some of the deficiency of only having one way in WoW macros (focus) to have an unchanging but reset-able target in a macro. Mutt permits you to have macros for spells that you know you'll be casting repeatedly on the same target (Remove Curse, Beacon of Light) and a way of adjusting the targets at the start of the raid or between combats.
