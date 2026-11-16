// SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const fs = require("fs");
const requireEnv = require("./require_env.js");

function slugify(name) {
  return name.replace(/[^A-Za-z0-9-]+/g, "-").replace(/^-+|-+$/, "");
}

async function getIDTokenWithRetry(core, audience, attempts = 5) {
  for (let i = 1; ; i++) {
    try {
      return await core.getIDToken(audience);
    } catch (err) {
      if (i >= attempts || !/50[23]|timeout|connect/i.test(String(err))) throw err;
      const base = Math.min(30000, 2000 * 2 ** i);
      const delay = base * (0.5 + Math.random()); // 50-150% of base: decorrelate parallel jobs
      core.warning(
        `getIDToken attempt ${i} failed: ${String(err).trim()}; retrying in ${Math.round(delay / 1000)}s`,
      );
      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

module.exports = async (container, publish, { core, exec }) => {
  if (!container) throw new Error("container not set");
  const installable = `.#containers.entries.${container}`;

  core.startGroup("build copy-to");
  const copy_to_out = await exec.getExecOutput("nix", [
    "build",
    "--no-link",
    "--print-out-paths",
    `${installable}.passthru.copyTo`,
  ]);
  const copy_to = `${copy_to_out.stdout.trim()}/bin/copy-to`;
  core.endGroup();

  const github_ref_name = requireEnv("GITHUB_REF_NAME");
  const github_ref_name_slug = slugify(github_ref_name);

  const repository_eval = await exec.getExecOutput("nix", [
    "eval",
    "--raw",
    `${installable}.meta.repository`,
  ]);
  console.log("");
  const repository = repository_eval.stdout.trim();

  const skopeo_args = [
    "--dest-compress-format",
    "zstd:chunked",
    "--dest-precompute-digests",
    "--retry-times",
    "5",
  ];
  const tags = [requireEnv("GITHUB_SHA"), github_ref_name_slug];

  const sigstore_params_path = `${requireEnv("RUNNER_TEMP")}/sigstore-params.yaml`;
  if (publish) {
    skopeo_args.push("--sign-by-sigstore", sigstore_params_path);

    const tags_eval = await exec.getExecOutput("nix", [
      "eval",
      "--json",
      `${installable}.meta.tags`,
    ]);
    tags.push(...JSON.parse(tags_eval.stdout));
  }
  console.debug("skopeo_args:", skopeo_args);
  console.debug("tags:", tags);

  let any_failed = false;
  const pushed_tags = [];
  for (const tag of tags) {
    core.startGroup(`pushing ${repository}:${tag}`);

    if (publish) {
      const oidcIDToken = await getIDTokenWithRetry(core, "sigstore");
      fs.writeFileSync(
        sigstore_params_path,
        JSON.stringify({
          fulcio: {
            fulcioURL: "https://fulcio.sigstore.dev",
            oidcMode: "staticToken",
            oidcIDToken,
          },
          rekorURL: "https://rekor.sigstore.dev",
        }),
        "utf8",
      );
    }

    const ret = await exec.exec(copy_to, [...skopeo_args, `docker://${repository}:${tag}`], {
      ignoreReturnCode: true,
    });
    if (ret !== 0) {
      any_failed = true;
      core.error(
        `${copy_to} ${[...skopeo_args, `docker://${repository}:${tag}`].join(" ")} failed: ${ret}`,
      );
    } else {
      pushed_tags.push(`${repository}:${tag}`);
    }

    core.endGroup();
  }

  if (pushed_tags.length > 0) {
    core.summary.addHeading("pushed tags", 2);
    core.summary.addList(pushed_tags);
    await core.summary.write();
  }

  return !any_failed;
};
