#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Utilities
function getDefaultLanguage(verbose: boolean): string {
  // Try to derive a two-letter language code
  const fallback = 'en';
  let lang = '';
  try {
    // Node 18+: resolved locale may be like en-US
    const loc = Intl.DateTimeFormat().resolvedOptions().locale || '';
    if (loc) lang = loc.split('-')[0];
  } catch {
    // ignore
  }
  if (!lang) {
    const env = process.env.LANG || process.env.LC_ALL || process.env.LC_MESSAGES || '';
    if (env) lang = env.split('.')[0]?.split('_')[0] || '';
  }
  if (!lang && verbose) {
    console.error('Use default language fallback: en');
  }
  return lang || fallback;
}

function readWordList(filename: string, verbose: boolean): string[] | null {
  const tryPaths = [
    join(__dirname, '..', 'assets', filename),
    // Fallback to Java resources if copied resources are not present
    join(__dirname, '..', '..', 'src', 'main', 'resources', filename),
  ];
  for (const full of tryPaths) {
    try {
      const text = readFileSync(full, { encoding: 'utf8' });
      const lines = text.split(/\r?\n/);
      const words: string[] = [];
      for (let line of lines) {
        let word = line.trim();
        if (word.length === 0) continue;
        // replace blanks with CamelCase
        while (word.includes(' ')) {
          const pos = word.indexOf(' ');
          const next = word.charAt(pos + 1).toUpperCase();
          word = word.substring(0, pos) + next + word.substring(pos + 2);
          word = word.trim();
        }
        words.push(word);
      }
      return words;
    } catch (e) {
      // try next
    }
  }
  if (verbose) {
    console.error('Cannot read wordlist:', filename);
  }
  return null;
}

function uniqueRandomIndices(size: number, maxExclusive: number): number[] {
  const ret: number[] = [];
  const used = new Set<number>();
  while (ret.length < size) {
    const cand = Math.floor(Math.random() * maxExclusive);
    if (!used.has(cand)) {
      used.add(cand);
      ret.push(cand);
    }
  }
  return ret;
}

function toDelimiters(delims: string): string[] {
  const ret: string[] = [];
  for (let i = 0; i < delims.length; i++) ret.push(delims.charAt(i));
  return ret;
}

function generateDigits(count: number): string {
  let ret = '';
  for (let i = 0; i < count; i++) ret += Math.floor(Math.random() * 10).toString();
  return ret;
}

function generate(options: {
  wordList: string[];
  number: number;
  delimiters: string[];
  numberOfDigits: number;
  wordsStartWithUppercase: boolean;
}): string {
  const { wordList, number, delimiters, numberOfDigits, wordsStartWithUppercase } = options;
  if (!wordList) throw new Error('wordList required');
  if (number <= 0 || number > wordList.length) {
    throw new Error(`number must be > 0 and <= ${wordList.length}! Actual: ${number}`);
  }
  const indices = uniqueRandomIndices(number, wordList.length);
  const injectNumbers = numberOfDigits > 0;
  const numberPos = Math.floor(Math.random() * number);
  let ret = '';
  for (let i = 0; i < number; i++) {
    let word = wordList[indices[i]];
    if (wordsStartWithUppercase && word.length > 0) {
      word = word.charAt(0).toUpperCase() + word.substring(1);
    }
    ret += word;
    if (injectNumbers && numberPos === i) {
      ret += generateDigits(numberOfDigits);
    }
    if (i < number - 1) {
      const delimIdx = Math.floor(Math.random() * delimiters.length);
      ret += delimiters[delimIdx];
    }
  }
  return ret;
}

// CLI parsing
interface CliOptions {
  number: number;
  numberOfDigits: number;
  delimiters: string;
  wordsStartWithUppercase: boolean;
  lang: string;
  verbose: boolean;
}

function getVersion(): string {
  try {
    const pkgJsonPath = join(__dirname, '..', 'package.json');
    const pkg = JSON.parse(readFileSync(pkgJsonPath, 'utf8'));
    return pkg.version || '0.0.0';
  } catch {
    return '0.0.0';
  }
}

function parseArgs(argv: string[]): CliOptions {
  // argv[0]=node, argv[1]=script
  const rest = argv.slice(2);

  // Defaults per Java implementation
  let number = 4;
  let numberOfDigits = 3;
  let delimiters = '=/*-+';
  let wordsStartWithUppercase = false;
  let lang = '';
  let verbose = false;

  // Collect flags and positionals
  const positionals: string[] = [];
  for (let i = 0; i < rest.length; i++) {
    const a = rest[i];
    if (a === '-U' || a === '--wordsStartWithUppercase') {
      wordsStartWithUppercase = true;
    } else if (a === '-v' || a === '--verbose') {
      verbose = true;
    } else if (a === '-L' || a === '--lang') {
      const value = rest[i + 1];
      if (value == null) throw new Error('Missing value for --lang');
      lang = value;
      i++;
    } else if (a.startsWith('-')) {
      throw new Error(`Unknown option: ${a}`);
    } else {
      positionals.push(a);
    }
  }

  if (positionals[0] != null) number = Number(positionals[0]);
  if (positionals[1] != null) numberOfDigits = Number(positionals[1]);
  if (positionals[2] != null) delimiters = String(positionals[2]);

  if (!Number.isFinite(number) || number <= 0) throw new Error('number must be a positive integer');
  if (!Number.isFinite(numberOfDigits) || numberOfDigits < 0) throw new Error('numberOfDigits must be >= 0');

  return { number, numberOfDigits, delimiters, wordsStartWithUppercase, lang, verbose };
}

function main() {
  try {
    const argv = process.argv;
    if (argv.includes('-V') || argv.includes('--version')) {
      console.log(getVersion());
      process.exit(0);
    }
    const cli = parseArgs(argv);
    let langToUse = cli.lang;
    if (!langToUse) {
      langToUse = getDefaultLanguage(cli.verbose);
      if (cli.verbose) {
        console.error('Use default language:', langToUse);
      }
    }
    const words = readWordList(`wordlist_${langToUse}.txt`, cli.verbose);
    if (!words) {
      console.error(`ERROR: Cannot read wordlist for language ${langToUse}`);
      process.exit(1);
    }
    const output = generate({
      wordList: words,
      number: cli.number,
      delimiters: toDelimiters(cli.delimiters),
      numberOfDigits: cli.numberOfDigits,
      wordsStartWithUppercase: cli.wordsStartWithUppercase,
    });
    console.log(output);
  } catch (e: any) {
    console.error('ERROR:', e?.message ?? String(e));
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export {
  readWordList,
  generate,
  generateDigits,
  toDelimiters,
  uniqueRandomIndices,
};
