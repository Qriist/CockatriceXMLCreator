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
HashArray := []
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;~ #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
Gui, XML: New, +MinSizex250
Gui, Add, Text,w300 BackgroundTrans center vText1,
Gui, Add, Text,w300 BackgroundTrans center vText2,Gathering set list...
Gui, Add, Text,w300 BackgroundTrans center vText3,
Gui, Show,autosize center,Pokemon XML Creator

OnExit, ExitRoutine	;ensures graceful shutdown of the database
cXml := new class_cockatriceXML
cxml.init("Pokemon")
apiCache := new class_ApiCache


;FileDelete, % A_ScriptDir "\cache\XML Creator - YuGiOh.db*"	;easy db delete for testing
apiCache.init(A_ScriptDir "\yugioh\",A_ScriptDir "\cache\XML Creator - Pokemon.db")
apiCache.initExpiry(86400) ;updates local cache once per day

;get energy types
energyObj := JSON.load(apiCache.retrieve("https://api.pokemontcg.io/v2/types"))["data"]
loop,{	;get the sets
	massSetObj := JSON.load(apiCache.retrieve("https://api.pokemontcg.io/v2/sets?&page=" a_index))
	for k,v in massSetObj["data"]{
		record := v
		cxml.newSetEntity(record["set_code"])
		cxml.setSetProp("releasedate",record["releaseDate"])
		cxml.setSetProp("longname",record["name"])
		cxml.setSetProp("settype",record["series"])
	}
	
	if (massSetObj["count"] = 0)	;no cards served, so we're at the end of the list.
		break
}

sortedCardObj := []
;sorting the cards by release date so the uiqified card's name is the same across db updates
loop, {
	if (apiCache.lastServedSource = "server")
		sleep, 100	;keep from hammering the server
	massCardObj := JSON.load(apiCache.retrieve("https://api.pokemontcg.io/v2/cards?&page=" a_index))
	for k,v in massCardObj["data"] {
		pushVal := (sortedCardObj[massCardObj["data",k,"set","releaseDate"]].count() + 1)
		if (pushVal = "")
			pushVal = 1
		;msgbox % massCardObj["data",k,"set","releaseDate"]
		sortedCardObj[massCardObj["data",k,"set","releaseDate"],pushVal] := v
	}
	if (massCardObj["count"] = 0)	;no cards served, so we're at the end of the list.
		break
}


deduped := []	;to keep track of hash<->cxml name
for k,v in sortedCardObj {
	releaseDate := k
	for k,v in sortedCardObj[releaseDate] {
		record := v
		
		;if (record["supertype"] = "Pokémon")
			;continue
		;If !record.HasKey("abilities")
		;If !record.haskey("ancientTrait")
			;continue
		
		;cardText := []	;allows for better control of individual card elements
		
		;Have to gather some de-dupe information before actually adding the card to the xml
		cardHash := cxml.uniqify(,,record["name"],record["attacks"],record["weaknesses"],record["resistances"],record["retreatCost"],record["abilities"],record["ancientTrait"],record["rules"])
		
		;by entering the cardHash as the entity name we can safely roll over the rest of the data without fear of overwriting data during XML generation. If we DO end up overwriting cards then just add more uniqify variables until we don't.
		cxml.newCardEntity(cardHash)	;newCardEntity() doesn't overwrite
		cxml.changeCardEntity(cardHash)	;must set manually due to not making a new cardEntity each time
		
		;have to set the name to something sensible
		If !deduped.HasKey(cardHash)	;only sets the name when first encountering this hash
			cxml.setMajorCardProp("name",record["name"] a_space StringUpper(record["id"]))	
		;msgbox % record["set","id"]
		
		setObj := {"rarity":record["rarity"]}
		cxml.attachSetToCard(StringUpper(record["set","id"]),setObj)
		
		;these images are not really deduped across printings, but they will at least contain id codes in the manager
		picURL := (record["images"].HasKey("large")?record["images","large"]
			:record["images"].HasKey("small")?record["images","small"]
			:"")	;find the large image, or the small image, or nothing.
			;msgbox % record["images","large"] "`n" picURL
		cxml.attachSetToCard(chr(176) cxml.getMajorCardProp("name") a_space "[" StringUpper(record["id"]) "]",(picUrl!=""?{"picURL":picURL}:"") )  
		
		
		if (deduped[cardHash] != "")
			Continue	;nothing further to do with a duped card now that we found the sets
		
		deduped[cardHash] := cxml.getMajorCardProp("name")
		
		cxml.setCardProp("maintype",record["supertype"])
		cxml.setCardProp("colors", st_glue(record["types"," "]))
		cxml.setCardProp("pt",record["hp"])
		
		;TODO - format legality
		
		switch record["supertype"]{
			
			case "Pokémon":{ 
				
				
				cxml.setMajorCardProp("text",  cxml.colorizeText( "❤️" record["hp"],"tomato",1) "`n")
				
				if instr(record["name"],"leafeon")
					cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.embedComment("I exile target player's graveyard"))
				
				If (record.haskey("evolvesFrom")){
					cxml.setCardProp("Evolves_From",record["evolvesFrom"])
					cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.embedComment("evolves from " record["evolvesFrom"]) )
				}
				If (record["evolvesTo"].count() > 0){
					cxml.setCardProp("Evolves_To",st_glue(record["evolvesTo"],", "))
					cxml.setMajorCardProp("text", cxml.getMajorCardProp("text")  )
					For k,v in record["evolvesTo"]{
						cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.embedComment("evolves to " v) )
					}
				}
				cxml.setCardProp("type", "Pokémon" cxml.ld() Trim(st_glue(record["subtypes"], " ") a_space st_glue(record["types"], " ")))
				if record.haskey("ancientTrait"){
					tableObj := []
					tableObj[1,1,"text"] := cxml.colorizeText(chr(160) "Ancient" chr(160) "Trait" chr(160),"White",1)
					tableObj[1,1,"background-color"] := "DarkGoldenRod"
					
					tableObj[2,1,"text"] := record["ancientTrait","text"]
					tableObj[2,1,"colspan"] := 2
					;tableObj[1,2,"rowspan"] := 2
					
					tableObj[1,2,"text"] := "<h3>" chr(160) chr(160) StrReplace(record["ancientTrait","name"]," ",chr(160)) chr(160) chr(160) "</h3>" cxml.embedComment(record["ancientTrait","name"]) cxml.embedComment("ancient trait")
					tableObj[1,2,"text-align"] := "center"
					tableObj[1,2,"vertical-align"] := "middle"
					tableObj[1,2,"background-color"] := "DarkGoldenRod"
					
					;tableObj[3,1,"text"] := "."
					;tableObj[2,3,"text"] := ""
					;tableObj[2,1,"text"]  :
					cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
					
				}
				for k,v in record["abilities"]{
					switch v["type"] {
						case "Pokémon Power":{
							tableObj := []
							tableObj[1,1,"text"] := cxml.colorizeText(chr(160) "Pokémon" chr(160) "Power" chr(160),"White",1) cxml.embedComment("Pokémon Power") cxml.embedComment("Pokemon Power") 
							tableObj[1,1,"background-color"] := "#CD5C5C"
							tableObj[1,1,"text-align"] := "center"
							
							tableObj[1,2,"text"] :=  chr(160) chr(160) cxml.colorizeBackgroundAndText(StrReplace(v["name"]," ",chr(160)),"","white",1) chr(160) chr(160)  cxml.embedComment(v["name"])
							tableObj[1,2,"text-align"] := "center"
							tableObj[1,2,"vertical-align"] := "middle"
							tableObj[1,2,"background-color"] := "#CD5C5C"
							
							tableObj[2,1,"text"] := v["text"]
							tableObj[2,1,"colspan"] := 2
							
							cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
							
							;checkUrls .= "Pokémon Power: " record["images","large"] "`n"
							;msgbox % st_printArr(v)
						}
						case "Poké-Body":{
							tableObj := []
							tableObj[1,1,"text"] := cxml.colorizeText(chr(160) "Poké-Body" chr(160),"White",1) cxml.embedComment("Poke-Body") 
							tableObj[1,1,"background-color"] := "#CD5C5C"
							tableObj[1,1,"text-align"] := "center"
							
							tableObj[1,2,"text"] :=  chr(160) chr(160) cxml.colorizeBackgroundAndText(v["name"],"","white",1) chr(160) chr(160)  cxml.embedComment(v["name"]) 
							tableObj[1,2,"text-align"] := "center"
							tableObj[1,2,"vertical-align"] := "middle"
							tableObj[1,2,"background-color"] := "#CD5C5C"
							
							tableObj[2,1,"text"] := v["text"]
							tableObj[2,1,"colspan"] := 2
							
							cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
							;msgbox % st_printArr(v)
							;checkUrls .= "Poké-Body: " record["images","large"] "`n"
							
						}
						case "Poké-Power":{
							tableObj := []
							tableObj[1,1,"text"] := cxml.colorizeText(chr(160) "Poké-Power" chr(160),"White",1) cxml.embedComment("Poke-Power") 
							tableObj[1,1,"background-color"] := "#CD5C5C"
							tableObj[1,1,"text-align"] := "center"
							
							tableObj[1,2,"text"] :=  chr(160) chr(160) cxml.colorizeBackgroundAndText(v["name"],"","white",1) chr(160) chr(160)  cxml.embedComment(v["name"]) 
							tableObj[1,2,"text-align"] := "center"
							tableObj[1,2,"vertical-align"] := "middle"
							tableObj[1,2,"background-color"] := "#CD5C5C"
							
							tableObj[2,1,"text"] := v["text"]
							tableObj[2,1,"colspan"] := 2
							
							cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
							;checkUrls .= "Poké-Power: " record["images","large"] "`n"
							
						}
						case "Ability":{
							tableObj := []
							tableObj[1,1,"text"] := cxml.colorizeText(chr(160) "Ability" chr(160),"White",1) 
							tableObj[1,1,"background-color"] := "#CD5C5C"
							tableObj[1,1,"text-align"] := "center"
							
							tableObj[1,2,"text"] :=  chr(160) chr(160) cxml.colorizeBackgroundAndText(v["name"],"","white",1) chr(160) chr(160)  cxml.embedComment(v["name"]) 
							tableObj[1,2,"text-align"] := "center"
							tableObj[1,2,"vertical-align"] := "middle"
							tableObj[1,2,"background-color"] := "#CD5C5C"
							
							tableObj[2,1,"text"] := v["text"]
							tableObj[2,1,"colspan"] := 2
							
							cxml.setMajorCardProp("text", cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
							;checkUrls .= "Ability: " record["images","large"] "`n"
							
						}
						Default: {
							msgbox % "undefined ability type: " v["type"]
						}
						
					}
					;switch v["type"]
					;msgbox % v["type"]
				}
				
				For k,v in record["attacks"]{ ;*[XML Creator - Pokemon]
					atkRecord := v
					tableObj := []
					;energy costs
					;tableObj[1,1,"text"] := a_space	;makes sure the cell will exist even if there's no cost
					;lastEnergy := ""
					for k,v in atkRecord["cost"]{
						if (atkRecord["convertedEnergyCost"] != 0)
							tableObj[1,1,"text"] .= cxml.embedImage(a_scriptdir "\assets\pokemon\energy\" v "_medium.png") cxml.embedComment(v " Energy", cxml.getMajorCardProp("text")) 
						else
							tableObj[1,1,"text"] .= ""
					}
					;if (atkRecord[cost].count() < 3){
						;cxml.setMajorCardProp("text",)
					;}
					
					;attack name
					;tableObj[1,2,"text"] .= "<h3>" StrReplace(atkRecord["name"],a_space,Chr(160)) "</h3>"
					;tableObj[1,1,"text"] := "<h4>" cxml.colorizeBackgroundAndText(tableObj[1,1,"text"] (atkRecord["convertedEnergyCost"]!=0?Chr(160):"") StrReplace(atkRecord["name"]," ", Chr(160))  ,"silver") "</h4>"
					tableObj[1,1,"text"] := "<h3>" cxml.colorizeBackgroundAndText(tableObj[1,1,"text"] (atkRecord["convertedEnergyCost"]!=0?Chr(160):"") StrReplace(atkRecord["name"]," ", Chr(160))  ,"#FBB917",,1) cxml.embedComment(atkRecord["name"]) "</h3>"
					;tableObj[1,2,"text"] := "<h3>" cxml.colorizeBackgroundAndText((atkRecord["convertedEnergyCost"]!=0?Chr(160):"") StrReplace(atkRecord["name"]," ", Chr(160))  ,"#FBB917",,1) cxml.embedComment(atkRecord["name"]) "</h3>"
					tableObj[1,1,"colspan"] := 2
					
					;tableObj[1,2,"text-align"] := "center"
					
					;tableObj[1,2,"text"] := atkRecord["name"]
					;tableObj[1,2,"text-align"] := "left"
					;tableObj[1,2,"vertical-align"] := "middle"
					;tableObj[1,1,"vertical-align"] := "bottom"
					
					;tableObj[1,2,"text"] := ""
					;tableObj[1,3,"text"] := ""
					;tableObj[1,4,"text"] := ""
					;atk := atkRecord["damage"]
					;atk := SubStr(st_pad(atk,Chr(160),"",10,0),-1,10) 
					;tableObj[1,2,"text"] := cxml.colorizeBackgroundAndText(atk Chr(160),,,1)
					;tableObj[1,2,"background-color"] := "red"
					
					
					if (atkRecord["damage"] != ""){
						tableObj[2,1,"text"] :=  "Damage: " cxml.colorizeBackgroundAndText(atkRecord["damage"],,"red",1)
						tableObj[2,1,"colspan"] := 2
					}
					tableObj.push([])	;makes a new row so the following .count() works correctly
					tableObj[tableObj.count(),1,"text"] :=  (atkRecord["text"]!=""?atkRecord["text"]:"[No additional effects.]")
					tableObj[tableObj.count(),1,"colspan"] := 2
					
					if (strlen(tableObj[tableObj.count(),1,"text"]) < 50)
						tableObj[tableObj.count(),1,"text"] := SubStr(st_pad(tableObj[tableObj.count(),1,"text"],"",Chr(160),,50),1,50) 
					;tableObj[1,2,"text"] := chr(160) chr(160) chr(160)
					
					;attack damage
					;tableObj[2,2,"text"] := (atkRecord["damage"]=""?"":"Damage: " atkRecord["damage"])
					;tableObj[1,2,"text-align"] := "left"
					;tableObj[1,2,"colspan"] := 3
					
					;attack text
					if (atkRecord["damage"] != ""){
						
					}
					colRowObj := []
					colRowObj["row",1,"background-color"] := "#FBB917"
					cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable(tableObj,colRowObj) "`n")
					;msgbox % st_printArr(atkrecord)
				}
				
				{	;try to build these together
					
					tableObj := []
					
					tableObj[1,1,"text"] := chr(160) "Weaknesses" chr(160)
					tableObj[1,1,"background-color"] := "#FADBD8"
					tableObj[2,1,"background-color"] := "#FADBD8"
					
					tableObj[1,2,"text"] := chr(160) "Resistances" chr(160)
					tableObj[1,2,"background-color"] := "#AED6F1"
					tableObj[2,2,"background-color"] := "#AED6F1"
					
					
					
					tableObj[1,3,"text"] := chr(160) "Retreat" chr(160)
					tableObj[1,3,"background-color"] := "#D6DBDF"
					tableObj[2,3,"background-color"] := "#D6DBDF"
					
					for k,v in record["resistances"] {
						tableObj[2,2,"text"] .= cxml.embedImage(a_scriptdir "\assets\pokemon\energy\" v["type"] "_small.png") cxml.embedComment(v["type"]) 
					}
					
					
					for k,v in record["weaknesses"] {
						tableObj[2,1,"text"] .= cxml.embedImage(a_scriptdir "\assets\pokemon\energy\" v["type"] "_small.png") cxml.embedComment(v["type"]) 
					}
					
					for k,v in record["retreatCost"] {
						tableObj[2,3,"text"] .= cxml.embedImage(a_scriptdir "\assets\pokemon\energy\" v "_small.png") cxml.embedComment(v) 
					}
					
					cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addTable(tableObj) "`n")
				}
			}
			
			case "Energy","Trainer": {
				cxml.setCardProp("type", record["supertype"] " " (record["subtypes"].count()>0?cxml.ld() " " st_glue(record["subtypes"]):""))
				listObj := []
				for k,v in record["rules"]{
					listText := v
					for k,v in energyObj{
						if Instr(listText,v)
							listText := StrReplace(listText,v,cxml.embedImage(a_scriptdir "\assets\pokemon\energy\" v "_tiny.png") cxml.embedComment(v,listText))
					}
					listObj.push(listText)
					
					;cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addList(listObj) "`n")
				}
				cxml.setMajorCardProp("text",cxml.getMajorCardProp("text") cxml.addList(listObj) "`n")
				
			}
			;case "Trainer" : {
			
			;}
			
		}
		;for k,v in record["card_images"] {
		
			;imageRecord := record["card_images",k]
			;cxml.attachSetToCard(chr(176) record["id"] "." a_index,{"picURL":imageRecord["image_url"]})
		;}
		;cxml.setMajorCardProp("text",record["desc"])		
		;cxml.setMajorCardProp("text",record["desc"])
		;cxml.setCardProp("colors",(record["attribute"]!=""?record["attribute"]:"NORMAL"))
		;cxml.setCardProp("cmc",(record.HasKey("level")?record["level"]:0)) ;set to 0 if no level found
		;cxml.setCardProp("ID",record["id"])
		;cxml.setCardProp("Type",record["type"])
		;cxml.setCardProp("Race",record["race"])
		;cxml.setCardProp("Archetype",record["archetype"])
		;cxml.setCardProp("Konami_ID",record["misc_info",1,"konami_id"])
		;if instr(cxml.getMajorCardProp("name"),"pikachu")
			;msgbox % st_printArr(cxml.getCardEntity())
		;msgbox % st_printArr(record)
		
	}
}
;Sort,checkUrls
;msgbox % Clipboard := checkUrls
outXml := cxml.generateXML()
FileOpen("E:\Projects\Cockatrice XML Creators\cxml testing\pokemon\data\cards.xml","w").write(outXml)
run,E:\Projects\Cockatrice XML Creators\cxml testing\pokemon\cockatrice.exe
ExitApp

CardTotal=0
Loop,
{
	
	If SetCodeList=
		SetCodeList=%setcode%
	else
		SetCodeList =  %setcodelist%,%setcode%
	CardTotal := CardTotal + SetListObj.sets[a_index].totalCards
	If SetListObj.sets[a_index].standardLegal=True
		StandardLegalSets=%standardlegalsets%%setcode%,
	If SetListObj.sets[a_index].expandedLegal=True
		ExpandedLegalSets=%ExpandedLegalSets%%setcode%,
	LongName := UnicodeToXML(SetListObj.sets[a_index].name)
	Series := UnicodeToXML(SetListObj.sets[a_index].series)
	ReleaseDate := UnicodeToXML(SetListObj.sets[a_index].releasedate)
		;~ UnicodeToXML(CardName)
	SetXML.="`n" A_Tab A_Tab "<set>`n"
	SetXML.=A_Tab A_Tab A_Tab "<name>" SetCode "</name>`n"
	SetXML.=A_Tab A_Tab A_Tab "<longname>" longname "</longname>`n"
	SetXML.=A_Tab A_Tab A_Tab "<settype>" Series "</settype>`n"
	SetXML.=A_Tab A_Tab A_Tab "<releasedate>" ReleaseDate "</releasedate>`n"
	SetXML.=A_Tab A_Tab "</set>"
}

StringTrimRight,StandardLegalSets,StandardLegalSets,1
StringTrimRight,ExpandedLegalSets,ExpandedLegalSets,1
CurrentCardCount=0
Loop,parse,SetCodeList,`,
{
	SetCode := A_LoopField
	SetCodeIndex =0
	
	
	Loop,
	{
		SpecificSetURL := DownloadToString("https://api.pokemontcg.io/v1/cards?pageSize=1000&page=" a_index "&setCode=" SetCode)
		;Clipboard := "https://api.pokemontcg.io/v1/cards?pageSize=1000&page=" a_index "&setCode=" SetCode
		SpecificSetObj := JSON.Load(SpecificSetURL)
		SpecificsetTotalCards := SpecificSetObj.cards.length()
		If SpecificsetTotalCards = 0
			break
		loop,%SpecificsetTotalCards%
		{
			CardId := SpecificSetObj.cards[SetCodeIndex].id
			CardText :=""
			CurrentCardCount+=1
			SetCodeIndex+=1
			CardText=
			CurrentCardPercent := CurrentCardCount / CardTotal * 100
			CardName := SpecificSetObj.cards[SetCodeIndex].name
			SetName := SpecificSetObj.cards[SetCodeIndex].set
			SetCode := SpecificSetObj.cards[SetCodeIndex].setCode
			StringUpper,setcode,setcode
			GuiControl, , Text1,Scraping data for %SetName% [%SetCode%]...
			GuiControl, , Text2,%cardname%
			GuiControl, , Text3,%CurrentCardCount% / %CardTotal% (%CurrentCardPercent%`%)
			Gui, Show,autosize NA,Pokemon XML Creator
			If SpecificSetObj.cards[SetCodeIndex].imageUrlHiRes!=""
				CardImage := SpecificSetObj.cards[SetCodeIndex].imageUrlHiRes
			Else
				CardImage := SpecificSetObj.cards[SetCodeIndex].imageUrl
			
			If SpecificSetObj.cards[SetCodeIndex].supertype="Pokémon" OR SpecificSetObj.cards[SetCodeIndex].supertype="Pok��mon"
			{
				SpecificSetObj.cards[SetCodeIndex].supertype := "Pokémon"
				CardHP := SpecificSetObj.cards[SetCodeIndex].hp
				CardText := "<font color=""tomato""><b>♥  HP: " CardHP "</b></font>`n`n"
				CardPowerToughness := "0/" CardHP
				
				;;;Discover and format types
				Loop % SpecificSetObj.cards[SetCodeIndex].types.length()
				{
					If CardTypes=
						CardTypes := SpecificSetObj.cards[SetCodeIndex].types[a_index]
					else
						CardTypes := CardTypes " " SpecificSetObj.cards[SetCodeIndex].types[a_index]
				}
				;~ MsgBox % CardTypes
				CardSubtype := SpecificSetObj.cards[SetCodeIndex].subtype
				
				
				;;;Discover and format Pre-Evolutions
				If SpecificSetObj.cards[SetCodeIndex].evolvesFrom!=""
				{
					CardEvolvesFrom := SpecificSetObj.cards[SetCodeIndex].evolvesFrom
					CardText = %CardText%<font color="green"><b>☣ Evolves from:</b></font> <i>%CardEvolvesFrom%</i>`n`n
				}
				else
					CardEvolvesFrom=
				
				;;;Discover and format Ancient Traits
				If SpecificSetObj.cards[SetCodeIndex].ancientTrait!=""
				{
					CardAncientTraitName := SpecificSetObj.cards[SetCodeIndex].ancientTrait.Name
					CardAncientTraitText := SpecificSetObj.cards[SetCodeIndex].ancientTrait.Text
					CardText = %CardText%<b><font color="DarkGoldenRod">∞ Ancient Trait</font></b> » <i>%CardAncientTraitName%</i>`n%CardAncientTraitText%`n`n
				}
				else
					CardAncientTrait=
				
				;;;Discover and format Abilities
				If SpecificSetObj.cards[SetCodeIndex].ability.name!=""
				{
					CardAbilityName := SpecificSetObj.cards[SetCodeIndex].ability.name
					CardAbilityText := SpecificSetObj.cards[SetCodeIndex].ability.text
					CardAbilityType := SpecificSetObj.cards[SetCodeIndex].ability.type
					If (CardAbilityType=Ability) OR (CardAbilityType="")
						CardText = %CardText%<font color="springgreen"><b>∴ Ability:</b></font> » <i>%CardAbilityName%</i>`n%CardAbilityText%`n`n
					Else
						CardText = %CardText%<font color="springgreen"><b>∴ Ability (%CardAbilityType%):</b></font> » <i>%CardAbilityName%</i>`n%CardAbilityText%`n`n
				}
				else
				{
					CardAbilityName=
					CardAbilityText=
					CardAbilityType=
				}
				
				
				;;;Discover and format Attacks
				Loop % SpecificSetObj.cards[SetCodeIndex].attacks.length()
				{
					AttackIndex := a_index
					Loop % SpecificSetObj.cards[SetCodeIndex].attacks[AttackIndex].cost.length()
					{
						AttackCost := SpecificSetObj.cards[SetCodeIndex].attacks[AttackIndex].cost[a_index]
						;~ MsgBox %  SpecificSetObj.cards[SetCodeIndex].attacks[a_index].cost[a_index]
						If a_index=1
							CardSpecificAttackCost=%AttackCost%
						Else 
							CardSpecificAttackCost=%CardSpecificAttackCost%, %attackcost%
					}
					CardSpecificAttackName := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].Name
					CardSpecificAttackText := Trim(SpecificSetObj.cards[SetCodeIndex].attacks[a_index].Text,a_space a_tab "`r`n")
					CardSpecificAttackdamage := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].damage
					CardSpecificAttackConvertedEnergyCost := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].ConvertedEnergyCost
					
					If (a_index = 1)
						CardText =%CardText%`n<b>Attacks</b>`n
					If (CardSpecificAttackText != "")
						CardText=%CardText%⚔ <i>%CardSpecificAttackName%</i> ⚔ »»» <b>%CardSpecificAttackdamage%</b>`n{%CardSpecificAttackCost%}`n%CardSpecificAttackText%`n`n
					else
						CardText=%CardText%⚔ <i>%CardSpecificAttackName%</i> ⚔ »»» <b>%CardSpecificAttackdamage%</b>`n{%CardSpecificAttackCost%}`n`n
					
					If CardSpecificAttackdamage=
					{
						AutoTrim,off
						StringReplace,CardText,CardText,⚔ »»» <b></b>,⚔,all
						AutoTrim,On
					}
					If SpecificSetObj.cards[SetCodeIndex].attacks.length() = a_index
					{
						;~ msgbox % SpecificSetObj.cards[SetCodeIndex].attacks.length() "`n" a_index
						CardText.="`n"
					}
					CardSpecificAttackCost=
				}
				
				
				;;;Discover and format Resistances
				Loop % SpecificSetObj.cards[SetCodeIndex].resistances.length()
				{
					ResistanceIndex := a_index
					ResistanceType := SpecificSetObj.cards[SetCodeIndex].resistances[ResistanceIndex].Type
					ResistanceValue := SpecificSetObj.cards[SetCodeIndex].resistances[ResistanceIndex].Value
					If a_index=1
						CardSpecificResistance=<i>%ResistanceType%:</i> <font color="Blue"><b>%ResistanceValue%</b></font>`n
					Else 
						CardSpecificResistances=%CardSpecificResistance%<i><font color="Blue">%ResistanceType%:</i> <b>%ResistanceValue%</b></font>`n
				}
				
				
				;;;Discover and format Weaknesses
				Loop % SpecificSetObj.cards[SetCodeIndex].weaknesses.length()
				{
					WeaknessIndex := a_index
					WeaknessType := SpecificSetObj.cards[SetCodeIndex].Weaknesses[WeaknessIndex].Type
					WeaknessValue := SpecificSetObj.cards[SetCodeIndex].Weaknesses[WeaknessIndex].Value
					If a_index=1
						CardSpecificWeakness=<i>%WeaknessType%:</i> <font color="red"><b>%WeaknessValue%</b></font>`n
					Else 
						CardSpecificWeakness=%CardSpecificWeakness%<i>%WeaknessType%:</i> <font color="red"><b>%WeaknessValue%</b></font>`n
				}
				
				;;;Insert any Res/Weak into the card text
				If (CardSpecificResistance!="") OR (CardSpecificWeakness!="")
				{
					CardText=%cardtext%<b>☯ <font color="blue">Resistance</font> & <font color="red">Weakness</font></b>`n%CardSpecificResistance%%CardSpecificWeakness%`n`n
					StringTrimRight,cardtext,cardtext,1
					;~ msgbox % CardName "`n" cardtext
					CardSpecificWeakness=
					CardSpecificResistance=
				}
				
				
				;;;Discover and format Retreat Costs
				If SpecificSetObj.cards[SetCodeIndex].RetreatCost.length()!=""
				{
					Loop % SpecificSetObj.cards[SetCodeIndex].RetreatCost.length()
					{
						If CardRetreatCost=
							CardRetreatCost := SpecificSetObj.cards[SetCodeIndex].RetreatCost[a_index]
						else
							CardRetreatCost := CardRetreatCost ", " SpecificSetObj.cards[SetCodeIndex].RetreatCost[a_index]
					}
					CardText = %CardText%<font color="brown"><b>↯ Retreat Cost:</b></font> {%CardRetreatCost%}
				}
				CardRetreatCost=
			}
			
			
			If SpecificSetObj.cards[SetCodeIndex].supertype="Trainer"
			{
				If (SpecificSetObj.cards[SetCodeIndex].hp!="") AND NOT (SpecificSetObj.cards[SetCodeIndex].hp="None")
				{
					CardHP := SpecificSetObj.cards[SetCodeIndex].hp
					CardText = <font color="tomato"><b>♥ HP: %CardHP%</b></font>`n`n
					CardPowerToughness := "0/" CardHP
				}
				else
					CardPowerToughness :=
				Loop % SpecificSetObj.cards[SetCodeIndex].text.length()
					CardText.=SpecificSetObj.cards[SetCodeIndex].text[a_index] "`n`n"
				;;;Discover and format Attacks
				Loop % SpecificSetObj.cards[SetCodeIndex].attacks.length()
				{
					AttackIndex := a_index
					Loop % SpecificSetObj.cards[SetCodeIndex].attacks[AttackIndex].cost.length()
					{
						AttackCost := SpecificSetObj.cards[SetCodeIndex].attacks[AttackIndex].cost[a_index]
						;~ MsgBox %  SpecificSetObj.cards[SetCodeIndex].attacks[a_index].cost[a_index]
						If a_index=1
							CardSpecificAttackCost=%AttackCost%
						Else 
							CardSpecificAttackCost=%CardSpecificAttackCost%, %attackcost%
					}
					CardSpecificAttackName := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].Name
					CardSpecificAttackText := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].Text
					CardSpecificAttackText := EndingWhiteSpaceTrim(CardSpecificAttackText)
					CardSpecificAttackdamage := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].damage
					CardSpecificAttackConvertedEnergyCost := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].ConvertedEnergyCost
					
					If a_index = 1
						CardText =%CardText%`n<b>Attacks</b>`n
					If CardSpecificAttackText=""
						CardText=%CardText%⚔ <i>%CardSpecificAttackName%</i> ⚔ »»» <b>%CardSpecificAttackdamage%</b>`n{%CardSpecificAttackCost%}`n%CardSpecificAttackText%`n`n
					else
						CardText=%CardText%⚔ <i>%CardSpecificAttackName%</i> ⚔ »»» <b>%CardSpecificAttackdamage%</b>`n{%CardSpecificAttackCost%}`n`n
					If CardSpecificAttackdamage=
					{
						AutoTrim,off
						StringReplace,CardText,CardText,⚔ »»» <b></b>,⚔,all
						AutoTrim,On
					}
					If SpecificSetObj.cards[SetCodeIndex].attacks.length() = a_index
					{
						;~ msgbox % SpecificSetObj.cards[SetCodeIndex].attacks.length() "`n" a_index
						CardText.="`n"
					}
					CardSpecificAttackCost=
				}
				CardTypes=
			}
			
			If SpecificSetObj.cards[SetCodeIndex].supertype="Energy"
			{
				;~ If (SpecificSetObj.cards[SetCodeIndex].hp!="") AND NOT (SpecificSetObj.cards[SetCodeIndex].hp="None")
				;~ {
					;~ CardHP := SpecificSetObj.cards[SetCodeIndex].hp
					;~ CardText = [HP] %CardHP%`n`n
					;~ CardPowerToughness := "0/" CardHP
				;~ }
				;~ else
				CardPowerToughness :=
				Loop % SpecificSetObj.cards[SetCodeIndex].text.length()
					CardText := CardText SpecificSetObj.cards[SetCodeIndex].text[a_index] "`n`n"
			}			
			CardSupertype := EndingWhiteSpaceTrim(SpecificSetObj.cards[SetCodeIndex].supertype)
			CardSubtype := EndingWhiteSpaceTrim(SpecificSetObj.cards[SetCodeIndex].subtype)
			
			
			
			
						;;;Format card text and use to build unique database
			Loop,3
				CardText=%cardtext%
			CardTextStripped=
			
			Loop,parse,cardtext
				if a_loopfield in a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,0,1,2,3,4,5,6,7,8,9
					CardTextStripped.=a_loopfield
			CardUniqueSingle := CardName " * " LC_SHA512(CardTextStripped)
			;~ msgbox % HashArray[CardUniqueSingle,"First Set"]
			FileCreateDir,%A_ScriptDir%\Images\Pokemon\%SetCode%\
			
			If CardUniqueList contains %CardUniqueSingle%
			{
				CardName := UnicodeToXML(CardName)
				FirstSet := HashArray[CardUniqueSingle,"First Set"]
				StringReplace,CardXML,CardXML,<name>%CardName% %FirstSet%</name>`n,<name>%CardName% %FirstSet%</name>`n<set picURL="%CardImage%">%SetCode%</set>`n
				
				;~ msgbox % setcode "`n" firstset
				;~ IfNotExist,%A_ScriptDir%\Images\Pokemon\%SetCode%\%CardName% %FirstSet% @%CardId%.png
				;~ {
					;~ FileMove,%A_ScriptDir%\Images\Pokemon\%FirstSet%\%CardName% %FirstSet%.png,%A_ScriptDir%\Images\Pokemon\%FirstSet%\%CardName% %FirstSet% @_Default.png
					;~ URLDownloadToFile,%CardImage%,%A_ScriptDir%\Images\Pokemon\%FirstSet%\%CardName% %FirstSet% @%CardID%.png
				;~ }
				continue
			}
			else
			{
				CardUniqueList .= CardUniqueSingle ","
				HashArray[CardUniqueSingle,"First Set"] := SetCode
			}
			;~ msgbox % CardUniqueList
			If SpecificSetObj.cards[SetCodeIndex].supertype="Pokémon"
			;~ {
				CardName := CardName " " SetCode
			If CardXML contains %CardName%
				Loop
				{
					if a_index=1
						continue
					CardNameTemp := SpecificSetObj.cards[SetCodeIndex].name " " SetCode "-" a_index
					If CardXML not contains %CardNameTemp%
					{	
						CardName=%CardNameTemp%
						CardNameTemp=
						break
					}
					
				}
			IfNotExist,%A_ScriptDir%\Images\Pokemon\%SetCode%\%CardName% @_Default.png
				IfNotExist,%A_ScriptDir%\Images\Pokemon\%SetCode%\%CardName%.png
				{
						;~ URLDownloadToFile,%CardImage%,%A_ScriptDir%\Images\Pokemon\%SetCode%\%CardName%.png
				}
			;~ }
			;;;Begin building the XML
			;~ msgbox % CardText
			CardText := UnicodeToXML(CardText)
			CardName := UnicodeToXML(CardName)
			CardXML.="`n" A_Tab A_Tab "<card>`n"
			CardXML.=A_Tab A_Tab A_Tab "<name>" CardName "</name>`n"
			CardXML.=A_Tab A_Tab A_Tab "<set picURL=""" CardImage """>" SetCode "</set>`n"
			CardXML.=A_Tab A_Tab A_Tab "<color>" CardTypes "</color>`n"	
			CardXML.=A_Tab A_Tab A_Tab "<manacost></manacost>`n"
			CardXML.=A_Tab A_Tab A_Tab "<cmc></cmc>`n"
			If SpecificSetObj.cards[SetCodeIndex].subtype=""
				CardXML.=A_Tab A_Tab A_Tab "<type>" CardSuperType "</type>`n"
			else
				CardXML.=A_Tab A_Tab A_Tab "<type>" CardSuperType " — "  CardSubtype "</type>`n"
			If CardPowerToughness contains `/
				CardXML.=A_Tab A_Tab A_Tab "<pt>" CardPowerToughness "</pt>`n"
			CardXML.=A_Tab A_Tab A_Tab "<tablerow>0</tablerow>`n"
			CardXML.=A_Tab A_Tab A_Tab "<text>" CardText "</text>`n"
			CardXML.=A_Tab A_Tab A_Tab "<font></font>`n"
			CardXML.=A_Tab A_Tab "</card>"
	;~ msgbox % cardxml
	;~ ExitApp
	;~ break
			CardTypes = 
		}	
		
		If SpecificsetTotalCards < 1000
			break
		;~ msgbox, test
		;~ ExitApp
		
	}
	;~ break
}
XML=
(
<?xml version="1.0" encoding="UTF-8"?>
<cockatrice_carddatabase version="3">
	<sets>%SetXML%
	</sets>
	<cards>%CardXML%
	</cards>
</cockatrice_carddatabase>
)
StringReplace,XML,XML,`r,,all
FileDelete,%a_scriptdir%\XML Creator - Pokemon.xml
FileAppend,%XML%,%a_scriptdir%\XML Creator - Pokemon.xml
FileCopy,%a_scriptdir%\XML Creator - Pokemon.xml,C:\Users\Qriist\Desktop\XML creator\cockatrice test\data\cards.xml,1
Loop,%A_ScriptDir%\Images\Pokemon\*,,1
	If !Instr(a_loopfilename,"@")
		FileDelete,%a_loopfilelongpath%





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ExitApp

ExitRoutine:
apiCache.CloseDB()



ExitApp
;uriDecode(str) {
    ;Loop
 ;If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
    ;StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
    ;Else Break
 ;Return, str
;}

;UriEncode(Uri, RE="[0-9A-Za-z]"){
    ;VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    ;While Code:=NumGet(Var,A_Index-1,"UChar")
    ;Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
    ;Return,Res  
;}

DownloadToString(url, encoding = "utf-8")
{
	static a := "AutoHotkey/" A_AhkVersion
	if (!DllCall("LoadLibrary", "str", "wininet") || !(h := DllCall("wininet\InternetOpen", "str", a, "uint", 1, "ptr", 0, "ptr", 0, "uint", 0, "ptr")))
		return 0
	c := s := 0, o := ""
	if (f := DllCall("wininet\InternetOpenUrl", "ptr", h, "str", url, "ptr", 0, "uint", 0, "uint", 0x80003000, "ptr", 0, "ptr"))
	{
		while (DllCall("wininet\InternetQueryDataAvailable", "ptr", f, "uint*", s, "uint", 0, "ptr", 0) && s > 0)
		{
			VarSetCapacity(b, s, 0)
			DllCall("wininet\InternetReadFile", "ptr", f, "ptr", &b, "uint", s, "uint*", r)
			o .= StrGet(&b, r >> (encoding = "utf-16" || encoding = "cp1200"), encoding)
		}
		DllCall("wininet\InternetCloseHandle", "ptr", f)
	}
	DllCall("wininet\InternetCloseHandle", "ptr", h)
	return o
}

m(x*){
	active:=WinActive("A")
	ControlGetFocus,Focus,A
	ControlGet,hwnd,hwnd,,%Focus%,ahk_id%active%
	static list:={btn:{oc:1,ari:2,ync:3,yn:4,rc:5,ctc:6},ico:{"x":16,"?":32,"!":48,"i":64}},msg:=[],msgbox
	list.title:="XML Class",list.def:=0,list.time:=0,value:=0,msgbox:=1,txt:=""
	for a,b in x
		obj:=StrSplit(b,":"),(vv:=List[obj.1,obj.2])?(value+=vv):(list[obj.1]!="")?(List[obj.1]:=obj.2):txt.=b "`n"
	msg:={option:value+262144+(list.def?(list.def-1)*256:0),title:list.title,time:list.time,txt:txt}
	Sleep,120
	MsgBox,% msg.option,% msg.title,% msg.txt,% msg.time
	msgbox:=0
	for a,b in {OK:value?"OK":"",Yes:"YES",No:"NO",Cancel:"CANCEL",Retry:"RETRY"}
		IfMsgBox,%a%
		{
			WinActivate,ahk_id%active%
			ControlFocus,%Focus%,ahk_id%active%
			return b
		}
}

UnicodeToXML(UnicodeString)
{
	AutoTrim, Off
	StringReplace,UnicodeString,UnicodeString,`n,<br>,all
	Loop,Parse,UnicodeString
	{
		
		NonsenseNumber := ord(A_LoopField)
		if (ord(A_LoopField) > 126) or (ord(a_loopfield) = 34) or (ord(a_loopfield) = 38) or (ord(a_loopfield) = 39) or (ord(a_loopfield) = 60) or (ord(a_loopfield) = 62)
			Nonsense=&#%NonsenseNumber%;
		else
			Nonsense=%a_loopfield%
		UnicodeStringNew.=nonsense
	} 
	AutoTrim, On
	return UnicodeStringNew
}



EndingWhiteSpaceTrim(StringToTrim)
{
	Loop,
	{
		If (SubStr(StringToTrim,0)=a_space) OR (SubStr(StringToTrim,0)=a_tab) OR (SubStr(StringToTrim,0)="`n") OR (SubStr(StringToTrim,0)="`r")
		{
			StringTrimRight,StringToTrim,StringToTrim,1
		}
		else
			break
	}
	return StringToTrim
}