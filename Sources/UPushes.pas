unit UPushes;

interface
uses
  System.classes, System.Types, XSuperObject, XSuperJSON,
  System.Notification, System.pushNotification
  {$IFDEF ANDROID}, System.Android.Notification , FMX.PushNotification.Android{$ENDIF}
  {$IFDEF IOS} System.IOS.Notification , FMX.PushNotification.IOS{$ENDIF}
  ;
type

  TPushData = class
  private
    FOnNotification: TPushServiceConnection.TReceiveNotificationEvent;
  public
    diDeviceID, diDeviceToken: string;
    APushService: TPushService;
    AServiceConnection: TPushServiceConnection;
    procedure RegisterPushService;
    procedure OnServiceConnectionChange(Sender: TObject; AChange: TPushService.TChanges);
    procedure OnReceiveNotificationEvent(Sender: TObject; const ANotification: TPushServiceNotification);

    property OnNotification:TPushServiceConnection.TReceiveNotificationEvent read FOnNotification write FOnNotification;
  end;

var
  PushData : TPushData;


implementation

uses
  system.sysutils;

procedure ShowNotification(ATitle, AText: string);
var
  NotifiCenter: TNotificationCenter;
  Notification: TNotification;
begin
  NotifiCenter := TNotificationCenter.Create(nil);
  Notification := NotifiCenter.CreateNotification;

  try
    if NotifiCenter.Supported then
    begin
      Notification.Title := ATitle;
      Notification.AlertBody := AText;
      Notification.EnableSound := true;
      Notification.Number := 0;
      NotifiCenter.ApplicationIconBadgeNumber := 0;
      NotifiCenter.PresentNotification(Notification);
    end;
  finally
    NotifiCenter.Free;
    Notification.Free;
  end;
end;

procedure TPushData.RegisterPushService;
begin
  FreeAndNil(APushService);
  if (TOSVersion.Platform = pfAndroid) or (TOSVersion.Platform = pfiOS) then
  begin

    // Получение и отправка токена устройства
    {$IFDEF ANDROID}
    // Для Android
    APushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.GCM);
    APushService.AppProps[TPushService.TAppPropNames.GCMAppID] := '825505333726';
    {$ENDIF}
    {$IF DEFINED(IOS) AND DEFINED(CPUARM)}
    // Для iOS
    APushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.APS);
    {$ENDIF}
    if Assigned(APushService) then
    begin
      // Создаём подключение к серверу
      AServiceConnection := TPushServiceConnection.Create(APushService);
      // Активируем подключение
      AServiceConnection.Active := true;
      // Подключаем делегаты
      AServiceConnection.OnChange := OnServiceConnectionChange;
      AServiceConnection.OnReceiveNotification := OnReceiveNotificationEvent;

      diDeviceID := APushService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceID];
      diDeviceToken := APushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];
    end;
  end;
end;


procedure TPushData.OnReceiveNotificationEvent(Sender: TObject;
  const ANotification: TPushServiceNotification);
var
  FTitle, FText: string;
  X: ISuperObject;
begin
  // если обработчик назначен, вызываем его, иначе - свой
  if Assigned(FOnNotification) then
  begin
    FOnNotification(Sender, ANotification);
    exit;
  end;

  X := SO(ANotification.Json.ToString);

  FTitle := X.s['title'];
  FText := X.s['message'];
  if (FTitle.IsEmpty) or (FText.IsEmpty) then
    exit;

  ShowNotification(FTitle, FText);
end;


procedure TPushData.OnServiceConnectionChange(Sender: TObject;
  AChange: TPushService.TChanges);
begin
  diDeviceID := APushService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceID];
  diDeviceToken := APushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];
end;


initialization
  PushData := TPushData.Create;

finalization

  FreeAndNil(pushData);

end.
