;-------------------------------------------------------------------------------
; TonUINO SDcard Manager
; Manage your SD card for your TonUINO
;-------------------------------------------------------------------------------
; AutoHotkey Version: 1.1.x
; Author:		Benedikt Schneyer 

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force ; Only one instance at a time


SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;; ***************
;; global settings
;; ***************


;; ***********
;; init config
;; ***********

IniRead, SDPath, % "settings.ini", % "User", % "SDpath", "Please select the SD Card"
IniRead, AudioPath, % "settings.ini", % "User", % "Audiopath", ""
;; ************
;; run as admin
;; ************

if (AsAdmin && not A_IsAdmin)
{
	Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}

;; ***
;; GUI
;; ***


Gui, New, , TonUINO SD Card manager
Gui, Add, Edit, w300 vSDPathEdit disabled, % SDPath
Gui, Add, Button, gselectSDcard X+m, Select SD Card

Gui, Add, GroupBox, X10 Y+m w400 h100, Copy Audio Files
Gui, Add, Edit, w300 vAudioPathEdit xp+10 yp+20 disabled, % AudioPath
Gui, Add, Button, gselectAudio X+m, Select Audio
Gui, Add, Button, gcopyAudio X20 Y+m, Copy Audio
Gui, Add, Text, vNextFolder, Next folder: NA

Gui, Add, GroupBox, X10 Y+20 w300 h100, SD card check
Gui, Add, Button, gRecheck X+10, Recheck
Gui, Add, Text, vMP3check w200 X20 yp+20, mp3 folder
Gui, Add, Text, vAdvertcheck w200 y+5, advert folder
Gui, Add, Text, vFolderNames w200 y+5, folder names
Gui, Add, Text, vSkippedFolder w200 y+5, skipped folder names
Gui, Add, Text, , Author Benedikt Schneyer

Gui, Show, center autosize, TonUINO SD Manager

checkSDCard(SDPath)
return

/*
    ######## ##     ## ########  ######     		######## ##    ## ########
    ##        ##   ##  ##       ##    ##    		##       ###   ## ##     ##
    ##         ## ##   ##       ##          		##       ####  ## ##     ##
    ######      ###    ######   ##          		######   ## ## ## ##     ##
    ##         ## ##   ##       ##          		##       ##  #### ##     ##
    ##        ##   ##  ##       ##    ##    		##       ##   ### ##     ##
    ######## ##     ## ########  ######     		######## ##    ## ########
*/

selectSDcard:
	FileSelectFolder, SDPath , ,2, Please select the SD Card
	if (SDPath = "")
		SDPath := "Please select the SD Card"
	GuiControl, , SDPathEdit, % SDPath 

	IniWrite, % SDpath, % "settings.ini", % "User", % "SDpath"
	checkSDCard(SDPath)
return

selectAudio:
	FileSelectFolder, AudioPath , ,2, Please select the audio folder
	if (AudioPath = "")
		AudioPath := "Please select the audio folder"
	GuiControl, , AudioPathEdit, % AudioPath 

	IniWrite, % AudioPath, % "settings.ini", % "User", % "AudioPath"
return

copyAudio:
	nextFolder := nextFolder(SDPath)

	FileCreateDir, % SDPath . "\" . nextFolder
	Loop, Files, % AudioPath . "\*.mp3", F
	{
		MsgBox, % A_LoopFileFullPath
		FileCopy, % A_LoopFileFullPath, % SDPath . "\" .  nextFolder . "\" . Format("{1:03}",A_Index) . "-" . A_LoopFileName
	}

	checkSDCard(SDPath)
return

nextFolder(SDPath)
{
	Loop, 99
		If not FileExist(SDPath . "\" . Format("{1:02}",A_Index))
			return Format("{1:02}",A_Index)
}

checkSDCard(SDPath)
{
	; check mp3 folder
	If FileExist(SDPath . "\mp3") {
		Gui, Font, cGreen Bold
		GuiControl, Font, MP3check
		GuiControl, , MP3check, mp3 folder found.
	}
	Else
	{
		Gui, Font, cRed Bold
		GuiControl, Font, MP3check
		GuiControl, , MP3check, mp3 folder is missing!
	}

	; check advert folder
	If FileExist(SDPath . "\advert") {
		Gui, Font, cGreen Bold
		GuiControl, Font, Advertcheck
		GuiControl, , Advertcheck, advert folder found.
	}
	Else
	{
		Gui, Font, cRed Bold
		GuiControl, Font, Advertcheck
		GuiControl, , Advertcheck, advert folder is missing!
	}

	Gui, Font, cGreen Bold
	GuiControl, Font, FolderNames
	GuiControl, , FolderNames, folder names OK

	; check additional folders
	Loop, Files, % SDPath . "\*", D
		If not RegExMatch(A_LoopFileName,"^(\d\d|advert|mp3)$")
		{
			Gui, Font, cRed Bold
			GuiControl, Font, FolderNames
			GuiControl, , FolderNames, Invalid folder detected
			Break
		}

	; next folder
	nextFolder(SDPath)
	GuiControl, , NextFolder, % "Next folder: " . nextFolder(SDPath)

	; check for skipped folder names
	Gui, Font, cGreen Bold
	GuiControl, Font, SkippedFolder
	GuiControl, , SkippedFolder, No folder name skipped

	empty := false
	Loop, 99
		If not FileExist(SDPath . "\" . Format("{1:02}",A_Index))
		{
			empty := true
		}
		Else If (empty) {
			Gui, Font, cRed Bold
			GuiControl, Font, SkippedFolder
			GuiControl, , SkippedFolder, Folder name skipped
			Break
		}

}

Recheck:
	checkSDCard(SDPath)
return

F12::Reload
