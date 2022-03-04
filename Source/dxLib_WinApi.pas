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

unit dxLib_WinApi;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  Winapi.Windows,
  Winapi.Messages;
  {$ELSE}
  Windows,
  Messages;
  {$ENDIF}

  //Waits for signals to fire while processing pending message queue
  function WaitWithMessageLoop(const pHandleToWaitOn:THandle; const pMaxTimeToWaitMS:DWord=INFINITE):Boolean;

  function SendMessageToForm(const pDestination:THandle; const pMessage:String; const pMessageType:DWord=0):LRESULT;

  //helper methods
  function GetWMCopyDataString(const pMsg:TWMCopyData):String;
  function ValidHandleValue(const pHandle:THandle):Boolean;

  function GetWindowsFolder():string;
  function GetWindowsSystemRoot():string;

  procedure RaiseLastWindowsError();

implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils;
  {$ELSE}
  SysUtils;
  {$ENDIF}


function WaitWithMessageLoop(const pHandleToWaitOn:THandle; const pMaxTimeToWaitMS:DWord=INFINITE):Boolean;
const
  WaitAllOption = False;
  InitialTimeOutMS = 0;
  IterateTimeOutMS = 200;
var
  vTimeSpentWaitingMS:DWord;
  vReturnVal:DWord;
  Msg:TMsg;
  H:THandle;
begin
  H := pHandleToWaitOn;

  // MsgWaitForMultipleObjects doesn't return with already signaled objects
  // Check first
  vReturnVal := WaitForSingleObject(H, InitialTimeOutMS);
  if (vReturnVal = WAIT_OBJECT_0) then
  begin
    Result := True;
    Exit;
  end;

  vTimeSpentWaitingMS := 0;
  while True do
  begin

    if (pMaxTimeToWaitMS <> INFINITE) and (vTimeSpentWaitingMS >= pMaxTimeToWaitMS) then
    begin
      Result := False;
      Exit;
    end;

    //Also due to the way MsgWaitForMultipleObjects operates,
    //process pending messages first (as existing pending messages apparently won't signal)
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      if Msg.Message = WM_QUIT then
      begin
        Result := False;
        Exit;
      end;
      TranslateMessage(Msg);
      DispatchMessage(Msg);

      vReturnVal := WaitForSingleObject(H, 0);
      if(vReturnVal = WAIT_OBJECT_0) then
      begin
        Result := True;
        Exit;
      end;
    end;


    // Now we've dispatched all the messages in the queue
    // use MsgWaitForMultipleObjects to either tell us there are
    // more messages to dispatch, or that our object has been signalled.
    vReturnVal := MsgWaitForMultipleObjects(1, H, WaitAllOption, IterateTimeOutMS, QS_ALLINPUT);

    Inc(vTimeSpentWaitingMS, IterateTimeOutMS);
    if (vReturnVal = WAIT_OBJECT_0) then
    begin
      // The event was signaled
      Result := True;
      Exit;
    end
    else if (vReturnVal = WAIT_OBJECT_0 + 1) then
    begin
      // New messages have come that need to be dispatched
      Continue;
    end
    else if (vReturnVal = WAIT_TIMEOUT) then
    begin
      // We hit our time limit, continue with the loop
      Continue;
    end
    else
    begin
      // Something else happened
      Result := False;
      Exit;
    end;
  end;
end;


//One blog article reference: Why are HANDLE return values so inconsistent
//http://blogs.msdn.com/b/oldnewthing/archive/2004/03/02/82639.aspx
function ValidHandleValue(const pHandle:THandle):Boolean;
begin
  Result := (pHandle <> INVALID_HANDLE_VALUE) and (pHandle <> 0);
end;


(*
1) Register public custom Message Type(s) with system:
  MyCustomMessageTYpe:DWord = 0;

  initialization  //or on main form creation, etc.
    MyCustomMessageType := RegisterWindowMessage('dxLib_CustomMessage');

2) Register to receive WM_COPYDATA messages on a form
  procedure WMCopyData(var Msg:TWMCopyData); message WM_COPYDATA;

  procedure TForm1.WMCopyData(var Msg: TWMCopyData);
  var
    vMessageString:String;
  begin
    if Msg.CopyDataStruct.dwData = MyCustomMessageType then //should filter on your custom message type
    begin
      SetString(vMessageString, PChar(Msg.CopyDataStruct.lpData), Msg.CopyDataStruct.cbData div SizeOf(Char));

      //do something with received message
      ShowMessage(vMessageString);
      Msg.Result := 13013;  //can optionally send a custom Result code back to Sender
    end
  end;

3) Send the form a message
   Can be from a background thread, from the same form, from a different form,
   or even from a different process.
   Return value is the optional Msg.Result code set by form processing the message (otherwise 0)

  SendMessageToForm(H, 'Hello', MyCustomMessageType);
*)
function SendMessageToForm(const pDestination:THandle; const pMessage:String; const pMessageType:DWord=0):LRESULT;
var
  vData:TCopyDataStruct;
begin
  vData.dwData := pMessageType;
  vData.cbData := (Length(pMessage)+1)*SizeOf(Char);
  vData.lpData := PChar(pMessage);

  Result := SendMessage(pDestination, WM_COPYDATA, wParam(pDestination), lParam(@vData));
end;


//helper method to prevent having to type this syntax every time
function GetWMCopyDataString(const pMsg:TWMCopyData):String;
begin
  SetString(Result, PChar(pMsg.CopyDataStruct.lpData), pMsg.CopyDataStruct.cbData div SizeOf(Char));
end;


function GetWindowsFolder():string;
var
  vLen:Integer;
begin
  Result := '';
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getwindowsdirectoryw
  vLen := GetWindowsDirectory(PChar(Result), MAX_PATH);
  if vLen > 0 then
  begin
    SetLength(Result, vLen);
  end
  else
  begin
    RaiseLastWindowsError();
  end;
end;


function GetWindowsSystemRoot():string;
var
  vLen:Integer;
begin
  Result := '';
  SetLength(Result, MAX_PATH);
  //https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemdirectoryw
  vLen := GetSystemDirectory(PChar(Result), MAX_PATH);
  if vLen > 0 then
  begin
    SetLength(Result, vLen);
  end
  else
  begin
    RaiseLastWindowsError();
  end;
end;


procedure RaiseLastWindowsError();
begin
  {$IFDEF DX_Supports_RaiseLastOSError}
  RaiseLastOSError();
  {$ELSE}
  RaiseLastWin32Error();
  {$ENDIF}
end;


end.
