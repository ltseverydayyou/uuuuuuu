pcall(function()
    local TextChatService = game:GetService("TextChatService")
    local chatWindowConfiguration = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local chatBarConfiguration = TextChatService:FindFirstChildOfClass("ChatBarConfiguration")

    if chatWindowConfiguration then
        chatWindowConfiguration.Enabled = true
    end

    if chatBarConfiguration then
        chatBarConfiguration.Enabled = true
    end

    if game:GetService("Players").LocalPlayer.PlayerGui.Chat.Frame then
        local chatFrame = game:GetService("Players").LocalPlayer.PlayerGui.Chat.Frame
        chatFrame.ChatChannelParentFrame.Visible = true
        chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position + UDim2.new(0, 0, chatFrame.ChatChannelParentFrame.Size.Y.Scale, chatFrame.ChatChannelParentFrame.Size.Y.Offset)
    end
end)