unit uCustomer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FGX.ActionSheet.Types, FGX.ActionSheet, FMX.Layouts, FMX.ZMaterialBackButton,
  FMX.ZNativeDrawFigure, FMX.ZMaterialActionButton,
  modTypes;

type
  TfrmCustomer = class(TBasicLVForm)
    fgSheet: TfgActionSheet;
    btnEditCustomer: TZMaterialActionButton;
    SpeedButton1: TSpeedButton;
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure fgSheetItemClick(Sender: TObject; const AAction: TfgActionCollectionItem);
    procedure FormCreate(Sender: TObject);
    procedure lvContentApplyStyleLookup(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnEditCustomerClick(Sender: TObject);
    procedure sbBookmarkClick(Sender: TObject);
  private
    FObjectID: integer;
    FCabinetUpdate: Boolean;
    FCustomerInfo: TmyTypeCustomer;
    procedure makeCustomerInfo(const aData: string; const aLV: TListView; out aAccountID: string);
    procedure ConfigCustomerInfo(const aLV: TListView);
    procedure SetHeadColor(const aColor: TAlphaColor);
    procedure BookmarkUpdate;
  public
    procedure ShowAbonentInfo(const aID: integer);
  end;

var
  frmCustomer: TfrmCustomer;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI, modDrawer,
  modAPI, modNative, modJSON, uCustomers, uEqipment, uNewAbonent, uMain;

function PhonesSplit(const aValue: string): TArray<string>;
var
  aCount: integer;
  aStr: string;
begin
  SetLength(Result, 0);
  aStr := aValue;
  if not aStr.EndsWith(',') then
    aStr := aStr + ',';
  aCount := aStr.CountChar(',');
  Result := aStr.Split([','], aCount);
end;

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

procedure TfrmCustomer.btnEditCustomerClick(Sender: TObject);
begin
  inherited;
  if btnEditCustomer.Visible then
    TfrmNewAbonent.Create(Application).Show(FCustomerInfo);
end;

procedure TfrmCustomer.fgSheetItemClick(Sender: TObject; const AAction: TfgActionCollectionItem);
begin
  inherited;
  Call(AAction.Caption);
end;

procedure TfrmCustomer.FormCreate(Sender: TObject);
begin
  inherited;
  FontAwesomeAssign(sbBack);
  //sbBack.Color := TAlphaColorRec.Black;
  lbTitle.FontColor := TAlphaColorRec.Black;
  btnEditCustomer.Visible := frmMain.Rights.AbEdit;
end;

procedure TfrmCustomer.FormResize(Sender: TObject);
begin
  inherited;
  lvContent.SeparatorLeftOffset := lvContent.Width;
  if btnEditCustomer.Visible then
  begin
    btnEditCustomer.Position.X := lvContent.Width - 16 - btnEditCustomer.Width;
    btnEditCustomer.Position.Y := lvContent.Height - 16 - btnEditCustomer.Height + (rHeader.Height);
  end
end;

procedure TfrmCustomer.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;

  sbBookmark.Visible := true;
  BookmarkUpdate;
end;

procedure TfrmCustomer.lvContentApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvContent.SetColorItemSeparator($FF90A4AE);
end;

procedure TfrmCustomer.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aJSON: string;
  aHeader: string;
  fgItem: TfgActionCollectionItem;
  I: integer;
  aPhones: TArray<string>;
begin
  inherited;
  if AItem.HasData['telCount'] then
  begin
    fgSheet.Actions.Clear;

    aPhones := PhonesSplit(AItem.Detail);
    for I := low(aPhones) to high(aPhones) do
    begin
      fgItem := fgSheet.Actions.Add as TfgActionCollectionItem;
      with fgItem do
        Caption := aPhones[I];
    end;
    fgSheet.Show;
  end
  else if AItem.HasData['open_customers'] then
  begin
    if AItem.Data['open_customers'].AsInteger > 0 then
    begin
      aHeader := AItem.Text;
      TfrmCustomers.Create(Application).ShowCustomers(AItem.Tag, aHeader);
    end;
  end
  else if AItem.HasData['open_eqipment'] then
  begin
    if AItem.Data['open_eqipment'].AsInteger > 0 then
    begin
      aHeader := AItem.Text;
      TfrmEqipment.Create(Application).ShowEqipmentInfo(AItem.Tag, StrToInt(AItem.Data['type'].AsString));
    end;
  end
  else if AItem.HasData['action_test'] then
  begin
    if AItem.Data['action_test'].AsInteger > 0 then
    begin
      ShowToast('Ping');
      TTask.Run(
        procedure
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

procedure TfrmCustomer.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
var AHandled: Boolean);
begin
  inherited;
  if not FCabinetUpdate then
    exit;

  AHandled := (AItem.Purpose = TListItemPurpose.None);

  if not AHandled then
    exit;

  if AItem.Data['detail_show'].AsInteger = 1 then
    AItem.Objects.DetailObject.Visible := true;
  if AItem.Data['arrow_show'].AsInteger = 1 then
    AItem.Objects.AccessoryObject.Visible := true;
  if AItem.Data['auto_height'].AsInteger = 1 then
    TmyLV.ItemHeightByDetail(AItem, (Sender as TListView));
  if AItem.Data['height'].AsInteger > 0 then
  begin
    AItem.Height := AItem.Data['height'].AsInteger;
    AItem.Objects.TextObject.PlaceOffset.Y := 2;
  end;
end;

procedure TfrmCustomer.SetHeadColor(const aColor: TAlphaColor);
begin
  rHeader.Fill.Color := aColor;
  Fill.Color := aColor;

  if aColor = TAlphaColorRec.White then
    sbBookmark.FontColor := $FFFF6600
  else
    sbBookmark.FontColor := TAlphaColorRec.White;
end;

procedure TfrmCustomer.ShowAbonentInfo(const aID: integer);
var
  aJSON: string;
  aHeader: string;
begin
  FObjectID := aID;
  lbTitle.Text := 'Инфо об абоненте';
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getCustomerInfo(aID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            makeCustomerInfo(aJSON, lvContent, aHeader);
            lbTitle.Text := 'Лицевой: ' + aHeader;
          end;

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmCustomer.BookmarkUpdate;
begin
  sbBookmark.Tag := TmyJSON.IsBookmark(self.ClassName, FObjectID);
  if sbBookmark.Tag = -1 then
    sbBookmark.Text := fa_bookmark_o
  else
    sbBookmark.Text := fa_bookmark;
end;

procedure TfrmCustomer.ConfigCustomerInfo(const aLV: TListView);
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

procedure TfrmCustomer.makeCustomerInfo(const aData: string; const aLV: TListView; out aAccountID: string);
var
  I, J: integer;
  AItem: TListViewItem;
  aStr: string;
  aGroupID: integer;
  bal: Double;
begin
  SetHeadColor(TAlphaColorRec.White);

  aLV.ItemsClearTrue;
  ConfigCustomerInfo(aLV);

  if aData.IsEmpty then
    exit;
  // ShowToast(aData);

  FCustomerInfo := TJSON.Parse<TmyTypeCustomer>(aData);
  I := 0;
  if (FCustomerInfo.struct[I].id <> -1) and (Length(FCustomerInfo.struct[I].services) = 0) then
  begin
    if (TryStrToFloat(FCustomerInfo.struct[I].balance, bal) and (bal < 0)) then
      SetHeadColor(TmyColors.PaymentsOut)
    else
      SetHeadColor(TmyColors.CustomerOffType);
  end;

  I := 0;
  aLV.Tag := FCustomerInfo.struct[I].id;

  aAccountID := FCustomerInfo.struct[I].account;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := trim(string.Join(' ', [FCustomerInfo.struct[I].firstname, FCustomerInfo.struct[I].midlename,
      FCustomerInfo.struct[I].surname]));
    Data['arrow_show'] := 0;
    Data['detail_show'] := 0;
    Data['height'] := aLV.ItemAppearance.ItemHeight; // 50;
  end;
  FCabinetUpdate := true;
  aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
  aLV.Adapter.ResetView(AItem);

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := 'Баланс';
    Detail := FCustomerInfo.struct[I].balance;
    Data['arrow_show'] := 0;
    Data['detail_show'] := 1;
    Data['height'] := 0;
  end;
  FCabinetUpdate := true;
  aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
  aLV.Adapter.ResetView(AItem);

  if not FCustomerInfo.struct[I].phones.IsEmpty then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := 'Позвонить';
      Detail := FCustomerInfo.struct[I].phones;
      Data['arrow_show'] := 0;
      Data['detail_show'] := 1;
      Data['height'] := 0;
      Data['telCount'] := Detail.CountChar(',') + 1;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  if not FCustomerInfo.struct[I].notice.IsEmpty then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := FCustomerInfo.struct[I].notice;
      // Detail := FCustomerInfo.struct[I].notice;
      Data['arrow_show'] := 0;
      Data['detail_show'] := 0;
      Data['height'] := 0;
      // Data['telCount'] := Detail.CountChar(',') + 1;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);
  end;

  AItem := aLV.Items.Add;
  FCabinetUpdate := false;
  with AItem do
  begin
    Text := string.Join(', ', [FCustomerInfo.struct[I].street, FCustomerInfo.struct[I].house,
      FCustomerInfo.struct[I].flat]);
    Data['arrow_show'] := 1;
    Data['detail_show'] := 0;
    Data['height'] := aLV.ItemAppearance.ItemHeight; // 50; // 35;
    Data['open_customers'] := 1;
    Tag := FCustomerInfo.struct[I].house_id;
  end;
  FCabinetUpdate := true;
  aLV.Adapter.ResetView(AItem);

  if Length(FCustomerInfo.struct[I].services) > 0 then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := 'Услуги';
      Purpose := TListItemPurpose.Header;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);

    for J := Low(FCustomerInfo.struct[I].services) to High(FCustomerInfo.struct[I].services) do
    begin
      AItem := aLV.Items.Add;
      FCabinetUpdate := false;
      with AItem do
      begin
        Text := FCustomerInfo.struct[I].services[J].name;
        Detail := FCustomerInfo.struct[I].services[J].tarif;
        Data['arrow_show'] := 0;
        Data['detail_show'] := 1;
        Data['height'] := 0;
        Tag := FCustomerInfo.struct[I].services[J].service_id;
      end;
      FCabinetUpdate := true;
      aLV.SetCustomColorForItem(AItem.Index, TmyColors.Content);
      aLV.Adapter.ResetView(AItem);
    end;
  end;

  if Length(FCustomerInfo.struct[I].equipment) > 0 then
  begin
    AItem := aLV.Items.Add;
    FCabinetUpdate := false;
    with AItem do
    begin
      Text := 'Оборудование';
      Purpose := TListItemPurpose.Header;
    end;
    FCabinetUpdate := true;
    aLV.Adapter.ResetView(AItem);

    for J := Low(FCustomerInfo.struct[I].equipment) to High(FCustomerInfo.struct[I].equipment) do
    begin
      if FCustomerInfo.struct[I].equipment[J].parent_id > 0 then
      begin
        aStr := FCustomerInfo.struct[I].equipment[J].parent_name;
        aGroupID := FindGroupID(aStr, aLV, true);
        if aGroupID = -1 then
        begin
          { with aLV.Items.Add do
            begin
            Purpose := TListItemPurpose.Header;
            Text := 'Подключен к:';
            end; }

          AItem := aLV.Items.Add;
          FCabinetUpdate := false;
          with AItem do
          begin
            Text := 'Подключен к:';
            Detail := aStr;
            Data['arrow_show'] := 1;
            Data['detail_show'] := 1;
            Data['height'] := 0;
            Data['open_eqipment'] := 1;
            Data['type'] := FCustomerInfo.struct[I].equipment[J].e_type;
            Tag := FCustomerInfo.struct[I].equipment[J].parent_id;
          end;
          FCabinetUpdate := true;
          aLV.Adapter.ResetView(AItem);
        end;
      end;
    end;

    for J := Low(FCustomerInfo.struct[I].equipment) to High(FCustomerInfo.struct[I].equipment) do
    begin
      if FCustomerInfo.struct[I].equipment[J].parent_id > 0 then
      begin
        aStr := FCustomerInfo.struct[I].equipment[J].parent_name;
        aGroupID := FindGroupID(aStr, aLV, true);
      end
      else
        aGroupID := aLV.Items.Count - 1;

      AItem := aLV.Items.Insert(aGroupID + 1);
      FCabinetUpdate := false;
      with AItem do
      begin
        if FCustomerInfo.struct[I].equipment[J].port <> '' then
          Text := '[ ' + FCustomerInfo.struct[I].equipment[J].port + ' ] ';

        Text := Text + FCustomerInfo.struct[I].equipment[J].name;
        Detail := FCustomerInfo.struct[I].equipment[J].mac;
        Data['arrow_show'] := 0;
        Data['detail_show'] := 1;
        Data['height'] := 0;
        Data['action_test'] := 1;
        Data['type'] := FCustomerInfo.struct[I].equipment[J].e_type;
        Tag := FCustomerInfo.struct[I].equipment[J].id;
      end;
      FCabinetUpdate := true;
      aLV.Adapter.ResetView(AItem);
    end;
  end;
end;

procedure TfrmCustomer.sbBookmarkClick(Sender: TObject);
begin
  inherited;
  if sbBookmark.Tag = -1 then
    TmyJSON.SaveBookmark(lbTitle.Text, self.ClassName, FObjectID)
  else
    TmyJSON.DeleteBookmark(self.ClassName, FObjectID);
  BookmarkUpdate;
end;

end.
