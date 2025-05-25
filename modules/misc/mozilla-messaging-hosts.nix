{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.mozilla;

  defaultPaths = [
    # Link a .keep file to keep the directory around
    (pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/.keep" "")
  ];

  thunderbirdNativeMessagingHostsPath =
    if isDarwin then "Library/Mozilla/NativeMessagingHosts" else ".mozilla/native-messaging-hosts";

  firefoxNativeMessagingHostsPath =
    if isDarwin then
      "Library/Application Support/Mozilla/NativeMessagingHosts"
    else
      ".mozilla/native-messaging-hosts";

  librewolfNativeMessagingHostsPath =
    if isDarwin then
      "Library/Application Support/LibreWolf/NativeMessagingHosts"
    else
      ".librewolf/native-messaging-hosts";
in
{
  meta.maintainers = with lib.maintainers; [
    booxter
    rycee
    lib.hm.maintainers.bricked
  ];

  options.mozilla = {
    firefoxNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Firefox native messaging hosts to configure.
      '';
    };

    thunderbirdNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Thunderbird native messaging hosts to configure.
      '';
    };

    librewolfNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Librewolf native messaging hosts to configure.
      '';
    };
  };

  config =
    lib.mkIf
      (
        cfg.firefoxNativeMessagingHosts != [ ]
        || cfg.thunderbirdNativeMessagingHosts != [ ]
        || cfg.librewolfNativeMessagingHosts != [ ]
      )
      {
        home.file =
          if isDarwin then
            let
              firefoxNativeMessagingHostsJoined = pkgs.symlinkJoin {
                name = "ff-native-messaging-hosts";
                paths = defaultPaths ++ cfg.firefoxNativeMessagingHosts;
              };
              thunderbirdNativeMessagingHostsJoined = pkgs.symlinkJoin {
                name = "th-native-messaging-hosts";
                paths = defaultPaths ++ cfg.thunderbirdNativeMessagingHosts;
              };
              librewolfNativeMessagingHostsJoined = pkgs.symlinkJoin {
                name = "lw-native-messaging-hosts";
                paths = defaultPaths ++ cfg.librewolfNativeMessagingHosts;
              };
            in
            {
              "${thunderbirdNativeMessagingHostsPath}" = lib.mkIf (cfg.thunderbirdNativeMessagingHosts != [ ]) {
                source = "${thunderbirdNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
              "${firefoxNativeMessagingHostsPath}" = lib.mkIf (cfg.firefoxNativeMessagingHosts != [ ]) {
                source = "${firefoxNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
              "${librewolfNativeMessagingHostsPath}" = lib.mkIf (cfg.librewolfNativeMessagingHosts != [ ]) {
                source = "${librewolfNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
            }
          else
            let
              mozillaNativeMessagingHostsJoined = pkgs.symlinkJoin {
                name = "mozilla-native-messaging-hosts";
                # on Linux, the directory is shared between Firefox and Thunderbird; merge both into one
                paths = defaultPaths ++ cfg.firefoxNativeMessagingHosts ++ cfg.thunderbirdNativeMessagingHosts;
              };
              librewolfNativeMessagingHostsJoined = pkgs.symlinkJoin {
                name = "librewolf-native-messaging-hosts";
                paths = defaultPaths ++ cfg.librewolfNativeMessagingHosts;
              };
            in
            {
              "${firefoxNativeMessagingHostsPath}" = {
                source = "${mozillaNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
              "${librewolfNativeMessagingHostsPath}" = {
                source = "${librewolfNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
            };
      };
}
