IM-Setstatus
============

Set the status of Pidgin and Skype to your current location. Other messengers possible...

Description
-----------

The script will query your current accesspoints and, based on their ESSID and/or MAC-ID, it will determine a location. The most basic mechanism is based on a static lookup table inside the script. However, it is also possible to use Google's geolocation-API to get a human-readable address.

The location is then set as your instant-messenger status. Currently, Pidgin and Skype are supported.

If you use Dropbox, it will also add a file containing your current location into your Dropbox folder. This might be handy in case you "lose" your machine...

Preparations
------------

 - To make the reverse location lookup possible, you need a key for the Google location API. It can be obtained here: https://developers.google.com/maps/documentation/business/geolocation/#api-key
   This key needs to be saved as a single, raw line (no newlines) in a file called `apikey.dat` alongside the file `im-setstatus.sh`.
   This can be done like this:
   ```bash
   cd im-setstatus
   echo -n "XXXXXXX" > apikey.dat
   ```
   where "XXXXXXX" is your API key.
 - Please note: you can not perform more than 100 lookups per day with the free version of your API-key
 - The static lookup-table might need some entries for your most frequently visited locations.
 - The variables in the beginning of the script need to be adapted to your liking
 - Skype will require you to authorize the script when executing it the first time while Skype is running.
 - To be fully functional, the script requires the following dependencies:
  - Pidgin Instant Messenger
  - Skype
  - skype4py (python package to set your status in Skype)
  - Python2.7 (for skype4py)
  - notify-send (to give you a visual feedback on your screen)
  - Dropbox
 - You should be connected to a wireless network.

Usage
-----

`./im-setstatus.sh`

License
-------

Copyright (c) 2014 Carlchristian Eckert  
Licensed under the MIT license.  
Free as in beer.
