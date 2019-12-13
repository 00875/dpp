
-- Copyright (C) 2016-2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

DPP_lang = DPP_lang or {}
local lang = DPP_lang

local gmod_language, LastLanguage

function lang.update()
	gmod_language = gmod_language or GetConVar('gmod_language')
	if not gmod_language then return end

	lang.CURRENT_LANG = gmod_language:GetString():lower():trim()

	if LastLanguage ~= lang.CURRENT_LANG then
		hook.Run('DPP.LanguageChanged', LastLanguage, lang.CURRENT_LANG)
		hook.Run('DPP.LanguageChanged2', LastLanguage, lang.CURRENT_LANG)
	end

	LastLanguage = lang.CURRENT_LANG

	net.Start('DPP.UpdateLang')
	net.WriteString(lang.CURRENT_LANG)
	net.SendToServer()
end

cvars.AddChangeCallback('gmod_language', lang.update, 'DPP')
lang.update()
timer.Simple(0, lang.update)