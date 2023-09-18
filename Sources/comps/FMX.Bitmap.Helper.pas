unit FMX.Bitmap.Helper;

interface

uses
  System.Classes, System.IOUtils, System.SysUtils,
  System.Net.HTTPClient, System.Net.HTTPClientComponent,
  FMX.Graphics, AnonThread;

type
  TBitmapHelper = class helper for TBitmap
  public
    procedure LoadFromURL(const aURL: string);
  end;

implementation

{ TBitmapHelper }

uses modAPI;

procedure TBitmapHelper.LoadFromURL(const aURL: string);
var
  AFileName: string;
  AExist: boolean;
begin
  if aURL.IsEmpty then
    exit;

  AFileName := TPath.Combine(TPath.GetDocumentsPath, TmyAPI.md5(aURL));
  AExist := FileExists(AFileName);

  TAnonymousThread<TMemoryStream>.Create(
    function: TMemoryStream
    var
      Http: TNetHTTPClient;
    begin
      Result := TMemoryStream.Create;
      if not AExist then
      begin
        Http := TNetHTTPClient.Create(nil);
        try
          Http.Get(aURL, Result)
        finally
          FreeAndNil(Http);
        end;
      end
      else
        Result.LoadFromFile(AFileName);
    end,

    procedure(AResult: TMemoryStream)
    begin
      if not Assigned(AResult) then
        exit;
      if (AResult.Size > 0) then
      begin
        if Assigned(self) then
          LoadFromStream(AResult);
        if not AExist then
          AResult.SaveToFile(AFileName);
      end;
      FreeAndNil(AResult);
    end,

    procedure(AException: Exception)
    begin
    end);
end;

end.
