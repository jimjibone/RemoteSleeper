#RemoteSleeper

A simple app that puts a remote (local) mac of your choice to sleep when the current mac goes to sleep. Kinda like synchro-sleep mac power awesomeness.

Uses the DFSSHWrapper libssh2 wrapper created by this fella https://github.com/thebsdbox (http://thebsdbox.co.uk).

Check out that website in order to use this wrapper in your own projects.

What does this app do then?
- Allows you to enter the IP address of your remote computer you wish to sleep.
- Allows you to enter the User Name of the user...
- And a Password
- And then whenever you mac running this app goes to sleep it will sleep the other mac! As long as it's still awake. (Handy for my Hackintosh that doesn't like to sleep like normal people).
- Also, this saves your remote macs IP Address and User Name for the next time you use the app to help your fingers stay on.

There is not saving of passwords at the time being though as the saved values are not encrypted!

Also, try out the Bonjour name of your mac instead of the raw IP, it's much nicer.

How I use it:
1. Turn on Hackintosh with Plex Media Server running.
2. Launch this app and enter details.
3. Launch Plex Media Center app.
4. Then let my real mac fall asleep whenever it wants.
5. The app then ssh's the Hackintosh and tells it to sleep.