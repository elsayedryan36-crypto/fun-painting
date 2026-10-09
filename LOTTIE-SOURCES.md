# Free Lottie assets for the 12 cards — where to get them & how to plug them in

The home cards now show a **calm category background** and play **any Lottie you drop in** on top of it. My hand-made Lotties were removed — download pro ones instead (they are far better).

## Best free Lottie sites

| Site | URL | Notes |
|---|---|---|
| **LottieFiles** | https://lottiefiles.com/free-animations | The biggest library. Filter by *Free*. Check the license on each file (many are free for personal **and** commercial use). Download as **Lottie JSON** or **.lottie**. |
| **Icons8 Animations** | https://icons8.com/animations | Big free set, consistent cartoon style — great for kids apps. Free with attribution (link to icons8.com in your store page). |
| **Lordicon** | https://lordicon.com | Free animated icons (interactive). Free tier needs a credit link. |
| **UseAnimations** | https://useanimations.com | Small clean pack, free for commercial use (no attribution needed on most). |
| **IconScout Lottie** | https://iconscout.com/lottie-animations | Has a *Free* filter; mixed licenses — check per file. |

Tips:
- Search **cartoon / cute / kids / flat** styles so all 12 cards look like one family.
- Prefer animations with a **transparent background** — your calm category background shows behind them.
- If a download is a **`.lottie` file**: it is just a **zip** — rename to `.zip`, unzip, and take the `.json` inside (usually in `animations/`).

## Search words per card

| Card | Try searching |
|---|---|
| Free Draw | `paint`, `brush`, `crayon`, `drawing` |
| Zoo | `lion`, `monkey`, `elephant`, `cute animal` |
| Sea | `fish`, `dolphin`, `octopus`, `underwater` |
| Dragons | `dragon`, `dinosaur` |
| Fairy | `butterfly`, `fairy`, `magic wand`, `sparkles` |
| Space | `rocket`, `planet`, `astronaut` |
| Cars | `car`, `truck`, `bus` |
| Circus | `balloon`, `circus`, `clown` |
| Food | `cupcake`, `donut`, `ice cream`, `fruit` |
| Flowers | `flower`, `bee`, `garden` |
| Letters | `abc`, `alphabet`, `school` |
| Numbers | `counting`, `numbers`, `star` |

## Plug one in (3 steps)

1. Put the json in the app folder: `assets/json/cards/zoo.json` (same name as the card).
2. In `pubspec.yaml`, under `assets:`, add the line:  `- assets/json/cards/`
3. In `lib/presentation/home/Widgets/kid_home_shelf.dart`, add the path to that world's `WorldMeta`, e.g.:
   `WorldMeta('Zoo', '🦁', Color(0xFF3D9142), 'assets/images/cards/zoo_bg.jpg', 'assets/json/cards/zoo.json'),`
4. `flutter clean && flutter pub get && flutter run` — the character now plays on top of the calm background.

The card plays the Lottie with `BoxFit.contain`, so any canvas size (square, 4:3…) fits perfectly — no cropping.

## Backgrounds (already in the repo)

`assets/images/cards/*_bg.jpg` — one calm 4:3 background per category, tinted with the category colour, **no animals or clutter** (Letters & Numbers arrive next round; a soft colour tint shows until then).
