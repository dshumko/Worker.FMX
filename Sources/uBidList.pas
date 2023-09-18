unit uBidList;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type

  TfrmBidList = class(TBasicLVForm)
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FStreetID: integer;
    FHouseID: integer;
    FCabinetUpdate: Boolean;
    procedure ReLoadList;
    procedure makeBidList(const aData: string; const aLV: TListView);
    procedure ConfigBidList(const aLV: TListView);
    procedure DrawerBid(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
  public
    procedure ShowBidList(const aStreetID, aHouseID: integer);

  end;

var
  frmBidList: TfrmBidList;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI,
  UListItemElements, modAPI, modNative, modJSON, modTypes,
  System.DateUtils, System.UIConsts,
  uBidInfo, System.Math;

procedure TfrmBidList.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  inherited;
  TfrmBidInfo.Create(Application).ShowBidInfo(AItem.Tag);
end;

procedure TfrmBidList.DrawerBid(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
var
  aDate: TListItemText;
  aNumber: TListItemText;
  aBidSign: TListItemRect;
  aHeight: Single;
begin
  if not FCabinetUpdate then
    exit;

  aHeight := 0;

  aBidSign := AItem.Objects.FindObjectT<TListItemRect>('bidType');
  if aBidSign = nil then
    aBidSign := TListItemRect.Create(AItem);
  aBidSign.Name := 'bidType';
  aBidSign.Width := 10;
  aBidSign.PlaceOffset.X := (Sender as TListView).Width - aBidSign.Width - 10 {$IFDEF MSWINDOWS} - 16 {$ENDIF};
  aBidSign.PlaceOffset.Y := 0;
  aBidSign.Color := AItem.Data['bidSign_color'].AsInteger;
  aBidSign.Height := (Sender as TListView).ItemAppearance.ItemHeight; // - (aBidSign.PlaceOffset.Y * 2);
  aBidSign.Visible := true;

  aNumber := AItem.Objects.FindObjectT<TListItemText>('number');
  if aNumber = nil then
    aNumber := TListItemText.Create(AItem);
  aNumber.Name := 'number';
  aNumber.Font.Size := 11;
  aNumber.PlaceOffset.X := 0;
  aNumber.PlaceOffset.Y := 4;
  aNumber.Width := (aBidSign.PlaceOffset.X) / 2;
  aNumber.Height := 18;
  aNumber.Text := AItem.Data['number'].AsString;

  aDate := AItem.Objects.FindObjectT<TListItemText>('date');
  if aDate = nil then
    aDate := TListItemText.Create(AItem);
  aDate.Name := 'date';
  aDate.Font.Size := 11;
  aDate.TextAlign := TTextAlign.Trailing;
  aDate.PlaceOffset.X := aNumber.Width + aNumber.PlaceOffset.X - 4;
  aDate.PlaceOffset.Y := aNumber.PlaceOffset.Y;
  aDate.Width := aNumber.Width;
  aDate.Height := aNumber.Height;
  aDate.Text := AItem.Data['date'].AsString;

  aHeight := aHeight + aDate.PlaceOffset.Y + aDate.Height;

  with AItem.Objects.TextObject do
  begin
    WordWrap := true;
    Trimming := TTextTrimming.None;
    Font.Size := 13;
    Font.Style := Font.Style + [TfontStyle.fsBold];
    TextAlign := TTextAlign.Leading;
    PlaceOffset.X := aNumber.PlaceOffset.X;
    PlaceOffset.Y := aNumber.Height + aNumber.PlaceOffset.Y;
    Width := ((Sender as TListView).Width - (aBidSign.Width + 4));
    // Height := 32;
    Height := lvContent.getItemTextHeight(AItem.Objects.TextObject, AItem.Objects.TextObject.Width);
  end;

  aHeight := aHeight + AItem.Objects.TextObject.Height;

  with AItem.Objects.DetailObject do
  begin
{$IFDEF IOS} Font.Size := 10.5; {$ENDIF}
    WordWrap := true;
    Trimming := TTextTrimming.None;
    TextAlign := TTextAlign.Leading;
    TextVertAlign := TTextAlign.Leading;
    PlaceOffset.X := AItem.Objects.TextObject.PlaceOffset.X;
    PlaceOffset.Y := AItem.Objects.TextObject.PlaceOffset.Y + AItem.Objects.TextObject.Height;
    Width := AItem.Objects.TextObject.Width;
    Height := lvContent.getItemTextHeight(AItem.Objects.DetailObject, Width) + AItem.Objects.TextObject.Height;
    // Height := (Sender as TListView).ItemAppearance.ItemHeight -
    // (aNumber.Height + aNumber.PlaceOffset.Y + PlaceOffset.Y) + 20;
  end;

  aHeight := (Sender as TListView).ItemSpaces.Top + (Sender as TListView).ItemSpaces.Bottom +
    Max(aHeight + AItem.Objects.DetailObject.Height, (Sender as TListView).ItemAppearance.ItemHeight);

  aBidSign.Height := aHeight;
  AItem.Height := Round(aBidSign.Height);

  AHandled := true;
end;

procedure TfrmBidList.FormActivate(Sender: TObject);
begin
  inherited;

  if FNeedUpdateBidList then
    ReLoadList;
end;

procedure TfrmBidList.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

procedure TfrmBidList.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerBid(Sender, AItem, AHandled);
end;

procedure TfrmBidList.ShowBidList(const aStreetID, aHouseID: integer);
begin
  lbTitle.Text := 'Заявки';
  FStreetID := aStreetID;
  FHouseID := aHouseID;
  Show;
  ReLoadList;
end;

procedure TfrmBidList.ReLoadList;
var
  aJSON: string;
begin
  { TODO: FNeedUpdateBidList - удалить }
  FNeedUpdateBidList := false; // отключить чтобы на activate не срабатывало каждый раз
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getBidList(FStreetID, FHouseID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeBidList(aJSON, lvContent);

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmBidList.ConfigBidList(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'Custom';
  aLV.ItemAppearance.ItemHeight := 100;
  aLV.SearchVisible := true;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    GlyphButton.Visible := false;
    TextButton.Visible := false;
    Accessory.Visible := false;
    Image.Visible := false;
    Detail.Visible := true;
    Text.Visible := true;
  end;
end;

procedure TfrmBidList.makeBidList(const aData: string; const aLV: TListView);
var
  aBidList: TmyTypeBidList;
  AItem: TListViewItem;
  I: integer;
  iColor : TColor;
begin
  aLV.ItemsClearTrue;
  ConfigBidList(aLV);

  if aData.IsEmpty then
    exit;

  aBidList := TJSON.Parse<TmyTypeBidList>(aData);

  for I := Low(aBidList.struct) to High(aBidList.struct) do
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aBidList.struct[I].adress;
      Detail := aBidList.struct[I].content;
      Data['number'] := IntToStr(aBidList.struct[I].id) + ' ' + aBidList.struct[I].type_name;
      Data['date'] := aBidList.struct[I].plan_str;
      Data['bidSign'] := aBidList.struct[I].whose;
      Data['bidSign_color'] := TmyColors.bidSignNobody;
      if aBidList.struct[I].whose = 0 then
        Data['bidSign_color'] := TmyColors.bidSignAlien
      else if aBidList.struct[I].whose = 1 then
      begin
        Data['bidSign_color'] := TmyColors.bidSignOwn;
        if UnixToDateTime(aBidList.struct[I].plan_date, false) < now() then
          Data['bidSign_color'] := TmyColors.bidSignOwnLate;
      end;
      Tag := aBidList.struct[I].id;
    end;

    FCabinetUpdate := true;
    if not aBidList.struct[I].Color.IsEmpty then
    begin
      iColor := StringTOCOlor(aBidList.struct[I].Color);
      aLV.SetCustomColorForItem(AItem.Index, VclToFmxColor(iColor));
    end;
    aLV.Adapter.ResetView(AItem);
  end;
end;

end.
