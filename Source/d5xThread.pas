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
unit d5xThread;

interface

uses
  Classes,
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
                    tsTerminationPending_DestroyInProgress,
                    tsSuspendPending_StopRequestReceived,
                    tsSuspendPending_RunOnceComplete,
                    tsTerminated);

  T5xThreadExecOptions = (teRepeatRun,
                          teRunThenSuspend,
                          teRunThenFree);



  T5xThread = class(TThread)
  private
    fThreadState:T5xThreadState;
    fOnException:T5xExceptionEvent;
    fOnRunCompletion:T5xNotifyThreadEvent;
    fOnReportProgress:TGetStrProc;
    fStateChangeLock:T5xProcessResourceLock;
    fAbortableSleepEvent:TEvent;
    fResumeSignal:TEvent;
    fTerminateSignal:TEvent;
    fExecDoneSignal:TEvent;
    fStartOption:T5xThreadExecOptions;
    fProgressTextToReport:String;
    fRequireCoinitialize:Boolean;
    function GetThreadState():T5xThreadState;
    procedure SuspendThread(const pReason:T5xThreadState);
    procedure Sync_CallOnReportProgress();
    procedure Sync_CallOnRunCompletion();
    procedure DoOnRunCompletion();
    property ThreadState:T5xThreadState read GetThreadState;
    procedure CallSynchronize(Method: TThreadMethod);
  protected
    procedure Execute(); override;

    procedure BeforeRun(); virtual;      // Override as needed
    procedure Run(); virtual; ABSTRACT;  // Must override
    procedure AfterRun(); virtual;       // Override as needed

    procedure Suspending(); virtual;
    procedure Resumed(); virtual;
    function ExternalRequestToStop():Boolean; virtual;
    procedure ReportProgress(const pAnyProgressText:string);
    function ShouldTerminate():Boolean;

    procedure Sleep(const pSleepTimeMS:Integer);

    property StartOption:T5xThreadExecOptions read fStartOption write fStartOption;
    property RequireCoinitialize:Boolean read fRequireCoinitialize write fRequireCoinitialize;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    function Start(const pExecOption:T5xThreadExecOptions=teRepeatRun):Boolean;
    function Stop():Boolean;  //not intended for use if StartOption is RunThenFree

    function CanBeStarted():Boolean;
    function ThreadIsActive():Boolean;

    property OnException:T5xExceptionEvent read fOnException write fOnException;
    property OnRunCompletion:T5xNotifyThreadEvent read fOnRunCompletion write fOnRunCompletion;
    property OnReportProgress:TGetStrProc read fOnReportProgress write fOnReportProgress;
  end;


implementation

uses
  ActiveX,
  Windows;


constructor T5xThread.Create();
begin
  inherited Create(True); //We always create suspended, user must call .Start()
  fThreadState := tsSuspended_NotYetStarted;
  fStateChangeLock := T5xProcessResourceLock.Create();
  fAbortableSleepEvent := TEvent.Create(nil, True, False, '');
  fResumeSignal := TEvent.Create(nil, True, False, '');
  fTerminateSignal := TEvent.Create(nil, True, False, '');
  fExecDoneSignal := TEvent.Create(nil, True, False, '');
end;


destructor T5xThread.Destroy();
begin
  if ThreadState <> tsSuspended_NotYetStarted then
  begin
    fTerminateSignal.SetEvent();
    SuspendThread(tsTerminationPending_DestroyInProgress);
    fExecDoneSignal.WaitFor(INFINITE); //we need to wait until we are done before inherited gets called and locks up as FFinished is not yet set
  end;
  inherited;
  fAbortableSleepEvent.Free();
  fStateChangeLock.Free();
  fResumeSignal.Free();
  fTerminateSignal.Free();
  fExecDoneSignal.Free();
end;


procedure T5xThread.Execute();

            procedure WaitForResume();
            var
              vWaitForEventHandles:array[0..1] of THandle;
              vWaitForResponse:DWORD;
            begin
              vWaitForEventHandles[0] := fResumeSignal.Handle;
              vWaitForEventHandles[1] := fTerminateSignal.Handle;
              vWaitForResponse := WaitForMultipleObjects(2, @vWaitForEventHandles[0], False, INFINITE);
              case vWaitForResponse of
              WAIT_OBJECT_0 + 1: Terminate;
              WAIT_FAILED: RaiseLastWin32Error; //D6+ =RaiseLastOSError;
              //else resume
              end;
            end;
var
  vCoInitCalled:Boolean;
begin
  vCoInitCalled := False;
  
  try
    try
      while not ShouldTerminate() do
      begin
        if not ThreadIsActive() then
        begin
          if ShouldTerminate() then Break;
          Suspending;
          WaitForResume();   //suspend()

          //Note: Only two reasons to wake up a suspended thread:
          //1: We are going to terminate it  2: we want it to restart doing work
          if ShouldTerminate() then Break;
          Resumed();
        end;

        if fRequireCoinitialize then
        begin
          CoInitialize(nil);
          vCoInitCalled := True;
        end;
        try
          BeforeRun();
          try
            while ThreadIsActive() do
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
              else
                begin
                  raise Exception.Create('Invalid StartOption detected in Execute()');
                end;
              end;
            end;
          finally
            AfterRun();
          end;
        finally
          if vCoInitCalled then
          begin
            CoUnInitialize();
          end;
        end;
      end; //while not ShouldTerminate()
    except
      on E:Exception do
      begin
        if Assigned(OnException) then
        begin
          OnException(self, E);
        end;
        Terminate();
      end;
    end;
  finally
    //since we have Resumed() this thread, we will wait until this event is
    //triggered before free'ing.
    fExecDoneSignal.SetEvent();
  end;
end;


procedure T5xThread.Suspending();
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
  finally
    fStateChangeLock.Unlock();
  end;
end;


procedure T5xThread.Resumed();
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
var
  vNeedToWakeFromSuspendedCreationState:Boolean;
begin
  vNeedToWakeFromSuspendedCreationState := False;

  fStateChangeLock.Lock();
  try
    StartOption := pExecOption;

    Result := CanBeStarted();
    if Result then
    begin
      if (fThreadState = tsSuspended_NotYetStarted) then
      begin
        //Resumed() will normally be called in the Exec loop but since we
        //haven't started yet, we need to do it here the first time only.
        Resumed();
        vNeedToWakeFromSuspendedCreationState := True;
      end;

      fThreadState := tsActive;

      //Resume();
      if vNeedToWakeFromSuspendedCreationState then
      begin
        //We haven't started Exec loop at all yet
        //Since we start all threads in suspended state, we need one initial Resume()
        Resume();
      end
      else
      begin
        //we're waiting on Exec, wake up and continue processing
        fResumeSignal.SetEvent();
      end;
    end;
  finally
    fStateChangeLock.Unlock();
  end;
end;


function T5xThread.Stop():Boolean;
begin
  if ThreadIsActive() then
  begin
    Result := True;
    SuspendThread(tsSuspendPending_StopRequestReceived);
  end
  else
  begin
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
  if Assigned(fOnRunCompletion) then fOnRunCompletion(Self);
end;


procedure T5xThread.DoOnRunCompletion();
begin
  if Assigned(fOnRunCompletion) then CallSynchronize(Sync_CallOnRunCompletion);
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
  Result := (ThreadState in [tsSuspended_NotYetStarted,
                             tsSuspended_ManuallyStopped,
                             tsSuspended_RunOnceCompleted]);
end;


function T5xThread.ThreadIsActive():Boolean;
begin
  Result := (ThreadState = tsActive);
end;


procedure T5xThread.Sleep(const pSleepTimeMS:Integer);
begin
  fAbortableSleepEvent.WaitFor(pSleepTimeMS);
end;


procedure T5xThread.CallSynchronize(Method: TThreadMethod);
begin
  if ThreadIsActive() then
  begin
    Synchronize(Method);
  end;
end;


function T5xThread.ShouldTerminate():Boolean;
begin
  Result := Terminated or
            (ThreadState in [tsTerminationPending_DestroyInProgress, tsTerminated]);
end;

procedure T5xThread.Sync_CallOnReportProgress();
begin
  if Assigned(fOnReportProgress) then
  begin
    fOnReportProgress(fProgressTextToReport);
  end;
end;


procedure T5xThread.ReportProgress(const pAnyProgressText:string);
begin
  if Assigned(fOnReportProgress) and ThreadIsActive then
  begin
    fProgressTextToReport := pAnyProgressText;
    CallSynchronize(Sync_CallOnReportProgress);
  end;
end;


end.
