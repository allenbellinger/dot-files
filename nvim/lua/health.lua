--[[
--
-- This file is not required for your own configuration,
-- but helps people determine if their system is setup correctly.
--
--]]

local check_version = function()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), '0.12.0') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

local check_external_reqs = function()
  -- Basic utils: `git`, `make`, `unzip`
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

-- Language servers and formatters are installed externally (Homebrew, uv,
-- cargo) rather than by a plugin, so surface anything missing from PATH.
local check_language_tooling = function()
  local tools = {
    ['typescript-language-server'] = 'brew install typescript-language-server',
    ['vscode-eslint-language-server'] = 'brew install vscode-langservers-extracted',
    ['vscode-json-language-server'] = 'brew install vscode-langservers-extracted',
    ['yaml-language-server'] = 'brew install yaml-language-server',
    ['lua-language-server'] = 'brew install lua-language-server',
    ['stylua'] = 'brew install stylua',
    ['stylelint'] = 'brew install stylelint',
    ['prettierd'] = 'brew install prettierd',
    ['ruff'] = 'brew install ruff',
    ['rust-analyzer'] = 'rustup component add rust-analyzer',
    ['rustfmt'] = 'rustup component add rustfmt',
    ['basedpyright-langserver'] = 'brew install basedpyright',
    ['nginx-language-server'] = 'uv tool install nginx-language-server',
    ['nginxfmt'] = 'uv tool install nginxfmt',
    ['ngserver'] = 'pnpm add -g @angular/language-server',
    ['stylelint-language-server'] = 'pnpm add -g @stylelint/language-server',
  }

  for _, exe in ipairs(vim.fn.sort(vim.tbl_keys(tools))) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found: '%s'", exe))
    else
      vim.health.warn(string.format("Missing: '%s' -- install with `%s`", exe, tools[exe]))
    end
  end

  vim.health.info [[`ngserver` (angularls) and `stylelint-language-server` are
resolved from the project's `node_modules/.bin` when it ships them, otherwise
from the global pnpm install above. They are editor tools, so projects are not
expected to carry them as devDependencies.]]
end

return {
  check = function()
    vim.health.start 'kickstart.nvim'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
  You do not need to install tooling for languages you do not use.]]

    vim.health.info('System Information: ' .. vim.inspect(vim.uv.os_uname()))

    check_version()
    check_external_reqs()
    check_language_tooling()
  end,
}
