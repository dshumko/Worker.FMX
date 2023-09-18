unit UMobWorkSettings;

interface
uses
  System.classes, System.types, System.SysUtils, XSuperObject, JsonableObject,
  UAuthData
  ;

type

  TmyPath = record
    class function SettingsFile: string; static;
    class function generateBid(const aID: integer): string; static;
    class function BookmarkFile: string; static;
  end;

  TMobWorkSettings = class(TJsonableObject)
  private
    function GetAutoEnter_AsString: string;
    procedure SetAutoEnter_AsString(const Value: string);
  public
    AuthData: TAuthData;
    status: string;
    [DISABLE]
    autoEnter: boolean;
    gpsInterval: integer;
    procedure AfterLoad(X: ISuperObject); override;
    procedure BeforeSave(X: ISuperObject); override;
    [Alias('autoEnter')]
    property autoEnter_AsString: string read GetAutoEnter_AsString write SetAutoEnter_AsString;

    constructor Create; override;
    destructor Destroy; override;
  end;





var
  Settings: TMobWorkSettings;
  FNeedCheckValidURL: Boolean;


implementation

uses
  UUtils, System.Generics.Defaults, System.IOUtils;

{ TMobWorkSettings }

procedure TMobWorkSettings.AfterLoad(X: ISuperObject);
begin
  inherited;

end;

procedure TMobWorkSettings.BeforeSave(X: ISuperObject);
begin
  inherited;

end;

constructor TMobWorkSettings.Create;
begin
  inherited Create;
  AuthData := TAuthData.Create;
  status := 'OK';
end;

destructor TMobWorkSettings.Destroy;
begin
  FreeAndNil(AuthData);
  inherited;
end;

function TMobWorkSettings.GetAutoEnter_AsString: string;
begin
  result := B2S[autoEnter];
end;

procedure TMobWorkSettings.SetAutoEnter_AsString(const Value: string);
begin
  autoEnter := Value='1';
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


initialization

finalization

end.
