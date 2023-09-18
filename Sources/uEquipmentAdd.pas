unit uEquipmentAdd;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, BasicForma, FGX.ProgressDialog,
  FMX.Layouts, FMX.ZMaterialBackButton, FMX.Controls.Presentation, FMX.Objects, FMX.TabControl, FMX.ZMaterialEdit,
  FMX.ScrollBox, FMX.Memo, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView;

type
  TfrmEquipmentAdd = class(TBasicForm)
    tcTabs: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    edIP: TZMaterialEdit;
    edMAC: TZMaterialEdit;
    edPORT: TZMaterialEdit;
    Layout7: TLayout;
    Label7: TLabel;
    mDesc: TMemo;
    sbConnectTo: TSpeedButton;
    SpeedButton1: TSpeedButton;
    btnSend: TButton;
    lvEquipment: TListView;
    pScroll: TPresentedScrollBox;
    procedure sbBackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormResize(Sender: TObject);
    procedure sbConnectToClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure lvEquipmentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvEquipmentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lvEquipmentApplyStyleLookup(Sender: TObject);
    procedure edMACExit(Sender: TObject);
    procedure edIPExit(Sender: TObject);
  private
    { Private declarations }
    FProc: TThreadProcedure;

    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);

    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure ConfigLV(const aLV: TListView);
    procedure makeEquipments(const aData: string);
  public
    { Public declarations }
    procedure Show(const aHouseID: Integer; const aProc: TThreadProcedure); overload;
  end;

var
  frmEquipmentAdd: TfrmEquipmentAdd;

implementation

uses
  System.Math, FMX.StatusBar, modUI, modNative, modTypes, modDrawer, System.Threading,
  modAPI, modJSON, XSuperObject, FMX.Utils;

{$R *.fmx}

function FormatMAC(const MAC: string): string;
var
  S: string;
  c: Char;
  i: Integer;
begin
  Result := '';
  if Length(MAC) < 12 then
    Exit;
  S := UpperCase(MAC);
  { }
  for c in S do
  begin
    if CharInSet(c, ['0' .. '9']) then
      Result := Result + c
    else if CharInSet(c, ['A' .. 'F']) then
      Result := Result + c;
  end;
  if Length(Result) = 12 then
  begin
    Result := Result.Insert(10, ':');
    Result := Result.Insert(8, ':');
    Result := Result.Insert(6, ':');
    Result := Result.Insert(4, ':');
    Result := Result.Insert(2, ':');
  end
  else
    Result := '';
end;

function FormatIP(const IP: string): string;
var
  c: Char;
begin
  for c in IP do
  begin
    if (CharInSet(c, ['0' .. '9']) or (c = '.')) then
      Result := Result + c;
  end;
end;

procedure TfrmEquipmentAdd.btnSendClick(Sender: TObject);
var
  vIP, vMAC: string;
  vPort: Integer;
begin
  inherited;
  vIP := FormatIP(edIP.Text);
  vMAC := FormatMAC(edMAC.Text);

  if vIP = '' then
  begin
    ShowToast('IP адрес введен не верно!');
    Exit;
  end;

  if vMAC = '' then
  begin
    ShowToast('MAC адрес введен не верно!');
    Exit;
  end;

  if lvEquipment.ItemIndex = -1 then
  begin
    ShowToast('ќборудование не выбрано');
    Exit;
  end;

  if not TryStrToInt(edPORT.Text, vPort) then
  begin
    ShowToast('”кажите порт');
    Exit;
  end;

  with TmyStoreData.FEquipment do
  begin
    equipment_id := lvEquipment.Items[lvEquipment.ItemIndex].Tag;
    name := lvEquipment.Items[lvEquipment.ItemIndex].Text;
    IP := vIP;
    MAC := vMAC;
    port := vPort;
    notice := mDesc.Text;
  end;

  if Assigned(FProc) then
    FProc();
  Close;
end;

procedure TfrmEquipmentAdd.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
  end;
end;

procedure TfrmEquipmentAdd.ConfigLV(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetail';
  aLV.ItemAppearance.ItemHeight := 44;
  aLV.SearchVisible := false;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Detail.Visible := false;
    Image.Visible := false;

    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 8;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := True;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := True;

{$IFDEF IOS} Detail.Font.Size := 10.5; {$ENDIF}
    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := True;
  end;
end;

procedure TfrmEquipmentAdd.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
begin
  AHandled := AItem.Purpose = TListItemPurpose.None;

  if not AHandled then
    Exit;

  AItem.Objects.AccessoryObject.Visible := AItem.Data['arrow_show'].AsInteger = 1;

  AItem.Objects.DetailObject.Visible := AItem.Data['detail_show'].AsInteger = 1;
  if not AItem.Objects.DetailObject.Visible then
    AItem.Objects.TextObject.Width := (Sender as TListView).Width;

  if AItem.Data['auto_height'].AsInteger = 1 then
    TmyLV.ItemHeightByDetail(AItem, (Sender as TListView));

  if AItem.HasData['center'] then
  begin
    AItem.Objects.TextObject.PlaceOffset.X := 0;
    AItem.Objects.TextObject.TextAlign := TTextAlign.Center;
  end;

  if AItem.Data['height'].AsInteger > 0 then
  begin
    AItem.Height := AItem.Data['height'].AsInteger;
    AItem.Objects.TextObject.PlaceOffset.Y := 2;
  end;
end;

procedure TfrmEquipmentAdd.edIPExit(Sender: TObject);
var
  S: string;
begin
  inherited;
  S := FormatIP(edIP.Text);
  if S <> '' then
    edIP.Text := S;
end;

procedure TfrmEquipmentAdd.edMACExit(Sender: TObject);
var
  S: string;
begin
  inherited;
  S := FormatMAC(edMAC.Text);
  if S <> '' then
    edMAC.Text := S;
end;

procedure TfrmEquipmentAdd.FormCreate(Sender: TObject);
begin
  inherited;
  pScroll.OnCalcContentBounds := CalcContentBoundsProc;
  tcTabs.ActiveTab := TabItem1;
  FKeyboardShowed := false;
end;

procedure TfrmEquipmentAdd.FormFocusChanged(Sender: TObject);
begin
  inherited;
  if pScroll.Visible then
    UpdateKBBounds;
end;

procedure TfrmEquipmentAdd.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkHardwareBack) or (Key = vkEscape) then
  begin
    if FKeyboardShowed then
    begin
      // hide virtual keyboard
    end
    else
    begin
      if tcTabs.TabIndex = 0 then
        inherited
      else
      begin
        sbBackClick(nil);
        Key := 0;
      end;
    end;
  end;
end;

procedure TfrmEquipmentAdd.FormResize(Sender: TObject);
begin
  inherited;
  btnSend.Margins.Left := ClientWidth / 3;
  btnSend.Margins.Right := ClientWidth / 3;
end;

procedure TfrmEquipmentAdd.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

procedure TfrmEquipmentAdd.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := false;
  RestorePosition;
end;

procedure TfrmEquipmentAdd.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmEquipmentAdd.lvEquipmentApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvEquipment.SetColorHeader($FFFFCC80);
  lvEquipment.SetColorTextHeader($FF212121);
  lvEquipment.SetColorBackground(TmyColors.Content);
  lvEquipment.SetColorItemSelected($FFFFF8E1);
end;

procedure TfrmEquipmentAdd.lvEquipmentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  (Sender as TListView).ShowSelection := not(Sender as TListView).IsCustomColorUsed(AItem.Index);
  (Sender as TListView).EnableTouchAnimation((Sender as TListView).ShowSelection);
  inherited;
  sbConnectTo.Text := AItem.Text;
  sbBackClick(nil);
end;

procedure TfrmEquipmentAdd.lvEquipmentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    Exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmEquipmentAdd.makeEquipments(const aData: string);
var
  i: Integer;
  AItem: TListViewItem;
  aRecord: TmyTypeLinkTo;
begin
  lvEquipment.ItemsClearTrue;
  ConfigLV(lvEquipment);

  if aData.IsEmpty then
    Exit;

  aRecord := TJSON.Parse<TmyTypeLinkTo>(aData);
  for i := Low(aRecord.struct) to High(aRecord.struct) do
  begin
    AItem := lvEquipment.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aRecord.struct[i].name;
      Data['detail_show'] := 0;
      Data['arrow_show'] := 1;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Tag := aRecord.struct[i].id;
    end;
    FCabinetUpdate := True;
    lvEquipment.Adapter.ResetView(AItem);
  end;
end;

procedure TfrmEquipmentAdd.RestorePosition;
begin
  pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, 0);
  pScroll.RealignContent;
end;

procedure TfrmEquipmentAdd.sbBackClick(Sender: TObject);
begin
  case tcTabs.TabIndex of
    0:
      inherited;
    1:
      tcTabs.SetActiveTabWithTransition(TabItem1, TTabTransition.Slide, TTabTransitionDirection.Reversed);
  end;
end;

procedure TfrmEquipmentAdd.sbConnectToClick(Sender: TObject);
begin
  inherited;
  tcTabs.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide, TTabTransitionDirection.Normal);
end;

procedure TfrmEquipmentAdd.Show(const aHouseID: Integer; const aProc: TThreadProcedure);
var
  aJSON: string;
begin
  FProc := aProc;
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getLinkTo(aHouseID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeEquipments(aJSON);
          fgWait.Hide;
        end);
    end);
end;

procedure TfrmEquipmentAdd.UpdateKBBounds;
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
      FNeedOffset := True;
      pScroll.RealignContent;
      application.ProcessMessages;
      pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;
  if not FNeedOffset then
    RestorePosition;
end;

end.
