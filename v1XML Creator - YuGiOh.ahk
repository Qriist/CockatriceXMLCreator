SetBatchLines -1
FileEncoding UTF-8
#include <JSON>
#include <class_cockatriceXML>
#include <string_things>
#Include <functions>
;#include <class_sqlitedb>
#include <SingleRecordSQL>
#include <class_apiCache>
#include <libcrypt>
#include <class_EasyIni>
#MaxMem 4096
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;~ #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.



OnExit, ExitRoutine	;ensures graceful shutdown of the database


iniArr := class_EasyIni(a_scriptdir "\XML Creator.ini")
storedCacheRevision := iniArr["YuGiOh","ygorganization_X-Cache-Revision"]
Gui, XML: New, +MinSizex250
Gui, Add, Text,w300 BackgroundTrans center vText1,
Gui, Add, Text,w300 BackgroundTrans center vText2,Gathering card list...
Gui, Add, Text,w300 BackgroundTrans center vText3,
Gui, Show,autosize center,YuGiOh XML Creator

cXml := new class_cockatriceXML
cxml.init("Yu-Gi-Oh")
apiCache := new class_ApiCache


;FileDelete, % A_ScriptDir "\cache\XML Creator - YuGiOh.db*"	;easy db delete for testing
api.init(A_ScriptDir "\yugioh\",A_ScriptDir "\cache\XML Creator - YuGiOh.db")

;api.exportUncompressedDb(A_ScriptDir "\cache\XML Creator - YuGiOh_uncompressed.db",1)

;ExitApp

api.begin()

api.initExpiry(31536000000) ;1000 years is long enough to cache before we start re-burning api, right?


storedDBVer := JSON.load(api.retrieve("https://db.ygoprodeck.com/api/v7/checkDBVer.php"))


msgbox
currentDBVer := JSON.load(api.retrieve("https://db.ygoprodeck.com/api/v7/checkDBVer.php",,,,,1))

;deciding if we update the main card database
forceBurn := (storedDBVer[1,"last_update"]=currentDBVer[1,"last_update"]?0:1)

;gathering data from either local or remote, depending on forceBurn
CardObj := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/cardinfo.php?misc=yes",,,,,forceBurn))["data"]
GuiControl, , text2,% "Gathering set list..."
setObj := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/cardsets.php",,,,,forceBurn))

;msgbox % st_printArr(cardobj)
;gathering a few things from the Q&A api

;api.invalidateRecord(api.generateFingerprint("https://db.ygorganization.com/manifest/" cacheRevision))

GuiControl, , text2,% "Gathering manifest..."
manifestStr := api.retrieve("https://db.ygorganization.com/manifest/" storedCacheRevision,,,,,1)
;msgbox % clipboard := manifestStr
Try	;manifest does not return json data if stored = current version, but we just want the response headers
	manifestArr := JSON.Load(manifestStr)

;invalidating stale paths
GuiControl, , text2,% "Invalidating stale paths..."
currentCacheRevision := RegexMatchGlobal(api.lastResponseHeaders,"X-Cache-Revision:\W*(\d+)",0)[1,1]

if (currentCacheRevision != storedCacheRevision){
	;everything in the manifest is eligible for invalidation - doesn't really matter if it's not in the db already
	invalidObj := []
	for k,v in StrSplit(trim(getArrayPaths(manifestArr,"https://db.ygorganization.com"),"`n"),"`n"){
		invalidObj.push(api.generateFingerprint(v))
	}
	api.invalidateRecords(invalidObj)
	iniArr["YuGiOh","ygorganization_X-Cache-Revision"] := currentCacheRevision
	iniArr.save(a_scriptdir "\XML Creator.ini")	;updates the storedCacheRevision only after stales are invalidated
}

;msgbox % api.lastResponseHeaders
api.commit()
api.begin()
;msgbox % "check?"
;backup id<->name list just in case main DB doesn't quite align with QA DB.
ids := json.load(api.retrieve("https://db.ygorganization.com/data/idx/card/name/en"))
konamiIds := []
for k,v in ids{
	konamiIds[ids[k,1]] := k
}

LinkMarkers := LinkMarkers()	;used for link monster arrows

;scrape a few properties used for related cards and various highlights
lists := yugiohLists(cardObj)

;processing sets
for k,v in setobj{
	record := setobj[k]
	;set := record["set_name"]
	cxml.newSetEntity(record["set_code"])
	cxml.setSetProp("releasedate",record["tcg_date"])
	cxml.setSetProp("longname",record["set_name"])
}
;set := record["card_sets",a_index,"set_code"]

;cxml.setSetProp("name",record["card_sets",a_index,"set_code"],set)
;cxml.setSetProp("longname",record["card_sets",a_index,"set_code"],set)
;cxml.setSetProp("name",record["card_sets",a_index,"set_code"],set)
;cxml.setSetProp("name",record["card_sets",a_index,"set_code"],set)
CardTotal := CardObj.count()
checkstuff := []
for k,v in CardObj
{

	record := v
	cxml.newCardEntity(record["name"])
	cxml.setMajorCardProp("text",record["desc"])
	cxml.setCardProp("colors",(record["attribute"]!=""?record["attribute"]:"NORMAL"))
	cxml.setCardProp("cmc",(record.HasKey("level")?record["level"]:0)) ;set to 0 if no level found
	cxml.setCardProp("ID",record["id"])
	cxml.setCardProp("Type",record["type"])
	cxml.setCardProp("Race",record["race"])
	cxml.setCardProp("Archetype",record["archetype"])
	cxml.setCardProp("Konami_ID",record["misc_info",1,"konami_id"])
	
	CurrentCardPercent := a_index / CardTotal
	GuiControl, , text1,Scraping data for...
	GuiControl, , text2,% record["name"]
	GuiControl, , text3,% a_index " / " CardTotal " processed. (" (a_index/CardTotal*100)"`%)"
	Gui, Show, AutoSize NA,YuGiOh XML Creator
	
	If (InStr(record["type"],"Monster"))
	{
		cxml.setCardProp("pt",record["atk"] "/" record["def"])
		cxml.setCardProp("maintype","Monster")
		cxml.setCardProp("type", regexreplace("Monster " cxml.ld() " " record["race"] " " StrReplace(record["type"],"Monster") (record["archetype"]!=""?a_space record["archetype"]:""), "(\h)+", "$1"))
		if record.HasKey("linkmarkers"){
			outLinkMarkers := ""
			for k,v in record["linkmarkers"] {
				outLinkMarkers .= a_space a_space StrReplace(record["linkmarkers",a_index],record["linkmarkers",a_index],LinkMarkers[record["linkmarkers",a_index]])
			}
			cxml.setMajorCardProp("text"
			,cxml.getMajorCardProp("text") "`n`n"
			;.	cxml.boldOrItalicText( cxml.colorizeText("[ Link Markers ]","OrangeRed") a_space outLinkMarkers,1))
			.	"[ Link Markers ]"a_space outLinkMarkers,1)
			cxml.setCardProp("pt",record["atk"] " / [" record["linkval"] "]  " StrReplace(outLinkMarkers,a_space))
		}
		cxml.setMajorCardProp("tablerow",3)
	}
	
	If Instr(record["type"],"Trap") ;AND (v["type"] != "Trap Card")
	{
		cxml.setMajorCardProp("type","Trap " cxml.ld() " " record["race"] " " record["archetype"])
		cxml.setCardProp("maintype","Trap")
		cxml.setMajorCardProp("tablerow",1)
	}
	
	If Instr(record["type"],"Spell")
	{
		cxml.setCardProp("type","Spell " cxml.ld() " " record["race"] " " record["archetype"])
		cxml.setCardProp("maintype","Spell")
		cxml.setMajorCardProp("tablerow",0)
	}
	
	If Instr(record["type"],"Token")
	{
		cxml.setCardProp("type","Token " cxml.ld() " " record["race"] " " record["archetype"])
		cxml.setCardProp("maintype","Token")
		cxml.setMajorCardProp("tablerow",3)
	}
	
	If Instr(record["type"],"Skill")
	{
		cxml.setCardProp("type","Skill " cxml.ld() " " record["race"] " " record["archetype"])
		cxml.setMajorCardProp("tablerow",3)
		cxml.setCardProp("maintype","Skill")
	}
	if record.HasKey("banlist_info"){
		outBanListInfo := "[ Format Legality ]`n"
		for k,v in record["banlist_info"] {
			outBanListInfo .= v " in " StringUpper(strreplace(k,"ban_")) "`n"
			cxml.setCardProp("format-" strreplace(k,"ban_"),v)
		}
		cxml.setMajorCardProp("text",outBanListInfo "`n" cxml.getMajorCardProp("text"))
	}
	
	for k,v in record["card_sets"]{
		setRecord := record["card_sets",k]
		setArr := {"rarity": setRecord["set_rarity"]}
		cxml.attachSetToCard(StrSplit(setRecord["set_code"],"-")[1],setArr)
	}
	
	;no yugioh db has any images attached to the set so doing a dirty hack to get all pictures
	for k,v in record["card_images"] {
		imageRecord := record["card_images",k]
		cxml.attachSetToCard(chr(176) record["id"] "." a_index,{"picURL":imageRecord["image_url"]})
	}
	
	if (cxml.getCardProp("Konami_ID") != ""){ ;*[XML Creator - YuGiOh]
		;fetching FAQ data
		;msgbox % clipboard := "https://db.ygorganization.com/data/card/" cxml.getCardProp("Konami_ID")
		faqArr := json.load(api.retrieve("https://db.ygorganization.com/data/card/" cxml.getCardProp("Konami_ID")))
		
		;searching for cards to attach - using a seperate step that doesn't rely on the our pretty text 
		;attachCheck := RegexMatchGlobal(faqArr["cardData",selectLang(faqArr["cardData"]),"effectText"],"([「""„](.+)[""“」])",0)
		;loop,
		;msgbox % st_printArr(attachCheck)
		;msgbox % a_index "`n`n`n"  clipboard := st_printArr(faqArr)
		
		faqEntries := []
		for k,v in faqArr["faqData","entries"]{
			entryIndex := k
			loop, % faqArr["faqData","entries",entryIndex].count(){
				entry := ""
				for k,v in faqArr["faqData","entries",entryIndex]{
					entrySubIndex := k
					entry .= faqArr["faqData","entries",entryIndex,entrySubIndex,selectLang(faqArr["faqData","entries",entryIndex,entrySubIndex])] "`n"
				}
				;entry .= "`n"
			}
			entry := trim(entry,"`n")
			if (entry!="")
				faqEntries.push(entry)
		}
		
		if (faqEntries.count() > 0){
			
			;TODO - move list creation to new cxml method
			
			;out := cxml.addList(faqEntries)
			out := "<ul>"
			For k,v in faqEntries{
				out .= "<li>" v "</li>"
			}
			out .= "</ul>"
			;msgbox % out
			outCheck := RegexMatchGlobal(out,"(「*<<(\d+)>>」*)",0)
			for k,v in outCheck{
				numFull := v[1]
				,num := v[2]
				out := strreplace(out,numFull, chr(34) konamiIds[num] chr(34))
				;msgbox % numFull "`n" num ;outcheck.count() st_printArr(outcheck)
			}
			cxml.setMajorCardProp("text",cxml.getMajorCardProp("text")  out)
			;msgbox % cxml.getMajorCardProp("text")
		}
		cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable({1:{1:{"text":""}}}))	;adds some consistent padding that doesn't rely on weird paragraph rules
		
		;fetching QA data
		qaArr := []
		for k,v in faqArr["qaIndex"]{
			qaIndexUrl := "https://db.ygorganization.com/data/qa/" v
			qa := json.load(api.retrieve(qaIndexUrl))
			
			;msgbox % clipboard := st_printArr(qa)
			qaObj := []
			qaObj[1,1,"text"] := qa["qaData",selectLang(qa["qaData"]),"question"]
			qaObj[1,1,"background-color"] := "#EDBB99"
			qaObj[1,1,"font-weight"] := "bold"
			qaObj[2,1,"text"] := qa["qaData",selectLang(qa["qaData"]),"answer"]
			qaObj[2,1,"background-color"] := "#F6DDCC"
			
			cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable(qaObj) "`n")
		}
		
		out := cxml.getMajorCardProp("text")
		outCheck := RegexMatchGlobal(out,"(「*<<(\d+)>>」*)",0)
		for k,v in outCheck{
			numFull := v[1]
			,num := v[2]
			out := strreplace(out,numFull, chr(34) konamiIds[num] chr(34))
		}
		cxml.setMajorCardProp("text",out)
		
		;searching for things to highlight
		highlightCheck := cxml.getMajorCardProp("text")
		highlightTest := RegExMatchGlobal(highlightCheck,"U)("".+"")",0)
		for k,v in highlightTest{
			checkQuote := highlightTest[a_index,1]
			trimmedQuote := Trim(checkQuote,chr(34))
			
			if lists["name"].HasKey(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText("「" trimmedQuote "」" ,"Gold",,1)))
				if (trimmedQuote != cxml.getMajorCardProp("name"))
					cxml.attachRelatedCard()
			}
			else if lists["race"].HasKey(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"LightCoral",,1)))
			}
			else if lists["archetype"].HasKey(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"Silver",,1)))
			}
			else if lists["type"].HasKey(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"Chartreuse",,1)))
			}
			
		}
		checkForBrackets := RegExMatchGlobal(cxml.getMajorCardProp("text"),"mU)(\[ .+ \])",0)
		for k,v in checkForBrackets {
			bracket := checkForBrackets[a_index,1]
			switch bracket {
				case "[ Format Legality ]":{
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,cxml.colorizeBackgroundAndText(bracket,"grey","white",1)))
					;cxml.setMajorCardProp("text",body "`n`n`n"cxml.getMajorCardProp("text"))
				}
				case "[ Monster Effect ]" :{
					bodyStart := "" ;"<code style=""color:white;background-color:grey; font-size:5rem;font-style:normal;font-family:Helvetica, sans-serif;"">"
					bodyEnd := "" ;"</code>"
					textcheck := cxml.getMajorCardProp("text")
					if !InStr(textcheck,bracket "`n"){
						cxml.setMajorCardProp("text", StrReplace(textcheck,bracket a_space, bracket "`n"))
						
					}
					textcheck := cxml.getMajorCardProp("text")
					If !Instr(textcheck,"-----"){
						cxml.setMajorCardProp("text",StrReplace(textcheck,"[ Monster Effect ]","----------------------------------------`n[ Monster Effect ]"))
					}
					
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,bodyStart cxml.colorizeText(bracket " ⚔️","Green",1) bodyEnd))
					;MsgBox % cxml.getMajorCardProp("text")
					
				}
				case "[ Pendulum Effect ]" :{
					textcheck := cxml.getMajorCardProp("text")
					if !InStr(textcheck,bracket "`n"){
						cxml.setMajorCardProp("text", StrReplace(textcheck,bracket a_space, bracket "`n"))
					}
					
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,bodyStart cxml.colorizeText(bracket " ⚖","Brown",1) bodyEnd))
					;MsgBox % cxml.getMajorCardProp("text")
				}
				case "[ Flavor Text ]" :{
					findFlavorText := RegExMatchGlobal(cxml.getMajorCardProp("text"),"ms)(\[ Flavor Text \](.+))",0)
					
					;msgbox % findFlavorText[1,1]
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),findFlavorText[1,1],bodyStart cxml.boldOrItalicText(findFlavorText[1,2],2) bodyEnd))
					;msgbox % clipboard := cxml.getMajorCardProp("text")
					
				}
				
				
				Default:{
					msgbox % "undefined: " bracket
					continue
				}
				
			}
		}
	}
	;~ Sort,SetXML,U D`|
	;~ StringReplace,SetXML,SetXML,`|,,all
	;msgbox % st_printArr(cxml.getCardEntity())
	
}
;msgbox % clipboard := cxml.generateXML()

api.commit()
outXml := cxml.generateXML()
FileOpen("E:\Projects\Cockatrice XML Creators\cxml testing\yugioh\data\cards.xml","w").write(outXml)
run,E:\Projects\Cockatrice XML Creators\cxml testing\yugioh\cockatrice.exe
ExitApp

ExitRoutine:
api.CloseDB()

ExitApp


UriEncode(Uri, RE="[0-9A-Za-z]"){
	VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
	While Code:=NumGet(Var,A_Index-1,"UChar")
		Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
	Return,Res
}


LinkMarkers(){
	LinkMarkers := {"Bottom-Left":"↙️"
	,"Bottom-Right":"↘️"
	,"Top-Left":"↖️"
	,"Top-Right":"↗️"
	,"Bottom":"↓"
	,"Right":"→"
	,"Top":"↑"
	,"Left":"←"}
	
	return LinkMarkers
}

Base64_Encode(ByRef data, len:=-1, ByRef out:="", mode:="A")
{
	if !InStr("AW", mode := Format("{:U}", mode), true)
		mode := "A"
	BytesPerChar := mode=="W" ? 2 : 1
	if (Round(len) <= 0)
		len := StrLen(data) * (A_IsUnicode ? 2 : 1)
	
	; CRYPT_STRING_BASE64 := 0x00000001
	if DllCall("Crypt32\CryptBinaryToString" . mode, "Ptr", &data, "UInt", len
		, "UInt", 0x00000001, "Ptr", 0, "UIntP", size)
	{
		VarSetCapacity(out, size *= BytesPerChar, 0)
		if DllCall("Crypt32\CryptBinaryToString" . mode, "Ptr", &data, "UInt", len
			, "UInt", 0x00000001, "Ptr", &out, "UIntP", size)
			return size * BytesPerChar
	}
}

yugiohLists(cardObj){
	lists := []
	for k,v in cardObj{
		;msgbox % st_printArr(cardobj[k])
		lists["name",cardObj[k,"name"]] := 1
		,lists["race",cardObj[k,"race"]] := 1
		,lists["archetype",cardObj[k,"archetype"]] := 1
		,lists["type",cardObj[k,"type"]] := 1
	}
	
	for k,v in ["name","race","archetype","type"]	;prunes empty keys from the list
		lists[v].delete("")
	;msgbox % st_printArr(lists)
	return lists
}

getArrayPaths(jsonObj,basePath := ""){
	for k,v in jsonObj {
		if IsObject(v)
			ret .= getArrayPaths(v,basePath "/" k)
		else
			ret .= basePath "/" k "`n"
	}
	return ret
}

selectLang(ByRef incomingArr){	;just picks the first language available
	;uses order found on https://db.ygorganization.com/about/api
	static langOrder := StrSplit("en|ja|de|fr|it|es|pt|ko","|")
	
	;MSGBOX % st_printarr(incomingArr)
	for k,v in langOrder {
		if incomingArr.HasKey(v)
			return v
	}
}




