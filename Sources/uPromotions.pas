unit uPromotions;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicLVForma, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FGX.ProgressDialog, FMX.ListView,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmPromotions = class(TBasicLVForm)
    procedure lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormShow(Sender: TObject);
  private
    procedure makePromotions(const aData: string; const aLV: TListView);
    procedure ConfigPromotions(const aLV: TListView);
    procedure Drawer(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
  public
    procedure ShowPromotions;
  end;

implementation

uses System.Threading, FMX.Utils, FMX.FontAwesome, XSuperJSON, XSuperObject, modUI,
  modAPI, modNative, modJSON, modTypes, modDrawer, modURL;

{$R *.fmx}

procedure TfrmPromotions.ShowPromotions;
var
  aJSON: string;
begin
  Show;
  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.Request(TmyAPI.getPromo);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          if TmyJSON.isOK(aJSON) then
          begin
            makePromotions(aJSON, lvContent);
            fgWait.Hide;
          end
          else
          begin
            fgWait.Hide;
            ShowToast(TmyJSON.ErrorMsg(aJSON));
          end;
        end);
    end);
end;

procedure TfrmPromotions.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  inherited;
  if not AItem.Data['url'].AsString.IsEmpty then
    openUrl(AItem.Data['url'].AsString);
end;

procedure TfrmPromotions.lvContentUpdatingObjects(const Sender: TObject; const AItem: TListViewItem;
var AHandled: Boolean);
begin
  inherited;
  Drawer(Sender, AItem, AHandled);
end;

procedure TfrmPromotions.makePromotions(const aData: string; const aLV: TListView);
var
  AItem: TListViewItem;
  FPromo: TmyTypePromoList;
  I: integer;
begin
  aLV.ItemsClearTrue;
  ConfigPromotions(aLV);

  if aData.IsEmpty then
    exit;

  if TmyJSON.isOK(aData) then
  begin
    FPromo := TJSON.Parse<TmyTypePromoList>(aData);
    for I := Low(FPromo.struct) to High(FPromo.struct) do
    begin
      AItem := aLV.Items.Add;
      with AItem do
      begin
        Text := FPromo.struct[I].title;
        Detail := FPromo.struct[I].body;
        Data['url'] := FPromo.struct[I].url;
        AItem.Data['custom'] := 1;
      end;
      aLV.Adapter.ResetView(AItem);
    end;
  end;
end;

procedure TfrmPromotions.ConfigPromotions(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetailRightButton';

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Image.Visible := false;
    TextButton.Visible := false;

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

procedure TfrmPromotions.Drawer(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
begin
  if (AItem.Data['custom'].AsInteger = 1) then
  begin
    TmyLV.ItemHeightByDetail(AItem, (Sender as TListView));
  end
  else
    AHandled := false;
end;

procedure TfrmPromotions.FormShow(Sender: TObject);
begin
  inherited;
  lbTitle.Font.Size := 18;
end;

end.
