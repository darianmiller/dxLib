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
unit dxLib_ProcessList;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  System.Contnrs,
  System.Classes,
  Winapi.Windows,
  Winapi.TlHelp32;
  {$ELSE}
  SysUtils,
  Contnrs,
  Classes,
  Windows,
  TlHelp32;
  {$ENDIF}

type

  //https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/ns-tlhelp32-processentry32
  TdxProcessEntryItem = class
  private
    fProcessID:DWORD;
    fThreads:DWORD;
    fParentProcessID:DWORD;
    fBasePriority:Longint;
    fExeFile:string;
    fOptionalFullPathName:string;
  public
    property ProcessID:DWORD read fProcessID write fProcessID;
    property Threads:DWORD read fThreads write fThreads;
    property ParentProcessID:DWORD read fParentProcessID write fParentProcessID;
    property BasePriority:Longint read fBasePriority write fBasePriority;
    property ExeFile:string read fExeFile write fExeFile;
    property OptionalFullPathName:string read fOptionalFullPathName write fOptionalFullPathName;
  end;

  TdxProcessEntryList = class(TObjectList)
  public
    function SnapShotActiveProcesses(const pLookupFullPathName:Boolean=False):Boolean;
  end;

  function SortProcessEntryByExeName(Item1, Item2: Pointer):Integer;

  
implementation
uses
  dxLib_ProcessFileNameFromId,
  dxLib_WinApi,
  dxLib_WinInjection;


//https://docs.microsoft.com/en-us/windows/win32/toolhelp/taking-a-snapshot-and-viewing-processes
function TdxProcessEntryList.SnapshotActiveProcesses(const pLookupFullPathName:Boolean=False):Boolean;
var
  h:THandle;
  vPE32:TProcessEntry32;
  vItem:TdxProcessEntryItem;
  vFoundAProcess:Boolean;
  vKeepItem:Boolean;
  vProcessLookup:TdxProcessNameToId;
begin
  Clear;

  vProcessLookup := nil;
  h := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if ValidHandleValue(h) then
  begin
    try
      vPE32.dwSize := SizeOf(vPE32);

      vFoundAProcess := Process32First(h, vPE32);
      while vFoundAProcess do
      begin
        vKeepItem := True;
        vItem := TdxProcessEntryItem.Create();
        try
          vItem.ProcessID := vPE32.th32ProcessID;
          vItem.Threads := vPE32.cntThreads;
          vItem.ParentProcessID := vPE32.th32ParentProcessID;
          vItem.BasePriority := vPE32.pcPriClassBase;
          vItem.ExeFile := vPE32.szExeFile;

          if pLookupFullPathName then
          begin
            if not Assigned(vProcessLookup) then
            begin
              vProcessLookup := TdxProcessNameToId.Create();
            end;
            try
              vItem.OptionalFullPathName := vProcessLookup.GetFileNameByProcessID(vItem.ProcessID);
            except
              //system process (or one we cannot access), skip as we desire list of active processes with full path names
              vKeepItem := False;
            end;
          end;

        finally
          if vKeepItem then
            Add(vItem)
          else
            vItem.Free();
        end;
        
        vFoundAProcess := Process32Next(h, vPE32);
      end;

    finally
      CloseHandle(h);
      vProcessLookup.Free();
    end;
  end;

  Result := (Count > 0);
end;


function SortProcessEntryByExeName(Item1, Item2: Pointer):Integer;
begin
  Result := CompareText(TdxProcessEntryItem(Item1).ExeFile, TdxProcessEntryItem(Item2).ExeFile);
end;

end.
