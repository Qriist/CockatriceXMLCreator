#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk


;generate monitor window
gxml := Gui() ;todo - move this window into CockatriceXMLCreator
gxml.Title := "YuGiOh XML Creator"
gxml.Opt("+Resize +MinSize250")
text1 := gxml.Add("Text","w300 BackgroundTrans center vtext1","")
text2 := gxml.Add("Text","w300 BackgroundTrans center vtext2","Gathering card list...")
text3 := gxml.Add("Text","w300 BackgroundTrans center vtext3","")
gxml.Show("autosize center")

;prepare starting environment
cxml := CockatriceXMLCreator("Yu-Gi-Oh")
api := apiQache()
; api.nuke(1)
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
text2.text := "Gathering set list..."
setObj := JSON.Load(api.retrieve("https://db.ygoprodeck.com/api/v7/cardsets.php",,,,,,forceBurn?))

text2.text := "Gathering manifest..."

manifestStr := api.retrieve("https://db.ygorganization.com/manifest/" storedCacheRevision,,,,,,1)
; MsgBox api.lastResponseHeaders

;todo - fill in the rest of the manifest checking

; api.begin()

;backup id<->name list just in case main DB doesn't quite align with QA DB.
ids := json.load(api.retrieve("https://db.ygorganization.com/data/idx/card/name/en"))
konamiIds := Map()
for k,v in ids {
    konamiIds[ids[k][1]] := k
}

LinkMarkers := fLinkMarkers()	;used for link monster arrows

;scrape a few properties used for related cards and various highlights
lists := yugiohLists(CardObj)

;processing sets
text2.Text := "Processing sets..."
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
    text1.Text := "Scraping data for..."
    text2.Text := record["name"]
    text3.Text := a_index " / " CardTotal " processed. (" (a_index/CardTotal*100) "%)"

	If (InStr(record["type"],"Monster"))
	{
		cxml.setCardProp("pt",record["atk"] "/" record["def"])
		cxml.setCardProp("maintype","Monster")
        cxml.setCardProp("type","Monster " cxml.ld() " subtypes")
        /*
		cxml.setCardProp("type", regexreplace("Monster " cxml.ld() " " record["race"] " " StrReplace(record["type"],"Monster") (record["archetype"]!=""?a_space record["archetype"]:""), "(\h)+", "$1"))
		if record.HasKey("linkmarkers"){
			outLinkMarkers := ""
			for k,v in record["linkmarkers"] {
				outLinkMarkers .= a_space a_space StrReplace(record["linkmarkers"][a_index],record["linkmarkers"][a_index],LinkMarkers[record["linkmarkers"][a_index]])
			}
			cxml.setMajorCardProp("text"
			,cxml.getMajorCardProp("text") "`n`n"
			;.	cxml.boldOrItalicText( cxml.colorizeText("[ Link Markers ]","OrangeRed") a_space outLinkMarkers,1))
			.	"[ Link Markers ]" a_space outLinkMarkers,1)
			cxml.setCardProp("pt",record["atk"] " / [" record["linkval"] "]  " StrReplace(outLinkMarkers,a_space))
		}
        */
		cxml.setMajorCardProp("tablerow",3)
	}
    ; MsgBox Type(record["card_sets"]) A_Clipboard := JSON.Dump(record)
    ; continue
    try {

        for k,v in record["card_sets"]{
            setRecord := record["card_sets"][k]
            setArr := Map("rarity", setRecord["set_rarity"])
            cxml.attachSetToCard(StrSplit(setRecord["set_code"],"-")[1],setArr)
            ; MsgBox A_Clipboard := JSON.Dump(record)
        }
    } catch {
            misc := record["misc_info"][1]
            ; msgbox A_Clipboard := sortedSets ;JSON.Dump(sortedSets[misc["ocg_date"]])
            ; msgbox misc["ocg_date"]
            if misc.has("ocg_date") && sortedSets.Has(misc["ocg_date"])
                cxml.attachSetToCard(sortedSets[misc["ocg_date"]],Map())
            if misc.has("tcg_date") && sortedSets.Has(misc["tcg_date"])
                cxml.attachSetToCard(sortedSets[misc["tcg_date"]],Map())
            ; cxml.attachSetToCard(sortedSets[])
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

}

outXml := cxml.generateXML()
FileOpen(A_ScriptDir "\cxml\Yu-Gi-Oh\data\cards.xml","w").Write(outXml)
; Sleep(3000)
gxml.Destroy()
ExitApp



fLinkMarkers(){
	LinkMarkers := Map("Bottom-Left","↙️"
	,"Bottom-Right","↘️"
	,"Top-Left","↖️"
	,"Top-Right","↗️"
	,"Bottom","↓"
	,"Right","→"
	,"Top","↑"
	,"Left","←")
	
	return LinkMarkers
}


yugiohLists(cardObj){
	lists := Map("name",Map()
        ,   "race", Map()
        ,   "archetype", Map()
        ,   "type", Map())

	for k,v in cardObj{
        lists["name"][v["name"]] := 1
        try
		    lists["race"][v["race"]] := 1
        try
		    lists["archetype"][v["archetype"]] := 1
        try
		    lists["type"][v["type"]] := 1
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
