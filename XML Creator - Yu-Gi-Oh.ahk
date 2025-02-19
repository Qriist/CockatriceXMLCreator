#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk


cxml := CockatriceXMLCreator("Yu-Gi-Oh")
cxml.gtext(2,"Gathering card list...")
api := apiQache()
api.initExpiry(31536000000) ;1000 years is long enough to cache before we start re-burning api, right?
storedCacheRevision := IniRead(A_ScriptDir "\XML Creator.ini","YuGiOh","ygorganization_X-Cache-Revision",0)

;open a transaction so our filtering steps are atomic

storedDBVer := api.findRecords("https://db.ygoprodeck.com/api/v7/checkDBVer.php")
If (storedDBVer.Length = 0){
    ;on fresh db
    storedDBVer := Map(1,Map("database_version",0,"last_update",0))
} else {
    ;all subsequent runs
    storedDBVer := JSON.load(api.retrieve("https://db.ygoprodeck.com/api/v7/checkDBVer.php"))
}
currentDBVer := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/checkDBVer.php",,,,,,1))

forceBurn := (storedDBVer[1]["last_update"]=currentDBVer[1]["last_update"]?unset:1)
CardObj := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/cardinfo.php?misc=yes",,,,,,forceBurn?))["data"]
cxml.gtext(2,"Gathering set list...")
setObj := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/cardsets.php",,,,,,forceBurn?))

cxml.gtext(2,"Gathering manifest...")

manifestStr := api.retrieve("https://db.ygorganization.com/manifest/" storedCacheRevision,,,,,,1)
; MsgBox api.lastResponseHeaders

;todo - fill in the rest of the manifest checking

; api.begin()

;backup id<->name list just in case main DB doesn't quite align with QA DB.
ids := json.load(api.retrieve("https://db.ygorganization.com/data/idx/card/name/en"))
konamiIds := Map()
for k,v in ids {
    konamiIds[Integer(ids[k][1])] := k
}
; msgbox A_Clipboard := JSON.Dump(konamiIds)
LinkMarkers := fLinkMarkers()	;used for link monster arrows

;scrape a few properties used for related cards and various highlights
lists := yugiohLists(CardObj)

;processing sets
cxml.gtext(2,"Processing sets...")
for k,v in setobj{
	record := setobj[k]
	;set := record["set_name"]
	cxml.newSetEntity(record["set_code"])
	cxml.setSetProp("releasedate",record["tcg_date"])
	cxml.setSetProp("longname",record["set_name"])
}
; msgbox A_Clipboard := JSON.Dump(setObj)
sortedSets := sortSetsByDate(setObj)
CardTotal := CardObj.length

for k,v in CardObj {
    record := v
    cxml.newCardEntity(record["name"])
	cxml.setMajorCardProp("text",record["desc"])
	cxml.setCardProp("colors",(record.Has("attribute")?record["attribute"]:"NORMAL"))
	cxml.setCardProp("cmc",(record.Has("level")?record["level"]:0)) ;set to 0 if no level found
	cxml.setCardProp("ID",record["id"])
	cxml.setCardProp("Type",record["type"])
	cxml.setCardProp("Race",record["race"])
	cxml.setCardProp("Archetype",(record.Has("archetype")?record["archetype"]:""))
    if !record["misc_info"][1].has("konami_id")
        record["misc_info"][1]["konami_id"] := ""
	cxml.setCardProp("Konami_ID",record["misc_info"][1]["konami_id"])
    
    CurrentCardPercent := a_index / CardTotal
    cxml.gtext(1,"Scraping data for...")
    cxml.gtext(2,record["name"])
    cxml.gtext(3,a_index " / " CardTotal " processed. (" (a_index/CardTotal*100) "%)")

	If (InStr(record["type"],"Monster"))
	{
		cxml.setCardProp("pt",record["atk"] "/" record["def"])
		cxml.setCardProp("maintype","Monster")
        tempArch := unset   
        try tempArch := record["archetype"]
        cardType := regexreplace("Monster " cxml.ld() " " record["race"] " " StrReplace(record["type"],"Monster") (IsSet(tempArch?)?a_space record["archetype"]:""),"(\h)+", "$1")
		cxml.setCardProp("type", cardType)
		if record.Has("linkmarkers"){
			outLinkMarkers := ""
			for k,v in record["linkmarkers"] {
				outLinkMarkers .= a_space a_space StrReplace(record["linkmarkers"][a_index],record["linkmarkers"][a_index],LinkMarkers[record["linkmarkers"][a_index]])
			}
            linkHead := cxml.colorizeText("[ Link Markers ]","Blue",1)
			cxml.setMajorCardProp("text"
			, cxml.getMajorCardProp("text") "`n`n"
			.	linkHead a_space outLinkMarkers)
			cxml.setCardProp("pt",record["atk"] " / [" record["linkval"] "]  " StrReplace(outLinkMarkers,a_space))
            cxml.setCardProp("Link_Markers",outLinkMarkers)
		}
		cxml.setMajorCardProp("tablerow",3)
	}

	If Instr(record["type"],"Trap") ;AND (v["type"] != "Trap Card")
	{
		cxml.setCardProp("type","Trap " cxml.ld() " " (record.has("race")?record["race"]:"") " " (record.has("archetype")?record["archetype"]:""))
		cxml.setCardProp("maintype","Trap")
		cxml.setMajorCardProp("tablerow",1)
	}

    If Instr(record["type"],"Spell")
	{
		cxml.setCardProp("type","Spell " cxml.ld() " " (record.has("race")?record["race"]:"") " " (record.has("archetype")?record["archetype"]:""))
		cxml.setCardProp("maintype","Spell")
		cxml.setMajorCardProp("tablerow",0)
	}
    
    If Instr(record["type"],"Token")
	{
		cxml.setCardProp("type","Token " cxml.ld() " " (record.has("race")?record["race"]:"") " " (record.has("archetype")?record["archetype"]:""))
		cxml.setCardProp("maintype","Token")
		cxml.setMajorCardProp("tablerow",3)
	}

    If Instr(record["type"],"Skill")
	{
		cxml.setCardProp("type","Skill " cxml.ld() " " (record.has("race")?record["race"]:"") " " (record.has("archetype")?record["archetype"]:""))
		cxml.setMajorCardProp("tablerow",3)
		cxml.setCardProp("maintype","Skill")
	}

    for k,v in ["goat","tcg","ocg"]
        cxml.setCardProp("format-" v,"legal")
    
    if record.Has("banlist_info"){
		outBanListInfo := "[ Format Legality ]`n"
        ; msgbox A_Clipboard := JSON.Dump(record["banlist_info"])
		for k,v in record["banlist_info"] {
			outBanListInfo .= v " in " StrUpper(strreplace(k,"ban_")) "`n"
			cxml.setCardProp("format-" strreplace(k,"ban_"),v)
		}
		cxml.setMajorCardProp("text",outBanListInfo "`n" cxml.getMajorCardProp("text"))
	}
    try {   ;best effort at attaching sets
        for k,v in record["card_sets"]{
            setRecord := record["card_sets"][k]
            setArr := Map("rarity", setRecord["set_rarity"])
            cxml.attachSetToCard(StrSplit(setRecord["set_code"],"-")[1],setArr)
        }
    } catch {   ;try to fall back on attaching at least one set
            misc := record["misc_info"][1]
            if misc.has("ocg_date") && sortedSets.Has(misc["ocg_date"])
                cxml.attachSetToCard(sortedSets[misc["ocg_date"]],Map())
            if misc.has("tcg_date") && sortedSets.Has(misc["tcg_date"])
                cxml.attachSetToCard(sortedSets[misc["tcg_date"]],Map())
    }

    ; no yugioh db has any images attached to the set so doing a dirty hack to get all pictures
	for k,v in record["card_images"] {
		imageRecord := record["card_images"][k]
        picObj := Map()
        fakeSet := chr(176) record["id"] "." a_index
        picObj["uuid"] := api.hash(&f := "Yu-Gi-Oh" fakeSet,"SHA512")
        picObj["picURL"] := imageRecord["image_url"]
		cxml.attachSetToCard(fakeSet,picObj)
	}
    
    if (cxml.getCardProp("Konami_ID") != ""){
        ;fetching FAQ data
        faqraw := qaraw := unset
        faqraw := api.retrieve("https://db.ygorganization.com/data/card/" cxml.getCardProp("Konami_ID"))
        try faqArr := json.load(faqraw)
        catch
            continue

        faqEntries := []
        try ;faqData is too inconsistent for manual checks so we're just running it
		for k,v in faqArr["faqData"]["entries"]{
			entryIndex := k
			loop faqArr["faqData"]["entries"][entryIndex].length{
				entry := ""
				for k,v in faqArr["faqData"]["entries"][entryIndex]{
					entrySubIndex := k
					entry .= faqArr["faqData"]["entries"][entryIndex][entrySubIndex][selectLang(faqArr["faqData"]["entries"][entryIndex][entrySubIndex])] "`n"
				}
				;entry .= "`n"
			}
			entry := trim(entry,"`n")
			if (entry!="")
				faqEntries.push(entry)
		}

        if (faqEntries.Length > 0) {
			;TODO - move list creation to new cxml method
			
			;out := cxml.addList(faqEntries)
			out := "<ul>"
			For k,v in faqEntries{
				out .= "<li>" v "</li>"
			}
			out .= "</ul>"
			;msgbox % out
			outCheck := RegExMatchAll(out,"(「*<<(\d+)>>」*)",0)
			for k,v in outCheck{
				numFull := v[1]
				num := v[2]
				out := strreplace(out,numFull, chr(34) konamiIds[num] chr(34))
				;msgbox % numFull "`n" num ;outcheck.count() st_printArr(outcheck)
			}
			cxml.setMajorCardProp("text",cxml.getMajorCardProp("text")  out)
			;msgbox % cxml.getMajorCardProp("text")
        }
        tablePad := Map(1,Map(1,Map("text","")))
		cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable(tablePad))	;adds some consistent padding that doesn't rely on weird paragraph rules

        ;fetching QA data
        for k,v in faqArr["qaIndex"]{
            qaIndexUrl := "https://db.ygorganization.com/data/qa/" v
            qaraw := api.retrieve(qaIndexUrl)
            try qa := json.load(qaraw)
            catch
                continue

            qaObj := Map()
            
            ;question block
            qaObj[1] := Map()
            qaObj[1][1] := Map()
            qaObj[1][1]["text"] := qa["qaData"][selectLang(qa["qaData"])]["question"]
			qaObj[1][1]["background-color"] := "#EDBB99"
			qaObj[1][1]["font-weight"] := "bold"
            
            ;answer block
            qaObj[2] := Map()
            qaObj[2][1] := Map()
            qaObj[2][1]["text"] := qa["qaData"][selectLang(qa["qaData"])]["answer"]
			qaObj[2][1]["background-color"] := "#F6DDCC"
			
            ;render
			cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable(qaObj) "`n")
        }

        out := cxml.getMajorCardProp("text")
        outCheck := RegExMatchAll(out,"m)(「*<<(\d+)>>」*)")
        ; msgbox A_Clipboard := JSON.Dump(outCheck)

        loop outCheck.length {
            numFull := outCheck[a_index][1]
            numReal := Integer(outCheck[a_index][2]) + 0
            
            If !konamiIds.has(Integer(numReal)) {
                strreplace(out,numFull, chr(34) "UNKNOWN DATABASE ENTRY" chr(34))
                continue
            }
            replace := chr(34) (konamiIds[Integer(numReal)]) Chr(34)
            out := strreplace(out,numFull,replace)
        }
        cxml.setMajorCardProp("text",out)

		;searching for things to highlight
		highlightCheck := cxml.getMajorCardProp("text")
		highlightTest := RegExMatchAll(highlightCheck,'U)(".+")')
		for k,v in highlightTest{
			checkQuote := highlightTest[a_index][1]
			trimmedQuote := Trim(checkQuote,chr(34))
			
			if lists["name"].Has(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText("「" trimmedQuote "」" ,"Gold",,1)))
				; if (trimmedQuote != cxml.getMajorCardProp("name"))
				; 	cxml.attachRelatedCard(trimmedQuote,cxml.getCardEntity(trimmedQuote))
                    ; MsgBox trimmedQuote
			}
			else if lists["race"].Has(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"LightCoral",,1)))
			}
			else if lists["archetype"].Has(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"Silver",,1)))
			}
			else if lists["type"].Has(trimmedQuote){
				cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),checkQuote,cxml.colorizeBackgroundAndText( trimmedQuote ,"Chartreuse",,1)))
			}
			
		}

		checkForBrackets := RegExMatchAll(cxml.getMajorCardProp("text"),"U)(\[ .+ \])")
		for k,v in checkForBrackets {
			bracket := checkForBrackets[a_index][1]
			switch bracket {
				case "[ Format Legality ]":
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,cxml.colorizeBackgroundAndText(bracket,"grey","white",1)))
				
				case "[ Monster Effect ]" :
					textcheck := cxml.getMajorCardProp("text")
					if !InStr(textcheck,bracket "`n"){
						cxml.setMajorCardProp("text", StrReplace(textcheck,bracket a_space, bracket "`n"))
					}
					textcheck := cxml.getMajorCardProp("text")
					If !Instr(textcheck,"-----"){
						cxml.setMajorCardProp("text",StrReplace(textcheck,"[ Monster Effect ]","----------------------------------------`n[ Monster Effect ]"))
					}
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,cxml.colorizeText(bracket " ⚔️","Green",1)))
				
				case "[ Pendulum Effect ]" :
					textcheck := cxml.getMajorCardProp("text")
					if !InStr(textcheck,bracket "`n"){
						cxml.setMajorCardProp("text", StrReplace(textcheck,bracket a_space, bracket "`n"))
					}
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),bracket,cxml.colorizeText(bracket " ⚖","Brown",1)))
				
				case "[ Flavor Text ]" :
					findFlavorText := RegExMatchAll(cxml.getMajorCardProp("text"),"ms)(\[ Flavor Text \](.+))",0)
					cxml.setMajorCardProp("text",StrReplace(cxml.getMajorCardProp("text"),findFlavorText[1,1],cxml.boldOrItalicText(findFlavorText[1,2],2)))

				case "[ Link Markers ]" :
                    ;do nothing, it's set above due to a bug
				Default:
					msgbox "undefined: " bracket
					continue
				
				
			}
		}
    }


}
cxml.generateXML()

ExitApp



fLinkMarkers(){
	LinkMarkers := Map("Bottom-Left","↙️"
	,"Bottom-Right","↘️"
	,"Top-Left","↖️"
	,"Top-Right","↗️"
	,"Bottom","⬇️"
	,"Right","➡️"
	,"Top","⬆️"
	,"Left","⬅️")
	return LinkMarkers
}


yugiohLists(cardObj){
	lists := Map("name",Map()
        ,   "race", Map()
        ,   "archetype", Map()
        ,   "type", Map())

	for k,v in cardObj{
        lists["name"][v["name"]] := 1
        try lists["race"][v["race"]] := 1
        try lists["archetype"][v["archetype"]] := 1
        try lists["type"][v["type"]] := 1
	}
	
	for k,v in ["name","race","archetype","type"]	;prunes empty keys from the list
		lists[v].delete("")
	return lists
}

sortSetsByDate(setObj){
    retObj := Map()
    for k,v in setObj {
        if retObj.Has(v["tcg_date"])
            continue
        retObj[v["tcg_date"]] := v["set_code"]
    }
    ; MsgBox A_Clipboard := JSON.Dump(retObj)
    return retObj
}


selectLang(incomingArr){	;just picks the first language available
	;uses order found on https://db.ygorganization.com/about/api
	static langOrder := StrSplit("en|ja|de|fr|it|es|pt|ko","|")
	
	;MSGBOX % st_printarr(incomingArr)
	for k,v in langOrder {
		if incomingArr.Has(v)
			return v
	}
}



RegExMatchAll(haystack, needleRegEx, startingPosition := 1) {
	out := [], end := StrLen(haystack)+1
	While startingPosition < end && RegExMatch(haystack, needleRegEx, &outputVar, startingPosition)
		out.Push(outputVar), startingPosition := outputVar.Pos + (outputVar.Len || 1)
	return out
}