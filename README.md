# AudioKeepAlive


A small application that runs in the menu bar that intends to solve an issue with wireless USB headsets on macos. 
Macos attempts to put these devices into a low power state, causing audio (including notifications!) to fade in over 1-2 seconds. 
This is an issue I have had on the Razer Blackshark V3 Pro.

This app fixes the issue by playing a silent track in the background constantly. It can be toggled on and off from the menu bar.

Additionally, the app can attempt to turn itself off after an hour of no audio being detected (1 minute polling). It also attempts to start on machine startup if you select that option.
