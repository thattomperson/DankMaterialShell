{
  description = "Dank material shell.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    quickshell.url = "git+https://git.outfoxxed.me/quickshell/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    dms-cli.url = "github:AvengeMedia/danklinux";
    dms-cli.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, quickshell, dms-cli, ... }:
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

            home.packages = with pkgs; [
              material-symbols
              inter
              fira-code
              cava
              wl-clipboard
              cliphist
              ddcutil
              libsForQt5.qt5ct
              kdePackages.qt6ct
              matugen
              dms-cli.packages.${system}.default
            ];
          };
        };
    };
}
