# pwgen-typescript

This is a TypeScript translation of the pwgen-java PwGenCommand logic.

## Notes:
- Wordlists: It will first look in pwgen-typescript/assets, and if not found, it falls back to pwgen-java/src/main/resources.

## Build (JS)
- `npm install`
- `npm run build`

## Run (JS)
- `node dist/index.js [number] [numberOfDigits] [delimiters] [options]`

## Build a standalone binary
- Prerequisite: `npm install`
- Build: `npm run build:bin`
- Binaries will be placed under dist/bin for macOS, Linux, and Windows (x64) by default.
- You can adjust targets in package.json → pkg.targets.

## Run the installed CLI (from JS build)
- After `npm run build`, you can run it via: node dist/index.js ...
- Or install/link locally: npm link (from pwgen-typescript) then use pwgen ...

## Options
- `-U, --wordsStartWithUppercase   Set first character of each word to uppercase`
- `-L, --lang <code>               Language to use, e.g. "de" or "en"; defaults to system language`
- `-v, --verbose                   Verbose logging`

## Defaults
- number: 4
- numberOfDigits: 3
- delimiters: =/*-+

## Examples
- `./dist/bin/pwgen-typescript 5 3`
- `./dist/bin/pwgen-typescript "=/*-+" -L en`
- `./dist/bin/pwgen-typescript 5 2 -U --lang de`
