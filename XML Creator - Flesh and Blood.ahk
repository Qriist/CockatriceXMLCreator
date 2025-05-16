#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk
cxml := CockatriceXMLCreator("Flesh and Blood")
api := apiQache()

pitch  := [
	"Red",
	"Yellow",
	"Blue"
]

iconMap := Map()
; iconMap[""]
;pre-load cards from official API - used to get html effects
cxml.gtext(2,"Preloading card data...")
url := "https://cards.fabtcg.com/api/search/v1/cards/?"
massCardObj := Map()
loop {
	jsonObj := json.Load(api.retrieve(url))
	For k,v in jsonObj["results"] {
		record := v
		name := record["name"]
		If (record["pitch"] != "")
			name .= " (" pitch[record["pitch"]] ")"
		massCardObj[name] := record["text_html"]
	}

	url := jsonObj["next"]
	if (url = "")
		break
}


;roll over set data
cxml.gtext(2,"Gathering set data...")
url := "https://the-fab-cube.github.io/flesh-and-blood-cards/json/english/set.json"
jsonObj := json.Load(api.retrieve(url))
for k,v in jsonObj{
	record := v
	cxml.newSetEntity(record["id"])
	cxml.setSetProp("name",StrUpper(record["id"]))
	cxml.setSetProp("releasedate",record["printings"][1]["initial_release_date"])
	cxml.setSetProp("longname",record["name"])
}

cxml.gtext(2,"Gathering card data...")
url := "https://the-fab-cube.github.io/flesh-and-blood-cards/json/english/card.json"
jsonObj := json.Load(api.retrieve(url))
for k,v in jsonObj {
	record := v

	if (record["pitch"] != ""){
		pn := record["name"] " (" pitch[record["pitch"]] ")"
		cxml.newCardEntity(pn)
		cxml.setMajorCardProp("name",pn)
		cxml.setCardProp("colors",pitch[record["pitch"]])
	} else {
		pn := record["name"]
		cxml.newCardEntity(pn)
		cxml.setMajorCardProp("name",pn)
	}
	if massCardObj.Has(pn)
		text := massCardObj[pn]
	else
		text := record["functional_text_plain"]
	
	;some hacky cleanups
	text := StrReplace(text,"<p>","<br>")
	text := StrReplace(text,"`n<ul>","<ul>")
	text := StrReplace(text,"`n<li>`n<br>","<li>")
	text := StrReplace(text,"</li>`n")
	text := StrReplace(text,"`n</li>","</li>")
	text := StrReplace(text,"</p>")


	iconRegex ??= "mU)(<img src='(.+)' alt='(.+)'>)"
	regexObj := RegExMatchAll(text,iconRegex)

	;the icons don't load from an external source so we embed them
	for k,v in regexObj{
			replaceStr := v[0]
			iconUrl := v[2]
			iconName := v[3]
			assetPath := a_scriptdir "\assets\Flesh and Blood\" iconName ".png"

			if !FileExist(assetPath){
				assetBuf := api.asset(iconUrl)
				f := FileOpen(assetPath,"w")
				f.RawWrite(assetBuf)
				f.Close()

				tempFile := cxml.resizeImage(assetPath,26)
				FileDelete(assetPath)
				; msgbox FileExist(tempFile) "`n___`n" FileExist(assetPath)
				
				FileCopy(tempFile,assetPath)
			}
			iconMap[iconName] ??= cxml.embedImage(assetPath)
			text := StrReplace(text,replaceStr,iconMap[iconName],,,1)
			
	}

	;follow up pass to make sure non-html icons are extracted
	regexObj := RegExMatchAll(text,"mU)(\{.\})")
	for k,v in regexObj {
		iconName := v[1]
		assetPath := a_scriptdir "\assets\Flesh and Blood\" iconName ".png"
		if !FileExist(assetPath)	;in case of new assets
			continue
		iconMap[iconName] ??= cxml.embedImage(assetPath)
		text := StrReplace(text,iconName,iconMap[iconName],,,1)
	}
	

	cxml.setMajorCardProp("text",text)

	cxml.setCardProp("type",record["type_text"])
	cxml.setCardProp("cmc",record["cost"])

	pt := record["power"] "/" record["defense"]
	cxml.setCardProp("pt",Trim(pt,"/"))
	if InStr(record["type_text"],"Hero")
		cxml.setCardProp("pt",record["health"] "/" record["health"])

	

	if (record["power"] != "")
		cxml.setCardProp("Power",record["power"])
	if (record["defense"] != "")
		cxml.setCardProp("Defense",record["defense"])

	if (record["health"] != "")
		cxml.setCardProp("Health",record["health"])
	if (record["intelligence"] != "")
		cxml.setCardProp("Intelligence",record["intelligence"])

	;check format legality
	formatObj := [
		"blitz",
		"cc",
		"commoner",
		"ll",
		"upf"
	]
	for k,v in formatObj {
		gameFormat := v
		legality := "not_legal"
		try if record[gameFormat "_legal"] = 1
			legality := "legal"
		try if record[gameFormat "_suspended"] = 1
			legality := "suspended"
		; try if record[gameFormat "_restricted"] = 1	;cockatrice will keep it from results
			; legality := "restricted"
		try if record[gameFormat "_banned"] = 1
			legality := "banned"
		cxml.setCardProp("format-" gameFormat,legality)
	}

	dedupe := Map()
	for k,v in record["printings"]{
		set_printing_unique_id := v["id"] "/" v["set_printing_unique_id"]
		if dedupe.Has(set_printing_unique_id)
			continue
		dedupe[set_printing_unique_id] := 1

		setObj := Map()
		setId := StrUpper(v["set_id"])
		setObj["num"] := StrReplace(v["id"] ,setId)

        setObj["rarity"] := v["rarity"]

        ;images can be attached to real sets thanks to cockatrice improvements
        setObj["picURL"] := v["image_url"]
        setObj["imageCollapse"] := set_printing_unique_id
        
        ; ;artist info, too
        ; try setObj["artist"] := record["artist"]

		cxml.attachSetToCard(setId,setObj)
	}



}

cxml.generateXML()

ExitApp

RegExMatchAll(haystack, needleRegEx, startingPosition := 1) {
	out := [], end := StrLen(haystack)+1
	While startingPosition < end && RegExMatch(haystack, needleRegEx, &outputVar, startingPosition)
		out.Push(outputVar), startingPosition := outputVar.Pos + (outputVar.Len || 1)
	return out
}