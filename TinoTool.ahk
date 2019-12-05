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


AUDIOPROMPT := "Please select the audio folder"
COPYLOGFILE := "copylog.txt"
SDPROMPT := "Please select the SD Card"

;; ***********
;; init config
;; ***********

iniPath := "settings.ini"

IniRead, SDPath, % iniPath, % "User", % "SDpath", % SDPROMPT
IniRead, AudioPath, % iniPath, % "User", % "Audiopath", % AUDIOPROMPT
IniRead, AsAdmin, % iniPath, % "User", % "AsAdmin", 0
IniRead, WithFilename, % iniPath, % "User", % "WithFilename", 1
IniRead, SmartRename, % iniPath, % "User", % "SmartRename", 1
IniRead, Recursive, % iniPath, % "User", % "Recursive", 0

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

Gui, Add, Edit, w380 vAudioPathEdit section x+5 y+5 disabled -Multi R1, % AudioPath
Gui, Add, Button, gselectAudio X+m, Select Audio
Gui, Add, Button, vCopyAudioBut gcopyAudio X20 Y+m, Copy Audio
Gui, Add, Checkbox, vWithFilename checked%WithFilename% gSaveIni X+m, Append original filename to number 
Gui, Add, Checkbox, vSmartRename checked%SmartRename% gSaveIni X+m, Smart rename
Gui, Add, Checkbox, vRecursive checked%Recursive% gSaveIni X+m, include subfolders
Gui, Add, Text, vNextFolder Xs+5, Copy to:
Gui, Add, DropDownList, X+m Yp-3 vTargetFolder AltSubmit, New||01|02

Gui, Font, bold
Gui, Add, Text, , Order preview (Click header to reorder)
Gui, Font,
Gui, Add, Text, , (Doubleclick row to toggle copy/skip)
Gui, Add, ListView, xs r10 w500 gLVClick AltSubmit, mode|Filename|Title|TrackNumber|Path
LV_ModifyCol(3, "Integer")
LV_ModifyCol(4, 0)

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

targetFolder := 1
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
		SDPath := SDPROMPT
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

	targetFolderName := targetFoldertoPath(SDPath, targetFolder)
	; MsgBox, % SDPath . "\" . targetFoldertoPath(SDPath, targetFolder)

	FileCreateDir, % SDPath . "\" . targetFolderName
	FileList := ""

	filesC := LV_GetCount()

	; Loop, Files, % AudioPath . "\*.mp3", F 
	; {
	; 	FileList .= A_LoopFileName . "`n"
	; }
	; Sort, FileList

	srcFilename := ""
	nid := 1
	Loop, Files, % SDPath . "\" . targetFolderName . "\*"
		nid++


	folder := Substr(AudioPath,InStr(Audiopath, "\",false,0)+1)

	FileAppend, % nextFolder . " -> " . folder . "`n" , % COPYLOGFILE


	Loop, % LV_GetCount()
	{
		if (nid > 255) 
		{
			MsgBox, % "Error: Only 255 files per folder"
			Return
		}
		SB_SetText("Copying - " . A_Index . "/" . filesC . " to " . targetFolderName)
		LV_GetText(mode,A_Index)
		LV_GetText(srcFilename,A_Index,2)
		LV_GetText(srcPath,A_Index,5)
		
		if (mode = "skip")
			continue
		filename := Format("{1:03}",nid++)
		if (WithFilename) {
			repFN := RegExReplace(srcFilename,".mp3","")
			if (SmartRename) {
				repFN := smartRename(repFN)
			} 
			filename .= "-" . repFN
		}
		filename .= ".mp3"

		FileCopy, % srcPath, % SDPath . "\" .  targetFolderName . "\" . filename
	}

	checkSDCard(SDPath)
	GuiControl, -Disabled, CopyAudioBut
	SB_SetText("ready")
return

nextFolder(SDPath)
{
	return Format("{1:02}",nFNumb(SDPath))
}

nFNumb(SDPath)
{
	Loop, 99
		If not FileExist(SDPath . "\" . Format("{1:02}",A_Index))
			return A_Index
}

TargetFolderDropDown(SDPath,preselected)
{
	if (preselected = "")
		preselected := 1

	max := nFNumb(SDPath)
	str := "|" . Format("{1:02}",max) . " (New)|"
	if (preselected = 1)
		str .= "|"
	Loop, % max - 1
	{
		str .= Format("{1:02}",A_Index) . "|"
		if (A_Index = preselected - 1)
			str .= "|"
	}
	return str	
}

checkSDCard(SDPath)
{
	Global targetFolder

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
	; GuiControl, , NextFolder, % "Next folder: " . nextFolder(SDPath)
	GuiControl, , TargetFolder, % TargetFolderDropDown(SDPath,targetFolder)


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
	global recursive

	SB_SetText("Reading files")
	LV_Delete()

	mode := "F"

	if (recursive)
		mode .= "R"

	Loop, Files, % AudioPath . "\*.mp3", % mode
	{
		LV_Add("", "copy", A_LoopFileName, id3read(A_LoopFileFullPath,021),id3read(A_LoopFileFullPath,026),A_LoopFileFullPath)
	}
	; auto-size
	LV_ModifyCol()
	; LV_ModifyCol(5, 0)

	SB_SetText("Ready")
}

SaveIni:
	Gui, Submit, NoHide

	IniWrite, % AsAdmin, % iniPath, % "User", % "AsAdmin"
	IniWrite, % WithFilename, % iniPath, % "User", % "WithFilename"
	IniWrite, % Recursive, % iniPath, % "User", % "Recursive"
	IniWrite, % SmartRename, % iniPath, % "User", % "SmartRename"
	readFileList(AudioPath)
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
