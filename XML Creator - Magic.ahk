#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk
cxml := CockatriceXMLCreator("Magic")
api := apiQache()

realXmlPath := "C:\Users\Qriist\AppData\Local\Cockatrice\Cockatrice\cards.xml"
realXml := FileOpen(realXmlPath,"r").Read()
patchedXmlPath := a_scriptdir "\cxml\Magic\data\cards.xml"
patchedXml := FileOpen(patchedXmlPath,"w")

massDataObj := JSON.Load(FileOpen(A_ScriptDir "\AllPrintings.json","r","UTF-8").Read())["data"]


;sort by date to ensure consistency
sortedSets := Map()
for k,v in massDataObj{
    date := v["releaseDate"]
    sortedSets[date] ??= Map()
    sortedSets[date][k] := 1
}

regexLine := ""
encountered := Map()
num := 0
notfound := 0
missing := Map()
for k,v in massDataObj{
    setObj := v
    for k,v in setObj["cards"] {
        num += 1
        cardObj := v
        cxml.gtext(2,num)
        ; switch cardObj["name"] {
        ;     case "Sol Ring", "Necrotic Ooze", "Reins of Power", "Cultivate", "Izzet Signet", "Damnation", "Drogskol Reaver":
        ;         ;do nothing
        ;     default:
        ;         continue
        ; }

        ids := cardObj["identifiers"]
        If !ids.has("scryfallIllustrationId")
            continue    ;no art to identify
        scryfallIllustrationId := ids["scryfallIllustrationId"]

        paramObj := Map()
        paramObj["scryfallIllustrationId"] := scryfallIllustrationId

        try paramObj["borderColor"] := cardObj["borderColor"]
        try paramObj["flavorText"] := cardObj["flavorText"]
        try paramObj["frameEffects"] := cardObj["frameEffects"]
        try paramObj["frameVersion"] := cardObj["frameVersion"]
        ; try paramObj["watermark"] := cardObj["watermark"]
        ; try paramObj["promoTypes"] := cardObj["watermark"]

        hash := cxml.uniqify(paramObj)

        if !encountered.has(hash){
            encountered[hash] := ids["scryfallId"]
        }
        
        regex := 'Um)uuid="' ids["scryfallId"] '"'
        replace := 'uuid="' ids["scryfallId"] '" imagecollapse="' encountered[hash] '"'
        realXml := RegExReplace(realXml,regex,replace)






        ; regexLine .= '(<set.+uuid="' ids["scryfallId"] '".+<\/set>)|'

        ; if InStr(realXml,ids["scryfallId"])
            ; msgbox A_Clipboard := ids["scryfallId"]
        ; setline := "<set"
        ; try setline .= ' muid="' ids["multiverseId"] '"'
        ; try setline .= ' uuid="' ids["scryfallId"] '"'
        ; try setline .= ' rarity="' cardObj["rarity"] '"'
        ; try setline .= ' num="' cardObj["number"] '"'
        ; setline .= ">" cardObj["setCode"] "</set>"
        ; msgbox A_Clipboard := setline
        ; msgbox InStr(realXml,setline)
        ; realXml := StrReplace(realXml,setline,,,&check := 0)
        ; MsgBox "|" Format("{:" StrLen(setline) "}","") "|"
    }
        
}
; regexLine := "Um)" RTrim(regexLine,"|")
; msgbox StrLen(regexLine)
; RegExReplace(realXml,regexLine)
patchedXml.Write(realXml)
patchedXml.Close()
ExitApp
cxml.gtext(2,"Loading input json...")
massSetObj := JSON.Load(FileOpen(A_ScriptDir "\AllPrintings.json","r").Read())["data"]


;first pass to parse sets
for k,v in massSetObj {
    record := v
    cxml.newSetEntity(k)
    cxml.setSetProp("name",k)
    cxml.setSetProp("releasedate",record["releaseDate"])
    cxml.setSetProp("longname",record["name"])
    cxml.setSetProp("settype",StrTitle(StrReplace(record["type"],"_"," ")))
    cxml.setSetProp("priority",10)  ;eh
}

;second pass to parse cards
for k,v in massSetObj{
    setCode := k
    setObj := v
    for k,v in setObj{

    }
}


ExitApp