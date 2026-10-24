# Rules Reference

Quick reference of the rules as implemented. Source of truth for intent: WIP 5.

## Attributes
- **Guts**, **Blood**, **Nerves**: 2d6 each. A double grants a rare origin.
- **Injuries** lower all attributes by their total.
- **Incapacitation:** after an injury that leaves any attribute at 0 or below, make a Guts save against the total of all injuries; failing = incapacitated. In fights: the player picks dice on a save page (also while fleeing) or gives in (counts as failed, no dice rolled), monsters roll all their breath dice. Outside fights: not yet (TODO).

## Breath dice
- Start: d4, d6, d8, d10, d12.
- Rolled for saves and fights. A die above the rolled attribute is **lost** (still counts for the result).
- Catching breath: exhaust one die type, recover all others. The last die type can't be exhausted.

## Saves
- Roll chosen breath dice; highest ≥ difficulty = success. Margin = difference.

## Fight exchange
- Both sides roll at once (breath, weapon and shield dice), then **commit**, judged by their scores before unnerving: the weapon die to strike with (free, forced or none) and whether to raise the shield (free or forced). The player commits on one panel (weapon die options, a shield switch that starts on when no forcing is needed, "Strike!"); it is shown only when a weapon die needs forcing, the player asked to pick among several (Veteran), or they carry a shield.
- **Threat** = highest of the breath dice and the *free* weapon / shield dice committed, minus the overshoot (how far above the wield score) of each forced die. Forced dice (and marked weapon faces) don't count themselves. Can be below 0; overshoots add up.
- Player picks: fight or flee, a weapon (or unarmed), a stance (armed only), breath dice (≥ 1).
- Monster: rolls all breath dice, first usable weapon. Its **attack** sets the stance: Guts (default), or Nerves aimed at a fixed player attribute (Lurker: Blood). Without a usable weapon (natural weapons always count) it threatens with Guts. Its **tactics** decide on its gear, with settings per monster: weapon (`max_overshoot`, `force_marked_faces`), shield (`max_overshoot`), armour (spares its pieces). By default it never forces (Lurker: forces its Knife as far as needed).
- **Vantage**: winner = threat difference; loser and tie = 0. Abilities may change it (Veteran: ×2).
- **Stances** work with the vantage; on a tie, each side's stance works with its own full threat instead, if above 0 (not changed by abilities). Only when > 0:
  - **Guts**: damage dealt + vantage.
  - **Blood**: damage taken − vantage.
  - **Nerves**: choose a foe attribute. Breath dice rolled with it are also lost if above score − vantage; gear wielded with it (weapon, shield) is **dropped** if its die came up above score − vantage: no strike or block, gone for the rest of the fight (picked up afterwards). Threat and commitments stay; forced gear that is dropped has still cost its threat.
- **Unarmed** = Guts, weapon damage 0. **Flee** = Blood, always escapes after damage.
- **Order** (each step is told and applied in turn, per side; authored in `exchange_steps.tres`): player commit → rolled dice / threat → tie, if any → Nerves (and dropped gear) → breath dice lost → weapon wear → Guts / Blood vantage → shields → armour → injury + incapacitation save → outcome. A side loses its breath dice before its incapacitation save.
- **Damage** = highest usable weapon die → stance → armour reduction, at least 0.
- Injuries and losses apply after the exchange.
- **Afterwards:** a monster that lost (or failed its save) stays incapacitated; the story decides what happens to it.
- **End:** player incapacitated while fleeing → lost; player flees → fled; otherwise 0 breath dice or incapacitated → that side is out (both = draw). Entering a fight with 0 breath = lost.

## Weapons
- A weapon die within the wield attribute (default Guts) on an unmarked face is **free**: it strikes and threatens, no mark.
- **Forcing** (committed after the roll): a die above the wield attribute strikes, costs its overshoot in threat and marks one face per point of overshoot (the rolled face, then the next higher ones; none left → ruined). A marked face within the wield attribute strikes without threat cost or threatening, then the next higher face is marked. Not used: nothing.
- With several weapon dice (Veteran) the best free die strikes, or the one the player picks (always offered when forcing is possible, or when asked for).
- **Marking** (all equipment): marking a marked face marks the next higher unmarked one; none left → **ruined** (destroyed for good). Marks can be restored while resting (later).
- **Natural weapons** (monsters without weapons): breath dice are weapon dice, always usable (even when lost), never marked.

## Armour
- Order: wield check first; only wielded dice meet armour.
- Blocking piece: weapon die result in its blocked results → that die deals 0 (threat unchanged; natural weapons too).
  - Helmet 5, 10 · Chainmail 3, 6, 9, 12 · Plate 2, 4, 6, 8, 10, 12. Pieces stack.
- Armour is worn, not voluntary: a blow it can block is blocked. Marked results still block.
- Per blocked die: the attacker's weapon marks that face (not natural weapons), and one piece takes it, picked by the **defender**:
  - among pieces whose fitting result is unmarked → that result is marked;
  - if every fitting result is marked → any fitting piece, which marks its next higher result or is ruined (no higher result left: ruined, but it still blocks).
  - The player is asked when there is more than one option; monsters (and the player with only one) wear down the piece with the most unmarked results and prefer marking to ruining.
- Gambeson: damage taken −1, applied last.

## Shields
- Shield die d6 (Buckler), d8 (Round Shield), d10 (Kite Shield), d12 (Pavise), rolled with the other dice. Only the first usable shield.
- **Raising is committed** after the roll, before the blow is known. A free raised die (marked faces too) threatens; **above the wield attribute** (default Guts) it must be forced: costs its overshoot in threat, no further wear.
- Raised: takes its result off the foe's blow (at most all of it), after Guts/Blood vantage and before the Gambeson.
- Marked only when it actually blocks damage: the rolled face (a marked face marks the next higher one; none left → ruined).

## Origin abilities (implemented)
- **Adventurer**: +1 to all attributes.
- **Peasant**: of the breath dice lost, only the highest is lost (equal results: the smaller die).
- **Veteran**: +1 weapon die (a d10 sword rolls 2d10, only one counts, committed before unnerving: the best free die not blocked by the foe's armour, or the one the player picks; only the chosen die can mark); double vantage.
- All other abilities are text only for now.

## Modifiers
- Profiles list equipment plus modifiers applied when handed out, e.g. **battered** = 2 random faces marked (never ruins). Characters: one list per kind; monsters: one list for all their equipment.
