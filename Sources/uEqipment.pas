unit uEqipment;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmEqipment = class(TBasicLVForm)
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure FormShow(Sender: TObject);
  private
    procedure makeEqipmentInfo(const aData: string; const aLV: TListView);
    procedure ConfigEqipment(const aLV: TListView);
    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
  public
    procedure ShowEqipmentInfo(const aID, aType: Integer);
  end;

var
  frmEqipment: TfrmEqipment;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI, UListItemElements,
  modAPI, modNative, modJSON, modTypes, modDrawer, uCustomers, uHouse, uCustomer;

procedure TfrmEqipment.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aJSON: string;
begin
  inherited;
  if AItem.HasData['open_houseinfo'] then
  begin
    if AItem.Data['open_houseinfo'].AsInteger > 0 then
      TfrmHouse.Create(Application).ShowHouseInfo(AItem.Tag);
  end
  else if AItem.HasData['action_test'] then
  begin
    if AItem.Data['action_test'].AsInteger > 0 then
    begin
      ShowToast('Ping');
      TTask.Run(
        procedure
        begin
          aJSON := TmyAPI.Request(TmyAPI.actionEqipment(AItem.Tag, AItem.Data['type'].AsInteger));
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
  end
  else if AItem.Data['open_eqipment'].AsInteger > 0 then
    TfrmEqipment.Create(Application).ShowEqipmentInfo(AItem.Tag, AItem.Data['type'].AsInteger)
  else if AItem.Data['open_abonent'].AsInteger > 0 then
    TfrmCustomer.Create(Application).ShowAbonentInfo(AItem.Tag);
end;

procedure TfrmEqipment.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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

procedure TfrmEqipment.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

procedure TfrmEqipment.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmEqipment.ShowEqipmentInfo(const aID, aType: Integer);
var
  aJSON: string;
begin
  lbTitle.Text := 'Оборудование';
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getEqipmentInfo(aID, aType));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            makeEqipmentInfo(aJSON, lvContent);
          end;

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmEqipment.ConfigEqipment(const aLV: TListView);
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
    Text.PlaceOffset.Y := 8;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := true;

{$IFDEF IOS} Detail.Font.Size := 10.5; {$ENDIF}
    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;
  end;
end;

procedure TfrmEqipment.makeEqipmentInfo(const aData: string; const aLV: TListView);
var
  I: Integer;
  aEqipment: TmyTypeEqipmentInfo;
  AItem: TListViewItem;
begin
  aLV.ItemsClearTrue;
  ConfigEqipment(aLV);

  if aData.IsEmpty then
    exit;

  aEqipment := TJSON.Parse<TmyTypeEqipmentInfo>(aData);

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := aEqipment.struct.name;
    Detail := aEqipment.struct.mac + sLineBreak + aEqipment.struct.notice;
    Data['arrow_show'] := 0;
    Data['detail_show'] := 1;
    Data['height'] := 0;
    Data['auto_height'] := 1;
    Tag := aEqipment.struct.id;
  end;
  FCabinetUpdate := true;
  aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
  aLV.Adapter.ResetView(AItem);

  if not aEqipment.struct.place.IsEmpty then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aEqipment.struct.place;
      Data['arrow_show'] := 1;
      Data['detail_show'] := 0;
      Data['height'] := aLV.ItemAppearance.ItemHeight; // 35;
      Data['auto_height'] := 0;
      Data['open_houseinfo'] := 1;
      Tag := aEqipment.struct.house_id;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := aEqipment.struct.ip;
    Data['arrow_show'] := 1;
    Data['detail_show'] := 0;
    Data['height'] := aLV.ItemAppearance.ItemHeight; // 35;
    Data['auto_height'] := 0;
    Data['action_test'] := 1;
    Data['center'] := 1;
    Data['type'] := aEqipment.struct.e_type;
    Tag := aEqipment.struct.id;
  end;
  FCabinetUpdate := true;

  aLV.Adapter.ResetView(AItem);

  if not aEqipment.struct.parent_aderss.IsEmpty then
  begin
    with aLV.Items.Add do
    begin
      Purpose := TListItemPurpose.Header;
      Text := 'Подключен к:';
    end;

    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aEqipment.struct.parent_aderss;
      Detail := aEqipment.struct.parent_name + sLineBreak + aEqipment.struct.parent_ip + ' порт: ' +
        aEqipment.struct.parent_port;
      Data['arrow_show'] := 1;
      Data['detail_show'] := 1;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Data['open_eqipment'] := 1;
      Data['type'] := aEqipment.struct.parent_type;
      Tag := aEqipment.struct.parent_id;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  if Length(aEqipment.struct.attributes) > 0 then
  begin
    with aLV.Items.Add do
    begin
      Purpose := TListItemPurpose.Header;
      Text := 'Атрибуты';
    end;

    for I := Low(aEqipment.struct.attributes) to High(aEqipment.struct.attributes) do
    begin
      AItem := aLV.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := aEqipment.struct.attributes[I].name;
        Data['arrow_show'] := 0;
        Data['detail_show'] := 0;
        Data['height'] := aLV.ItemAppearance.ItemHeight; // 35;
        Data['auto_height'] := 0;
      end;
      FCabinetUpdate := true;
      aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
      aLV.Adapter.ResetView(AItem);
    end;
  end;

  if Length(aEqipment.struct.ports) > 0 then
  begin
    with aLV.Items.Add do
    begin
      Purpose := TListItemPurpose.Header;
      Text := 'Порты';
    end;

    for I := Low(aEqipment.struct.ports) to High(aEqipment.struct.ports) do
    begin
      AItem := aLV.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := '[ ' + aEqipment.struct.ports[I].port + ' ] ' + aEqipment.struct.ports[I].name;
        Detail := aEqipment.struct.ports[I].ip;
        Data['arrow_show'] := 1;
        Data['detail_show'] := 1;
        Data['height'] := 0;
        Data['auto_height'] := 1;
        Data['open_abonent'] := 0;
        Data['open_eqipment'] := 0;
        Data['type'] := aEqipment.struct.ports[I].e_type;
        Log.d('type ' + aEqipment.struct.ports[I].port + ' >>> ' + aEqipment.struct.ports[I].e_type.ToString);
        if aEqipment.struct.ports[I].e_type = 0 then
          Data['open_abonent'] := 1
        else
          Data['open_eqipment'] := 1;
        Tag := aEqipment.struct.ports[I].id;
      end;
      FCabinetUpdate := true;
      if aEqipment.struct.ports[I].on_srv = 0 then
        aLV.SetCustomColorForItem(AItem.Index, TmyColors.CustomerOffType);
      aLV.Adapter.ResetView(AItem);
    end;
  end;
end;

end.
