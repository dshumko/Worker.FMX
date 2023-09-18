unit modAPI;

interface

uses
  System.Types, System.SysUtils, System.IOUtils, System.Classes,
  System.NetEncoding,
  System.Net.HTTPClient, System.Net.HTTPClientComponent, System.Net.UrlClient,
  idGlobal, IdHashMessageDigest,
  FMX.Graphics, FMX.Types, modTypes;

type
  TmyAPI = record
  public
    class var FLogin: string;
    class var FPassword: string;
    class var FValidURL: string;
    class var FCompany: string;
    class var FvalidURL_date: TDate;

    class function GetValidURL: string; static;

    class function ServerUrl: string; static;
    class function Request(const aURL: string): string; static;
    class function md5(const aValue: string): string; static;
    class function urlEnc(const aValue: string): string; static;
    class function Base64enc(const aValue: string): string; static;
    class function Base64dec(const aValue: string): string; static;
    class function Base64BitmapEnc(const aValue: TBitmap): string; static;
    class function Base64BitmapStreamEnc(const aValue: TMemoryStream): string; static;
    class procedure Base64BitmapStreamDec(const aValue: string; out aImage: TBitmap); static;

    class function userAuth: string; static;
    class function getStreets: string; static;
    class function getHouses(const aStreetID: integer): string; static;
    class function getHouseInfo(const aHouseID: integer): string; static;
    class function getHouseCustomers(const aHouseID: integer): string; static;
    class function getCustomerInfo(const aCustomerID: integer): string; static;
    class function getEqipmentInfo(const aEqipmentID, aType: integer): string; static;

    class function actionEqipment(const aEqipmentID, aType: integer): string; static;

    class function getBidList(const aStreetID, aHouseID: integer): string; static;
    class function getBidInfo(const aID: integer): string; static;
    class function TakeBid(const aID: integer): string; static;
    class function JoinBid(const aID: integer): string; static;
    class function RefuseBid(const aID: integer): string; static;
    class function closeBid(const aID: integer): string; static;

    class function getMaterials: string; static;

    class function setLocation(const aLat, aLon: Double): string; static;
    // class function setBidPhoto(const aImage: TBitmap; const aID: integer): string; static;
    // class function setBidPhotoStream(const aImage: TMemoryStream; const aID: integer): string; static;

    class function getPromo: string; static;
    class function contactsList: string; static;
    class function SaveToken(const aDeviceID, aDeviceToken: string): string; static;

    class function newCustomer(const aNewCustomer: TmyTypeNewCustomer): string; static;

    class function getCustomerServices(const aCustomerID: integer): string; static;
    class function getLinkTo(const aHouseID: integer): string; static;
    class function getDiscountList(const aCustomerID: integer): string; static;

    procedure OnValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);

  end;

const
  A4onApiURL: string = 'https://test.a4on.net/cabinet/worker.php?';

implementation

{ TmyAPI }

uses
  System.Net.Mime,
  FMX.DeviceInfo,
  modJSON,
  XSuperObject
  {$IFDEF  ANDROID},
  Androidapi.JNI.Support
  {$ENDIF}
  ;

const
  msgErr = '{"status":"ERROR","text":"Ошибка получения данных"}';
  msgErrInternet = '{"status":"ERROR","text":"Нет интернета :("}';
  A4onApiKey: string = 'QTRPTi5UVi1CaWxsaW5nIEVQRw';

  // A4onApiURL: string = 'https://test.a4on.net/cabinet/worker.php?';
  // A4onApiURL: string = 'https://cab.wikilink.by/api/worker_tvsat.php?'; // ТВсат
  // A4onApiURL: string = 'https://cab.wikilink.by/api/worker_ug.php?'; // ТВсат ЮГ
  // A4onApiURL: string = 'https://cab.wikilink.by/api/worker_cns.php?'; // wikilink
  // A4onApiURL: string = 'https://cab.wikilink.by/api/worker_plus.php?'; // ТВсат плюс
  // A4onApiURL: string = 'https://komset.prx.a4on.net:5443/komset.php?'; // комсет
  // A4onApiURL: string = 'https://komset.prx.a4on.net:5443/siti.php?'; // Сити
  // A4onApiURL: string = 'https://178.218.43.14:1433/worker/worker.php?'; // Рыбинск
  // A4onApiURL: string = 'https://saratov.prx.a4on.net:1443/worker.php?'; // Саратов
  // A4onApiURL: string = 'https://prizm.prx.a4on.net:2443/worker.php?';
  // A4onApiURL: string = 'https://sun.prx.a4on.net:3443/worker.php?';
  // A4onApiURL: string = 'https://kainar.prx.a4on.net:10443/worker.php?';
  // A4onApiURL: string = 'https://lngrd.prx.a4on.net:11443/worker.php?';
  // A4onApiURL: string = 'https://api.norbi-tv.ru/worker.php?'; // Норби ТВ
  // A4onApiURL: string = 'https://tvk.prx.a4on.net:12443/worker.php?'; // ТВК
  // A4onApiURL: string = 'https://prizma.by/mobwork/worker.php?'; // Призма
  // A4onApiURL: string = 'https://prizma.by/mobwork/wmedia.php?'; // Призма Медиа
  // A4onApiURL: string = 'https://93.125.125.241/worker.php?'; // Элсат
  // A4onApiURL: string = 'https://cab.pinpro.by/api/worker_pip.php?'; // Пинск ПИП
  // A4onApiURL: string = 'https://cab.pinpro.by/api/worker_mir.php?'; // Пинск МирТВ
var
  FmyAPI: TmyAPI; // объявлена для события

class function TmyAPI.urlEnc(const aValue: string): string;
// uses System.NetEncoding
begin
  Result := TNetEncoding.URL.Encode(aValue);
end;

class function TmyAPI.actionEqipment(const aEqipmentID, aType: integer): string;
begin
  Result := format('method=actionEqipment&id=%d&type=%d', [aEqipmentID, aType]);
end;

class procedure TmyAPI.Base64BitmapStreamDec(const aValue: string; out aImage: TBitmap);
var
  aMem: TMemoryStream;
  aStrMem: TBytesStream;
begin
  if aValue.IsEmpty then
    exit;

  aMem := TMemoryStream.Create;
  aStrMem := TBytesStream.Create(BytesOf(aValue));

  if TNetEncoding.Base64.Decode(aStrMem, aMem) > 0 then
  begin
    aMem.Position := 0;
    if aImage = nil then
      aImage := TBitmap.CreateFromStream(aMem)
    else
      aImage.LoadFromStream(aMem);
  end;

  FreeAndNil(aMem);
  FreeAndNil(aStrMem);
end;

class function TmyAPI.Base64BitmapStreamEnc(const aValue: TMemoryStream): string;
begin
  Result := '';
  if aValue = nil then
    exit;
  if aValue.Size = 0 then
    exit;

  Result := TNetEncoding.Base64.EncodeBytesToString(aValue.Memory, aValue.Size);
end;

class function TmyAPI.Base64BitmapEnc(const aValue: TBitmap): string;
var
  aStr: TMemoryStream;
begin
  Result := '';
  if aValue = nil then
    exit;
  if aValue.IsEmpty then
    exit;

  aStr := TMemoryStream.Create;
  try
    aValue.SaveToStream(aStr);
    TmyAPI.Base64BitmapStreamEnc(aStr);
  finally
    FreeAndNil(aStr);
  end;
end;

class function TmyAPI.Base64dec(const aValue: string): string;
// uses System.NetEncoding
begin
  Result := TNetEncoding.Base64.Decode(aValue);
end;

class function TmyAPI.Base64enc(const aValue: string): string;
// uses System.NetEncoding
begin
  Result := TNetEncoding.Base64.Encode(aValue);
end;

class function TmyAPI.closeBid(const aID: integer): string;
var
  aResponse: IHTTPResponse;
  LSource: TStringStream;
  AHeaders: TNetHeaders;
  URL: string;
begin
  if not IsNetConnected then
  begin
    Result := msgErrInternet;
    exit;
  end;
  Result := msgErr;
  with THTTPClient.Create do
  begin
    OnValidateServerCertificate := FmyAPI.OnValidateServerCertificate;
    try
      LSource := TStringStream.Create(TmyJSON.LoadFromFile(TmyPath.generateBid(aID), false), TEncoding.UTF8);
      try
        SetLength(AHeaders, 1);
        AHeaders[0] := TNameValuePair.Create('Connection', 'close');
        URL := TmyAPI.ServerUrl + format('method=closeBid&id=%d', [aID]);
        aResponse := Post(URL, LSource, nil, AHeaders);
        Result := aResponse.ContentAsString(TEncoding.UTF8).Trim([#$FEFF]);
      except
        Result := msgErr;
      end;
      FreeAndNil(LSource);
    finally
      Free;
    end;
  end;
end;

class function TmyAPI.contactsList: string;
begin
  Result := 'method=contactsList';
end;

class function TmyAPI.getPromo: string;
begin
  Result := 'method=getPromo';
end;

class function TmyAPI.getStreets: string;
begin
  Result := 'method=getStreets';
end;

class function TmyAPI.getBidInfo(const aID: integer): string;
begin
  Result := format('method=getBid&id=%d', [aID]);
end;

class function TmyAPI.getBidList(const aStreetID, aHouseID: integer): string;
begin
  Result := format('method=getBidList&street=%d&house=%d', [aStreetID, aHouseID]);
end;

class function TmyAPI.getCustomerInfo(const aCustomerID: integer): string;
begin
  Result := format('method=getCustomerInfo&id=%d', [aCustomerID]);
end;

class function TmyAPI.getCustomerServices(const aCustomerID: integer): string;
begin
  Result := format('method=getCustomerServices&id=%d', [aCustomerID]);
end;

class function TmyAPI.getDiscountList(const aCustomerID: integer): string;
begin
  Result := format('method=getDiscountList&id=%d', [aCustomerID]);
end;

class function TmyAPI.getEqipmentInfo(const aEqipmentID, aType: integer): string;
begin
  Result := format('method=getEqipmentInfo&id=%d&type=%d', [aEqipmentID, aType]);
end;

class function TmyAPI.getHouseCustomers(const aHouseID: integer): string;
begin
  Result := format('method=getHouseCustomers&id=%d', [aHouseID]);
end;

class function TmyAPI.getHouseInfo(const aHouseID: integer): string;
begin
  Result := format('method=getHouseInfo&id=%d', [aHouseID]);
end;

class function TmyAPI.getHouses(const aStreetID: integer): string;
begin
  Result := format('method=getHouses&id=%d', [aStreetID]);
end;

class function TmyAPI.getLinkTo(const aHouseID: integer): string;
begin
  Result := format('method=getLinkTo&id=%d', [aHouseID]);
end;

class function TmyAPI.getMaterials: string;
begin
  Result := 'method=getMaterials';
end;

class function TmyAPI.userAuth: string;
begin
  Result := 'method=userAuth';
end;

class function TmyAPI.md5(const aValue: string): string;
// uses IdHashMessageDigest, idGlobal
begin
  Result := '';
  with TIdHashMessageDigest5.Create do
  begin
    try
      try
        Result := LowerCase(HashStringAsHex(aValue, IndyTextEncoding_UTF8));
      except
        Result := '';
      end;
    finally
      Free;
    end;
  end;
end;

class function TmyAPI.newCustomer(const aNewCustomer: TmyTypeNewCustomer): string;
var
  aResponse: IHTTPResponse;
  LSource: TStringStream;
  AHeaders: TNetHeaders;
  URL: string;
begin
  if not IsNetConnected then
  begin
    Result := msgErrInternet;
    exit;
  end;
  Result := msgErr;
  with THTTPClient.Create do
  begin
    OnValidateServerCertificate := FmyAPI.OnValidateServerCertificate;
    try
      LSource := TStringStream.Create(TJSON.Stringify(aNewCustomer), TEncoding.UTF8);
      try
        SetLength(AHeaders, 1);
        AHeaders[0] := TNameValuePair.Create('Connection', 'close');
        URL := TmyAPI.ServerUrl + 'method=newCustomer';
        aResponse := Post(URL, LSource, nil, AHeaders);
        Result := aResponse.ContentAsString(TEncoding.UTF8).Trim([#$FEFF]);
      except
        Result := msgErr;
      end;
      LSource.Free;
    finally
      Free;
    end;
  end;
end;

procedure TmyAPI.OnValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest;
  const Certificate: TCertificate; var Accepted: Boolean);
begin
  Accepted := true; // пропускаем проверку сертификата
end;

class function TmyAPI.Request(const aURL: string): string;
var
  aResp: IHTTPResponse;
  AHeaders: TArray<TNameValuePair>;
begin
  if not IsNetConnected then
  begin
    Result := msgErrInternet;
    exit;
  end;
  Result := msgErr;
  with THTTPClient.Create do
  begin
    OnValidateServerCertificate := FmyAPI.OnValidateServerCertificate;
    try
      try
        SetLength(AHeaders, 1);
        AHeaders[0] := TNameValuePair.Create('Connection', 'close');
        aResp := Get(TmyAPI.ServerUrl + aURL, nil, AHeaders);
        Result := aResp.ContentAsString(TEncoding.UTF8).Trim([#$FEFF]);
      except
        Result := msgErr;
      end;
    finally
      Free;
    end;
  end;
end;

class function TmyAPI.SaveToken(const aDeviceID, aDeviceToken: string): string;
begin
  Result := format('method=SaveToken&device_id=%s&device_token=%s&platform=%s',
    [aDeviceID, aDeviceToken{$IFDEF ANDROID}, 'ANDROID'{$ELSEIF defined(IOS)}, 'IOS'{$ENDIF}]);
end;

class function TmyAPI.ServerUrl: string;
begin
  Result := format('%slogin=%s&paswd=%s&', [TmyAPI.FValidURL, TmyAPI.FLogin, TmyAPI.FPassword]);
end;

class function TmyAPI.setLocation(const aLat, aLon: Double): string;
begin
  Result := format('method=setLocation&lat=%15.12f&lon=%15.12f', [aLat, aLon]);
end;

class function TmyAPI.TakeBid(const aID: integer): string;
begin
  Result := format('method=takeBid&id=%d', [aID]);
end;

class function TmyAPI.RefuseBid(const aID: integer): string;
begin
  Result := format('method=refuseBid&id=%d', [aID]);
end;

class function TmyAPI.JoinBid(const aID: integer): string;
begin
  Result := format('method=joinBid&id=%d', [aID]);
end;

class function TmyAPI.GetValidURL: string;
var
  vURL: string;
  aResp: TStringStream;
  AHeaders: TArray<TNameValuePair>;
begin
  vURL := 'http://api.a4on.net/worker/' + FCompany;
  if not IsNetConnected then
  begin
    Result := msgErrInternet;
    exit;
  end;
  Result := msgErr;
  aResp := TStringStream.Create('', TEncoding.UTF8);
  with TNetHTTPClient.Create(nil) do
  begin
    OnValidateServerCertificate := FmyAPI.OnValidateServerCertificate;
    try
      try
        SetLength(AHeaders, 1);
        AHeaders[0] := TNameValuePair.Create('Connection', 'close');
        Get(vURL, aResp, AHeaders);
        Result := aResp.DataString.Trim([#$FEFF]);
      except
        Result := '';
      end;
    finally
      Free;
    end;
  end;
end;

end.
