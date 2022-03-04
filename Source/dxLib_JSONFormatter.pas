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
unit dxLib_JSONFormatter;

interface
{$I dxLib.inc}

uses
  {$IFDEF DX_UnitScopeNames}
  System.Classes;
  {$ELSE}
  Classes;
  {$ENDIF}


type

  TLineFeedIndentStatus = (IdentNone,
                           IdentForward,
                           IdentBackward,
                           IdentSameLevel);

  TdxJSONFormatter = class
  private
    fColonPrefix:String;
    fColonSuffix:String;
    fCommaPrefix:String;
    fCommaSuffix:String;
    fCommaLineBreak:Boolean;
    fArrayLineBreak:Boolean;
    fObjectLineBreak:Boolean;
    fIndentString:String;

    fCurrentLineIdent:Integer;
    fLineFeedStatus:TLineFeedIndentStatus;
  protected
    procedure Append(const aOutput:TStream; const aChar:Char); overload;
    procedure Append(const aOutput:TStream; const aString:String); overload;
    procedure ExpandOutputAsNeeded(const aOutput:TStream; const aLength:Integer);
    procedure HandleLineFeed(const aOutput:TStream);
  public
    constructor Create();

    function FormatJSON(const aJSON:String):String; overload;
    procedure FormatJSON(const aInput:TStream; const aOutput:TStream); overload;

    procedure SetCompactStyle();
    procedure SetDefaultStyle();

    property ColonPrefix:String read fColonPrefix write fColonPrefix;
    property ColonSuffix:String read fColonSuffix write fColonSuffix;
    property CommaPrefix:String read fCommaPrefix write fCommaPrefix;
    property CommaSuffix:String read fCommaSuffix write fCommaSuffix;
    property CommaLineBreak:Boolean read fCommaLineBreak write fCommaLineBreak;
    property ArrayLineBreak:Boolean read fArrayLineBreak write fArrayLineBreak;
    property ObjectLineBreak:Boolean read fObjectLineBreak write fObjectLineBreak;
    property IndentString:String read fIndentString write fIndentString;
  end;


  function FormatJSON(const aJSON:String):String; overload;
  procedure FormatJSON(const aInput:TStream; const aOutput:TStream); overload;


const
  MEM_BLOCK_SIZE = 1024;

  DEFAULT_IDENT_SPACING = '  ';
  DEFAULT_COLON_PREFIX_SPACING = '';
  DEFAULT_COLON_SUFFIX_SPACING = ' ';
  DEFAULT_COMMA_PREFIX_SPACING = '';
  DEFAULT_COMMA_SUFFIX_SPACING = ' ';
  DEFAULT_COMMA_LINEBREAK = True;
  DEFAULT_ARRAY_LINEBREAK = True;
  DEFAULT_OBJECT_LINEBREAK = True;


implementation
uses
  {$IFDEF DX_UnitScopeNames}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$ENDIF}
  dxLib_JSONUtils,
  dxLib_Streams,
  dxLib_Strings;


function FormatJSON(const aJSON:String):String;
var
  vFormatter:TdxJSONFormatter;
begin
  vFormatter := TdxJSONFormatter.Create();
  try
    Result := vFormatter.FormatJSON(aJSON);
  finally
    vFormatter.Free();
  end;
end;


procedure FormatJSON(const aInput:TStream; const aOutput:TStream);
var
  vFormatter:TdxJSONFormatter;
begin
  vFormatter := TdxJSONFormatter.Create();
  try
    vFormatter.FormatJSON(aInput, aOutput);
  finally
    vFormatter.Free();
  end;
end;


constructor TdxJSONFormatter.Create();
begin
  inherited;
  SetDefaultStyle();
end;

//similar style to jsonlint.com (except ArrayLineBreak)
procedure TdxJSONFormatter.SetDefaultStyle();
begin
  IndentString := DEFAULT_IDENT_SPACING;
  ColonPrefix := DEFAULT_COLON_PREFIX_SPACING;
  ColonSuffix := DEFAULT_COLON_SUFFIX_SPACING;
  CommaPrefix := DEFAULT_COMMA_PREFIX_SPACING;
  CommaSuffix := DEFAULT_COMMA_SUFFIX_SPACING;
  CommaLineBreak := DEFAULT_COMMA_LINEBREAK;
  ArrayLineBreak := DEFAULT_ARRAY_LINEBREAK;
  ObjectLineBreak := DEFAULT_OBJECT_LINEBREAK;
end;


//use if you want to take formatted JSON and strip whitespace
//{ "Test" : 123 } => {"Test":123}
procedure TdxJSONFormatter.SetCompactStyle();
begin
  IndentString := EmptyStr;
  ColonPrefix := EmptyStr;
  ColonSuffix := EmptyStr;
  CommaPrefix := EmptyStr;
  CommaSuffix := EmptyStr;
  CommaLineBreak := False;
  ArrayLineBreak := False;
  ObjectLineBreak := False;
end;


function TdxJSONFormatter.FormatJSON(const aJSON:String):String;
var
  vInput:TMemoryStream;
  vOutput:TMemoryStream;
begin
  vInput := TMemoryStream.Create();
  vOutput := TMemoryStream.Create();
  try
    AppendStream(vInput, aJSON);
    FormatJSON(vInput, vOutput);
    Result := MemoryStreamToString(vOutput);
  finally
    vOutput.Free();
    vInput.Free();
  end;
end;


procedure TdxJSONFormatter.FormatJSON(const aInput:TStream; const aOutput:TStream);
var
  vInQuote:Boolean;
  vIgnoreNextQuote:Boolean;
  vCurrentChar:Char;
  vTestChar:Char;
  vFormattedOutput:String;
  vSavePosition:Int64;
begin
  aOutput.Size := 0;
  //Preallocate space as we'll typically need at least as much space allocated for output as we have coming in.
  aOutput.Size := aInput.Size;
  aInput.Position := 0;
  aOutput.Position := 0;

  fCurrentLineIdent := 0;
  vIgnoreNextQuote := False;
  vInQuote := False;

  while aInput.Position < aInput.Size do
  begin
    aInput.Read(vCurrentChar, ByteLength(vCurrentChar));

    if (vCurrentChar = '"') then
    begin
      if vIgnoreNextQuote then
      begin
        vIgnoreNextQuote := False;
      end
      else
      begin
        vInQuote := not vInQuote;
      end;
    end
    else if (vInQuote and (vCurrentChar = '\')) then
    begin
      if aInput.Position < aInput.Size then
      begin
        //peek ahead to check for escaped quote  \"
        vSavePosition := aInput.Position;
        aInput.ReadBuffer(vTestChar, ByteLength(vTestChar));
        aInput.Position := vSavePosition;

        vIgnoreNextQuote := (vTestChar = '"');
      end
      else
      begin
        vIgnoreNextQuote := False;
      end;
    end;


    if vInQuote then
    begin
      Append(aOutput, vCurrentChar);
    end
    else if vCurrentChar = '{' then
    begin
      Append(aOutput, vCurrentChar);
      if ObjectLineBreak then
      begin
        fLineFeedStatus := IdentForward;
      end;
    end
    else if vCurrentChar = '}' then
    begin
      if ObjectLineBreak then
      begin
        if fLineFeedStatus = IdentForward then
        begin
          fLineFeedStatus := IdentNone;  //{}
        end
        else
        begin
          fLineFeedStatus := IdentBackward;
        end;
      end;
      Append(aOutput, vCurrentChar);
    end
    else if vCurrentChar = ',' then
    begin
      vFormattedOutput := fCommaPrefix + vCurrentChar + fCommaSuffix;
      Append(aOutput, vFormattedOutput);
      if CommaLineBreak then
      begin
        fLineFeedStatus := IdentSameLevel;
      end;
    end
    else if vCurrentChar = ':' then
    begin
      vFormattedOutput := fColonPrefix + vCurrentChar + fColonSuffix;
      Append(aOutput, vFormattedOutput);
    end
    else if vCurrentChar = '[' then
    begin
      Append(aOutput, vCurrentChar);
      if ArrayLineBreak then
      begin
        fLineFeedStatus := IdentForward;
      end;
    end
    else if vCurrentChar = ']' then
    begin
      if ArrayLineBreak then
      begin
        if fLineFeedStatus = IdentForward then
        begin
          fLineFeedStatus := IdentNone;  //[]
        end
        else
        begin
          fLineFeedStatus := IdentBackward;
        end;
      end;
      Append(aOutput, vCurrentChar);
    end
    else if not CharInSet(vCurrentChar, JSON_WHITESPACE_CHARACTERS) then
    begin
      Append(aOutput, vCurrentChar);
    end;
  end;

  //trim output
  aOutput.Size := aOutput.Position;
end;


procedure TdxJSONFormatter.Append(const aOutput:TStream; const aChar:Char);
begin
  HandleLineFeed(aOutput);
  ExpandOutputAsNeeded(aOutput, ByteLength(aChar));
  AppendStream(aOutput, aChar);
end;

procedure TdxJSONFormatter.Append(const aOutput:TStream; const aString:String);
begin
  HandleLineFeed(aOutput);
  ExpandOutputAsNeeded(aOutput, ByteLength(aString));
  AppendStream(aOutput, aString);
end;


procedure TdxJSONFormatter.HandleLineFeed(const aOutput:TStream);
var
  vFormattedOutput:String;
  i:Integer;
begin
  if fLineFeedStatus <> IdentNone then
  begin
    if fLineFeedStatus = IdentForward then
    begin
      Inc(fCurrentLineIdent);
    end
    else if fLineFeedStatus = IdentBackward then
    begin
      Dec(fCurrentLineIdent);
    end;
    //else fLineFeedSatatus = IdentSameLevel
    fLineFeedStatus := IdentNone;

    vFormattedOutput := sLineBreak;
    for i := 1 to fCurrentLineIdent do
    begin
      vFormattedOutput := vFormattedOutput + IndentString;
    end;

    ExpandOutputAsNeeded(aOutput, ByteLength(vFormattedOutput));
    AppendStream(aOutput, vFormattedOutput);
  end;
end;


procedure TdxJSONFormatter.ExpandOutputAsNeeded(const aOutput:TStream; const aLength:Integer);
begin
  if aOutput.Position + aLength > aOutput.Size then
  begin
    aOutput.Size := aOutput.Size + MEM_BLOCK_SIZE;
  end;
end;


end.
