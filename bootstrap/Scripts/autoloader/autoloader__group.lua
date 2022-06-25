local settings = getMudletHomeDir() .. '/settings.xml'
__settingsReloadTimer__ = nil
function settingsReloaded(_, path)
  if path == settings then
    if __settingsReloadTimer__ then killTimer(__settingsReloadTimer__) end
    removeFileWatch(settings)
    __settingsReloadTimer__ = tempTimer(0.25, function()
      cecho('\n<cyan>MAIN SETTINGS RELOADED WITH LATEST CHANGES\n')
      installPackage(settings)
      addFileWatch(settings)
    end)
  end
end

cecho('\n<cyan>Watching settings file for changes...\n')
addFileWatch(settings)
registerAnonymousEventHandler('sysPathChanged', settingsReloaded)


local libraries = getMudletHomeDir() .. '/libraries.xml'
__librariesReloadTimer__ = nil
function librariesReloaded(_, path)
  if path == libraries then
    if __librariesReloadTimer__ then killTimer(__librariesReloadTimer__) end
    removeFileWatch(libraries)
    __librariesReloadTimer__ = tempTimer(0.25, function()
      cecho('\n<cyan>SECONDARY LIBRARIES RELOADED WITH LATEST CHANGES\n')
      installPackage(libraries)
      addFileWatch(libraries)
    end)
  end
end

cecho('\n<cyan>Watching libraries file for changes...\n')
addFileWatch(libraries)
registerAnonymousEventHandler('sysPathChanged', librariesReloaded)
