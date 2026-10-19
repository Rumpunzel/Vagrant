# Rules Reference

Quick reference of the rules as implemented. Source of truth for intent: WIP 5.

## Attributes
- **Guts**, **Blood**, **Nerves**: 2d6 each. A double grants a rare origin.
- **Injuries** lower all attributes by their total.

## Breath dice
- Start: d4, d6, d8, d10, d12.
- Rolled for saves and fights. A die above the rolled attribute is **lost** (still counts for the result).
- Catching breath: exhaust one die type, recover all others. The last die type can't be exhausted.

## Saves
- Roll chosen breath dice; highest ≥ difficulty = success. Margin = difference.

## Fight exchange
- Both sides roll at once. **Threat** = highest breath die.
- Player picks: fight or flee, a weapon (or unarmed), a stance (armed only), breath dice (≥ 1).
- Monster: rolls all breath dice, first usable weapon. Its **attack** sets the stance: Guts (default), or Nerves aimed at a fixed player attribute (Lurker: Guts). Without a usable weapon (natural weapons always count) it threatens with Guts.
- **Vantage**: winner = threat difference; loser and tie = 0. Abilities may change it (Veteran: ×2).
- **Stances** work with the vantage; on a tie, each side's stance works with its own full threat instead (not changed by abilities). Only when > 0:
  - **Guts**: damage dealt + vantage.
  - **Blood**: damage taken − vantage.
  - **Nerves**: chosen foe attribute − vantage for this exchange (before dice are checked).
- **Unarmed** = Guts, weapon damage 0. **Flee** = Blood, always escapes after damage.
- **Order** (each step is told and applied in turn): rolled dice / threat → Nerves → losses and wield checks → (shields, disabled) → armour → injuries → outcome.
- **Damage** = highest usable weapon die → stance → armour reduction, at least 0.
- Injuries and losses apply after the exchange.
- **End:** player flees → fled; otherwise 0 breath dice → that side is out (both = draw). Entering a fight with 0 breath = lost.

## Weapons
- Wield check: weapon die > wield attribute (default Guts) → can't wield, **mark** that face.
- Marked face = 0 damage. Marking a marked face → **ruined** (visible, unusable).
- **Natural weapons** (monsters without weapons): breath dice are weapon dice, always usable (even when lost), never marked.

## Armour
- Order: wield check first; only wielded dice meet armour.
- Blocking piece: weapon die result in its blocked results → that die deals 0 (threat unchanged; natural weapons too).
  - Helmet 5, 10 · Chainmail 3, 6, 9, 12 · Plate 2, 4, 6, 8, 10, 12. Pieces stack.
- Per blocked die: attacker marks weapon at that face (not natural weapons); one random blocking armour piece marks that result. Marked results still block; blocking a marked result again ruins the piece.
- Gambeson: damage taken −1, applied last.

## Shields
- **Disabled for now**: carried, but not raised. Rule H below is kept in the resolver until a mechanic is found that fits after the wield checks.
- Shield die d6 (Buckler), d8 (Round Shield), d10 (Kite Shield), d12 (Pavise). Only the first usable shield is raised.
- Wield check first: shield die > Guts → not raised, that face is marked. Marked face = no effect. Marking a marked face → ruined.
- Raised: subtract the shield result from the foe's **highest die** (breath or weapon; tie → weapon), at least 0.
- The lowered die still counts with its lowered value (threat, damage). Natural weapons: one reduction lowers threat and damage.
- Losses, wield checks and armour still use the **rolled** face.

## Origin abilities (implemented)
- **Adventurer**: +1 to all attributes.
- **Peasant**: of the breath dice lost, only the highest is lost (equal results: the smaller die).
- **Veteran**: +1 weapon die (a d10 sword rolls 2d10, only one counts, chosen after unnerving: the one dealing the most damage (marked faces and armour-blocked results deal 0), then the one harming the weapon least (harmless < marked < ruined), then the lower result; only the chosen die can mark); double vantage.
- All other abilities are text only for now.

## Modifiers
- Profiles list equipment plus modifiers applied when handed out, e.g. **battered** = 2 random faces marked (never ruins). Characters: one list per kind; monsters: one list for all their equipment.
