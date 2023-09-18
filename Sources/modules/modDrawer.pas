unit modDrawer;

interface

uses
  System.Types, System.UITypes, System.SysUtils, System.Classes,
  FMX.Types, FMX.ListView, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.TextLayout;

type
  TmyLV = class
    class procedure ConfigMenu(const aLV: TListView); static;
    class procedure ConfigNewsInfo(const aLV: TListView); static;

    class procedure ConfigBidComplete(const aLV: TListView); static;

    class procedure ItemHeightByDetail(const AItem: TListViewItem; aLV: TListView); static;

  end;

var
  FCabinetUpdate: Boolean = false;
  // TextLayout: TTextLayout = nil;

implementation

uses
  System.Math,
  FMX.FontAwesome, FMX.Utils, modUI, UListItemElements;

class procedure TmyLV.ConfigBidComplete(const aLV: TListView);
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

    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 0;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Center;
    Text.Visible := true;

    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;
  end;
end;

class procedure TmyLV.ConfigMenu(const aLV: TListView);
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
    Detail.TextColor := TmyColors.MenuPics;
    Detail.Font.Size := 24;
    Detail.Font.Family := FontAwesomeName;
  end;
end;

class procedure TmyLV.ConfigNewsInfo(const aLV: TListView);
begin
  aLV.CanSwipeDelete := false;
  aLV.ItemAppearance.ItemAppearance := 'ImageListItemBottomDetailRightButton';

  with aLV.ItemAppearanceObjects.ItemObjects do
  begin
    Accessory.Visible := false;
    Image.Visible := false;
    TextButton.Visible := false;

    Text.Align := TListItemAlign.Leading;
    Text.PlaceOffset.Y := 0;
    Text.Trimming := TTextTrimming.None;
    Text.WordWrap := true;
    Text.TextVertAlign := TTextAlign.Center;

    Detail.Trimming := TTextTrimming.None;
    Detail.WordWrap := true;

    Detail.Align := TListItemAlign.Leading;
  end;
end;

class procedure TmyLV.ItemHeightByDetail(const AItem: TListViewItem; aLV: TListView);
const
{$IFDEF MSWINDOWS}
  DefaultScrollBarWidth = 16;
{$ELSE}
  DefaultScrollBarWidth = 7;
{$ENDIF}
var
  aScrollWidth: Single;
  aTextHeight: Single;
begin
  aScrollWidth := DefaultScrollBarWidth;
  if not aLV.ShowScrollBar then
    aScrollWidth := 0;
  if (AItem.Data['arrow_show'].AsInteger = 1) then
    aScrollWidth := aScrollWidth + Max(AItem.Objects.AccessoryObject.Width, 22);

  aTextHeight := 0;
  with AItem.Objects.TextObject do
  begin
    WordWrap := true;
    Trimming := TTextTrimming.None;
    Font.Size := 13;
    // TextAlign := TTextAlign.Leading;
    Width := aLV.Width - (PlaceOffset.X * 2) - aLV.ItemSpaces.Left - aLV.ItemSpaces.Right - aScrollWidth;
    Height := aLV.getItemTextHeight(AItem.Objects.TextObject, Width);
  end;

  aTextHeight := aTextHeight + AItem.Objects.TextObject.Height;

  if not AItem.Detail.IsEmpty then
  begin
    // AItem.Objects.TextObject.PlaceOffset.Y := 8;
    // AItem.Objects.TextObject.Height := aTextHeight + 13;

    with AItem.Objects.DetailObject do
    begin
      VertAlign := TListItemAlign.Leading;
      WordWrap := true;
      Trimming := TTextTrimming.None;
      Font.Size := 13;
      PlaceOffset.Y := AItem.Objects.TextObject.PlaceOffset.Y + AItem.Objects.TextObject.Height;
      Width := AItem.Objects.TextObject.Width;
      // TextAlign := TTextAlign.Leading;
      // AItem.Objects.DetailObject.PlaceOffset.Y := AItem.Objects.TextObject.Height - 15;

      Height := aLV.getItemTextHeight(AItem.Objects.DetailObject, Width) + AItem.Objects.TextObject.Height;
    end;

    aTextHeight := aTextHeight + AItem.Objects.DetailObject.Height;
  end;

  aTextHeight := aLV.ItemSpaces.Top + aLV.ItemSpaces.Bottom + Max(aTextHeight + AItem.Objects.DetailObject.Height,
    aLV.ItemAppearance.ItemHeight);

  AItem.Height := Round(aTextHeight);
end;

(* class procedure TmyLV.ItemHeightByDetail(const AItem: TListViewItem; aLV: TListView);
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

  AItem.Objects.DetailObject.VertAlign := TListItemAlign.Leading;
  AItem.Objects.DetailObject.PlaceOffset.Y := AItem.Objects.TextObject.Height - 15;

  TextLayout.BeginUpdate;
  try
  TextLayout.Text := AItem.Detail;
  TextLayout.MaxSize := TPointF.Create(aLV.Width - aLV.ItemSpaces.Left - aLV.ItemSpaces.Right - aScrollWidth, 1000);
  TextLayout.Font.Assign(aLV.ItemAppearanceObjects.ItemObjects.Text.Font);
  TextLayout.WordWrap := aLV.ItemAppearanceObjects.ItemObjects.Text.WordWrap;
  TextLayout.Trimming := aLV.ItemAppearanceObjects.ItemObjects.Text.Trimming;
  TextLayout.HorizontalAlign := aLV.ItemAppearanceObjects.ItemObjects.Text.TextAlign;
  TextLayout.VerticalAlign := aLV.ItemAppearanceObjects.ItemObjects.Text.TextVertAlign;
  finally
  TextLayout.EndUpdate;
  end;
  end;

  AItem.Height := Round(TextLayout.Height + aLV.ItemSpaces.Top + aLV.ItemSpaces.Bottom + aTextHeight) + 28;
  end;
*)

initialization

// TextLayout := TTextLayoutManager.DefaultTextLayout.Create;

finalization

// TextLayout.free;

end.
