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
unit dxLib_TestRunner;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  Vcl.Forms,
  {$ELSE}
  Forms,
  {$ENDIF}
  TestFramework,
  GUITestRunner,
  TextTestRunner;


  procedure RunRegisteredTests();

implementation
uses
  dxLib_System;


procedure RunRegisteredTests();
begin
  Application.Initialize;

  if IsConsole then
  begin
    {$IFDEF FINALBUILDER_XMLOUTPUT}
    if ParamCount > 0 then
    begin
      FinalBuilder.XMLTestRunner.RunRegisteredTests(ParamStr(1));
    end
    else //Creates 'dunit-report.xml'
    begin
      FinalBuilder.XMLTestRunner.RunRegisteredTests;
    end;
    {$ELSE}
    TextTestRunner.RunRegisteredTests;

    if IsDebuggerPresent then
    begin
      Readln; //Pause to allow developer to view console app results
    end;
   {$ENDIF}
  end
  else
  begin
    GUITestRunner.RunRegisteredTests;
  end;
end;


end.
