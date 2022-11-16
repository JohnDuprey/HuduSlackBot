# HuduBot - Slack bot for Hudu

This is an Azure function app created to bridge the gap between [Slack](https://slack.com) and [Hudu](https://hudu.com) to provide additional context in your work chat.

## Features
- Link unfurling
- Activity log subscriptions

## Requirements
- Custom Slack app deployed to your team
- Azure subscription and function app
- Hudu hostname and API key

## Installation
1. Generate a Hudu API key https://yourhuduserver/admin/api_keys
2. Deploy the [Slack App](https://api.slack.com/apps) using the App Manifest in the Deployment folder (make sure to update the parameters to match your environment)
3. Deploy the Azure Function App to your environment
4. Fill in the details of the deployment template with the appropriate API keys.
5. Generate function keys for each HTTP trigger, Send-SlackInteraction and Send-SlackEvent, update your Slack App configuration accordingly.
5. Invite @HuduBot to any private channels you would like it to function in.


## Copyright
This project utilizes some of the helper functions and approaches written by Kelvin Tegelaar from the CIPP project https://github.com/KelvinTegelaar/CIPP and is licensed under the same terms.

Special thanks to [@KelvinTegelaar](https://github.com/KelvinTegelaar), [@lwhitelock](https://github.com/lwhitelock) [@PalmEmanuel](https://github.com/palmemanuel), [@RamblingCookieMonster](https://github.com/ramblingcookiemonster) for inspiration and their PowerShell modules that helped make this possible.