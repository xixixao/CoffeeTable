# Check to see if a save is required by quering each module
    saveRequired = false
    for module in modules
      if module.saveRequired()
        saveRequired = true
        toAutosave.modules[module.name] = module.saveData()
        # notify module that current state is being saved
        module.savePerformed()


  autosave = ->
    await setTimeout defer(), AUTOSAVE_DELAY
    