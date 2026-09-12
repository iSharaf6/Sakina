#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const defaultRoot = resolve(scriptDirectory, "..");

function parseArguments(argv) {
  const options = {
    root: defaultRoot,
    output: "supabase/manifests/guidance-manifest.json",
    check: false,
    stdout: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--check") {
      options.check = true;
    } else if (argument === "--stdout") {
      options.stdout = true;
    } else if (argument === "--root" || argument === "--output") {
      const value = argv[index + 1];
      if (!value) throw new Error(`${argument} requires a value`);
      options[argument.slice(2)] = value;
      index += 1;
    } else if (argument === "--help") {
      process.stdout.write(
        "Usage: node scripts/generate-guidance-manifest.mjs " +
          "[--check] [--stdout] [--root PATH] [--output PATH]\n",
      );
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${argument}`);
    }
  }

  options.root = resolve(options.root);
  options.output = resolve(options.root, options.output);
  return options;
}

function findBalancedBlock(source, openingIndex, openCharacter, closeCharacter) {
  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let index = openingIndex; index < source.length; index += 1) {
    const character = source[index];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === '"') {
        inString = false;
      }
      continue;
    }

    if (character === '"') {
      inString = true;
    } else if (character === openCharacter) {
      depth += 1;
    } else if (character === closeCharacter) {
      depth -= 1;
      if (depth === 0) return source.slice(openingIndex, index + 1);
    }
  }

  throw new Error(`Unbalanced ${openCharacter}${closeCharacter} block`);
}

function decodeSwiftStringLiteral(literal) {
  try {
    return JSON.parse(literal);
  } catch (error) {
    throw new Error(`Unsupported Swift string literal ${literal}: ${error.message}`);
  }
}

const swiftStringPattern = '"(?:\\\\.|[^"\\\\])*"';

function extractNamedString(block, name) {
  const match = block.match(
    new RegExp(`\\b${name}\\s*:\\s*(${swiftStringPattern})`, "u"),
  );
  if (!match) throw new Error(`Missing ${name} in ${block.slice(0, 100)}…`);
  return decodeSwiftStringLiteral(match[1]);
}

function parseSituations(source) {
  const results = [];
  let cursor = 0;

  while (true) {
    const marker = source.indexOf("Situation(", cursor);
    if (marker === -1) break;
    const openingIndex = source.indexOf("(", marker);
    const block = findBalancedBlock(source, openingIndex, "(", ")");
    cursor = openingIndex + block.length;

    const verseKeysMatch = block.match(/\bverseKeys\s*:\s*(\[[\s\S]*?\])/u);
    if (!verseKeysMatch) continue;
    const verseKeys = [
      ...verseKeysMatch[1].matchAll(new RegExp(swiftStringPattern, "gu")),
    ].map((match) => decodeSwiftStringLiteral(match[0]));

    results.push({
      id: extractNamedString(block, "id"),
      titleEnglish: extractNamedString(block, "title"),
      contextEnglish: extractNamedString(block, "whyNote"),
      verseKeys,
    });
  }

  return results;
}

function parseSwiftStringDictionary(source, declarationMarker) {
  const declarationIndex = source.indexOf(declarationMarker);
  if (declarationIndex === -1) {
    throw new Error(`Could not find Swift dictionary ${declarationMarker}`);
  }

  const openingIndex = source.indexOf("[", declarationIndex + declarationMarker.length);
  if (openingIndex === -1) throw new Error(`Missing dictionary body for ${declarationMarker}`);
  const block = findBalancedBlock(source, openingIndex, "[", "]");
  const pairPattern = new RegExp(
    `(${swiftStringPattern})\\s*:\\s*(${swiftStringPattern})`,
    "gu",
  );
  const entries = new Map();

  for (const match of block.matchAll(pairPattern)) {
    const key = decodeSwiftStringLiteral(match[1]);
    const value = decodeSwiftStringLiteral(match[2]);
    if (entries.has(key)) throw new Error(`Duplicate dictionary key: ${key}`);
    entries.set(key, value);
  }

  return entries;
}

function canonicalHash(entry) {
  const sourceSnapshot = {
    schema_version: 1,
    situation_id: entry.situation_id,
    verse_key: entry.verse_key,
    title_en: entry.title_en,
    title_ar: entry.title_ar,
    context_en: entry.context_en,
    context_ar: entry.context_ar,
    surah_name_en: entry.surah_name_en,
    surah_name_ar: entry.surah_name_ar,
    verse_ar: entry.verse_ar,
    verse_en: entry.verse_en,
  };

  return createHash("sha256")
    .update(JSON.stringify(sourceSnapshot).normalize("NFC"), "utf8")
    .digest("hex");
}

function requireNonBlank(value, label) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${label} must be a non-blank string`);
  }
}

async function buildManifest(root) {
  const [catalogSource, guidanceSource, reflectionsSource, verseFileSource] =
    await Promise.all([
      readFile(resolve(root, "Shared/QuranCatalog.swift"), "utf8"),
      readFile(resolve(root, "Shared/ArabicSituationTitles.swift"), "utf8"),
      readFile(resolve(root, "Shared/ArabicReflections.swift"), "utf8"),
      readFile(resolve(root, "Shared/Resources/verses.json"), "utf8"),
    ]);

  const situations = parseSituations(catalogSource);
  const arabicTitles = parseSwiftStringDictionary(
    guidanceSource,
    "static let values: [String: String] =",
  );
  const arabicContexts = parseSwiftStringDictionary(
    reflectionsSource,
    "static let bySituationID: [String: String] =",
  );
  const verseFile = JSON.parse(verseFileSource);
  const verses = new Map(verseFile.verses.map((verse) => [verse.key, verse]));

  if (situations.length === 0) throw new Error("No Situation entries were parsed");
  const situationIDs = new Set();
  const identities = new Set();
  const manifest = [];

  for (const situation of situations) {
    if (situationIDs.has(situation.id)) {
      throw new Error(`Duplicate situation ID: ${situation.id}`);
    }
    situationIDs.add(situation.id);

    if (situation.verseKeys.length === 0) {
      throw new Error(`Situation ${situation.id} has no verse keys`);
    }

    const titleArabic = arabicTitles.get(situation.id);
    const contextArabic = arabicContexts.get(situation.id);
    requireNonBlank(titleArabic, `Arabic title for ${situation.id}`);
    requireNonBlank(contextArabic, `Arabic context for ${situation.id}`);

    for (const verseKey of situation.verseKeys) {
      const verse = verses.get(verseKey);
      if (!verse) throw new Error(`Missing verse ${verseKey} for ${situation.id}`);

      const identity = `${situation.id}\u0000${verseKey}`;
      if (identities.has(identity)) {
        throw new Error(`Duplicate manifest identity: ${situation.id} + ${verseKey}`);
      }
      identities.add(identity);

      const entry = {
        situation_id: situation.id,
        verse_key: verseKey,
        title_en: situation.titleEnglish,
        title_ar: titleArabic,
        context_en: situation.contextEnglish,
        context_ar: contextArabic,
        surah_name_en: verse.surahName,
        surah_name_ar: verse.surahNameArabic,
        verse_ar: verse.arabic,
        verse_en: verse.translation,
      };

      for (const [key, value] of Object.entries(entry)) {
        requireNonBlank(value, `${key} for ${situation.id} + ${verseKey}`);
      }

      manifest.push({ ...entry, source_hash: canonicalHash(entry) });
    }
  }

  const unexpectedTitles = [...arabicTitles.keys()].filter((id) => !situationIDs.has(id));
  const unexpectedContexts = [...arabicContexts.keys()].filter((id) => !situationIDs.has(id));
  if (unexpectedTitles.length > 0 || unexpectedContexts.length > 0) {
    throw new Error(
      `Stale Arabic keys: titles=[${unexpectedTitles.join(", ")}], ` +
        `contexts=[${unexpectedContexts.join(", ")}]`,
    );
  }

  return manifest;
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const manifest = await buildManifest(options.root);
  const rendered = `${JSON.stringify(manifest, null, 2)}\n`;

  if (options.stdout) process.stdout.write(rendered);

  if (options.check) {
    let existing;
    try {
      existing = await readFile(options.output, "utf8");
    } catch {
      throw new Error(`Generated manifest is missing: ${options.output}`);
    }
    if (existing !== rendered) {
      throw new Error(
        `Manifest is stale. Run: node scripts/generate-guidance-manifest.mjs`,
      );
    }
  } else if (!options.stdout) {
    await writeFile(options.output, rendered, "utf8");
  }

  process.stderr.write(
    `${options.check ? "Validated" : "Generated"} ${manifest.length} guidance items.\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`guidance manifest: ${error.message}\n`);
  process.exitCode = 1;
});

