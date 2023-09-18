unit modJSON;

interface

uses
  System.Types, System.SysUtils, System.IOUtils, System.Classes, System.UITypes, System.UIConsts,
  FMX.Types, FMX.Graphics, FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  modTypes;

type
  TmyPath = record
    class function SettingsFile: string; static;
    class function generateBid(const aID: integer): string; static;
    class function BookmarkFile: string; static;

  end;

  TmyJSON = class
    class procedure SaveToFile(const aData, aFileName: string; const ErrorCheck: boolean = true); static;
    class function LoadFromFile(aFileName: string; const ErrorCheck: boolean = true): string; static;
    class function ErrorsSkip(const aData: string): string; static;

    class function isOK(const aData: string): boolean; static;
    class function ErrorMsg(aData: string): string; static;

    class function WriteSettingsData(const aSettings: TmyTypeSettingsData): string; static;
    class procedure ReadSettingsData(const aData: string; out aSettings: TmyTypeSettingsData); static;

    class procedure SaveLocalBidText(const aID, aResult: integer; const aResultText: string;
      aUnixDateTime: int64); static;
    class procedure SaveLocalBidPhoto(const aID, aIndex: integer; const aImage: TBitmap); static;

    class procedure LoadLocalBidText(const aID: integer; out aResult: integer; out aResultText: string;
      out aUnixDateTime: integer); static;
    class procedure LoadLocalBidPhoto(const aID, aIndex: integer; out aImage: TBitmap); static;
    class procedure LoadLocalBidMaterials(const aID: integer; out aIDS, aCounts: string); static;

    class procedure DeleteLocalBidPhoto(const aID, aIndex: integer); static;

    class procedure SaveBookmark(const aName, aForm: string; const aID: integer); static;
    class function IsBookmark(const aForm: string; const aID: integer): integer; static;
    class procedure DeleteBookmark(const aForm: string; const aID: integer); static;
  end;

var
  FAuthData: TmyTypeAuth;

const
  TagEditDateTime = 1;
  TagEditStatusWork = 2;
  TagEditComment = 3;
  TagEditPhoto = 4;
  TagShowUsedMaterials = 5;

implementation

uses
  System.DateUtils, FMX.Surfaces,
  modDrawer, FMX.FontAwesome, modUI, XSuperJSON, XSuperObject, modAPI;

const
  msgErr = '{"status":"ERROR","text":"Ошибка получения данных"}';

function FindGroupID(const aValue: string; aLV: TListView; const Alternative: boolean = false): integer;
var
  I: integer;
  Found: boolean;
begin
  Result := -1;
  for I := 0 to aLV.Items.Count - 1 do
  begin
    if Alternative then
      Found := (aLV.Items[I].Text.StartsWith('Подключен к:')) and (aLV.Items[I].Detail = aValue)
    else
      Found := (aLV.Items[I].Purpose = TListItemPurpose.Header) and (aLV.Items[I].Text = aValue);
    if Found then
    begin
      Result := I;
      break;
    end;
  end;
end;

{ TmyJSON }

class function TmyJSON.IsBookmark(const aForm: string; const aID: integer): integer;
var
  aJSON: string;
  aRecord: TmyTypeBookmarks;
  I: integer;
begin
  Result := -1;
  aJSON := TmyJSON.LoadFromFile(TmyPath.BookmarkFile);
  if TmyJSON.isOK(aJSON) then
  begin
    aRecord := TJSON.Parse<TmyTypeBookmarks>(aJSON);
    for I := Low(aRecord.struct) to High(aRecord.struct) do
      if (aRecord.struct[I].form = aForm) and (aRecord.struct[I].id = aID) then
      begin
        Result := I;
        break;
      end;
  end;
end;

class procedure TmyJSON.DeleteBookmark(const aForm: string; const aID: integer);
var
  aIndex: integer;
  aJSON: string;
  aRecord: TmyTypeBookmarks;
begin
  aIndex := TmyJSON.IsBookmark(aForm, aID);
  if aIndex = -1 then
    exit;

  aJSON := TmyJSON.LoadFromFile(TmyPath.BookmarkFile);
  if TmyJSON.isOK(aJSON) then
  begin
    aRecord := TJSON.Parse<TmyTypeBookmarks>(aJSON);
    Delete(aRecord.struct, aIndex, 1);
  end;
  TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeBookmarks>(aRecord), TmyPath.BookmarkFile);
end;

class procedure TmyJSON.SaveBookmark(const aName, aForm: string; const aID: integer);
var
  aJSON: string;
  aRecord: TmyTypeBookmarks;
begin
  aJSON := TmyJSON.LoadFromFile(TmyPath.BookmarkFile);
  if TmyJSON.isOK(aJSON) then
    aRecord := TJSON.Parse<TmyTypeBookmarks>(aJSON);
  aRecord.status := 'OK';
  SetLength(aRecord.struct, Length(aRecord.struct) + 1);
  with aRecord.struct[Length(aRecord.struct) - 1] do
  begin
    name := aName;
    form := aForm;
    id := aID;
  end;
  TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeBookmarks>(aRecord), TmyPath.BookmarkFile);
end;

class procedure TmyJSON.DeleteLocalBidPhoto(const aID, aIndex: integer);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

  aBid.status := 'OK';
  aBid.id := aID;
  if Length(aBid.photos) > aIndex then
  begin
    aBid.photos[aIndex].Data := '';
    TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeLocalBid>(aBid, true), aFile, false);
  end;
end;

class function TmyJSON.ErrorMsg(aData: string): string;
var
  xJS: ISuperObject;
begin
  xJS := SO(aData);
  if xJS.S['status'] = 'ERROR' then
    Result := xJS.S['text'];
end;

class function TmyJSON.ErrorsSkip(const aData: string): string;
var
  PreData: string;
{$IFNDEF DEBUG}
  aPos: integer;
{$ENDIF}
begin
  PreData := aData;
{$IFNDEF DEBUG}
  if PreData.StartsWith('{"status"') then
    Result := PreData
  else
  begin
    aPos := Pos('{"status"', PreData);
    if aPos <= 0 then
      PreData := msgErr
    else
      System.Delete(PreData, 1, aPos - 1);
    Result := PreData;
  end;
{$ELSE}
  Result := PreData;
{$ENDIF}
end;

class function TmyJSON.isOK(const aData: string): boolean;
var
  xJS: ISuperObject;
begin
  xJS := SO(aData);
  Result := xJS.S['status'] = 'OK';
end;

class function TmyJSON.LoadFromFile(aFileName: string; const ErrorCheck: boolean = true): string;
begin
  Result := msgErr;
  if not FileExists(aFileName) then
    exit;

  with TStringList.Create do
  begin
    LoadFromFile(aFileName, TEncoding.UTF8);
    if ErrorCheck then
      Result := ErrorsSkip(Text)
    else
      Result := Text;
    Free;
  end;
end;

function frmt(const S: string): string;
begin
  Result := S;
  if not Result.Contains('.') then
    Result := Result + '.0';
end;

class procedure TmyJSON.ReadSettingsData(const aData: string; out aSettings: TmyTypeSettingsData);
begin
  if aData.IsEmpty then
    exit;

  if TmyJSON.isOK(aData) then
  begin
    aSettings := TJSON.Parse<TmyTypeSettingsData>(aData);
    aSettings.password := TmyAPI.Base64dec(aSettings.password);
  end;
end;

class procedure TmyJSON.SaveLocalBidPhoto(const aID, aIndex: integer; const aImage: TBitmap);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
  aJPEG: TMemoryStream;
  aSurf: TBitmapSurface;
  aSaveParams: TBitmapCodecSaveParams;
begin
  aJPEG := TMemoryStream.Create;
  aSurf := TBitmapSurface.Create;
  aSurf.Assign(aImage);

  aSaveParams.Quality := 80;
  if not TBitmapCodecManager.SaveToStream(aJPEG, aSurf, '.jpg', @aSaveParams) then
  begin
    FreeAndNil(aJPEG);
    FreeAndNil(aSurf);
    exit;
  end;

  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

  aBid.status := 'OK';
  aBid.id := aID;
  if Length(aBid.photos) <= aIndex then
    SetLength(aBid.photos, aIndex + 1);
  aBid.photos[aIndex].Data := TmyAPI.Base64BitmapStreamEnc(aJPEG);

  FreeAndNil(aJPEG);
  FreeAndNil(aSurf);

  TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeLocalBid>(aBid, true), aFile, false);
end;

class procedure TmyJSON.LoadLocalBidPhoto(const aID, aIndex: integer; out aImage: TBitmap);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  if aImage = nil then
    aImage := TBitmap.Create;

  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
  begin
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

    if Length(aBid.photos) > aIndex then
      TmyAPI.Base64BitmapStreamDec(aBid.photos[aIndex].Data, aImage);
  end
end;

class procedure TmyJSON.SaveLocalBidText(const aID, aResult: integer; const aResultText: string; aUnixDateTime: int64);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

  aBid.status := 'OK';
  aBid.id := aID;
  aBid.Result := aResult;
  aBid.resultText := aResultText;
  aBid.unix_dt := aUnixDateTime;

  TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeLocalBid>(aBid, true), aFile, false);
end;

class procedure TmyJSON.LoadLocalBidText(const aID: integer; out aResult: integer; out aResultText: string;
  out aUnixDateTime: integer);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON)
  else
  begin
    aBid.status := 'OK';
    aBid.id := aID;
    aBid.Result := 0;
    aBid.resultText := '';
    aBid.unix_dt := DateTimeToUnix(Now, true);
  end;

  aResult := aBid.Result;
  aResultText := aBid.resultText;
  aUnixDateTime := aBid.unix_dt;
end;

class procedure TmyJSON.LoadLocalBidMaterials(const aID: integer; out aIDS, aCounts: string);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

  aIDS := aBid.materials.ids;
  aCounts := aBid.materials.counts;
end;

class procedure TmyJSON.SaveToFile(const aData, aFileName: string; const ErrorCheck: boolean = true);
begin
  with TStringList.Create do
  begin
    if ErrorCheck then
      Text := ErrorsSkip(aData)
    else
      Text := aData;
    SaveToFile(aFileName, TEncoding.UTF8);
    Free;
  end;
end;

class function TmyJSON.WriteSettingsData(const aSettings: TmyTypeSettingsData): string;
begin
  Result := Format
    ('{"status":"OK","login":"%s","password":"%s","autoEnter":"%s","gps":%d,"company":"%s", "validURL":"%s","validURL_date":"%s"}',
    [aSettings.login, TmyAPI.Base64enc(aSettings.password), aSettings.autoEnter, aSettings.gpsInterval,
    aSettings.company, aSettings.validURL, FormatDateTime('yyyy-MM-dd', aSettings.validURL_date)]);
end;

{ TmyPath }

class function TmyPath.BookmarkFile: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'bookmars');
end;

class function TmyPath.generateBid(const aID: integer): string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, IntToStr(aID) + '.json')
end;

class function TmyPath.SettingsFile: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'accWork');
end;

end.
