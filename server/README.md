# Universal Beatdown - online relay server

The game's ONLINE mode (rooms by code, Quickplay, Versus + Story co-op, web + PC) needs this small
server to be reachable by everyone. It is one file, `relay.js`, plain Node.js with no packages.

## Run it on your own PC (testing)

```
node server/relay.js
```

It listens on port 8787. In the game: Main Menu > ONLINE > SERVER = `ws://127.0.0.1:8787` (same PC),
or `ws://<your PC's local IP>:8787` for another device on your Wi-Fi.

## Put it online for free (Render)

1. Make a free account at https://render.com and connect your GitHub.
2. New > **Blueprint** > pick the `fighting-game` repo. Render reads `render.yaml` and creates the
   service `ub-relay` by itself. (Or: New > Web Service, Start Command `node server/relay.js`.)
3. When it is live you get an address like `https://ub-relay-xxxx.onrender.com`.
4. In the game: ONLINE > SERVER = `wss://ub-relay-xxxx.onrender.com` (note **wss://**, not https://).
   The website version can only use `wss://` addresses.

Free Render services fall asleep after 15 minutes without players; the first connection then takes
about 30 seconds while it wakes up.

## What it does

- `host` makes a room with a 5-letter code, `join` enters it by code, `quick` joins the oldest open
  room of a mode (Versus / Story).
- Game data (binary frames) is passed between the two players of a room untouched. The HOST's game
  runs the fight; the guest sends button presses and draws what the host sends.
