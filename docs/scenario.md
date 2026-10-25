# Build Dangerous — Scenario

*An Amstrad CPC game. Mode 1 (320×200, 4 colours). 16×16 sprites.*

## Logline

Every building in town is getting a grand opening — speeches, ribbons, a crowd waiting to walk in. Every building is also a death trap, because the owners cut every corner they could find. Inspector **Thanos** has sixty seconds of dignity and one job: find every trap before the ribbon gets cut, or the crowd walks into a building that bites back.

## The Inspector

**Thanos** is immortal. He cannot actually die — he can only be *embarrassed*. Every bite, shock, drowning, and flattening is survivable, but it costs him **Reputation Energy**. He's held the Municipal Hazard Inspection contract for longer than anyone can remember, and the contract is renewed on vibes and a clean record. Zero out his energy and the contract — not his life — is what ends. He walks it off, swears, and keeps the same stony expression regardless of what just happened to him.

Personality: deadpan, weary, professionally unimpressed by physics. He's seen it all, twice, and it's always Tuesday.

## The Hook (per building)

**Outdoor scene:** an evening grand opening — the building's name lit up on the facade, the owner on a small stage out front, mid-speech, scissors in hand, ribbon strung across the door. A queue of excited townsfolk fidgets on the pavement. A big dial/clock ticks down — the owner's patience, and the crowd's. This is the pressure clock for the level: when it hits zero, the ribbon gets cut whether Thanos is ready or not.

**Indoor scene:** cut to Thanos stepping into the lobby. The player takes over. He has to walk every floor, spot every rigged fixture, and disable it before the clock outside runs out — all while the building actively tries to kill him.

## Core Fantasy

Thanks to a lifetime of claims adjusting, Thanos has a sixth sense: hazards *look* almost normal, but not quite — a crooked sign, a damp patch, a coil of wire that shouldn't be visible. The player is trained to read the same tells.

**Disarming a hazard always hurts — that's the job, not a failure state.** Finding a trap and actually deactivating it means getting bitten, shocked, drenched, or otherwise comically wrecked; the vignette plays — eating into the clock while the crowd waits outside — and the hazard is gone. He's immortal: it costs him time, not energy. There is no clean way to defuse a trap. The only real mistake is **declaring a room safe when it isn't** — walking through, deciding (rightly or wrongly) that it's clear, and marking it off the inspection sheet. If a live hazard is still sitting in that room when he does, that's a **Miss**: the only thing that costs Reputation Energy, and a mark on the building's tally that follows him to the end-of-level report.

Thanos can re-enter any room and re-check it as many times as he likes — there's no penalty for taking his time or backtracking. The building's exit only unlocks once **every room has been marked safe at least once**, whether he actually cleared it or just called it and moved on. So the real choice each room presents isn't "disarm or don't" — it's "go find every hazard in here and spend the clock getting wrecked by each one, or call it safe now, save the time, and gamble on a Miss."

The game is equally a spot-the-difference puzzle and a risk/reward management game: hazards are seeded into otherwise-identical room layouts, and most of the challenge is reading tells and deciding how thoroughly to check each room against the outside clock, not reflexes alone.

## The Twelve Ways to Get Got

Each is a short (1–2 second) animated gag, not a death — Thanos always gets back up, dusts off, and his expression never changes.

1. **Bitten** — a "decorative" floor grille is actually a crate of the owner's "guard ferret." Thanos yelps and shakes his leg like a cartoon dog.
2. **Electrocuted** — bare wire taped behind a light switch. He lights up like a sign, hair standing on end, and the lights in the room flicker in sympathy.
3. **Drowned** — a mop closet door hides a burst water main; opening it floods the room and Thanos bobs to the surface wearing a rubber duck he didn't bring.
4. **Hit on the head** — a chandelier/vending machine/scaffolding plank, held up by a single zip tie, lets go right on cue. He flattens like an accordion, then pops back up.
5. **Cut in half** — an elevator with doors that close a half-second too early. He steps through at the wrong moment and separates clean at the waist — top half keeps talking into his radio until the bottom half catches up.
6. **Impaled** — a "soft landing" cushion over an open shaft is actually a bed of nails with a cushion cover stapled over it.
7. **Squashed** — a trash compactor room with a door helpfully labelled "NOT A TRASH COMPACTOR."
8. **Incinerated** — a gas leak meets a pilot light; he goes up in a comic fireball and walks out of frame as a walking briquette, smoke still rising.
9. **Frozen solid** — a walk-in freezer door with a broken release handle; he's a block of ice for a beat, including a visible thought-bubble icicle, before shattering free.
10. **Poisoned (green gas)** — a leaking chemical drum under a "cleaning supplies" sign; he turns green, wobbles, and deflates like a week-old balloon.
11. **Sucked up** — an industrial vacuum/garbage chute with no grille; he gets inhaled, bounces through the ductwork (sound effect optional), and is spat out two rooms over.
12. **Catapulted through the roof** — a frayed elevator counterweight cable lets go under him; he launches straight up through the ceiling and the rooftop scenery, then falls back into frame a beat later, plaster dust and pigeon feathers included.

Each hazard has a matching "tell" — a visual detail slightly wrong in that room — that the player can learn to recognise (a floor grille with scratch marks, a wire with no conduit, a sign hung crooked over a hole, etc.).

## Distractions (they cost time, never health)

Nothing physical — just people, eating the clock while the crowd waits outside.

- **Tasha (Τασία), his wife, phones** two or three times per building, at random moments (never in the first 20 seconds). He has to take it: her face pops up in a window in the corner of the building, and she wants something — is he coming to dinner, the tap is dripping, does he know what day it is, her mother wants a word, is he wearing the blue shirt, can he pick up milk. Two possible answers. The right one ("Yes dear. Eight. Sharp.") wraps the call up fast and scores a little; the wrong one ("Time is relative, dear.") — or saying nothing — gets a longer reply and a rant ("I gave you the best 300 years of my life, Thanos!"). Six calls go round through the campaign.
- **Bambis (Μπάμπης), the owner's nephew**, an influencer, paces a floor in some rooms. Walk into him and it's a selfie for his twelve followers: two camera flashes and "like and subscribe" while Thanos stands there. One selfie per visit to a room; with good timing (or a few steps up a staircase while he passes underneath) he can be dodged.

## The Buildings (campaign order, rising difficulty)

1. **Sunny Vale Apartments** — tutorial building. Small, few floors, one or two hazard types per room, generous clock. Teaches movement, inspecting, and the energy/clock pressure.
2. **Big Box Mall** — wide floors, escalators (they carry Thanos on their own — up or down, never the wrong way), one of every trap type, first appearance of timed/moving hazards (e.g. the guillotine elevator doors).
3. **Grand Hotel** — tall, vertical play (stairs/lift shafts matter), introduces fire and water hazards together, tighter clock.
4. **Mega Hospital** — chemical and biohazard themed, escalators between the wards, fast hazards, crowded rooms, decoy "fake" hazards that look dangerous but are safe (bluffing the player's pattern sense).
5. **Hard Knock Hotel & Casino** — a rock-themed casino-hotel: slot machines and escalators on the casino floor, card tables, a stage with amp stacks (the pyrotechnics are a trap), signed guitars on every wall, the rock-star suite, a rooftop pool. One of every trap, neon walls.
6. **The Skyscraper** (finale) — every hazard type appears at least once, the owner is visibly impatient on the outside-scene clock, and the twist lands here (see below).

## The Twist

The owner of the Skyscraper isn't just cheap — he's deliberately under-building to fail the structure after the opening, for the insurance payout, timed to a packed lobby. Thanos can find the paperwork taped under a stairwell (an "evidence" pickup: Fire on it like a trap, but it costs nothing and never counts as a live hazard when signing off). The ending branches on how the inspection actually went, not on a separate confrontation scene:

- **Good ending:** every room marked safe, energy held, clock beaten — Thanos walks back out. If he found the paperwork, he serves the owner a demolition order instead of letting him cut the ribbon, the insurance scam is over, and the crowd cheers for the inspector. If he didn't, every building opens safely and nobody asks about the paperwork. A zero-Miss clean sweep gets its own extra beat of applause.
- **Bad ending:** clock runs out or energy zeroes — the ribbon gets cut on schedule, the crowd files in, and the last image is Thanos's inspection contract getting stamped "TERMINATED" while chaos starts behind him. Deadpan narration, not gore — this is a comedy.

## Tone & Presentation

- Visual comedy over violence — every hazard is a slapstick beat, not gore. Think Looney Tunes physics on 8-bit hardware.
- Thanos's face never changes. The joke is that nothing fazes him; the energy bar is the only thing that visibly reacts.
- Dry, deadpan one-line text captions on each hit ("Filed under: dog bite. Again.") rather than voice or long cutscenes — keeps it readable and cheap to produce.
- Outdoor ribbon-cutting scene reused as a template across all six buildings (owner sprite/name/dialogue swapped), keeping asset cost low while giving each level a bookend.

## Win / Lose per Building

Every room must be marked safe before the exit unlocks — that part isn't optional or graded, it's the gate. What's graded is *how* he got there:

- **Win (clean/good exit):** every room marked safe, energy above zero, exit reached before the outside clock runs out. The fewer Misses on the building's tally, the better the grade — a zero-Miss run is a "clean sweep" and the best version of this ending.
- **Partial/soft-fail:** the outside clock runs out before every room is marked, but energy is still above zero and at least half the rooms are signed off — owner is embarrassed into a short delay, small reputation penalty, proceed to next building anyway.
- **Fail:** energy hits zero at any point, or the clock runs out with fewer than half the rooms signed off — contract-ending outcome for that run (game over, or a "fired, try again" restart depending on difficulty mode).

## Scoring

- Small points for each hazard actually found and disarmed — it costs energy and a vignette either way, so the points are the only thing softening that cost, and they reward thoroughness over guessing.
- A larger points penalty for every **Miss** (a room marked safe with a live hazard still in it), matching its bigger energy cost — misses are the expensive mistake, not the slapstick hits.
- End-of-building bonus tied to how much clock time remained, how much energy was left, and a flat bonus for a zero-Miss "clean sweep" — rewards careful, thorough play over either recklessness or dawdling.
