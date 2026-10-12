# 🧪 Potion Town

A cozy multiplayer potion shop game for Roblox. Every player gets their own magical
shop, chooses one of 10 house styles, and can walk over to visit other players' shops.

See **[docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)** for the full mind map, all phases
and the science-named potion recipes.

## Current state: Phase 1 (Town and homes)

- A town with a central plaza, the Town Market pavilion, a wishing well and an
  enchanted forest full of glowing mushrooms and fireflies
- 8 plots around the plaza. When someone joins, their shop gets built on a free plot.
- You spawn inside your own shop
- 10 shop styles: Enchanted Cottage, Futuristic Lab, Coquette Boutique, Rustic
  Farmhouse, Wooden Lodge, Gothic Castle, Mushroom Hideaway, Zen Tea House, Crystal
  Spire and Sunstone Bazaar
- Cozy interiors with glowing potion shelves, a bubbling cauldron, a counter,
  lanterns and drying herbs
- Things you can interact with: doors, stirring the cauldron, sparkles (likes) on
  other people's shop signs, changing your style, the wishing well
- A side menu: 🏠 Home, 🎨 Style, 🧭 Visit, ⛲ Town
- Your style and sparkle count are saved

Everything is built from code, so there are no models or meshes to import.

## How to play it in Roblox Studio

### Option A: open the place file (easiest)

1. Download `PotionTown.rbxlx` from this repo.
2. Double-click it, or open Roblox Studio and choose **File → Open from File**.
3. Press **Play**. The town builds itself in about a second.

### Option B: live-sync the code with Rojo (best for development)

1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) and its
   Studio plugin.
2. In this folder, run `rojo serve`.
3. In Studio, open a Baseplate place, then click **Rojo → Connect**.
4. Press **Play**. Changes you save to `src/` show up in Studio straight away.

To rebuild the place file after changing code, run
`rojo build default.project.json -o PotionTown.rbxlx`.

### Recommended Studio settings

- **Lighting → Technology = Future.** The place file already sets this. It gives
  lanterns and the cauldron real shadows and glow, which is the cozy look.
- **Game Settings → Security → Enable Studio Access to API Services.** Without this
  the game still works in Studio, it just won't save.
- **Game Settings → Places → Max Players = 8.** There is one plot per player.

### Testing multiplayer

In Studio go to **Test → Clients and Servers**, pick 2 or 3 players, and click
**Start**. Each test player gets their own shop. Use 🧭 **Visit** to jump to the
other shops, and try leaving a sparkle on someone's sign.

## Project layout

```
default.project.json        Rojo project (maps src/ into the game)
PotionTown.rbxlx            Ready-to-open place file built from src/
src/shared/                 ReplicatedStorage.Shared
  Config.lua                Town layout numbers, potion colors
  HouseStyles.lua           The 10 shop styles (colors, materials, roof, features)
src/server/                 ServerScriptService.Server
  Main.server.lua           Entry point: joins/leaves, remotes, plaza props
  WorldBuilder.lua          Lighting, terrain, plaza, market, plots, forest
  HouseBuilder.lua          Builds a shop from a style (shell, roof, features, interior)
  PlotService.lua           Plot ownership, (re)building, door/cauldron/sign interactions
  PlayerData.lua            DataStore saving
  BuildUtil.lua             Part/lantern/lamp/sign helpers
  Remotes.lua               RemoteEvents
src/client/                 StarterPlayerScripts.Client
  ShopUI.client.lua         Side menu, style picker, visit menu, toasts
```

### Adding an 11th style

Add a new entry to `HouseStyles.List` in `src/shared/HouseStyles.lua`. Pick a roof
type (`Gable`, `Flat`, `Dome`, `Cone` or `Pagoda`) and any of the existing
`Features`. It appears in the picker automatically.
