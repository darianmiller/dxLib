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

unit dxLib_Strings;

interface
{$I dxLib.inc}


  function ByteLength(const aChar:Char):Integer; overload;
  {$IFNDEF DX_DELPHI2009_UP}  //available in System.SysUtils from D2009+
  function ByteLength(const aString:String):Integer; overload;
  function ByteLength(const aString:AnsiString):Integer; overload;
  {$ENDIF}
  {$IFDEF DX_String_Is_UTF16}
  function ByteLength(const aChar:AnsiChar):Integer; overload;
  {$ENDIF}

  {$IFNDEF DX_Supports_CharInSet}
  type
    TSysAnsiCharSet = set of AnsiChar;

  function CharInSet(C:AnsiChar; const CharSet:TSysAnsiCharSet):Boolean;
  {$ENDIF}


  function IsPrintableCharacter(const pChar:Char):Boolean; overload;
  {$IFDEF DX_String_Is_UTF16}
  function IsPrintableCharacter(const pChar:AnsiChar):Boolean; overload;
  {$ENDIF}



  {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
  /// <summary>
  ///  Converts text into a form that contains only Unreserved Characters as per
  ///  RFC 3986
  /// </summary>
  /// <remarks>
  ///  Not intended for encoding a full URI, rather just individual eleements
  ///  such as parameters.
  /// </remarks>
  {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
  function URIEncodeElement(const pText:AnsiString):AnsiString;


  {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
  /// <summary>
  ///  Decodes text that includes percent-encoded characters
  /// </summary>
  /// <remarks>
  ///  URIDecodeElement decodes what it can, otherwise returns what was provided
  ///  instead of generating an exception on invalid data.
  /// </remarks>
  {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
  function URIDecodeElement(const pText:AnsiString):AnsiString;


const
  EmptyAnsiString:AnsiString = '';
  LowerCaseCharacters = ['a'..'z'];
  UpperCaseCharacters = ['A'..'Z'];
  CharacterDigits = ['0'..'9'];
  AlphaCharacters = LowerCaseCharacters + UpperCaseCharacters;
  AlphaNumericCharacters = AlphaCharacters + CharacterDigits;

  Unreserved3986Characters = AlphaNumericCharacters + ['-','_','.','~'];  //RFC 3986 list of "Unreserved Characters"

{$IFNDEF DX_Supports_SLineBreak}
  sLineBreak = {$IFDEF POSIX}Char(#10);{$ELSE}Char(#13) + Char(#10);{$ENDIF}
{$ENDIF}

implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils;
  {$ELSE}
  SysUtils;
  {$ENDIF}


function ByteLength(const aChar:Char):Integer;
begin
  Result := SizeOf(Char);
end;

{$IFNDEF DX_DELPHI2009_UP}
function ByteLength(const aString:String):Integer;
begin
  Result := Length(aString) * SizeOf(Char);
end;
function ByteLength(const aString:AnsiString):Integer;
begin
  Result := Length(aString) * SizeOf(AnsiChar);
end;
{$ENDIF}

{$IFDEF DX_String_Is_UTF16}
function ByteLength(const aChar:AnsiChar):Integer;
begin
  Result := SizeOf(AnsiChar);
end;
{$ENDIF}


{$IFNDEF DX_Supports_CharInSet}
function CharInSet(C:AnsiChar; const CharSet:TSysAnsiCharSet):Boolean;
begin
  Result := C in CharSet;
end;
{$ENDIF}

function IsPrintableCharacter(const pChar:Char):Boolean;
begin
  Result := (Ord(pChar) >= 32) and (Ord(pChar) <= 126);
end;


{$IFDEF DX_String_Is_UTF16}
function IsPrintableCharacter(const pChar:AnsiChar):Boolean;
begin
  Result := (Ord(pChar) >= 32) and (Ord(pChar) <= 126);
end;
{$ENDIF}



function URIEncodeElement(const pText:AnsiString):AnsiString;
var
  i:integer;
begin
  Result := '';

  for i := 1 to Length(pText) do
  begin
    if not CharInSet(pText[i], Unreserved3986Characters) then
    begin
      Result := Result + '%' + AnsiString(IntToHex(Ord(pText[i]), 2));
    end
    else
    begin
      Result := Result + pText[i];
    end;
  end;
end;


function URIDecodeElement(const pText:AnsiString):AnsiString;
var
  i:integer;
  vEncodePosition:Integer;
  vHexCode:AnsiString;
begin
  Result := '';
  vHexCode := '';
  vEncodePosition := 0;

  for i := 1 to Length(pText) do
  begin
    Case vEncodePosition of
    0:
      begin
        if pText[i] = '%' then
        begin
          vEncodePosition := 1;
        end
        else
        begin
          Result := Result + pText[i];
        end;
      end;
    1:
      begin
        if CharInSet(pText[i], AlphaNumericCharacters) then
        begin
          vHexCode := vHexCode + pText[i];
          Inc(vEncodePosition);
        end
        else //err
        begin
          Result := Result + '%' + pText[i];
          vEncodePosition := 0;
          vHexCode := '';
        end;
      end;
    2:
      begin
        if CharInSet(pText[i], AlphaNumericCharacters) then
        begin
          vHexCode := vHexCode + pText[i];
          Result := Result + AnsiString(Chr(StrToInt(Format('$%s',[vHexCode]))));
          vEncodePosition := 0;
          vHexCode := '';
        end
        else //err
        begin
          Result := Result + '%' + vHexCode + pText[i];
          vEncodePosition := 0;
          vHexCode := '';
        end;
      end;
    end;
  end;

  //Check for invalid characters on the tail end..
  if vEncodePosition = 1 then
  begin
    Result := Result + '%';
  end
  else if vEncodePosition = 2 then
  begin
    Result := Result + '%' + vHexCode;
  end;
end;


end.
