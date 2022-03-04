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
unit dxLib_RTTI;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  System.Classes,
  System.TypInfo;
  {$ELSE}
  Classes,
  TypInfo;
  {$ENDIF}

  procedure SetPublishedPropertyDefaultsViaRTTI(const aInstance:TPersistent);


const
  //D10 Seattle DOC: The default/nodefault directives are supported only for ordinal types and for set types (provided the upper/lower bounds of the set's base type have ordinal values between 0 and 31)
  //[dcc32 Error] E2146 Default values must be of ordinal, pointer or small set type
  PROPERTIES_WITH_DEFAULT_VALUES = [tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration, tkSet];

  //D10 Seattle DOC: Note: You can't use the ordinal value 2147483648 as a default value. This value is used internally to represent nodefault.
  NO_DEFAULT_VALUE_PROPERTY_FLAG = Low(LongInt);  //D5 Use Low(LongInt) instead of -2147483648 or $80000000


implementation
uses
  dxLib_ClassPropertyArray;


procedure SetPublishedPropertyDefaultsViaRTTI(const aInstance:TPersistent);
var
  i:Integer;
  vClassPropertyArray:TdxClassPropertyArray;
  vPropertyInfo:PPropInfo;
begin
  vClassPropertyArray := TdxClassPropertyArray.Create(aInstance, PROPERTIES_WITH_DEFAULT_VALUES);
  try
    for i := 0 to vClassPropertyArray.Count-1 do
    begin
      vPropertyInfo := vClassPropertyArray.Items[i];
      if not (vPropertyInfo.Default = NO_DEFAULT_VALUE_PROPERTY_FLAG) then
      begin
        if vPropertyInfo.PropType^.Kind = tkInt64 then
        begin
          SetInt64Prop(aInstance, vPropertyInfo, vPropertyInfo.Default);
        end
        else
        begin
          SetOrdProp(aInstance, vPropertyInfo, vPropertyInfo.Default);
        end;
      end;
    end;
  finally
    vClassPropertyArray.Free();
  end;
end;


end.
