<div align="center">

# Personal & Work Nix Flake

Reusable Nix Flake for macOS (`nix-darwin`) and NixOS (WSL) with shared Home Manager profiles.

</div>

## Overview
This repository manages three host configurations plus a shared Home Manager layer:

Host | Type | Purpose | Home Profile
-----|------|---------|-------------
`macbook-spw` | macOS (Darwin) | Work laptop (corporate CA + work git email) | `home.nix` (wraps `home-common.nix`)
`macbook-personal` | macOS (Darwin) | Personal laptop | `home-personal.nix` (wraps `home-common.nix`)
`desktop-personal` | NixOS (WSL) | Personal WSL environment | `home-personal.nix`

Shared logic (packages, Neovim, tools, Zsh config, etc.) lives in `home-common.nix`. Each profile supplies its own overrides (Git email, CA certs, ASCII art banner, etc.).

## Features
- Flake-based reproducible system + user environments
- `nix-darwin` for macOS system integration (Touch ID sudo, managed packages)
- Home Manager for user-level tooling & theming
- Theming via [`nix-colors`](https://github.com/misterio77/nix-colors) (`catppuccin-mocha`)
- Corporate/work vs personal separation:
	- Work: injected corporate CA env vars + Git email `chris.rowe@spw.com`
	- Personal: clean environment, Git email `chris@rowe.cloud`
- DRY Neovim setup with LSP, Treesitter, Telescope, completion, snippets
- WSL configuration hardened/minimized (no unnecessary services, trimmed `wsl.conf`)

## Repository Structure
```
flake.nix                # Entry-point: defines inputs & host outputs
flake.lock               # Locked dependency versions
configuration.nix        # Base macOS (darwin) system configuration
home.nix                 # Work Home Manager profile (imports home-common)
home-personal.nix        # Personal Home Manager profile (imports home-common)
home-common.nix          # Shared reusable Home Manager module
nixos/desktop-personal.nix # NixOS (WSL) system configuration
nvim/                     # Lua plugin configs & options for Neovim
	options.lua
	plugin/*.lua
icons/                    # Optional lf icons set
spw-ascii-art.txt         # ASCII banner shown only on work profile
README.md
```

## Flake Inputs
Defined in `flake.nix`:
- `nixpkgs` (unstable) – packages & modules
- `nix-darwin` – macOS system integration
- `home-manager` – user environment management
- `nix-colors` – theme abstraction

## Host Targets
Build or apply a specific host by referencing its flake output.

### macOS (Work)
```bash
darwin-rebuild switch --flake .#macbook-spw
```

### macOS (Personal)
```bash
darwin-rebuild switch --flake .#macbook-personal
```

### NixOS (WSL) Personal
Inside the WSL NixOS instance:
```bash
sudo nixos-rebuild switch --flake .#desktop-personal
```

## Home Manager Profiles
The host definitions pass the appropriate Home Manager module import:
- Work: `home.nix` → includes ASCII art + corporate cert env vars
- Personal: `home-personal.nix` → minimal, no corporate CA variables
- Shared: `home-common.nix` → color scheme, packages, Zsh, Git base, Neovim, tools

### Overridable Parameters (`home-common.nix`)
Parameter | Description
----------|------------
`gitUserEmail` | Git email for the profile
`includeCorporateCA` | Adds `AWS_CA_BUNDLE`, `NODE_EXTRA_CA_CERTS`, `REQUESTS_CA_BUNDLE`
`caCertPath` | Path to corporate cert when enabled
`asciiArtFile` | Optional banner displayed at shell init

## Adding a New Host
1. Create a system module (e.g. `nixos/laptop.nix` or `configuration-personal.nix`).
2. Add an entry to `flake.nix` under `darwinConfigurations` or `nixosConfigurations`.
3. Point Home Manager user to either `home.nix`, `home-personal.nix`, or a new wrapper importing `home-common.nix` with your desired overrides.

Example (Darwin):
```nix
darwinConfigurations."my-mac" = nix-darwin.lib.darwinSystem {
	specialArgs = { inherit nix-colors; };
	modules = [
		./configuration.nix
		home-manager.darwinModules.home-manager {
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.extraSpecialArgs = { inherit nix-colors; };
			home-manager.users."chris" = import ./home-personal.nix;
		}
	];
};
```

## Updating Dependencies
Lock file updates (pin new upstream versions):
```bash
nix flake update
git add flake.lock
git commit -m "chore: update flake inputs"
```

## Common Tasks
Task | Command
-----|--------
Switch work mac config | `darwin-rebuild switch --flake .#macbook-spw`
Switch personal mac    | `darwin-rebuild switch --flake .#macbook-personal`
Switch WSL config       | `sudo nixos-rebuild switch --flake .#desktop-personal`
Dry-run build (mac)     | `darwin-rebuild build --flake .#macbook-spw`
Show available outputs  | `nix flake show`

## WSL Notes
- `appendWindowsPath=false` ensures a clean PATH.
- Minimal services enabled (SSH/cron/avahi disabled by default).
- `security.sudo.wheelNeedsPassword = false;` for convenience—tighten if needed.

## Theming
Color scheme is defined via `nix-colors` (`catppuccin-mocha`), applied to:
- Zsh prompt styling (through generated shell theme snippet)
- Neovim colorscheme (dynamically derived)

## Neovim Stack
Includes (from `home-common.nix`):
- LSP: `nvim-lspconfig`, `lua-language-server`, `terraform-ls`, etc.
- Completion: `nvim-cmp`, `cmp-nvim-lsp`, `cmp_luasnip`, `luasnip`, `friendly-snippets`
- UI/UX: `lualine`, `telescope + fzf native`, `nvim-treesitter.withAllGrammars`, `comment-nvim`, `nerdtree`

## Corporate Certificate Handling
For the work profile, the CA path is hard-coded in:
- `configuration.nix` (`nix.extraOptions` / `ssl-cert-file`)
- `home.nix` (via `home-common.nix` params)
You can extract this into a secret or environment-specific overlay later if needed.

## Extending
Ideas:
- Add `devShells` outputs for language-specific environments
- Introduce overlays for custom package versions
- Add host-specific fonts or application bundles
- Introduce per-host feature modules under a `features/` directory

## Troubleshooting
Issue | Hint
------|-----
Missing package | Add to `home.packages` (user) or `environment.systemPackages` (system)
Git email wrong | Adjust argument in `home.nix` / `home-personal.nix`
Color mismatch  | Change `colorScheme` in `home-common.nix`
WSL PATH noise  | Confirm `/etc/wsl.conf` is applied after terminating WSL session (`wsl --terminate <distro>`)

## License
No explicit license provided. Consider adding one (e.g. MIT) if you plan to share publicly.

---
Maintained by Chris Rowe.

