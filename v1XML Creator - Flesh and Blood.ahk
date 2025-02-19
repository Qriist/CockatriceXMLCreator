#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1
FileEncoding UTF-8
#include <cJSON>
#include <class_cockatriceXML>
#include <string_things>
#Include <functions>
;#include <class_sqlitedb>
#include <SingleRecordSQL>
#include <class_apiCache>
#include <libcrypt>
#include <class_EasyIni>
#Include <regexmatchglobal>
#MaxMem 4096
HashArray := []
pitchColorArr := ["Red","Yellow","Blue"]
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;~ #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
Gui, XML: New, +MinSizex250
Gui, Add, Text,w300 BackgroundTrans center vText1,
Gui, Add, Text,w300 BackgroundTrans center vText2,Gathering card list...
Gui, Add, Text,w300 BackgroundTrans center vText3,
Gui, Show,autosize center,Flesh & Blood XML Creator

;OnExit, ExitRoutine	;ensures graceful shutdown of the database
cXml := new class_cockatriceXML
cxml.init("Flesh & Blood")
apiCache := new class_ApiCache

;FileDelete, % A_ScriptDir "\cache\XML Creator - YuGiOh.db*"	;easy db delete for testing
apiCache.init(A_ScriptDir "\Flesh and Blood\",A_ScriptDir "\cache\XML Creator - Flesh and Blood.db")
;apiCache.initExpiry(86400) ;updates local cache once per day

identObj := []
loop,{	;doing initial scan to get identifiers
	if (apiCache.lastServedSource = "server")
		sleep, 60
	jsonObj := json.load(apiCache.retrieve("https://fabdb.net/api/cards?per_page=100&page=" a_index))
	for k,v in jsonObj["data"] {
		identObj.push(v["identifier"])
	}
	
} until (jsonObj["meta","to"] = jsonObj["meta","total"])
classObj := []


;first pass to gather various names for highlighting
;GuiControl, , text2,% "Doing first pass to gather info for name highlighting..."
;nameObj := [],talentObj := [],classObj := [],typeObj := [],subtypeObj := []
;for k,v in identObj{
	;cardObj := json.load(apiCache.retrieve("https://fabdb.net/api/cards/" v ))
	;subprop := 1
	;for k,v in cardObj["keywords"]{ ;*[XML Creator - Flesh and Blood]
		;switch v {
			;case cardObj["talent"]:{
				;talentObj[StringUpper(cardObj["talent"],"T")] := 1
			;}
			;case cardObj["class"]:{
				;cxml.setCardProp("class", StringUpper(cardObj["class"],"T"))
				;cxml.appendCardProp("type", StringUpper(cardObj["class"],"T") " ")
			;}
			;case cardObj["type"]:{
				;cxml.setCardProp("Maintype", StringUpper(cardObj["type"],"T"))
				;cxml.appendCardProp("type", StringUpper(cardObj["type"],"T"))
			;}
			;case cardObj["subtype"]:{
				;cxml.setCardProp("subtype", StringUpper(cardObj["subtype"],"T"))
				;cxml.appendCardProp("type", " - " StringUpper(cardObj["subtype"],"T"))
				
			;}
			;Default:{
				;subprop += 1
				;if regexmatch(v,"i)\d+h")
					;subv := "(" StringUpper(v) ")"	;wraps (1H) & (2H) properties
				;else
					;subv := StringUpper(v,"T")
				;cxml.setCardProp("subtype " subprop, subv)
				;cxml.appendCardProp("type", " " subv)
			;}
		;}
	;}
;}

;msgbox % identObj.count() st_printarr(identObj)
for k,v in identObj {
	if (apiCache.lastServedSource = "server")
		sleep, 60
	identifier := v
	cardObj := json.load(apiCache.retrieve("https://fabdb.net/api/cards/" identifier ))
	GuiControl, , text2,% "Processing " cardObj["name"] " (" (a_index / identObj.count() * 100) "%" ")"
	
	;---------------------------
	;XML Creator - Flesh and Blood.ahk
	;---------------------------
	;[] => 1
	;[action] => 1
	;[attack] => 1
	;[defense] => 1
	;[equipment] => 1
	;[hero] => 1
	;[instant] => 1
	;[mentor] => 1
	;[resource] => 1
	;[token] => 1
	;[weapon] => 1
	
	;---------------------------
	;OK   
	;---------------------------
	;nameColor := (cardObj["type"]!="action"?"":" [" StringUpper(RegExMatchGlobal(cardObj["identifier"],"^.+-(\w+)$",0)[1,1],"T") "]")
	;if !IfContains(nameColor,"red,yellow,blue")	;cards without additional variants don't have the color in the identifier
		;nameColor := ""
	if (cardObj["stats","resource"] != "")
		nameColor := " [" pitchColorArr[cardObj["stats","resource"]] "]"
	else
		nameColor := ""
	
	cxml.newCardEntity(cardObj["name"] nameColor)
	;msgbox % cardObj["name"] nameColor "`n" cardObj["stats","resource"]
	
	cxml.setMajorCardProp("text",m2h(cardObj["text"]))
	cxml.setCardProp("identifier",cardObj["identifier"])
	
	;msgbox % m2h(cardObj["text"])
	;msgbox % cxml.getMajorCardProp("text")
	;building the type line
	subprop := 1
	for k,v in cardObj["keywords"]{ ;*[XML Creator - Flesh and Blood]
		switch v {
			case cardObj["talent"]:{
				cxml.setCardProp("talent", StringUpper(cardObj["talent"],"T")) 
				cxml.appendCardProp("Type", StringUpper(cardObj["talent"],"T") " ")
			}
			case cardObj["class"]:{
				cxml.setCardProp("class", StringUpper(cardObj["class"],"T"))
				cxml.appendCardProp("type", StringUpper(cardObj["class"],"T") " ")
			}
			case cardObj["type"]:{
				cxml.setCardProp("Maintype", StringUpper(cardObj["type"],"T"))
				cxml.appendCardProp("type", StringUpper(cardObj["type"],"T"))
			}
			case cardObj["subtype"]:{
				cxml.setCardProp("subtype", StringUpper(cardObj["subtype"],"T"))
				cxml.appendCardProp("type", " - " StringUpper(cardObj["subtype"],"T"))
				
			}
			Default:{
				subprop += 1
				if regexmatch(v,"i)\d+h")
					subv := "(" StringUpper(v) ")"	;wraps (1H) & (2H) properties
				else
					subv := StringUpper(v,"T")
				cxml.setCardProp("subtype " subprop, subv)
				cxml.appendCardProp("type", " " subv)
			}
		}
	}
	match := RegExMatchGlobal(cardObj["text"],"\[(?>([+-])?(\w+)? ?)?(\w+)\]",0)
	;if (match.count() > 0)
		;msgbox % st_printArr(match)
	for k,v in match{
		;msgbox % v[1]
		classObj[v[3]] := cardObj["name"]
	}
	;For k,v in cardObj["printings"]{
		;msgbox % v["finish"]
		;classObj[v["finish"]] := cardObj["identifier"]
	;}
	
	for k,v in cardObj["stats"]{
		/*
			---------------------------
			XML Creator - Flesh and Blood.ahk
			---------------------------
			[attack] => 1
			[cost] => 1
			[defense] => 1
			[intellect] => 1
			[life] => 1
			[resource] => 1
			
			---------------------------
			OK   
			---------------------------
		*/
			;classObj[k] := 1
	}
	;cxml.newCardEntity(record["name"])
	;cxml.setCardProp("colors",(record["attribute"]!=""?record["attribute"]:"NORMAL"))
	;cxml.setCardProp("cmc",(record.HasKey("level")?record["level"]:0)) ;set to 0 if no level found
	;cxml.setCardProp("ID",record["id"])
	;cxml.setCardProp("Type",record["type"])
	;cxml.setCardProp("Race",record["race"])
	;cxml.setCardProp("Archetype",record["archetype"])
	;cxml.setCardProp("Konami_ID",record["misc_info",1,"konami_id"])
			
	;For k,v in cardObj["printings"]
	;cxml.newSetEntity(record["set_code"])
	;cxml.setSetProp("releasedate",record["tcg_date"])
	;cxml.setSetProp("longname",record["set_name"])
			
			}
			
			GuiControl, , text2,% "Generating XML"
			cardObj.delete("listings")
			msgbox % clipboard := st_printarr(classObj,10)
			ExitApp
			
			
			
markdown2html(markdown){
	output := markdown
	/*
	; inline code
		While RegExMatch(output, "``(.+?)``", &match) {
			output := StrReplace(output, match[0], "<code>" ltgt(match[1]) "</code>",,1)
		}
	*/
	
	/*
        ; image
		r := 1
		While (s := RegExMatch(output, "!\x5B *([^\x5D]*) *\x5D\x28 *([^\x29]+) *\x29(\x28 *[^\x29]* *\x29)?", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			dims := Trim(match[3],"()")
			output := StrReplace(output, match[0], "<img src=""" match[2] "" (dims?" " dims:"")
                    . "' alt=""" ltgt(match[1]) """ title=""" ltgt(match[1]) """>",,1)
		}
	*/
	
	/*
        ; link / url
		r := 1
		While (s := RegExMatch(output, "\x5B *([^\x5D]+) *\x5D\x28 *([^\x29]+) *\x29", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<a href=""" match[2] """ target=" _blank " rel=" noopener noreferrer ">"
                    . match[1] "</a>",,1)
		}
	*/
	
	/*
	;strong + emphesis (bold + italics)
		While (s := RegExMatch(output, "**only__ have 1 Eye of Ophidia in your deck.)*
			
		When you __pitch__ Eye of Ophi**", &match, r))
           || (s := RegExMatch(output, "(?<!\w)[\_]{3,3}([^\_]+)[\_]{3,3}", &match, r)) {
		If IsInCode(match[0], output) || IsInTag(match[0], output) {
			r := s + match.Len(0)
			Continue
		}
		output := StrReplace(output, match[0], "<em><strong>" ltgt(match[1]) "</strong></em>",,1)
	}
	*/
	;bold and italics
	biCheck := RegExMatchGlobal(output,"(?<!\w)([\_\*]{3,3}([^\_\*]+)[\_\*]{3,3})",0)	
	for k,v in biCheck {
		output := StrReplace(output,v[1],"<b><i>" v[2] "</i></b>")
	}
	
     ;bold
	
	;boldCheck := RegExMatchGlobal(output,"(?<!\w)([\_\*]{2,2}([^\_\*]+)[\_\*]{2,2})",0)	
	
	loop{
		boldCheck := RegExMatchGlobal(output,"(?<!\w)([\_\*]{2}([^\_\*]+)[\_\*]{2})",0)
		for k,v in boldCheck {
			output := StrReplace(output,v[1],"<b>" v[2] "</b>")
		}
	} until !boldCheck.count()
	
	;msgbox % output
	;italics
	;italicCheck := RegExMatchGlobal(output,"(?<!\w)([\_\*]{1,1}([^\_\*]+)[\_\*]{1,1})",0)
	loop{
		italicCheck := RegExMatchGlobal(output,"(?<!\w)([\_\*]{1}([^\_\*]+)[\_\*]{1})",0)
		for k,v in italicCheck {
			output := StrReplace(output,v[1],"<i>" v[2] "</i>")
		}
	} until !italicCheck.count()
	
	
	;msgbox % output
	return output
	While (s := RegExMatch(output, "(?<!\w)[\_\*]{2,2}([^\_\*]+)[\_\*]{2,2}", &match, r)){
		;If IsInCode(match[0], output) || IsInTag(match[0], output) {
			;r := s + match.Len(0)
			;Continue
		;}
		output := StrReplace(output, match[0], "<strong>" ltgt(match[1]) "</strong>",,1)
	}
	
	/*
        ; emphesis (italics)
		While (s := RegExMatch(output, "(?<!\w)[\*]{1,1}([^\*]+)[\*]{1,1}", &match, r))
           || (s := RegExMatch(output, "(?<!\w)[\_]{1,1}([^\_]+)[\_]{1,1}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<em>" ltgt(match[1]) "</em>",,1)
		}
		
        ; strikethrough
		While (s := RegExMatch(output, "(?<!\w)~{2,2}([^~]+)~{2,2}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<del>" ltgt(match[1]) "</del>",,1)
		}
	*/
	

	return output
}

m2h(ByRef markdown){
	return markdown2html(markdown)
}


make_html(_in_text, options:="", github:=false, final:=true, md_type:="") {
	
	If !RegExMatch(_in_text,"[`r`n]+$") && (final) && md_type!="header" { ; add trailing CRLF if doesn't exist
		_in_text .= "`r`n"
	}
	
	html1 := "<html><head><style>`r`n"
	html2 := "`r`n</style></head>`r`n`r`n<body>"
	toc_html1 := "<div id=""toc-container"">"
               . "<div id=""toc-icon"" align=""right"">&#9776;</div>"
               . "<div id=""toc-contents"">"
	toc_html2 := "</div></div>" ; end toc-container and toc-contents
	html3 := "<div id=""body-container""><div id=""main"">`r`n" ; <div id=" q "body-container" q ">
	html4 := "</div></div></body></html>" ; </div>
	
	body := ""
	toc := [], do_toc := false
	do_nav := false, nav_arr := []
	
	table_done := false
	
	If (final)
		css := options.css
	
	a := StrSplit(_in_text,"`n","`r")
	i := 0
	
	While (i < a.Length) {                                          ; ( ) \x28 \x29
		i++, line := a[i]                                           ; [ ] \x5B \x5D
		blockquote := "", ul := "", ul2 := "", code_block := ""     ; { } \x7B \x7D
		ol := "", ol2 := "", ol_type := ""
		table := ""
		
		If final && RegExMatch(line, "^<nav\|") && a.Has(i+1) && (a[i+1] = "") {
			do_nav := True
			nav_arr := StrSplit(Trim(line,"<>"),"|")
			nav_arr.RemoveAt(1)
			Continue
		}
		
		If (final && line = "<toc>") {
			do_toc := True
			Continue
		}
		
        ; header h1 - h6
		If RegExMatch(line, "^(#+) (.+)", &match) {
            ; dbg("HEADER H1-H6")
			
			depth := match[1], _class := "", title := ltgt(match[2])
			
			If RegExMatch(line, "\x5B *([\w ]+) *\x5D$", &_match)
				_class := _match[1], title := SubStr(title, 1, StrLen(match[2]) - _match.Len(0))
			
			If (github && (match.Len(1) = 1 || match.Len(1) = 2))
				_class := "underline"
			
			id := RegExReplace(RegExReplace(StringLower(title),"[\[\]\{\}\(\)\@\!]",""),"[ \.]","-")
			opener := "<h" match.Len(1) (id?" id="" id "" ":"") (_class?" class="" _class """:"") ">"
			
			body .= (body?"`r`n":"") opener Trim(make_html(title,,github,false,"header"),"`r`n")
            ; body .= (body?"`r`n":"") opener title
                  . "<a href=""# id ""><span class=""link"">•</span></a>"
                  . "</h" match.Len(1) ">"
			
			toc.Push([StrLen(depth), title, id])
			Continue
		}
		
        ; spoiler
		If RegExMatch(line, "^<spoiler=([^>]+)>$", &match) {
			disp_text := ltgt(match[1])
			spoiler_text := ""
			i++, line := a[i]
			While !RegExMatch(line, "^</spoiler>$") {
				spoiler_text .= (spoiler_text?"`r`n":"") line
				i++, line := a[i]
			}
			
			body .= (body?"`r`n":"") "<p><details><summary class=""spoiler"">"
                  . disp_text "</summary>" make_html(spoiler_text,,github,false,"spoiler") "</details></p>"
			Continue
		}
		
        ; hr
		If RegExMatch(line, "^([=\-\*_ ]{3,}[=\-\*_ ]*)(?:\x5B *[^\x5D]* *\x5D)?$", &match) {
            ; dbg("HR: " line)
			
			hr_style := ""
			
			If Trim(line)=""
				Continue
			
			If (github && SubStr(match[1],1,1) = "=")
				Continue
			
			If RegExMatch(line, "\x5B *([^\x5D]*) *\x5D", &match) {
				hr_str := match[1]
				arr := StrSplit(hr_str," ")
				
				For i, style in arr {
					If (SubStr(style, -2) = "px")
						hr_style .= (hr_style?" ":"") "border-top-width: " style ";"
					Else If RegExMatch(style, "(dotted|dashed|solid|double|groove|ridge|inset|outset|none|hidden)")
						hr_style .= (hr_style?" ":"") "border-top-style: " style ";"
					Else
						hr_style .= (hr_style?" ":"") "border-top-color: " style ";"
				}
			}
			body .= (body?"`r`n":"") "<hr style="" hr_style "">"
			Continue
		}
		
        ; blockquote - must come earlier because of nested elements
		While RegExMatch(line, "^\> ?(.*)", &match) {
            ; dbg("BLOCKQUOTE 1")
			
			blockquote .= (blockquote?"`r`n":"") match[1]
			
			If a.Has(i+1)
				i++, line := Trim(a[i]," `t")
			Else
				Break
		}
		
		If (blockquote) {
            ; dbg("BLOCKQUOTE 2")
			
			body .= (body?"`r`n":"") "<blockquote>" make_html(blockquote,,github, false, "blockquote") "</blockquote>"
			Continue
		}
		
        ; code block
		If (line = "``````") {
            ; dbg("CODEBLOCK")
			
			If (i < a.Length)
				i++, line := a[i]
			Else
				Break
			
			While (line != "``````") {
				code_block .= (code_block?"`r`n":"") line
				If (i < a.Length)
					i++, line := a[i]
				Else
					Break
			}
			
			body .= (body?"`r`n":"") "<pre><code>" StrReplace(StrReplace(code_block,"<","&lt;"),">","&gt;") "</code></pre>"
			Continue
		}
		
        ; table
		While RegExMatch(line, "^\|.*?\|$") {
            ; dbg("TABLE 1")
			
			table .= (table?"`r`n":"") line
			
			If a.Has(i+1)
				i++, line := a[i]
			Else
				Break
		}
		
		If (table) {
            ; dbg("TABLE 2")
			
			table_done := true
			
			body .= (body?"`r`n":"") "<table class=""normal"">"
			b := [], h := [], t := " `t"
			
			Loop, Parse, table, "`n", "`r"
			{
				body .= "<tr>"
				c := StrSplit(A_LoopField,"|"), c.RemoveAt(1), c.RemoveAt(c.Length)
				
				If (A_Index = 1) {
					align := ""
					Loop c.Length {
						If RegExMatch(Trim(c[A_Index],t), "^:(.+?)(?<!\\):$", &match) {
							m := StrReplace(inline_code(match[1]),"\:",":")
							h.Push(["center",m])
						} Else If RegExMatch(Trim(c[A_Index],t), "^([^:].+?)(?<!\\):$", &match) {
							m := StrReplace(inline_code(match[1]),"\:",":")
							h.Push(["right",m])
						} Else If RegExMatch(Trim(c[A_Index],t), "^:(.+)", &match) {
							m := StrReplace(inline_code(match[1]),"\:",":")
							h.Push(["left",m])
						} Else {
							m := StrReplace(inline_code(Trim(c[A_Index],t)),"\:",":")
							h.Push(["",m])
						}
					}
				} Else If (A_Index = 2) {
					Loop c.Length {
						If RegExMatch(c[A_Index], "^:\-+:$", &match)
							b.Push(align:="center")
						Else If RegExMatch(c[A_Index], "^\-+:$", &match)
							b.Push(align:="right")
						Else
							b.Push(align:="left")
						If (!h[A_Index][1])
							h[A_Index][1] := align
						body .= "<th align=" h[A_Index][1] ">" h[A_Index][2] "</th>"
					}
				} Else {
					Loop c.Length {
						m := inline_code(c[A_Index]) ; make_html(c[A_Index],, false, "table data")
						body .= "<td align=" b[A_Index]  ">" Trim(m," `t") "</td>"
					}
				}
				body .= "</tr>"
			}
			body .= "</table>"
			Continue
		}
		
        ; unordered lists
		If RegExMatch(line, "^( *)[\*\+\-] (.+?)(\\?)$", &match) {
			
            ; dbg("UNORDERED LISTS")
			
			While RegExMatch(line, "^( *)([\*\+\-] )?(.+?)(\\?)$", &match) { ; previous IF ensures first iteration is a list item
				ul2 := ""
				
				If !match[1] && match[2] && match[3] {
					ul .= (ul?"</li>`r`n":"") "<li>" make_html(match[3],,github,false,"ul item")
					
					If match[4]
						ul .= "<br>"
					
					If (i < a.Length)
						i++, line := a[i]
					Else
						Break
					
					Continue
					
				} Else If !match[2] && match[3] {
					ul .= make_html(match[3],,github,false,"ul item append")
					
					If match[4]
						ul .= "<br>"
					
					If (i < a.Length)
						i++, line := a[i]
					Else
						Break
					
					Continue
					
				} Else If match[1] && match[3] {
					
					While RegExMatch(line, "^( *)([\*\+\-] )?(.+?)(\\?)$", &match) {
						If (Mod(StrLen(match[1]),2) || !match[1] || !match[3])
							Break
						
						ul2 .= (ul2?"`r`n":"") SubStr(line, 3)
						
						If (i < a.Length)
							i++, line := a[i]
						Else {
							line := ""
							Break
						}
					}
					
					ul .= "`r`n" make_html(ul2,,github,false,"ul")
					Continue
				}
				
				If (i < a.Length)
					i++, line := a[i]
				Else
					Break
			}
		}
		
		If (ul) {
			body .= (body?"`r`n":"") "<ul>`r`n" ul "</li></ul>`r`n"
			Continue
		}
		
        ; ordered lists
		If RegExMatch(line, "^( *)[\dA-Za-z]+(?:\.|\x29) +(.+?)(\\?)$", &match) {
			
            ; dbg("ORDERED LISTS")
			
			While RegExMatch(line, "^( *)([\dA-Za-z]+(?:\.|\x29) )?(.+?)(\\?)$", &match) { ; previous IF ensures first iteration is a list item
				ol2 := ""
				
				If !match[1] && match[2] && match[3] {
					ol .= (ol?"</li>`r`n":"") "<li>" make_html(match[3],,github,false,"ol item")
					
					If (A_Index = 1)
						ol_type := "type=" RegExReplace(match[2], "[\.\) ]","") ""
					
					If match[4]
						ol .= "<br>"
					
					If (i < a.Length)
						i++, line := a[i]
					Else
						Break
					
					Continue
					
				} Else If !match[2] && match[3] {
					ol .= make_html(match[3],,github,false,"ol item append")
					
					If match[4]
						ol .= "<br>"
					
					If (i < a.Length)
						i++, line := a[i]
					Else
						Break
					
					Continue
					
				} Else If match[1] && match[3] {
					
					While RegExMatch(line, "^( *)([\dA-Za-z]+(?:\.|\x29) )?(.+?)(\\?)$", &match) {
						If (Mod(StrLen(match[1]),2) || !match[1] || !match[3])
							Break
						
						ol2 .= (ol2?"`r`n":"") SubStr(line, 3)
						
						If (i < a.Length)
							i++, line := a[i]
						Else {
							line := ""
							Break
						}
					}
					
					ol .= "`r`n" make_html(ol2,,github,false,"ol")
					Continue
				}
				
				If (i < a.Length)
					i++, line := a[i]
				Else
					Break
			}
		}
		
		If (ol) {
			body .= (body?"`r`n":"") "<ol " ol_type ">`r`n" ol "</li></ol>`r`n"
			Continue
		}
		
        ; =======================================================================
        ; ...
        ; =======================================================================
		
		If RegExMatch(md_type,"^(ol|ul)") { ; ordered/unordered lists
			body .= (body?"`r`n":"") inline_code(line)
			Continue
		} Else If RegExMatch(line, "^(<nav|<toc)") { ; nav toc
			Continue
		} Else If RegExMatch(line, "\\$") { ; manual line break at end \
			body .= (body?"`r`n":"") "<p>"
			reps := 0
			
			While RegExMatch(line, "(.+)\\$", &match) {
				reps++
				body .= ((A_Index>1)?"<br>":"") inline_code(match[1])
				
				If (i < a.Length)
					i++, line := a[i]
				Else
					Break
			}
			
			If line
				body .= (reps?"<br>":"") inline_code(line) "</p>"
			Else
				body .= "</p>"
		} Else If line {
			If md_type != "header"
				body .= (body?"`r`n":"") "<p>" inline_code(line) "</p>"
			Else
				body .= (body?"`r`n":"") inline_code(line)
		}
	}
	
    ; processing toc ; try to process exact height
	final_toc := "", toc_width := 0, toc_height := 0
	If (Final && do_toc) {
		;temp := Gui()
		temp.SetFont("s" options.font_size, options.font_name)
		
		depth := toc[1][1]
		diff := (depth > 1) ? depth - 1 : 0
		indent := "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
		
		For i, item in toc { ; 1=depth, 2=title, 3=id
			depth := item[1] - diff - 1
			
			ctl := temp.Add("Text",, rpt("     ",depth) "• " item[2])
			ctl.GetPos(,,&w, &h)
			toc_width := (w > toc_width) ? w : toc_width
			toc_height += options.font_size * 2
			
			final_toc .= (final_toc?"`r`n":"") "<a href=""#" item[3] """>"
                       . "<div class=""toc-item"">" (depth?rpt(indent,depth):"")
                       . "• " ltgt(item[2]) "</div></a>"
		}
		
		temp.Destroy()
	}
	
    ; processing navigation menu
	nav_str := ""
	If (final && do_nav) {
		;temp := Gui()
		temp.SetFont("s" options.font_size, options.font_name)
		
		Loop nav_arr.Length {
			title := SubStr((txt := nav_arr[A_Index]), 1, (sep := InStr(txt, "=")) - 1)
			
			ctl := temp.Add("Text",,title)
			ctl.GetPos(,,&w)
			toc_width := (w > toc_width) ? w : toc_width
			toc_height += options.font_size * 2
			
			nav_str .= (final_toc?"`r`n":"") "<a href=""" SubStr(txt, sep+1) """ target=""" _blank """ rel=""" noopener noreferrer """>"
                       . "<div class=""toc-item"">" title "</div></a>"
		}
		
		(do_toc) ? nav_str .= "<hr>" : ""
		temp.Destroy()
	}
	
    ; processing TOC
	user_menu := ""
	If Final && (do_nav || do_toc)
		user_menu := toc_html1 nav_str final_toc toc_html2
	
	If final {
		If (do_nav && do_toc)
			toc_height += Round(options.font_size * 1.6) ; multiply by body line-height
		
		css := StrReplace(css, "[_toc_width_]",toc_width + 25) ; account for scrollbar width
		css := StrReplace(css, "[_toc_height_]",toc_height)
		css := StrReplace(css, "[_font_name_]", options.font_name)
		css := StrReplace(css, "[_font_size_]", options.font_size)
		css := StrReplace(css, "[_font_weight_]", options.font_weight)
		
		If (do_toc || do_nav)
			result := html1 . css . html2 . user_menu . html3 . body . html4
		Else
			result := html1 . css . html2 . html3 . body . html4
	} Else
		result := body
	
	return result
	
    ; =======================================================================
    ; Local Functions
    ; =======================================================================
	
	
}


inline_code(_in) {
		output := _in
		
        ; inline code
		While RegExMatch(output, "``(.+?)``", &match) {
			output := StrReplace(output, match[0], "<code>" ltgt(match[1]) "</code>",,1)
		}
		
        ; image
		r := 1
		While (s := RegExMatch(output, "!\x5B *([^\x5D]*) *\x5D\x28 *([^\x29]+) *\x29(\x28 *[^\x29]* *\x29)?", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			dims := Trim(match[3],"()")
			output := StrReplace(output, match[0], "<img src=""" match[2] "" (dims?" " dims:"")
                    . "' alt=""" ltgt(match[1]) """ title=""" ltgt(match[1]) """>",,1)
		}
		
        ; link / url
		r := 1
		While (s := RegExMatch(output, "\x5B *([^\x5D]+) *\x5D\x28 *([^\x29]+) *\x29", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<a href=""" match[2] """ target=" _blank " rel=" noopener noreferrer ">"
                    . match[1] "</a>",,1)
		}
		
        ; strong + emphesis (bold + italics)
		While (s := RegExMatch(output, "(?<!\w)[\*]{3,3}([^\*]+)[\*]{3,3}", &match, r))
           || (s := RegExMatch(output, "(?<!\w)[\_]{3,3}([^\_]+)[\_]{3,3}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<em><strong>" ltgt(match[1]) "</strong></em>",,1)
		}
		
        ; strong (bold)
		While (s := RegExMatch(output, "(?<!\w)[\*]{2,2}([^\*]+)[\*]{2,2}", &match, r))
           || (s := RegExMatch(output, "(?<!\w)[\_]{2,2}([^\_]+)[\_]{2,2}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<strong>" ltgt(match[1]) "</strong>",,1)
		}
		
        ; emphesis (italics)
		While (s := RegExMatch(output, "(?<!\w)[\*]{1,1}([^\*]+)[\*]{1,1}", &match, r))
           || (s := RegExMatch(output, "(?<!\w)[\_]{1,1}([^\_]+)[\_]{1,1}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<em>" ltgt(match[1]) "</em>",,1)
		}
		
        ; strikethrough
		While (s := RegExMatch(output, "(?<!\w)~{2,2}([^~]+)~{2,2}", &match, r)) {
			If IsInCode(match[0], output) || IsInTag(match[0], output) {
				r := s + match.Len(0)
				Continue
			}
			output := StrReplace(output, match[0], "<del>" ltgt(match[1]) "</del>",,1)
		}
		
		return output
	}
	
	ltgt(_in) {
		return StrReplace(StrReplace(_in,"<","&lt;"),">","&gt;")
	}
	
	rpt(_in, reps) {
		final_str := ""         ; Had to change "final" var to "final_str".
		Loop reps               ; This may still be a bug in a133...
			final_str .= _in
		return final_str
	}
	
	IsInTag(needle, haystack) {
		start := InStr(haystack, needle) + StrLen(needle)
		sub_str := SubStr(haystack, start)
		
		tag_start := InStr(sub_str,"<")
		tag_end := InStr(sub_str,">")
		
		If (!tag_start && tag_end) Or (tag_end < tag_start)
			return true
		Else
			return false
	}
	
	IsInCode(needle, haystack) {
		start := InStr(haystack, needle) + StrLen(needle)
		sub_str := SubStr(haystack, start)
		
		code_start := InStr(sub_str,"<code>")
		code_end := InStr(sub_str,"</code>")
		
		If (!code_start && code_end) Or (code_end < code_start)
			return true
		Else
			return false
	}