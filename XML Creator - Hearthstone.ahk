#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk
cxml := CockatriceXMLCreator("Hearthstone")
api := apiQache()
api.initExpiry(82800)	;23 hours
api.requestInterval(100)	;keeps from hammering the server on non-cache requests


;navigating Blizzard's OAuth2 nonsense
client := IniRead(A_ScriptDir "\auth\auth.ini","auth","Hearthstone_Client")
secret := IniRead(A_ScriptDir "\auth\auth.ini","auth","Hearthstone_Secret")
url := "https://oauth.battle.net/token"
api.curl.SetOpt("URL",url)
api.curl.SetOpt("USERNAME",client)
api.curl.SetOpt("PASSWORD",secret)
api.curl.SetHeaders(Map("Content-Type","application/x-www-form-urlencoded"))
api.curl.SetPost("grant_type=client_credentials")
api.curl.Sync()

auth := JSON.load(api.curl.GetLastBody())
headers := Map("Authorization","Bearer " auth["access_token"])

; url := "https://d15f34w2p8l1cc.cloudfront.net/hearthstone/2e01a1623d42fb74581eeb12b5529a283f7dbbe33349e0e0e9caf922acc52da6.png"
; ; url := "https://www.google.com/images/branding/googlelogo/2x/googlelogo_light_color_272x92dp.png"
; img := api.retrieve(url,headers,,,,,,1)
; FileOpen(A_ScriptDir "\test.png","w").RawWrite(img)

; ExitApp
massCardObj := Map()
cxml.gtext("2","Collecting raw card data...")
loop {
	url := "https://us.api.blizzard.com/hearthstone/cards?"
		.	"collectible=0,1&"
		.	"page=" a_index
	; msgbox Type(api.retrieve(url,headers))
	try rawObj := JSON.load(api.retrieve(url,headers))
	catch 
		msgbox a_index
	cxml.gtext("3","Page " a_index "/" rawObj["pageCount"])
	for k,v in rawObj["cards"]
		massCardObj[v["id"]] := v
} until (rawObj["page"] = rawObj["pageCount"])

cxml.gtext("2","Collecting raw metadata...")
url := "https://us.api.blizzard.com/hearthstone/metadata"
rawMetaObj := JSON.load(api.retrieve(url,headers))

/*	ID types found in card data:
	cardSetId
	cardTypeId
	childIds
	classId
	copyOfCardId
	keywordIds
	minionTypeId
	multiClassIds
	multiTypeIds
	parentId
	rarityId
	touristClassId
*/
lng := "en_US"
idObj := Map()

idObj["gameModes"] := Map()
for k,v in rawMetaObj["types"] {
	idObj["gameModes"][v["id"]] := r := Map()
	r["id"] := v["id"]
	r["name"] := v["name"][lng]
	r["slug"] := v["slug"]
}

idObj["cardTypeId"] := Map()
for k,v in rawMetaObj["types"] {
	idObj["cardTypeId"][v["id"]] := r := Map()
	r["id"] := v["id"]
	r["name"] := v["name"][lng]
	r["slug"] := v["slug"]
}



;begin processing card data
for k,v in massCardObj {
	record := v
	switch record["cardTypeId"] {
		case 3:
		case 4:
		case 5:
		case 7:
		case 10:
		case 39:
		case 40:
		case 44:	;trinket
		default:
			; msgbox "unknown card type: " record["cardTypeId"] "`n" A_Clipboard := JSON.Dump(v)
		A_Clipboard := v["image"][lng]
		img := api.retrieve(v["image"][lng],headers,,,,,,1)
		; if (Type(img) = "String")
		; 	continue
		; msgbox img
		; msgbox img.size
		if (InStr(StrGet(img,"utf-8"),"Denied"))
			continue
		FileOpen(A_ScriptDir "\test.png","w").RawWrite(img)
		try msgbox StrGet(img,"utf-8")
		
		; api.curl.SetOpt("url",v["image"][lng],api.easy_handle)
		; api.curl.WriteToFile(A_ScriptDir "\test.png",api.easy_handle)
		; api.curl.Sync(api.easy_handle)
		
	}
	
}





ExitApp
/*

SetBatchLines -1
FileEncoding UTF-8
CardList := urldownloadtovar("https://omgvamp-hearthstone-v1.p.mashape.com/cards")
;~ FileAppend,%cardlist%,hearthstone.json
;~ FileRead,CardList,hearthstone.json
CardObj := JSON.Load(CardList)

CategoryNumber=0
For Category, CategoryList in CardObj
{ 
	NumberOfCards := CardObj[Category].length()
	;~ msgbox % CardObj[Category].length()
	;~ msgbox % st_printarr(cardsubobj)
	Loop, %NumberOfCards%
	{
			SuperType=
			SubType=
			CategoryIndexNumer := a_index
			CardName := CardObj[Category,a_index,"name"]
			CardArmor := CardObj[Category,a_index,"armor"]
			CardAttack := CardObj[Category,a_index,"attack"]
			;~ CardObj[Category,a_index,"cardId"]
			CardSet := CardObj[Category,a_index,"cardSet"]
			
			CardClasses=
			Loop % CardObj[Category,a_index,"classes"].length()
				CardClasses.=CardObj[Category,CategoryIndexNumer,"classes",a_index] " "			
			If CardClasses!=
				StringTrimRight,CardClasses,CardClasses,1
			
			CardCost := CardObj[Category,a_index,"cost"]
			CardElite := CardObj[Category,a_index,"elite"] ;Supertype
			CardType := CardObj[Category,a_index,"type"] ;SuperType
			CardFaction := CardObj[Category,a_index,"faction"] ;SuperType
			
			CardSuperType := CardType
			If CardFaction!=
				CardSuperType := CardFaction " " CardType
			If CardElite = true
				CardSuperType := "Elite " CardType
				
			
			
			CardText := CardObj[Category,a_index,"text"] 
			StringReplace,CardText,CardText,\n,,all
			If CardObj[Category,a_index,"flavor"]!=""
			{
				CardFlavor := CardObj[Category,a_index,"flavor"]
				StringReplace,CardFlavor,CardFlavor," -,"<br>&nbsp;&nbsp;&nbsp;&nbsp;-
				CardText.="<br><br><br><i>" CardFlavor "</i>"
			}
			
			CardHealth := CardObj[Category,a_index,"health"]
						CardDurability := CardObj[Category,a_index,"durability"]

			If CardType in Minion
			{
				CardPT := CardAttack "/" CardHealth
				;~ msgbox % cardattack
			}
			else If CardType in Hero
				CardPT := "0/" CardHealth
			else If CardType in Weapon
				CardPT := CardAttack "/" CardDurability
			else
				CardPT :=""
			CardImage := CardObj[Category,a_index,"imgGold"]
			;~ Loop % CardObj[Category,a_index,"mechanics"].length()
				;~ MsgBox % CardObj[Category,CategoryIndexNumer,"mechanics",a_index,"name"]
			CardMultiClassGroup := CardObj[Category,CategoryIndexNumer,"multiClassGroup"] ;SubType
			CardPlayerClass := CardObj[Category,a_index,"playerClass"]
			CardRace := CardObj[Category,a_index,"race"] ;SubType
			
			If CardClasses!=
				SubType.=CardClasses " "
			If CardMultiClassGroup!=
				SubType.=CardMultiClassGroup " "
			If CardRace !=
				SubType.=CardRace " "
			StringTrimRight,SubType,SubType,1
			
			CardText := UnicodeToXML(CardText)
			CardName := UnicodeToXML(CardName)
			CardSet := UnicodeToXML(CardSet)
			If SetXML not contains %CardSet%
			{
				SetXML.="`n" A_Tab A_Tab "<set>`n"
				SetXML.=A_Tab A_Tab A_Tab "<name>" CardSet "</name>`n"
				SetXML.=A_Tab A_Tab A_Tab "<longname>" CardSet "</longname>`n"
				SetXML.=A_Tab A_Tab A_Tab "<settype>" CardSet "</settype>`n"
				SetXML.=A_Tab A_Tab A_Tab "<releasedate>0001-01-01</releasedate>`n"
				SetXML.=A_Tab A_Tab "</set>"
			}
			
			CardXML.="`n" A_Tab A_Tab "<card>`n"
			CardXML.=A_Tab A_Tab A_Tab "<name>" CardName "</name>`n"
			CardXML.=A_Tab A_Tab A_Tab "<set picURL=""" CardImage """>" CardSet "</set>`n"
			CardXML.=A_Tab A_Tab A_Tab "<color>" CardPlayerClass "</color>`n"	
			CardXML.=A_Tab A_Tab A_Tab "<manacost>" CardCost "</manacost>`n"
			CardXML.=A_Tab A_Tab A_Tab "<cmc>" CardCost "</cmc>`n"
			If CardSubType!=
				CardXML.=A_Tab A_Tab A_Tab "<type>" CardSuperType " — "  CardSubType "</type>`n"
			else
				CardXML.=A_Tab A_Tab A_Tab "<type>" CardSuperType "</type>`n"
			If CardPT contains `/
				CardXML.=A_Tab A_Tab A_Tab "<pt>" CardPT "</pt>`n"
			If CardType in Minion,Hero
				CardXML.=A_Tab A_Tab A_Tab "<tablerow>2</tablerow>`n"
			Else if CardType in HeroPower,Weapon
				CardXML.=A_Tab A_Tab A_Tab "<tablerow>1</tablerow>`n"
			else
				CardXML.=A_Tab A_Tab A_Tab "<tablerow>0</tablerow>`n"
			CardXML.=A_Tab A_Tab A_Tab "<text>" CardText "</text>`n"
			CardXML.=A_Tab A_Tab "</card>"
	}
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
FileDelete,%a_scriptdir%\XML Creator - Hearthstone.xml
FileAppend,%XML%,%a_scriptdir%\XML Creator - Hearthstone.xml
FileCopy,%a_scriptdir%\XML Creator - Hearthstone.xml,C:\Users\Qriist\Desktop\XML creator\cockatrice test\data\cards.xml,1

ExitApp
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;~ #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
;~ msgbox % a_isunicode
Gui, XML: New, +MinSizex250
Gui, Add, Text,w300 BackgroundTrans center vText1,
Gui, Add, Text,w300 BackgroundTrans center vText2,Gathering set list...
Gui, Add, Text,w300 BackgroundTrans center vText3,
Gui, Show,autosize center,Pokemon XML Creator
CardTotal=0
Loop,
{
	SetListURL := DownloadToString("https://api.pokemontcg.io/v1/sets?pageSize=1000&page=" a_index)
	SetListObj := JSON.Load(SetListURL)
	
	if SetListObj.sets.length()=0
		break
	;~ MsgBox % SetListObj.sets.length()
	SetTotal := SetListObj.sets.length()
	Loop,%SetTotal%
	{
		;~ msgbox % SetListObj.sets[a_index].code
		SetCode := SetListObj.sets[a_index].code
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
		
	}
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
		SpecificSetObj := JSON.Load(SpecificSetURL)
		SpecificsetTotalCards := SpecificSetObj.cards.length()
		If SpecificsetTotalCards = 0
			break
		loop,%SpecificsetTotalCards%
		{
			
			CurrentCardCount+=1
			SetCodeIndex+=1
			CardText=
			CurrentCardPercent := CurrentCardCount / CardTotal
			CardName := SpecificSetObj.cards[SetCodeIndex].name
			SetName := SpecificSetObj.cards[SetCodeIndex].set
			SetCode := SpecificSetObj.cards[SetCodeIndex].setCode
			StringUpper,setcode,setcode
			GuiControl, , Text1,Scraping data for %SetName%...
			GuiControl, , Text2,%cardname%
			GuiControl, , Text3,%CurrentCardCount% / %CardTotal% (%CurrentCardPercent%)
			Gui, Show,autosize NA,Pokemon XML Creator
			If SpecificSetObj.cards[SetCodeIndex].imageUrlHiRes!=""
				CardImage := SpecificSetObj.cards[SetCodeIndex].imageUrlHiRes
			Else
				CardImage := SpecificSetObj.cards[SetCodeIndex].imageUrl
			
			
			If SpecificSetObj.cards[SetCodeIndex].supertype="Pokémon"
			{
				CardHP := SpecificSetObj.cards[SetCodeIndex].hp
				CardText := "♥  [HP] " CardHP "`n`n"
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
					CardText = %CardText%☣ [Evolves From] %CardEvolvesFrom%`n`n
				}
				else
					CardEvolvesFrom=
				
				;;;Discover and format Ancient Traits
				If SpecificSetObj.cards[SetCodeIndex].ancientTrait!=""
				{
					CardAncientTraitName := SpecificSetObj.cards[SetCodeIndex].ancientTrait.Name
					CardAncientTraitText := SpecificSetObj.cards[SetCodeIndex].ancientTrait.Text
					CardText = %CardText%∞ [Ancient Trait] » %CardAncientTraitName%`n%CardAncientTraitText%`n`n
				}
				else
					CardAncientTrait=
				
				;;;Discover and format Abilities
				If SpecificSetObj.cards[SetCodeIndex].ability.name!=""
				{
					CardAbilityName := SpecificSetObj.cards[SetCodeIndex].ability.name
					CardAbilityText := SpecificSetObj.cards[SetCodeIndex].ability.text
					CardAbilityType := SpecificSetObj.cards[SetCodeIndex].ability.type
					If CardAbilityType = Ability
						CardText = %CardText%∴ [Ability] » %CardAbilityName%`n%CardAbilityText%`n`n
					Else
						CardText = %CardText%∴ [Ability / %CardAbilityType%] » %CardAbilityName%`n%CardAbilityText%`n`n
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
					CardSpecificAttackText := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].Text
					CardSpecificAttackdamage := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].damage
					CardSpecificAttackConvertedEnergyCost := SpecificSetObj.cards[SetCodeIndex].attacks[a_index].ConvertedEnergyCost
					
					If a_index = 1
						CardText =%CardText%[Attacks]`n
					CardText=%CardText%⚔ %CardSpecificAttackName% ⚔ »»» %CardSpecificAttackdamage%`n{%CardSpecificAttackCost%}`n%CardSpecificAttackText%`n`n
					
					If CardSpecificAttackdamage=
						StringReplace,CardText,CardText,⚔ »»»,⚔,all
					If a_index = SpecificSetObj.cards[SetCodeIndex].attacks.length()
						CardText=%CardText%`n`n
					CardSpecificAttackCost=
					
				}
				
				
				;;;Discover and format Resistances
				Loop % SpecificSetObj.cards[SetCodeIndex].resistances.length()
				{
					ResistanceIndex := a_index
					ResistanceType := SpecificSetObj.cards[SetCodeIndex].resistances[ResistanceIndex].Type
					ResistanceValue := SpecificSetObj.cards[SetCodeIndex].resistances[ResistanceIndex].Value
					If a_index=1
						CardSpecificResistance=Resistant to %ResistanceType%: %ResistanceValue%`n
					Else 
						CardSpecificResistances=%CardSpecificResistance%Resistant to %ResistanceType%: %ResistanceValue%`n
				}
				
				
				;;;Discover and format Weaknesses
				Loop % SpecificSetObj.cards[SetCodeIndex].weaknesses.length()
				{
					WeaknessIndex := a_index
					WeaknessType := SpecificSetObj.cards[SetCodeIndex].Weaknesses[WeaknessIndex].Type
					WeaknessValue := SpecificSetObj.cards[SetCodeIndex].Weaknesses[WeaknessIndex].Value
					If a_index=1
						CardSpecificWeakness=Weak to %WeaknessType%: %WeaknessValue%`n
					Else 
						CardSpecificWeakness=%CardSpecificWeakness%Weak to %WeaknessType%: %WeaknessValue%`n
				}
				
				;;;Insert any Res/Weak into the card text
				If (CardSpecificResistance!="") OR (CardSpecificWeakness!="")
				{
					CardText=%cardtext%☯ [Resistance & Weakness]`n%CardSpecificResistance%%CardSpecificWeakness%
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
					CardText = %CardText%`n`n↯ [Retreat Cost] {%CardRetreatCost%}
				}
				CardRetreatCost=
			}
			
			
			If SpecificSetObj.cards[SetCodeIndex].supertype="Trainer"
			{
				If (SpecificSetObj.cards[SetCodeIndex].hp!="") AND NOT (SpecificSetObj.cards[SetCodeIndex].hp="None")
				{
					CardHP := SpecificSetObj.cards[SetCodeIndex].hp
					CardText = ♥ [HP] %CardHP%`n`n
					CardPowerToughness := "0/" CardHP
				}
				else
					CardPowerToughness :=
				Loop % SpecificSetObj.cards[SetCodeIndex].text.length()
					CardText := CardText SpecificSetObj.cards[SetCodeIndex].text[a_index] "`n`n"
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
					CardText := CardText SpecificSetObj.cards[SetCodeIndex].text
			}			
			CardSupertype := SpecificSetObj.cards[SetCodeIndex].supertype
			CardSubtype := SpecificSetObj.cards[SetCodeIndex].subtype
			If CardSubtype=""
				CardOverAllTypes := CardSuperType " — " CardSubType
			else
				CardOverAllTypes := CardSuperType
			
			;;;Format card text and use to build unique database
			Loop,3
				CardText=%cardtext%
			CardTextStripped=
			Loop,parse,cardtext
				if a_loopfield in a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,0,1,2,3,4,5,6,7,8,9
					CardTextStripped.=a_loopfield
			CardUniqueSingle := CardName " * " LC_SHA512(CardTextStripped)
			If CardUniqueList contains %CardUniqueSingle%
				continue
			else
				CardUniqueList .= CardUniqueSingle ","
			;~ msgbox % carduniquelist
			If SpecificSetObj.cards[SetCodeIndex].supertype="Pokémon"
			{
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
						
				;~ CardID := SpecificSetObj.cards[SetCodeIndex].setcode
				;~ StringUpper,CardID,CardID
				;~ CardName := CardName " (" SetCode ")"
			}
			;;;Begin building the XML
			;~ msgbox % CardText
			;~ CardXML=
	;~ (
;~ %CardXML%`n		<card>
			;~ <name>%CardName%</name>
			;~ <set picURL="%CardImage%">%SetCode%</set>
			;~ <color>%CardTypes%</color>
			;~ <manacost>%CardTypes%</manacost>
			;~ <cmc></cmc>
			;~ <type>%CardSubtype%</type>%CardPowerToughness%
			;~ <tablerow>0</tablerow>
			;~ <text>%CardFullText%</text>
		;~ </card>
		
	;~ )
	

	;~ msgbox % cardxml
	;~ ExitApp
			CardTypes = 
		}	
		
		If SpecificsetTotalCards < 1000
			break
		;~ msgbox, test
		;~ ExitApp
		
	}
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
FileDelete,%a_scriptdir%\XML Creator - Pokemon.xml
FileAppend,%XML%,%a_scriptdir%\XML Creator - Pokemon.xml
FileCopy,%a_scriptdir%\XML Creator - Pokemon.xml,C:\Users\Qriist\Desktop\XML creator\cockatrice test\data\cards.xml,1






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ExitApp


/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
/*
class JSON
{
    /**
     * Method: Load
     *     Parses a JSON string into an AHK value
     * Syntax:
     *     value := JSON.Load( text [, reviver ] )
     * Parameter(s):
     *     value      [retval] - parsed value
     *     text    [in, ByRef] - JSON formatted string
     *     reviver   [in, opt] - function object, similar to JavaScript's
     *                           JSON.parse() 'reviver' parameter
     */
    /*
	class Load extends JSON.Functor
    {
        Call(self, ByRef text, reviver:="")
        {
            this.rev := IsObject(reviver) ? reviver : false
        ; Object keys(and array indices) are temporarily stored in arrays so that
        ; we can enumerate them in the order they appear in the document/text instead
        ; of alphabetically. Skip if no reviver function is specified.
            this.keys := this.rev ? {} : false

            static quot := Chr(34), bashq := "\" . quot
                 , json_value := quot . "{[01234567890-tfn"
                 , json_value_or_array_closing := quot . "{[]01234567890-tfn"
                 , object_key_or_object_closing := quot . "}"

            key := ""
            is_key := false
            root := {}
            stack := [root]
            next := json_value
            pos := 0

            while ((ch := SubStr(text, ++pos, 1)) != "") {
                if InStr(" `t`r`n", ch)
                    continue
                if !InStr(next, ch, 1)
                    this.ParseError(next, text, pos)

                holder := stack[1]
                is_array := holder.IsArray

                if InStr(",:", ch) {
                    next := (is_key := !is_array && ch == ",") ? quot : json_value

                } else if InStr("}]", ch) {
                    ObjRemoveAt(stack, 1)
                    next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

                } else {
                    if InStr("{[", ch) {
                    ; Check if Array() is overridden and if its return value has
                    ; the 'IsArray' property. If so, Array() will be called normally,
                    ; otherwise, use a custom base object for arrays
                        static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
                    
                    ; sacrifice readability for minor(actually negligible) performance gain
                        (ch == "{")
                            ? ( is_key := true
                              , value := {}
                              , next := object_key_or_object_closing )
                        ; ch == "["
                            : ( value := json_array ? new json_array : []
                              , next := json_value_or_array_closing )
                        
                        ObjInsertAt(stack, 1, value)

                        if (this.keys)
                            this.keys[value] := []
                    
                    } else {
                        if (ch == quot) {
                            i := pos
                            while (i := InStr(text, quot,, i+1)) {
                                value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

                                static tail := A_AhkVersion<"2" ? 0 : -1
                                if (SubStr(value, tail) != "\")
                                    break
                            }

                            if (!i)
                                this.ParseError("'", text, pos)

                              value := StrReplace(value,  "\/",  "/")
                            , value := StrReplace(value, bashq, quot)
                            , value := StrReplace(value,  "\b", "`b")
                            , value := StrReplace(value,  "\f", "`f")
                            , value := StrReplace(value,  "\n", "`n")
                            , value := StrReplace(value,  "\r", "`r")
                            , value := StrReplace(value,  "\t", "`t")

                            pos := i ; update pos
                            
                            i := 0
                            while (i := InStr(value, "\",, i+1)) {
                                if !(SubStr(value, i+1, 1) == "u")
                                    this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

                                uffff := Abs("0x" . SubStr(value, i+2, 4))
                                if (A_IsUnicode || uffff < 0x100)
                                    value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
                            }

                            if (is_key) {
                                key := value, next := ":"
                                continue
                            }
                        
                        } else {
                            value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

                            static number := "number", integer :="integer"
                            if value is %number%
                            {
                                if value is %integer%
                                    value += 0
                            }
                            else if (value == "true" || value == "false")
                                value := %value% + 0
                            else if (value == "null")
                                value := ""
                            else
                            ; we can do more here to pinpoint the actual culprit
                            ; but that's just too much extra work.
                                this.ParseError(next, text, pos, i)

                            pos += i-1
                        }

                        next := holder==root ? "" : is_array ? ",]" : ",}"
                    } ; If InStr("{[", ch) { ... } else

                    is_array? key := ObjPush(holder, value) : holder[key] := value

                    if (this.keys && this.keys.HasKey(holder))
                        this.keys[holder].Push(key)
                }
            
            } ; while ( ... )

            return this.rev ? this.Walk(root, "") : root[""]
        }

        ParseError(expect, ByRef text, pos, len:=1)
        {
            static quot := Chr(34), qurly := quot . "}"
            
            line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
            col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
            msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
            ,     (expect == "")     ? "Extra data"
                : (expect == "'")    ? "Unterminated string starting at"
                : (expect == "\")    ? "Invalid \escape"
                : (expect == ":")    ? "Expecting ':' delimiter"
                : (expect == quot)   ? "Expecting object key enclosed in double quotes"
                : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
                : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
                : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
                : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
                :                      "Expecting JSON value(string, number, true, false, null, object or array)"
            , line, col, pos)

            static offset := A_AhkVersion<"2" ? -3 : -4
            throw Exception(msg, offset, SubStr(text, pos, len))
        }

        Walk(holder, key)
        {
            value := holder[key]
            if IsObject(value) {
                for i, k in this.keys[value] {
                    ; check if ObjHasKey(value, k) ??
                    v := this.Walk(value, k)
                    if (v != JSON.Undefined)
                        value[k] := v
                    else
                        ObjDelete(value, k)
                }
            }
            
            return this.rev.Call(holder, key, value)
        }
    }

    /**
     * Method: Dump
     *     Converts an AHK value into a JSON string
     * Syntax:
     *     str := JSON.Dump( value [, replacer, space ] )
     * Parameter(s):
     *     str        [retval] - JSON representation of an AHK value
     *     value          [in] - any value(object, string, number)
     *     replacer  [in, opt] - function object, similar to JavaScript's
     *                           JSON.stringify() 'replacer' parameter
     *     space     [in, opt] - similar to JavaScript's JSON.stringify()
     *                           'space' parameter
     */
    /*
	class Dump extends JSON.Functor
    {
        Call(self, value, replacer:="", space:="")
        {
            this.rep := IsObject(replacer) ? replacer : ""

            this.gap := ""
            if (space) {
                static integer := "integer"
                if space is %integer%
                    Loop, % ((n := Abs(space))>10 ? 10 : n)
                        this.gap .= " "
                else
                    this.gap := SubStr(space, 1, 10)

                this.indent := "`n"
            }

            return this.Str({"": value}, "")
        }

        Str(holder, key)
        {
            value := holder[key]

            if (this.rep)
                value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

            if IsObject(value) {
            ; Check object type, skip serialization for other object types such as
            ; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
                static type := A_AhkVersion<"2" ? "" : Func("Type")
                if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
                    if (this.gap) {
                        stepback := this.indent
                        this.indent .= this.gap
                    }

                    is_array := value.IsArray
                ; Array() is not overridden, rollback to old method of
                ; identifying array-like objects. Due to the use of a for-loop
                ; sparse arrays such as '[1,,3]' are detected as objects({}). 
                    if (!is_array) {
                        for i in value
                            is_array := i == A_Index
                        until !is_array
                    }

                    str := ""
                    if (is_array) {
                        Loop, % value.Length() {
                            if (this.gap)
                                str .= this.indent
                            
                            v := this.Str(value, A_Index)
                            str .= (v != "") ? v . "," : "null,"
                        }
                    } else {
                        colon := this.gap ? ": " : ":"
                        for k in value {
                            v := this.Str(value, k)
                            if (v != "") {
                                if (this.gap)
                                    str .= this.indent

                                str .= this.Quote(k) . colon . v . ","
                            }
                        }
                    }

                    if (str != "") {
                        str := RTrim(str, ",")
                        if (this.gap)
                            str .= stepback
                    }

                    if (this.gap)
                        this.indent := stepback

                    return is_array ? "[" . str . "]" : "{" . str . "}"
                }
            
            } else ; is_number ? value : "value"
                return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
        }

        Quote(string)
        {
            static quot := Chr(34), bashq := "\" . quot

            if (string != "") {
                  string := StrReplace(string,  "\",  "\\")
                ; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
                , string := StrReplace(string, quot, bashq)
                , string := StrReplace(string, "`b",  "\b")
                , string := StrReplace(string, "`f",  "\f")
                , string := StrReplace(string, "`n",  "\n")
                , string := StrReplace(string, "`r",  "\r")
                , string := StrReplace(string, "`t",  "\t")

                static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
                while RegExMatch(string, rx_escapable, m)
                    string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
            }

            return quot . string . quot
        }
    }

    /**
     * Property: Undefined
     *     Proxy for 'undefined' type
     * Syntax:
     *     undefined := JSON.Undefined
     * Remarks:
     *     For use with reviver and replacer functions since AutoHotkey does not
     *     have an 'undefined' type. Returning blank("") or 0 won't work since these
     *     can't be distnguished from actual JSON values. This leaves us with objects.
     *     Replacer() - the caller may return a non-serializable AHK objects such as
     *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
     *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
     *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
     *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
     */
 /*   Undefined[]
    {
        get {
            static empty := {}, vt_empty := ComObject(0, &empty, 1)
            return vt_empty
        }
    }

    class Functor
    {
        __Call(method, ByRef arg, args*)
        {
        ; When casting to Call(), use a new instance of the "function object"
        ; so as to avoid directly storing the properties(used across sub-methods)
        ; into the "function object" itself.
            if IsObject(method)
                return (new this).Call(method, arg, args*)
            else if (method == "")
                return (new this).Call(arg, args*)
        }
    }
}
uriDecode(str) {
    Loop
 If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
    StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
    Else Break
 Return, str
}
 
UriEncode(Uri, RE="[0-9A-Za-z]"){
    VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    While Code:=NumGet(Var,A_Index-1,"UChar")
    Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
    Return,Res  
}

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

Class XML{
	keep:=[]
	__Get(x=""){
		return this.XML.xml
	}__New(param*){
		;temp.preserveWhiteSpace:=1
		root:=param.1,file:=param.2,file:=file?file:root ".xml",temp:=ComObjCreate("MSXML2.DOMDocument"),temp.SetProperty("SelectionLanguage","XPath"),this.xml:=temp,this.file:=file,XML.keep[root]:=this
		if(FileExist(file)){
			FileRead,info,%file%
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else
				temp.LoadXML(info),this.xml:=temp
		}else
			this.xml:=this.CreateElement(temp,root)
	}Add(XPath,att:="",text:="",dup:=0){
		p:="/",add:=(next:=this.SSN("//" XPath))?1:0,last:=SubStr(XPath,InStr(XPath,"/",0,0)+1)
		if(!next.xml){
			next:=this.SSN("//*")
			for a,b in StrSplit(XPath,"/")
				p.="/" b,next:=(x:=this.SSN(p))?x:next.AppendChild(this.XML.CreateElement(b))
		}if(dup&&add)
			next:=next.ParentNode.AppendChild(this.XML.CreateElement(last))
		for a,b in att
			next.SetAttribute(a,b)
		if(text!="")
			next.text:=text
		return next
	}CreateElement(doc,root){
		return doc.AppendChild(this.XML.CreateElement(root)).ParentNode
	}EA(XPath,att:=""){
		list:=[]
		if(att)
			return XPath.NodeName?SSN(XPath,"@" att).text:this.SSN(XPath "/@" att).text
		nodes:=XPath.NodeName?XPath.SelectNodes("@*"):nodes:=this.SN(XPath "/@*")
		while(nn:=nodes.item[A_Index-1])
			list[nn.NodeName]:=nn.text
		return list
	}Find(info*){
		static last:=[]
		doc:=info.1.NodeName?info.1:this.xml
		if(info.1.NodeName)
			node:=info.2,find:=info.3,return:=info.4!=""?"SelectNodes":"SelectSingleNode",search:=info.4
		else
			node:=info.1,find:=info.2,return:=info.3!=""?"SelectNodes":"SelectSingleNode",search:=info.3
		if(InStr(info.2,"descendant"))
			last.1:=info.1,last.2:=info.2,last.3:=info.3,last.4:=info.4
		if(InStr(find,"'"))
			return doc[return](node "[.=concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "')]/.." (search?"/" search:""))
		else
			return doc[return](node "[.='" find "']/.." (search?"/" search:""))
	}Get(XPath,Default){
		text:=this.SSN(XPath).text
		return text?text:Default
	}Language(Language:="XSLPattern"){
		this.XML.SetProperty("SelectionLanguage",Language)
	}ReCreate(XPath,new){
		rem:=this.SSN(XPath),rem.ParentNode.RemoveChild(rem),new:=this.Add(new)
		return new
	}Save(x*){
		if(x.1=1)
			this.Transform()
		if(this.XML.SelectSingleNode("*").xml="")
			return m("Errors happened while trying to save " this.file ". Reverting to old version of the XML")
		filename:=this.file?this.file:x.1.1,ff:=FileOpen(filename,0),text:=ff.Read(ff.length),ff.Close()
		if(!this[])
			return m("Error saving the " this.file " XML.  Please get in touch with maestrith if this happens often")
		if(text!=this[])
			file:=FileOpen(filename,"rw"),file.Seek(0),file.Write(this[]),file.Length(file.Position)
	}SSN(XPath){
		return this.XML.SelectSingleNode(XPath)
	}SN(XPath){
		return this.XML.SelectNodes(XPath)
	}Transform(){
		static
		if(!IsObject(xsl))
			xsl:=ComObjCreate("MSXML2.DOMDocument"),xsl.loadXML("<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform""><xsl:output method=""xml"" indent=""yes"" encoding=""UTF-8""/><xsl:template match=""@*|node()""><xsl:copy>`n<xsl:apply-templates select=""@*|node()""/><xsl:for-each select=""@*""><xsl:text></xsl:text></xsl:for-each></xsl:copy>`n</xsl:template>`n</xsl:stylesheet>"),style:=null
		this.XML.TransformNodeToObject(xsl,this.xml)
	}Under(under,node,att:="",text:="",list:=""){
		new:=under.AppendChild(this.XML.CreateElement(node)),new.text:=text
		for a,b in att
			new.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			new.SetAttribute(b,att[b])
		return new
	}
}SSN(node,XPath){
	return node.SelectSingleNode(XPath)
}SN(node,XPath){
	return node.SelectNodes(XPath)
}m(x*){
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

		if (ord(A_LoopField) > 126 || ord(A_LoopField) = 34 || ord(A_LoopField) = 38 || ord(A_LoopField) = 39 || ord(A_LoopField) = 60 || ord(A_LoopField) = 62)
			UnicodeStringNew.="&#" ord(A_LoopField) ";"
		else
			UnicodeStringNew.=a_loopfield
	} 
	AutoTrim, On
	return UnicodeStringNew
}

st_printArr(array, depth=5, indentLevel="")
{
   for k,v in Array
   {
      list.= indentLevel "[" k "]"
      if (IsObject(v) && depth>1)
         list.="`n" st_printArr(v, depth-1, indentLevel . "    ")
      Else
         list.=" => " v
      list.="`n"
   }
   return rtrim(list)
}


LC_Version := "0.0.21.01"

LC_ASCII2Bin(s,pretty:=0) {
	r:=""
	Loop, % l:=StrLen(s)
	{
		z:=Asc(SubStr(s,A_Index,1)),y:="",p:=1
		Loop, 8
			b:=!!(z&p),y:=b y,p:=p<<1
		r.=y
		if (pretty && (A_Index<l))
			r.=" "
	}
	return r
}

LC_Ascii2Bin2(Ascii) {
	for each, Char in StrSplit(Ascii)
	Loop, 8
		Out .= !!(Asc(Char) & 1 << 8-A_Index)
	return Out
}
 
LC_Bin2Ascii(Bin) {
	Bin := RegExReplace(Bin, "[^10]")
	Loop, % StrLen(Bin) / 8
	{
		for each, Bit in StrSplit(SubStr(Bin, A_Index*8-7, 8))
			Asc += Asc + Bit
		Out .= Chr(Asc), Asc := 0
	}
	return Out
}

LC_BinStr_EncodeText(Text, Pretty=False, Encoding="UTF-8") {
	VarSetCapacity(Bin, StrPut(Text, Encoding))
	LC_BinStr_Encode(BinStr, Bin, StrPut(Text, &Bin, Encoding)-1, Pretty)
	return BinStr
}

LC_BinStr_DecodeText(Text, Encoding="UTF-8") {
	Len := LC_BinStr_Decode(Bin, Text)
	return StrGet(&Bin, Len, Encoding)
}

LC_BinStr_Encode(ByRef Out, ByRef In, InLen, Pretty=False) {
	Loop, % InLen
	{
		Byte := NumGet(In, A_Index-1, "UChar")
		Loop, 8
			Out .= Byte>>(8-A_Index) & 1
		if Pretty ; Perhaps a regex at the end instead of a check in every loop would be better
			Out .= " "
	}
	; Out := RegExReplace(Out, "(\d{8})", "$1 ") ; For example, this
}

LC_BinStr_Decode(ByRef Out, ByRef In) {
	ByteCount := StrLen(In)/8
	VarSetCapacity(Out, ByteCount, 0)
	BitIndex := 1
	Loop, % ByteCount
	{
		Byte := 0
		Loop, 8
			Byte := Byte<<1 | SubStr(In, BitIndex++, 1)
		NumPut(Byte, Out, A_Index-1, "UChar")
	}
}


LC_Base64_EncodeText(Text,Encoding="UTF-8")
{
	VarSetCapacity(Bin, StrPut(Text, Encoding))
	LC_Base64_Encode(Base64, Bin, StrPut(Text, &Bin, Encoding)-1)
	return Base64
}

LC_Base64_DecodeText(Text,Encoding="UTF-8")
{
	Len := LC_Base64_Decode(Bin, Text)
	return StrGet(&Bin, Len, Encoding)
}

LC_Base64_Encode(ByRef Out, ByRef In, InLen)
{
	return LC_Bin2Str(Out, In, InLen, 0x40000001)
}

LC_Base64_Decode(ByRef Out, ByRef In)
{
	return LC_Str2Bin(Out, In, 0x1)
}


LC_Bin2Hex(ByRef Out, ByRef In, InLen, Pretty=False)
{
	return LC_Bin2Str(Out, In, InLen, Pretty ? 0xb : 0x4000000c)
}

LC_Hex2Bin(ByRef Out, ByRef In)
{
	return LC_Str2Bin(Out, In, 0x8)
}

LC_Bin2Str(ByRef Out, ByRef In, InLen, Flags)
{
	DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &In
	, "UInt", InLen, "UInt", Flags, "Ptr", 0, "UInt*", OutLen)
	VarSetCapacity(Out, OutLen * (1+A_IsUnicode))
	DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &In
	, "UInt", InLen, "UInt", Flags, "Str", Out, "UInt*", OutLen)
	return OutLen
}

LC_Str2Bin(ByRef Out, ByRef In, Flags)
{
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &In, "UInt", StrLen(In)
	, "UInt", Flags, "Ptr", 0, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(Out, OutLen)
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &In, "UInt", StrLen(In)
	, "UInt", Flags, "Str", Out, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	return OutLen
}

; 
; Version: 2014.03.06-1518, jNizM
; see https://en.wikipedia.org/wiki/Caesar_cipher
; ===================================================================================

LC_Caesar(string, num := 2) {
    ret := c := ""
    loop, parse, string
    {
        c := Asc(A_LoopField)
        if (c > 64) && (c < 91)
            ret .= Chr(Mod(c - 65 + num, 26) + 65)
        else if (c > 96) && (c < 123)
            ret .= Chr(Mod(c - 97 + num, 26) + 97)
        else
            ret .= A_LoopField
    }
    return ret
}

LC_CalcAddrHash(addr, length, algid, byref hash = 0, byref hashlength = 0) {
	static h := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "a", "b", "c", "d", "e", "f"]
	static b := h.minIndex()
	hProv := hHash := o := ""
	if (DllCall("advapi32\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "UInt", 24, "UInt", 0xf0000000))
	{
		if (DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", algid, "UInt", 0, "UInt", 0, "Ptr*", hHash))
		{
			if (DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", addr, "UInt", length, "UInt", 0))
			{
				if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", 0, "UInt*", hashlength, "UInt", 0))
				{
					VarSetCapacity(hash, hashlength, 0)
					if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", &hash, "UInt*", hashlength, "UInt", 0))
					{
						loop % hashlength
						{
							v := NumGet(hash, A_Index - 1, "UChar")
							o .= h[(v >> 4) + b] h[(v & 0xf) + b]
						}
					}
				}
			}
			DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
		}
		DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
	}
	return o
}
LC_CalcStringHash(string, algid, encoding = "UTF-8", byref hash = 0, byref hashlength = 0) {
	chrlength := (encoding = "CP1200" || encoding = "UTF-16") ? 2 : 1
	length := (StrPut(string, encoding) - 1) * chrlength
	VarSetCapacity(data, length, 0)
	StrPut(string, &data, floor(length / chrlength), encoding)
	return LC_CalcAddrHash(&data, length, algid, hash, hashlength)
}
LC_CalcHexHash(hexstring, algid) {
	length := StrLen(hexstring) // 2
	VarSetCapacity(data, length, 0)
	loop % length
	{
		NumPut("0x" SubStr(hexstring, 2 * A_Index - 1, 2), data, A_Index - 1, "Char")
	}
	return LC_CalcAddrHash(&data, length, algid)
}
LC_CalcFileHash(filename, algid, continue = 0, byref hash = 0, byref hashlength = 0) {
	fpos := ""
	if (!(f := FileOpen(filename, "r")))
	{
		return
	}
	f.pos := 0
	if (!continue && f.length > 0x7fffffff)
	{
		return
	}
	if (!continue)
	{
		VarSetCapacity(data, f.length, 0)
		f.rawRead(&data, f.length)
		f.pos := oldpos
		return LC_CalcAddrHash(&data, f.length, algid, hash, hashlength)
	}
	hashlength := 0
	while (f.pos < f.length)
	{
		readlength := (f.length - fpos > continue) ? continue : f.length - f.pos
		VarSetCapacity(data, hashlength + readlength, 0)
		DllCall("RtlMoveMemory", "Ptr", &data, "Ptr", &hash, "Ptr", hashlength)
		f.rawRead(&data + hashlength, readlength)
		h := LC_CalcAddrHash(&data, hashlength + readlength, algid, hash, hashlength)
	}
	return h
}

LC_CRC32(string, encoding = "UTF-8") {
	chrlength := (encoding = "CP1200" || encoding = "UTF-16") ? 2 : 1
	length := (StrPut(string, encoding) - 1) * chrlength
	VarSetCapacity(data, length, 0)
	StrPut(string, &data, floor(length / chrlength), encoding)
	hMod := DllCall("Kernel32.dll\LoadLibrary", "Str", "Ntdll.dll")
	SetFormat, Integer, % SubStr((A_FI := A_FormatInteger) "H", 0)
	CRC32 := DllCall("Ntdll.dll\RtlComputeCrc32", "UInt", 0, "UInt", &data, "UInt", length, "UInt")
	CRC := SubStr(CRC32 | 0x1000000000, -7)
	DllCall("User32.dll\CharLower", "Str", CRC)
	SetFormat, Integer, %A_FI%
	return CRC, DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)
}
LC_HexCRC32(hexstring) {
	length := StrLen(hexstring) // 2
	VarSetCapacity(data, length, 0)
	loop % length
	{
		NumPut("0x" SubStr(hexstring, 2 * A_Index -1, 2), data, A_Index - 1, "Char")
	}
	hMod := DllCall("Kernel32.dll\LoadLibrary", "Str", "Ntdll.dll")
	SetFormat, Integer, % SubStr((A_FI := A_FormatInteger) "H", 0)
	CRC32 := DllCall("Ntdll.dll\RtlComputeCrc32", "UInt", 0, "UInt", &data, "UInt", length, "UInt")
	CRC := SubStr(CRC32 | 0x1000000000, -7)
	DllCall("User32.dll\CharLower", "Str", CRC)
	SetFormat, Integer, %A_FI%
	return CRC, DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)
}
LC_FileCRC32(sFile := "", cSz := 4) {
	Bytes := ""
	cSz := (cSz < 0 || cSz > 8) ? 2**22 : 2**(18 + cSz)
	VarSetCapacity(Buffer, cSz, 0)
	hFil := DllCall("Kernel32.dll\CreateFile", "Str", sFile, "UInt", 0x80000000, "UInt", 3, "Int", 0, "UInt", 3, "UInt", 0, "Int", 0, "UInt")
	if (hFil < 1)
	{
		return hFil
	}
	hMod := DllCall("Kernel32.dll\LoadLibrary", "Str", "Ntdll.dll")
	CRC32 := 0
	DllCall("Kernel32.dll\GetFileSizeEx", "UInt", hFil, "Int64", &Buffer), fSz := NumGet(Buffer, 0, "Int64")
	loop % (fSz // cSz + !!Mod(fSz, cSz))
	{
		DllCall("Kernel32.dll\ReadFile", "UInt", hFil, "Ptr", &Buffer, "UInt", cSz, "UInt*", Bytes, "UInt", 0)
		CRC32 := DllCall("Ntdll.dll\RtlComputeCrc32", "UInt", CRC32, "UInt", &Buffer, "UInt", Bytes, "UInt")
	}
	DllCall("Kernel32.dll\CloseHandle", "Ptr", hFil)
	SetFormat, Integer, % SubStr((A_FI := A_FormatInteger) "H", 0)
	CRC32 := SubStr(CRC32 + 0x1000000000, -7)
	DllCall("User32.dll\CharLower", "Str", CRC32)
	SetFormat, Integer, %A_FI%
	return CRC32, DllCall("Kernel32.dll\FreeLibrary", "Ptr", hMod)
}

;from joedf : fork-fusion of jNizM+Laszlo's functions [to_decimal()+ToBase()]
LC_To_Dec(b, n) { ; 1 < b <= 36, n >= 0
	d:=0
	StringUpper,n,n
	loop % StrLen(n)
	{
		d *= b, k:=SubStr(n,A_Index,1)
		if k is not Integer
			k:=Asc(k)-55
		d += k
	}
	return d
}
;from Laszlo : http://www.autohotkey.com/board/topic/15951-base-10-to-base-36-conversion/#entry103624
LC_From_Dec(b,n) { ; 1 < b <= 36, n >= 0
	Loop {
		d := mod(n,b), n //= b
		m := (d < 10 ? d : Chr(d+55)) . m
		IfLess n,1, Break
	}
	Return m
}
LC_Dec2Hex(x) {
	return LC_From_Dec(16,x)
}
LC_Hex2Dec(x) {
	return LC_To_Dec(16,x)
}
LC_Numvert(num,from,to) { ; from joedf : http://ahkscript.org/boards/viewtopic.php?f=6&t=6363
    return LC_From_Dec(to,LC_To_Dec(from,num))
}

;
; Date Updated:
;	Friday, November 23rd, 2012 - Tuesday, February 10th, 2015
;
; Script Function:
;	Function Library to Encrypt / Decrypt in Div2 (by Joe DF)
;	Div2 was invented with a friend for fun, back in ~2010.
;	The string is "divided" in 2 during encryption. It is a 
;	simple reordering of the characters in a string. The was
; 	to have a human-readable/decryptable message.
;
; Notes:
;	AutoTrim should turned off, for the encryption to work properly
;	because, in Div2, <spaces> and <New lines> count as a character.
;

LC_Div2_encode(input, WithAutoTrim:=1, numproc:=1) {
	if (WithAutoTrim)
		StringReplace,input,input,%A_Space%,_,A
	loop, %numproc%
	{
		final:="", inputlen := StrLen(input)
		divmax := ceil((0.5 * inputlen) + 1)
		loop, %inputlen%
		{
			temp := SubStr(input,A_Index,1)
			q := inputlen + 1 - A_Index
			temp2 := SubStr(input,q,1)
			if (A_Index < divmax) {
				final .= temp
				if (A_Index != q)
					final .= temp2
			}
			if (A_Index >= divmax)
				Break
		}
		input := final
	}
	return final
}

LC_Div2_decode(input, WithAutoTrim:=1, numproc:=1) {
	if (WithAutoTrim)
		StringReplace,input,input,%A_Space%,_,A
	loop, %numproc%
	{
		i := 1, final:="", inputlen := StrLen(input)
		loop, % loopc := ceil(inputlen * (1/2))
		{	
			if (i <= inputlen)
				final .= SubStr(input,i,1)
			i += 2
		}
		i := inputlen
		loop, %loopc%
		{		
			if (i <= inputlen) {
				if (mod(SubStr(i,0,1)+0,2)==1) {
					if (i != 1)
						final .= SubStr(input,i-1,1)
				} else {
					final .= SubStr(input,i,1)
				}
			}
			i -= 2
		}
		input := final
	}
	return final
}


LC_HMAC(Key, Message, Algo := "MD5") {
	static Algorithms := {MD2:    {ID: 0x8001, Size:  64}
						, MD4:    {ID: 0x8002, Size:  64}
						, MD5:    {ID: 0x8003, Size:  64}
						, SHA:    {ID: 0x8004, Size:  64}
						, SHA256: {ID: 0x800C, Size:  64}
						, SHA384: {ID: 0x800D, Size: 128}
						, SHA512: {ID: 0x800E, Size: 128}}
	static iconst := 0x36
	static oconst := 0x5C
	if (!(Algorithms.HasKey(Algo)))
	{
		return ""
    }
	Hash := KeyHashLen := InnerHashLen := ""
	HashLen := 0
	AlgID := Algorithms[Algo].ID
	BlockSize := Algorithms[Algo].Size
	MsgLen := StrPut(Message, "UTF-8") - 1
	KeyLen := StrPut(Key, "UTF-8") - 1
	VarSetCapacity(K, KeyLen + 1, 0)
	StrPut(Key, &K, KeyLen, "UTF-8")
	if (KeyLen > BlockSize)
    {
		LC_CalcAddrHash(&K, KeyLen, AlgID, KeyHash, KeyHashLen)
	}

	VarSetCapacity(ipad, BlockSize + MsgLen, iconst)
	Addr := KeyLen > BlockSize ? &KeyHash : &K
	Length := KeyLen > BlockSize ? KeyHashLen : KeyLen
	i := 0
	while (i < Length)
	{
		NumPut(NumGet(Addr + 0, i, "UChar") ^ iconst, ipad, i, "UChar")
		i++
	}
	if (MsgLen)
	{
		StrPut(Message, &ipad + BlockSize, MsgLen, "UTF-8")
	}
	LC_CalcAddrHash(&ipad, BlockSize + MsgLen, AlgID, InnerHash, InnerHashLen)

	VarSetCapacity(opad, BlockSize + InnerHashLen, oconst)
	Addr := KeyLen > BlockSize ? &KeyHash : &K
	Length := KeyLen > BlockSize ? KeyHashLen : KeyLen
	i := 0
	while (i < Length)
	{
		NumPut(NumGet(Addr + 0, i, "UChar") ^ oconst, opad, i, "UChar")
		i++
	}
	Addr := &opad + BlockSize
	i := 0
	while (i < InnerHashLen)
	{
		NumPut(NumGet(InnerHash, i, "UChar"), Addr + i, 0, "UChar")
		i++
	}
	return LC_CalcAddrHash(&opad, BlockSize + InnerHashLen, AlgID)
}

LC_MD2(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x8001, encoding)
}
LC_HexMD2(hexstring) {
	return LC_CalcHexHash(hexstring, 0x8001)
}
LC_FileMD2(filename) {
	return LC_CalcFileHash(filename, 0x8001, 64 * 1024)
}
LC_AddrMD2(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x8001)
}

LC_MD4(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x8002, encoding)
}
LC_HexMD4(hexstring) {
	return LC_CalcHexHash(hexstring, 0x8002)
}
LC_FileMD4(filename) {
	return LC_CalcFileHash(filename, 0x8002, 64 * 1024)
}
LC_AddrMD4(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x8002)
}

LC_MD5(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x8003, encoding)
}
LC_HexMD5(hexstring) {
	return LC_CalcHexHash(hexstring, 0x8003)
}
LC_FileMD5(filename) {
	return LC_CalcFileHash(filename, 0x8003, 64 * 1024)
}
LC_AddrMD5(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x8003)
}

;nnnik's custom encryption algorithm
;Version 2.1 of the encryption/decryption functions

LC_nnnik21_encryptStr(str="",pass="")
{
	If !(enclen:=(strput(str,"utf-16")*2))
		return "Error: Nothing to Encrypt"
	If !(passlen:=strput(pass,"utf-8")-1)
		return "Error: No Pass"
	enclen:=Mod(enclen,4) ? (enclen) : (enclen-2)
	Varsetcapacity(encbin,enclen,0)
	StrPut(str,&encbin,enclen/2,"utf-16")
	Varsetcapacity(passbin,passlen+=mod((4-mod(passlen,4)),4),0)
	StrPut(pass,&passbin,strlen(pass),"utf-8")
	LC_nnnik21_encryptbin(&encbin,enclen,&passbin,passlen)
	LC_Base64_Encode(Text, encbin, enclen)
	return Text
}

LC_nnnik21_decryptStr(str="",pass="")
{
	If !((strput(str,"utf-16")*2))
		return "Error: Nothing to Decrypt"
	If !((passlen:=strput(pass,"utf-8")-1))
		return "Error: No Pass"
	Varsetcapacity(passbin,passlen+=mod((4-mod(passlen,4)),4),0)
	StrPut(pass,&passbin,strlen(pass),"utf-8")
	enclen:=LC_Base64_Decode(encbin, str)
	LC_nnnik21__decryptbin(&encbin,enclen,&passbin,passlen)
	return StrGet(&encbin,"utf-16")
}


LC_nnnik21_encryptbin(pBin1,sBin1,pBin2,sBin2)
{
	b:=0
	Loop % sBin1/4
	{
		a:=numget(pBin1+0,sBin1-A_Index*4,"uint")
		numput(a+b,pBin1+0,sBin1-A_Index*4,"uint")
		b:=(a+b)*a
	}
	Loop % sBin2/4
	{
		c:=numget(pBin2+0,(A_Index-1)*4,"uint")
		b:=0
		Loop % sBin1/4
		{
			a:=numget(pBin1+0,(A_Index-1)*4,"uint")
			numput((a+b)^c,pBin1+0,(A_Index-1)*4,"uint")
			b:=(a+b)*a
		}
	}
}

LC_nnnik21__decryptbin(pBin1,sBin1,pBin2,sBin2){
	Loop % sBin2/4
	{
		c:=numget(pBin2+0,sBin2-A_Index*4,"uint")
		b:=0
		Loop % sBin1/4
		{
			a:=numget(pBin1+0,(A_Index-1)*4,"uint")
			numput(a:=(a^c)-b,pBin1+0,(A_Index-1)*4,"uint")
			b:=(a+b)*a
		}
	}
	b:=0
	Loop % sBin1/4
	{
		a:=numget(pBin1+0,sBin1-A_Index*4,"uint")
		numput(a:=a-b,pBin1+0,sBin1-A_Index*4,"uint")
		b:=(a+b)*a
	}
}


LC_RC4_Encrypt(Data,Pass) {
	Format:=A_FormatInteger,b:=0,j:=0,Key:=Object(),sBox:=Object()
	SetFormat,Integer,Hex
	VarSetCapacity(Result,StrLen(Data)*2)
	Loop 256
		a:=(A_Index-1),Key[a]:=Asc(SubStr(Pass,Mod(a,StrLen(Pass))+1,1)),sBox[a]:=a
	Loop 256
		a:=(A_Index-1),b:=(b+sBox[a]+Key[a])&255,sBox[a]:=(sBox[b]+0,sBox[b]:=sBox[a]) ; SWAP(a,b)
	Loop Parse, Data
		i:=(A_Index&255),j:=(sBox[i]+j)&255,k:=(sBox[i]+sBox[j])&255,sBox[i]:=(sBox[j]+0,sBox[j]:=sBox[i]) ; SWAP(i,j)
		,Result.=SubStr(Asc(A_LoopField)^sBox[k],-1,2)
	StringReplace,Result,Result,x,0,All
	SetFormat,Integer,%Format%
	Return Result
}

LC_RC4_Decrypt(Data,Pass) {
	b:=0,j:=0,x:="0x",Key:=Object(),sBox:=Object()
	VarSetCapacity(Result,StrLen(Data)//2)
	Loop 256
		a:=(A_Index-1),Key[a]:=Asc(SubStr(Pass,Mod(a,StrLen(Pass))+1,1)),sBox[a]:=a
	Loop 256
		a:=(A_Index-1),b:=(b+sBox[a]+Key[a])&255,sBox[a]:=(sBox[b]+0,sBox[b]:=sBox[a]) ; SWAP(a,b)
	Loop % StrLen(Data)//2
		i:=(A_Index&255),j:=(sBox[i]+j)&255,k:=(sBox[i]+sBox[j])&255,sBox[i]:=(sBox[j]+0,sBox[j]:=sBox[i]) ; SWAP(i,j)
		,Result.=Chr((x . SubStr(Data,(2*A_Index)-1,2))^sBox[k])
	Return Result
}

LC_RC4(RC4Data,RC4Pass) { ; Thanks Rajat for original, Updated Libcrypt version
	; http://www.autohotkey.com/board/topic/570-rc4-encryption/page-2#entry25712
	ATrim:=A_AutoTrim,BLines:=A_BatchLines,RC4PassLen:=StrLen(RC4Pass),Key:=Object(),sBox:=Object(),b:=0,RC4Result:="",i:=0,j:=0
	AutoTrim,Off
	SetBatchlines,-1
	Loop, 256
		a:=(A_Index-1),ModVal:=Mod(a,RC4PassLen),c:=SubStr(RC4Pass,ModVal+=1,1),Key[a]:=Asc(c),sBox[a]:=a
	Loop, 256
		a:=(A_Index-1),b:=Mod(b+sBox[a]+Key[a],256),T:=sBox[a],sBox[a]:=sBox[b],sBox[b]:=T
	Loop, Parse, RC4Data
		i:=Mod(i+1,256),j:=Mod(sBox[i]+j,256),k:=sBox[Mod(sBox[i]+sBox[j],256)],c:=Asc(A_LoopField)^k,c:=((c==0)?k:c),RC4Result.=Chr(c)
	AutoTrim, %ATrim%
	SetBatchlines, %BLines%
	Return RC4Result
}

/*
	- ROT5 covers the numbers 0-9.
	- ROT13 covers the 26 upper and lower case letters of the Latin alphabet (A-Z, a-z).
	- ROT18 is a combination of ROT5 and ROT13.
	- ROT47 covers all printable ASCII characters, except empty spaces. Besides numbers and the letters of the Latin alphabet,
			the following characters are included:
			!"#$%&'()*+,-./:;<=>?[\]^_`{|}~
*/
/*
LC_Rot5(string) {
	Loop, Parse, string
		s .= (strlen((c:=A_LoopField)+0)?((c<5)?c+5:c-5):(c))
	Return s
}

; by Raccoon July-2009
; http://rosettacode.org/wiki/Rot-13#AutoHotkey
LC_Rot13(string) {
	Loop, Parse, string
	{
		c := asc(A_LoopField)
		if (c >= 97) && (c <= 109) || (c >= 65) && (c <= 77)
			c += 13
		else if (c >= 110) && (c <= 122) || (c >= 78) && (c <= 90)
			c -= 13
		s .= Chr(c)
	}
	Return s
}

LC_Rot18(string) {
	return LC_Rot13(LC_Rot5(string))
}

; adapted from http://langref.org/fantom+java+scala/strings/reversing-a-string/simple-substitution-cipher
; from decimal 33 '!' through 126 '~', 94 
LC_Rot47(string) {
	Loop Parse, string
	{
		c := Asc(A_LoopField)
		c += (c >= Asc("!") && c <= Asc("O") ? 47 : (c >= Asc("P") && c <= Asc("~") ? -47 : 0))
		s .= Chr(c)
	}
	Return s
}

; RSHash (Robert Sedgewick's string hashing algorithm)
; from jNizM
; https://autohotkey.com/boards/viewtopic.php?p=87929#p87929

LC_RSHash(str) {
	a := 0xF8C9, b := 0x5C6B7, h := 0
	loop, parse, str
		h := h * a + Asc(A_LoopField), a *= b
	return (h & 0x7FFFFFFF)
}

LC_SecureSalted(salt, message, algo := "md5") {
	hash := ""
	saltedHash := %algo%(message . salt) 
	saltedHashR := %algo%(salt . message)
	len := StrLen(saltedHash)
	loop % len / 2
	{
		byte1 := "0x" . SubStr(saltedHash, 2 * A_index - 1, 2)
		byte2 := "0x" . SubStr(saltedHashR, 2 * A_index - 1, 2)
		SetFormat, integer, hex
		hash .= StrLen(ns := SubStr(byte1 ^ byte2, 3)) < 2 ? "0" ns : ns
	}
	SetFormat, integer, dez
	return hash
}

LC_SHA(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x8004, encoding)
}
LC_HexSHA(hexstring) {
	return LC_CalcHexHash(hexstring, 0x8004)
}
LC_FileSHA(filename) {
	return LC_CalcFileHash(filename, 0x8004, 64 * 1024)
}
LC_AddrSHA(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x8004)
}

LC_SHA256(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x800c, encoding)
}
LC_HexSHA256(hexstring) {
	return LC_CalcHexHash(hexstring, 0x800c)
}
LC_FileSHA256(filename) {
	return LC_CalcFileHash(filename, 0x800c, 64 * 1024)
}
LC_AddrSHA256(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x800c)
}

LC_SHA384(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x800d, encoding)
}
LC_HexSHA384(hexstring) {
	return LC_CalcHexHash(hexstring, 0x800d)
}
LC_FileSHA384(filename) {
	return LC_CalcFileHash(filename, 0x800d, 64 * 1024)
}
LC_AddrSHA384(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x800d)
}

LC_SHA512(string, encoding = "UTF-8") {
	return LC_CalcStringHash(string, 0x800e, encoding)
}
LC_HexSHA512(hexstring) {
	return LC_CalcHexHash(hexstring, 0x800e)
}
LC_FileSHA512(filename) {
	return LC_CalcFileHash(filename, 0x800e, 64 * 1024)
}
LC_AddrSHA512(addr, length) {
	return LC_CalcAddrHash(addr, length, 0x800e)
}

; Modified by GeekDude from http://goo.gl/0a0iJq
LC_UriEncode(Uri, RE="[0-9A-Za-z]") {
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	While Code := NumGet(Var, A_Index - 1, "UChar")
		Res .= (Chr:=Chr(Code)) ~= RE ? Chr : Format("%{:02X}", Code)
	Return, Res
}

LC_UriDecode(Uri) {
	Pos := 1
	While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos)
	{
		VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code,2)
		Loop, Parse, Code, `%
			NumPut("0x" A_LoopField, Var, A_Index-1, "UChar")
		Decoded := StrGet(&Var, "UTF-8")
		Uri := SubStr(Uri, 1, Pos-1) . Decoded . SubStr(Uri, Pos+StrLen(Code)+1)
		Pos += StrLen(Decoded)+1
	}
	Return, Uri
}

;----------------------------------

LC_UrlEncode(Url) { ; keep ":/;?@,&=+$#."
	return LC_UriEncode(Url, "[0-9a-zA-Z:/;?@,&=+$#.]")
}

LC_UrlDecode(url) {
	return LC_UriDecode(url)
}

; 
; Version: 2014.03.06-1518, jNizM
; see https://en.wikipedia.org/wiki/Vigen%C3%A8re_cipher
; ===================================================================================

LC_VigenereCipher(string, key, enc := 1) {
	enc := "", DllCall("user32.dll\CharUpper", "Ptr", &string, "Ptr")
	, string := RegExReplace(StrGet(&string), "[^A-Z]")
	loop, parse, string
	{
		a := Asc(A_LoopField) - 65
		, b := Asc(SubStr(key, 1 + Mod(A_Index - 1, StrLen(key)), 1)) - 65
		, enc .= Chr(Mod(a + b, 26) + 65)
	}
	return enc
}

LC_VigenereDecipher(string, key) {
	dec := ""
	loop, parse, key
		dec .= Chr(26 - (Asc(A_LoopField) - 65) + 65)
	return LC_VigenereCipher(string, dec)
}

; FUnctions and algorithm by VxE
; intergrated into libcrypt.ahk with "LC_" prefixes

/*
####################################################################################################
####################################################################################################
######                                                                                        ######
######                                [VxE]-251 Encryption                                    ######
######                                          &                                             ######
######                                [VxE]-89  Encryption                                    ######
######                                                                                        ######
####################################################################################################
####################################################################################################

[VxE] 251 encryption is a rotation-based encryption algorithm using a dynamic key and a
dynamic map. The '251' indicates the size of the map, which omits the following byte-values:
0x00 ( null byte: string terminator )
0x09 ( tab character: common text formatting character )
0x0A ( newline character: common text formatting character )
0x0D ( carriage return character: common text formatting character )
0x7F ( wierd character: ascii 'del' )

This encryption function also supports an 89-character map, which incorporates the byte values
between 0x20 and 0x7e, omitting 0x22, 0x27, 0x2C, 0x2F, 0x5C, and 0x60. This mode allows text value
input to be encrypted as text without high-ascii characters or non-printable characters.
*/

; ##################################################################################################
; ## Function shortcuts
/*
LC_VxE_Encrypt89( key, byref message ) { ; ----------------------------------------------------------
   Return LC_VxE_Crypt( key, message, 1, "vxe89 len" StrLen( message ) << !!A_IsUnicode )
} ; VxE_Encrypt89( key, byref message ) ----------------------------------------------------------

LC_VxE_Decrypt89( key, byref message ) { ; ----------------------------------------------------------
   Return LC_VxE_Crypt( key, message, 0, "vxe89 len" StrLen( message ) << !!A_IsUnicode )
} ; VxE_Decrypt89( key, byref message ) ----------------------------------------------------------

LC_VxE_Encrypt251( key, byref message, len ) { ; ----------------------------------------------------
   Return LC_VxE_Crypt( key, message, 1, "len" len )
} ; VxE_Encrypt251( key, byref message, len ) ----------------------------------------------------

LC_VxE_Decrypt251( key, byref message, len ) { ; ----------------------------------------------------
   Return LC_VxE_Crypt( key, message, 0, "len" len )
} ; VxE_Decrypt251( key, byref message, len ) ----------------------------------------------------

; ##################################################################################################
; ## The core function

LC_VxE_Crypt( key, byref message, direction = 1, options="" ) { ; -----------------------------------
; Transorms the message. 'direction' indicates whether or not to decrypt or encrypt the message.
; However, since this algorithm is symmetrical, distinguishing between 'encrypt' and 'decrypt' is
; merely for the benefit of human understanding.

; This agorithm was developed by [VxE] in July 2010. When a key/message are passed to this function,
; it generates the rotation map using the key. Then, it traverses the bytes in the message, rotating
; their values along the map according to the key. Once the character's encoded value is determined,
; the key is augmented by a value based on the byte value.

   If !RegexMatch( options, "i)(?:len|l)\K(?:0x[\da-fA-F]+|\d+)", length ) ; check explicit length
      length := StrLen( message ) << !!A_IsUnicode ; otherwise, find length.
   UseVxE89 := InStr( options, "vxe89" ) ; check 'options' for text-friendly mode.
   direction := 2 * ( direction = 1 ) - 1 ; coerce the 'direction' to either +1 or -1.

   w := StrLen( key ) << !!A_IsUnicode
   ; 'w' holds the derived key, which is a 32-bit integer based on the key.
   ; Although this doesn't seem very entropic, remember that the map is also derived from the key.
   
   If (UseVxE89) ; using the smaller map allows text-friendly encrypting since the small map is
      Loop 126 ; composed only of low-ascii printable characters
         If ( A_Index >= 32 && A_Index != 34 && A_Index != 39 && A_Index != 44
         && A_Index != 47 && A_Index != 92 && A_Index != 96 )
            map .= Chr( A_Index )
   If !UseVxE89 ; the 251 map is more suitable for non-text data
      Loop 255
         If ( A_Index != 9 && A_Index != 10 && A_Index != 13 && A_Index != 127 )
            map .= Chr( A_Index )
   k := StrLen( map ) ; keep the length of the map

   Loop 9 ; pad the key up to 509 characters, mixing in digit-characters
      If StrLen( key ) < 509
         key := SubStr( key Chr( 48 + A_Index ) key, 1, 509 )

   Loop 509 ; rearrange the map, using the padded key as the selector.
   { ; This is how the map becomes dynamic. 509 times, a char is selected from the map and
   ; is extracted from the map string, then appended to it. At the same time, the derived key is
   ; augmented by XORing it with a value based on each byte in the key.
      q := *( &key + A_Index - 1 )
      pos := 1 + Mod( q * A_Index * 3, k )
      StringMid, e, map, %pos%, 1
      StringLeft, i, map, pos - 1
      StringTrimLeft, c, map, %pos%
      map := i c e
      w ^= q * A_Index * 1657
   }
   x := 0
   Loop %length%
   {
      c := NumGet( message, A_Index - 1, "UChar" ) ; for each byte in the message

      If !c || !( i := InStr( map, Chr( c ), 1 ) )
         Continue ; if the character isn't in the map, just skip it.
      i-- ; the map index should be zero based for easier use with Mod() function
      x++ ; this tracks the actual index, not the char position.

      e := Mod( 223390000 + i + w * direction, k ) ; rotate the index along the map

      c := Asc( SubStr( map, e + 1, 1 ) ) ; lookup the character at the rotated index

      NumPut( c, message, A_Index - 1, "UChar" ) ; append the newly-mapped char to the result

      ; Finally, depending on the direction of rotation, use either the original index or
      ; the rotated index to augment the derived key
      If ( direction = 1 )
         c := Mod( e + x, 251 )
      Else c := Mod( i + x, 251 )
      w ^= c | c << 8 | c << 16 | c << 24
   }
   return length
} ; VxE_Crypt( key, byref message, direction = 1, options="" ) -----------------------------------

LC_XOR_Encrypt(str,key) {
	EncLen:=StrPut(Str,"UTF-16")*2
	VarSetCapacity(EncData,EncLen)
	StrPut(Str,&EncData,"UTF-16")

	PassLen:=StrPut(key,"UTF-8")
	VarSetCapacity(PassData,PassLen)
	StrPut(key,&PassData,"UTF-8")

	LC_XOR(OutData,EncData,EncLen,PassData,PassLen)
	LC_Base64_Encode(OutBase64, OutData, EncLen)
	return OutBase64
}

LC_XOR_Decrypt(OutBase64,key) {
	EncLen:=LC_Base64_Decode(OutData, OutBase64)

	PassLen:=StrPut(key,"UTF-8")
	VarSetCapacity(PassData,PassLen)
	StrPut(key,&PassData,"UTF-8")

	LC_XOR(EncData,OutData,EncLen,PassData,PassLen)
	return StrGet(&EncData,"UTF-16")
}

LC_XOR(byref OutData,byref EncData,EncLen,byref PassData,PassLen)
{
	VarSetCapacity(OutData,EncLen)
	Loop % EncLen
		NumPut(NumGet(EncData,A_Index-1,"UChar")^NumGet(PassData,Mod(A_Index-1,PassLen),"UChar"),OutData,A_Index-1,"UChar")
}

StringUpper(StringToUp)
{
	StringUpper,StringtoUp,StringToUp
	return StringToUp
}

URLDownloadToVar(url){
	hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	hObject.Open("GET",url)
	hObject.SetRequestHeader("X-Mashape-Key","rmXyxhqXgMmsh2RXCz0oSBpCJhiBp1v0yGOjsnl34qCR7PI6KL")
	hObject.Send()
	return hObject.ResponseText
}