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

VERSION := "0.6.2"
AUDIOPROMPT := "Please select the audio folder"

;; ***********
;; init config
;; ***********

iniPath := "settings.ini"

IniRead, SDPath, % iniPath, % "User", % "SDpath", % "Please select the SD Card"
IniRead, AudioPath, % iniPath, % "User", % "Audiopath", % AUDIOPROMPT
IniRead, AsAdmin, % iniPath, % "User", % "AsAdmin", 0
IniRead, WithFilename, % iniPath, % "User", % "WithFilename", 1

;; ************
;; run as admin
;; ************

if (AsAdmin && not A_IsAdmin)
{
	Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}

; MsgBox, % id3read("F:\temp\Tonuino\Auf der Baustelle\01 1.mp3","Artist")

;; ***
;; GUI
;; ***


Gui, New, , TonUINO SD Card manager
Gui, Add, Edit, w300 vSDPathEdit disabled, % SDPath
Gui, Add, Button, gselectSDcard X+m, Select SD Card
Gui, Add, Progress, w200 x10 h20 cBlue vSDSpaceProgress BackgroundAAAAAA, 
Gui, Add, Text, x+m yp+5 vSDSpace w300, NA

Gui, Add, Tab3, w520 x10 y+10, Copy|SD Check|Settings

Gui, Add, Edit, w300 vAudioPathEdit section x+5 y+5 disabled, % AudioPath
Gui, Add, Button, gselectAudio X+m, Select Audio
Gui, Add, Button, vCopyAudioBut gcopyAudio X20 Y+m, Copy Audio
Gui, Add, Checkbox, vWithFilename checked%WithFilename% gSaveIni X+m, Append original filename to number 
Gui, Add, Text, vNextFolder, Next folder: NA
; Gui, Add, DropDownList, vSortBy gSortByChange, Filename|Title|Track Number
Gui, Font, bold
Gui, Add, Text, , Order preview (Click header to reorder)
Gui, Font,
Gui, Add, ListView, xs r10 w500, Filename|Title|TrackNumber
LV_ModifyCol(3, "Integer")

Gui, Tab, SD
Gui, Add, Button, gRecheck X+10, Recheck
Gui, Add, Text, vCheck w500, SD is fine
Gui, Add, Edit, vErrors w500 r10

Gui, Tab, Settings
Gui, Add, Checkbox, vAsAdmin gSaveIni checked%AsAdmin%, Start as admin (restart needed)
Gui, Add, Button, gRestart, Restart TinoTool

Gui, Tab,
Gui, Add, Link, , <a href="https://github.com/DarthBrento/TinoTool">Project on GitHub</a>
Gui, Add, Text, x+350 , % "Version: " VERSION

Gui, Add, StatusBar,, ready

Gui, Show, center autosize, TinoTool

checkSDCard(SDPath)
readFileList(AudioPath)
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

	IniWrite, % SDpath, % iniPath, % "User", % "SDpath"
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

	nextFolder := nextFolder(SDPath)
	
	readFileList(AudioPath)

	IniWrite, % AudioPath, % iniPath, % "User", % "AudioPath"
return


copyAudio:
	Gui, Submit, NoHide
	GuiControl, +Disabled, CopyAudioBut
	SB_SetText("Copying")

	nextFolder := nextFolder(SDPath)
	
	FileCreateDir, % SDPath . "\" . nextFolder
	FileList := ""

	filesC := LV_GetCount()

	Loop, Files, % AudioPath . "\*.mp3", F 
	{
		FileList .= A_LoopFileName . "`n"
		filesC += 1
	}
	Sort, FileList

	srcFilename := ""

	Loop, % LV_GetCount()
	{
		LV_GetText(srcFilename,A_Index)
		MsgBox, % srcFilename
		filename := Format("{1:03}",A_Index)
		if (WithFilename)
			filename .= "-" . srcFilename
		filename .= ".mp3"

		FileCopy, % AudioPath . "\" . srcFilename, % SDPath . "\" .  nextFolder . "\" . filename
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

	; Drive Space
	DriveSpaceFree, freeSpace, % SDPath

	DriveGet, cap, Capacity, % SDPath
	GuiControl, , SDSpace, % Format("{1:.2f}",freespace/1024) . " GB of " . Format("{1:.2f}",cap/1024) . " GB available"
	GuiControl, , SDSpaceProgress, % 100 - (freespace/cap) * 100
}

readFileList(AudioPath) 
{
	SB_SetText("Reading files")

	Loop, Files, % AudioPath . "\*.mp3", F 
	{
		LV_Add("", A_LoopFileName, id3read(A_LoopFileFullPath,021),id3read(A_LoopFileFullPath,026))
	}
	; auto-size
	LV_ModifyCol()
	SB_SetText("Ready")
}

SaveIni:
	Gui, Submit, NoHide

	IniWrite, % AsAdmin, % iniPath, % "User", % "AsAdmin"
	IniWrite, % WithFilename, % iniPath, % "User", % "WithFilename"
Return

GuiClose:
ExitApp

Recheck:
	checkSDCard(SDPath)
return

Restart:
Reload

#If !A_IsCompiled
F12::Reload

If A_Scriptname=id3read.ahk
	ExitApp

	
/*
Size ................................... (001): 166 KB
Element Type ........................... (002): MP3 audio format
Change Date ............................ (003): 12/03/2012 21:33
Creation ............................... (004): 12/03/2012 21:33
Last visit ............................. (005): 12/03/2012 21:33
Attributes ............................. (006): A
Recognized type ........................ (009): Audio
Owner .................................. (010): Voyager \ Janeway
Art .................................... (011): Music
Participants interpreters .............. (013): Individual Artist
Album .................................. (014): Album Name
Years .................................. (015): 1998
Genre .................................. (016): Other
Conductors ............................. (017): Conductor
Review ................................. (019): Not rated
Authors ................................ (020): Individual Artist
Title .................................. (021): Title of the song
Copyright .............................. (025): CopyRight
Track number ........................... (026): 1
Length ................................. (027): 00:00:06
Bitrate ................................ (028): 192 kbit / s
Protected .............................. (029): No
Computer ............................... (053): VOYAGER (this computer)
File Name .............................. (155): MP3-object Test.mp3
Released ............................... (173): No
Folder name ............................ (176): Desktop
Folder Path ............................ (177): D: \ system \ desktop
Folder ................................. (178): Desktop (C: \ System)
Path ................................... (180): D: \ WINDOWS \ Desktop \ MP3 object Test.mp3
Type ................................... (182): MP3 audio format
Link status ............................ (188): Unresolved
Encoded by ............................. (193): Encoded by (e.g. LAME)
Editor ................................. (195): Publisher
Subtitle ............................... (196): Subtitle
Album artist ........................... (217): Album Artist
Beats per minute ....................... (219): 120
Composers .............................. (220): Composer
Part of a set .......................... (224): 1
Sequence name .......................... (254): Subtitle
Approval Status ........................ (269): Not released

https://autohotkey.com/board/topic/83376-ahk-l-read-id3-tags-function/
*/

	
 	
id3read(filename,code)
{
	objShell := ComObjCreate("Shell.Application")
		
	SplitPath,filename , ename,edir

	oDir := objShell.NameSpace(eDir)
	oMP3 := oDir.ParseName(eName)
	  
	return oDir.GetDetailsOf(oMP3, code)
}