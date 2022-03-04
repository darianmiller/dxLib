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
unit dxLib_Streams;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  System.Classes;
  {$ELSE}
  Classes;
  {$ENDIF}

  procedure AppendStream(const aDestination:TStream; const aString:String); overload;
  procedure AppendStream(const aDestination:TStream; const aChar:Char); overload;
  {$IFDEF DX_String_Is_UTF16}
  procedure AppendStream(const aDestination:TStream; const aChar:AnsiChar); overload;
  procedure AppendStream(const aDestination:TStream; const aString:AnsiString); overload;
  {$ENDIF}
  function MemoryStreamToString(const aSource:TMemoryStream):String;


implementation
uses
  System.SysUtils,
  dxLib_Strings;


procedure AppendStream(const aDestination:TStream; const aChar:Char); overload;
begin
  if aChar <> '' then
  begin
    aDestination.Write(aChar, ByteLength(aChar));
  end;
end;


{$IFDEF DX_String_Is_UTF16}
procedure AppendStream(const aDestination:TStream; const aChar:AnsiChar); overload;
begin
  if aChar <> '' then
  begin
    aDestination.Write(aChar, ByteLength(aChar));
  end;
end;

procedure AppendStream(const aDestination:TStream; const aString:AnsiString);
begin
  if Length(aString) > 0 then
  begin
    aDestination.Write(aString[1], ByteLength(aString));
  end;
end;
{$ENDIF}

procedure AppendStream(const aDestination:TStream; const aString:String);
begin
  if Length(aString) > 0 then
  begin
    aDestination.Write(aString[1], ByteLength(aString));
  end;
end;


function MemoryStreamToString(const aSource:TMemoryStream):String;
begin
  if Assigned(aSource) and (aSource.Size > 0) then
  begin
    SetString(Result, PChar(aSource.Memory), aSource.Size div SizeOf(Char));
  end
  else
  begin
    Result := '';
  end;
end;


end.
