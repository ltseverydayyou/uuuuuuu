pcall(function()
    local TextChatService = game:GetService("TextChatService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer.PlayerGui

    local chatWindowConfiguration = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local chatBarConfiguration = TextChatService:FindFirstChildOfClass("ChatBarConfiguration")

    if chatWindowConfiguration then
        chatWindowConfiguration.Enabled = true
    end

    if chatBarConfiguration then
        chatBarConfiguration.Enabled = true
    end

    local chatFrame = PlayerGui.Chat and PlayerGui.Chat:FindFirstChild("Frame")
    if chatFrame then
        local chatChannelParentFrame = chatFrame:FindFirstChild("ChatChannelParentFrame")
        local chatBarParentFrame = chatFrame:FindFirstChild("ChatBarParentFrame")

        if chatChannelParentFrame and chatBarParentFrame then
            chatChannelParentFrame.Visible = true
            chatBarParentFrame.Position = chatChannelParentFrame.Position + UDim2.new(0, 0, chatChannelParentFrame.Size.Y.Scale, chatChannelParentFrame.Size.Y.Offset)
        end
    end
end)