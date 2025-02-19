#Requires AutoHotkey v2.0
#Include lib\CockatriceXMLCreator.ahk
cxml := CockatriceXMLCreator("Pokemon")
api := apiQache()
api.initExpiry(86400)

cxml.gtext(2,"Gathering energy types...")
;get energy types
energyObj := JSON.load(api.retrieve("https://api.pokemontcg.io/v2/types"))["data"]

cxml.gtext(2,"Gathering sets...")
loop {	;get the sets
	massSetObj := JSON.load(api.retrieve("https://api.pokemontcg.io/v2/sets?&page=" a_index))
	for k,v in massSetObj["data"]{
		record := v
		cxml.newSetEntity(record["id"])
        cxml.setSetProp("name",StrUpper(record["id"]))
		cxml.setSetProp("releasedate",record["releaseDate"])
		cxml.setSetProp("longname",record["name"])
		cxml.setSetProp("settype",record["series"])
	}
	if (massSetObj["count"] = 0)	;no cards served, so we're at the end of the list.
		break
}

;sorting the cards by release date and id so the uniqified card's name is the same across db updates
sortedCardObj := Map()
cxml.gtext(2,"Gathering cards...")
overallCount := 0
loop {
    url := "https://api.pokemontcg.io/v2/cards?&page=" a_index ;"&orderBy=releaseDate,id"
	massCardObj := JSON.load(api.retrieve(url))
    tc := massCardObj["totalCount"]
    ps := massCardObj["pageSize"] 
    cxml.gtext(3,"Page " a_index " / " (Ceil(tc/ps)+1))
    ; Obj_Gui(massCardObj)

	if (massCardObj["count"] = 0)	;no cards served, so we're at the end of the list.
		break

	for k,v in massCardObj["data"] {
        index := sortedCardObj.count + a_index
        record := v
        releaseDate := record["set"]["releaseDate"]
        ; if !sortedCardObj.Has(releaseDate)
        sortedCardObj[releaseDate] ??= Map()
        sortedCardObj[releaseDate][sortedCardObj[releaseDate].count + 1] := record
        overallCount += 1
        ; Obj_Gui(v)
        ; MsgBox
		; pushVal := (sortedCardObj[massCardObj["data"][k]["set"]["releaseDate"]].count() + 1)
		; if (pushVal = "")
	; 		pushVal = 1
	; 	;msgbox % massCardObj["data",k,"set","releaseDate"]
	; 	sortedCardObj[massCardObj["data"][k]["set"]["releaseDate"]][pushVal] := v
	}
    ; if (api.lastServedSource = "server")
	; 	sleep(100)	;keep from hammering the server
}

;list of properties to compare against when deduping
dupelist := ["name","attacks","weaknesses","resistances","retreatCost","abilities","ancientTrait","rules"]
deduped := Map()
cxml.gtext(1,"Scraping card data for...")
outpics := ""
cardIndex := 0
for k,v in sortedCardObj{
    dateObj := v
    for k,v in dateObj {
        cardIndex += 1
        record := v
        cxml.gtext(2,record["name"])
        cxml.gtext(3,cardIndex " / " overallCount)
        for k,v in ["cardmarket","tcgplayer"]
            record[v] := unset

   		;Have to gather some de-dupe information before actually adding the card to the xml
        dupeChk := Map()
        for k,v in dupelist
            try dupeChk[v] := record[v] 
        cardHash := cxml.uniqify(dupeChk)
        
        ; Obj_Gui(record)
        ; MsgBox
        ;by entering the cardHash as the entity name we can safely roll over the rest of the data without fear of overwriting data during XML generation. If we DO end up overwriting cards then just add more uniqify variables until we don't.
        ;notably, we are *not* setting the name until later
		cxml.newCardEntity(cardHash)	;newCardEntity() doesn't overwrite
		cxml.changeCardEntity(cardHash)	;must set manually due to not making a new cardEntity each time
		
        setObj := Map()
        setId := StrUpper(record["set"]["id"])
        try setObj["rarity"] := record["rarity"]
        setObj["num"] := record["number"]

        ;images can be attached to real sets thanks to cockatrice improvements
        try setObj["picURL"] := record["images"]["large"] ;unconditionally set
        setObj["picURL"] ??= record["images"]["small"]    ;use small if large not found
        setObj["uuid"] := api.hash(&f := "Pokemon" record["id"],"SHA512")
        
        cxml.attachSetToCard(setId,setObj)

		if deduped.has(cardHash)
			Continue	;nothing further to do with a duped card now that we found the sets
        
        ;have to set the name to something sensible
        cxml.setMajorCardProp("name",record["name"] a_space StrUpper(record["id"]))

        ;track the deduped name
		deduped[cardHash] := cxml.getMajorCardProp("name")

        ;process card data as normal.
		cxml.setCardProp("maintype",record["supertype"])
		; cxml.setCardProp("colors", st_glue(record["types"," "]))
		; cxml.setCardProp("pt",record["hp"])
        cxml.setMajorCardProp("text","placeholder")
    }
}
; msgbox overallCount "`n" deduped.count
cxml.generateXML()
; Sleep(3000)
ExitApp


; procCard(cardObj){

; }

; Created by AHK_user 2022-04-30
; Based on V1 Array_Gui by Geekdude
; https://www.autohotkey.com/boards/viewtopic.php?t=35124
#Requires AutoHotKey v2.0-beta.3
#SingleInstance force

;; Example code to demonstate
; oarray:= [{Apples: ["Red", "Crunchy", "Lumpy"], Oranges: ["Orange", "Squishy", "Spherical"] },"Test",{test:1},["1","bleu"],Map("sdfs",2,"sdd",{test:5,name:10},"objectExample",["1","3","4"])]
; oarray.prop1 := "test"
; Obj_Gui(oarray)

; myGui := Gui()
; ogcTreeView := myGui.AddTreeView("w300 h200")
; myGui.AddText(,"test")
; myGui.Show()
; Obj_Gui(myGui)

; Example EditGui
; atest := ["test", "tast", 2, 3]
; aTest := EditGui(aTest)

; Displays the content of the variable
Obj_Gui(Array, ParentID := "") {
    static ogcTreeView
    if !ParentID{
        myGui := Gui()
        myGui.Opt("+Resize")
        myGui.OnEvent("Size", Gui_Size)
        myGui.MarginX := "0", myGui.MarginY := "0"
        if (IsObject(Array)){
            ogcTreeView := myGui.AddTreeView("w300 h300")
            ogcTreeView.OnEvent("ContextMenu", ContextMenu_TreeView)
            ItemID := ogcTreeView.Add("(" type(Array) ")", 0, "+Expand")
            Obj_Gui(Array, ItemID)
        }
        else{
            ogcEdit := myGui.AddEdit("w300 h200 +multi", Array)
        }
        myGui.Title := "Gui (" Type(Array) ")" 

        ;Reload menu for testing
        ; Menus := MenuBar()
        ; Menus.Add("&Reload", (*) => (Reload()))
        ; myGui.MenuBar := Menus

        myGui.Show()
        return
    }
    if (type(Array)="Array"){
        For Key, Value in Array{
            if (IsObject(Value)){
                ItemID := ogcTreeView.Add("[" Key "] (" type(Value) ")", ParentID, "Expand")
                Obj_Gui(Value, ItemID)
            }   
            else{
                ogcTreeView.Add("[" Key "] (" type(Value) ")  =  " Value, ParentID, "Expand")
            }  
        }
    }
    if (type(Array) = "Map") {
        For Key, Value in Array {
            if (IsObject(Value)) {
                ItemID := ogcTreeView.Add('["' Key '"] (' type(Value) ')', ParentID, "Expand")
                Obj_Gui(Value, ItemID)
            } else {
                ogcTreeView.Add('["' Key '"] (' type(Value) ')  =  ' Value, ParentID, "Expand")
            }
        }
        aMethods := ["Count", "Capacity", "CaseSense", "Default", "__Item"]
        for index, PropName in aMethods {
            try ogcTreeView.Add("." PropName " (" type(Array.%PropName%) ")  =  " Array.%PropName%, ParentID, "Expand")
        }

    }
    try{
        For PropName, PropValue in Array.OwnProps(){
            if (IsObject(PropValue)){
                ItemID := ogcTreeView.Add("." PropName " (" type(PropValue) ")", ParentID, "Expand")
                Obj_Gui(PropValue, ItemID)
            }    
            else{
                ogcTreeView.Add("." PropName " (" type(PropValue) ")  =  " PropValue, ParentID, "Expand")
            } 
        }
    }
    if (type(Array) = "Func"){
        aMethods := ["Name", "IsBuiltIn", "IsVariadic", "MinParams", "MaxParams"]
        for index, PropName in aMethods{
            ogcTreeView.Add("." PropName " (" type(Array.%PropName%) ")  =  " Array.%PropName%, ParentID, "Expand")
        }
    }
    if (type(Array) = "Buffer"){
        aMethods := ["Prt","Size"]
        for index, PropName in aMethods{
            try ogcTreeView.Add("." PropName " (" type(Array.%PropName%) ")  =  " Array.%PropName%, ParentID, "Expand")
        }
    }
    if (type(Array) = "Gui"){
        aMethods := ["BackColor", "FocusedControl", "Hwnd", "MarginX", "MarginY", "Name", "Title"]
        for index, PropName in aMethods{
            try ogcTreeView.Add("." PropName " (" type(Array.%PropName%) ")  =  " Array.%PropName%, ParentID, "Expand")
        }
        For Hwnd, oCtrl in Array{
            ItemID := ogcTreeView.Add("__Enum[" Hwnd "] (" Type(oCtrl) ")", ParentID, "Expand")
            Obj_Gui(oCtrl, ItemID)
        }
    }
    if (SubStr(type(Array),1,4)="Gui."){
        aMethods := ["ClassNN", "Enabled", "Focused", "Hwnd", "Name", "Text", "Type", "Value", "Visible"]
        for index, PropName in aMethods {
            try ogcTreeView.Add("." PropName " (" type(Array.%PropName%) ")  =  " Array.%PropName%, ParentID, "Expand")
        }
        ogcTreeView.Add(".Gui (Gui)", ParentID, "Expand")
    }

    return

    Gui_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        For Hwnd, GuiCtrlObj in thisGui {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , Width - cX, Height -cY)
        }
        DllCall("LockWindowUpdate", "Uint", 0)
    }

    ContextMenu_TreeView(GuiCtrlObj , Item, IsRightClick, X, Y){
        SelectedItemID := GuiCtrlObj.GetSelection()
        RetrievedText := GuiCtrlObj.GetText(SelectedItemID)
        Value := RegExReplace(RetrievedText,".*?\)\s\s=\s\s(.*)","$1")
        ItemID := SelectedItemID
        
        ParentText := ""
        ParentItemID := ItemID
        loop{
            if (ParentItemID=0){
                break
            }
            RetrievedParentText := GuiCtrlObj.GetText(ParentItemID)
            ParentText := RegExReplace(RetrievedParentText, "(.*?)\s.*", "$1") ParentText
            ParentItemID := GuiCtrlObj.GetParent(ParentItemID)
        }

        Menu_TV := Menu()
        if(InStr(RetrievedText, ")  =  ")){
            Menu_TV.Add("Copy [" Value "]",(*)=>(A_Clipboard:= Value, Tooltip2("Copied [" Value "]")))
            Menu_TV.SetIcon("Copy [" Value "]", "Shell32.dll", 135)
        }
        Menu_TV.Add("Copy [" ParentText "]", (*) => (A_Clipboard := ParentText, Tooltip2("Copied [" ParentText "]")))
        Menu_TV.SetIcon("Copy [" ParentText "]", "Shell32.dll", 135)
        Menu_TV.Show()
    }

    Tooltip2(Text := "", X := "", Y := "", WhichToolTip := "") {
        ToolTip(Text, X, Y, WhichToolTip)
        SetTimer () => ToolTip(), -3000
    }
}
EditGui(Input){
    Output := Input
    Gui_Edit := Gui()
    Gui_Edit.Opt("+Resize")
    Gui_Edit.OnEvent("Size", Gui_Size)
    Gui_Edit.OnEvent("Close", Gui_Close)
    Gui_Edit.MarginX := "0", Gui_Edit.MarginY := "0"
    if (Type(Input)="Array") {
        ogcEdit := Gui_Edit.AddListView("w300 r" Input.Length+2 " -ReadOnly -Sort -Hdr",["Edit"])
        ogcEdit.OnEvent("ContextMenu", LV_ContextMenu)
        for Index, Value in Input{
            ogcEdit.Add(, Value)
        }
        ogcEdit.ModifyCol(1,300-5)
    } else if (!IsObject(Input)){
        ogcEdit := Gui_Edit.AddEdit("w300 h200 +multi", Input)
    } else{
        MsgBox("Input with type [" type(Input) "] is not yet supported.")
        return Input
    }
    Gui_Edit.Title := "Edit Gui (" Type(Input) ")"

    ;Reload menu for testing
    ; Menus := MenuBar()
    ; Menus.Add("&Reload", (*) => (Reload()))
    ; Gui_Edit.MenuBar := Menus

    Gui_Edit.Show()
    HotIfWinActive "ahk_id " Gui_Edit.Hwnd
    Hotkey "Delete", ClearRows
    WinWaitClose(Gui_Edit)
    Hotkey "Delete", "Off"
    return Output

    Gui_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        if (Type(Input) = "Array"){
            ogcEdit.ModifyCol(1, Width - 5)
        }
        For Hwnd, GuiCtrlObj in thisGui {
            GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
            GuiCtrlObj.Move(, , Width - cX, Height - cY)
        }
        DllCall("LockWindowUpdate", "Uint", 0)
    }
    Gui_Close(thisGui){
        if (Type(Input) = "Array"){
            Loop ogcEdit.GetCount()
            {
                Output[A_index] := ogcEdit.GetText(A_Index)
            }
        }
        else{
            Output := ogcEdit.text
        }  
    }
    LV_ContextMenu(LV, Item, IsRightClick, X, Y){
        Rows := LV.GetCount()
        Row := LV.GetNext()
        ContextMenu := Menu()
        ContextMenu.Add("Edit", (*) => (PostMessage(LVM_EDITLABEL := 0x1076, Row - 1, 0, , "ahk_id " LV.hwnd)))
        ContextMenu.SetIcon("Edit","shell32.dll", 134)
        ((Rows = 0 or row=0) && ContextMenu.Disable("Edit"))
        ContextMenu.Add()
        ContextMenu.Add("Insert item", (*)=> (LV.Modify(, "-Select -focus"), LV.Insert(Row, "Select", ""), Output.InsertAt(Row,""),PostMessage(LVM_EDITLABEL := 0x1076, Row-1, 0, , "ahk_id " LV.hwnd)))
        ContextMenu.SetIcon("Insert item", "netshell.dll", 98)
        ((Rows = 0 or row = 0) && ContextMenu.Disable("Insert item"))
        ContextMenu.Add("Insert item below", (*)=> (Row:= LV.GetNext() + 1, LV.Modify(, "-Select -focus"),LV.Insert(Row, "Select", ""), Output.InsertAt(Row, ""),PostMessage(LVM_EDITLABEL := 0x1076, Row - 1, 0, , "ahk_id " LV.hwnd)))
        ContextMenu.SetIcon("Insert item below", "comres.dll", 5)
        ContextMenu.Add()
        ContextMenu.Add("Delete", ClearRows)
        ContextMenu.SetIcon("Delete", "Shell32.dll", 132)
        ((Rows = 0 or row = 0) && ContextMenu.Disable("Delete"))
        ContextMenu.Show()
    }
    ClearRows(*) {
        RowNumber := 0	; This causes the first iteration to start the search at the top.
        Loop {
            RowNumber := ogcEdit.GetNext(RowNumber - 1)
            if not RowNumber	; The above returned zero, so there are no more selected rows.
                break
            ogcEdit.Delete(RowNumber)	; Clear the row from the ListView.
            Output.RemoveAt(RowNumber)
        }
    }
}