# Funky Friday Autoplayer

`SexyPlayer.lua` is the current Funky Friday autoplayer.

## Features
- Handles normal notes, spam, chords, and hold notes.
- Tracks notes separately so overlapping notes do not interfere with each other.
- Supports `firesignal` and Virtual Input.
- Adjustable hit accuracy, timing offset, spawn-to-hit delay, and tap hold time.
- Automatically rebinds when a new song starts.
- Includes manual Rebind and Unload buttons.

## Usage
Run `SexyPlayer.lua`, enable Autoplay, and start a song.

`firesignal` is the default input mode. Use Virtual Input if your executor handles it better.

If notes feel early or late on your executor, adjust **Timing Offset** or **Spawn-to-Hit Delay** slightly.
