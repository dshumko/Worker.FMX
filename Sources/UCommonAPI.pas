unit UCommonAPI;

interface
uses
  System.Types, System.Classes, System.Threading, System.SysUtils,
  System.Net.HTTPClient,
  System.Net.UrlClient,
  System.NetEncoding,
  XSuperObject,JsonableObject,
  UAuthData;


type

  TErrRec = record
    Status:string;
    Msg:string;
    procedure Clear;
  end;


  TURIHelper = record helper for TURI
    function FindParameterIndex(const AName: string): Integer;
    function ParamExists(const AName:string): Boolean;
    procedure AddOrSetParamByName(const AName,AValue: string);
  end;

  TCommonAPI = class
  protected
    FURI : TURI;
    FParams:TStringList;
    FPostData: TStringStream;
    FResStream: TStringStream;
    FHeaders: TArray<TNameValuePair>;

    procedure ResetURL();
    function GetMethod: string; inline;
    procedure SetMethod(const Value: string); inline;
    function GetParam(name: string): string; inline;
    procedure SetParam(name: string; const Value: string); inline;
  public
    AuthData:TAuthData;
    HTTP:THTTPClient;
    Err:TErrRec;
    ResultJson:ISuperObject;
    ResultString:string;

    procedure Assign(a:TCommonAPI); virtual;

    function BaseApiURL():string; virtual; abstract;
    function ObtainCompanyURL: string;
    function UserAuth : string; virtual;

    function MsgErrGetData():string; virtual;
    function MsgErrNoConnection():string; virtual;

    function Request(const ARequestType:string=shttpmethodget): string;
    function MakeUrlParams():string;

    procedure OnValidateServerCertificate(const Sender: TObject; const ARequest: TURLRequest;
      const Certificate: TCertificate; var Accepted: Boolean);

    constructor Create; virtual;
    destructor Destroy; override;

    property Method: string read GetMethod write SetMethod;
    property Param[name:string]: string read GetParam write SetParam;
  end;

  TCommonApiThread=class(TThread)
  public
    FAPI: TCommonAPI;
    procedure Execute; override;
    constructor Create(const AApi:TCommonApi; const ATermProc:TNotifyEvent);
  end;

var
  FS: TFormatSettings;

const
  sSTATUS = 'status';
  sERROR = 'ERROR';
  sOK = 'OK';
  sTEXT = 'text';
  sMethod = 'method';
  sLogin = 'login';
  sPaswd = 'paswd';


implementation

uses
  FMX.DeviceInfo, UUnescapeJson;

procedure TErrRec.Clear;
begin
  Status:='';
  Msg:='';
end;


constructor TCommonAPI.Create;
begin
  FParams := TStringList.Create;
  FParams.Delimiter := '&';
  FParams.StrictDelimiter := true;
  FPostData := TStringStream.Create('', TEncoding.UTF8);
  FResStream := TStringStream.Create('', TEncoding.UTF8);
  SetLength(FHeaders, 1);
  FHeaders[0].Name := 'Connection';
  FHeaders[0].Value := 'close';
  AuthData := TAuthData.Create;
  Http := THTTPClient.Create;
  Http.OnValidateServerCertificate := OnValidateServerCertificate;
end;

destructor TCommonAPI.Destroy;
begin
  FreeAndNil(HTTP);
  FreeAndNil(AuthData);
  FreeAndNil(FResStream);
  FreeAndNil(FPostData);
  FreeAndNil(FParams);
  inherited;
end;


procedure TCommonAPI.Assign(a: TCommonAPI);
begin
  AuthData := a.AuthData;
  FUri := a.FURI;
end;

function TCommonAPI.userAuth: string;
begin
  ResetURL();
  Method := 'userAuth';
  Result := Request();
//  Result := 'method=userAuth';
end;

function TCommonAPI.MakeUrlParams: string;
var
  i: Integer;
begin
  if (AuthData.Login<>'') then
  begin
    FURI.AddOrSetParamByName(sLogin,AuthData.Login);
    FURI.AddOrSetParamByName(sPaswd,AuthData.Password);
  end;
  result := FURI.ToString;
end;


procedure TCommonAPI.ResetURL;
begin
  FURI := TURI.Create(AuthData.ValidURL);
  FPostData.Clear;
end;


function TCommonAPI.GetMethod: string;
begin
  result := GetParam(sMethod);
end;

function TCommonAPI.GetParam(name: string): string;
var ind:integer;
begin
  result := '';
  ind := FURI.findParameterIndex(name);
  if ind <> -1 then
    result := FURI.Parameter[ind].Value;
end;

// GETTERS and SETTERS
procedure TCommonAPI.SetMethod(const Value: string);
begin
  FURI.AddOrSetParamByName(sMethod,value);
end;

procedure TCommonAPI.SetParam(name: string; const Value: string);
begin
  FURI.AddOrSetParamByName(name,value);
end;

function TCommonAPI.ObtainCompanyURL: string;
begin
  FURI:=TURI.Create( BaseApiURL() + AuthData.Company );
  Result := Request();
end;

procedure TCommonAPI.OnValidateServerCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := true; // пропускаем проверку сертификата
end;

function TCommonAPI.MsgErrGetData():string;
begin
  result := 'Ошибка получения данных';
end;

function TCommonAPI.MsgErrNoConnection: string;
begin
  result := 'Нет доступа в интернет';
end;

// сюда мы приходим с заполненным FURI и FPostData для POST
function TCommonAPI.Request(const ARequestType:string=shttpmethodGET): string;
var
  vResp: IHTTPResponse;
  vURL: string;
//  X:ISuperObject;
begin
  ResultJson := TSuperObject.Create();
  try
    // предположим сначала плохое
    ResultJson.S[sSTATUS] := sERROR;
    ResultJson.S[sTEXT] := MsgErrGetData();

    if not IsNetConnected then
    begin
      ResultJson.S[sTEXT] := MsgErrNoConnection();
      Result := UnescapeJson(ResultJson.AsJSON);
      exit;
    end;

      FResStream.Clear;

      vURL := MakeUrlParams();
      if ARequestType = sHTTPMethodGet then
      begin
        vResp := Http.Get(vURL, FResStream, FHeaders)
      end
      else
      begin
        vResp := Http.Post(vURL, FPostData, FResStream, FHeaders)
      end;

      Err.Clear;

      if vResp.StatusCode = 200 then
      begin
        Result := FResStream.DataString.Trim([#$FEFF]);
        ResultString := Result;
        if vResp.MimeType.StartsWith('application/json') then
        begin
          ResultJson := TSuperObject.Create(result);
        end
        else
        if vResp.MimeType.StartsWith('text/html') then
        begin
          ResultJson.S[sSTATUS] := sOK;
          ResultJson.S[sTEXT] := Result;
        end;
      end
      else
      begin
        ResultJson.S[sTEXT] := vResp.StatusText;
      end;

  finally
    if ResultJson.contains(sSTATUS) then
    begin
      Err.Status := ResultJson.S[sSTATUS];
      Err.Msg := ResultJson.S[sTEXT];
    end;
  end;

end;


{ TApiThread }

constructor TCommonApiThread.Create(const AApi:TCommonApi; const ATermProc: TNotifyEvent);
begin
  inherited Create(True);
  FAPI := AApi;
  OnTerminate := ATermProc;
  FreeOnTerminate:=True;
end;

procedure TCommonApiThread.Execute;
begin

end;


{ TURIHelper }

procedure TURIHelper.AddOrSetParamByName(const AName, AValue: string);
var
  LIndex: Integer;
begin
  LIndex := FindParameterIndex(AName);
  if LIndex >= 0 then
    Parameter[LIndex] := TURIParameter.Create( TNetEncoding.URL.EncodeQuery(AName), TNetEncoding.URL.EncodeQuery(AValue))
  else
    AddParameter(AName, AValue);
end;

function TURIHelper.FindParameterIndex(const AName: string): Integer;
var
  I: Integer;
  LName: string;
begin
  Result := -1;
  LName := TNetEncoding.URL.EncodeQuery(AName);
  for I := 0 to Length(Params) - 1 do
    if Params[I].Name = LName then
      Exit(I);
end;

function TURIHelper.ParamExists(const AName: string): Boolean;
begin
  Result := FindParameterIndex(AName)<>-1;
end;

end.
