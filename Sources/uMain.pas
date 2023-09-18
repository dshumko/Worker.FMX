unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Permissions,
  FMX.Utils, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Sensors, System.Sensors.Components, FGX.ProgressDialog,
  FMX.ZMaterialEdit, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.ListView, FMX.Objects,
  modTypes, modUI, System.PushNotification, System.Notification
  {$IFDEF ANDROID},
  FMX.PushNotification.Android
  {$ENDIF}
  {$IFDEF IOS},
  FMX.PushNotification.IOS
  {$ENDIF};

type
  TfrmMain = class(TForm)
    Content: TRectangle;
    lvContent: TListView;
    rHeader: TRectangle;
    lbTitle: TLabel;
    fgWait: TfgActivityDialog;
    aGPS: TLocationSensor;
    tmGPSInterval: TTimer;
    pScroll: TVertScrollBox;
    layUserAuth: TLayout;
    rShadowLayer: TRectangle;
    Layout1: TLayout;
    btnUserAuth: TButton;
    lbAutoEnter: TLabel;
    swAutoEnter: TSwitch;
    StyleBook1: TStyleBook;
    edCompany: TZMaterialEdit;
    edUserAcc: TZMaterialEdit;
    edUserPass: TZMaterialEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure lvContentResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure aGPSLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
    procedure tmGPSIntervalTimer(Sender: TObject);
    procedure btnUserAuthClick(Sender: TObject);
    procedure edUserPassChange(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormFocusChanged(Sender: TObject);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvContentApplyStyleLookup(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edCompanyKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure edUserAccKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure edUserPassKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    back_pressed: Single;
    FGPSFirstStart: Boolean;
    FGPSLastTime: TDateTime;

    diDeviceID, diDeviceToken: string;
    APushService: TPushService;
    AServiceConnection: TPushServiceConnection;
    FKeyboardShowed: Boolean;
    FNeedCheckValidURL: Boolean;
    FSettings: TmyTypeSettingsData;
    FRights: TUserRights;
    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    // "Опасные" разрешения, омеченные в настройках проекта
    FPermission_ACCESS_COARSE_LOCATION: string;
    FPermission_ACCESS_FINE_LOCATION: string;
    FPermission_CALL_PHONE: string;
    FPermission_CAMERA: string;
    FPermission_READ_CALENDAR: string;
    FPermission_READ_PHONE_STATE: string;
    FPermission_WRITE_CALENDAR: string;
    FPermission_READ_EXTERNAL_STORAGE: string;
    FPermission_WRITE_EXTERNAL_STORAGE: string;
    FPermissionsGranted: Boolean;
    procedure GetPermissionsNames; // Получение "имен" разрешений
    procedure CheckPermissions; // Проверка выдачи разрешений
    procedure DisplayRationale(Sender: TObject; const APermissions: TArray<string>; const APostRationaleProc: TProc);
    procedure TakePermissionsRequestResult(Sender: TObject; const APermissions: TArray<string>;
      const AGrantResults: TArray<TPermissionStatus>);

    procedure OnReceiveNotificationEvent(Sender: TObject; const ANotification: TPushServiceNotification);
    procedure OnServiceConnectionChange(Sender: TObject; AChange: TPushService.TChanges);

    procedure RebuildOrientation;
    procedure ShowListView;
    procedure makeMenu(const aLV: TListView);
    procedure ConfigMenu(const aLV: TListView);
    function ReadAuthData(const aData: string): integer;
    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure OnColumnClick(const Sender: TObject; const Column: integer; const X, Y: Single;
      const AItem: TListViewItem; const DrawebleName: string);
    function CheckGPS: Boolean;
  public
    property Rights: TUserRights read FRights;
    procedure RegisterPushService;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  System.Math,
  System.Threading,
  System.DateUtils,
  FMX.StatusBar,
  FMX.FontAwesome,
  FMX.DeviceInfo,
  FMX.DialogService,
  {$IFDEF ANDROID}
  FMX.VirtualKeyboard,
  FMX.Platform,
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os,
  {$ENDIF}
  XSuperObject,
  modJSON,
  modNative,
  modAPI,
  uAddress,
  uBidList,
  uContacts,
  uPromotions,
  uBookmarks;

function getRealIndex(const Row, Column, Columns: integer): integer;
begin
  Result := (((Row + 1) * Columns) - 1) - (Columns - Column);
end;

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

procedure TfrmMain.OnColumnClick(const Sender: TObject; const Column: integer; const X, Y: Single;
  const AItem: TListViewItem; const DrawebleName: string);
begin
  if AItem.Index = 0 then
    begin
      if Column = 1 then
        TfrmBidList.Create(Application).ShowBidList(0, 0)
      else
        TfrmAddress.Create(Application).ShowStreets;
    end
  else if AItem.Index = 1 then
    begin
      if Column = 1 then
        TfrmPromotions.Create(Application).ShowPromotions
      else
        TfrmContacts.Create(Application).ShowContacts;
    end
  else if AItem.Index = 2 then
    begin
      if Column = 1 then
        TfrmBookmarks.Create(Application).Show;
    end;
end;

procedure TfrmMain.OnReceiveNotificationEvent(Sender: TObject; const ANotification: TPushServiceNotification);
var
  FTitle, FText: string;
  xJS: ISuperObject;
begin
  xJS := SO(ANotification.Json.ToString);

  FTitle := xJS.s['title'];
  FText := xJS.s['message'];
  if (FTitle.IsEmpty) or (FText.IsEmpty) then
    exit;
  ShowNotification(FTitle, FText);
end;

procedure TfrmMain.OnServiceConnectionChange(Sender: TObject; AChange: TPushService.TChanges);
begin
  diDeviceID := APushService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceID];
  diDeviceToken := APushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];
end;

procedure TfrmMain.aGPSLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
{$IFNDEF MSWINDOWS}
var
  aLat: Double;
  aLon: Double;
  {$ENDIF}
begin
  {$IFNDEF MSWINDOWS}
  FGPSLastTime := Now();
  aLat := NewLocation.Latitude;
  aLon := NewLocation.Longitude;
  TTask.Run(
    procedure
    begin
      TmyAPI.Request(TmyAPI.setLocation(aLat, aLon));
    end);
  aGPS.Active := false;
  {$ENDIF}
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  // SetHeadColor(rHeader.Fill.Color);
  FKeyboardShowed := false;
  rHeader.Fill.Color := TmyColors.Header;
  Fill.Kind := TBrushKind.Solid;
  Fill.Color := TmyColors.Header;
  Content.Fill.Color := TmyColors.Header;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CloseApp;
  {$IFDEF ANDROID}
  // KillMe;
  {$ENDIF}
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FPermissionsGranted := False;
  GetPermissionsNames;
  CheckPermissions;

  pScroll.OnCalcContentBounds := CalcContentBoundsProc;
  FKeyboardShowed := false;

  lbTitle.Font.Size := 18;
  lbTitle.FontColor := TAlphaColorRec.White;

  lbAutoEnter.StyledSettings := lbAutoEnter.StyledSettings - [TstyledSetting.FontColor];

  {$IFDEF ANDROID}
  btnUserAuth.FontColor := TAlphaColorRec.White;
  lbAutoEnter.FontColor := TAlphaColorRec.White;
  {$ELSE}
  lbAutoEnter.FontColor := TAlphaColorRec.Black;
  btnUserAuth.FontColor := TAlphaColorRec.Black;
  {$ENDIF};

  TmyJSON.ReadSettingsData(TmyJSON.LoadFromFile(TmyPath.SettingsFile), FSettings);
  edUserAcc.Text := FSettings.login;
  edUserPass.Text := FSettings.password;
  edCompany.Text := FSettings.Company;

  swAutoEnter.IsChecked := FSettings.autoEnter = '1';

  if not FSettings.validURL.IsEmpty then
    begin
      TmyAPI.FValidURL := FSettings.validURL;
      TmyAPI.FvalidURL_date := FSettings.validURL_date;
      FNeedCheckValidURL := not(TmyAPI.FvalidURL_date = Date());
      FNeedCheckValidURL := FNeedCheckValidURL or (TmyAPI.FvalidURL_date >= (Date() + 7));
    end
  else
    FNeedCheckValidURL := true;

  if swAutoEnter.IsChecked then
    btnUserAuthClick(nil);
end;

procedure TfrmMain.FormFocusChanged(Sender: TObject);
begin
  if pScroll.Visible then
    UpdateKBBounds;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
{$IFDEF ANDROID}
var
  Keyboard: IFMXVirtualKeyboardService;
  {$ENDIF}
begin
  if (Key = vkHardwareBack) or (Key = vkEscape) then
    begin
      if FKeyboardShowed then
        begin
          // hide virtual keyboard
          {$IFDEF ANDROID}
          if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(Keyboard)) and
            (TVirtualKeyboardState.Visible in Keyboard.VirtualKeyboardState) then
            Keyboard.HideVirtualKeyboard;
          {$ENDIF}
        end
      else
        begin
          if (back_pressed + 2000) > MilliSecondOfTheDay(Now) then
            Close
          else
            ShowToast('Нажмите еще раз для выхода');
          back_pressed := MilliSecondOfTheDay(Now);
        end;
      Key := 0;
    end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  RebuildOrientation;
  if lvContent.Visible then
    makeMenu(lvContent);
  btnUserAuth.Margins.Left := ClientWidth / 3;
  btnUserAuth.Margins.Right := ClientWidth / 3;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FKeyboardShowed := false;

  TmyWindow.StatusBarColor(self, TmyColors.Header);
  Content.Fill.Color := TmyColors.Content;
  rHeader.Fill.Color := TmyColors.Header;
  RebuildOrientation;
end;

procedure TfrmMain.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKeyboardShowed := KeyboardVisible;
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := false;
  RestorePosition;
end;

procedure TfrmMain.RestorePosition;
begin
  pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, 0);
  pScroll.RealignContent;
end;

procedure TfrmMain.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKeyboardShowed := KeyboardVisible;
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmMain.btnUserAuthClick(Sender: TObject);
const
  B2S: array [Boolean] of string = ('0', '1');
var
  aJSON, aJSON2, aRespData: string;
begin
  TmyAPI.FLogin := edUserAcc.Text;
  TmyAPI.FPassword := edUserPass.Text;
  TmyAPI.FCompany := edCompany.Text;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      if FNeedCheckValidURL then
        begin
          aRespData := TmyAPI.GetValidURL;
          if not aRespData.IsEmpty then
            begin
              TmyAPI.FValidURL := aRespData;
              TmyAPI.FvalidURL_date := Now();
            end
          else
            TmyAPI.FValidURL := A4onApiURL;
        end;

      aJSON := TmyAPI.Request(TmyAPI.userAuth);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          // ShowToast(TmyAPI.FValidURL + sLineBreak + aRespData + '....');
          if TmyJSON.isOK(aJSON) then
            begin
              FSettings.login := TmyAPI.FLogin;
              FSettings.password := TmyAPI.FPassword;
              FSettings.autoEnter := B2S[swAutoEnter.IsChecked];
              FSettings.gpsInterval := ReadAuthData(aJSON);
              FSettings.Company := TmyAPI.FCompany;
              FSettings.validURL := TmyAPI.FValidURL;
              FSettings.validURL_date := TmyAPI.FvalidURL_date;
              TmyJSON.SaveToFile(TmyJSON.WriteSettingsData(FSettings), TmyPath.SettingsFile);

              RegisterPushService;

              if not diDeviceID.IsEmpty and not diDeviceToken.IsEmpty then
                begin
                  TTask.Run(
                    procedure
                    begin
                      aJSON2 := TmyAPI.Request(TmyAPI.SaveToken(diDeviceID, diDeviceToken));
                    end);
                end;
              ShowListView;
              fgWait.Hide;
            end
          else
            begin
              fgWait.Hide;
              ShowToast(TmyJSON.ErrorMsg(aJSON));
            end;
        end)
    end);
end;

procedure TfrmMain.lvContentApplyStyleLookup(Sender: TObject);
begin
  lvContent.SetColorBackground(TmyColors.Content);
end;

procedure TfrmMain.lvContentResize(Sender: TObject);
begin
  (Sender as TListView).SeparatorLeftOffset := (Sender as TListView).Width;
end;

procedure TfrmMain.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
var
  iTitle, iGlyph: TListItemText;
  aPos: Single;
  I: integer;
begin
  for I := 1 to lvContent.Columns do
    begin
      if not InRange(I, 1, AItem.Tag) then
        continue;

      aPos := (((lvContent.ColumnWidth * I) - lvContent.ColumnWidth) - 6) + Trunc(lvContent.ColumnOffset * I);

      iGlyph := AItem.Objects.FindObjectT<TListItemText>('glyph' + IntToStr(I));
      if iGlyph = nil then
        iGlyph := TListItemText.Create(AItem);
      iGlyph.Name := 'glyph' + IntToStr(I);
      iGlyph.Width := lvContent.ColumnWidth - 8;
      iGlyph.Height := lvContent.ColumnWidth - 38;
      iGlyph.TextAlign := TTextAlign.Center;
      iGlyph.TextVertAlign := TTextAlign.Center;
      iGlyph.SelectedTextColor := TmyColors.MenuPics;
      iGlyph.TextColor := TmyColors.MenuPics;
      iGlyph.PlaceOffset.X := aPos;
      iGlyph.PlaceOffset.Y := 4;
      iGlyph.Font.Family := FontAwesomeName;
      iGlyph.Font.Size := lvContent.ColumnWidth / 2;
      iGlyph.Text := AItem.Data['glyph' + IntToStr(I)].AsString;

      iTitle := AItem.Objects.FindObjectT<TListItemText>('title' + IntToStr(I));
      if iTitle = nil then
        iTitle := TListItemText.Create(AItem);
      iTitle.Name := 'title' + IntToStr(I);
      iTitle.TextAlign := TTextAlign.Center;
      iTitle.TextVertAlign := TTextAlign.Center;
      iTitle.SelectedTextColor := TAlphaColorRec.Black;
      iTitle.TextColor := TAlphaColorRec.Black;
      iTitle.Font.Size := 14;
      iTitle.WordWrap := true;
      iTitle.Width := iGlyph.Width - 8;
      iTitle.PlaceOffset.X := aPos { + 8 };
      iTitle.PlaceOffset.Y := iGlyph.Height;
      iTitle.Height := lvContent.ItemAppearance.ItemHeight - iTitle.PlaceOffset.Y;
      iTitle.Text := AItem.Data['title' + IntToStr(I)].AsString;
    end;

  AHandled := true;
end;

procedure TfrmMain.RebuildOrientation;
begin
  Content.Margins.Top := TmyWindow.StatusBarHeight;
end;

procedure TfrmMain.ShowListView;
begin
  tmGPSInterval.Enabled := CheckGPS;
  if tmGPSInterval.Enabled then
    FGPSLastTime := System.DateUtils.IncMinute(Now(), -1 * FSettings.gpsInterval);

  pScroll.Visible := false;
  lvContent.Visible := true;
  Resize;
end;

procedure TfrmMain.TakePermissionsRequestResult(Sender: TObject; const APermissions: TArray<string>;
const AGrantResults: TArray<TPermissionStatus>);
begin
  if (Length(AGrantResults) = 9) and (AGrantResults[0] = TPermissionStatus.Granted) and
    (AGrantResults[1] = TPermissionStatus.Granted) and (AGrantResults[2] = TPermissionStatus.Granted) and
    (AGrantResults[3] = TPermissionStatus.Granted) and (AGrantResults[4] = TPermissionStatus.Granted) and
    (AGrantResults[5] = TPermissionStatus.Granted) and (AGrantResults[6] = TPermissionStatus.Granted) and
    (AGrantResults[7] = TPermissionStatus.Granted) and (AGrantResults[8] = TPermissionStatus.Granted) then
    begin
      // Разрешения получены
      FPermissionsGranted := True;
    end
  else
    begin
      FPermissionsGranted := False;
      ShowToast('Работа приложения может быть нарущена, т.к. не получены необходимые разрешения');
    end;
end;

procedure TfrmMain.tmGPSIntervalTimer(Sender: TObject);
begin
  if (CheckGPS) and (System.DateUtils.MinutesBetween(Now(), FGPSLastTime) >= FSettings.gpsInterval) and (not aGPS.Active)
  then
    aGPS.Active := true
end;

procedure TfrmMain.RegisterPushService;
begin
  if (TOSVersion.Platform = pfAndroid) or (TOSVersion.Platform = pfiOS) then
    begin
      APushService := nil;

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

procedure TfrmMain.edCompanyKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    begin
      edUserAcc.SetFocus;
      Key := 0;
    end;
end;

procedure TfrmMain.edUserAccKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    begin
      edUserPass.SetFocus;
      Key := 0;
    end;
end;

procedure TfrmMain.edUserPassChange(Sender: TObject);
begin
  btnUserAuth.Enabled := (not edUserAcc.Text.IsEmpty) and (not edUserPass.Text.IsEmpty);
end;

procedure TfrmMain.edUserPassKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    begin
      btnUserAuthClick(nil);
      Key := 0;
    end;
end;

procedure TfrmMain.ConfigMenu(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'Custom';
  // aLV.ItemAppearance.ItemHeight := 60;
  aLV.ShowSelection := false;
  aLV.SeparatorLeftOffset := aLV.Width;
  aLV.ShowScrollBar := false;

  aLV.ColumnWidth := aLV.Width / 2;
  aLV.AutoColumns := true;
  aLV.ItemAppearance.ItemHeight := Trunc(aLV.ColumnWidth);
  aLV.OnColumnClick := OnColumnClick;
  aLV.ShowScrollBar := false;
  aLV.EnableTouchAnimation(false);

  with aLV.ItemAppearanceObjects.ItemObjects do
    begin
      Image.Visible := false;
      Accessory.Visible := false;
      TextButton.Visible := false;
      GlyphButton.Visible := false;
      Text.Visible := false;
      Detail.Visible := false;
    end;
end;

procedure TfrmMain.DisplayRationale(Sender: TObject; const APermissions: TArray<string>;
const APostRationaleProc: TProc);
var
  i: integer;
  RationaleMsg: string;
begin
  RationaleMsg := string.Empty;
  for i := 0 to High(APermissions) do
    begin
      if (APermissions[i] = FPermission_ACCESS_COARSE_LOCATION) or (APermissions[i] = FPermission_ACCESS_FINE_LOCATION) then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ к Вашему местоположению' + SLineBreak + SLineBreak
      else
      if APermissions[i] = FPermission_CALL_PHONE then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ для совершения звонков'
      else
      if APermissions[i] = FPermission_CAMERA then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ к Вашей камере'
      else
      if (APermissions[i] = FPermission_READ_CALENDAR) or (APermissions[i] = FPermission_WRITE_CALENDAR) then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ к Вашему календарю'
      else
      if (APermissions[i] = FPermission_READ_EXTERNAL_STORAGE) or (APermissions[i] = FPermission_WRITE_EXTERNAL_STORAGE) then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ к Вашему хранилищу'
      else
      if APermissions[i] = FPermission_READ_PHONE_STATE then
        RationaleMsg := RationaleMsg + 'Приложению необходим доступ к Вашему телефону';
    end;

  // Show an explanation to the user *asynchronously* - don't block this thread waiting for the user's response!
  // After the user sees the explanation, invoke the post-rationale routine to request the permissions
  TDialogService.ShowMessage(RationaleMsg,
    procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end);
end;

procedure TfrmMain.makeMenu(const aLV: TListView);
const
  arrTitles: array [0 .. 4] of string = ('Заявки', 'Дома', 'Акции', 'Телефоны', 'Закладки');
  arrPics: array [0 .. 4] of string = (fa_list_alt, fa_building, fa_trophy, fa_phone, fa_bookmark);
var
  J: integer;
  AItem: TListViewItem;
  RowCount: integer;
  realIndex: integer;
  ColumnInRow: integer;
begin
  aLV.ItemsClearTrue;
  ConfigMenu(aLV);

  RowCount := ceil(Length(arrTitles) / lvContent.Columns);
  realIndex := -1;

  for J := 0 to RowCount - 1 do
    begin
      inc(realIndex);

      AItem := aLV.Items.Add;
      with AItem do
        begin
          ColumnInRow := 1;

          while realIndex < Length(arrTitles) do
            begin
              Data['title' + IntToStr(ColumnInRow)] := arrTitles[realIndex];
              Data['glyph' + IntToStr(ColumnInRow)] := arrPics[realIndex];
              Tag := ColumnInRow;

              if ColumnInRow mod lvContent.Columns = 0 then
                break;
              inc(realIndex);
              inc(ColumnInRow);
            end;
        end;
      aLV.Adapter.ResetView(AItem);
    end;
end;

function TfrmMain.ReadAuthData(const aData: string): integer;
var
  aAuth: TmyTypeAuth;
begin
  Result := 0;
  if aData.IsEmpty then
    exit;

  if TmyJSON.isOK(aData) then
    begin
      aAuth := TJSON.Parse<TmyTypeAuth>(aData);
      Result := aAuth.struct[0].gps;
      FRights := aAuth.struct[0].Rights;
    end;
end;

procedure TfrmMain.UpdateKBBounds;
var
  LFocused: TControl;
  LFocusRect: TRectF;
begin
  FNeedOffset := false;
  if Assigned(Focused) then
    begin
      LFocused := TControl(Focused.GetObject);
      LFocusRect := LFocused.AbsoluteRect;
      LFocusRect.Offset(pScroll.ViewportPosition);
      if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and (LFocusRect.Bottom > FKBBounds.Top) then
        begin
          FNeedOffset := true;
          layUserAuth.Align := TAlignLayout.Horizontal;
          pScroll.RealignContent;
          Application.ProcessMessages;
          pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, LFocusRect.Bottom - FKBBounds.Top);
        end;
    end;
  if not FNeedOffset then
    RestorePosition;
end;

procedure TfrmMain.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
    begin
      ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
    end;
end;

function TfrmMain.CheckGPS: Boolean;
begin
  Result := (FSettings.gpsInterval > 0);
  if Result and (not IsGPSActive) then
    begin
      Result := false;
      ShowToast('Отключен GPS. Закроем приложение.');
      // Sleep(1000);
      CloseApp;
      {$IFDEF ANDROID}
      // KillMe;
      {$ENDIF}
    end;
end;

procedure TfrmMain.CheckPermissions;
begin
  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions([FPermission_ACCESS_COARSE_LOCATION, FPermission_ACCESS_FINE_LOCATION,
    FPermission_CALL_PHONE, FPermission_CAMERA, FPermission_READ_CALENDAR, FPermission_READ_PHONE_STATE,
    FPermission_WRITE_CALENDAR, FPermission_READ_EXTERNAL_STORAGE, FPermission_WRITE_EXTERNAL_STORAGE],
    TakePermissionsRequestResult, DisplayRationale);
  {$ENDIF}
end;

procedure TfrmMain.GetPermissionsNames;
begin
  {$IFDEF ANDROID}
  FPermission_ACCESS_COARSE_LOCATION := JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION);
  FPermission_ACCESS_FINE_LOCATION := JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION);
  FPermission_CALL_PHONE := JStringToString(TJManifest_permission.JavaClass.CALL_PHONE);
  FPermission_CAMERA := JStringToString(TJManifest_permission.JavaClass.CAMERA);
  FPermission_READ_CALENDAR := JStringToString(TJManifest_permission.JavaClass.READ_CALENDAR);
  FPermission_READ_PHONE_STATE := JStringToString(TJManifest_permission.JavaClass.READ_PHONE_STATE);
  FPermission_WRITE_CALENDAR := JStringToString(TJManifest_permission.JavaClass.WRITE_CALENDAR);
  FPermission_READ_EXTERNAL_STORAGE := JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);
  FPermission_WRITE_EXTERNAL_STORAGE := JStringToString(TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE);
  {$ENDIF}
end;

initialization

TmyWindow.Init;

end.
