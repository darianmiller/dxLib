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

{$IFDEF VER130}  //D5 Borland: Released 10th August 1999, Codename Argus
  {$DEFINE DELPHI5_UP}
{$ENDIF}
{$IFDEF VER140}  //D6 Borland: Released 21st May 2001, Codename Illiad
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
{$ENDIF}
{$IFDEF VER150}  //D7 Borland: Released 9th August 2002, Codename Aurora
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
{$ENDIF}
//D8=DotNet Released 22nd December 2003, Codename Octane
{$IFDEF VER170} //D9 Borland: Released 12th October 2004, Codename Diamondback
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
{$ENDIF}
{$IFDEF VER180}  //D10 Borland: Released 23rd November 2005, Codename DeXter
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
{$ENDIF}
{$IFDEF VER185}  //D11 Codegear: Released 16th March 2007, Codename Spacely
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
{$ENDIF}
{$IFDEF VER200}  //D12 Embarcadero: Released 25th August 2008, Codename Tiburon
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE SUPPORTS_UNICODESTRING}
{$ENDIF}
//D13 skipped
{$IFDEF VER210}  //D14 Embarcadero: Released 25th August 2009, Codename Weaver
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE DELPHI2010_UP}
{$ENDIF}
{$IFDEF VER220}  //D15 Embarcadero: Released 30th August 2010, Codename Fulcrum
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE DELPHI2010_UP}
  {$DEFINE DELPHIXE_UP}
{$ENDIF}
{$IFDEF VER230}  //D16 Embarcadero: Released 1st September, 2011, Codename Pulsar
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE DELPHI2010_UP}
  {$DEFINE DELPHIXE_UP}
  {$DEFINE DELPHIXE2_UP}
{$ENDIF}
{$IFDEF VER240}  //D17 Embarcadero: Released 4th September, 2012, Codename WaterDragon
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE DELPHI2010_UP}
  {$DEFINE DELPHIXE_UP}
  {$DEFINE DELPHIXE2_UP}
  {$DEFINE DELPHIXE3_UP}
{$ENDIF}
{$IFDEF VER250}  //D18 Embarcadero: Released 22nd April, 2013, Codename Quintessence
  {$DEFINE DELPHI5_UP}
  {$DEFINE DELPHI6_UP}
  {$DEFINE DELPHI7_UP}
  {$DEFINE DELPHI2005_UP}
  {$DEFINE DELPHI2006_UP}
  {$DEFINE DELPHI2007_UP}
  {$DEFINE DELPHI2009_UP}
  {$DEFINE DELPHI2010_UP}
  {$DEFINE DELPHIXE_UP}
  {$DEFINE DELPHIXE2_UP}
  {$DEFINE DELPHIXE3_UP}
  {$DEFINE DELPHIXE4_UP}
{$ENDIF}


{$IFDEF DELPHI2006_UP}
  {$DEFINE SUPPORTS_REPORTMEMORYLEAKSONSHUTDOWN}
{$ENDIF}
{$IFDEF DELPHI2009_UP}
  {$DEFINE SUPPORTS_UNICODESTRING}
  //anon methods
  //generics
{$ENDIF}
{$IFDEF DELPHI2010_UP}
  //enhanced RTTI
  //attributes
{$ENDIF}
{$IFDEF DELPHIXE_UP}
  {$DEFINE RESUME_DEPRECATED}
  //IOUtils
  //regex
  //ttimezone
{$ENDIF}
{$IFDEF DELPHIXE2_UP}
  //64-bit
  //Mac OS X
  //Unit scope names for VCL/RTL
  //system.zip
  //tlogincredentialservvice
{$ENDIF}
{$IFDEF DELPHIXE4_UP}
  //ZeroBasedStrings
  //volatile, weak, ref
{$ENDIF}
