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
*)
unit dxLib_JSONParser;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  System.TypInfo,
  {$ELSE}
  SysUtils,
  TypInfo,
  {$ENDIF}
  dxLib_JSONObjects;

type
  TdxJSONParseError = class(Exception)
  end;

  TdxJSONParser = class
  private
    fCurrentPosition:Integer;
    fJSONString:String;
    fJSONLength:Integer;
  protected
    procedure AssignBoolValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Boolean);
    procedure AssignFloatValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Extended);
    procedure AssignIntValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Integer);
    procedure AssignInt64Value(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Int64);
    procedure AssignNullValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo);
    procedure AssignStringValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:String);

    procedure SkipWhiteSpace();

    procedure ParseJSONObject(const aInstance:TdxJSONObject);
    procedure ParseJSONArray(const aInstance:TdxJSONObject; const aProperty:PPropInfo);
    function ParseJSONString():String;
    function ParseJSONValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo):String;
  public
    procedure ParseJSON(const aJSON:String; const aInstance:TdxJSONObject);
  end;


  TdxHackJSONArrayOfObject = class(TdxJSONArrayOfObject)
  end;
  TdxHackJSONArrayOfString = class(TdxJSONArrayOfString)
  end;

ResourceString
  PARSE_ELEM_ERROR = 'Missing expected element at position %d';
  PARSE_CHAR_ERROR = 'Unexpected character at position %d - %s';
  PARSE_COLON_ERROR = 'Missing colon separator at position %d';
  PARSE_COLON_TRUNC = 'Name/value object separation appears truncated at position %d';
  PARSE_BRACE_MISSING = 'Object ending brace missing at position %d';
  PARSE_BRACKET_MISSING = 'Array ending bracket missing at position %d';
  PARSE_HEX_ERROR = 'Invalid hex conversion at position %d - %s';
  PARSE_HEX_TRUNC = 'Hex truncation at position %d';
  PARSE_BOOL_ERROR = 'Invalid boolean conversion at position %d - %s';
  PARSE_BOOL_TRUNC = 'Boolean truncation at position %d';
  PARSE_NULL_ERROR = 'Invalid null conversion at position %d - %s';
  PARSE_NULL_TRUNC = 'Null truncation at position %d';
  PARSE_DANGLING_ESCAPE = 'Escape sequence truncated at position %d';
  PARSE_DANGLING_QUOTE = 'String value not properly quoted - dangling quote at position %d';


implementation
uses
  {$IFDEF DX_Has_Unit_Variants}
    {$IFDEF DX_UnitScopeNames}
    System.Variants,
    {$ELSE}
    Variants,
    {$ENDIF}
  {$ENDIF}
  dxLib_ClassPropertyArray,
  dxLib_JSONUtils,
  dxLib_Strings;


procedure TdxJSONParser.ParseJSON(const aJSON:String; const aInstance:TdxJSONObject);
var
  vCurrentChar:Char;
begin
  fJSONString := aJSON;
  fCurrentPosition := 1;
  fJSONLength := Length(fJSONString);

  if fJSONLength > 0 then
  begin
    SkipWhiteSpace();
    vCurrentChar := fJSONString[fCurrentPosition];
    if vCurrentChar = '{' then
    begin
      ParseJSONObject(aInstance);
    end
    else if vCurrentChar = '[' then
    begin
      ParseJSONArray(aInstance, nil);
    end
    else
    begin
      raise TdxJSONParseError.CreateFmt(PARSE_CHAR_ERROR, [fCurrentPosition, vCurrentChar]);
    end;
  end;
end;


procedure TdxJSONParser.SkipWhiteSpace();
begin
  while (fCurrentPosition <= fJSONLength)
        and (CharInSet(fJSONString[fCurrentPosition], JSON_WHITESPACE_CHARACTERS)) do
  begin
    Inc(fCurrentPosition);
  end;
end;


//we just read in "{" read info up to matching "}"

//When entering method, CurrentPosition = placement of { character
//When leaving method, CurrentPosition = placement of } character
procedure TdxJSONParser.ParseJSONObject(const aInstance:TdxJSONObject);
var
  vCurrentChar:Char;
  vProperties:TdxClassPropertyArray;
  vProperty:PPropInfo;
  vFinalEndFound:Boolean;
  vValueNeeded:Boolean;
  vObjectName:String;
  vEndsToFind:Integer;
begin

  if not Assigned(aInstance) then  //additional logic needed to bypass trying to parse info in string that does not have a property assigned....
  begin
    inc(fCurrentPosition);
    vFinalEndFound := False;
    vEndsToFind := 1;
    while fCurrentPosition <= fJSONLength do
    begin
      SkipWhiteSpace();
      vCurrentChar := fJSONString[fCurrentPosition];
      if vCurrentChar = '}' then
      begin
        Dec(vEndsToFind);
        if vEndsToFind = 0 then
        begin
          vFinalEndFound := True;
          Break;
        end;
      end
      else if vCurrentChar = '{' then     //embedded object within a child object
      begin
        Inc(vEndsToFind);
      end;
      inc(fCurrentPosition);
    end;
  end
  else
  begin
    vProperties := TdxClassPropertyArray.Create(aInstance, tkProperties);
    try
      vFinalEndFound := False;
      vValueNeeded := False;
      Inc(fCurrentPosition);

      while fCurrentPosition <= fJSONLength do
      begin
        SkipWhiteSpace();
        vCurrentChar := fJSONString[fCurrentPosition];
        if vCurrentChar = '}' then
        begin
          if vValueNeeded then
          begin
            raise TdxJSONParseError.CreateFmt(PARSE_ELEM_ERROR, [fCurrentPosition]);
          end;
          vFinalEndFound := True;
          Break;
        end
        else if vCurrentChar = ',' then
        begin
          if vValueNeeded then
          begin
            raise TdxJSONParseError.CreateFmt(PARSE_ELEM_ERROR, [fCurrentPosition]);
          end;
          vValueNeeded := True;
          Inc(fCurrentPosition);
        end
        else if vCurrentChar = '"' then
        begin
          vObjectName := ParseJSONString();
          Inc(fCurrentPosition);
          vProperty := vProperties.GetPropertyByName(vObjectName);

          SkipWhiteSpace();
          if fCurrentPosition <= fJSONLength then
          begin
            vCurrentChar := fJSONString[fCurrentPosition];
            if vCurrentChar = ':' then  //name:value
            begin
              Inc(fCurrentPosition);
              SkipWhiteSpace();
              if fCurrentPosition <= fJSONLength then
              begin
                ParseJSONValue(aInstance, vProperty);
                vValueNeeded := False;
              end
              else
              begin
                raise TdxJSONParseError.CreateFmt(PARSE_COLON_TRUNC, [fCurrentPosition]);
              end;
            end
            else
            begin
              raise TdxJSONParseError.CreateFmt(PARSE_COLON_ERROR, [fCurrentPosition]);
            end;
          end
          else
          begin
            raise TdxJSONParseError.CreateFmt(PARSE_COLON_TRUNC, [fCurrentPosition]);
          end;
        end
        else
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_CHAR_ERROR, [fCurrentPosition, vCurrentChar]);
        end;
      end; //main while loop
    finally
      vProperties.Free();
    end;
  end;
  if not vFinalEndFound then
  begin
    raise TdxJSONParseError.CreateFmt(PARSE_BRACE_MISSING, [fCurrentPosition]);
  end;
end;


//we just read in [ read info up to matching ]
//When entering method, CurrentPosition = placement of [ character
//When leaving method, CurrentPosition = placement of [ character
procedure TdxJSONParser.ParseJSONArray(const aInstance:TdxJSONObject; const aProperty:PPropInfo);
var
  vCurrentChar:Char;
  vFinalEndFound:Boolean;
  vValueNeeded:Boolean;
  vEndsToFind:Integer;
begin
  if not Assigned(aInstance) then  //additional logic needed to bypass trying to parse info in string that does not have a property assigned....
  begin
    inc(fCurrentPosition);
    vFinalEndFound := False;
    vEndsToFind := 1;
    while fCurrentPosition <= fJSONLength do
    begin
      SkipWhiteSpace();
      vCurrentChar := fJSONString[fCurrentPosition];
      if vCurrentChar = ']' then
      begin
        Dec(vEndsToFind);
        if vEndsToFind = 0 then
        begin
          vFinalEndFound := True;
          Break;
        end;
      end
      else if vCurrentChar = '[' then //embedded array within a child object
      begin
        Inc(vEndsToFind);
      end;
      inc(fCurrentPosition);
    end;
  end
  else
  begin
    vFinalEndFound := False;
    vValueNeeded := False;
    Inc(fCurrentPosition);

    if aInstance is TdxJSONArrayOfObject then
    begin
      TdxHackJSONArrayOfObject(aInstance).ClearList();
    end
    else if aInstance is TdxJSONArrayOfString then
    begin
      TdxHackJSONArrayOfString(aInstance).ClearList();
    end;


    while fCurrentPosition <= fJSONLength do
    begin
      SkipWhiteSpace();
      vCurrentChar := fJSONString[fCurrentPosition];
      if vCurrentChar = ']' then
      begin
        if vValueNeeded then
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_ELEM_ERROR, [fCurrentPosition]);
        end;
        vFinalEndFound := True;
        Break;
      end
      else if vCurrentChar = ',' then
      begin
        if vValueNeeded then
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_ELEM_ERROR, [fCurrentPosition]);
        end;
        vValueNeeded := True;
        Inc(fCurrentPosition);
      end
      else
      begin
        ParseJSONValue(aInstance, aProperty);
        vValueNeeded := False;
      end;
    end; //main while loop
  end;

  if not vFinalEndFound then
  begin
    raise TdxJSONParseError.CreateFmt(PARSE_BRACKET_MISSING, [fCurrentPosition]);
  end;
end;


//we just read in " read up to matching "

//When entering method, CurrentPosition = placement of starting " character
//When leaving method, CurrentPosition = placement of ending " character
function TdxJSONParser.ParseJSONString():String;
var
  vCurrentChar:Char;
  vFinalEndFound:Boolean;
  vHex:String;
  vChar:Integer;
Begin
  Result := '';
  vFinalEndFound := false;
  inc(fCurrentPosition);

  while fCurrentPosition <= fJSONLength do
  begin
    vCurrentChar := fJSONString[fCurrentPosition];

    if vCurrentChar = '"' then
    begin
      vFinalEndFound := True;
      break;
    end
    else if vCurrentChar = '\' then
    begin
      //next character determines behavior of the escape
      Inc(fCurrentPosition);
      if fCurrentPosition <= fJSONLength then
      begin
        vCurrentChar := fJSONString[fCurrentPosition];
        if CharInSet(vCurrentChar, ['"', '\', '/']) then
        begin
          Result := Result + vCurrentChar;
        end
        else if vCurrentChar = 'b' then
        begin
          Result := Result + #8;
        end
        else if vCurrentChar = 'f' then
        begin
          Result := Result + #12;
        end
        else if vCurrentChar = 't' then
        begin
          Result := Result + #9;
        end
        else if vCurrentChar = 'n' then
        begin
          Result := Result + #10;
        end
        else if vCurrentChar = 'r' then
        begin
          Result := Result + #13;
        end
        else if vCurrentChar = 'u' then //4 hex digits follows to define character
        begin
          Inc(fCurrentPosition, 4);
          if fCurrentPosition <= fJSONLength then
          begin
            vHex := '$' + UpperCase(Copy(fJSONString, fCurrentPosition-3, 4));
            try
              vChar := StrToInt(vHex);
              if (vChar > 255) and (SizeOf(Char) = 1) then  //non-unicode version of Delphi
              begin
                Result := Result + '?';
              end
              else
              begin
                Result := Result + Char(vChar);
              end;
            except
              on e:exception do
              begin
                raise TdxJSONParseError.CreateFmt(PARSE_HEX_ERROR, [fCurrentPosition-3, vHex]);
              end;
            end;
          end
          else
          begin
            raise TdxJSONParseError.CreateFmt(PARSE_HEX_TRUNC, [fCurrentPosition-4]);
          end;
        end
        else
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_CHAR_ERROR, [fCurrentPosition, vCurrentChar]);
        end;
      end
      else
      begin
        raise TdxJSONParseError.CreateFmt(PARSE_DANGLING_ESCAPE, [fCurrentPosition]);
      end;
    end
    else
    begin
      Result := Result + vCurrentChar;
    end;

    inc(fCurrentPosition);
  end; //main while loop

  if not vFinalEndFound then
  begin
    raise TdxJSONParseError.CreateFmt(PARSE_DANGLING_QUOTE, [fCurrentPosition]);
  end;
end;


//RFC: Value can be String, Number, Object, Array, true, false, null

//When entering method, CurrentPosition = placement of initial piece of data { for objects, [ for arrays, " for strings, -Digits for numeric, 't' for true, 'f' for false, 'n' for null
//When leaving method, CurrentPosition = placement one after the end of the previous value just read in
function TdxJSONParser.ParseJSONValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo):String;
var
  vCurrentChar:Char;
  vStringVal:String;
  vInt:String;
  vDecimal:String;
  vInt64Val:Int64;
  vIntVal:Integer;
  vChild:TObject;
  vChildJSON:TdxJSONObject;
begin
  Result := '';
  while fCurrentPosition <= fJSONLength do
  begin
    vCurrentChar := fJSONString[fCurrentPosition];

    if vCurrentChar = '"' then
    begin
      vStringVal := ParseJSONString();
      Inc(fCurrentPosition);
      if aInstance is TdxJSONArrayOfString then
      begin
        TdxJSONArrayOfString(aInstance).Add(vStringVal);
      end
      else
      begin
        AssignStringValue(aInstance, aProperty, vStringVal);
      end;
      Break;
    end
    else if CharInSet(vCurrentChar, ['N','n']) then
    begin
      Inc(fCurrentPosition, 3);
      if fCurrentPosition <= fJSONLength then
      begin
        vStringVal := Copy(fJSONString, fCurrentPosition-3, 4);
        if SameText('null', vStringVal) then
        begin
          if aInstance is TdxJSONArrayOfString then
          begin
            //string array with embedded null.
            TdxJSONArrayOfString(aInstance).Add('');
          end
          else if (aInstance is TdxJSONArrayOfObject) then
          begin
            TdxJSONArrayOfObject(aInstance).Add(nil);
          end
          else
          begin
            AssignNullValue(aInstance, aProperty);
          end;
        end
        else
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_NULL_ERROR, [fCurrentPosition, vStringVal]);
        end;
      end
      else
      begin
        raise TdxJSONParseError.CreateFmt(PARSE_NULL_TRUNC, [fCurrentPosition]);
      end;
      Inc(fCurrentPosition);
      Break;
    end
    else if CharInSet(vCurrentChar, ['T','t']) then
    begin
      Inc(fCurrentPosition, 3);
      if fCurrentPosition <= fJSONLength then
      begin
        vStringVal := Copy(fJSONString, fCurrentPosition-3, 4);
        if SameText('TRUE', vStringVal) then
        begin
          if aInstance is TdxJSONArrayOfString then
          begin
            TdxJSONArrayOfString(aInstance).Add('true');
          end
          else
          begin
            AssignBoolValue(aInstance, aProperty, True);
          end;
        end
        else
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_BOOL_ERROR, [fCurrentPosition, vStringVal]);
        end;
      end
      else
      begin
        raise TdxJSONParseError.CreateFmt(PARSE_BOOL_TRUNC, [fCurrentPosition]);
      end;
      Inc(fCurrentPosition);
      Break;
    end
    else if CharInSet(vCurrentChar, ['F','f']) then
    begin
      Inc(fCurrentPosition, 4);
      if fCurrentPosition <= fJSONLength then
      begin
        vStringVal := Copy(fJSONString, fCurrentPosition-4, 5);
        if SameText('FALSE', vStringVal) then
        begin
          if aInstance is TdxJSONArrayOfString then
          begin
            TdxJSONArrayOfString(aInstance).Add('false');
          end
          else
          begin
            AssignBoolValue(aInstance, aProperty, False);
          end;
        end
        else
        begin
          raise TdxJSONParseError.CreateFmt(PARSE_BOOL_ERROR, [fCurrentPosition, vStringVal]);
        end;
      end
      else
      begin
        raise TdxJSONParseError.CreateFmt(PARSE_BOOL_TRUNC, [fCurrentPosition]);
      end;
      Inc(fCurrentPosition);
      Break;
    end
    else if CharInSet(vCurrentChar, ['-','0','1','2','3','4','5','6','7','8','9']) then
    begin
      vInt := vCurrentChar;
      vDecimal := '';
      Inc(fCurrentPosition);
      while (fCurrentPosition <= fJSONLength) do
      begin
        vCurrentChar := fJSONString[fCurrentPosition];
        if CharInSet(vCurrentChar, ['0','1','2','3','4','5','6','7','8','9']) then
        begin
          vInt := vInt + vCurrentChar;
          Inc(fCurrentPosition);
        end
        else
        begin
          break;
        end;
      end;

      if vCurrentChar = '.' then
      begin
        vDecimal := vCurrentChar;
        Inc(fCurrentPosition);
        while (fCurrentPosition <= fJSONLength) do
        begin
          vCurrentChar := fJSONString[fCurrentPosition];
          if CharInSet(vCurrentChar, ['e','E','+','-','0','1','2','3','4','5','6','7','8','9']) then
          begin
            vDecimal := vDecimal + vCurrentChar;
            Inc(fCurrentPosition);
          end
          else
          begin
            break;
          end;
        end;
      end;

      if Length(vDecimal) > 0 then
      begin
        if aInstance is TdxJSONArrayOfString then
        begin
          TdxJSONArrayOfString(aInstance).Add(vInt + vDecimal);
        end
        else
        begin
          AssignFloatValue(aInstance, aProperty, StrToFloat(vInt + vDecimal));
        end;
      end
      else
      begin
        vInt64Val := StrToInt64(vInt);
        if (vInt64Val < High(Integer)) and (vInt64Val >= Low(Integer)) then
        begin
          vIntVal := StrToInt(vInt);
          if aInstance is TdxJSONArrayOfString then
          begin
            TdxJSONArrayOfString(aInstance).Add(vInt);
          end
          else
          begin
            AssignIntValue(aInstance, aProperty, vIntVal);
          end;
        end
        else
        begin
          if aInstance is TdxJSONArrayOfString then
          begin
            TdxJSONArrayOfString(aInstance).Add(vInt);
          end
          else
          begin
            AssignInt64Value(aInstance, aProperty, vInt64Val);
          end;
        end;
      end;
      Break;
    end
    else if vCurrentChar = '{' then
    begin
      vChildJSON := nil;
      if (aInstance is TdxJSONArrayOfObject) then
      begin
        vChildJSON := TdxJSONArrayOfObject(aInstance).CreateItem();
        TdxJSONArrayOfObject(aInstance).Add(vChildJSON);
      end
      else if Assigned(aInstance) and Assigned(aProperty) then
      begin
        vChild := TObject(GetOrdProp(aInstance, aProperty));
        if Assigned(vChild) then
        begin
          if vChild is TdxJSONObject then
          begin
            vChildJSON := TdxJSONObject(vChild);
          end;
        end;
        //else attempting to assign a JSON object to a non-object property...will skip
      end;
      ParseJSONObject(vChildJSON);
      Inc(fCurrentPosition);
      Break;
    end
    else if vCurrentChar = '[' then
    begin
      vChildJSON := nil;
      if Assigned(aInstance) and Assigned(aProperty) then
      begin
        vChild := TObject(GetOrdProp(aInstance, aProperty));
        if Assigned(vChild) then
        begin
          if vChild is TdxJSONObject then
          begin
            vChildJSON := TdxJSONObject(vChild);
          end;
        end;
      end;

      ParseJSONArray(vChildJSON, aProperty);
      Inc(fCurrentPosition);
      Break;
    end;
  end;
end;


procedure TdxJSONParser.AssignBoolValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Boolean);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    case aProperty.PropType^.Kind of
    tkEnumeration:
      begin
        SetEnumProp(aInstance, aProperty, BooleanIdents[aVal]);
      end;
    tkVariant:
      begin
        SetVariantProp(aInstance, aProperty, aVal);
      end;
    end;
  end;
end;


procedure TdxJSONParser.AssignIntValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Integer);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    case aProperty.PropType^.Kind of
    tkString, tkLString:
      begin
        SetStrProp(aInstance, aProperty, IntToStr(aVal));
      end;
    {$IFDEF DX_String_Is_UTF16}
    tkUString,tkWString:
      begin
        SetUnicodeStrProp(aInstance, aProperty, IntToStr(aVal));
      end;
    {$ENDIF}
    tkClass, tkInteger:
      begin
        SetOrdProp(aInstance, aProperty, aVal);
      end;
    tkInt64:
      begin
        SetInt64Prop(aInstance, aProperty, aVal);
      end;
    tkFloat:
      begin
        SetFloatProp(aInstance, aProperty, aVal);
      end;
    tkVariant:
      begin
        SetVariantProp(aInstance, aProperty, aVal);
      end;
    end;
  end;
end;


procedure TdxJSONParser.AssignInt64Value(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Int64);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    case aProperty.PropType^.Kind of
    tkString, tkLString:
      begin
        SetStrProp(aInstance, aProperty, IntToStr(aVal));
      end;
    {$IFDEF DX_String_Is_UTF16}
    tkUString,tkWString:
      begin
        SetUnicodeStrProp(aInstance, aProperty, IntToStr(aVal));
      end;
    {$ENDIF}
    tkInt64:
      begin
        SetInt64Prop(aInstance, aProperty, aVal);
      end;
    end;
  end;
end;


procedure TdxJSONParser.AssignNullValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    if aProperty.PropType^.Kind = tkVariant then
    begin
      SetVariantProp(aInstance, aProperty, Null);
    end
    {$IFDEF DX_String_Is_UTF16}
    else if aProperty.PropType^.Kind in [tkUString,tkWString] then
    begin
      SetStrProp(aInstance, aProperty, 'null');
    end
    {$ENDIF}
    else if aProperty.PropType^.Kind in [tkString, tkLString] then
    begin
      SetStrProp(aInstance, aProperty, 'null');
    end;
  end;
end;


procedure TdxJSONParser.AssignStringValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:String);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    case aProperty.PropType^.Kind of
    tkString, tkLString:
      begin
        SetStrProp(aInstance, aProperty, aVal);
      end;
    {$IFDEF DX_String_Is_UTF16}
    tkUString,tkWString:
      begin
        SetUnicodeStrProp(aInstance, aProperty, aVal);
      end;
    {$ENDIF}
    tkChar:
      begin
        if Length(aVal) = 1 then
        begin
          SetOrdProp(aInstance, aProperty, Ord(aVal[1]));
        end;
      end;
    tkEnumeration:
      begin
        //this can throw errors on invalid enumerations being provided
        SetEnumProp(aInstance, aProperty, aVal);
      end;
    tkSet:
      begin
        if Length(aVal) = 0 then
        begin
          SetSetProp(aInstance, aProperty, '[]');
        end
        else
        begin
          SetSetProp(aInstance, aProperty, aVal);
        end;
      end;
    tkVariant:
      begin
        SetVariantProp(aInstance, aProperty, aVal);
      end;
    end;
  end;
end;


procedure TdxJSONParser.AssignFloatValue(const aInstance:TdxJSONObject; const aProperty:PPropInfo; const aVal:Extended);
begin
  if Assigned(aInstance) and Assigned(aProperty) then
  begin
    case aProperty.PropType^.Kind of
    tkFloat:
      begin
        SetFloatProp(aInstance, aProperty, aVal);
      end;
    tkVariant:
      begin
        SetVariantProp(aInstance, aProperty, aVal);
      end;
    end;
  end;
end;


end.
