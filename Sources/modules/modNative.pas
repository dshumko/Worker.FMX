unit modNative;

interface

uses
  System.SysUtils, FGX.Toasts, FMX.Forms, FMX.Dialogs, FMX.Platform, FMX.PhoneDialer
{$IFDEF ANDROID}
    , AndroidApi.Helpers, AndroidApi.JNI.app, FMX.Platform.Android
{$ENDIF};

procedure ShowToast(const aMsg: string);
procedure CloseApp;
procedure Call(const Number: string);

implementation

procedure CloseApp;
begin
{$IFDEF ANDROID}
  TAndroidHelper.Activity.moveTaskToBack(true);
  // MainActivity.finish;
{$ELSE}
  Application.Terminate
  // Application.MainForm.Close;
{$ENDIF}
end;

procedure ShowToast(const aMsg: string);
begin
{$IF defined(ANDROID) or defined(IOS)}
  TfgToast.Show(aMsg);
{$ELSE}
  ShowMessage(aMsg);
{$ENDIF}
end;

procedure Call(const Number: string);
var
  FPhoneDialerService: IFMXPhoneDialerService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXPhoneDialerService, FPhoneDialerService) then
    FPhoneDialerService.Call(Number)
  else
    ShowMessage('Не поддерживается платформой!' + #13#10 + 'Позвоните по номеру: ' + Number);
end;

end.
