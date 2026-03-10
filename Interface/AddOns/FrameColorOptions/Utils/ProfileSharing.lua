local _, private = ...

local L = FrameColor.API:GetLocale()
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("AceSerializer-3.0")

function private:GetSerializedProfile()
  --AceSerialize
  local serializedProfile = LibSerialize:Serialize(FrameColor.db.profile)
  --LibDeflate
  local compressedProfile = LibDeflate:CompressZlib(serializedProfile)
  local encodedProfile = LibDeflate:EncodeForPrint(compressedProfile)
  return encodedProfile
end

function private:ImportProfile(input)
  -- @TODO add proper validation.
  --empty?
  if input == "" then
    FrameColor:Print(L["import_empty_string_error"])
    return
  end
  --LibDeflate decode
  local decoded_profile = LibDeflate:DecodeForPrint(input)
  if decoded_profile == nil then
    FrameColor:Print(L["import_decoding_failed_error"])
    return
  end
  --LibDefalte uncompress
  local uncompressed_profile = LibDeflate:DecompressZlib(decoded_profile)
  if uncompressed_profile == nil then
    FrameColor:Print(L["import_uncompression_failed_error"])
    return
  end
  --AceSerialize
  --deserialize the profile and overwirte the current values
  local valid, imported_Profile = LibSerialize:Deserialize(uncompressed_profile)
  if valid and imported_Profile then
  for k, v in pairs(imported_Profile) do
    FrameColor.db.profile[k] = CopyTable(v)
  end
  else
    FrameColor:Print(L["invalid_profile_error"])
  end
end
