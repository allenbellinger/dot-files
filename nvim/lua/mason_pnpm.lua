local MIN_RELEASE_AGE_MINUTES = 20160
local MIN_RELEASE_AGE_SECONDS = MIN_RELEASE_AGE_MINUTES * 60

local spawn = require('mason-core.spawn')
local semver = require('mason-core.semver')
local Purl = require('mason-core.purl')

local cache = {}

local function cache_key(pkg)
  return pkg .. os.date('%Y-%m-%d')
end

local function purl_to_npm(purl)
  if purl.namespace then
    return ('%s/%s'):format(purl.namespace, purl.name)
  end
  return purl.name
end

local function iso_to_epoch(iso)
  local y, mo, d, h, mi, s = iso:match('(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
  if not y then
    return nil
  end
  local t = os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
  })
  return t - (os.difftime(os.time(os.date('!*t')), os.time(os.date('*t'))))
end

local function get_aged_versions_async(pkg)
  local key = cache_key(pkg)
  if cache[key] ~= nil then
    return cache[key]
  end
  local result = spawn.npm({ 'view', '--json', pkg, 'time' })
  if not result:is_success() then
    return nil
  end
  local ok, times = pcall(vim.json.decode, result:get_or_nil().stdout)
  if not ok or type(times) ~= 'table' then
    return nil
  end
  local now = os.time()
  local versions = {}
  for version, iso in pairs(times) do
    if version ~= 'created' and version ~= 'modified' and version ~= 'unpublished' and type(iso) == 'string' then
      local epoch = iso_to_epoch(iso)
      if epoch and (now - epoch) >= MIN_RELEASE_AGE_SECONDS then
        table.insert(versions, version)
      end
    end
  end
  table.sort(versions, function(a, b)
    local sa = semver.parse(a):get_or_nil()
    local sb = semver.parse(b):get_or_nil()
    if not sa or not sb then
      return a > b
    end
    return sb < sa
  end)
  cache[key] = versions
  return versions
end

local function cached_aged_versions(pkg)
  return cache[cache_key(pkg)]
end

local function newest_aged_version_async(pkg)
  local versions = get_aged_versions_async(pkg)
  if versions and versions[1] then
    return versions[1]
  end
  return nil
end

local function newest_aged_version_cached(pkg)
  local versions = cached_aged_versions(pkg)
  if versions and versions[1] then
    return versions[1]
  end
  return nil
end

local function make_compiler(mason_result, npm_compiler)
  return setmetatable({
    install = function(ctx, source)
      return mason_result.try(function(try)
        try(ctx.spawn.pnpm({ 'init' }))
        local package_json = try(mason_result.pcall(vim.json.decode, ctx.fs:read_file('package.json')))
        package_json.name = '@mason/' .. package_json.name
        package_json.devEngines = nil
        package_json = try(mason_result.pcall(vim.json.encode, package_json, {}))
        ctx.fs:write_file('package.json', package_json)

        local version = newest_aged_version_async(source.package) or source.version
        if version ~= source.version then
          ctx.stdio_sink:stdout(
            ('%s@%s is younger than %d minutes; installing %s@%s instead\n'):format(
              source.package,
              source.version,
              MIN_RELEASE_AGE_MINUTES,
              source.package,
              version
            )
          )
        end
        ctx.stdio_sink:stdout(('Installing npm package %s@%s with pnpm\n'):format(source.package, version))

        try(ctx.spawn.pnpm({
          'add',
          '--config.node-linker=hoisted',
          ('%s@%s'):format(source.package, version),
          source.extra_packages or vim.NIL,
        }))
      end)
    end,
    get_versions = function(purl, source)
      local versions = get_aged_versions_async(purl_to_npm(purl))
      if versions then
        return mason_result.success(versions)
      end
      return npm_compiler.get_versions(purl, source)
    end,
  }, { __index = npm_compiler })
end

local function patch_get_latest_version()
  local AbstractPackage = require('mason-core.package.AbstractPackage')
  local original = AbstractPackage.get_latest_version
  AbstractPackage.get_latest_version = function(self)
    local purl = Purl.parse(self.spec.source.id):get_or_nil()
    if purl and purl.type == 'npm' then
      local version = newest_aged_version_cached(purl_to_npm(purl))
      if version then
        return version
      end
    end
    return original(self)
  end
end

local function warm_installed_cache()
  local registry = require('mason-registry')
  local suspend_fns = {}
  for _, pkg in ipairs(registry.get_installed_packages()) do
    local purl = Purl.parse(pkg.spec.source.id):get_or_nil()
    if purl and purl.type == 'npm' then
      local npm_name = purl_to_npm(purl)
      table.insert(suspend_fns, function()
        get_aged_versions_async(npm_name)
      end)
    end
  end
  if #suspend_fns > 0 then
    require('mason-core.async').wait_all(suspend_fns)
  end
end

local function wrap_update_with_warmup(registry)
  registry.update = function(callback)
    local async = require('mason-core.async')
    local noop = function() end
    async.run(function()
      registry:emit('update:start', registry.sources)
      async.scheduler()
      pcall(warm_installed_cache)
      require('mason-registry.installer')
        .install(registry.sources, function(finished, all)
          registry:emit('update:progress', finished, all)
        end)
        :on_success(function(updated_registries)
          registry:emit('update:success', updated_registries)
        end)
        :on_failure(function(errors)
          registry:emit('update:failed', errors)
        end)
        :get_or_throw()
    end, callback or noop)
  end
end

local M = {}

function M.setup(opts)
  require('mason').setup(opts)
  local mason_compiler = require('mason-core.installer.compiler')
  local mason_result = require('mason-core.result')
  local npm_compiler = require('mason-core.installer.compiler.compilers.npm')
  mason_compiler.register_compiler('npm', make_compiler(mason_result, npm_compiler))
  patch_get_latest_version()

  wrap_update_with_warmup(require('mason-registry'))
end

return M
