{ config
, pkgs
, nix-colors
, ghostty
, asciiArtFile ? null
, gitUserEmail ? null
, includeCorporateCA ? false
, caCertPath ? null
, ... }:

# Common Home Manager configuration shared across work & personal profiles.
# Differences are injected via arguments.
let
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
  caVars = if includeCorporateCA && caCertPath != null then {
    AWS_CA_BUNDLE = caCertPath;
    NODE_EXTRA_CA_CERTS = caCertPath;
    REQUESTS_CA_BUNDLE = caCertPath;
  } else {};
  ascii = if asciiArtFile != null then ''
    _lw_user="''${USER:-$(id -un 2>/dev/null || echo unknown)}"
    _lw_terminal_id=$(hostname -s 2>/dev/null || hostname)
    _lw_now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    _lw_state_file="$HOME/.cache/lw-last-login"

    _lw_user=$(printf '%s' "$_lw_user" | tr '[:lower:]' '[:upper:]')
    _lw_terminal_id=$(printf '%s' "$_lw_terminal_id" | tr '[:lower:]' '[:upper:]')

    if [ -r "$_lw_state_file" ]; then
      _lw_last=$(head -n 1 "$_lw_state_file")
    else
      _lw_last="$_lw_now"
    fi

    mkdir -p "$HOME/.cache"
    printf '%s\n' "$_lw_now" > "$_lw_state_file"

    _lw_user=$(printf '%-20.20s' "$_lw_user")
    _lw_terminal_id=$(printf '%-20.20s' "$_lw_terminal_id")
    _lw_last=$(printf '%-20.20s' "$_lw_last")

    awk -v user="$_lw_user" -v terminal_id="$_lw_terminal_id" -v last_login="$_lw_last" '
      {
        gsub(/\{\{USERNAME________\}\}/, user)
        gsub(/\{\{TERMINAL_ID_____\}\}/, terminal_id)
        gsub(/\{\{LAST_LOGIN______\}\}/, last_login)
        print
      }
    ' ${asciiArtFile}

    unset _lw_user _lw_terminal_id _lw_last _lw_now _lw_state_file
  '' else "";
in
{
  imports = [
    nix-colors.homeManagerModules.default
  ];

  # Fail fast if we forgot to pass a Git email (prevents silently missing identity
  # and later git commit errors). The work/personal profiles should supply
  # gitUserEmail via their local `home-identity.nix` (gitignored) or a default.
  assertions = [
    {
      assertion = gitUserEmail != null;
      message = ''home-common.nix: gitUserEmail is null.
Set GIT_USER_EMAIL in your environment and rebuild, e.g.:
  GIT_USER_EMAIL="you@domain" sudo -E darwin-rebuild switch --impure --flake .#macbook-spw
'';
    }
  ];

  colorScheme = nix-colors.colorSchemes.catppuccin-mocha;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.file = pkgs.lib.optionalAttrs (asciiArtFile != null) {
    ".hushlogin".text = "";
  };

  home.packages = let
    jetBrainsMonoNerdFont = pkgs.nerd-fonts.jetbrains-mono;
    ghosttyPkg = if pkgs.stdenv.isLinux then [ ghostty.packages.${pkgs.system}.default ] else [ ];
    platformExtras = if pkgs.stdenv.isLinux then [ pkgs.xclip pkgs.wl-clipboard ] else [ ];
    basePackages = with pkgs; [
    _1password-cli
    gh
    terraform
    github-copilot-cli
    # goose-cli # temporarily removed — broken in nixpkgs-unstable (upstream Rust compile bug)
    husky
    jfrog-cli
    yamlfmt
    yamllint
    cacert
    nodejs
    tfswitch
    yarn
    python313
    typescript
    volta
  ];
  in basePackages ++ [ jetBrainsMonoNerdFont ] ++ ghosttyPkg ++ platformExtras;

  home.sessionVariables = {
    EDITOR = "vim";
    VOLTA_HOME = "$HOME/.volta";
  } // caVars;

  programs.zsh = {
    enable = true;
    history = {
      ignoreAllDups = true;
      share = true;
      append = true;
      save = 1000;
      expireDuplicatesFirst = true;
    };
    initContent = ''
      sh ${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
      ${ascii}
    '';
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.granted = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = 
    let base = {
      enable = true;
      signing.format = "openpgp";
      settings = {
        user.name = "Chris Rowe";
        http.sslCAPath = if includeCorporateCA && caCertPath != null then caCertPath else null;
      };
      lfs = {
        enable = true;
      };
    }; in
    if gitUserEmail != null then base // { settings.user.email = gitUserEmail; } else base;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings.add_newline = false;
  };

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    prefix = "^A";
    sensibleOnTop = true;
    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      continuum
      resurrect
      tmux-floax
      tmux-sessionx
      yank
    ];
    extraConfig = ''
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position top
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'

      set -g @catppuccin_window_left_separator ""
      set -g @catppuccin_window_right_separator " "
      set -g @catppuccin_window_middle_separator " █"
      set -g @catppuccin_window_number_position "right"
      set -g @catppuccin_window_default_fill "number"
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_fill "number"
      set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
      set -g @catppuccin_status_modules_right "directory" # date_time"
      set -g @catppuccin_status_modules_left "session"
      set -g @catppuccin_status_left_separator  " "
      set -g @catppuccin_status_right_separator " "
      set -g @catppuccin_status_right_separator_inverse "no"
      set -g @catppuccin_status_fill "icon"
      set -g @catppuccin_status_connect_separator "no"
      set -g @catppuccin_directory_text "#{b:pane_current_path}"

      set -g @continuum-restore 'on'

      set -g @floax-width '80%'
      set -g @floax-height '80%'
      set -g @floax-border-color 'magenta'
      set -g @floax-text-color 'blue'
      set -g @floax-bind 'p'
      set -g @floax-change-path 'true'

      set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
      set -g @fzf-url-history-limit '2000'

      set -g @resurrect-strategy-nvim 'session'

      set -g @sessionx-bind-zo-new-window 'ctrl-y'
      set -g @sessionx-auto-accept 'off'
      set -g @sessionx-bind 'o'
      set -g @sessionx-window-height '85%'
      set -g @sessionx-window-width '75%'
      set -g @sessionx-zoxide-mode 'on'
      set -g @sessionx-filter-current 'false'

      bind ^X lock-server
      bind ^C new-window -c "$HOME"
      bind ^D detach
      bind * list-clients

      bind H previous-window
      bind L next-window

      bind r command-prompt "rename-window %%"
      bind R source-file ~/.config/tmux/tmux.conf
      bind ^A last-window
      bind ^W list-windows
      bind w list-windows
      bind z resize-pane -Z
      bind ^L refresh-client
      bind l refresh-client
      bind | split-window
      bind s split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind '"' choose-window
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r -T prefix , resize-pane -L 20
      bind -r -T prefix . resize-pane -R 20
      bind -r -T prefix - resize-pane -D 7
      bind -r -T prefix = resize-pane -U 7
      bind : command-prompt
      bind * setw synchronize-panes
      bind P set pane-border-status
      bind c kill-pane
      bind x swap-pane -D
      bind S choose-session
      bind R source-file ~/.config/tmux/tmux.conf
      bind K send-keys "clear"\; send-keys "Enter"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = { enable = true; config = {}; };

  # Provide icons for lf if present (optional - can be added by per-profile needs)
  # xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };
    commands.editor-open = ''$$EDITOR $f'';
    keybindings = { "<enter>" = "open"; ee = "editor-open"; };
  };

  programs.gpg = {
    enable = true;
    mutableKeys = true;
    mutableTrust = true;
  };

  programs.uv.enable = true;

  programs.neovim =
  let
    toLuaFile = file: builtins.readFile file;
  in {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withRuby = false;
    withPython3 = false;
    extraPackages =
      let
        linuxClipboard = with pkgs; (if pkgs.stdenv.isLinux then [ xclip wl-clipboard ] else []);
      in with pkgs; [
        lua-language-server
        terraform-ls
        tflint
        typescript
        yamlfmt
        yamllint
        yaml-language-server
      ] ++ linuxClipboard;
    extraConfig = ''
    autocmd VimEnter * NERDTree | wincmd p
    let NERDTreeSortHiddenFirst=1
    let NERDTreeShowHidden=1
    '';
    initLua = ''
      ${builtins.readFile ./nvim/options.lua}
    '';
    plugins = with pkgs.vimPlugins; [
      { plugin = nvim-lspconfig; config = toLuaFile ./nvim/plugin/lsp.lua; type = "lua"; }
      typescript-tools-nvim
      cmp-nvim-lsp
      { plugin = ale; config = toLuaFile ./nvim/plugin/ale.lua; type = "lua"; }
      { plugin = comment-nvim; config = "require(\"Comment\").setup()"; type = "lua"; }
      { plugin = nix-colors-lib.vimThemeFromScheme { scheme = config.colorScheme; }; config = "colorscheme nix-${config.colorScheme.slug}"; type = "viml"; }
      neodev-nvim
      { plugin = nvim-cmp; config = toLuaFile ./nvim/plugin/cmp.lua; type = "lua"; }
      { plugin = telescope-nvim; config = toLuaFile ./nvim/plugin/telescope.lua; type = "lua"; }
      telescope-fzf-native-nvim
      nerdtree
      cmp_luasnip
      luasnip
      friendly-snippets
      lualine-nvim
      nvim-web-devicons
      { plugin = nvim-treesitter.withAllGrammars; config = toLuaFile ./nvim/plugin/treesitter.lua; type = "lua"; }
      vim-nix
    ];
  };
}
