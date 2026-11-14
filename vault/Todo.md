---
class: state
validity: current
type: guide
---

# To-do list

Back to [Summary](SUMMARY.md). Large plans are in the [Roadmap](Roadmap.md).

## Testing

- [ ] **Play Colosseum 1 yourself.** The tests used a CPU-controlled Warrior, so a human must tune the difficulty, especially the Blinded Lord.
  - In `BlindedLord.gd`: boss HP, `phase2_speed_mult` and `phase2_cooldown_mult`.
  - In `ChemicalPool.gd`: `TICK` and `TICK_DAMAGE`.
  - In `StoryManager.gd`: `MAX_ATTACKERS`.
- [ ] **Play Colosseum 2 yourself**, especially the Architect Chorus's Elevator Shake and Blasphemy Caeser's phase 2.
  - In `BlasphemyCaeser.gd`: `P1_HP` / `P2_HP`, pattern cooldowns and damage.
  - In `ArchitectChorus.gd`: HP, `JOLT_EVERY` and the slam numbers.
  - In `ChemicalPool.gd`: `LAVA_TICK_DAMAGE`.
  - In `WarriorData.gd`: the Warrior buff numbers and the sword growth (`sword_power_damage`, `sword_power_size`).
- [ ] **Play Colosseums 3 and 4 yourself.** Check the Forge Mother, the Architect's Golem, both Shining choices, and the Void Massacre (VIGOROUS may still be too hard).
  - Boss numbers: HP / patterns in `ForgeMother.gd`, `ArchitectsGolem.gd`, `VoidMassacre.gd`.
  - The Shining choice: `_apply_void_mod` in `StoryManager.gd` (weak 0.7x, strong 1.35x HP and 1.25x damage).
- [ ] Play Story with the new Story-only buffs (Warrior and Architect, 2026-11-10): Story may be easier now, especially Colosseum 4 (Architect) and Colosseum 5 (both heroes buffed). Bosses were buffed to match (1.35x HP, attack more often, faster; same damage): check boss fights don't drag on too long. See [Game content](Content.md).
- [ ] **Play the Boss Extensions yourself** (Story board > BOSS EXTENSIONS): tune the 16 new enemies and 5 new bosses (`scripts/story/ext/`). Check the 3 Void Horrids at once are fair, the Forge Father's phase 2 speed, the Caeser's Grave souls, and that the Warrior AND the Architect can both beat each extension. See [Story Mode](StoryMode.md).
- [ ] **Fight Kokusen yourself** (Character Select > Enemy Test): is 2500 HP too long a fight? Are Meteor Rain and Closed World fair to dodge? Does flight feel good against every fighter (especially the flying APHA Architect)?
- [ ] Play the 3 Fights-mode bosses yourself and tune them (`HP`, pattern cooldowns and damage, `phase2_*` in `scripts/enemies/bosses/`).
- [ ] Check whether Kharlemings can still stand on top of each other on level 5 (their name tags overlap).
- [ ] Test on a real iPhone 13: loading, touch controls, and audio after the tap.
- [ ] **Web on phones: check the page no longer reloads by itself** (reported 2026-11-09: it reloaded 1-3 minutes after opening). Play 5+ minutes on a phone, through several Story areas. See [Performance](Performance.md).
- [ ] Play the new Story levels (5, 7, 11, 14, 18, 21-23, 25, 33) and tune the new soldier weapons (`ArmedSoldier.gd`: HP per weapon, `FRONT_GUARD` of the great shield, arrow damage).
- [ ] Check the optional Shining level (32) both ways and by skipping it, then play level 34.
- [ ] **Graphics setting on an iPhone 11:** pick FAST, turn on the FPS counter (Sandbox), and check the fight stays at 40+ FPS, also during ultimates and big Story boss fights. Also check that POTATO and REAL look right on PC. See [Performance](Performance.md).
- [ ] **iPhone web after the memory fixes (2026-11-10):** play 5+ minutes with Story + the Map Catalogue. Check: no crash, sound plays after the tap, and the sound stops when you leave Safari or lock the phone. See [Performance](Performance.md).
- [ ] Try the new **Touch UI Size** slider (Settings) on a phone and pick a good default.
- [ ] **Play Colosseum 5** (levels 35-50). Nothing there was beaten yet, by CPU or human:
  - The 8 bosses (HP / patterns in `scripts/story/c5/*.gd`; shared hard-boss rules in `C5Boss.gd` and `BossBrain.gd`).
  - The Sun finale: throwing the bomb and the platform escape (`SunFinale.gd`: `PLATFORMS`, `WALL_SPEED`, `FALL_DAMAGE`). Check every gap can be jumped by both heroes.
  - The CPU partner: does it keep up, help enough, not get in the way (`Companion.gd`). Since 2026-11-10 it is a HARD CPU with a G Gauge and 1 flask: check it isn't too strong now. Only tested by CPU-vs-CPU runs (it used ultimates 5 times in 30 s as the Warrior).
  - The nerfed Devilish Grin and Pained One (coin flip TAILS): still a threat, or too easy now?
  - The Executor's memory fog (reversed controls, 3.5 s): fun or too annoying?
- [ ] **3D on phones / web:** play a few Story levels on an iPhone and in the web build: 3D cutscenes, 3D menus and the 3D boss-map backgrounds cost more. Check FPS and memory (no reload / crash). Fast renders 3D at half resolution, Potato turns 3D off. See [3D](ThreeD.md).
- [ ] **Look at the 3D boss models yourself** and say which ones need to look more like their 2D art (`scripts/three_d/Boss3D.gd`).
- [ ] **Play DemiLand (level 63) yourself:** are the 3 bosses fair (the CPU couldn't beat them), is it 5-15 minutes, are the roll / stamina costs fun, is the night dark enough? Numbers: bosses in `scripts/story/demi/`, camps / CamTons / arenas in `DemiWorld.gd`, roll + stamina in `scripts/souls/SoulsRules.gd`. The run is saved at CamTons since 2026-11-13: check that resuming works.
- [ ] **Play The Enlightened Chase (51-62) yourself.** Check: the bombards are dodgeable, Counselor healing isn't annoying, Camel Charge is fair, the First Prime (300 HP) and the Enlightened One (180 + 210 HP, falling objects, phase 2 lasers / light balls) after the nerf. Numbers in `scripts/story/c6/`.
- [ ] **Play the Achievement update yourself:** unlock a few in Versus and Story and check the pop-up, the grid, the badges on the board and the Colosseum 5 SOLO button. Only the CPU and scripted tests have run it so far. Is the Multiversal achievement (all of C5 solo, x4 challenges) too hard? Tuning is in `Achievements.gd`.
- [ ] **Blasphemy Caeser after the nerf** (210 + 260 HP, sword +45%): too easy now?
- [ ] Play Story with **Deep Faith Payoff** (Warrior / Architect: +20% HP, 3 flasks, -15% cooldowns, stacks on the older Story buff): is Story now too easy? Tune `DEEP_FAITH_*` in `StoryManager.gd`.
- [ ] **Play The Caves (levels 64-66) yourself:** are the speeds (560 / 620 / 690 px/s), the jump height and the low rocks fair? Is the "chasm then low rock" combo in cave 3 doable with S-dive? Numbers in `scripts/story/slide/CaveSlide.gd` (`TIERS`, `JUMP_V`, `CEIL_GAP`). Only a bot played them.
- [ ] **Read the new Story dialogue in play:** the C1-5 openings and boss talks, and the Enlightened Chase lines from the lore (incl. the Storm talk after the last fight). Lines in `scripts/story/dialogue/StoryDialogue.gd`.
- [ ] **Listen to the audio yourself:** the 41 music tracks, the 24 new Kenney sound effects and the dialogue voice blips. Say which tracks or volumes need a change. See [Audio](Audio.md).
- [ ] Record the Needle's voice lines (`audio/voice/needle_shaw`, `needle_adino`, `needle_guarana`, `needle_getgood`).

## Website

- [ ] Decide on the domain: keep universalshowdown.com or register universalbeatdown.com.

## Game

- [ ] More playable fighters in Story Mode (Warrior and Architect; the Anti Architect stays Versus-only).
- [ ] Real sprite or texture art, to replace the art that the code draws.
- [ ] Record real voice lines for Minos and Sisyphus (`audio/voice/`).
- [ ] Nicer art for Geyron's wings (they read a bit like a fan of spikes).
- [ ] Story Mode extras: difficulty settings, a level timer or score, unlockables.

## Performance

- [ ] Pool the other projectiles: Triangle Bomb, Void Goo, Oil Puddle, Throne, Nightmare Heart, Helper Minion.
