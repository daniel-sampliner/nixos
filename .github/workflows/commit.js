// SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const fs = require("node:fs/promises");

const query = `mutation (
  $githubRepository: String!
  $branchName: String!
  $expectedHeadOid: GitObjectID!
  $commitBody: String,
  $commitHeadline: String!,
  $additions: [FileAddition!]!
) {
  createCommitOnBranch(
    input: {
      branch: {
        repositoryNameWithOwner: $githubRepository
        branchName: $branchName
      }
      expectedHeadOid: $expectedHeadOid
      fileChanges: { additions: $additions }
      message: {
        body: $commitBody
        headline: $commitHeadline
      }
    }
  ) {
    commit {
      url
    }
  }
}`;

async function b64EncodeFile(path) {
  const contents = await fs.readFile(path);
  return contents.toString("base64");
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} env not set`);
  }
  return value;
}

module.exports = async (commit_subject, { exec, github }) => {
  const status = await exec.getExecOutput("git", ["status", "--porcelain=v2"]);

  // porcelain v2 changed-file lines: "1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>".
  // The path is everything after the 8 fixed fields, so it may contain spaces.
  const changed_files = status.stdout
    .split("\n")
    .filter((line) => line.startsWith("1 "))
    .map((line) => line.split(" ").slice(8).join(" "));

  const additions = await Promise.all(
    changed_files.map(async (path) => ({
      path,
      contents: await b64EncodeFile(path),
    })),
  );

  const head = await exec.getExecOutput("git", ["rev-parse", "HEAD"]);

  const variables = {
    githubRepository: requireEnv("GITHUB_REPOSITORY"),

    branchName: requireEnv("BRANCH"),
    expectedHeadOid: head.stdout.trim(),
    commitHeadline: commit_subject,

    commitBody: await fs.readFile(`${requireEnv("RUNNER_TEMP")}/commit_body`, "utf8"),

    additions,
  };

  const result = await github.graphql(query, variables);
  return result;
};
