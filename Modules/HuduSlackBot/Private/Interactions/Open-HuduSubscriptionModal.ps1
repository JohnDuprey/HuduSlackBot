function Open-HuduSubscriptionModal {
    param($TriggerId)

    $RecordTypes = @('Article', 'Asset', 'Company', 'User', 'Website')
    $RecordTypeOptions = foreach ($RecordType in $RecordTypes) {
        @{
            text  = @{
                type = 'plain_text'
                text = $RecordType
            }
            value = $RecordType
        }
    }
    # Get Hudu info
    Initialize-HuduApi
    $AssetLayouts = Get-HuduAssetLayouts | Sort-Object -Property name
    $AssetLayoutOptions = foreach ($AssetLayout in $AssetLayouts) {
        @{
            text  = @{
                type = 'plain_text'
                text = $AssetLayout.name
            }
            value = ('{0}={1}' -f $AssetLayout.id, $AssetLayout.name)
        }
    }

    $Blocks = [PSCustomObject]@(
        @{
            type = 'section'
            text = @{
                type = 'mrkdwn'
                text = "Subscribe to specific Activity Log events from Hudu. Just pick a Resource Type, Action and a Channel from the lists below.`nIf you are selecting an Asset, you can choose to subscribe to all layouts or a specific one."
            }
        }
        @{
            type = 'divider'
        }
        @{
            type     = 'input'
            block_id = 'RecordTypeSelect'
            label    = @{
                type = 'plain_text'
                text = 'Record Type'
            }
            element  = @{
                action_id   = 'RecordType'
                type        = 'static_select'
                placeholder = @{
                    type = 'plain_text'
                    text = 'Select a Record Type'
                }
                options     = $RecordTypeOptions
            }
        }
        @{
            type     = 'input'
            block_id = 'AssetLayoutSelect'
            label    = @{
                type = 'plain_text'
                text = 'Asset Layout'
            }
            optional = $true
            element  = @{
                action_id   = 'AssetLayout'
                type        = 'static_select'
                placeholder = @{
                    type = 'plain_text'
                    text = 'All Asset Layouts'
                }
                options     = $AssetLayoutOptions
                
            }
        }
        @{
            type     = 'input'
            block_id = 'ActionTypeSelect'
            label    = @{
                type = 'plain_text'
                text = 'Activity Log Action'
            }
            element  = @{
                action_id   = 'ActionType'
                type        = 'multi_static_select'
                placeholder = @{
                    type = 'plain_text'
                    text = 'Select an Action'
                }
                options     = @(
                    @{
                        text  = @{
                            type = 'plain_text'
                            text = 'Archived'
                        }
                        value = 'archived'
                    }
                    @{
                        text  = @{
                            type = 'plain_text'
                            text = 'Created'
                        }
                        value = 'created'
                    }
                    @{
                        text  = @{
                            type = 'plain_text'
                            text = 'Updated'
                        }
                        value = 'updated'
                    }
                    @{
                        text  = @{
                            type = 'plain_text'
                            text = 'Unarchived'
                        }
                        value = 'unarchived'
                    }
                )
            }
        }
        @{
            type     = 'input'
            block_id = 'ChannelSelect'
            label    = @{
                type = 'plain_text'
                text = 'Channel'
            }
            element  = @{
                action_id          = 'ChannelID'
                type               = 'multi_conversations_select'
                filter             = @{
                    include = @(
                        'public'
                        'private'
                    )
                }
                max_selected_items = 1
                
            }
        }
    
    )

    $View = [PSCustomObject]@{
        type        = 'modal'
        callback_id = 'Open-HuduSubscriptionModel'
        title       = @{
            type = 'plain_text'
            text = 'Add Subscription'
        }
        submit      = @{
            type = 'plain_text'
            text = 'Add'
        }
        close       = @{
            type = 'plain_text'
            text = 'Cancel'
        }
        blocks      = $Blocks
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Host $View
    $Body = @{
        trigger_id = $TriggerId
        view       = $View
    }

    Write-Host ($Body | ConvertTo-Json)
    try {
        $OpenModal = Send-SlackApi -Method 'views.open' -Body $Body
        if ($OpenModal.ok) {
            Write-Host 'Opened subscription modal'
        }
        else {
            Write-Host "Unable to open modal"
            $OpenModal
        }
    }
    catch {
        Write-Host "MODAL ERROR: $($_.Exception.Message)"
    }
}
