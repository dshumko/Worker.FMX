unit uBidInfo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmBidInfo = class(TBasicLVForm)
    lyButtons: TLayout;
    sbBidDo: TSpeedButton;
    sbBidClose: TSpeedButton;
    sbBidRefuse: TSpeedButton;
    sbBidJoin: TSpeedButton;
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure FormResize(Sender: TObject);
    procedure sbBidDoClick(Sender: TObject);
    procedure sbBidJoinClick(Sender: TObject);
    procedure sbBidCloseClick(Sender: TObject);
    procedure sbBidRefuseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure sbBookmarkClick(Sender: TObject);
  private
    FObjectID: integer;
    FWhose: integer;
    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure RebuildOperationPanel;
    procedure ConfigBidInfo(const aLV: TListView);
    procedure makeBidInfo(const aData: string; const aLV: TListView; out aWhose: integer);
  public
    procedure ShowBidInfo(const aID: integer); overload;
    procedure BookmarkUpdate;
  end;

var
  frmBidInfo: TfrmBidInfo;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI, UListItemElements, modDrawer,
  modAPI, modNative, modJSON, modTypes, uBidComplete, uCustomer, uHouse;

const
  WhoseMy = 1;
  WhoseSomeOne = 0;
  WhoseNoOne = -1;

function calcMargins(const aControl: TSpeedButton): Single;
begin
  Result := 0;
  if aControl.Visible then
    Result := aControl.Margins.Left + aControl.Margins.Right;
end;

procedure setMargings(aControl: TSpeedButton; aLeft, aRight: Single; aAlign: TAlignLayout);
begin
  aControl.Margins.Left := aLeft;
  aControl.Margins.Right := aRight;
  aControl.Align := aAlign;
end;

procedure TfrmBidInfo.FormResize(Sender: TObject);
begin
  inherited;
  RebuildOperationPanel;
  lvContent.SeparatorLeftOffset := lvContent.Width;
end;

procedure TfrmBidInfo.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
  sbBookmark.Visible := true;
  BookmarkUpdate;
end;

(* procedure TfrmBidInfo.ItemHeightByDetail(const AItem: TListViewItem; aLV: TListView);
  // uses FMX.TextLayout, FMX.Graphics, System.Math
  const
  {$IFDEF MSWINDOWS}
  DefaultScrollBarWidth = 16;
  {$ELSE}
  DefaultScrollBarWidth = 7;
  {$ENDIF}
  var
  aScrollWidth: Integer;
  aTextHeight: Integer;
  begin
  if AItem.Text.IsEmpty then
  exit;

  aScrollWidth := DefaultScrollBarWidth;
  if not aLV.ShowScrollBar then
  aScrollWidth := 0;

  TextLayout.BeginUpdate;
  try
  TextLayout.Font.Assign(aLV.ItemAppearanceObjects.ItemObjects.Text.Font);
  TextLayout.Font.Size := TextLayout.Font.Size + 0.2;
  TextLayout.WordWrap := aLV.ItemAppearanceObjects.ItemObjects.Text.WordWrap;
  TextLayout.Trimming := aLV.ItemAppearanceObjects.ItemObjects.Text.Trimming;
  TextLayout.HorizontalAlign := aLV.ItemAppearanceObjects.ItemObjects.Text.TextAlign;
  TextLayout.VerticalAlign := aLV.ItemAppearanceObjects.ItemObjects.Text.TextVertAlign;
  TextLayout.MaxSize := TPointF.Create(aLV.Width - aLV.ItemSpaces.Left - aLV.ItemSpaces.Right - aScrollWidth, 1000);
  TextLayout.Text := AItem.Text;
  finally
  TextLayout.EndUpdate;
  end;

  aTextHeight := Round(TextLayout.Height);
  TextLayout.Text := 'mWp';

  aTextHeight := Round(aTextHeight + TextLayout.Height);

  if not AItem.Detail.IsEmpty then
  begin
  AItem.Objects.TextObject.PlaceOffset.Y := 8;
  AItem.Objects.TextObject.Height := aTextHeight + 13;

  // AItem.Objects.DetailObject.Align := TListItemAlign.Leading;
  AItem.Objects.DetailObject.VertAlign := TListItemAlign.Leading;
  // AItem.Objects.DetailObject.PlaceOffset.Y := AItem.Objects.TextObject.Height - 15;

  TextLayout.BeginUpdate;
  try
  TextLayout.Text := AItem.Detail;
  TextLayout.MaxSize := TPointF.Create(aLV.Width - aLV.ItemSpaces.Left - aLV.ItemSpaces.Right - aScrollWidth, 1000);
  TextLayout.Font.Assign(aLV.ItemAppearanceObjects.ItemObjects.Text.Font);
  TextLayout.Font.Size := TextLayout.Font.Size + 0.2;
  TextLayout.WordWrap := true; // aLV.ItemAppearanceObjects.ItemObjects.Text.WordWrap;
  TextLayout.Trimming := TTextTrimming.None; // aLV.ItemAppearanceObjects.ItemObjects.Text.Trimming;
  TextLayout.HorizontalAlign := TTextAlign.Leading; // aLV.ItemAppearanceObjects.ItemObjects.Text.TextAlign;
  TextLayout.VerticalAlign := TTextAlign.Leading; // aLV.ItemAppearanceObjects.ItemObjects.Text.TextVertAlign;
  finally
  TextLayout.EndUpdate;
  end;
  end;

  AItem.Height := Round(TextLayout.Height + aLV.ItemSpaces.Top + aLV.ItemSpaces.Bottom + aTextHeight);
  end; *)

procedure TfrmBidInfo.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  inherited;
  if AItem.HasData['open_abonent'] then
  begin
    if AItem.Data['open_abonent'].AsInteger > 0 then
      TfrmCustomer.Create(Application).ShowAbonentInfo(AItem.Tag);
  end
  else if AItem.HasData['open_houseinfo'] then
  begin
    if AItem.Data['open_houseinfo'].AsInteger > 0 then
      TfrmHouse.Create(Application).ShowHouseInfo(AItem.Tag);
  end;
end;

procedure TfrmBidInfo.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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
    AItem.Objects.TextObject.TextVertAlign := TTextAlign.Center;
  end;

  if AItem.Data['height'].AsInteger > 0 then
  begin
    AItem.Height := AItem.Data['height'].AsInteger;
    AItem.Objects.TextObject.PlaceOffset.Y := 2;
    AItem.Objects.TextObject.TextVertAlign := TTextAlign.Center;
  end;
end;

procedure TfrmBidInfo.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmBidInfo.RebuildOperationPanel;
var
  divValue: integer;
begin
  lyButtons.Height := 60;
  divValue := 3;
  if FWhose = WhoseNoOne then
  begin
    sbBidDo.Visible := true;
    sbBidClose.Visible := false;
    sbBidRefuse.Visible := false;
    sbBidJoin.Visible := false;
    setMargings(sbBidDo, 8, 8, TAlignLayout.Client);
  end
  else if FWhose = WhoseMy then
  begin
    sbBidDo.Visible := false;
    sbBidRefuse.Visible := true;
    sbBidClose.Visible := true;
    sbBidJoin.Visible := false;
    Dec(divValue, 1);
    setMargings(sbBidClose, 8, 8, TAlignLayout.Left);
    setMargings(sbBidRefuse, 0, 8, TAlignLayout.Client);
    sbBidClose.Width := (lyButtons.Width - (calcMargins(sbBidDo) + calcMargins(sbBidClose) + calcMargins(sbBidRefuse)))
      / divValue;
  end
  else if FWhose = WhoseSomeOne then
  begin
    sbBidDo.Visible := false;
    sbBidRefuse.Visible := false;
    sbBidClose.Visible := false;
    sbBidJoin.Visible := true;
    setMargings(sbBidJoin, 8, 8, TAlignLayout.Client);
  end;

  lyButtons.Visible := (sbBidJoin.Visible or sbBidClose.Visible or sbBidRefuse.Visible or sbBidDo.Visible);
end;

procedure TfrmBidInfo.sbBidCloseClick(Sender: TObject);
begin
  inherited;
  TfrmBidComplete.Create(Application).Show(lvContent.Tag, lvContent.Items[0].Text, lvContent.Items[0].Detail);
  Close;
end;

procedure TfrmBidInfo.sbBidDoClick(Sender: TObject);
var
  aJSON: string;
begin
  inherited;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.TakeBid(lvContent.Tag));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            FWhose := WhoseMy;
            RebuildOperationPanel;
            FNeedUpdateBidList := true; // обновляем список заявок
          end
          else
          begin
            FWhose := WhoseSomeOne;
            RebuildOperationPanel;
            ShowToast(TmyJSON.ErrorMsg(aJSON));
          end
        end)
    end);
end;

procedure TfrmBidInfo.sbBidJoinClick(Sender: TObject);
var
  aJSON: string;
begin
  inherited;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.JoinBid(lvContent.Tag));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            FWhose := WhoseMy;
            RebuildOperationPanel;
            FNeedUpdateBidList := true; // обновляем список заявок
          end
          else
          begin
            FWhose := WhoseSomeOne;
            RebuildOperationPanel;
            ShowToast(TmyJSON.ErrorMsg(aJSON));
          end
        end)
    end);
end;

procedure TfrmBidInfo.sbBidRefuseClick(Sender: TObject);
var
  aJSON: string;
begin
  inherited;
  aJSON := TmyPath.generateBid(lvContent.Tag);
  if FileExists(aJSON) then
    DeleteFile(aJSON);

  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.RefuseBid(lvContent.Tag));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            FWhose := WhoseNoOne;
            RebuildOperationPanel;
            FNeedUpdateBidList := true; // обновляем список заявок
          end
          else
          begin
            FWhose := WhoseSomeOne;
            RebuildOperationPanel;
            ShowToast(TmyJSON.ErrorMsg(aJSON));
            FNeedUpdateBidList := true; // обновляем список заявок
          end;
        end)
    end);
end;

procedure TfrmBidInfo.sbBookmarkClick(Sender: TObject);
begin
  inherited;
  if sbBookmark.Tag = -1 then
    TmyJSON.SaveBookmark(lbTitle.Text, self.ClassName, FObjectID)
  else
    TmyJSON.DeleteBookmark(self.ClassName, FObjectID);
  BookmarkUpdate;
end;

procedure TfrmBidInfo.ShowBidInfo(const aID: integer);
var
  aJSON: string;
begin
  FObjectID := aID;
  lyButtons.Visible := false;
  lbTitle.Text := 'Заявка: ' + IntToStr(aID);
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getBidInfo(aID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            makeBidInfo(aJSON, lvContent, FWhose);
            RebuildOperationPanel;
          end;
          fgWait.Hide;
        end);
    end);
end;

procedure TfrmBidInfo.BookmarkUpdate;
begin
  sbBookmark.Tag := TmyJSON.IsBookmark(self.ClassName, FObjectID);
  if sbBookmark.Tag = -1 then
    sbBookmark.Text := fa_bookmark_o
  else
    sbBookmark.Text := fa_bookmark;
end;

procedure TfrmBidInfo.ConfigBidInfo(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetail';
  aLV.ItemAppearance.ItemHeight := 60;
  aLV.SearchVisible := false;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Image.Visible := false;
    Detail.Visible := false;

    { Text.Align := TListItemAlign.Leading;
      Text.PlaceOffset.Y := 0;
      Text.Trimming := TTextTrimming.None;
      Text.WordWrap := True;
      Text.TextVertAlign := TTextAlign.Center;
      Text.Visible := True;

      Detail.Trimming := TTextTrimming.None;
      Detail.WordWrap := True; }
    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 5;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Leading;

{$IFDEF IOS} Detail.Font.Size := 10.5; {$ENDIF}
    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;

    Detail.Align := TListItemAlign.Trailing;
  end;
end;

procedure TfrmBidInfo.makeBidInfo(const aData: string; const aLV: TListView; out aWhose: integer);
var
  AItem: TListViewItem;
  aBidInfo: TmyTypeBidInfo;
  I: integer;
  aStr: string;
begin
  aLV.ItemsClearTrue;
  ConfigBidInfo(aLV);

  if aData.IsEmpty then
    exit;

  aBidInfo := TJSON.Parse<TmyTypeBidInfo>(aData);

  aWhose := aBidInfo.struct.whose;
  aLV.Tag := aBidInfo.struct.id;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := aBidInfo.struct.plan_str;
    Detail := IntToStr(aBidInfo.struct.id) + ', ' + aBidInfo.struct.type_name;
    Data['detail_show'] := 1;
    Data['arrow_show'] := 0;
    Data['height'] := 0;
    Data['auto_height'] := 0;
  end;
  FCabinetUpdate := true;
  aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
  aLV.Adapter.ResetView(AItem);

  if aBidInfo.struct.customer_id > 0 then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aBidInfo.struct.fio;
      Detail := 'Лицевой ' + aBidInfo.struct.account + ', Баланс = ' + aBidInfo.struct.balance;
      Data['detail_show'] := 1;
      Data['arrow_show'] := 1;
      Data['auto_height'] := 0;
      Data['height'] := 0;
      Data['open_abonent'] := 1;
      Tag := aBidInfo.struct.customer_id;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);

    if Length(aBidInfo.struct.services) > 0 then
    begin
      aStr := '';
      for I := Low(aBidInfo.struct.services) to High(aBidInfo.struct.services) do
      begin
        aStr := aStr + aBidInfo.struct.services[I].name;
        if I < High(aBidInfo.struct.services) then
          aStr := aStr + #13#10;
      end;

      AItem := aLV.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := 'Подключенные услуги';
        Detail := aStr;
        Data['detail_show'] := 1;
        Data['arrow_show'] := 0;
        Data['height'] := 0;
        Data['auto_height'] := 1;
      end;
      FCabinetUpdate := true;
      aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
      aLV.Adapter.ResetView(AItem);
    end;
  end;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := aBidInfo.struct.adress;
    Data['detail_show'] := 0;
    Data['arrow_show'] := 1;
    Data['height'] := aLV.ItemAppearance.ItemHeight;
    Data['open_houseinfo'] := 1;
    Tag := aBidInfo.struct.house_id;
  end;
  FCabinetUpdate := true;
  aLV.Adapter.ResetView(AItem);

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := aBidInfo.struct.Content;
    Data['detail_show'] := 0;
    Data['arrow_show'] := 0;
    Data['auto_height'] := 1;
  end;
  FCabinetUpdate := true;
  aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
  aLV.Adapter.ResetView(AItem);
end;

end.
