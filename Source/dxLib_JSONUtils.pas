(*
Copyright (c) 2016 Darian Miller
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
unit dxLib_JSONUtils;

interface
{$I dxLib.inc}

  function JSON_NameValue(const aName:String; const aValue:String):String; overload;
  function JSON_NameValue(const aName:String; const aValue:Boolean):String; overload;
  function JSON_NameValue(const aName:String; const aValue:Currency):String; overload;
  function JSON_NameValue(const aName:String; const aValue:Extended):String; overload;
  function JSON_NameValue(const aName:String; const aValue:Integer):String; overload;
  function JSON_NameValue(const aName:String; const aValue:Int64):String; overload;


  function JSON_Boolean(const aValue:Boolean):String;
  function JSON_Currency(const aValue:Currency):String;
  function JSON_Float(const aValue:Extended):String;
  function JSON_Integer(const aValue:Integer):String;
  function JSON_Int64(const aValue:Int64):String;
  function JSON_Null():String;
  function JSON_String(const aValue:String):String;
  function JSON_SubObject(const aName:String; const aJSONObject:String):String;


const
  //RFC4627: Insignificant whitespace is allowed before or after any of the six structural characters.
  JSON_WHITESPACE_CHARACTERS = [#9,#10,#13,#32];
  JSON_EMPTY_OBJECT = '{}';
  JSON_EMPTY_ARRAY = '[]';


implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils;
  {$ELSE}
  SysUtils;
  {$ENDIF}


function JSON_NameValue(const aName:String; const aValue:String):String;
begin
  Result := JSON_String(aName) + ':' + JSON_String(aValue);
end;

function JSON_NameValue(const aName:String; const aValue:Boolean):String;
begin
  Result := JSON_String(aName) + ':' + JSON_Boolean(aValue);
end;

function JSON_NameValue(const aName:String; const aValue:Currency):String;
begin
  Result := JSON_String(aName) + ':' + JSON_Currency(aValue);
end;

function JSON_NameValue(const aName:String; const aValue:Extended):String;
begin
  Result := JSON_String(aName) + ':' + JSON_Float(aValue);
end;

function JSON_NameValue(const aName:String; const aValue:Integer):String;
begin
  Result := JSON_String(aName) + ':' + JSON_Integer(aValue);
end;

function JSON_NameValue(const aName:String; const aValue:Int64):String;
begin
  Result := JSON_String(aName) + ':' + JSON_Int64(aValue);
end;


function JSON_Boolean(const aValue:Boolean):String;
begin
  if aValue then
  begin
    Result := 'true';
  end
  else
  begin
    Result := 'false';
  end;
end;

function JSON_Currency(const aValue:Currency):String;
begin
  Result := FormatFloat('#0.00##', aValue);
end;

function JSON_Float(const aValue:Extended):String;
begin
  Result := FloatToStrF(aValue, ffGeneral, 18, 0);
end;

function JSON_Integer(const aValue:Integer):String;
begin
  Result := IntToStr(aValue);
end;

function JSON_Int64(const aValue:Int64):String;
begin
  Result := IntToStr(aValue);
end;

function JSON_Null():String;
begin
  Result := 'null';
end;

function JSON_String(const aValue:String):String;
var
  i:Integer;
  vChar:Char;
begin
  Result := '"';
  for i := 1 to Length(aValue) do
  begin
    vChar := aValue[i];
    if vChar = '/' then
    begin
      Result := Result + '\/';
    end
    else if vChar = '\' then
    begin
      Result := Result + '\\';
    end
    else if vChar = '"' then
    begin
      Result := Result + '\"';
    end
    else if vChar = #8 then
    begin
      Result := Result + '\b';
    end
    else if vChar = #9 then
    begin
      Result := Result + '\t';
    end
    else if vChar = #10 then
    begin
      Result := Result + '\n';
    end
    else if vChar = #12 then
    begin
      Result := Result + '\f';
    end
    else if vChar = #13 then
    begin
      Result := Result + '\r';
    end
    else if (Ord(vChar) < 32) or (Ord(vChar) > 127) then
    begin
      Result := Result + '\u' + IntToHex(Ord(vChar), 4);
    end
    else
    begin
      Result := Result + vChar;
    end;
  end;
  Result := Result + '"';
end;

function JSON_SubObject(const aName:String; const aJSONObject:String):String;
begin
  Result := JSON_String(aName) + ':' + aJSONObject;
end;


end.
