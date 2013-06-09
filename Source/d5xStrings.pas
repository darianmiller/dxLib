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
unit d5xStrings;

interface

  function LowString():Integer;
  function HighString(const pValue:String):Integer; overload;
  {$IFDEF STRING_IS_UNICODE}
  function HighString(const pValue:AnsiString):Integer; overload;
  {$ENDIF}

  function IsPrintableCharacter(const pChar:Char):Boolean; overload;
  {$IFDEF STRING_IS_UNICODE}
  function IsPrintableCharacter(const pChar:AnsiChar):Boolean; overload;
  {$ENDIF}


implementation


//1 for Legacy Delphi compilers
//0 for Zero Based Strings / NextGen Compilers
function LowString():Integer;
begin
  //todo: ZBS
  Result := 1;
end;


function HighString(const pValue:String):Integer;
begin
  //todo: ZBS
  Result := Length(pValue);
end;


{$IFDEF STRING_IS_UNICODE}
function HighString(const pValue:AnsiString):Integer;
begin
  //todo: ZBS
  Result := Length(pValue);
end;
{$ENDIF}


function IsPrintableCharacter(const pChar:Char):Boolean;
begin
  Result := (Ord(pChar) >= 32) and (Ord(pChar) <= 126);
end;


{$IFDEF STRING_IS_UNICODE}
function IsPrintableCharacter(const pChar:AnsiChar):Boolean;
begin
  Result := (Ord(pChar) >= 32) and (Ord(pChar) <= 126);
end;
{$ENDIF}

end.
