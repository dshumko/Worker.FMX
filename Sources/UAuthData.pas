unit UAuthData;

interface
uses
  system.classes, system.types, system.sysutils, JsonableObject, XSuperObject,UUtils;

type
  TAuthData=class( TJsonableObject )
    function GetEncryptedPassword: string;
    procedure SetEncryptedPassword(const Value: string);
    function GetURL_date_AsString: string;
    procedure SetURL_date_AsString(const Value: string);
  public
    Login: string;
    [DISABLE]
    Password: string;
    Company: string;
    ValidURL: string;
    [DISABLE]
    validURL_date: TDate;

    [Alias('password')]
    property EncryptedPassword:string read GetEncryptedPassword write SetEncryptedPassword;
    [Alias('validURL_date')]
    property validURL_date_AsString:string read GetURL_date_AsString write SetURL_date_AsString;
  end;


implementation

function TAuthData.GetEncryptedPassword: string;
begin
  result := Base64enc(password);
end;

function TAuthData.GetURL_date_AsString: string;
begin
  result := FormatDateTime('yyyy-MM-dd', validURL_date, fs);
end;

procedure TAuthData.SetEncryptedPassword(const Value: string);
begin
  password := Base64dec(value);
end;

procedure TAuthData.SetURL_date_AsString(const Value: string);
var a:tArray<string>;
  y,m,d:word;
begin
  // date format yyyy-MM-dd
  validURL_date := 0;
  a:=Value.Split(['-']);
  if (Length(a)=3) then
  begin
    y:=StrToIntDef(a[0],0);
    m:=StrToIntDef(a[1],0);
    d:=StrToIntDef(a[2],0);
    if (y<>0)and(m<>0)and(d<>0) then
      validURL_date := EncodeDate(y, m, d);
  end;
end;


end.
