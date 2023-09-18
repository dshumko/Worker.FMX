unit uCustomers;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.ZNativeDrawFigure, FMX.ZMaterialActionButton, FMX.Layouts,
  FMX.ZMaterialBackButton;

type
  TfrmCustomers = class(TBasicLVForm)
    btnNewCustomer: TZMaterialActionButton;
    Label1: TLabel;
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure btnNewCustomerClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FHouseID: integer;
    procedure ConfigCustomers(const aLV: TListView);
    procedure makeCustomers(const aData: string; const aLV: TListView);
    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
  public
    procedure ShowCustomers(const aID: integer; const aHeader: string = ''); overload;
  end;

var
  frmCustomers: TfrmCustomers;

implementation

uses
  System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI,
  UListItemElements, modAPI, modNative, modJSON, modTypes,
  System.DateUtils, System.UIConsts, modDrawer, uHouse, uCustomer, uNewAbonent, uMain;

{$R *.fmx}

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

procedure TfrmCustomers.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aHeader: string;
begin
  inherited;
  aHeader := AItem.Text;
  if AItem.Tag <> -1 then
  begin
    TfrmCustomer.Create(Application).ShowAbonentInfo(AItem.Tag);
  end;
end;

procedure TfrmCustomers.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmCustomers.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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

procedure TfrmCustomers.FormCreate(Sender: TObject);
begin
  inherited;
  btnNewCustomer.Visible := frmMain.Rights.AbAdd;
end;

procedure TfrmCustomers.FormResize(Sender: TObject);
begin
  inherited;
  if btnNewCustomer.Visible then
  begin
    btnNewCustomer.Position.X := lvContent.Width - 16 - btnNewCustomer.Width;
    btnNewCustomer.Position.Y := lvContent.Height - 16 - btnNewCustomer.Height + (rHeader.Height);
  end
end;

procedure TfrmCustomers.ShowCustomers(const aID: integer; const aHeader: string = '');
var
  aJSON: string;
begin
  lbTitle.Text := aHeader;
  FHouseID := aID;
  Show;
  FormResize(Self);
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getHouseCustomers(aID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeCustomers(aJSON, lvContent);

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmCustomers.btnNewCustomerClick(Sender: TObject);
begin
  inherited;
  if btnNewCustomer.Visible then
    TfrmNewAbonent.Create(Application).Show(FHouseID, lbTitle.Text);
end;

procedure TfrmCustomers.ConfigCustomers(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'custom';
  aLV.ItemAppearance.ItemHeight := 60;
  aLV.SearchVisible := true;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 8;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := false;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := true;
  end;
end;

procedure TfrmCustomers.makeCustomers(const aData: string; const aLV: TListView);
var
  aCustomers: TmyTypeHouseCustomers;
  aGroupID, I: integer;
  bal: Double;
  aStr: string;
  AItem: TListViewItem;
  iColor : TColor;
begin
  aLV.SearchBoxClear;
  aLV.ItemsClearTrue;
  ConfigCustomers(aLV);

  if aData.IsEmpty then
    exit;

  aCustomers := TJSON.Parse<TmyTypeHouseCustomers>(aData);

  for I := Low(aCustomers.struct) to High(aCustomers.struct) do
  begin
    aStr := '';
    if not aCustomers.struct[I].porch.IsEmpty then
      aStr := 'подъезд ' + aCustomers.struct[I].porch;
    if not aStr.IsEmpty then
      aStr := aStr + ' этаж ' + aCustomers.struct[I].floor;

    aGroupID := FindGroupID(aStr, aLV);
    if aGroupID = -1 then
    begin
      with aLV.Items.Insert(0) do
      begin
        Purpose := TListItemPurpose.Header;
        Text := aStr;
      end;
    end;
  end;

  for I := Low(aCustomers.struct) to High(aCustomers.struct) do
  begin
    aStr := '';
    if not aCustomers.struct[I].porch.IsEmpty then
      aStr := 'подъезд ' + aCustomers.struct[I].porch;
    if not aStr.IsEmpty then
      aStr := aStr + ' этаж ' + aCustomers.struct[I].floor;

    aGroupID := FindGroupID(aStr, aLV);

    AItem := aLV.Items.Insert(aGroupID + 1);
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aCustomers.struct[I].flat + '. ' + aCustomers.struct[I].fio;
      if not aCustomers.struct[I].info.IsEmpty then
        Detail := aCustomers.struct[I].info
      else
        Detail := '';
      // Text := Text + #13#10 + aCustomers.struct[I].info;

      Tag := aCustomers.struct[I].id;
      if Tag <> -1 then
      begin
        Detail := Detail + ' Бал.' + aCustomers.struct[I].balance;
        Data['arrow_show'] := 1;
        Data['detail_show'] := 1;
      end
      else
      begin
        Data['arrow_show'] := 0;
        Data['detail_show'] := 1;
      end;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Data['customer_connected'] := aCustomers.struct[I].connected;
    end;
    FCabinetUpdate := true;
    if (aCustomers.struct[I].id <> -1) and (aCustomers.struct[I].connected = 0) then
    begin
      if (TryStrToFloat(aCustomers.struct[I].balance, bal) and (bal < 0)) then
        aLV.SetCustomColorForItem(AItem.Index, TmyColors.PaymentsOut)
      else
        aLV.SetCustomColorForItem(AItem.Index, TmyColors.CustomerOffType)
    end
    else
    begin
      if not aCustomers.struct[I].Color.IsEmpty then
      begin
        iColor := StringTOCOlor(aCustomers.struct[I].Color);
        aLV.SetCustomColorForItem(AItem.Index, VclToFmxColor(iColor));
      end;
    end;
    aLV.Adapter.ResetView(AItem);
  end;

end;

end.
