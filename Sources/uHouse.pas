unit uHouse;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmHouse = class(TBasicLVForm)
    btnBookMark: TSpeedButton;
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure sbBookmarkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FObjectID: integer;
    procedure makeHouseInfo(const aData: string; const aLV: TListView; out aFullStreet: string);
    procedure ConfigHouseInfo(const aLV: TListView);
    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure BookmarkUpdate;
  public
    procedure ShowHouseInfo(const aID: Integer);
  end;

var
  frmHouse: TfrmHouse;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI, UListItemElements, modDrawer,
  modAPI, modNative, modJSON, modTypes, uCustomers, uEqipment, uBidList;

procedure TfrmHouse.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aHeader: string;
begin
  inherited;
  if AItem.HasData['open_customers'] then
  begin
    if AItem.Data['open_customers'].AsInteger > 0 then
    begin
      aHeader := lbTitle.Text;
      TfrmCustomers.Create(Application).ShowCustomers(AItem.Tag, aHeader);
    end;
  end
  else if AItem.HasData['open_eqipment'] then
  begin
    if AItem.Data['open_eqipment'].AsInteger > 0 then
    begin
      aHeader := AItem.Text;
      TfrmEqipment.Create(Application).ShowEqipmentInfo(AItem.Tag, AItem.Data['type'].AsInteger);
    end;
  end
  else if AItem.HasData['open_bidList'] then
  begin
    if AItem.Data['open_bidList'].AsInteger > 0 then
    begin
      TfrmBidList.Create(Application).ShowBidList(0, AItem.Tag);
    end;
  end;
end;

procedure TfrmHouse.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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

procedure TfrmHouse.FormShow(Sender: TObject);
begin
  inherited;
  sbBookmark.Visible := true;
  BookmarkUpdate;
end;

procedure TfrmHouse.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmHouse.ShowHouseInfo(const aID: Integer);
var
  aJSON, aHeader: string;
begin
  FObjectID := aID;
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getHouseInfo(aID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            makeHouseInfo(aJSON, lvContent, aHeader);
            lbTitle.Text := aHeader;
          end;

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmHouse.ConfigHouseInfo(const aLV: TListView);
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

procedure TfrmHouse.makeHouseInfo(const aData: string; const aLV: TListView; out aFullStreet: string);
var
  aHouseInfo: TmyTypeHouseInfo;
  I: Integer;
  AItem: TListViewItem;
begin
  aLV.SearchBoxClear;
  aLV.ItemsClearTrue;
  ConfigHouseInfo(aLV);

  if aData.IsEmpty then
    exit;

  aHouseInfo := TJSON.Parse<TmyTypeHouseInfo>(aData);

  aFullStreet := aHouseInfo.struct.name;

  if not aHouseInfo.struct.chair.IsEmpty then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aHouseInfo.struct.chair;
      Data['detail_show'] := 0;
      Data['arrow_show'] := 0;
      Data['auto_height'] := 0;
      if not trim(aHouseInfo.struct.chair_phone).IsEmpty then
      begin
        Detail := aHouseInfo.struct.chair_phone;
        Data['detail_show'] := 1;
        Data['arrow_show'] := 1;
        Data['phone'] := aHouseInfo.struct.chair_phone;
      end;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := 'Абоненты';
    Data['detail_show'] := 0;
    Data['arrow_show'] := 1;
    Data['height'] := aLV.ItemAppearance.ItemHeight;
    Data['open_customers'] := 1;
    Tag := aHouseInfo.struct.id;
  end;
  FCabinetUpdate := true;
  aLV.Adapter.ResetView(AItem);

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := 'Заявки';
    Data['detail_show'] := 0;
    Data['arrow_show'] := 0;
    Data['height'] := aLV.ItemAppearance.ItemHeight;
    if aHouseInfo.struct.bid_count > 0 then
    begin
      Data['open_bidList'] := aHouseInfo.struct.bid_count;
      Data['arrow_show'] := 1;
    end;
    Tag := aHouseInfo.struct.id;
  end;
  FCabinetUpdate := true;
  aLV.Adapter.ResetView(AItem);

  AItem := aLV.Items.Add;
  with AItem do
  begin
    Text := 'Оборудование';
    Purpose := TListItemPurpose.Header;
  end;

  for I := Low(aHouseInfo.struct.equipment) to High(aHouseInfo.struct.equipment) do
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aHouseInfo.struct.equipment[I].name;
      Detail := aHouseInfo.struct.equipment[I].notice;
      Tag := aHouseInfo.struct.equipment[I].id;
      Data['type'] := aHouseInfo.struct.equipment[I].e_type;
      Data['detail_show'] := 1;
      Data['arrow_show'] := 1;
      Data['auto_height'] := 0;
      Data['open_eqipment'] := 1;
      Tag := aHouseInfo.struct.equipment[I].id;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  if Length(aHouseInfo.struct.circuit) > 0 then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := 'Схемы';
      Purpose := TListItemPurpose.Header;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);

    for I := Low(aHouseInfo.struct.circuit) to High(aHouseInfo.struct.circuit) do
    begin
      AItem := aLV.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := aHouseInfo.struct.circuit[I].name;
        Detail := aHouseInfo.struct.circuit[I].notice;
        Tag := aHouseInfo.struct.circuit[I].id;
        Data['detail_show'] := 1;
        Data['arrow_show'] := 1;
        Data['auto_height'] := 0;
      end;
      FCabinetUpdate := true;
      aLV.Adapter.ResetView(AItem);
    end;
  end;
end;

procedure TfrmHouse.sbBookmarkClick(Sender: TObject);
var
  s : String;
begin
  inherited;
  s := self.ClassName;
  if sbBookmark.Tag = -1 then
    TmyJSON.SaveBookmark(lbTitle.Text, s, FObjectID)
  else
    TmyJSON.DeleteBookmark(s, FObjectID);
  BookmarkUpdate;
end;

procedure TfrmHouse.BookmarkUpdate;
var
 s : String;
begin
  s := self.ClassName;
  sbBookmark.Tag := TmyJSON.IsBookmark(s, FObjectID);
  if sbBookmark.Tag = -1 then
    sbBookmark.Text := fa_bookmark_o
  else
    sbBookmark.Text := fa_bookmark;
end;

end.
