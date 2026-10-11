# DeckForever (addon)

Steam Deck presets for **World of Warcraft: Forever**. Pick a preset, keep it or let it revert
after 15 seconds, done. Every preset was measured on a Steam Deck OLED: frame rate, 1% lows and
battery draw, in the open world and in a capital.

**Designed to go with the [DeckForever app](https://github.com/eliog/DeckForever)**, which installs
Battle.net and WoW: Forever on the Steam Deck, adds them to the Steam library, and can repair, back
up or uninstall the setup. The app gets the game running; this addon tunes it. The addon also works
on its own if you set up the game another way.

## Presets

| Preset | Frame rate | What you get | Deck TDP limit | Battery life* |
|---|---|---|---|---|
| **Battery** | 30 fps | lightest look, steady everywhere, even in cities | 8–10 W | ~4.3 h |
| **Balanced** | 45 fps | Battery plus real shadows and shading | 10 W | ~3.7 h |
| **Max FPS** | 60 fps | sharp, longer view, full power (cities ~50 fps) | Off | ~2.8 h |
| **Max Quality** | 30 fps | everything high: lighting, shadows, reflections. Plug in; not for cities | Off | ~2.5 h |

\*Steam Deck OLED, questing. Capitals are limited by power on any handheld; Battery at 30 fps is
the preset that stays smooth there.

## Features

- **Controller friendly.** D-pad moves a focus ring, A selects, B closes, shoulders switch tabs.
  Large buttons, no dropdowns, nothing that needs hovering.
- **Safe to try.** Your own settings are saved before the first preset; **Restore previous** puts
  them back. Each apply shows a 15-second Keep / Revert dialog. Nothing is changed in combat.
- **Customize** any preset setting with steppers that use the game's own names. Changes show in
  gold; one button resets a preset.
- **Steam Deck tab**: the Quick Access settings (refresh rate, frame limit, TDP) that go with each
  preset. An addon can't change those, so the tab tells you what to set.
- **UI scale** for the 7-inch screen. The game locks its own UI Scale option in Forever; the addon
  scales the interface instead.
- **Reload UI** button in the window, and a **minimap button** with a quick menu.
- Raid and battleground settings (a separate set in the game) follow the preset, a notch lower.

## Commands

| Command | |
|---|---|
| `/deckforever` | Open the window |
| `/deckforever apply battery\|balanced\|performance\|quality` | Apply a preset (`performance` is Max FPS, `quality` is Max Quality) |
| `/deckforever restore` | Back to your own settings from before the first preset |
| `/deckforever preview <preset>` | List what a preset would change |
| `/deckforever customize [preset]` / `deck [preset]` | Open the Customize / Steam Deck tab |
| `/deckforever set <preset> <setting> <value>` / `reset <preset> [setting]` | Override or reset preset values |
| `/deckforever uiscale <0.5-1.0>\|default` | Interface size (about 0.75 suits the Deck) |
| `/deckforever minimap on\|off`, `raid on\|off`, `reminder on\|off\|<minutes>` | Options |
| `/deckforever fps`, `status`, `help` | Information |

## Install

New to WoW: Forever on the Deck? Start with the [DeckForever app](https://github.com/eliog/DeckForever).

Install it from [CurseForge](https://www.curseforge.com/projects/1739370) (search for
*DeckForever* in the CurseForge app), or download the zip from
[Releases](https://github.com/eliog/DeckForeverAddon/releases) and extract it into
`World of Warcraft/_classic_beta_/Interface/AddOns/` (the client folder for WoW: Forever).

## Development

Tests run outside the game against a small WoW API mock, seeded with a WoW: Forever `Config.wtf`:

```sh
luajit tests/run.lua
```

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) when a
`v*` tag is pushed.

## License

[MIT](LICENSE)

## Disclaimer

DeckForever is an independent, fan-made addon. It is not affiliated with, endorsed by or supported
by Valve Corporation or Blizzard Entertainment. Steam and Steam Deck are trademarks of Valve
Corporation. World of Warcraft is a trademark of Blizzard Entertainment, Inc.
