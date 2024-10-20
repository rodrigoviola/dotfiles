{
  description = "MacBook system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
    let
      configuration = { pkgs, config, ... }: {

        nixpkgs.config.allowUnfree = true;

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages =
          [
            pkgs.mkalias
            pkgs.nixpkgs-fmt
          ];

        homebrew = {
          enable = true;

          taps = [
            "hashicorp/tap"
          ];

          brews = [
            "aria2"
            "aws-vault"
            "awscli"
            "bat"
            "coreutils"
            "curl"
            "eksctl"
            "eza"
            "fd"
            "fzf"
            "gh"
            "git"
            "gnu-sed"
            "gnu-tar"
            "gnupg"
            "hashicorp/tap/terraform"
            "helm"
            "helmfile"
            "htop"
            "hugo"
            "jq"
            "k9s"
            "krew"
            "kubectx"
            "kubernetes-cli"
            "kustomize"
            "lazydocker"
            "lazygit"
            "neofetch"
            "neovim"
            "nmap"
            "openconnect"
            "p7zip"
            "pwgen"
            "ripgrep"
            "telnet"
            "tmux"
            "tree"
            "watch"
            "wget"
            "yq"
            "yt-dlp"
          ];

          casks = [
            "alfred"
            "anydesk"
            "balenaetcher"
            "battery"
            "bettertouchtool"
            "bisq"
            "chatgpt"
            "coconutbattery"
            "docker"
            "drawio"
            "firefox"
            "focus"
            "font-ibm-plex"
            "font-meslo-lg-nerd-font"
            "google-chrome"
            "iterm2"
            "keepingyouawake"
            "keyboardcleantool"
            "libreoffice"
            "microsoft-onenote"
            "microsoft-remote-desktop"
            "notion"
            "raspberry-pi-imager"
            "session-manager-plugin"
            "sparrow"
            "spectacle"
            "spotify"
            "telegram"
            "the-unarchiver"
            "utm"
            "visual-studio-code"
            "vmware-fusion"
            "whatsapp"
            # "mactex" used for cv.pdf, to be replaced with xu-cheng/latex-docker            
          ];

          onActivation.cleanup = "zap";
        };

        fonts.packages = [
          (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

        system.activationScripts.applications.text =
          let
            env = pkgs.buildEnv {
              name = "system-applications";
              paths = config.environment.systemPackages;
              pathsToLink = "/Applications";
            };
          in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';

        # Configure OS settings -- Check some available options at https://mynixos.com/nix-darwin/options
        system.defaults.dock.autohide = true;
        system.defaults.NSGlobalDomain.InitialKeyRepeat = 15; # Short
        system.defaults.NSGlobalDomain.KeyRepeat = 2; # Fast
        system.keyboard.enableKeyMapping = true;
        system.keyboard.swapLeftCtrlAndFn = true;
        time.timeZone = "America/Asuncion";

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mbp
      darwinConfigurations."mbp" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "user";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mbp".pkgs;
    };
}
