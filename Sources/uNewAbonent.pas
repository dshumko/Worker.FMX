unit uNewAbonent;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, BasicForma, FGX.ProgressDialog,
  FMX.Controls.Presentation, FMX.Objects, FMX.ScrollBox, FMX.Edit, FMX.Layouts, FMX.Memo, FMX.ZMaterialEdit,
  FMX.ZMaterialBackButton, FMX.TabControl, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.Utils, modTypes, FMX.ZNativeDrawFigure, FMX.ZMaterialActionButton;

type
  TfrmNewAbonent = class(TBasicForm)
    pScroll: TPresentedScrollBox;
    edFlat: TZMaterialEdit;
    edSecondName: TZMaterialEdit;
    edName: TZMaterialEdit;
    edThirdName: TZMaterialEdit;
    edPassportNum: TZMaterialEdit;
    edPassportReg: TZMaterialEdit;
    tcTabs: TTabControl;
    tiAbonent: TTabItem;
    tiService: TTabItem;
    tiEqiupment: TTabItem;
    tiDiscount: TTabItem;
    lvServices: TListView;
    lvEquipment: TListView;
    lvDiscount: TListView;
    fabServices: TZMaterialActionButton;
    SpeedButton1: TSpeedButton;
    fabEquipment: TZMaterialActionButton;
    SpeedButton2: TSpeedButton;
    Layout1: TLayout;
    sbPrevTab: TSpeedButton;
    sbNextTab: TSpeedButton;
    tiNotice: TTabItem;
    btnSend: TButton;
    Layout7: TLayout;
    Label7: TLabel;
    mDesc: TMemo;
    fabDiscount: TZMaterialActionButton;
    SpeedButton3: TSpeedButton;
    lblPage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure btnSendClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lvServicesUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure fabServicesClick(Sender: TObject);
    procedure lvEquipmentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormShow(Sender: TObject);
    procedure fabEquipmentClick(Sender: TObject);
    procedure sbPrevTabClick(Sender: TObject);
    procedure sbNextTabClick(Sender: TObject);
    procedure tcTabsChange(Sender: TObject);
    procedure sbBackClick(Sender: TObject);
    procedure fabDiscountClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lvServicesItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvDiscountItemClick(const Sender: TObject; const AItem: TListViewItem);
  private
    { Private declarations }
    FHouseID: integer;
    FCustomerID: integer;
    FKeyboardShowed: Boolean;

    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure ConfigLV(const aLV: TListView);
    procedure StoredProcService;
    procedure StoredProcEquipment;
    procedure StoredProcDiscount;

    procedure DeleteItem(const aLV: TListView; const aIndex: integer);
  public
    { Public declarations }
    procedure Show(const aHouseID: integer; const aStreet: string); overload;
    procedure Show(const aCustomerInfo: TmyTypeCustomer); overload;
  end;

var
  frmNewAbonent: TfrmNewAbonent;

implementation

{$R *.fmx}

uses
  FMX.DialogService, System.Math, System.Threading, modNative, modAPI, modJSON, uCustomer, XSuperObject,
  modDrawer, uServiceAdd, uEqipment, modUI, FMX.StatusBar, uEquipmentAdd, uDiscountAdd, uMain;

function FindGroupID(const aValue: string; aLV: TListView; const Alternative: Boolean = false): integer;
var
  I: integer;
  Found: Boolean;
begin
  Result := -1;
  for I := 0 to aLV.Items.Count - 1 do
  begin
    if Alternative then
      Found := (aLV.Items[I].Text.StartsWith('Подключен к:')) and (aLV.Items[I].Detail = aValue)
    else
      Found := (aLV.Items[I].Purpose = TListItemPurpose.Header) and (aLV.Items[I].Text = aValue);
    if Found then
    begin
      Result := I;
      break;
    end;
  end;
end;

procedure TfrmNewAbonent.DeleteItem(const aLV: TListView; const aIndex: integer);
begin
  TTask.Run(
    procedure
    begin
      TThread.Synchronize(nil,
        procedure
        begin
          aLV.Items.Delete(aIndex);
        end)
    end);
end;

procedure TfrmNewAbonent.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
begin
  AHandled := AItem.Purpose = TListItemPurpose.None;

  if not AHandled then
    exit;

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

procedure TfrmNewAbonent.fabDiscountClick(Sender: TObject);
begin
  inherited;
  with TmyStoreData.FDiscount do
  begin
    discount_id := 0;
    name := '';
    from_date := 0;
    to_date := 0;
    sum := 0;
    notice := '';
  end;

  TfrmDiscountAdd.Create(application).Show(FCustomerID,
    procedure
    begin
      StoredProcDiscount;
    end);
end;

procedure TfrmNewAbonent.fabEquipmentClick(Sender: TObject);
begin
  inherited;
  with TmyStoreData.FEquipment do
  begin
    equipment_id := 0;
    name := '';
    ip := '';
    mac := '';
    port := 0;
    notice := '';
  end;

  TfrmEquipmentAdd.Create(application).Show(FHouseID,
    procedure
    begin
      StoredProcEquipment;
    end);
end;

procedure TfrmNewAbonent.fabServicesClick(Sender: TObject);
begin
  inherited;
  if not fabServices.Visible then exit;
  
  with TmyStoreData.FService do
  begin
    service_id := 0;
    name := '';
    onList_id := 0;
    onList_name := '';
    date := now;
    notice := '';
  end;

  TfrmServiceAdd.Create(application).Show(FCustomerID,
    procedure
    begin
      StoredProcService;
    end);
end;

procedure TfrmNewAbonent.ConfigLV(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetail';
  aLV.ItemAppearance.ItemHeight := 60;
  aLV.SearchVisible := false;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Detail.Visible := false;
    Image.Visible := false;

    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 0;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := true;

{$IFDEF IOS} Detail.Font.Size := 10.5; {$ENDIF}
    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;
  end;
end;

procedure TfrmNewAbonent.btnSendClick(Sender: TObject);
var
  newCustomer: TmyTypeNewCustomer;
  aJSON: string;
  xJS: ISuperObject;
  I: integer;
begin
  inherited;

  newCustomer.customer_id := FCustomerID;
  newCustomer.flat := edFlat.Text;
  newCustomer.secondname := edSecondName.Text;
  newCustomer.name := edName.Text;
  newCustomer.thirdname := edThirdName.Text;
  newCustomer.passport_num := edPassportNum.Text;
  newCustomer.passport_reg := edPassportReg.Text;
  newCustomer.desc := mDesc.Text;
  newCustomer.house_id := FHouseID;

  for I := 0 to lvServices.Items.Count - 1 do
  begin
    if lvServices.Items[I].HasData['store_onList_id'] then
    begin
      SetLength(newCustomer.new_services, Length(newCustomer.new_services) + 1);
      with newCustomer.new_services[Length(newCustomer.new_services) - 1] do
      begin
        service_id := lvServices.Items[I].Tag;
        name := lvServices.Items[I].Text + ' / ' + lvServices.Items[I].Detail;
        onList_id := lvServices.Items[I].Data['store_onList_id'].AsInteger;
        onList_name := lvServices.Items[I].Data['store_onList_name'].AsString;
        date := lvServices.Items[I].Data['store_date'].AsExtended;
        notice := lvServices.Items[I].Data['store_notice'].AsString;
      end;
    end;
  end;

  for I := 0 to lvEquipment.Items.Count - 1 do
  begin
    if lvEquipment.Items[I].HasData['store_ip'] then
    begin
      SetLength(newCustomer.new_equipments, Length(newCustomer.new_equipments) + 1);
      with newCustomer.new_equipments[Length(newCustomer.new_equipments) - 1] do
      begin
        equipment_id := lvEquipment.Items[I].Tag;
        name := lvEquipment.Items[I].Text;
        ip := lvEquipment.Items[I].Data['store_ip'].AsString;
        mac := lvEquipment.Items[I].Data['store_mac'].AsString;
        port := lvEquipment.Items[I].Data['store_port'].AsInteger;
        notice := lvEquipment.Items[I].Data['store_notice'].AsString;
      end;
    end;
  end;

  for I := 0 to lvDiscount.Items.Count - 1 do
  begin
    if lvDiscount.Items[I].HasData['store_sum'] then
    begin
      SetLength(newCustomer.new_discounts, Length(newCustomer.new_discounts) + 1);
      with newCustomer.new_discounts[Length(newCustomer.new_discounts) - 1] do
      begin
        discount_id := lvDiscount.Items[I].Tag;
        name := lvDiscount.Items[I].Text;
        from_date := lvDiscount.Items[I].Data['store_from_date'].AsExtended;
        to_date := lvDiscount.Items[I].Data['store_to_date'].AsExtended;
        sum := lvDiscount.Items[I].Data['store_sum'].AsExtended;
        notice := lvDiscount.Items[I].Data['store_notice'].AsString;
      end;
    end;
  end;

  if (newCustomer.secondname.IsEmpty) or (newCustomer.flat.IsEmpty) then
  begin
    ShowToast('Заполните *обязательные поля');
    exit;
  end;

  // ShowToast(TJSON.Stringify<TmyTypeNewCustomer>(newCustomer));
  // exit;

  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.newCustomer(newCustomer);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          fgWait.Hide;
          if TmyJSON.isOK(aJSON) then
          begin
            ShowToast('Успешно добавлен/изменен');
            xJS := SO(aJSON);
            TfrmCustomer.Create(application).ShowAbonentInfo(xJS.I['customer_id']);
            Close;
          end
          else
            ShowToast(TmyJSON.ErrorMsg(aJSON));
        end)
    end);
end;

procedure TfrmNewAbonent.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
  end;
end;

procedure TfrmNewAbonent.FormCreate(Sender: TObject);
begin
  inherited;
  pScroll.OnCalcContentBounds := CalcContentBoundsProc;
  FKeyboardShowed := false;
  tcTabs.ActiveTab := tiAbonent;
  ConfigLV(lvServices);
  ConfigLV(lvEquipment);
  ConfigLV(lvDiscount);
  fabServices.Visible := frmMain.Rights.AbAddSrv;
end;

procedure TfrmNewAbonent.FormFocusChanged(Sender: TObject);
begin
  inherited;
  if pScroll.Visible then
    UpdateKBBounds;
end;

procedure TfrmNewAbonent.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
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

procedure TfrmNewAbonent.FormResize(Sender: TObject);
begin
  inherited;
  btnSend.Margins.Left := ClientWidth / 3;
  btnSend.Margins.Right := ClientWidth / 3;

  if fabServices.Visible then
  begin
    fabServices.Position.X := lvServices.Width - 16 - fabServices.Width;
    fabServices.Position.Y := lvServices.Height - 16 - fabServices.Height - tiService.Height - Layout1.Height +
      (rHeader.Height);
  end;

  fabEquipment.Position.X := lvEquipment.Width - 16 - fabEquipment.Width;
  fabEquipment.Position.Y := lvEquipment.Height - 16 - fabEquipment.Height - tiEqiupment.Height - Layout1.Height +
    (rHeader.Height);

  fabDiscount.Position.X := lvDiscount.Width - 16 - fabDiscount.Width;
  fabDiscount.Position.Y := lvDiscount.Height - 16 - fabDiscount.Height - tiDiscount.Height - Layout1.Height +
    (rHeader.Height);
end;

procedure TfrmNewAbonent.FormShow(Sender: TObject);
begin
  inherited;
  TmyWindow.StatusBarColor(self, TmyColors.Header);
  Content.Fill.Color := TmyColors.Content;
  rHeader.Fill.Color := TmyColors.Header;

  tcTabsChange(nil);
end;

procedure TfrmNewAbonent.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := false;
  RestorePosition;
end;

procedure TfrmNewAbonent.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmNewAbonent.lvDiscountItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aIndex: integer;
begin
  inherited;
  aIndex := AItem.Index;
  if AItem.HasData['store_sum'] then
  begin
    TDialogService.MessageDialog('Удалить коэффициент?', TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        case AResult of
          mrYES:
            DeleteItem(lvDiscount, aIndex);
        end;
      end);
  end;
end;

procedure TfrmNewAbonent.lvEquipmentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aIndex: integer;
  aHeader: string;
begin
  inherited;
  aIndex := AItem.Index;
  if AItem.HasData['store_ip'] then
  begin
    TDialogService.MessageDialog('Удалить оборудование?', TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        case AResult of
          mrYES:
            DeleteItem(lvEquipment, aIndex);
        end;
      end);
  end
  else if AItem.HasData['open_eqipment'] then
  begin
    if AItem.Data['open_eqipment'].AsInteger > 0 then
    begin
      aHeader := AItem.Text;
      TfrmEqipment.Create(application).ShowEqipmentInfo(AItem.Tag, StrToInt(AItem.Data['type'].AsString));
    end;
  end
  else if AItem.HasData['action_test'] then
  begin
    if AItem.Data['action_test'].AsInteger > 0 then
    begin
      TTask.Run(
        procedure
        var
          aJSON: string;
        begin
          aJSON := TmyAPI.Request(TmyAPI.actionEqipment(AItem.Tag, StrToInt(AItem.Data['type'].AsString)));
          TThread.Synchronize(TThread.CurrentThread,
            procedure
            begin
              if TmyJSON.isOK(aJSON) then
                ShowMessage(SO(aJSON)['result'].AsString)
              else
                ShowMessage(TmyJSON.ErrorMsg(aJSON));
            end);
        end);
    end;
  end;
end;

procedure TfrmNewAbonent.lvServicesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aIndex: integer;
begin
  inherited;
  aIndex := AItem.Index;
  if AItem.HasData['store_onList_id'] then
  begin
    TDialogService.MessageDialog('Удалить услугу?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        case AResult of
          mrYES:
            DeleteItem(lvServices, aIndex);
        end;
      end);
  end;
end;

procedure TfrmNewAbonent.lvServicesUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmNewAbonent.RestorePosition;
begin
  pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, 0);
  pScroll.RealignContent;
end;

procedure TfrmNewAbonent.sbBackClick(Sender: TObject);
begin
  if tcTabs.TabIndex <> 0 then
    sbPrevTabClick(Sender)
  else
    inherited;
end;

procedure TfrmNewAbonent.sbNextTabClick(Sender: TObject);
begin
  inherited;
  case tcTabs.TabIndex of
    0:
      tcTabs.SetActiveTabWithTransition(tiService, TTabTransition.Slide, TTabTransitionDirection.Normal);
    1:
      tcTabs.SetActiveTabWithTransition(tiEqiupment, TTabTransition.Slide, TTabTransitionDirection.Normal);
    2:
      tcTabs.SetActiveTabWithTransition(tiDiscount, TTabTransition.Slide, TTabTransitionDirection.Normal);
    3:
      tcTabs.SetActiveTabWithTransition(tiNotice, TTabTransition.Slide, TTabTransitionDirection.Normal);
  end;
end;

procedure TfrmNewAbonent.sbPrevTabClick(Sender: TObject);
begin
  inherited;
  case tcTabs.TabIndex of
    1:
      tcTabs.SetActiveTabWithTransition(tiAbonent, TTabTransition.Slide, TTabTransitionDirection.Reversed);
    2:
      tcTabs.SetActiveTabWithTransition(tiService, TTabTransition.Slide, TTabTransitionDirection.Reversed);
    3:
      tcTabs.SetActiveTabWithTransition(tiEqiupment, TTabTransition.Slide, TTabTransitionDirection.Reversed);
    4:
      tcTabs.SetActiveTabWithTransition(tiDiscount, TTabTransition.Slide, TTabTransitionDirection.Reversed);
  end;
end;

procedure TfrmNewAbonent.Show(const aCustomerInfo: TmyTypeCustomer);
var
  I: integer;
  AItem: TListViewItem;
  aStr: string;
  aGroupID: integer;
begin
  FHouseID := aCustomerInfo.struct[0].house_id;
  // lbTitle.Text := aCustomerInfo.struct[0].street;
  edName.Text := aCustomerInfo.struct[0].firstname;
  edSecondName.Text := aCustomerInfo.struct[0].surname;
  edThirdName.Text := aCustomerInfo.struct[0].midlename;
  edFlat.Text := aCustomerInfo.struct[0].flat;
  FCustomerID := aCustomerInfo.struct[0].id;
  edPassportNum.Text := aCustomerInfo.struct[0].passport_num;
  edPassportReg.Text := aCustomerInfo.struct[0].passport_reg;

  if Length(aCustomerInfo.struct[0].services) > 0 then
  begin
    for I := Low(aCustomerInfo.struct[0].services) to High(aCustomerInfo.struct[0].services) do
    begin
      AItem := lvServices.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := aCustomerInfo.struct[0].services[I].name;
        Detail := aCustomerInfo.struct[0].services[I].tarif;
        Data['arrow_show'] := 0;
        Data['detail_show'] := 1;
        Data['height'] := 0;
        Tag := aCustomerInfo.struct[0].services[I].service_id;
      end;
      FCabinetUpdate := true;
      lvServices.Adapter.ResetView(AItem);
    end;
  end;

  if Length(aCustomerInfo.struct[0].equipment) > 0 then
  begin
    for I := Low(aCustomerInfo.struct[0].equipment) to High(aCustomerInfo.struct[0].equipment) do
    begin
      if aCustomerInfo.struct[0].equipment[I].parent_id > 0 then
      begin
        aStr := aCustomerInfo.struct[0].equipment[I].parent_name;
        aGroupID := FindGroupID(aStr, lvEquipment, true);
        if aGroupID = -1 then
        begin
          AItem := lvEquipment.Items.Add;
          FCabinetUpdate := false;
          with AItem do
          begin
            Text := 'Подключен к:';
            Detail := aStr;
            Data['arrow_show'] := 1;
            Data['detail_show'] := 1;
            Data['height'] := 0;
            Data['open_eqipment'] := 1;
            Data['type'] := aCustomerInfo.struct[0].equipment[I].e_type;
            Tag := aCustomerInfo.struct[0].equipment[I].parent_id;
          end;
          FCabinetUpdate := true;
          lvEquipment.Adapter.ResetView(AItem);
        end;
      end;
    end;

    for I := Low(aCustomerInfo.struct[0].equipment) to High(aCustomerInfo.struct[0].equipment) do
    begin
      if aCustomerInfo.struct[0].equipment[I].parent_id > 0 then
      begin
        aStr := aCustomerInfo.struct[0].equipment[I].parent_name;
        aGroupID := FindGroupID(aStr, lvEquipment, true);
      end
      else
        aGroupID := lvEquipment.Items.Count - 1;

      AItem := lvEquipment.Items.Insert(aGroupID + 1);
      FCabinetUpdate := false;
      with AItem do
      begin
        if aCustomerInfo.struct[0].equipment[I].port <> '' then
          Text := '[ ' + aCustomerInfo.struct[0].equipment[I].port + ' ] ';

        Text := Text + aCustomerInfo.struct[0].equipment[I].name;
        Detail := aCustomerInfo.struct[0].equipment[I].mac;
        Data['arrow_show'] := 0;
        Data['detail_show'] := 1;
        Data['height'] := 0;
        Data['action_test'] := 1;
        Data['type'] := aCustomerInfo.struct[0].equipment[I].e_type;
        Tag := aCustomerInfo.struct[0].equipment[I].id;
      end;
      FCabinetUpdate := true;
      lvEquipment.Adapter.ResetView(AItem);
    end;
  end;

  Show;
end;

procedure TfrmNewAbonent.StoredProcDiscount;
var
  AItem: TListViewItem;
begin
  AItem := lvDiscount.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := TmyStoreData.FDiscount.name;
    Data['arrow_show'] := 0;
    Data['detail_show'] := 0;
    Data['height'] := 0;
    Data['store_from_date'] := TmyStoreData.FDiscount.from_date;
    Data['store_to_date'] := TmyStoreData.FDiscount.to_date;
    Data['store_sum'] := TmyStoreData.FDiscount.sum;
    Data['store_notice'] := TmyStoreData.FDiscount.notice;
    Tag := TmyStoreData.FDiscount.discount_id;
  end;
  FCabinetUpdate := true;
  lvDiscount.SetCustomColorForItem(AItem.Index, TmyColors.CustomerOffType);
  lvDiscount.Adapter.ResetView(AItem);

  with TmyStoreData.FDiscount do
  begin
    discount_id := 0;
    name := '';
    from_date := 0;
    to_date := 0;
    sum := 0;
    notice := '';
  end;
end;

procedure TfrmNewAbonent.StoredProcEquipment;
var
  AItem: TListViewItem;
begin
  AItem := lvEquipment.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := TmyStoreData.FEquipment.name;
    Detail := TmyStoreData.FEquipment.ip;
    Data['arrow_show'] := 0;
    Data['detail_show'] := 1;
    Data['height'] := 0;
    Data['store_ip'] := TmyStoreData.FEquipment.ip;
    Data['store_mac'] := TmyStoreData.FEquipment.mac;
    Data['store_port'] := TmyStoreData.FEquipment.port;
    Data['store_notice'] := TmyStoreData.FEquipment.notice;
    Tag := TmyStoreData.FEquipment.equipment_id;
  end;
  FCabinetUpdate := true;
  lvEquipment.SetCustomColorForItem(AItem.Index, TmyColors.CustomerOffType);
  lvEquipment.Adapter.ResetView(AItem);

  with TmyStoreData.FEquipment do
  begin
    equipment_id := 0;
    name := '';
    ip := '';
    mac := '';
    port := 0;
    notice := '';
  end;
end;

procedure TfrmNewAbonent.StoredProcService;
var
  AItem: TListViewItem;
begin
  AItem := lvServices.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := TmyStoreData.FService.name;
    Detail := TmyStoreData.FService.price;
    Data['arrow_show'] := 0;
    Data['detail_show'] := 1;
    Data['height'] := 0;
    Data['store_onList_id'] := TmyStoreData.FService.onList_id;
    Data['store_onList_name'] := TmyStoreData.FService.onList_name;
    Data['store_date'] := TmyStoreData.FService.date;
    Data['store_notice'] := TmyStoreData.FService.notice;
    Tag := TmyStoreData.FService.service_id;
  end;
  FCabinetUpdate := true;
  lvServices.SetCustomColorForItem(AItem.Index, TmyColors.CustomerOffType);
  lvServices.Adapter.ResetView(AItem);

  with TmyStoreData.FService do
  begin
    service_id := 0;
    name := '';
    onList_id := 0;
    onList_name := '';
    date := now;
    notice := '';
  end;
end;

procedure TfrmNewAbonent.tcTabsChange(Sender: TObject);
begin
  inherited;
  sbPrevTab.Visible := tcTabs.ActiveTab <> tiAbonent;
  sbNextTab.Visible := tcTabs.ActiveTab <> tiNotice;
  lbTitle.Text := 'Редактирование: ' + tcTabs.ActiveTab.Text;
  lblPage.Text := tcTabs.ActiveTab.Text;
end;

procedure TfrmNewAbonent.Show(const aHouseID: integer; const aStreet: string);
begin
  FHouseID := aHouseID;
  FCustomerID := -1;
  Show;
end;

procedure TfrmNewAbonent.UpdateKBBounds;
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
      pScroll.RealignContent;
      application.ProcessMessages;
      pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;
  if not FNeedOffset then
    RestorePosition;
end;

end.
