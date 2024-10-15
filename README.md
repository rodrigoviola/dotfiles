# Notes 

Starting from scratch on a brand new computer

```sh
# Install dependencies
xcode-select --install

# Install Nix package manager
sh <(curl -L https://nixos.org/nix/install)

# Install nix-darwin
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake '.#mbp'

# Rebuild config
darwin-rebuild switch --flake '.#mbp'
```
