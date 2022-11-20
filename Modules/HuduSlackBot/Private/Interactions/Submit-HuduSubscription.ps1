function Submit-HuduSubscription {
    Param($Interaction)

    $ModalValues = $Interaction.view.state.values

    $Interaction | ConvertTo-Json -Depth 10
    $ConversationID = $ModalValues.ChannelSelect.ChannelID | Select-Object -ExpandProperty selected_conversations

    try { 
        $Channel = Get-SlackChannelInfo -ChannelID $ConversationID -ErrorAction Stop
        $Channel | ConvertTo-Json -Depth 10
        
        $TableRow = @{
            RecordType = [string]$ModalValues.RecordTypeSelect.RecordType.selected_option.value
            Actions = [string]($ModalValues.ActionTypeSelect.ActionType.selected_options.value -join ',')
            ChannelID  = [string]$Channel.ID
            CreatedBy  = [string]$Interaction.user.id
        }
        if ($TableRow.RecordType -eq 'Asset') {
            
            if ($ModalValues.AssetLayoutSelect.AssetLayout.selected_option) {
                $Id, $Name = $ModalValues.AssetLayoutSelect.AssetLayout.selected_option.value -split '='
                $TableRow.AssetLayoutId = "$Id"
                $TableRow.AssetLayoutName = "$Name"
            }
            else {
                $TableRow.AssetLayoutId = "0"
                $TableRow.AssetLayoutName = 'All Asset Layouts'
            }
        }

        $AddSubscription = @{
            TableName    = 'HuduActivitySubscriptions'
            PartitionKey = 'Subscription'
            TableRow     = $TableRow
        }
        Set-SlackBotData @AddSubscription
        Update-SlackAppHome -UserId $Interaction.user.id
    }
    catch {
        $ErrorConvo = @{
            Method = 'conversations.open'
            Body   = @{
                users     = $Interaction.user.id
                return_im = $true
            }
        }
        $Conversation = Send-SlackApi @ErrorConvo
        if ($Conversation.ok) {
            $ErrorMessage = @{
                Channel = $Conversation.channel.id
                Text    = ('Uh oh. I could not access the conversation specified <#{0}>. If this is not a public channel make sure to invite me!' -f $ConversationID)
            }
            Send-SlackMessage @ErrorMessage
        }
    }
}
