# plotline

A cinematic universe watch-order tracker hosted on GitHub Pages.

## 🎬 Live site

**<https://hermannakos.github.io/plotline/>**

## Features

- **5 universes** – MCU, DCU, Monsterverse, Star Wars, Arrowverse
- Phase / era groupings with interleaved crossover events (Arrowverse)
- Per-entry **watched** toggle saved to `localStorage`
- Progress bar & stats per universe
- Zero build step — single `index.html` using React & Babel via CDN

## Deployment

The site is a single static `index.html` file. Push to the `main` branch and
enable **GitHub Pages → Deploy from branch → `main` / `/ (root)`** in the
repository Settings.

The `.nojekyll` file at the root prevents GitHub Pages from running Jekyll.