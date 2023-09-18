unit uContacts;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmContacts = class(TBasicLVForm)
    procedure lvContentApplyStyleLookup(Sender: TObject);
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormShow(Sender: TObject);
  private
    procedure ConfigListView(const aLV: TListView);
    procedure makeContacts(const aData: string; const aLV: TListView);
  public
    { Public declarations }
    procedure ShowContacts;
  end;

var
  frmContacts: TfrmContacts;

implementation

{$R *.fmx}

uses System.Threading, FMX.FontAwesome, XSuperJSON, XSuperObject, modUI,
  modAPI, modNative, modJSON, modTypes;

procedure TfrmContacts.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

procedure TfrmContacts.lvContentApplyStyleLookup(Sender: TObject);
begin
  inherited;
  lvContent.SetColorHeader(TAlphaColorRec.Lightgrey);
  lvContent.SetColorTextHeader(TAlphaColorRec.Black);
end;

procedure TfrmContacts.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  inherited;
  if AItem.HasData['phone'] then
    Call(AItem.Data['phone'].AsString);
end;

procedure TfrmContacts.ShowContacts;
var
  aJSON: string;
begin
  lbTitle.Text := 'Телефоны';
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.contactsList);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
            makeContacts(aJSON, lvContent);

          fgWait.Hide;
        end);
    end);
end;

procedure TfrmContacts.ConfigListView(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'Custom';
  aLV.ItemAppearance.ItemHeight := 60;
  aLV.ShowSelection := false;
  aLV.SeparatorLeftOffset := aLV.Width;
  aLV.ShowScrollBar := false;

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Image.Visible := false;
    Accessory.Visible := false;
    TextButton.Visible := false;
    GlyphButton.Visible := false;

    Text.Visible := true;
    Text.PlaceOffset.X := 40;

    Detail.Visible := true;
    Detail.Width := 30;
    Detail.PlaceOffset.X := 0;
    Detail.TextAlign := TTextAlign.Center;
    Detail.TextColor := TmyColors.ContactCall;
    Detail.Font.Size := 24;
    Detail.Font.Family := FontAwesomeName;
  end;
end;

procedure TfrmContacts.makeContacts(const aData: string; const aLV: TListView);
var
  I: integer;
  aContactsList: TmyTypeContactsList;
begin
  aLV.ItemsClearTrue;
  ConfigListView(aLV);

  if aData.IsEmpty then
    exit;

  aContactsList := TJSON.Parse<TmyTypeContactsList>(aData);

  for I := Low(aContactsList.struct) to High(aContactsList.struct) do
  begin
    with aLV.Items.Add do
    begin
      Text := aContactsList.struct[I].name;
      Data['phone'] := aContactsList.struct[I].phone;
      Detail := fa_phone;
    end;
  end;
end;

end.
