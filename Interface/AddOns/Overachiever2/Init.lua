-- Overachiever2: Init
-- Global table initialization. Loaded first via .toc to ensure
-- other files can reference these without safe-init boilerplate.

-- Runtime-only tables: safe to create fresh since nothing external populates them.
Overachiever2 = {}
Overachiever2.Utils = {}

-- SavedVariable (declared in .toc): WoW may have already loaded saved data into
-- this global, so use "or {}" to avoid overwriting it.
Overachiever2_Settings = Overachiever2_Settings or {}