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
unit dxLib_Types;

interface
{$I dxLib.inc}

  {$IFDEF DX_DELPHI6_UP}
    {$IFNDEF DX_DELPHI2009_UP}
    Type
      PByte = PAnsiChar;
      //NativeInt didn't exist or was broken before Delphi 2009.
      NativeInt = Integer;
    {$ENDIF}

    {$IFNDEF DX_DELPHI2010_UP}
    Type
      //NativeUInt didn't exist or was broken before Delphi 2010
      NativeUInt = Cardinal;
    {$ENDIF}

    {$IFNDEF DX_DELPHIXE_UP}
    Type
      //PNativeUInt didn't exist before Delphi XE
      PNativeUInt = ^Cardinal;
    {$ENDIF}

    {$IFNDEF DX_DELPHIXE2_UP}
    Type
      //IntPtr and UIntPtr didn't exist before Delphi XE2
      IntPtr = Integer;
      UIntPtr = Cardinal;
    {$ENDIF}
  {$ELSE}
    Type
      //these didn't exist Delphi 5 or earlier
      PByte = PAnsiChar;
      NativeInt = Integer;
      NativeUInt = Cardinal;
      PNativeUInt = ^Cardinal;
      IntPtr = Integer;
      UIntPtr = Cardinal;
  {$ENDIF}

implementation

end.
