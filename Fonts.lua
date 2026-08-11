local env = select(2, ...)
local UIFont = env.modules:Import("packages\\ui-font")
local UIFont_FontUtil = env.modules:Import("packages\\ui-font\\font-util")

UIFont.LWFontSizeDef = {
    ImmersiveChatBubbleFont = 13,
    ParchmentText = 14,
    ParchmentOptionText = 14,
    ParchmentItemText = 12,
    ParchmentRewardTagText = 10,
    ParchmentCategoryLabelText = 14,
    ParchmentHeaderPrimaryText = 18,
    ParchmentHeaderSecondaryText = 12,
}

UIFont.ImmersiveChatBubbleFont = UIFont_FontUtil:CreateFontObject("ImmersiveChatBubbleFont")
UIFont.ImmersiveChatBubbleFont:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ImmersiveChatBubbleFont, "")

UIFont.ParchmentText = UIFont_FontUtil:CreateFontObject("ParchmentText")
UIFont.ParchmentText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentText, "")

UIFont.ParchmentOptionText = UIFont_FontUtil:CreateFontObject("ParchmentOptionText")
UIFont.ParchmentOptionText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentOptionText, "")

UIFont.ParchmentItemText = UIFont_FontUtil:CreateFontObject("ParchmentItemText")
UIFont.ParchmentItemText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentItemText, "")

UIFont.ParchmentRewardTagText = UIFont_FontUtil:CreateFontObject("ParchmentRewardTagText")
UIFont.ParchmentRewardTagText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentRewardTagText, "OUTLINE")

UIFont.ParchmentCategoryLabelText = UIFont_FontUtil:CreateFontObject("ParchmentCategoryLabelText")
UIFont.ParchmentCategoryLabelText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentCategoryLabelText, "")

UIFont.ParchmentHeaderPrimaryText = UIFont_FontUtil:CreateFontObject("ParchmentHeaderPrimaryText")
UIFont.ParchmentHeaderPrimaryText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentHeaderPrimaryText, "")

UIFont.ParchmentHeaderSecondaryText = UIFont_FontUtil:CreateFontObject("ParchmentHeaderSecondaryText")
UIFont.ParchmentHeaderSecondaryText:SetFont(GameFontNormal:GetFont(), UIFont.LWFontSizeDef.ParchmentHeaderSecondaryText, "")
