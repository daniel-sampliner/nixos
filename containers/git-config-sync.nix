# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  buildEnv,
  nix2container,

  gitMinimal,
  s6-networking,
  s6-portable-utils,
  writers,
}:
let
  gitDir = "/srv/git";
  branch = "main";
  repo = "repo.git";

  configDir = "/srv/config";

  entrypoint = writers.writeExecline { } "/bin/entrypoint" ''
    execline-cd ${gitDir}
    execline-umask 0077

    if {
      ifelse { eltest -d ${repo} }
      { }
      git init \
        --bare \
        --initial-branch=${branch} \
        ${repo}
    }
    if { s6-touch ${repo}/git-daemon-export-ok }
    if { s6-ln -sf ${post-receive} ${repo}/hooks/post-receive }

    exec -a s6-tcpserver s6-tcpserver 0.0.0.0 9418
    git daemon
      --base-path=.
      --enable=receive-pack
      --inetd
      --informative-errors
      --log-destination=stderr
      .
  '';

  post-receive = writers.writeExecline { } "post-receive" ''
    fdmove -c 1 2

    execline-cd ${configDir}

    forstdin -E -x 0 line
    multidefine $line { "" new ref }
    if { eltest $ref = "refs/heads/${branch}" }

    if { s6-mkdir work-$new }
    if { git --git-dir=${gitDir}/${repo} --work-tree=work-$new checkout ${branch} . }

    backtick -D "" -E old { s6-linkname -f work }
    if { s6-ln -nsf work-$new work }
    s6-rmrf $old
  '';

  healthcheck = writers.writeExecline { } "/bin/healthcheck" ''
    git ls-remote --exit-code git://127.0.0.1:9418/repo HEAD
  '';
in
nix2container.buildImage {
  name = "git-config-sync";
  tag = gitMinimal.version;

  copyToRoot = [
    (buildEnv {
      name = "root";
      paths = [
        gitMinimal
        s6-networking
        s6-portable-utils

        entrypoint
        healthcheck
      ];
      pathsToLink = [
        "/bin"
        "/libexec"
      ];
    })
  ];

  config = {
    Entrypoint = [ "entrypoint" ];
    User = "65534";

    ExposedPorts = {
      "9418/tcp" = { };
    };

    Volumes = {
      ${configDir} = { };
      ${gitDir} = { };
    };
  };
}
