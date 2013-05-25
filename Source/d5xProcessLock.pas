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
unit d5xProcessLock;

interface
uses
  Windows;

type
  T5xProcessResourceLock = class(TObject)
  protected
    fProcessWideLock:TRTLCriticalSection;
    {$IFNDEF DELPHIXE2_UP}
    //http://delphitools.info/2011/11/30/fixing-tcriticalsection/
    fCacheLineFiller:array[0..95] of Byte;
    {$ENDIF}
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Lock();
    procedure Unlock();
    
    function TryLock():Boolean;
  end;


implementation


constructor T5xProcessResourceLock.Create();
begin
  inherited Create();
  InitializeCriticalSection(fProcessWideLock);
end;


destructor T5xProcessResourceLock.Destroy();
begin
  DeleteCriticalSection(fProcessWideLock);
  inherited Destroy();
end;


procedure T5xProcessResourceLock.Lock();
begin
  EnterCriticalSection(fProcessWideLock);
end;


procedure T5xProcessResourceLock.Unlock();
begin
  LeaveCriticalSection(fProcessWideLock);
end;


function T5xProcessResourceLock.TryLock():Boolean;
begin
  Result := TryEnterCriticalSection(fProcessWideLock);
end;


end.
