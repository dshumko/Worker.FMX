unit uBidPhoto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, System.Actions, FMX.ActnList,
  FMX.StdActns, FMX.MediaLibrary.Actions, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmBidPhoto = class(TBasicLVForm)
    lyButtons: TLayout;
    btnBidSave: TButton;
    lytPhoto1: TLayout;
    imgPhoto1: TImage;
    lyt3: TLayout;
    btnPhoto1: TSpeedButton;
    lyt5: TLayout;
    btnDel1: TSpeedButton;
    lytPhoto2: TLayout;
    imgPhoto2: TImage;
    ly2: TLayout;
    btnPhoto2: TSpeedButton;
    lyt4: TLayout;
    btnDel2: TSpeedButton;
    actlst: TActionList;
    actPhoto1: TTakePhotoFromCameraAction;
    actPhoto2: TTakePhotoFromCameraAction;
    procedure btnDelClick(Sender: TObject);
    procedure btnPhoto1Click(Sender: TObject);
    procedure btnPhoto2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure actPhoto1DidFinishTaking(Image: TBitmap);
    procedure actPhoto2DidFinishTaking(Image: TBitmap);
    procedure btnBidSaveClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FID: integer;
    procedure DeleteLocalBidPhoto(const aID, aIndex: integer);
  public
    procedure Show(const aID: integer); overload;
  end;

var
  frmBidPhoto: TfrmBidPhoto;

implementation

uses System.Threading, FMX.FontAwesome, FMX.Utils, XSuperJSON, XSuperObject, modUI,
  UListItemElements, modAPI, modNative, modJSON, modTypes;

{$R *.fmx}

procedure TfrmBidPhoto.DeleteLocalBidPhoto(const aID, aIndex: integer);
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
  if Length(aBid.photos) > aIndex then
  begin
    aBid.photos[aIndex].Data := '';
    TmyJSON.SaveToFile(TJSON.Stringify<TmyTypeLocalBid>(aBid, true), aFile, false);
  end;
end;

procedure TfrmBidPhoto.actPhoto1DidFinishTaking(Image: TBitmap);
begin
  inherited;
  imgPhoto1.Bitmap.Assign(Image);
end;

procedure TfrmBidPhoto.actPhoto2DidFinishTaking(Image: TBitmap);
begin
  inherited;
  imgPhoto2.Bitmap.Assign(Image);
end;

procedure TfrmBidPhoto.btnBidSaveClick(Sender: TObject);
begin
  inherited;
  if not imgPhoto1.Bitmap.IsEmpty then
    TmyJSON.SaveLocalBidPhoto(FID, 0, imgPhoto1.Bitmap);
  if not imgPhoto2.Bitmap.IsEmpty then
    TmyJSON.SaveLocalBidPhoto(FID, 1, imgPhoto2.Bitmap);
  sbBackClick(nil);
end;

procedure TfrmBidPhoto.btnDelClick(Sender: TObject);
begin
  inherited;
  DeleteLocalBidPhoto(FID, (Sender as TSpeedButton).Tag);

  if (Sender as TSpeedButton).Tag = 0 then
    imgPhoto1.Bitmap.Assign(nil)
  else
    imgPhoto2.Bitmap.Assign(nil);
end;

procedure TfrmBidPhoto.btnPhoto1Click(Sender: TObject);
begin
  inherited;
  actPhoto1.ExecuteTarget(Sender);
end;

procedure TfrmBidPhoto.btnPhoto2Click(Sender: TObject);
begin
  inherited;
  actPhoto2.ExecuteTarget(Sender);
end;

procedure TfrmBidPhoto.FormCreate(Sender: TObject);
begin
  inherited;
  FontAwesomeAssign(btnPhoto1);
  btnPhoto1.Font.Size := 18;
  btnPhoto1.Text := fa_camera;
  btnPhoto1.FontColor := TAlphaColorRec.White;

  FontAwesomeAssign(btnPhoto2);
  btnPhoto2.Font.Size := 18;
  btnPhoto2.Text := fa_camera;
  btnPhoto2.FontColor := TAlphaColorRec.White;

  FontAwesomeAssign(btnDel1);
  btnDel1.Font.Size := 18;
  btnDel1.Text := fa_trash;
  btnDel1.FontColor := TmyColors.PaymentsOut;

  FontAwesomeAssign(btnDel2);
  btnDel2.Font.Size := 18;
  btnDel2.Text := fa_trash;
  btnDel2.FontColor := TmyColors.PaymentsOut;
end;

procedure TfrmBidPhoto.FormResize(Sender: TObject);
begin
  inherited;
  lytPhoto1.Height := Round((Content.Height - lyButtons.Height - rHeader.Height) / 2);
  btnBidSave.Margins.Left := ClientWidth / 3;
  btnBidSave.Margins.Right := ClientWidth / 3;
end;

procedure TfrmBidPhoto.FormShow(Sender: TObject);
begin
  inherited;
  Content.Fill.Color := TAlphaColorRec.Black;
  rHeader.Fill.Color := TAlphaColorRec.Black;
  lbTitle.Font.Size := 18;
end;

procedure TfrmBidPhoto.Show(const aID: integer);
var
  aBitmap: TBitmap;
begin
  FID := aID;
  aBitmap := TBitmap.Create;
  TmyJSON.LoadLocalBidPhoto(aID, 0, aBitmap);
  if not aBitmap.IsEmpty then
  begin
    imgPhoto1.Bitmap.SetSize(aBitmap.Width, aBitmap.Height);
    imgPhoto1.Bitmap.CopyFromBitmap(aBitmap);
  end;
  FreeAndNil(aBitmap);

  aBitmap := TBitmap.Create;
  TmyJSON.LoadLocalBidPhoto(aID, 1, aBitmap);
  if not aBitmap.IsEmpty then
  begin
    imgPhoto2.Bitmap.SetSize(aBitmap.Width, aBitmap.Height);
    imgPhoto2.Bitmap.CopyFromBitmap(aBitmap);
  end;
  FreeAndNil(aBitmap);
  Show;
end;

end.
