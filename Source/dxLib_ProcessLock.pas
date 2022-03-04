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

unit dxLib_ProcessLock;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  Winapi.Windows;
  {$ELSE}
  Windows;
  {$ENDIF}

const
  DefSpinCount = 3800;

type
  {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
  /// <summary>
  ///   Wrapper around TRTLCriticalSection for protecting access to shared
  ///   resources across multiple threads of a process
  /// </summary>
  /// <remarks>
  ///   MSDN: The threads of a single process can use a critical section object
  ///   for mutual-exclusion synchronization. There is no guarantee about the
  ///   order that threads obtain ownership of the critical section. However,
  ///   the system is fair to all threads.
  /// </remarks>
  {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
  TdxProcessResourceLock = class(TObject)
  private
    fProcessWideLock:TRTLCriticalSection;
    fSpinCount:DWord;
    {$IFDEF NODEF}{$REGION 'MultiCorePerformanceTweak'}{$ENDIF}
      {$IFNDEF DELPHIXE2_UP} //Addressed in XE2 and no longer needed
        {$HINTS OFF} //Ignore 'private symbol declared but never used'
        fCacheLineFiller:array[0..95] of Byte; //see: http://delphitools.info/2011/11/30/fixing-tcriticalsection/
        {$HINTS ON}
      {$ENDIF}
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}

    function GetSpinCount:DWord;
    procedure SetSpinCount(const pValue:DWord);
  public
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    /// <remarks>
    ///   The DefSpinCount comes from a reference on MSDN
    ///   http://msdn.microsoft.com/en-us/library/windows/desktop/ms686197(v=vs.85).aspx
    ///   You can improve performance significantly by choosing a small spin
    ///   count for a critical section of short duration. The heap manager uses
    ///   a spin count of roughly 4000 for its per-heap critical sections. This
    ///   gives great performance and scalability in almost all worst-case
    ///   scenarios.
    /// </remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    constructor Create(const pSpinCount:DWord=DefSpinCount);
    destructor Destroy(); override;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The spin count for the critical section object.
    ///</summary>
    ///<remarks>
    /// MSDN: On single-processor systems, the spin count is ignored and the
    /// critical section spin count is set to zero (0). On multiprocessor
    /// systems, if the critical section is unavailable, the calling thread
    /// spins dwSpinCount times before performing a wait operation on a
    /// semaphore associated with the critical section. If the critical section
    /// becomes free during the spin operation, the calling thread avoids the
    /// wait operation.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property SpinCount:DWord Read GetSpinCount Write SetSpinCount;

    procedure Lock();
    procedure Unlock();

    function TryLock():Boolean;
  end;


implementation


constructor TdxProcessResourceLock.Create(const pSpinCount:DWord=DefSpinCount);
begin
  inherited Create();
  if pSpinCount <= 0 then
  begin
    InitializeCriticalSection(fProcessWideLock);
  end
  else
  begin
    InitializeCriticalSectionAndSpinCount(fProcessWideLock, pSpinCount);
  end;
end;


destructor TdxProcessResourceLock.Destroy();
begin
  DeleteCriticalSection(fProcessWideLock);
  inherited Destroy();
end;


procedure TdxProcessResourceLock.Lock();
begin
  EnterCriticalSection(fProcessWideLock);
end;


procedure TdxProcessResourceLock.Unlock();
begin
  LeaveCriticalSection(fProcessWideLock);
end;


function TdxProcessResourceLock.TryLock():Boolean;
begin
  Result := TryEnterCriticalSection(fProcessWideLock);
end;


function TdxProcessResourceLock.GetSpinCount():DWord;
begin
  Result := fSpinCount;
end;


procedure TdxProcessResourceLock.SetSpinCount(const pValue:DWord);
begin
  fSpinCount := SetCriticalSectionSpinCount(fProcessWideLock, pValue);
end;


end.
