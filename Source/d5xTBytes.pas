(*
Copyright (c) 2013 Darian Miller

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

As of May 2013, latest version available online at:
  https://github.com/darianmiller/d5xlib

D5X Win32/Win64 Ready
*)

{$I d5x.inc}
unit d5xTBytes;

interface
uses
  SysUtils,
  Classes;

  {$IFNDEF TBYTES_DEFINED} //TBytes built-in D2007+
  type
    TBytes = Array of Byte;
  {$ENDIF}

  function Bytes(const A:Array of Byte):TBytes;

  procedure StringToBytes(const pSource:String; var pDestination:TBytes); overload;
  {$IFDEF STRING_IS_UNICODE}
  procedure StringToBytes(const pSource:AnsiString; var pDestination:TBytes); overload;
  {$ENDIF}

  procedure BytesToString(const pSource:TBytes; var pDestination:String); overload;
  {$IFDEF STRING_IS_UNICODE}
  procedure BytesToString(const pSource:TBytes; var pDestination:AnsiString); overload;
  {$ENDIF}

  procedure AppendBytes(const pSource:String; var pDestination:TBytes); overload;
  {$IFDEF STRING_IS_UNICODE}
  procedure AppendBytes(const pSource:AnsiString; var pDestination:TBytes); overload;
  {$ENDIF}
  procedure AppendBytes(const pSource:Array of Byte; var pDestination:TBytes; const pByteCount:Integer=0); overload;

  procedure CloneBytes(const pSource:TBytes; var pDestination:TBytes);

  procedure StreamToBytes(const pSource:TStream; var pDestination:TBytes);
  procedure BytesToStream(const pSource:TBytes; const pDestination:TStream);

  function RawToBytes(const pSource; const pSize:Integer):TBytes;


implementation
uses
  Math,
  d5xStrings;


function Bytes(const A:Array of Byte):TBytes;
var
  i:Integer;
begin
  SetLength(Result, Length(A));
  for i := Low(Result) to High(Result) do
  begin
    Result[i] := A[i];
  end;
end;


procedure StringToBytes(const pSource:String; var pDestination:TBytes);
begin
  SetLength(pDestination, Length(pSource) * SizeOf(Char));
  if Length(pSource) > 0 then
  begin
    Move(pSource[LowString], pDestination[0], Length(pDestination));
  end;
end;


{$IFDEF STRING_IS_UNICODE}
procedure StringToBytes(const pSource:AnsiString; var pDestination:TBytes);
begin
  SetLength(pDestination, Length(pSource) * SizeOf(AnsiChar));
  if Length(pSource) > 0 then
  begin
    Move(pSource[LowString], pDestination[0], Length(pDestination));
  end;
end;
{$ENDIF}


procedure BytesToString(const pSource:TBytes; var pDestination:String);
begin
  SetString(pDestination, PChar(@pSource[0]), Length(pSource) div SizeOf(Char));
end;

procedure BytesToString(const pSource:Array of Byte; var pDestination:String); overload;
begin
  SetString(pDestination, PChar(@pSource[0]), Length(pSource) div SizeOf(Char));
end;


{$IFDEF STRING_IS_UNICODE}
procedure BytesToString(const pSource:TBytes; var pDestination:AnsiString);
begin
  SetString(pDestination, PAnsiChar(@pSource[0]), Length(pSource));
end;
procedure BytesToString(const pSource:Array of Byte; var pDestination:AnsiString); overload;
begin
  SetString(pDestination, PAnsiChar(@pSource[0]), Length(pSource));
end;
{$ENDIF}


procedure AppendBytes(const pSource:String; var pDestination:TBytes);
var
  vDestLen:Integer;
  vAppendLen:Integer;
begin
  vAppendLen := Length(pSource) * SizeOf(Char);
  if vAppendLen > 0 then
  begin
    vDestLen := Length(pDestination);
    SetLength(pDestination, vDestLen + vAppendLen);
    Move(pSource[LowString], pDestination[vDestLen], vAppendLen);
  end;
end;


{$IFDEF STRING_IS_UNICODE}
procedure AppendBytes(const pSource:AnsiString; var pDestination:TBytes); overload;
var
  vDestLen:Integer;
  vAppendLen:Integer;
begin
  vAppendLen := Length(pSource) * SizeOf(AnsiChar);
  if vAppendLen > 0 then
  begin
    vDestLen := Length(pDestination);
    SetLength(pDestination, vDestLen + vAppendLen);
    Move(pSource[LowString], pDestination[vDestLen], vAppendLen);
  end;
end;
{$ENDIF}


procedure AppendBytes(const pSource:Array of Byte; var pDestination:TBytes; const pByteCount:Integer=0);
var
  vDestLen:Integer;
  vAppendLen:Integer;
begin
  vAppendLen := Length(pSource);
  if pByteCount > 0 then
  begin
    vAppendLen := Min(pByteCount, vAppendLen);
  end;
  if vAppendLen > 0 then
  begin
    vDestLen := Length(pDestination);
    SetLength(pDestination, vDestLen + vAppendLen);
    Move(pSource[Low(pSource)], pDestination[vDestLen], vAppendLen);
  end;
end;


procedure CloneBytes(const pSource:TBytes; var pDestination:TBytes);
begin
  if Length(pSource) > 0 then
  begin
    SetLength(pDestination, Length(pSource));
    Move(pSource[Low(pSource)], pDestination[0], Length(pDestination));
  end
  else
  begin
    pDestination := nil;
  end;
end;


procedure StreamToBytes(const pSource:TStream; var pDestination:TBytes);
var
  vSourceSize:Int64;
begin
  If Assigned(pSource) then
  begin
    vSourceSize := pSource.Size;
    pSource.Position := 0;
    SetLength(pDestination, vSourceSize);
    pSource.Read(pDestination[0], vSourceSize);
  end;
end;


procedure BytesToStream(const pSource:TBytes; const pDestination:TStream);
begin
  pDestination.WriteBuffer(pSource[0], Length(pSource));
end;


function RawToBytes(const pSource; const pSize:Integer):TBytes;
begin
  SetLength(Result, pSize);
  Move(pSource, Result[0], pSize);
end;


end.
