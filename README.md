<h1> <a href="https://redalert.me/" target="_blank"><img src="https://redalert.me/images/logo_big.png" align="right" height="40"></a> RedAlert for iOS</h1>

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/eladnava/redalert-ios?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

RedAlert was developed by volunteers to provide real-time emergency alerts for Israeli citizens.

* [Official Site](https://redalert.me)
* [App Store Listing](https://apps.apple.com/il/app/zb-dwm-htr-wt-bzmn-mt/id937914925)
* [Google Play Listing](https://play.google.com/store/apps/details?id=com.red.alert)

The app relays real-time safety alerts published by the Home Front Command (Pikud Haoref) using the [pikud-haoref-api](https://github.com/eladnava/pikud-haoref-api) Node.js package.

## Screenshots

<img src="./RedAlert/Screenshots/1.png" width="250"> <img src="./RedAlert/Screenshots/2.png" width="250"> <img src="./RedAlert/Screenshots/3.png" width="250">

## Achievements

* Published by **Geektime** as [the fastest rocket alert app](http://www.geektime.co.il/push-notifications-at-protective-edge/)
* Featured by the Israeli government on their [Google+ page](https://plus.google.com/+Israel/posts/U3juWS1YPK4)
* Ranked **1st place** on **Google Play's Top Free** in Israel for 4 weeks during Operation Protective Edge
* Won **2nd place** in the [Ford SYNC AppLink TLV](https://eladnava.com/how-we-won-2nd-place-ford-tel-aviv-hackathon/) hackathon for integrating the app with Ford cars

## Features

#### The fastest, most reliable emergency alert app in Israel.

* Speed & reliability - alerts are received before / during the official siren thanks to dedicated notification servers
* Threat types - receive alerts about rocket fire, hostile aircraft intrusion, terrorist infiltration, and more
* Alert history - see the list of recent alerts, their location, and time of day (in your local time)
* Connectivity test - check, at any time, whether your device is able to receive alerts via the "self-test" option
* Sound selection - choose from 15 unique sounds for alerts
* Silent mode override - the application will override silent / vibrate mode to sound critical alerts
* Vibration - your phone will vibrate in addition to playing the selected alert sound
* Area selection - select your alert cities / regions by searching for them
* I'm safe - let your friends and family know you are safe by sending an "I'm safe" message via the app
* Localization - the app has been translated to multiple languages (Hebrew, English, Russian)

## Requirements for Development
* Xcode 10.1+
* A physical iOS device to test on (the iOS simulator cannot receive push notifications)

## Collaborating

* If you find a bug or wish to make some kind of change, please create an issue first
* Make your commits as tiny as possible - one feature or bugfix at a time
* Write detailed commit messages, in-line with the project's commit naming conventions
* Make sure your code conventions are in-line with the project

## Donations

The application was developed to protect Israeli citizens. 
It costs money to run the servers, your donation is greatly appreciated.

* [Donate via Paypal](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=eladnava@gmail.com&lc=US&item_name=RedAlert&no_note=0&cn=&curency_code=USD&bn=PP-DonationsBF:btn_donateCC_LG.gif:NonHosted)

## Special Thanks

* Thanks to Ilana Badner for the Russian translation
* Thanks to Eden Glant for the "Siren 1" and "Siren 2" sounds

## License

Apache 2.0
