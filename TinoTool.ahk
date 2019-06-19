;-------------------------------------------------------------------------------
; TonUINO SDcard Manager
; Manage your SD card for your TonUINO
;-------------------------------------------------------------------------------
; AutoHotkey Version: 1.1.x
; Author:		Benedikt Schneyer 

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force ; Only one instance at a time
#NoTrayIcon

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;; ***************
;; global settings
;; ***************

VERSION := "0.5.2"
AUDIOPROMPT := "Please select the audio folder"

;; ***********
;; init config
;; ***********

IniRead, SDPath, % "settings.ini", % "User", % "SDpath", % "Please select the SD Card"
IniRead, AudioPath, % "settings.ini", % "User", % "Audiopath", % AUDIOPROMPT
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
Gui, Add, Button, vCopyAudioBut gcopyAudio X20 Y+m, Copy Audio
Gui, Add, Checkbox, vWithFilename checked X+m, Append original filename to number 
Gui, Add, Text, vNextFolder, Next folder: NA

Gui, Add, GroupBox, X10 Y+20 w300 h105, SD card check
Gui, Add, Button, gRecheck X+10, Recheck
Gui, Add, Text, vCheck w200 X20 yp+20, SD is fine
Gui, Add, Edit, vErrors w280 h60
Gui, Add, Link, , <a href="https://github.com/DarthBrento/TinoTool">Project on GitHub</a>
Gui, Add, Text, x+250 , % "Version: " VERSION

Gui, Add, StatusBar,, ready

Gui, Show, center autosize, TinoTool

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
	FileSelectFolder, SDPath , ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Please select the SD Card
	if (SDPath = "")
		SDPath := "Please select the SD Card"
	GuiControl, , SDPathEdit, % SDPath 

	IniWrite, % SDpath, % "settings.ini", % "User", % "SDpath"
	checkSDCard(SDPath)
return

selectAudio:
	
	starting := "::{20d04fe0-3aea-1069-a2d8-08002b30309d}"
	
	if (AudioPath != AUDIOPROMPT)
		starting := "*" . AudioPath

	FileSelectFolder, AudioPath , % starting ,2, Please select the audio folder
	if (AudioPath = "")
		AudioPath := AUDIOPROMPT
	GuiControl, , AudioPathEdit, % AudioPath 

	IniWrite, % AudioPath, % "settings.ini", % "User", % "AudioPath"
return

copyAudio:
	Gui, Submit, NoHide
	GuiControl, +Disabled, CopyAudioBut
	SB_SetText("Copying")

	nextFolder := nextFolder(SDPath)
	
	FileCreateDir, % SDPath . "\" . nextFolder
	FileList := ""

	filesC := 0

	Loop, Files, % AudioPath . "\*.mp3", F 
	{
		FileList .= A_LoopFileName . "`n"
		filesC += 1
	}
	Sort, FileList

	Loop, parse, FileList, `n
	{
		if (A_LoopField = "")
			Continue

		filename := Format("{1:03}",A_Index)
		if (WithFilename)
			filename .= "-" . A_LoopField
		filename .= ".mp3"

		FileCopy, % AudioPath . "\" . A_LoopField, % SDPath . "\" .  nextFolder . "\" . filename
		SB_SetText("Copying - " . A_Index . "/" . filesC . " to " . nextFolder)
	}

	checkSDCard(SDPath)
	GuiControl, -Disabled, CopyAudioBut
	SB_SetText("ready")
return

nextFolder(SDPath)
{
	Loop, 99
		If not FileExist(SDPath . "\" . Format("{1:02}",A_Index))
			return Format("{1:02}",A_Index)
}

checkSDCard(SDPath)
{
	errors := ""
	; check mp3 folder
	If not FileExist(SDPath . "\mp3") {
		errors .= "Missing folder: mp3`n"
	}

	; check advert folder
	If not FileExist(SDPath . "\advert") {
		errors .= "Missing folder: advert`n"
	}

	; check additional folders
	Loop, Files, % SDPath . "\*", D 
	{
		If A_LoopFileAttrib contains H,R,S  ; Skip any file that is either H (Hidden), R (Read-only), or S (System).
    		continue  ; Skip this file and move on to the next one.

		If not RegExMatch(A_LoopFileName,"^(\d\d|advert|mp3)$")
		{
			errors .= "Invalid folder name: " A_LoopFileName " in root directory`n"
		}
	}

	Loop, Files, % SDPath . "\*", F
		errors .= "Invalid file: " A_LoopFileName " in root directory`n"


	; next folder
	nextFolder(SDPath)
	GuiControl, , NextFolder, % "Next folder: " . nextFolder(SDPath)

	; skipped folder names
	empty := false
	Loop, 99
		If not FileExist(SDPath . "\" . Format("{1:02}",A_Index))
		{
			empty := true
		}
		Else If (empty) {
			errors .= "Unreachable folder: " Format("{1:02}",A_Index) "`n"
		}

	if (StrLen(errors)) {
		GuiControl, Show, Errors
		GuiControl, , Errors, % errors
		GuiControl, , Check, Errors:
	} Else {
		GuiControl, ,Check, SD is fine
		GuiControl, Hide, Errors
	}
}

GuiClose:
ExitApp

Recheck:
	checkSDCard(SDPath)
return

#If !A_IsCompiled
F12::Reload
