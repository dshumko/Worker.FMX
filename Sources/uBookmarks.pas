unit uBookmarks;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, BasicLVForma, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView, FMX.Objects, FMX.Layouts,
  FMX.ZMaterialBackButton, FMX.Controls.Presentation;

type
  TfrmBookmarks = class(TBasicLVForm)
    procedure FormShow(Sender: TObject);
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmBookmarks: TfrmBookmarks;

implementation

uses
  modTypes, modNative, XSuperObject, modJSON, uBidInfo, uCustomer, uAddress, uHouse;

{$R *.fmx}

procedure TfrmBookmarks.FormShow(Sender: TObject);
var
  aRecord: TmyTypeBookmarks;
  aJSON: string;
  I: Integer;
  AItem: TListViewItem;
begin
  inherited;
  lbTitle.Font.Size := 18;

  aJSON := TmyJSON.LoadFromFile(TmyPath.BookmarkFile);
  if TmyJSON.isOK(aJSON) then
  begin
    aRecord := TJSON.Parse<TmyTypeBookmarks>(aJSON);

    for I := Low(aRecord.struct) to High(aRecord.struct) do
    begin
      AItem := lvContent.Items.Add;
      AItem.Text := aRecord.struct[I].name;
      AItem.Data['form'] := aRecord.struct[I].form;
      AItem.Tag := aRecord.struct[I].id;
    end;
  end
  else
    ShowToast('У Вас пока нет закладок!');
end;

procedure TfrmBookmarks.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  s: String;
begin
  inherited;
  s := AItem.Data['form'].AsString;
  if (s = 'TfrmBidInfo') then
    TfrmBidInfo.Create(Application).ShowBidInfo(AItem.Tag)
  else if (s = 'TfrmCustomer') then
    TfrmCustomer.Create(Application).ShowAbonentInfo(AItem.Tag)
  else if (s = 'TagFormTypeHouses') then
    TfrmAddress.Create(Application).ShowHouses(AItem.Tag, AItem.Text)
  else if (s = 'TfrmHouse') then
    TfrmHouse.Create(Application).ShowHouseInfo(AItem.Tag)
end;

end.
