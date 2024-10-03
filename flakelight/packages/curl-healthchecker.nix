# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ curlMinimal }:
(curlMinimal.override { gssSupport = false; }).overrideAttrs (prev: {
  configureFlags = prev.configureFlags or [ ] ++ [
    "--disable-alt-svc"
    "--disable-aws"
    "--disable-crypto-auth"
    "--disable-dict"
    "--disable-file"
    "--disable-ftp"
    "--disable-gopher"
    "--disable-imap"
    "--disable-ipv6"
    "--disable-largefile"
    "--disable-libcurl-option"
    "--disable-manual"
    "--disable-mqtt"
    "--disable-ntlm-wb"
    "--disable-pop3"
    "--disable-progressbar"
    "--disable-rtsp"
    "--disable-smb"
    "--disable-smtp"
    "--disable-telnet"
    "--disable-tftp"
    "--disable-threaded-resolver"
    "--disable-tls-srp"
  ];
})
