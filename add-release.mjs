// Adds a release tag to a project's tag list in antora-playbook.yml.
//
//   node add-release.mjs rubocop v1.93.0
//
// A new minor version is appended. A patch release replaces the tag of the same
// minor version, since both are published as the same docs version. When the
// playbook changes, the commit message for it is printed to stdout.

import { readFileSync, writeFileSync } from "node:fs";

const PLAYBOOK = "antora-playbook.yml";
const [project, tag] = process.argv.slice(2);

if (!/^[\w.-]+$/.test(project ?? "") || !/^v\d+\.\d+\.\d+$/.test(tag ?? "")) {
  console.error("Usage: node add-release.mjs <project> <vX.Y.Z>");
  process.exit(1);
}

const minor = (version) => version.split(".").slice(0, 2).join(".");
const playbook = readFileSync(PLAYBOOK, "utf8");

const source = playbook.match(
  new RegExp(`- url: \\S+/${project.replace(/\./g, "\\.")}\\.git\\n(?:(?!\\s*- url:).*\\n)*`),
);
if (!source) {
  console.error(`${project} isn't in ${PLAYBOOK}`);
  process.exit(1);
}

const list = source[0].match(/(tags:\s*)(\[[^\]]*\])/);
if (!list) {
  console.error(`${project} has no tag list in ${PLAYBOOK}`);
  process.exit(1);
}
const quote = list[2].match(/["']/)?.[0] ?? '"';
const tags = [...list[2].matchAll(/["']([^"']+)["']/g)].map((match) => match[1]);
const previous = tags.find((existing) => minor(existing) === minor(tag));

if (previous === tag) {
  console.error(`${tag} is already listed for ${project}`);
  process.exit(0);
}
if (previous) {
  tags[tags.indexOf(previous)] = tag;
} else {
  tags.push(tag);
}

let rendered;
if (list[2].includes("\n")) {
  const indent = list[2].match(/\n(\s*)["']/)[1];
  const closing = list[2].match(/\n(\s*)\]$/)[1];
  rendered = `[\n${tags.map((t) => `${indent}${quote}${t}${quote},`).join("\n")}\n${closing}]`;
} else {
  rendered = `[${tags.map((t) => `${quote}${t}${quote}`).join(", ")}]`;
}

// Replacer functions, so that a `$` in the playbook isn't read as a pattern.
const updatedSource = source[0].replace(list[0], () => `${list[1]}${rendered}`);
writeFileSync(PLAYBOOK, playbook.replace(source[0], () => updatedSource));

const name = project === "rubocop" ? "RuboCop" : project;
const version = tag.slice(1);
console.log(
  previous
    ? `Update ${name} ${minor(version)} to ${version}`
    : `Add ${name} ${minor(version)}`,
);
