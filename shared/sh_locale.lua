-- =====================================================================
-- S82Studio - He thong da ngon ngu
-- Cach dung: Locale('key'), hoac Locale('key', arg1, arg2, ...) neu chuoi
-- co chua %s / %d (string.format)
-- =====================================================================

---@param key string
---@vararg any
---@return string
function Locale(key, ...)
    local lang = Config.Locale or 'vi'
    local pack = Locales[lang] or Locales['en'] or {}
    local str = pack[key] or (Locales['en'] and Locales['en'][key]) or key

    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then
            return formatted
        end
    end

    return str
end
