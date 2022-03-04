(*
Copyright (c) 2012 Darian Miller
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so, provided that the above copyright notice(s) and this permission notice
appear in all copies of the Software and that both the above copyright notice(s) and this permission notice appear in supporting documentation.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE
LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER
IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other
dealings in this Software without prior written authorization of the copyright holder.

As of January 2016, latest version available online at:
  https://github.com/darianmiller/dxLib


Note: there are plenty of JSON options for Delphi developers.
Recent versions of Delphi include options,
and there are a handful of 3rd party JSON libraries available.
There will be the usual "But...X offers Y" comments.

First response: if you want the best performance, use Synopse and not this class.

Reasons I use this class...you may or may not agree:
- It's usable in Delphi 5 and above
- Before the built-in Delphi classes were available, I've used SuperObject a few times,
  but I really do not like maintaining this style of code. (their provided example code
  helps prove the point)
    X.A['adresses'].O[1].S['adress'] := 'blabla';
    X.A['adresses'].O[1].S['city'] := 'Adana';
    X.A['adresses'].O[1].I['pc'] := 1170;
- When working with established API's, I like building well-defined objects
- I like the ease of adding JSON support to existing Delphi objects
- I wrote it
*)
unit dxLib_JSONObjects;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_String_Is_UTF16}
  Generics.Collections, System.Generics.Defaults,
  {$ENDIF}
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  System.Classes;
  {$ELSE}
  SysUtils,
  Classes;
  {$ENDIF}

type
  //Only Published read/write properties are supported
  //
  //Unsupported property types:
  //  tkRecord
  //  tkArray
  //  tkDynArray
  //  tkInterface
  //  tkMethod
  //Partial support
  //  tkClass: Only TdxJSONObject descendants
  //Only with Delphi 2009+
  //  tkWString: Treated as String
  //  tkWChar: Treated as Char
  TdxJSONObject = class(TPersistent)
  private
    procedure ParseJSON(const aJSON:String);
  protected
    function GetAsJSON():String; virtual;
    procedure SetAsJSON(const aJSON:String); virtual;
  public
    constructor Create(); virtual;

    property AsJSON:String Read GetAsJSON Write SetAsJSON;

    procedure Assign(const aSource:TdxJSONObject); reintroduce;
    procedure Clear(); virtual;
  end;

  TdxJSONObjectClass = class of TdxJSONObject;


  TdxJSONArrayOfObject = class(TdxJSONObject)
  private
    fList:TList;
  protected
    function GetAsJSON():String; override;
    procedure SetAsJSON(const aJSON:String); override;

    procedure ClearList();
    function GetItem(const aIndex:Integer):TdxJSONObject; virtual;
    procedure SetItem(const aIndex:Integer; const aItem:TdxJSONObject); virtual;
  public
    constructor Create(); override;
    destructor Destroy(); override;

    function CreateItem():TdxJSONObject; virtual; abstract;

    function Add(const aItem:TdxJSONObject):Integer; virtual;
    procedure Clear(); override;
    function Count():Integer;
    procedure Delete(const aIndex:Integer);
    procedure Sort(const aSortProc:TListSortCompare);

    property Items[const aIndex:Integer]:TdxJSONObject read GetItem write SetItem; default;
  end;


  TdxJSONArrayOfString = class(TdxJSONObject)
  private
    {$IFDEF DX_String_Is_UTF16}
    fStringList:TList<String>;
    {$ELSE}
    fStringList:TStringList;
    {$ENDIF}
  protected
    function GetAsJSON():String; override;
    procedure SetAsJSON(const aJSON:String); override;

    procedure ClearList();
    function GetItem(const aIndex:Integer):String; virtual;
    procedure SetItem(const aIndex:Integer; const aItem:String); virtual;
  public
    constructor Create(); override;
    destructor Destroy(); override;

    function Add(const aItem:String):Integer; virtual;
    procedure Clear(); override;
    function Count():Integer;
    procedure Delete(const aIndex:Integer);
    {$IFDEF DX_String_Is_UTF16}
    procedure Sort(const AComparer:IComparer<String>);
    {$ELSE}
    procedure Sort(const aSortProc:TStringListSortCompare);
    {$ENDIF}

    property Items[const aIndex:Integer]:String read GetItem write SetItem; default;
  end;


  TdxJSONArrayOfBoolean = class(TdxJSONArrayOfString)
  protected
    function GetAsJSON():String; override;
    function GetItem(const aIndex:Integer):Boolean; reintroduce;
    procedure SetItem(const aIndex:Integer; const aItem:Boolean); reintroduce;
  public
    function Add(const aItem:Boolean):Integer; reintroduce;
    property Items[const aIndex:Integer]:Boolean read GetItem write SetItem;
  end;


  TdxJSONArrayOfCurrency = class(TdxJSONArrayOfString)
  protected
    function GetAsJSON():String; override;
    function GetItem(const aIndex:Integer):Currency; reintroduce;
    procedure SetItem(const aIndex:Integer; const aItem:Currency); reintroduce;
  public
    function Add(const aItem:Currency):Integer; reintroduce;
    property Items[const aIndex:Integer]:Currency read GetItem write SetItem;
  end;


  TdxJSONArrayOfFloat = class(TdxJSONArrayOfString)
  protected
    function GetAsJSON():String; override;
    function GetItem(const aIndex:Integer):Extended; reintroduce;
    procedure SetItem(const aIndex:Integer; const aItem:Extended); reintroduce;
  public
    function Add(const aItem:Extended):Integer; reintroduce;
    property Items[const aIndex:Integer]:Extended read GetItem write SetItem;
  end;


  TdxJSONArrayOfInteger = class(TdxJSONArrayOfString)
  protected
    function GetAsJSON():String; override;
    function GetItem(const aIndex:Integer):Integer; reintroduce;
    procedure SetItem(const aIndex:Integer; const aItem:Integer); reintroduce;
  public
    function Add(const aItem:Integer):Integer; reintroduce;
    property Items[const aIndex:Integer]:Integer read GetItem write SetItem;
  end;


  TdxJSONArrayOfInt64 = class(TdxJSONArrayOfString)
  protected
    function GetAsJSON():String; override;
    function GetItem(const aIndex:Integer):Int64; reintroduce;
    procedure SetItem(const aIndex:Integer; const aItem:Int64); reintroduce;
  public
    function Add(const aItem:Int64):Integer; reintroduce;
    property Items[const aIndex:Integer]:Int64 read GetItem write SetItem;
  end;


implementation
uses
  {$IFDEF DX_Has_Unit_Variants}
    {$IFDEF DX_UnitScopeNames}
    System.Variants,
    {$ELSE}
    Variants,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF DX_UnitScopeNames}
  System.TypInfo,
  {$ELSE}
  TypInfo,
  {$ENDIF}
  dxLib_ClassPropertyArray,
  dxLib_JSONParser,
  dxLib_JSONUtils,
  dxLib_RTTI;


constructor TdxJSONObject.Create();
begin
  inherited Create();
  SetPublishedPropertyDefaultsViaRTTI(self);
end;


procedure TdxJSONObject.Assign(const aSource:TdxJSONObject);
begin
  AsJSON := aSource.AsJSON;
end;


//resets to default values
procedure TdxJSONObject.Clear();
var
  vNewInstance:TdxJSONObject;
begin
  //This first, more obvious format does not call the TdxJSONObject constructor:
  //  vNew := self.ClassType.Create as TdxJSONObject;
  //whereas casting using the specific class type does
  //Note: If your descendant constructor is not getting called, insure your
  //Create interface definition is marked with the 'override' directive
  vNewInstance := TdxJSONObjectClass(self.ClassType).Create();
  try
    self.ParseJSON(vNewInstance.AsJSON);
  finally
    vNewInstance.Free();
  end;
end;


function TdxJSONObject.GetAsJSON():String;
var
  vProperties:TdxClassPropertyArray;
  vProperty:PPropInfo;
  vTypeData:PTypeData;
  i:Integer;
  vPropertyName:String;
  vNameValue:String;
  vChild:TObject;
  vVar:Variant;
  vFloat:Extended;
  vCurr:Currency;
begin
  Result := '';

  vProperties := TdxClassPropertyArray.Create(self, tkProperties);
  try
    for i := 0 to vProperties.Count-1 do
    begin
      vNameValue := '';
      vProperty := vProperties.Items[i];

      if (vProperty.GetProc <> nil) and (vProperty.SetProc <> nil) then
      begin
        vPropertyName := String(vProperty.Name);  //.name= TSymbolName shortstring

        //D5 not handled:         [tkUnknown, tkMethod, tkArray, tkRecord, tkInterface, tkDynArray]
        //D10Seattle not handled: [tkUnknown, tkMethod, tkArray, tkRecord, tkInterface, tkDynArray, tkClassRef, tkPointer, tkProcedure]

        case vProperty.PropType^.Kind of
        tkString, tkLString:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetStrProp(self, vProperty));
          end;
        {$IFDEF DX_String_Is_UTF16}
        tkUString:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetStrProp(self, vProperty));
          end;
        tkWString:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetWideStrProp(self, vProperty));
          end;
        {$ELSE}
        //Unsupported in pre-2009
        //tkWString:
           //Old versions (D5) do not expose GetWideStrProp/SetWideStrProp in TypInfo
           //and we'd also need a TStringList for wide strings (or some WideString list)
        {$ENDIF}
        tkInteger:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetOrdProp(self, vProperty));
          end;
        tkInt64:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetInt64Prop(self, vProperty));
          end;
        tkFloat:
          begin
            vFloat := GetFloatProp(self, vProperty);

            vTypeData := GetTypeData(vProperty.PropType^);
            if vTypeData^.FloatType = ftCurr  then
            begin
              vCurr := vFloat;
              vNameValue := JSON_NameValue(vPropertyName, vCurr); //force 0.00 format even on empty values
            end
            else
            begin
              vNameValue := JSON_NameValue(vPropertyName, vFloat);
            end;
          end;
        tkChar:
          begin
            vNameValue := JSON_NameValue(vPropertyName, Char(GetOrdProp(self, vProperty)));
          end;
        {$IFDEF DX_String_Is_UTF16}
        tkWChar:
          begin
            vNameValue := JSON_NameValue(vPropertyName, WideChar(GetOrdProp(self, vProperty)));
          end;
        //{$ELSE}
        //Unsupported in pre-2009
        {$ENDIF}
        tkEnumeration:
          begin
            if (vProperty.PropType^ = System.TypeInfo(Boolean))
               or (vProperty.PropType^ = System.TypeInfo(ByteBool))
               or (vProperty.PropType^ = System.TypeInfo(WordBool))
               or (vProperty.PropType^ = System.TypeInfo(LongBool)) then
            begin
              vNameValue := JSON_NameValue(vPropertyName, Boolean(GetOrdProp(self, vProperty)));
            end
            else
            begin
              vNameValue := JSON_NameValue(vPropertyName, GetEnumProp(self, vProperty));
            end;
          end;
        tkSet:
          begin
            vNameValue := JSON_NameValue(vPropertyName, GetSetProp(self, vProperty));
          end;
        tkVariant:
          begin
            vVar := GetVariantProp(self, vProperty);
            if VarIsNull(vVar) then
            begin
              vNameValue := JSON_NameValue(vPropertyName, JSON_Null);
            end
            else
            begin
              vNameValue := JSON_NameValue(vPropertyName, VarToStr(vVar));
            end;
          end;
        tkClass:
          begin
            vChild := TObject(GetOrdProp(self, vProperty));
            if Assigned(vChild) then
            begin
              if vChild is TdxJSONObject then
              begin
                vNameValue := JSON_SubObject(vPropertyName, TdxJSONObject(vChild).AsJSON);
              end;
              //non-TdxJSONObject descendants are ignored
            end;
          end;
        end;


        if Length(vNameValue) > 0 then //supported property type
        begin
          if Length(Result) > 0 then
          begin
            Result := Result + ',' + vNameValue;
          end
          else
          begin
            Result := vNameValue;
          end;
        end;
      end;
    end;
  finally
    vProperties.Free();
  end;

  Result := '{' + Result + '}';
end;


procedure TdxJSONObject.ParseJSON(const aJSON:String);
var
  vParser:TdxJSONParser;
begin
  vParser := TdxJSONParser.Create();
  try
    vParser.ParseJSON(aJSON, self);
  finally
    vParser.Free();
  end;
end;


procedure TdxJSONObject.SetAsJSON(const aJSON:String);
begin
  //no matter what's in aJSON ensure instance is reset and defaults established
  //(If parser fails to read all the data, do not leave the previous data intact)
  Clear();

  ParseJSON(aJSON);
end;


constructor TdxJSONArrayOfObject.Create();
begin
  fList := TList.Create();
  inherited;
end;


destructor TdxJSONArrayOfObject.Destroy();
begin
  ClearList();
  fList.Free();
  inherited;
end;


function TdxJSONArrayOfObject.GetAsJSON():String;
var
  i:integer;
  vItem:TdxJSONObject;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fList.Count-1 do
  begin
    if fList[i] <> nil then
    begin
      vItem := TdxJSONObject(fList[i]);
      vItemJSON := vItem.AsJSON;
    end
    else
    begin
      vItemJSON := JSON_Null;
    end;

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


procedure TdxJSONArrayOfObject.SetAsJSON(const aJSON:String);
begin
  ClearList();
  inherited;
end;


procedure TdxJSONArrayOfObject.ClearList();
var
  i:integer;
  vItem:TdxJSONObject;
begin
  for i := fList.Count-1 downto 0 do
  begin
    vItem := TdxJSONObject(fList[i]);
    vItem.Free();
  end;
  fList.Count := 0;
end;


function TdxJSONArrayOfObject.Add(const aItem:TdxJSONObject):Integer;
begin
  Result := fList.Add(aItem);
end;


procedure TdxJSONArrayOfObject.Clear();
begin
  ClearList();
  inherited;
end;


procedure TdxJSONArrayOfObject.Delete(const aIndex:Integer);
var
  vItem:TdxJSONObject;
begin
  vItem := TdxJSONObject(fList[aIndex]);
  fList.Items[aIndex] := nil;
  fList.Delete(aIndex);
  vItem.Free();
end;


function TdxJSONArrayOfObject.Count():Integer;
begin
  Result := fList.Count;
end;


function TdxJSONArrayOfObject.GetItem(const aIndex:Integer):TdxJSONObject;
begin
  Result := TdxJSONObject(fList[aIndex]);
end;


procedure TdxJSONArrayOfObject.SetItem(const aIndex:Integer; const aItem:TdxJSONObject);
begin
  fList[aIndex] := aItem;
end;


procedure TdxJSONArrayOfObject.Sort(const aSortProc:TListSortCompare);
begin
  fList.Sort(aSortProc);
end;


constructor TdxJSONArrayOfString.Create();
begin
  {$IFDEF DX_String_Is_UTF16}
  fStringList := TList<String>.Create();
  {$ELSE}
  fStringList := TStringList.Create();
  {$ENDIF}
  inherited;
end;


destructor TdxJSONArrayOfString.Destroy();
begin
  fStringList.Free();
  inherited;
end;

function TdxJSONArrayOfString.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    vItemJSON := JSON_String(fStringList[i]);

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


procedure TdxJSONArrayOfString.SetAsJSON(const aJSON:String);
begin
  ClearList();
  inherited;
end;


function TdxJSONArrayOfString.GetItem(const aIndex:Integer):String;
begin
  Result := fStringList[aIndex];
end;


procedure TdxJSONArrayOfString.SetItem(const aIndex:Integer; const aItem:String);
begin
  fStringList[aIndex] := aItem;
end;


function TdxJSONArrayOfString.Add(const aItem:String):Integer;
begin
  Result := fStringList.Add(aItem);
end;


procedure TdxJSONArrayOfString.Clear();
begin
  ClearList;
  inherited;
end;


procedure TdxJSONArrayOfString.ClearList();
begin
  fStringList.Clear();
end;


function TdxJSONArrayOfString.Count():Integer;
begin
  Result := fStringList.Count;
end;


procedure TdxJSONArrayOfString.Delete(const aIndex:Integer);
begin
  fStringList.Delete(aIndex);
end;

{$IFDEF DX_String_Is_UTF16}
procedure TdxJSONArrayOfString.Sort(const AComparer:IComparer<String>);
begin
  fStringList.Sort(AComparer);
end;
{$ELSE}
procedure TdxJSONArrayOfString.Sort(const aSortProc:TStringListSortCompare);
begin
  fStringList.CustomSort(aSortProc);
end;
{$ENDIF}


function TdxJSONArrayOfInteger.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    vItemJSON := JSON_Integer(StrToIntDef(fStringList[i], 0));

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


function TdxJSONArrayOfInteger.Add(const aItem:Integer):Integer;
begin
  Result := fStringList.Add(IntToStr(aItem));
end;

function TdxJSONArrayOfInteger.GetItem(const aIndex:Integer):Integer;
var
  vItem:String;
begin
  vItem := inherited GetItem(aIndex);
  Result := StrToIntDef(vItem, 0);
end;


procedure TdxJSONArrayOfInteger.SetItem(const aIndex:Integer; const aItem:Integer);
begin
  inherited SetItem(aIndex, IntToStr(aItem));
end;


function TdxJSONArrayOfInt64.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    vItemJSON := JSON_Integer(StrToInt64Def(fStringList[i],0));

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


function TdxJSONArrayOfInt64.Add(const aItem:Int64):Integer;
begin
  Result := fStringList.Add(IntToStr(aItem));
end;


function TdxJSONArrayOfInt64.GetItem(const aIndex:Integer):Int64;
var
  vItem:String;
begin
  vItem := inherited GetItem(aIndex);
  Result := StrToInt64Def(vItem,0);
end;


procedure TdxJSONArrayOfInt64.SetItem(const aIndex:Integer; const aItem:Int64);
begin
  inherited SetItem(aIndex, IntToStr(aItem));
end;


function TdxJSONArrayOfBoolean.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    vItemJSON := JSON_Boolean(SameText(fStringList[i], 'true'));

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


function TdxJSONArrayOfBoolean.Add(const aItem:Boolean):Integer;
begin
  Result := fStringList.Add(JSON_Boolean(aItem));
end;

function TdxJSONArrayOfBoolean.GetItem(const aIndex:Integer):Boolean;
begin
  Result := SameText(inherited GetItem(aIndex), 'true');
end;

procedure TdxJSONArrayOfBoolean.SetItem(const aIndex:Integer; const aItem:Boolean);
begin
  inherited SetItem(aIndex, JSON_Boolean(aItem));
end;


function TdxJSONArrayOfFloat.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    try
      vItemJSON := JSON_Float(StrToFloat(fStringList[i]));
    except
      vItemJSON := JSON_Float(0);
    end;

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


function TdxJSONArrayOfFloat.Add(const aItem:Extended):Integer;
begin
  try
    Result := fStringList.Add(FloatToStr(aItem));
  except
    Result := fStringList.Add('0');
  end;
end;

function TdxJSONArrayOfFloat.GetItem(const aIndex:Integer):Extended;
var
  vItem:String;
begin
  vItem := inherited GetItem(aIndex);
  try
    Result := StrToFloat(vItem);
  except
    Result := 0;
  end;
end;


procedure TdxJSONArrayOfFloat.SetItem(const aIndex:Integer; const aItem:Extended);
begin
  inherited SetItem(aIndex, JSON_Float(aItem));
end;


function TdxJSONArrayOfCurrency.GetAsJSON():String;
var
  i:integer;
  vItemJSON:String;
begin
  Result := '';

  for i := 0 to fStringList.Count-1 do
  begin
    try
      vItemJSON := JSON_Currency(StrToCurr(fStringList[i]));
    except
      vItemJSON := JSON_Currency(0);
    end;

    if i > 0 then
    begin
      Result := Result + ',' + vItemJSON;
    end
    else
    begin
      Result := vItemJSON;
    end;
  end;
  Result := '[' + Result + ']';
end;


function TdxJSONArrayOfCurrency.Add(const aItem:Currency):Integer;
begin
  Result := fStringList.Add(JSON_Currency(aItem));
end;

function TdxJSONArrayOfCurrency.GetItem(const aIndex:Integer):Currency;
var
  vItem:String;
begin
  vItem := inherited GetItem(aIndex);
  try
    Result := StrToCurr(vItem);
  except
    Result := 0;
  end;
end;


procedure TdxJSONArrayOfCurrency.SetItem(const aIndex:Integer; const aItem:Currency);
begin
  inherited SetItem(aIndex, JSON_Currency(aItem));
end;

end.



