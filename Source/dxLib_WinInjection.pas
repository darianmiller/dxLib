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

unit dxLib_WinInjection;

interface
{$I dxLib.inc}

uses
  dxLib_WinApi,
  {$IFDEF DX_UnitScopeNames}
  Winapi.Windows;
  {$ELSE}
  Windows;
  {$ENDIF}

  function InjectDLL(const pTargetProcessID:DWORD; const pSourceDLLFullPathName:string; const pSuppressOSError:Boolean=True):Boolean;


implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$ENDIF}
  dxLib_Strings,
  dxLib_Types;


function InjectDLL(const pTargetProcessID:DWORD; const pSourceDLLFullPathName:string; const pSuppressOSError:Boolean=True):Boolean;
var
  vKernal32Handle:HMODULE;
  vTargetProcessHandle:THandle;
  vRemoteThreadID:DWORD;
  vRemoteThreadHandle:THandle;
  pRemoteBuffer:Pointer;
  vBytesToWrite,vBytesWritten:NativeUInt; //UInt, SIZE_T.  Some type cleanup in dxLib_Types for working with multiple Delphi versions
  vLoadLibraryProc:FARPROC;
begin
  Result := False;
  if ValidHandleValue(pTargetProcessID) then
  begin
    vBytesToWrite := ByteLength(pSourceDLLFullPathName) + 1;

    vTargetProcessHandle := OpenProcess(PROCESS_CREATE_THREAD or PROCESS_QUERY_INFORMATION or PROCESS_VM_OPERATION or PROCESS_VM_WRITE or PROCESS_VM_READ, False, pTargetProcessID);
    if vTargetProcessHandle <> 0 then
    begin
      try
        pRemoteBuffer := VirtualAllocEx(vTargetProcessHandle, nil, vBytesToWrite, MEM_COMMIT, PAGE_READWRITE);
        if pRemoteBuffer <> nil then
        begin
          try
            if WriteProcessMemory(vTargetProcessHandle, pRemoteBuffer, PChar(pSourceDLLFullPathName), vBytesToWrite, vBytesWritten) then
            begin
              vKernal32Handle := GetModuleHandle('kernel32.dll');
              if vKernal32Handle <> 0 then
              begin
                {$IFDEF UNICODE}
                vLoadLibraryProc := GetProcAddress(vKernal32Handle, 'LoadLibraryW');
                {$ELSE}
                vLoadLibraryProc := GetProcAddress(vKernal32Handle, 'LoadLibraryA');
                {$ENDIF UNICODE}
                if vLoadLibraryProc <> nil then
                begin
                  vRemoteThreadHandle := CreateRemoteThread(vTargetProcessHandle, nil, 0, vLoadLibraryProc, pRemoteBuffer, 0, vRemoteThreadID);
                  if vRemoteThreadHandle <> 0 then
                  begin
                    try
                      WaitForSingleObject(vRemoteThreadHandle, INFINITE);
                      Result := True;
                    finally
                      CloseHandle(vRemoteThreadHandle);
                    end;
                  end;
                end;
              end;
            end;
          finally
            VirtualFreeEx(vTargetProcessHandle, pRemoteBuffer, 0, MEM_RELEASE);
          end;
        end;
      finally
        CloseHandle(vTargetProcessHandle);
      end;
    end;

    if not Result then
    begin
      if not pSuppressOSError then
      begin
        RaiseLastWindowsError();
      end;
    end;
  end;
end;

(*
https://stackoverflow.com/questions/12180732/do-i-need-to-adjust-token-privileges-in-order-to-successfully-call-createremotet
https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess
https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualallocex
https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-writeprocessmemory  (requires: PROCESS_VM_OPERATION)
https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createremotethread  (requires: PROCESS_CREATE_THREAD, PROCESS_QUERY_INFORMATION, PROCESS_VM_OPERATION, PROCESS_VM_WRITE, and PROCESS_VM_READ)
*)


end.
