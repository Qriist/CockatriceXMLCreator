#Requires AutoHotkey v2.0
#include <Aris/G33kDude/cJson> ; G33kDude/cJson@2.1.0
#include <Aris/Qriist/apiQache> ; github:Qriist/apiQache@v0.81.0 --main Lib\apiQache.ahk
#include <Aris/Qriist/LibQurl> ; Qriist/LibQurl@v0.91.0
#include <Aris/Qriist/Null> ; github:Qriist/Null@v1.0.0 --main Null.ahk
; #include <Aris/Qriist/SqlarMultipleCiphers> ; github:Qriist/SqlarMultipleCiphers@v2.0.3+SqlarMultipleCiphers.ICU.7z --files *.*
#include <Aris/Qriist/SQriLiteDB> ; github:Qriist/SQriLiteDB@v0.82.0 --main SQriLiteDB.ahk
#include <Aris/SKAN/RunCMD> ; SKAN/RunCMD@aadeb56
#include <Aris/Chunjee/adash> ; Chunjee/adash@v0.5.0
#include <Aris/thqby/Base64> ; thqby/Base64@831e5e3
class CockatriceXMLCreator {
    __New(incomingGameEntityName := "") {
        this.gameEntity := Map()
        this.currentCardEntity := Map()
        this.currentCard := ""
        this.currentSetEntity := Map()
        this.currentSet := ""
        this.xmlInProgress := Map()
        this.xmlsize := 262144000
        this.base64 := Map()
        this.gameEntity := Map()
		this.gameEntity["game"] := incomingGameEntityName
		this.gameEntity["cards"] := Map()
		this.gameEntity["sets"] := Map()
		this.gameEntity["related"] := Map()
		this.gameEntity["reverse-related"] := Map()
		this.currentCardEntity := Map()
		this.g()
		this.checkForCkInstall()
    }
	
	
	;new entities
	newCardEntity(incomingName,autoChangeToNewEntity := 1){
		if this.gameEntity["cards"].Has(incomingName)
			return

		;construct the basic card object
		card := this.gameEntity["cards"][incomingName] := Map()
		card["name"] := incomingName
		card["text"] := ""
		card["props"] := Map()
		card["sets"] := Map()
		card["sets"][0] := Map()	;maintains a list of visibleSetCodes
		card["related"] := Map()
		card["reverse-related"] := Map()
		card["token"] := 0
		card["tablerow"] := 3
		card["cipt"] := 0
		card["upsidedown"] := 0
		
		if (autoChangeToNewEntity = 1)
			this.changeCardEntity(incomingName)
	}
	newSetEntity(incomingName,autoChangeToNewEntity := 1){
		if this.gameEntity["sets"].Has(incomingName)
			return
		
		;construct the basic set object
		set := this.gameEntity["sets"][incomingName] := Map()
		set["name"] := incomingName
		set["longname"] := ""
		set["settype"] := ""
		set["releasedate"] := ""

		if (autoChangeToNewEntity = 1)
			this.changeSetEntity(incomingName)
	}
	
	
	;changing the current default entity
	changeCardEntity(incomingName){
		this.currentCardEntity := this.gameEntity["cards"][incomingName]
		this.currentCard := incomingName
	}
	changeSetEntity(incomingName){
		this.currentSetEntity := this.gameEntity["sets"][incomingName]
		this.currentSet := incomingName
	}
	
	
	;setting an entity property
	setMajorCardProp(propName,propValue, nameOfCardEntity?){
		nameOfCardEntity ??= this.currentCard
		this.gameEntity["cards"][nameOfCardEntity][propName] := propValue
	}
	setCardProp(propName,propValue, nameOfCardEntity?){
		nameOfCardEntity ??= this.currentCard
		this.gameEntity["cards"][nameOfCardEntity]["props"][propName] := propValue
	}
	setSetProp(propName, propValue, nameOfSetEntity?){
		nameOfSetEntity ??= this.currentSet
		this.gameEntity["sets"][nameOfSetEntity][propName] := propValue
	}
	attachSetToCard(visibleSetCode,setArr,nameOfCardEntity := ""){
		;used for generating the unbounded <set> tags on each card
		;first parameter is what's visible in cockatrice
		;visibleSetCode does not need to be unique, nor does any property of setArr[]
		;all properties will be attached exactly as passed, k=v
		;pseudocode template: <set setArr["prop1"]="abc" setArr["prop2"]="xyz">visibleSetCode</set>
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		; sets := this.gameEntity["cards"][nameOfCardEntity]["sets"]
		sets := this.gameEntity["cards"][nameOfCardEntity]["sets"]
		sets[sets.count] := setArr	;should start from 1
		this.gameEntity["cards"][nameOfCardEntity]["sets"][0][(this.gameEntity["cards"][nameOfCardEntity]["sets"].count-1)] := visibleSetCode
	}
	attachRelatedCard(relatedCard,relatedCardObj,nameOfCardEntity := ""){
		;attaches relatedCard to nameOfCardEntity
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity]["related"][relatedCard] := relatedCardObj
	}
	attachReverseRelatedCard(rRelatedCard,rRelatedCardObj,nameOfCardEntity := ""){
		;attaches rRelatedCard card to nameOfCardEntity
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity]["reverse-related"][rRelatedCard] := rRelatedCardObj
	}
	
	;appending to a property
	appendMajorCardProp(propName,propValue, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity][propName] .= propValue
	}
	appendCardProp(propName,propValue, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity]["props"][propName] .= propValue
	}
	appendSetProp(propName, propValue, nameOfSetEntity := ""){
		if (nameOfSetEntity = "")
			nameOfSetEntity := this.currentSet
		this.gameEntity["sets"][nameOfSetEntity][propName] .= propValue
	}
	
	;prepending to a property
	prependMajorCardProp(propName,propValue, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity][propName] := propValue this.gameEntity["cards"][nameOfCardEntity][propName]
	}
	prependCardProp(propName,propValue, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		this.gameEntity["cards"][nameOfCardEntity]["props"][propName] := propValue this.gameEntity["cards"][nameOfCardEntity,propName]
	}
	prependSetProp(propName, propValue, nameOfSetEntity := ""){
		if (nameOfSetEntity = "")
			nameOfSetEntity := this.currentSet
		this.gameEntity["sets"][nameOfSetEntity][propName] := propValue this.gameEntity["cards"][nameOfSetEntity][propName]
	}
	
	
	;retrieving an entity property
	getMajorCardProp(propName, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		return this.gameEntity["cards"][nameOfCardEntity][propName]
	}
	getCardProp(propName, nameOfCardEntity := ""){
		if (nameOfCardEntity="")
			nameOfCardEntity := this.currentCard
		return this.gameEntity["cards"][nameOfCardEntity]["props"][propName]
	}
	getSetProp(propName,nameOfSetEntity := ""){
		if (nameOfSetEntity = "")
			nameOfSetEntity := this.currentSetEntity
		return this.gameEntity["sets"][nameOfSetEntity][propName]
	}
	
	
	;retrieving an entire entity object
	getCardEntity(nameOfCardEntity := ""){
		if (nameOfCardEntity = "")
			return this.currentCardEntity
		return this.gameEntity["cards"][nameOfCardEntity]
	}
	getSetEntity(nameOfSetEntity := ""){
		if (nameOfSetEntity = "")
			return this.currentSetEntity
		return this.gameEntity["sets"][nameOfSetEntity]
	}
	
	
	;font stuff
	colorizeText(inText,inColor,boldOrItalics := ""){
		;wraps text in html color tags (pass either specific words or 0xFFFFFF codes)
		;useful links to look at the colors
		;	https://htmlcolorcodes.com/color-names/
		;	https://www.computerhope.com/jargon/w/w3c-color-names.htm
		return "<font color=" chr(34) inColor chr(34) ">" this.boldOrItalicText(inText,boldOrItalics) "</font>"
	}
	colorizeBackground(inText,inColor){	;use just for 
		
		return
	}
	longdash(){	;longdash is useful when building type lines - just a shortcut
		return "—"
	}
	ld(){	;longdash alias
		return this.longdash()
	}
	boldOrItalicText(inText,boldOrItalic := ""){
		;0 = nothing
		;1 = bold
		;2 = italic
		;3 = both
		switch boldOrItalic {
			case "",0: 
				return inText
			case 1,"bold","b": 
				return "<b>" inText "</b>"
			case 2,"italic","i": 
				return "<i>" inText "</i>"
			case 3,"bolditalic","bi": 
				return "<b><i>" inText "</i></b>"
			Default: 
				return inText
		}
	}
	colorizeBackgroundAndText(inText, backgroundColor := "white", textColor := "black", boldOrItalics := ""){
		;using a dirty hack to get in-line background colors... 
		;a code block is used due Cockatrice's extremely limited rendering engine
		
		;should probably expand the font list to prioritize the current modern OS fonts
		;static codeblockFonts := st_glue(["Helvetica","sans-serif"],",")
		
		;return "<code style=""background-color:" backgroundColor ";font-family:" codeblockFonts ";"">" this.colorizeText(inText,textColor,boldOrItalics) "</code>"
		return "<span style='background-color:" backgroundColor ";'>" this.colorizeText(inText,textColor,boldOrItalics) "</span>"
		;bodyStart := 
		;bodyEnd := 
	}
	embedImage(imgPath,styleObj?){
		if this.base64.Has(imgPath)	;image already processed into memory
			return "<img src='data:image/png;base64," this.base64[imgPath] "' /></img>"
		
		rawData := Buffer(FileGetSize(imgPath))
		FileOpen(imgPath,"r").RawRead(rawData)
		this.base64[imgPath] := Base64.Encode(rawData)
		return "<img src='data:image/png;base64," this.base64[imgPath] "' /></img>"
	}
	embedComment(inText,dedupe := ""){
		;used to add invisible comments, usually when you need to add a search term without affecting game text
		;won't embed the comment if it exists in dedupe in order to save xml space
		if !InStr(dedupe,inText)
			return "<!--" inText "-->"
	}
	addTable(tableObj,colRowObj?){
		;format any number of outer objects (rows) plus any number of nested inner keys (columns) into an HTML table
		;all font processing should be done as the tableObj is built
		;backgroundObj is used to set the background color of a specific cell
		;example backgroundObj key:  {"4|2" : "green"}  where "4|2" corresponds to row 4 and column 2
		
		if (tableObj.count = 0)	;nothing to do
			return
		
		; If !IsSet(colRowObj){
		; 	colRowObj := Map("row",Map())
		; }

		body := "<table>"
		loop tableObj.count {
			rowIndex := a_index
			trstyle := ""
			try trstyle := A_Space this.StyleOptions(colRowObj["row"][rowIndex])
			body .= "<tr " rowIndex trstyle ">"

			; try
			; body .= "<tr " colRowObj["row"][rowIndex] ">"
			; body .= "<tr " rowIndex ">"
			loop tableObj[rowIndex].count{
				colIndex := a_index
				colspan := ""
				rowspan := ""

				if tableObj[rowIndex][colIndex].has("colspan")
					colspan := a_space "colspan=" tableObj[rowIndex][colIndex]["colspan"]
				if tableObj[rowIndex][colIndex].has("rowspan")
					rowspan := a_space "rowspan=" tableObj[rowIndex][colIndex]["rowspan"]
				
				try for k,v in ["backgound-color"]["font-weight"]{
					
				}
				; if (style != "")
				; 	style := "style=" chr(34) style chr(34)
				if tableObj[rowIndex][colIndex].has("background-color")
					bgcolor := a_space "style=" chr(34) "background-color:" tableObj[rowIndex][colIndex]["background-color"] ";" chr(34)
				; try
				txt := ""
				try txt := tableObj[rowIndex][colIndex]["text"]
				body .= "<td" colspan rowspan this.StyleOptions(tableObj[rowIndex][colIndex]) ">" txt "</td>"
				; body .= "<td" (IsSet(colspan)?colspan:"") (IsSet(rowspan)?rowspan:"") this.styleOptions(tableObj[rowIndex][colIndex]) ">" tableObj[rowIndex][colIndex]["text"] "</td>"
				
				;msgbox % "<td" colspan ">" tableObj[rowIndex,colIndex,"text"] "</td>"
				style := colspan := ""	;reset values
				
			}
			body .= "</tr>"
		}
		body .= "</table>"
		;msgbox % clipboard := body
		return body 
	}
	addList(listObj,listType := "u"){
		;creates an ordered or unordered list
		;defaults to unordered, set listType to "o" to make an ordered list
		outlist := ""
		For k,v in listObj{
			outList .= "<li>" v "</li>"
		}
		if (outList != "")
			return "<" listType "l>" outList "<" listType "l>"
	}
	styleOptions(styleObj){
		;pass in any object and it will return a style string with all matching keys
		
		styleStr := ""
		for k,v in ["background-color","font-weight","text-align","vertical-align"]
			if styleObj.Has(v)
				styleStr .= v ":" styleObj[v] ";"
		
		if (styleStr != "")
			return " style=" chr(34) styleStr chr(34)
	}
	
	uniqify(paramObj, stripNonAlphanumeric := 1,normalizeCase := 1){
		;pass in any number of strings and objects to create a unique hash of all discovered text
		;stripNonAlphanumeric removes all white space, punctuation, and special characters before hashing
		;normalizeCase makes everything lowercase before hashing
		unique := JSON.Dump(paramObj)
		If (stripNonAlphanumeric = 1)
			unique := RegExReplace(unique,"\W")
		If (normalizeCase = 1)
			unique := StrLower(unique)
		return api.hash(&unique)	;todo: acquire hash function
	}
	
	;XML generation
	generateXML(infoObj := Map()){
		this.xmlInProgress := []
		this.generateXML_header(infoObj)
		this.generateXML_sets()
		this.generateXML_related()
		this.generateXML_cards()
		this.generateXML_footer()
		xml := ""
		VarSetStrCapacity(&xml,this.xmlsize)
		;msgbox % 
		for k,v in this.xmlInProgress {
			xml .= this.xmlInProgress[k]
		}

		FileOpen(A_ScriptDir "\cxml\" this.gameEntity["game"] "\data\cards.xml","w").Write(xml)

		;compress for release
		;todo - optimize compress
		DirCreate(A_ScriptDir "\output\")
		try FileDelete(A_ScriptDir "\output\" this.gameEntity["game"] ".7z")
		RunCMD(A_ScriptDir "\tools\7za.exe a " 
			.	Chr(34) A_ScriptDir "\output\" this.gameEntity["game"] ".7z" Chr(34) A_Space
			.	Chr(34) A_ScriptDir "\cxml\" this.gameEntity["game"] "\data\cards.xml" Chr(34) A_Space)
		return
	}
	generateXML_header(infoObj := Map()){
		this.xmlInProgress.push('<?xml version="1.0" encoding="UTF-8"?>`n')
		this.xmlInProgress.push('<cockatrice_carddatabase version="4" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://raw.githubusercontent.com/Cockatrice/Cockatrice/master/doc/carddatabase_v4/cards.xsd">`n')
		this.xmlInProgress.push(a_tab "<info>`n")
		for k,v in infoObj {
			this.xmlInProgress.push(a_tab a_tab "<" k ">" v "</" k ">`n")
		}
		this.xmlInProgress.push(a_tab "</info>`n")
	}
	generateXML_sets(){
		this.xmlInProgress.push(a_tab "<sets>`n")
		for k,v in this.gameEntity["sets"]{
			set := k
			this.xmlInProgress.push(a_tab a_tab "<set>`n")
			for k,v in this.gameEntity["sets"][set]{
				if (v!="")
					this.xmlInProgress.push(a_tab a_tab a_tab "<" this.UnicodeToXML(&k) ">" this.UnicodeToXML(&v) "</" this.UnicodeToXML(&k) ">`n")
			}
			this.xmlInProgress.push(a_tab a_tab "</set>`n")
		}
		this.xmlInProgress.push("</sets>`n")
		
	}
	generateXML_related(){
		; for k,v in this.gameEntity["related"] {
		; 	this.["cards"][k]["related"][v] := ""
		; }
	}
	generateXML_cards(){
		this.xmlInProgress.push("<cards>`n")
		for k,v in this.gameEntity["cards"]{
			card := k
			this.xmlInProgress.push(a_tab a_tab "<card>`n")
			for k,v in this.gameEntity["cards"][card]{
				majProp := k
				switch majProp {
					case "cipt","token","upsidedown":
						if (v != 0)
							this.xmlInProgress.push(a_tab a_tab a_tab "<" k ">" this.UnicodeToXML(&v) "</" k ">`n")
					case "props":
						this.xmlInProgress.push(a_tab a_tab a_tab "<prop>`n")
						for k,v in this.gameEntity["cards"][card]["props"]
							this.xmlInProgress.push(a_tab a_tab a_tab a_tab "<" k ">" this.UnicodeToXML(&v) "</" k ">`n")
						this.xmlInProgress.push(a_tab a_tab a_tab "</prop>`n")						
					case "related":
						for k,v in this.gameEntity["cards"][card]["related"]{
							relatedCard := k
							relStr := ""
							for k,v in this.gameEntity["cards"][card]["related"][relatedCard]{
								relStr .= a_space k "=" chr(34) v chr(34)
							}
							this.xmlInProgress.push(a_tab a_tab a_tab "<related" relStr ">" this.UnicodeToXML(&relatedCard) "</related>`n")							
						}
					case "reverse-related" :
						;todo
					case "sets" : 
						for k,v in this.gameEntity["cards"][card]["sets"][0]{
							;msgbox % st_printArr(this.gameEntity["cards",card,"sets",0])
							setIndex := k
							setCode := v
							setAttributes := ""
							; msgbox JSON.Dump(this.gameEntity["cards"][card]["sets"])
							for k,v in this.gameEntity["cards"][card]["sets"][setIndex]{
								;do NOT push this one to xmlInProgress
								setAttributes .= a_space k "=" chr(34) this.UnicodeToXML(&v) chr(34)
							}
							this.xmlInProgress.push(a_tab a_tab a_tab "<set" setAttributes ">" this.UnicodeToXML(&setCode) "</set>`n")
						}
					default: 
						this.xmlInProgress.push(a_tab a_tab a_tab "<" k ">" this.UnicodeToXML(&z := StrReplace(StrReplace(v,"`r"),"`n","<br>")) "</" k ">`n")
				}
				
			}
			this.xmlInProgress.push(a_tab a_tab "</card>`n")
		}
		this.xmlInProgress.push(a_tab "</cards>`n")
		;return ret
	}
	generateXML_footer(){
		/*
			ret .= "</cockatrice_carddatabase>"
			return ret
		*/
		this.xmlInProgress.push("</cockatrice_carddatabase>")
	}
	UnicodeToXML(&UnicodeString)
	{
	
		;msgbox % UnicodeString
		UnicodeStringNew := ""
		VarSetStrCapacity(&UnicodeStringNew,(StrLen(UnicodeString) * 8)) ;maybe speeds up building UnicodeStringNew
		Loop Parse UnicodeString
		{
			checkOrd := ord(A_LoopField)
			switch checkOrd {
				case 34,38,39,60,62 :
					UnicodeStringNew .= "&#" checkOrd ";"
				default:
					If !(checkOrd>126)
						UnicodeStringNew .= a_loopfield
					else
						UnicodeStringNew .= "&#" checkOrd ";"
			}
		}
		return UnicodeStringNew
	}
	g(){
		this.gui := Gui()
		this.gui.title := this.gameEntity["game"] " XML Creator"
		this.gui.Opt("+Resize +MinSize250")
		this.gt1 := this.gui.Add("Text","w300 BackgroundTrans center vtext1","")
		this.gt2 := this.gui.Add("Text","w300 BackgroundTrans center vtext2","")
		this.gt3 := this.gui.Add("Text","w300 BackgroundTrans center vtext3","")
		this.gui.Show("autosize center")
	}
	gtext(line,text := ""){
		this.gt%line%.text := text
	}
	checkForCkInstall(){
		ckpath := A_ScriptDir "\cxml\" this.gameEntity["game"]
		ckpathesc := StrReplace(ckpath,A_Space,"^ ")
		If DirExist(ckpath)
			return
		this.gtext(2,"New game detected, installing Cockatrice for " this.gameEntity["game"] ".")		
		DirCreate(ckpath)
		RunCMD('"' A_ScriptDir '\tools\7za.exe" x "' A_ScriptDir '\tools\cockatrice.7z" "-o' ckpath '"')
		FileCreateShortcut(A_ScriptDir "\cxml\" this.gameEntity["game"] "\cockatrice.exe",A_ScriptDir "\XML Creator - " this.gameEntity["game"] ".lnk")
	}
}