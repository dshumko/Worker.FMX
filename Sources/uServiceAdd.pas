unit uServiceAdd;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, BasicForma, FMX.TabControl,
  FGX.ProgressDialog, FMX.Layouts, FMX.ZMaterialBackButton, FMX.Controls.Presentation, FMX.Objects, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView, FMX.Calendar,
  modTypes;

type
  TfrmServiceAdd = class(TBasicForm)
    tcTabs: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    lvServices: TListView;
    Calendar1: TCalendar;
    lvPrice: TListView;
    procedure FormCreate(Sender: TObject);
    procedure lvServicesUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvServicesItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure sbBackClick(Sender: TObject);
    procedure Calendar1DateSelected(Sender: TObject);
    procedure lvPriceItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lvPriceApplyStyleLookup(Sender: TObject);
    procedure lvServicesApplyStyleLookup(Sender: TObject);
  private
    FCustomServices: TmyTypeCustomServices;
    FProc: TThreadProcedure;

    procedure DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure ConfigLV(const aLV: TListView);
    procedure makeServices(const aData: string);
    { Private declarations }
  public
    { Public declarations }
    procedure Show(const aCustomerID: integer; const aProc: TThreadProcedure); overload;
  end;

var
  frmServiceAdd: TfrmServiceAdd;

implementation

uses
  System.Threading,FMX.Utils,
  modAPI, modJSON, modDrawer, modNative, XSuperObject, modUI;

{$R *.fmx}

procedure TfrmServiceAdd.FormCreate(Sender: TObject);
begin
  inherited;
  tcTabs.ActiveTab := TabItem1;

  ConfigLV(lvPrice);
end;

procedure TfrmServiceAdd.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
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

procedure TfrmServiceAdd.DrawerGeneral(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
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

procedure TfrmServiceAdd.Calendar1DateSelected(Sender: TObject);
begin
  inherited;
  with TmyStoreData.FService do
  begin
    service_id := lvServices.Items[lvServices.ItemIndex].Tag;
    name := lvServices.Items[lvServices.ItemIndex].Text;
    price := lvServices.Items[lvServices.ItemIndex].Detail;
    onList_id := lvPrice.Items[lvPrice.ItemIndex].Tag;
    onList_name := lvPrice.Items[lvPrice.ItemIndex].Text;
    date := Calendar1.DateTime;
  end;

  if Assigned(FProc) then
    FProc();
  Close;
end;

procedure TfrmServiceAdd.ConfigLV(const aLV: TListView);
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

procedure TfrmServiceAdd.makeServices(const aData: string);
var
  I: integer;
  AItem: TListViewItem;
begin
  lvServices.ItemsClearTrue;
  ConfigLV(lvServices);

  if aData.IsEmpty then
    exit;

  FCustomServices := TJSON.Parse<TmyTypeCustomServices>(aData);

  for I := Low(FCustomServices.struct) to High(FCustomServices.struct) do
  begin
    AItem := lvServices.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := trim(FCustomServices.struct[I].name.Substring(0, FCustomServices.struct[I].name.LastIndexOf('/')));
      Detail := trim(FCustomServices.struct[I].name.Substring(FCustomServices.struct[I].name.LastIndexOf('/') + 1));
      Data['detail_show'] := 1;
      Data['arrow_show'] := 1;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Tag := FCustomServices.struct[I].service_id;
    end;
    FCabinetUpdate := true;
    lvServices.Adapter.ResetView(AItem);
  end;
end;

procedure TfrmServiceAdd.sbBackClick(Sender: TObject);
begin
  case tcTabs.TabIndex of
    0:
      inherited;
    1:
      tcTabs.SetActiveTabWithTransition(TabItem1, TTabTransition.Slide, TTabTransitionDirection.Reversed);
    2:
      tcTabs.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide, TTabTransitionDirection.Reversed);
  end;
end;

procedure TfrmServiceAdd.lvPriceApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvPrice.SetColorHeader($FFFFCC80);
  lvPrice.SetColorTextHeader($FF212121);
  lvPrice.SetColorBackground(TmyColors.Content);
  lvPrice.SetColorItemSelected($FFFFF8E1);
end;

procedure TfrmServiceAdd.lvPriceItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  (Sender as TListView).ShowSelection := not(Sender as TListView).IsCustomColorUsed(AItem.Index);
  (Sender as TListView).EnableTouchAnimation((Sender as TListView).ShowSelection);
  inherited;
  tcTabs.SetActiveTabWithTransition(TabItem3, TTabTransition.Slide, TTabTransitionDirection.Normal);
end;

procedure TfrmServiceAdd.lvServicesApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvServices.SetColorHeader($FFFFCC80);
  lvServices.SetColorTextHeader($FF212121);
  lvServices.SetColorBackground(TmyColors.Content);
  lvServices.SetColorItemSelected($FFFFF8E1);
end;

procedure TfrmServiceAdd.lvServicesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  I: integer;
  BItem: TListViewItem;
  j: integer;
begin
  inherited;
  tcTabs.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide, TTabTransitionDirection.Normal);

  lvPrice.ItemsClearTrue;
  ConfigLV(lvPrice);

  I := AItem.Index;

  if Length(FCustomServices.struct[I].onlist) > 0 then
  begin
    for j := Low(FCustomServices.struct[I].onlist) to High(FCustomServices.struct[I].onlist) do
    begin
      BItem := lvPrice.Items.Add;
      FCabinetUpdate := false;
      with BItem do
      begin
        Text := FCustomServices.struct[I].onlist[j].name;
        Data['detail_show'] := 0;
        Data['arrow_show'] := 1;
        Data['height'] := 0;
        Data['auto_height'] := 1;
        Tag := FCustomServices.struct[I].onlist[j].on_id;
      end;
      FCabinetUpdate := true;
      lvPrice.Adapter.ResetView(BItem);
    end;
  end
  else
  begin
    BItem := lvPrice.Items.Add;
    FCabinetUpdate := false;
    with BItem do
    begin
      Text := 'Дальше...';
      Data['detail_show'] := 0;
      Data['arrow_show'] := 1;
      Data['height'] := 0;
      Data['auto_height'] := 1;
      Tag := -1;
    end;
    FCabinetUpdate := true;
    lvPrice.Adapter.ResetView(BItem);
  end;
end;

procedure TfrmServiceAdd.lvServicesUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
  var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  DrawerGeneral(Sender, AItem, AHandled);
end;

procedure TfrmServiceAdd.Show(const aCustomerID: integer; const aProc: TThreadProcedure);
var
  aJSON: string;
begin
  FProc := aProc;
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getCustomerServices(aCustomerID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeServices(aJSON);
          fgWait.Hide;
        end);
    end);
end;

end.
