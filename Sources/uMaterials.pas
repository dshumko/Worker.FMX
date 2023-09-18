unit uMaterials;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Edit, FMX.EditBox, FMX.NumberBox,
  FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmMaterials = class(TBasicLVForm)
    lvSelected: TListView;
    rLayInput: TRectangle;
    Rectangle1: TRectangle;
    Layout1: TLayout;
    nbCount: TNumberBox;
    btnOk: TButton;
    lbRest: TLabel;
    rLayOutput: TRectangle;
    Rectangle3: TRectangle;
    Layout2: TLayout;
    nbOut: TNumberBox;
    btnOutput: TButton;
    lblOutput: TLabel;
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure nbCountChange(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure sbBackClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure lvSelectedItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure btnOutputClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure InputLayoutShow;
    procedure InputLayoutHide;
    procedure OutputLayoutShow;
    procedure OutputLayoutHide;
    procedure SaveLocalBidMaterials(const aID: integer; const aIDS, aCounts, aWHIDs: string);
    procedure makeMaterials(const aData, aIDS, aCounts: string; const aLV, aSelLV: TListView);
    procedure ConfigMaterials(const aLV: TListView);
  public
    procedure Show(const aID: integer; const aHeader: string); overload;
  end;

var
  frmMaterials: TfrmMaterials;

implementation

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI,
  UListItemElements, modAPI, modNative, modJSON, modTypes, uBidComplete;

{$R *.fmx}

function frmt(const s: string): string;
begin
  Result := s;
  if not Result.Contains('.') then
    Result := Result + '.0';
end;

procedure TfrmMaterials.btnOutputClick(Sender: TObject);
var
  aValue, aCount: Single;
  I, aIndex: integer;
begin
  inherited;
  aIndex := -1;
  for I := 0 to lvContent.Items.Count - 1 do
  begin
    if lvContent.Items[I].Tag = rLayOutput.Tag then
    begin
      aIndex := I;
      break; // continue?
    end
  end;

  aValue := nbOut.Value;
  I := lvSelected.Selected.Index;

  aCount := lvSelected.Items[I].Detail.ToSingle;
  if aValue = aCount then
    lvSelected.Items.Delete(I)
  else
    lvSelected.Items[I].Detail := frmt((aCount - aValue).ToString);

  aCount := lvContent.Items[aIndex].Detail.ToSingle;
  lvContent.Items[aIndex].Detail := frmt((aCount + aValue).ToString);
  OutputLayoutHide;
end;

procedure TfrmMaterials.ConfigMaterials(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetail';
  aLV.ItemAppearance.ItemHeight := 50;
  aLV.SearchVisible := true;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := true;
    Image.Visible := false;
  end;
end;

procedure TfrmMaterials.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkHardwareBack) or (Key = vkEscape) then
  begin
    if rLayInput.Visible then
    begin
      InputLayoutHide;
      Key := 0;
    end;
    if rLayOutput.Visible then
    begin
      OutputLayoutHide;
      Key := 0;
    end
  end;
  inherited;
end;

procedure TfrmMaterials.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

procedure TfrmMaterials.makeMaterials(const aData, aIDS, aCounts: string; const aLV, aSelLV: TListView);
var
  aMaterials: TmyTypeMaterials;
  I: integer;
  s: string;
  arrIDs: TArray<string>;
  arrCounts: TArray<string>;
  J, aIndex: integer;
  aNewItem: TListViewItem;
  aSavedItem: TListViewItem;
begin
  aLV.ItemsClearTrue;
  ConfigMaterials(aLV);

  if aData.IsEmpty then
    exit;

  arrIDs := aIDS.Split([',']);
  arrCounts := aCounts.Split([',']);

  aMaterials := TJSON.Parse<TmyTypeMaterials>(aData);

  with aLV.Items.Add do
  begin
    Purpose := TListItemPurpose.Header;
    Text := 'ћатериалы в наличии';
  end;

  for I := Low(aMaterials.struct) to High(aMaterials.struct) do
  begin
    aNewItem := aLV.Items.Add;
    aNewItem.Tag := aMaterials.struct[I].id;
    aNewItem.Text := aMaterials.struct[I].name;
    aNewItem.Data['int'] := aMaterials.struct[I].int;
    aNewItem.Data['wh_id'] := aMaterials.struct[I].wh_id;
    s := aMaterials.struct[I].rest;
    aNewItem.Detail := s.Remove(s.IndexOf('.') + 2);

    // добавл€ем сохраненные материалы
    if aIDS.Contains(aNewItem.Tag.ToString) then
    begin
      aIndex := -1;
      for J := Low(arrIDs) to High(arrIDs) do
      begin
        if arrIDs[J].ToInteger = aNewItem.Tag then
        begin
          aIndex := J;
          break;
        end;
      end;

      aSavedItem := aSelLV.Items.Add;
      aSavedItem.Tag := aMaterials.struct[I].id;
      aSavedItem.Text := aMaterials.struct[I].name;
      aSavedItem.Data['int'] := aMaterials.struct[I].int;
      aSavedItem.Data['wh_id'] := aMaterials.struct[I].wh_id;
      s := arrCounts[aIndex];
      if not s.Contains('.') then
        s := s + '.0';
      aSavedItem.Detail := s;

      if aIndex >= 0 then
      begin
        aNewItem.Detail := frmt(FloatToStr(StrToFloat(aMaterials.struct[I].rest) - StrToFloat(arrCounts[aIndex])));
        // обновл€ем значение в списке доступных материалов
      end;
    end;
  end;
end;

procedure TfrmMaterials.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  inherited;
  if (AItem.Detail.ToSingle > 0) then
  begin
    rLayInput.Tag := AItem.Tag;
    lbRest.Text := Format('ƒоступно: %s', [AItem.Detail]);
    nbCount.Max := StrToFloat(AItem.Detail);
    nbCount.Min := 0.00001;
    nbCount.Value := 1;
    InputLayoutShow;
  end;
end;

procedure TfrmMaterials.lvSelectedItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aValue: Single;
begin
  inherited;
  aValue := AItem.Detail.ToSingle;
  rLayOutput.Tag := AItem.Tag;
  lblOutput.Text := Format('¬ за€вке: %s', [AItem.Detail]);
  nbOut.Max := aValue;
  nbOut.Min := 0.00001;
  nbOut.Value := aValue;
  OutputLayoutShow;
end;

procedure TfrmMaterials.nbCountChange(Sender: TObject);
begin
  inherited;
  if nbCount.Value > nbCount.Max then
    nbCount.Value := nbCount.Max;
end;

procedure TfrmMaterials.SaveLocalBidMaterials(const aID: integer; const aIDS, aCounts, aWHIDs: string);
var
  aJSON, aFile: string;
  aBid: TmyTypeLocalBid;
begin
  aFile := TmyPath.generateBid(aID);
  aJSON := TmyJSON.LoadFromFile(aFile, false);
  if TmyJSON.isOK(aJSON) then
    aBid := TJSON.Parse<TmyTypeLocalBid>(aJSON);

  aBid.status := 'OK';
  aBid.id := aID;
  aBid.materials.ids := aIDS;
  aBid.materials.counts := aCounts;
  aBid.materials.whids := aWHIDs;

  TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeLocalBid>(aBid, true), aFile, false);
end;

procedure TfrmMaterials.sbBackClick(Sender: TObject);
var
  aIDS, aWHIDs, aCounts: string;
  I: integer;
begin
  aIDS := '';
  aWHIDs := '';
  aCounts := '';

  for I := 0 to lvSelected.Items.Count - 1 do
  begin
    aIDS := aIDS + ',' + lvSelected.Items[I].Tag.ToString;
    aCounts := aCounts + ',' + lvSelected.Items[I].Detail;
    aWHIDs := aWHIDs + ',' + lvSelected.Items[I].Data['wh_id'].AsInteger.ToString;
  end;

  aIDS := aIDS.Trim([',']);
  aCounts := aCounts.Trim([',']);
  aWHIDs := aWHIDs.Trim([',']);

  SaveLocalBidMaterials(lbTitle.Tag, aIDS, aCounts, aWHIDs);

  inherited;
end;

procedure TfrmMaterials.btnOkClick(Sender: TObject);
var
  aValue, aCount: Single;
  I, aIndex: integer;
begin
  inherited;
  aIndex := -1;
  for I := 0 to lvSelected.Items.Count - 1 do
  begin
    if lvSelected.Items[I].Tag = rLayInput.Tag then
    begin
      aIndex := I;
      break; // continue?
    end
  end;

  aValue := nbCount.Value;
  I := lvContent.Selected.Index;

  if aIndex = -1 then
  begin
    with lvSelected.Items.Add do
    begin
      Text := lvContent.Items[I].Text;
      Detail := frmt(nbCount.Value.ToString);
      Data['wh_id'] := lvContent.Items[I].Data['wh_id'].AsInteger;
      Tag := rLayInput.Tag;
    end;
    aCount := lvContent.Items[I].Detail.ToSingle;
    lvContent.Items[I].Detail := frmt((aCount - aValue).ToString);
  end
  else
  begin
    aCount := lvSelected.Items[aIndex].Detail.ToSingle;
    aCount := aCount + aValue;
    lvSelected.Items[aIndex].Detail := aCount.ToString;
    aCount := lvContent.Items[I].Detail.ToSingle;
    lvContent.Items[I].Detail := frmt((aCount - aValue).ToString);
  end;
  InputLayoutHide;
end;

procedure TfrmMaterials.InputLayoutHide;
begin
  rLayInput.Visible := false;
end;

procedure TfrmMaterials.InputLayoutShow;
begin
  rLayInput.Position.X := 0;
  rLayInput.Position.Y := rHeader.Position.Y + rHeader.Height;
  rLayInput.Width := Content.Width;
  rLayInput.Height := Content.Height;
  rLayInput.Visible := true;
  rLayInput.BringToFront;
end;

procedure TfrmMaterials.OutputLayoutHide;
begin
  rLayOutput.Visible := false;
end;

procedure TfrmMaterials.OutputLayoutShow;
begin
  rLayOutput.Position.X := 0;
  rLayOutput.Position.Y := rHeader.Position.Y + rHeader.Height;
  rLayOutput.Width := Content.Width;
  rLayOutput.Height := Content.Height;
  rLayOutput.Visible := true;
  rLayOutput.BringToFront;
end;

procedure TfrmMaterials.Show(const aID: integer; const aHeader: string);
var
  aJSON: string;
  aIDS, aCounts: string;
begin
  lbTitle.Tag := aID;
  lbTitle.Text := aHeader;
  ConfigMaterials(lvSelected);
  rLayInput.Visible := false;
  rLayOutput.Visible := false;

  TmyJSON.LoadLocalBidMaterials(aID, aIDS, aCounts);

  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getMaterials);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeMaterials(aJSON, aIDS, aCounts, lvContent, lvSelected);

          fgWait.Hide;
        end)
    end);
end;

end.
