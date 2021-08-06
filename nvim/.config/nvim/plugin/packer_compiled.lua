-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/oliverm/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/oliverm/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/oliverm/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/oliverm/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/oliverm/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ["auto_mkdir2.vim"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/auto_mkdir2.vim"
  },
  ["compe-conjure"] = {
    after_files = { "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/compe-conjure/after/plugin/compe_conjure.vim" },
    load_after = {
      conjure = true
    },
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/compe-conjure"
  },
  conjure = {
    after = { "compe-conjure" },
    config = { "require('config.conjure')" },
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/conjure"
  },
  ["lsp-status.nvim"] = {
    after = { "nvim-lspconfig" },
    loaded = true,
    only_config = true
  },
  ["lsp_signature.nvim"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/lsp_signature.nvim"
  },
  ["lua-dev.nvim"] = {
    config = { "require('config.lua-dev')" },
    load_after = {
      ["nvim-lsp-installer"] = true
    },
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/lua-dev.nvim"
  },
  ["nvim-compe"] = {
    after = { "compe-conjure" },
    loaded = true,
    only_config = true
  },
  ["nvim-lightbulb"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/nvim-lightbulb"
  },
  ["nvim-lsp-installer"] = {
    after = { "rust-tools.nvim", "lua-dev.nvim" },
    commands = { "LspUpdateAll" },
    config = { "require('config.nvim-lsp-installer').setup_commands()" },
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/nvim-lsp-installer"
  },
  ["nvim-lspconfig"] = {
    after = { "nvim-lsp-installer", "rust-tools.nvim" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/nvim-lspconfig"
  },
  ["nvim-treesitter"] = {
    config = { "require('config.nvim-treesitter')" },
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/nvim-treesitter"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/packer.nvim"
  },
  ["parinfer-rust"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/parinfer-rust"
  },
  playground = {
    commands = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    loaded = false,
    needs_bufread = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/playground"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/popup.nvim"
  },
  ["rust-tools.nvim"] = {
    config = { "require('config.rust-tools')" },
    load_after = {
      ["nvim-lsp-installer"] = true
    },
    loaded = false,
    needs_bufread = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/rust-tools.nvim"
  },
  ["telescope-fzf-native.nvim"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/telescope-fzf-native.nvim"
  },
  ["telescope.nvim"] = {
    after = { "nvim-lspconfig", "rust-tools.nvim" },
    config = { "require('config.telescope')" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/telescope.nvim"
  },
  ["trouble.nvim"] = {
    after = { "nvim-lspconfig" },
    loaded = true,
    only_config = true
  },
  ["vim-avro"] = {
    loaded = false,
    needs_bufread = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-avro"
  },
  ["vim-fugitive"] = {
    commands = { "G", "Git", "Gclog" },
    loaded = false,
    needs_bufread = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-fugitive"
  },
  ["vim-lastplace"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/vim-lastplace"
  },
  ["vim-sensible"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/vim-sensible"
  },
  ["vim-solarized8"] = {
    config = { "require('config.theme.vim-solarized8')" },
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/vim-solarized8"
  },
  ["vim-terraform"] = {
    config = { "require('config.vim-terraform')" },
    loaded = false,
    needs_bufread = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-terraform"
  },
  ["vim-tmux-navigator"] = {
    loaded = true,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/start/vim-tmux-navigator"
  },
  vimspector = {
    config = { "require('config.vimspector')" },
    keys = { { "", ",D" } },
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/Users/oliverm/.local/share/nvim/site/pack/packer/opt/vimspector"
  },
  ["which-key.nvim"] = {
    after = { "vimspector", "nvim-lspconfig", "rust-tools.nvim", "telescope.nvim" },
    loaded = true,
    only_config = true
  }
}

time([[Defining packer_plugins]], false)
local module_lazy_loads = {
  ["^nvim%-lsp%-installer"] = "nvim-lsp-installer"
}
local lazy_load_called = {['packer.load'] = true}
local function lazy_load_module(module_name)
  local to_load = {}
  if lazy_load_called[module_name] then return nil end
  lazy_load_called[module_name] = true
  for module_pat, plugin_name in pairs(module_lazy_loads) do
    if not _G.packer_plugins[plugin_name].loaded and string.match(module_name, module_pat) then
      to_load[#to_load + 1] = plugin_name
    end
  end

  if #to_load > 0 then
    require('packer.load')(to_load, {module = module_name}, _G.packer_plugins)
    local loaded_mod = package.loaded[module_name]
    if loaded_mod then
      return function(modname) return loaded_mod end
    end
  end
end

if not vim.g.packer_custom_loader_enabled then
  table.insert(package.loaders, 1, lazy_load_module)
  vim.g.packer_custom_loader_enabled = true
end

-- Config for: which-key.nvim
time([[Config for which-key.nvim]], true)
require('config.which-key')
time([[Config for which-key.nvim]], false)
-- Config for: vim-solarized8
time([[Config for vim-solarized8]], true)
require('config.theme.vim-solarized8')
time([[Config for vim-solarized8]], false)
-- Config for: trouble.nvim
time([[Config for trouble.nvim]], true)
require("trouble").setup { }
time([[Config for trouble.nvim]], false)
-- Config for: nvim-treesitter
time([[Config for nvim-treesitter]], true)
require('config.nvim-treesitter')
time([[Config for nvim-treesitter]], false)
-- Config for: lsp-status.nvim
time([[Config for lsp-status.nvim]], true)
require('config.lsp-status') require('config.theme.statusline')
time([[Config for lsp-status.nvim]], false)
-- Config for: nvim-compe
time([[Config for nvim-compe]], true)
require('config.nvim-compe')
time([[Config for nvim-compe]], false)
-- Load plugins in order defined by `after`
time([[Sequenced loading]], true)
vim.cmd [[ packadd telescope.nvim ]]

-- Config for: telescope.nvim
require('config.telescope')

vim.cmd [[ packadd nvim-lspconfig ]]
time([[Sequenced loading]], false)

-- Command lazy-loads
time([[Defining lazy-load commands]], true)
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TSPlaygroundToggle lua require("packer.load")({'playground'}, { cmd = "TSPlaygroundToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file TSHighlightCapturesUnderCursor lua require("packer.load")({'playground'}, { cmd = "TSHighlightCapturesUnderCursor", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file G lua require("packer.load")({'vim-fugitive'}, { cmd = "G", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file LspUpdateAll lua require("packer.load")({'nvim-lsp-installer'}, { cmd = "LspUpdateAll", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Gclog lua require("packer.load")({'vim-fugitive'}, { cmd = "Gclog", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
pcall(vim.cmd, [[command -nargs=* -range -bang -complete=file Git lua require("packer.load")({'vim-fugitive'}, { cmd = "Git", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]])
time([[Defining lazy-load commands]], false)

-- Keymap lazy-loads
time([[Defining lazy-load keymaps]], true)
vim.cmd [[noremap <silent> ,D <cmd>lua require("packer.load")({'vimspector'}, { keys = ",D", prefix = "" }, _G.packer_plugins)<cr>]]
time([[Defining lazy-load keymaps]], false)

vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType terraform ++once lua require("packer.load")({'vim-terraform'}, { ft = "terraform" }, _G.packer_plugins)]]
vim.cmd [[au FileType avro ++once lua require("packer.load")({'vim-avro'}, { ft = "avro" }, _G.packer_plugins)]]
vim.cmd [[au FileType avdl ++once lua require("packer.load")({'vim-avro'}, { ft = "avdl" }, _G.packer_plugins)]]
vim.cmd [[au FileType lua ++once lua require("packer.load")({'lua-dev.nvim'}, { ft = "lua" }, _G.packer_plugins)]]
vim.cmd [[au FileType clojure ++once lua require("packer.load")({'conjure'}, { ft = "clojure" }, _G.packer_plugins)]]
vim.cmd [[au FileType rust ++once lua require("packer.load")({'rust-tools.nvim'}, { ft = "rust" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time([[Sourcing ftdetect script at: /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-terraform/ftdetect/hcl.vim]], true)
vim.cmd [[source /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-terraform/ftdetect/hcl.vim]]
time([[Sourcing ftdetect script at: /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-terraform/ftdetect/hcl.vim]], false)
time([[Sourcing ftdetect script at: /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-avro/ftdetect/avdl.vim]], true)
vim.cmd [[source /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-avro/ftdetect/avdl.vim]]
time([[Sourcing ftdetect script at: /Users/oliverm/.local/share/nvim/site/pack/packer/opt/vim-avro/ftdetect/avdl.vim]], false)
vim.cmd("augroup END")
if should_profile then save_profiles(1) end

end)

if not no_errors then
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
