if GetLocale() ~= "ruRU" then return end

local env = select(2, ...)
local L = env.L
-- Translator ZamestoTV
L["ESC"] = "ESC"
L["GOODBYE"] = GOODBYE
L["ACCEPT"] = ACCEPT
L["AUTO_ACCEPT"] = ACCEPT
L["DECLINE"] = DECLINE
L["CANCEL"] = CANCEL
L["CONTINUE"] = CONTINUE
L["COMPLETE"] = COMPLETE
L["OBJECTIVES"] = "Задачи"
L["REWARDS"] = REWARDS
L["LEARN_SPELL_OBJECTIVE"] = LEARN_SPELL_OBJECTIVE
L["WIP"] = "В разработке"

-- Frames
L["DIALOG_FRAME"] = "Окно диалога"
L["DIALOG_SETTINGS_OPEN"] = "Открыть настройки"
L["DIALOG_SETTINGS_MODE"] = "Режим диалогов"

-- Playback
L["PLAYBACK_PAUSE_CHARACTERS"] = {
    "…",
    "!",
    "?",
    ".",
    ",",
    ";",
}
L["PLAYBACK_SPEED_MODIFIER"] = 1

-- Config
L["CONFIG_GENERAL"] = "Общие"
L["CONFIG_GENERAL_PREFERENCES"] = "Предпочтения"
L["CONFIG_GENERAL_PREFERENCES_FONT"] = "Шрифт"
L["CONFIG_GENERAL_OTHER"] = "Другое"
L["CONFIG_GENERAL_OTHER_RESETBUTTON"] = "Сбросить все настройки"
L["CONFIG_GENERAL_OTHER_RESETPROMPT"] = "Вы уверены, что хотите сбросить все настройки?"
L["CONFIG_GENERAL_OTHER_RESETPROMPT_YES"] = "Подтвердить"
L["CONFIG_GENERAL_OTHER_RESETPROMPT_NO"] = "Отмена"

L["CONFIG_DIALOGUE"] = "Диалоги"
L["CONFIG_DIALOGUE_MODE_CLASSIC"] = "Классический"
L["CONFIG_DIALOGUE_MODE_IMMERSIVE"] = "Погружение"

L["CONFIG_EFFECTS"] = "Эффекты"
L["CONFIG_EFFECTS_HIDEUI"] = "Скрывать интерфейс"
L["CONFIG_EFFECTS_CAMERA"] = "Эффекты камеры"
L["CONFIG_EFFECTS_CAMERA_NONE"] = "Нет"
L["CONFIG_EFFECTS_CAMERA_FULL"] = "Полные"
L["CONFIG_EFFECTS_CAMERA_BALANCED"] = "Сбалансированные"
L["CONFIG_EFFECTS_CAMERA_CUSTOM"] = "Пользовательские"

L["CONFIG_TTS"] = "Преобразование текста в речь"
L["CONFIG_KEYBINDINGS"] = "Назначение клавиш"

L["CONFIG_APPEARANCE"] = "Внешний вид"
L["CONFIG_APPEARANCE_DIALOG"] = "Окно диалога"
L["CONFIG_APPEARANCE_DIALOG_FONTSIZE"] = "Размер шрифта"
L["CONFIG_APPEARANCE_IMMERSIVE"] = "Погружение"
L["CONFIG_APPEARANCE_IMMERSIVE_FONTSIZE"] = "Размер шрифта облаков текста"

L["CONFIG_AUDIO"] = "Звук"
L["CONFIG_AUDIO_GENERAL"] = "Общие"
L["CONFIG_AUDIO_GENERAL_ENABLEGLOBALAUDIO"] = "Включить звук"

L["CONFIG_ABOUT"] = "О аддоне"
L["CONFIG_ABOUT_CONTRIBUTORS"] = "Помощники"
L["CONFIG_ABOUT_DEVELOPER"] = "Разработчик"
L["CONFIG_ABOUT_DEVELOPER_ADAPTIVEX"] = "AdaptiveX"
