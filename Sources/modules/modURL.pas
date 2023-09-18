unit modURL;

interface

uses
  IdURI, SysUtils, Classes, FMX.Dialogs
{$IFDEF ANDROID}
    , Androidapi.Helpers, FMX.Helpers.Android, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net, Androidapi.JNI.app, Androidapi.JNI.JavaTypes
{$ELSEIF defined(IOS)}
    , Macapi.Helpers, iOSapi.Foundation, FMX.Helpers.iOS
{$ELSEIF defined(MSWINDOWS)}
    , ShellAPI
{$ENDIF};

procedure openUrl(const aURL: string);

implementation

{$IFDEF ANDROID}

function andUrl(const aURL: string): boolean;
var
  Intent: JIntent;
  value: string;
begin
  if aURL.Contains('@') then
    value := aURL
  else
    value := TIdURI.URLEncode(aURL);

  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(value)));
  TAndroidHelper.Activity.startActivity(Intent);
  Result := True;
end;
{$ENDIF}
{$IFDEF IOS}

function iosUrl(const aURL: string): boolean;
var
  NSU: NSUrl;
begin
  NSU := StrToNSUrl(TIdURI.URLEncode(aURL));
  if SharedApplication.canOpenURL(NSU) then
    SharedApplication.openUrl(NSU);
end;
{$ENDIF}
{$IFDEF MSWINDOWS}

function winUrl(const aURL: string): boolean;
begin
  ShellExecute(0, 'open', pchar(aURL), nil, nil, 0);
  Result := True;
end;
{$ENDIF}

procedure openUrl(const aURL: string);
begin
{$IFDEF ANDROID} andUrl(aURL); {$ENDIF}
{$IFDEF IOS} iosUrl(aURL); {$ENDIF}
{$IFDEF MSWINDOWS} winUrl(aURL); {$ENDIF}
end;

end.
