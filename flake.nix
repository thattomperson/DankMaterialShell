{
  description = "Dank material shell.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell, dgop, dms-cli, ... }:
    let
      forEachSystem = fn:
        nixpkgs.lib.genAttrs
          nixpkgs.lib.platforms.linux
          (system: fn system nixpkgs.legacyPackages.${system});
    in {
      packages = forEachSystem (system: pkgs: rec {
        dankMaterialShell = pkgs.stdenvNoCC.mkDerivation {
          name = "dankMaterialShell";
          src = ./.;
          installPhase = ''
            mkdir -p $out/etc/xdg/quickshell/DankMaterialShell
            cp -r . $out/etc/xdg/quickshell/DankMaterialShell
            ln -s $out/etc/xdg/quickshell/DankMaterialShell $out/etc/xdg/quickshell/dms
          '';
        };

        default = self.packages.${system}.dankMaterialShell;
      });

      homeModules.dankMaterialShell = { config, pkgs, lib, ... }:
        let cfg = config.programs.dankMaterialShell;
        in {

          options.programs.dankMaterialShell = {
            enable = lib.mkEnableOption "DankMaterialShell";
            enableKeybinds =
              lib.mkEnableOption "DankMaterialShell Niri keybinds";
            enableSystemd =
              lib.mkEnableOption "DankMaterialShell systemd startup";
            enableSpawn =
              lib.mkEnableOption "DankMaterialShell Niri spawn-at-startup";
            enableSystemMonitoring = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to use system monitoring widgets";
            };
            enableClipboard = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to use the clipboard widget";
            };
            enableVPN = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to use the VPN widget";
            };
            enableBrigthnessControl = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to have brightness/backlight support";
            };
            enableNightMode = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to have night mode support";
            };
            enableDynamicTheming = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to have dynamic theming support";
            };
            enableAudioWavelenght = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add needed dependencies to have audio wavelenght support";
            };
            enableCalendarEvents = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Add calendar events support via khal";
            };
            quickshell = {
              package =  lib.mkPackageOption pkgs "quickshell" {
                default = quickshell.packages.${pkgs.system}.quickshell;
                nullable = false;
              };
            };
          };

          config = lib.mkIf cfg.enable {
            programs.quickshell = {
              enable = true;
              package = cfg.quickshell.package;
              configs.DankMaterialShell = "${
                  self.packages.${pkgs.system}.dankMaterialShell
                }/etc/xdg/quickshell/DankMaterialShell";
              activeConfig = lib.mkIf cfg.enableSystemd "DankMaterialShell";
              systemd = lib.mkIf cfg.enableSystemd {
                enable = true;
                target = "graphical-session.target";
              };
            };

            programs.niri.settings = lib.mkMerge [
              (lib.mkIf cfg.enableKeybinds {
                binds = with config.lib.niri.actions; let
                  quickShellIpc = spawn "${cfg.quickshell.package}/bin/qs" "-c" "DankMaterialShell" "ipc" "call";
                in {
                  "Mod+Space".action = quickShellIpc "spotlight" "toggle";
                  "Mod+V".action = quickShellIpc "clipboard" "toggle";
                  "Mod+M".action = quickShellIpc "processlist" "toggle";
                  "Mod+Comma".action = quickShellIpc "settings" "toggle";
                  "Super+Alt+L".action = quickShellIpc "lock" "lock";
                  "XF86AudioRaiseVolume" = {
                    allow-when-locked = true;
                    action = quickShellIpc "audio" "increment" "3";
                  };
                  "XF86AudioLowerVolume" = {
                    allow-when-locked = true;
                    action = quickShellIpc "audio" "decrement" "3";
                  };
                  "XF86AudioMute" = {
                    allow-when-locked = true;
                    action = quickShellIpc "audio" "mute";
                  };
                  "XF86AudioMicMute" = {
                    allow-when-locked = true;
                    action = quickShellIpc "audio" "micmute";
                  };
                };
              })
              (lib.mkIf (cfg.enableSpawn) {
                spawn-at-startup =
                  [{ command = [ "${cfg.quickshell.package}/bin/qs" "-c" "DankMaterialShell" ]; }];
              })
            ];

            home.packages = [
              pkgs.material-symbols
              pkgs.inter
              pkgs.fira-code

              pkgs.ddcutil
              pkgs.libsForQt5.qt5ct
              pkgs.kdePackages.qt6ct
              dms-cli.packages.${pkgs.system}.default
            ]
            ++ lib.optional cfg.enableSystemMonitoring dgop.packages.${pkgs.system}.dgop
            ++ lib.optionals cfg.enableClipboard [pkgs.cliphist pkgs.wl-clipboard]
            ++ lib.optionals cfg.enableVPN [pkgs.glib pkgs.networkmanager]
            ++ lib.optional cfg.enableBrigthnessControl pkgs.brightnessctl
            ++ lib.optional cfg.enableNightMode pkgs.gammastep
            ++ lib.optional cfg.enableDynamicTheming pkgs.matugen
            ++ lib.optional cfg.enableAudioWavelenght pkgs.cava
            ++ lib.optional cfg.enableCalendarEvents pkgs.khal;
          };
        };
    };
}
