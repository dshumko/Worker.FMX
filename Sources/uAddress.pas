unit uAddress;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmAddress = class(TBasicLVForm)
    btnBookMark: TSpeedButton;
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormShow(Sender: TObject);
    procedure sbBookmarkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FCurrentFormType: Integer;
    FObjectID: integer;
    procedure ConfigAddress(const aLV: TListView);
    procedure makeStreet(const aData: string; const aLV: TListView);
    procedure makeHouse(const aData: string; const aLV: TListView);
    procedure BookmarkUpdate;
  public
    procedure ShowStreets;
    procedure ShowHouses(const aID: Integer; const aHeader: string = '');
  end;

var
  frmAddress: TfrmAddress;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, XSuperJSON, XSuperObject, modUI,
  modAPI, modNative, modJSON, modTypes, uHouse;

const
  TagFormTypeStreets = 1;
  TagFormTypeHouses = 2;

procedure TfrmAddress.FormCreate(Sender: TObject);
begin
  inherited;
  FObjectID := -1;
end;

procedure TfrmAddress.FormShow(Sender: TObject);
begin
  inherited;
  if FCurrentFormType = TagFormTypeStreets then
    lbTitle.Font.Size := 18;

  sbBookmark.Visible := (FCurrentFormType <> TagFormTypeStreets);
  BookmarkUpdate;
end;

procedure TfrmAddress.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  aHeader: string;
begin
  inherited;
  aHeader := AItem.Text;

  if FCurrentFormType = TagFormTypeStreets then
    TfrmAddress.Create(Application).ShowHouses(AItem.Tag, aHeader)
  else if FCurrentFormType = TagFormTypeHouses then
    TfrmHouse.Create(Application).ShowHouseInfo(AItem.Tag);
end;

procedure TfrmAddress.ShowStreets;
var
  aJSON: string;
begin
  FCurrentFormType := TagFormTypeStreets;
  lbTitle.Text := 'Улицы';
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getStreets);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeStreet(aJSON, lvContent);

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmAddress.ShowHouses(const aID: Integer; const aHeader: string);
var
  aJSON: string;
begin
  FCurrentFormType := TagFormTypeHouses;
  FObjectID := aID;
  lbTitle.Text := aHeader;
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getHouses(aID));

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeHouse(aJSON, lvContent);

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmAddress.ConfigAddress(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ListItem';
  aLV.ItemAppearance.ItemHeight := 60;
  aLV.SearchVisible := true;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Text.Visible := true;
  end;
end;

procedure TfrmAddress.makeStreet(const aData: string; const aLV: TListView);
var
  aStreet: TmyTypeStreetHouse;
  I: Integer;
begin
  aLV.SearchBoxClear;
  aLV.ItemsClearTrue;
  ConfigAddress(aLV);

  if aData.IsEmpty then
    exit;

  aStreet := TJSON.Parse<TmyTypeStreetHouse>(aData);
  for I := Low(aStreet.struct) to High(aStreet.struct) do
  begin
    with aLV.Items.Add do
    begin
      Text := aStreet.struct[I].name;
      Tag := aStreet.struct[I].id;
    end;
  end;
end;

procedure TfrmAddress.sbBookmarkClick(Sender: TObject);
var
  s : String;
begin
  inherited;
  s := 'TagFormTypeHouses';
  if sbBookmark.Tag = -1 then
    TmyJSON.SaveBookmark(lbTitle.Text, s, FObjectID)
  else
    TmyJSON.DeleteBookmark(s, FObjectID);
  BookmarkUpdate;
end;

procedure TfrmAddress.makeHouse(const aData: string; const aLV: TListView);
var
  aHouses: TmyTypeStreetHouse;
  I: Integer;
begin
  aLV.SearchBoxClear;
  aLV.ItemsClearTrue;
  ConfigAddress(aLV);

  if aData.IsEmpty then
    exit;

  aHouses := TJSON.Parse<TmyTypeStreetHouse>(aData);
  for I := Low(aHouses.struct) to High(aHouses.struct) do
  begin
    with aLV.Items.Add do
    begin
      Text := aHouses.struct[I].name;
      Tag := aHouses.struct[I].id;
    end;
  end;
end;

procedure TfrmAddress.BookmarkUpdate;
var
 s : String;
begin
  s := 'TagFormTypeHouses';
  sbBookmark.Tag := TmyJSON.IsBookmark(s, FObjectID);
  if sbBookmark.Tag = -1 then
    sbBookmark.Text := fa_bookmark_o
  else
    sbBookmark.Text := fa_bookmark;
end;


end.
