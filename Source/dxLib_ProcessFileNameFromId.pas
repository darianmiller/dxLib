(*
Copyright (c) 2019 Darian Miller
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

As of November 2019, latest version available online at:
  https://github.com/darianmiller/dxLib
*)
unit dxLib_ProcessFileNameFromId;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  Winapi.Windows;
  {$ELSE}
  Windows;
  {$ENDIF}

type

  {$IFDEF UNICODE}
  TQueryFullProcessImageName = function(HProcess:THandle; dwFlags:DWORD; lpExeName:PWideChar; var lpdwSize:DWORD):BOOL; stdcall;
  {$ELSE}
  TQueryFullProcessImageName = function(HProcess:THandle; dwFlags:DWORD; lpExeName:PAnsiChar; var lpdwSize:DWORD):BOOL; stdcall;
  {$ENDIF}

const

  {$IFDEF UNICODE}
  QueryFullProcessImageName = 'QueryFullProcessImageNameW';
  {$ELSE}
  QueryFullProcessImageName = 'QueryFullProcessImageNameA';
  {$ENDIF}

type

  TdxProcessNameToId = class
  private
    fQueryFullProcessImageName:TQueryFullProcessImageName;
  public
    constructor Create();
    function GetFileNameByProcessID(const pTargetProcessID:DWORD):string;
  end;


implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$ENDIF}
  dxLib_WinAPI;


constructor TdxProcessNameToId.Create();
var
  h:HMODULE;
begin
  inherited;
  h := GetModuleHandle('kernel32.dll');
  @fQueryFullProcessImageName := GetProcAddress(h, QueryFullProcessImageName);
end;


//requires Vista or later
function TdxProcessNameToId.GetFileNameByProcessID(const pTargetProcessID:DWORD):string;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $00001000;
var
  h:THandle;
  S:DWORD;
begin
  Result := '';
  if not Assigned(fQueryFullProcessImageName) then RaiseLastWindowsError();

  h := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pTargetProcessID);
  if not ValidHandleValue(h) then RaiseLastWindowsError();
  try
    S := MAX_PATH;
    SetLength(Result, S + 1);
    while not fQueryFullProcessImageName(h, 0, PChar(Result), S) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) do
    begin
      S := S * 2;
      SetLength(Result, S + 1);
    end;
    SetLength(Result, S);
    Inc(S);
    if not fQueryFullProcessImageName(h, 0, PChar(Result), S) then
    begin
      RaiseLastWindowsError();
    end;
  finally
    CloseHandle(h);
  end;
end;


end.
