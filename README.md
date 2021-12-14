# MultiResetWall

A wall-style multi-instance macro for Minecraft RSG resetting fork from Specnr and Dowsky

## Instructions

I recommend you use multiMC for ease of installation and updating: https://multimc.org/

1. Open all instances of Minecraft and drag them in order to the left most posistion on your taskbar and then run Setup.ahk, you should hear a "done" when its finished
2. Run TheWall.ahk, this will name all instaces for you.
3. Open OBS and ensure all scenes are mapping to the correct minecraft instance. (For OBS setup I recommend you use 1 scene that has all your overlay information in it timer, alerts, camera etc and then use that scene as a source in all scenes you create. Then also look at using Source Record plugin: https://obsproject.com/forum/resources/source-record.1285/)
4. Right click your wall scene and select Fullscreen projector -> Your monitor you are playing on.
5. Press your keys for resetting and off you go. 


## Usage

To use the macro, run TheWall.ahk and wait for it to say ready. Start up OBS, then start up a [Fullscreen projector](https://youtu.be/9YqZ6Ogv3rk).

On the Fullscreen projector, you have a few hotkeys: 
- R: Will reset the instance which your mouse is hovering over
- F: Will play the instance which your mouse is hovering over
- G: Will play the instance which your mouse is hovering over, and reset all of the other ones
- T: Will reset all instances

- There are additional keys for background resetting if you wish to configure. They will be commented out by default.

## Credit

- Specnr :)
- Dowsky
- jojoe77777 for making the original wall macro
