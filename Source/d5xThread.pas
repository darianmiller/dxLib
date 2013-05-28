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
*)

{$I d5x.inc}
unit d5xThread;

interface

uses
  Classes,
  Windows,
  SysUtils,
  SyncObjs,
  d5xProcessLock;


type

  T5xThread = class;
  T5xNotifyThreadEvent = procedure(const pThread:T5xThread) of object;
  T5xExceptionEvent = procedure(pSender:TObject; pException:Exception) of object;


  T5xThreadState = (tsActive,
                    tsSuspended_NotYetStarted,
                    tsSuspended_ManuallyStopped,
                    tsSuspended_RunOnceCompleted,
                    tsSuspendPending_StopRequestReceived,
                    tsSuspendPending_RunOnceComplete,
                    tsTerminated);

  T5xThreadExecOptions = (teRepeatRun,
                          teRunThenSuspend,
                          teRunThenFree);



  //A TThread that can be managed (started/stopped) externally
  T5xThread = class(TThread)
  private
    fThreadState:T5xThreadState;
    fTrappedException:Exception;
    fOnException:T5xExceptionEvent;
    fOnRunCompletion:T5xNotifyThreadEvent;
    fOnReportProgress:TGetStrProc;
    fStateChangeLock:T5xProcessResourceLock;
    fAbortableSleepEvent:TEvent;
    fResumeSignal:TEvent;
    fAwakeToFreeEvent:TEvent;
    fStartOption:T5xThreadExecOptions;
    fProgressTextToReport:String;
    fRequireCoinitialize:Boolean;
    function GetThreadState():T5xThreadState;
    procedure SuspendThread(const pReason:T5xThreadState);
    procedure Sync_CallOnReportProgress();
    procedure Sync_CallOnRunCompletion();
    procedure Sync_CallOnException();
    procedure DoOnRunCompletion();
    procedure DoOnException();
    property ThreadState:T5xThreadState read GetThreadState;
    procedure CallSynchronize(pMethod:TThreadMethod);
  protected
    procedure Execute(); override;

    procedure BeforeRun(); virtual;      // Override as needed
    procedure Run(); virtual; ABSTRACT;  // Must override
    procedure AfterRun(); virtual;       // Override as needed

    procedure WaitForResume(); virtual;
    procedure ThreadHasResumed(); virtual;
    function ExternalRequestToStop():Boolean; virtual;
    procedure ReportProgress(const pAnyProgressText:string);

    procedure Sleep(const pSleepTimeMS:Integer); //abortable sleep

    property StartOption:T5xThreadExecOptions read fStartOption write fStartOption;
    property RequireCoinitialize:Boolean read fRequireCoinitialize write fRequireCoinitialize;
    function WaitForHandle(const pHandle:THandle):Boolean;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    function Start(const pExecOption:T5xThreadExecOptions=teRepeatRun):Boolean;
    function Stop():Boolean;

    function CanBeStarted():Boolean;
    function ThreadIsActive():Boolean;

    property OnException:T5xExceptionEvent read fOnException write fOnException;
    property OnRunCompletion:T5xNotifyThreadEvent read fOnRunCompletion write fOnRunCompletion;
    property OnReportProgress:TGetStrProc read fOnReportProgress write fOnReportProgress;
  end;


implementation

uses
  ActiveX,
  d5xWinApi;


constructor T5xThread.Create();
begin
  inherited Create(True); //We always create suspended, user must always call Start()
  fThreadState := tsSuspended_NotYetStarted;
  fStateChangeLock := T5xProcessResourceLock.Create();
  fAbortableSleepEvent := TEvent.Create(nil, True, False, '');
  fResumeSignal := TEvent.Create(nil, True, False, '');
end;


destructor T5xThread.Destroy();
begin
  if fThreadState = tsSuspended_NotYetStarted then
  begin
    //Workaround for issue of freeing a non-started thread
    //that was created in suspended mode
    fAwakeToFreeEvent := TEvent.Create(nil, True, False, '');
    try
      Start();
      if GetCurrentThreadID = MainThreadID then
      begin
        WaitWithMessageLoop(fAwakeToFreeEvent.Handle, INFINITE);
      end
      else
      begin
        fAwakeToFreeEvent.WaitFor(INFINITE);
      end;
    finally
      FreeAndNil(fAwakeToFreeEvent);
    end;
  end;
  fAbortableSleepEvent.SetEvent();
  fResumeSignal.SetEvent();
  inherited;
  fStateChangeLock.Free();
  fResumeSignal.Free();
  fAbortableSleepEvent.Free();
end;


procedure T5xThread.Execute();
begin
  try
    if Assigned(fAwakeToFreeEvent) then
    begin
      //We've awoken a thread created in Suspend mode simply to free it
      fAwakeToFreeEvent.SetEvent();
      Terminate();
      Exit;
    end;
    
    while not Terminated do
    begin
      if fRequireCoinitialize then
      begin
        CoInitialize(nil);
      end;
      try
        ThreadHasResumed();
        BeforeRun();
        try
          while ThreadIsActive() do // check for stop, externalstop, terminate
          begin
            Run(); //descendant's code
            DoOnRunCompletion();

            case fStartOption of
            teRepeatRun:
              begin
                //loop
              end;
            teRunThenSuspend:
              begin
                SuspendThread(tsSuspendPending_RunOnceComplete);
                Break;
              end;
            teRunThenFree:
              begin
                FreeOnTerminate := True;
                Terminate();
                Break;
              end;
            end;
          end; //while ThreadIsActive()
        finally
          AfterRun();
        end;
      finally
        if fRequireCoinitialize then
        begin
          //ensure this is called if thread is to be frozen
          CoUnInitialize();
        end;
      end;

      WaitForResume;
      // -- RESUME -- thread
      //Note: Only two reasons to wake up a suspended thread:
      //1: We are going to terminate it
      //2: we want it to restart doing work
    end; //while not Terminated
  except
    on E:Exception do
    begin
      fTrappedException := E;
      DoOnException();
    end;
  end;
end;


procedure T5xThread.WaitForResume();
begin
  fStateChangeLock.Lock();
  try
    if fThreadState = tsSuspendPending_StopRequestReceived then
    begin
      fThreadState := tsSuspended_ManuallyStopped;
    end
    else if fThreadState = tsSuspendPending_RunOnceComplete then
    begin
      fThreadState := tsSuspended_RunOnceCompleted;
    end;

    fResumeSignal.ResetEvent();
    fAbortableSleepEvent.ResetEvent();
  finally
    fStateChangeLock.Unlock();
  end;

  WaitForHandle(fResumeSignal.Handle);
end;


procedure T5xThread.ThreadHasResumed();
begin
  fAbortableSleepEvent.ResetEvent();
  fResumeSignal.ResetEvent();
end;


function T5xThread.ExternalRequestToStop:Boolean;
begin
  //Intended to be overriden - for descendant's use as needed
  Result := False;
end;


procedure T5xThread.BeforeRun();
begin
  //Intended to be overriden - for descendant's use as needed
end;


procedure T5xThread.AfterRun();
begin
  //Intended to be overriden - for descendant's use as needed
end;


function T5xThread.Start(const pExecOption:T5xThreadExecOptions=teRepeatRun):Boolean;
begin
  if fStateChangeLock.TryLock() then
  begin
    try
      StartOption := pExecOption;

      Result := CanBeStarted();
      if Result then
      begin
        if fThreadState = tsSuspended_NotYetStarted then
        begin
          fThreadState := tsActive;
          //We haven't started Exec loop at all yet
          //Since we start all threads in suspended state, we need one initial Resume()
         {$IFDEF RESUME_DEPRECATED}
           inherited Start();
         {$ELSE}
           Resume();
         {$ENDIF}
        end
        else
        begin
          fThreadState := tsActive;
          //we're waiting on Exec, wake up and continue processing
          fResumeSignal.SetEvent();
        end;
      end;
    finally
      fStateChangeLock.Unlock();
    end;
  end
  else //thread is not asleep
  begin
    Result := False;
  end;
end;


function T5xThread.Stop():Boolean;
begin
  if StartOption <> teRunThenFree then
  begin
    fStateChangeLock.Lock();
    try
      if ThreadIsActive() then
      begin
        Result := True;
        SuspendThread(tsSuspendPending_StopRequestReceived);
      end
      else
      begin
        Result := False;
      end;
    finally
      fStateChangeLock.Unlock();
    end;
  end
  else
  begin
    //Never allowed to stop a FreeOnTerminate thread
    //Cannot control thread termination from outside
    Result := False;
  end;
end;


procedure T5xThread.SuspendThread(const pReason:T5xThreadState);
begin
  fStateChangeLock.Lock();
  try
    fThreadState := pReason; //will auto-suspend thread in Exec
    fAbortableSleepEvent.SetEvent();
  finally
    fStateChangeLock.Unlock();
  end;
end;


procedure T5xThread.Sync_CallOnRunCompletion();
begin
  if not Terminated then
  begin
    fOnRunCompletion(Self);
  end;
end;


procedure T5xThread.DoOnRunCompletion();
begin
  if Assigned(fOnRunCompletion) then
  begin
    CallSynchronize(Sync_CallOnRunCompletion);
  end;
end;

procedure T5xThread.Sync_CallOnException();
begin
  if not Terminated then
  begin
    fOnException(self, fTrappedException);
  end;
end;

procedure T5xThread.DoOnException();
begin
  if Assigned(fOnException) then
  begin
    CallSynchronize(Sync_CallOnException);
  end;
  fTrappedException := nil;
end;


function T5xThread.GetThreadState():T5xThreadState;
begin
  fStateChangeLock.Lock();
  try
    if Terminated then
    begin
      fThreadState := tsTerminated;
    end
    else if ExternalRequestToStop() then
    begin
      fThreadState := tsSuspendPending_StopRequestReceived;
    end;
    Result := fThreadState;
  finally
    fStateChangeLock.Unlock();
  end;
end;


function T5xThread.CanBeStarted():Boolean;
begin
  if Assigned(fAwakeToFreeEvent) then
  begin
    //special case - wake up suspended thread simply to shutdown/free
    Result := True;
    Exit;
  end;


  if fStateChangeLock.TryLock() then
  begin
    try
      Result := (not Terminated) and
                (fThreadState in [tsSuspended_NotYetStarted,
                                  tsSuspended_ManuallyStopped,
                                  tsSuspended_RunOnceCompleted]);

    finally
      fStateChangeLock.UnLock();
    end;
  end
  else //thread isn't asleep
  begin
    Result := False;
  end;
end;


function T5xThread.ThreadIsActive():Boolean;
begin
  Result := (not Terminated) and (ThreadState = tsActive);
end;


procedure T5xThread.Sleep(const pSleepTimeMS:Integer);
begin
  if not Terminated then
  begin
    fAbortableSleepEvent.WaitFor(pSleepTimeMS);
  end;
end;


procedure T5xThread.CallSynchronize(pMethod:TThreadMethod);
begin
  Synchronize(pMethod);
end;


procedure T5xThread.Sync_CallOnReportProgress();
begin
  if not Terminated then
  begin
    fOnReportProgress(fProgressTextToReport);
  end;
end;


procedure T5xThread.ReportProgress(const pAnyProgressText:string);
begin
  if Assigned(fOnReportProgress) then
  begin
    fProgressTextToReport := pAnyProgressText;
    CallSynchronize(Sync_CallOnReportProgress);
  end;
end;


function T5xThread.WaitForHandle(const pHandle:THandle):Boolean;
const
  WaitForAll = False;
  IterateTimeOutMilliseconds = 200;
var
  vWaitForEventHandles:array[0..1] of THandle;
  vWaitForResponse:DWord;
begin
  Result := False;
  vWaitForEventHandles[0] := pHandle;   //initially for: fResumeSignal.Handle;
  vWaitForEventHandles[1] := fAbortableSleepEvent.Handle;
  while not Terminated do
  begin
    vWaitForResponse := WaitForMultipleObjects(2, @vWaitForEventHandles[0], WaitForAll, IterateTimeOutMilliseconds);
    case vWaitForResponse of
    WAIT_TIMEOUT:
      begin
        Continue;
      end;
    WAIT_OBJECT_0:
      begin
        Result := True;  //initially for Resume, but also for descendants to use
        Break;
      end;
    WAIT_OBJECT_0 + 1:
      begin
        fAbortableSleepEvent.ResetEvent(); //likely a stop received while we are waiting for an external handle
        Break;
      end;
    WAIT_FAILED:
       begin
         {$IFDEF DELPHI6_UP}
         RaiseLastOSError;
         {$ELSE}
         RaiseLastWin32Error;
         {$ENDIF}
       end;
    end;
  end;
end;


end.
