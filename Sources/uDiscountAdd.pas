unit uDiscountAdd;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, BasicForma, FGX.ProgressDialog,
  FMX.Layouts, FMX.ZMaterialBackButton, FMX.Controls.Presentation, FMX.Objects, FMX.TabControl, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView, FMX.DateTimeCtrls, FMX.ZMaterialEdit,
  FMX.ScrollBox, FMX.Memo;

type
  TfrmDiscountAdd = class(TBasicForm)
    tcTabs: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    lvDiscounts: TListView;
    deFrom: TDateEdit;
    deTo: TDateEdit;
    Label2: TLabel;
    edSum: TZMaterialEdit;
    Label3: TLabel;
    mNotice: TMemo;
    sbSelect: TSpeedButton;
    SpeedButton1: TSpeedButton;
    btnSend: TButton;
    pScroll: TPresentedScrollBox;
    lbl1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lvDiscountsUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure sbSelectClick(Sender: TObject);
    procedure lvDiscountsItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure sbBackClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lvDiscountsApplyStyleLookup(Sender: TObject);
  private
    FProc: TThreadProcedure;
    { Private declarations }

    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);

    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure ConfigLV(const aLV: TListView);
    procedure makeDiscount(const aData: string);
  public
    { Public declarations }
    procedure Show(const aCustomerID: integer; const aProc: TThreadProcedure); overload;
  end;

var
  frmDiscountAdd: TfrmDiscountAdd;

implementation

uses
  XSuperObject, modDrawer, System.Threading, modAPI, modJSON, modTypes,
  FMX.StatusBar, modUI, System.Math, modNative, FMX.Utils, System.DateUtils;

{$R *.fmx}

procedure TfrmDiscountAdd.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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

procedure TfrmDiscountAdd.btnSendClick(Sender: TObject);
begin
  inherited;
  if edSum.Text.Trim.IsEmpty then
  begin
    ShowToast('Коэффициент не указан');
    exit;
  end;

  if lvDiscounts.ItemIndex = -1 then
  begin
    ShowToast('На что скидка?');
    exit;
  end;

  with TmyStoreData.FDiscount do
  begin
    discount_id := lvDiscounts.Items[lvDiscounts.ItemIndex].Tag;
    name := lvDiscounts.Items[lvDiscounts.ItemIndex].Text;
    from_date := deFrom.DateTime;
    to_date := deTo.DateTime;
    sum := edSum.Text.ToSingle;
    notice := mNotice.Text;
  end;

  if Assigned(FProc) then
    FProc();
  Close;
end;

procedure TfrmDiscountAdd.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
  end;
end;

procedure TfrmDiscountAdd.ConfigLV(const aLV: TListView);
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
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := true;

{$IFDEF IOS} Detail.Font.Size := 10.5; {$ENDIF}
    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;
  end;
end;

procedure TfrmDiscountAdd.FormCreate(Sender: TObject);
begin
  inherited;
  pScroll.OnCalcContentBounds := CalcContentBoundsProc;
  FKeyboardShowed := false;
  tcTabs.ActiveTab := TabItem1;

  ConfigLV(lvDiscounts);
end;

procedure TfrmDiscountAdd.FormFocusChanged(Sender: TObject);
begin
  inherited;
  if pScroll.Visible then
    UpdateKBBounds;
end;

procedure TfrmDiscountAdd.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
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

procedure TfrmDiscountAdd.FormResize(Sender: TObject);
begin
  inherited;
  btnSend.Margins.Left := ClientWidth / 3;
  btnSend.Margins.Right := ClientWidth / 3;
end;

procedure TfrmDiscountAdd.FormShow(Sender: TObject);
var
  AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word;
begin
  inherited;
  lbTitle.Font.Size := 18;
  DecodeDateTime(Now(), AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond);
  deFrom.Date := EncodeDate(AYear, AMonth, 1);
  deTo.Date := EncodeDate(AYear, AMonth, DaysInAMonth(AYear, AMonth));
end;

procedure TfrmDiscountAdd.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := false;
  RestorePosition;
end;

procedure TfrmDiscountAdd.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKeyboardShowed := KeyboardVisible;
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmDiscountAdd.lvDiscountsApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvDiscounts.SetColorHeader($FFFFCC80);
  lvDiscounts.SetColorTextHeader($FF212121);
  lvDiscounts.SetColorBackground(TmyColors.Content);
  lvDiscounts.SetColorItemSelected($FFFFF8E1);
end;

procedure TfrmDiscountAdd.lvDiscountsItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  (Sender as TListView).ShowSelection := not(Sender as TListView).IsCustomColorUsed(AItem.Index);
  (Sender as TListView).EnableTouchAnimation((Sender as TListView).ShowSelection);
  inherited;
  sbSelect.Text := AItem.Text;
  sbBackClick(nil);
end;

procedure TfrmDiscountAdd.lvDiscountsUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmDiscountAdd.makeDiscount(const aData: string);
var
  I: integer;
  AItem: TListViewItem;
  aDiscount: TmyTypeDiscount;
begin
  lvDiscounts.ItemsClearTrue;
  ConfigLV(lvDiscounts);

  if aData.IsEmpty then
    exit;

  aDiscount := TJSON.Parse<TmyTypeDiscount>(aData);

  for I := Low(aDiscount.struct) to High(aDiscount.struct) do
  begin
    AItem := lvDiscounts.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := aDiscount.struct[I].name;
      Data['detail_show'] := 0;
      Data['arrow_show'] := 1;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Tag := aDiscount.struct[I].id;
    end;
    FCabinetUpdate := true;
    lvDiscounts.Adapter.ResetView(AItem);
  end;

end;

procedure TfrmDiscountAdd.RestorePosition;
begin
  pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, 0);
  pScroll.RealignContent;
end;

procedure TfrmDiscountAdd.sbBackClick(Sender: TObject);
begin
  case tcTabs.TabIndex of
    0:
      inherited;
    1:
      tcTabs.SetActiveTabWithTransition(TabItem1, TTabTransition.Slide, TTabTransitionDirection.Reversed);
  end;
end;

procedure TfrmDiscountAdd.sbSelectClick(Sender: TObject);
begin
  inherited;
  tcTabs.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide, TTabTransitionDirection.Normal);
end;

procedure TfrmDiscountAdd.Show(const aCustomerID: integer; const aProc: TThreadProcedure);
var
  aJSON: string;
begin
  FProc := aProc;
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getDiscountList(aCustomerID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeDiscount(aJSON);
          fgWait.Hide;
        end);
    end);
end;

procedure TfrmDiscountAdd.UpdateKBBounds;
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
