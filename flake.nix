{
  description = "Dank material shell.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    quickshell.url = "git+https://git.outfoxxed.me/quickshell/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    niri.url = "github:sodiboo/niri-flake";
    # home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, niri, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {

      packages.x86_64-linux.dankMaterialShell = pkgs.stdenvNoCC.mkDerivation {
        name = "dankMaterialShell";
        src = ./.;
        buildInputs = with pkgs; [
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
        ];
        installPhase = ''
          mkdir -p $out/etc/xdg/quickshell/DankMaterialShell
          cp -r .  $out/etc/xdg/quickshell/DankMaterialShell
        '';
      };

      packages.x86_64-linux.default =
        self.packages.x86_64-linux.dankMaterialShell;

      homeModules.dankMaterialShell = { config, options, pkgs, outputs, ... }:
        let cfg = config.programs.dankMaterialShell;
        in {
          imports = [ niri.homeModules.niri ];

          options.programs.dankMaterialShell = {
            enable = pkgs.lib.mkEnableOption "DankMaterialShell";
            enableKeybinds =
              pkgs.lib.mkEnableOption "DankMaterialShell Niri keybinds";
            enableSystemd =
              pkgs.lib.mkEnableOption "DankMaterialShell systemd startup";
          };

          config.programs.quickshell.enable = pkgs.lib.mkIf cfg.enable true;

          config.programs.quickshell.configs.DankMaterialShell =
            pkgs.lib.mkIf cfg.enable
            "${self.outputs.packages.x86_64-linux.dankMaterialShell}/etc/xdg/quickshell/DankMaterialShell";

          config.programs.quickshell.package = pkgs.lib.mkIf cfg.enable
            self.inputs.quickshell.packages.x86_64-linux.quickshell;

          config.programs.quickshell.activeConfig =
            pkgs.lib.mkIf cfg.enableSystemd "DankMaterialShell";
          config.programs.quickshell.systemd.enable =
            pkgs.lib.mkIf cfg.enableSystemd true;
          config.programs.quickshell.systemd.target =
            pkgs.lib.mkIf cfg.enableSystemd "graphical-session.target";

          config.programs.niri.settings.binds = pkgs.lib.mkIf cfg.enableKeybinds
            (with config.lib.niri.actions; {
              "Mod+Space" = {
                hotkey-overlay.title = "Application Launcher";
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "spotlight"
                  "toggle";
              };
              "Mod+V" = {
                hotkey-overlay.title = "Clipboard Manager";
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "clipboard"
                  "toggle";
              };
              "Mod+M" = {
                hotkey-overlay.title = "Task Manager";
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "processlist"
                  "toggle";
              };
              "Mod+Comma" = {
                hotkey-overlay.title = "Settings";
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "settings"
                  "toggle";
              };
              "Super+Alt+L" = {
                hotkey-overlay.title = "Lock Screen";
                action = spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "lock"
                  "lock";
              };
              "XF86AudioRaiseVolume" = {
                allow-when-locked = true;
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "audio"
                  "increment" "3";
              };
              "XF86AudioLowerVolume" = {
                allow-when-locked = true;
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "audio"
                  "decrement" "3";
              };
              "XF86AudioMute" = {
                allow-when-locked = true;
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "audio"
                  "mute";
              };
              "XF86AudioMicMute" = {
                allow-when-locked = true;
                action =
                  spawn "qs" "-c" "DankMaterialShell" "ipc" "call" "audio"
                  "micmute";
              };
            });

          config.home.packages = pkgs.lib.mkIf cfg.enable (with pkgs; [
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
          ]);

          config.programs.niri.settings.spawn-at-startup =
            pkgs.lib.mkIf (cfg.enable && !cfg.enableSystemd) [{
              command = [ "qs" "-c" "DankMaterialShell" ];
            }];
        };
    };
}
