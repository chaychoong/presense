# PreSense

The PreSense iOS App works together with Estimote beacons and Slack to help you check on your coworker's availability.

The Android app can be found here: https://github.com/jang93/PreSense_Android

### Prerequisite

To start off, you need some Estimote beacons, preferably one per office or room! You will also need a Slack team.

### PreSense Bot installation instructions
The PreSense Bot repo can be found here: https://github.com/chaychoong/PreSensebot

* Click on your team name on the Slack web interface and select **Apps & integrations**. Alternatively, you can use this URL: https://slack.com/apps

* Search for "Bots" using the search bar and select the first option with the description "Connect a bot to the Slack Real Time Messaging API"

* Click on **Install** under your team name.

* Choose a username for your bot and select **Add Bot Integration**.

* Jot down the **API Token** generated. We will need this later.

* You can choose to customize the icon for the bot and add a name and description. Once you are done, hit **Save Integration**.

* Click on this button: [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/chaychoong/presensebot/tree/master)

* You will need a Heroku account to deploy the app. If you already have a Heroku account, log in at the bottom of the page.

* Once you have created an account, hit back and log in!

* Give your app a name. I know it says Optional, but you will need this for your configuration.

* Under Config Variables, insert your API Token under **HUBOT_SLACK_TOKEN** and set the **HEROKU_URL** to https://[App Name].herokuapp.com/

* Hit **Deploy for Free** and you are done!

### Running the bot

The bot listens to only one command: where is [name]. The bot will reply "[name] is available", "[name] is busy" or "[name] is not found", depending on the status of the username.

You can give the bot the "where is [name]" command by dropping it a Direct Message, or invite the bot into any Slack channel and tag it in your message, eg. "@botname: where is [name]"

### Running the app

* Ensure you are in the region of a transmitting Estimote Beacon with a UUID of B9407F30-F5F8-466E-AFF9-25556B57FE6D

* Set your username. This may not necessarily be your Slack username, but the name that others will use to check on you!

* Use this as the Webhook URL: https://[heroku app name].herokuapp.com/hubot/notify/general

* Hit Register and you are done! Your status will automatically be set as **Available**. You can toggle your status between **Available** and **Busy**.

* When you go out of range of your beacon, your status will be set to "out of offce". During this state, you will not be able to toggle your status.

* When you are back in range of your beacon, your status will be reset to **Available**

Enjoy!
