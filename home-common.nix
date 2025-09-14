{ config
, pkgs
, nix-colors
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
  ascii = if asciiArtFile != null then "cat ${asciiArtFile}" else "";
in
{
  imports = [
    nix-colors.homeManagerModules.default
  ];

  colorScheme = nix-colors.colorSchemes.catppuccin-mocha;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    _1password-cli
    gh
    terraform
    terraform-docs
    husky
    yamlfmt
    yamllint
    cacert
    nodejs
    tfswitch
    yarn
    python313
    typescript
    open-policy-agent
    volta
  ];

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

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
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
      userName = "Chris Rowe";
      signing = {
        signByDefault = true;
        key = "0x1813F3955C9120C1";
      };
      extraConfig = if includeCorporateCA && caCertPath != null then {
        http.sslCAPath = caCertPath;
      } else {};
    }; in
    if gitUserEmail != null then base // { userEmail = gitUserEmail; } else base;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings.add_newline = false;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
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

  programs.neovim =
  let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      lua-language-server
      terraform-ls
      tflint
      typescript
      xclip
      wl-clipboard
      yamlfmt
      yamllint
      yaml-language-server
    ];
    extraConfig = ''
    autocmd VimEnter * NERDTree | wincmd p
    let NERDTreeSortHiddenFirst=1
    let NERDTreeShowHidden=1
    '';
    extraLuaConfig = ''
      ${builtins.readFile ./nvim/options.lua}
    '';
    plugins = with pkgs.vimPlugins; [
      { plugin = nvim-lspconfig; config = toLuaFile ./nvim/plugin/lsp.lua; }
      typescript-tools-nvim
      cmp-nvim-lsp
      { plugin = ale; config = toLuaFile ./nvim/plugin/ale.lua; }
      { plugin = comment-nvim; config = toLua "require(\"Comment\").setup()"; }
      { plugin = nix-colors-lib.vimThemeFromScheme { scheme = config.colorScheme; }; config = "colorscheme nix-${config.colorScheme.slug}"; }
      neodev-nvim
      { plugin = nvim-cmp; config = toLuaFile ./nvim/plugin/cmp.lua; }
      { plugin = telescope-nvim; config = toLuaFile ./nvim/plugin/telescope.lua; }
      telescope-fzf-native-nvim
      nerdtree
      cmp_luasnip
      luasnip
      friendly-snippets
      lualine-nvim
      nvim-web-devicons
      { plugin = nvim-treesitter.withAllGrammars; config = toLuaFile ./nvim/plugin/treesitter.lua; }
      vim-nix
    ];
  };
}
