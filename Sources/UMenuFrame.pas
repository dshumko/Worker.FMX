unit UMenuFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, UVK_LVPatterns, System.ImageList, FMX.ImgList, System.Generics.Collections,
  JsonableObject, FMX.TabControl,XSuperObject;

type
  TMenuItem=class
  public
    id:integer;
    Text:string;
    img:string;
  end;

  TMenuObject=class(TJsonableObject)
  private
  public
    [disable]
    Items:TObjectList<TMenuItem>;
    [Alias('Items')]
    _Items: TArray<TMenuItem>;

    procedure BeforeSave(X:ISuperObject); override;
    procedure AfterLoad(X:ISuperObject); override;

    constructor Create; override;
    destructor Destroy; override;
  end;

  TMenuAdapter = class(TVK_LV_ListAdapter<TMenuItem>)
  public
    ImgList:TImageList;
    Menu:TMenuObject;
    procedure SetupDrawableContent(const AListViewItem: TListViewItem; const ADrawable: TListItemDrawable; const AData: TMenuItem); override;
    procedure SetItemData(const AListViewItem: TListViewItem; const AData: TMenuItem; const AName:string); override;
    function List():TObjectList<TMenuItem>; override;
    constructor Create(const AListView: TListView); override;
    destructor Destroy; override;
  end;

  TMenuFrame = class(TFrame)
    lvContent: TListView;
    il1: TImageList;
    procedure lvContentUpdatingObjects(const Sender: TObject;
      const AItem: TListViewItem; var AHandled: Boolean);
    procedure lvContentItemClickEx(const Sender: TObject; ItemIndex: Integer;
      const LocalClickPos: TPointF; const ItemObject: TListItemDrawable);
  private
    procedure MakeMenu;
    function GetParentTab():TTabItem;
  public
    Adapter:TMenuAdapter;
    FRunFrameProc:TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  math, UMobWorkColorScheme, FMX.FontAwesome, URouter;

{$R *.fmx}

const
  sORDERS='orders';
  sBUILDINGS='buildings';
  sACTIONS='actions';
  sPHONES='phones';
  sBOOKMARKS='bookmarks';

  menuItems = '{"Items":[' +
              '{"id":1,"Text":"Заявки","img":"'+sorders+'"},' +
              '{"id":2,"Text":"Дома","img":"'+sbuildings+'"},' +
              '{"id":3,"Text":"Акции","img":"'+sactions+'"},' +
              '{"id":4,"Text":"Телефоны","img":"'+sphones+'"},' +
              '{"id":5,"Text":"Закладки","img":"'+sbookmarks+'"}' +
              ']}';
  menuLayout = '{' +
                    '"Columns":  ' +
                    '[],' +
                    '"Objects":  ' +
                    '[' +
                    '  {"Kind":"data","Name":"ID"},' +

                    '  {"Kind":"image","Name":"img",' +
                    '   "Place":{"X":"(itemwidth-96)/2","Y":"5","W":"96","H":"96"},' +
                    '   "HAlign":"leading","VAlign":"center",' +
                    '  },' +

                    '  {"Kind":"text","Name":"Text","TextHAlign":"leading","TextVAlign":"leading",' +
                    '   "Place":{"X":"20","Y":"img.h / 2","W":"auto","H":"auto"},' +
                    '   "Color":"Brown",' +
                    '   "Font":{"Size":16,"Style":"bold"}' +
                    '  }' +

                    '],' +
                    '"ItemHeight":"96+10",' +
                    '"ItemSpaces": {"X":"","Y":"","W":"","H":""}' +
                    '}';

  IMG_ORDERS=0;
  IMG_BUILDINGS=1;
  IMG_ACTIONS=2;
  IMG_PHONES=3;
  IMG_BOOKMARKS=4;

//  arrTitles: array [0 .. 4] of string = ('Заявки', 'Дома', 'Акции', 'Телефоны', 'Закладки');
//  arrPics: array [0 .. 4] of string = (fa_list_alt, fa_building, fa_trophy, fa_phone, fa_bookmark);


constructor TMenuFrame.Create(AOwner: TComponent);
begin
  inherited;
  Adapter := TMenuAdapter.Create(lvContent);
  Adapter.AddPatternFromJSON(menuLayout);
  Adapter.SetupListView();
  Adapter.ResetView();

  makeMenu();
end;

destructor TMenuFrame.Destroy;
begin
  FreeAndNil(Adapter);
  inherited;
end;

function TMenuFrame.GetParentTab: TTabItem;
var
  p:TFmxObject;
begin
  p:=Parent;
  while p<>NIL do
  begin
    if p is TTabItem then
    begin
      result := p as TTabItem;
      exit;
    end;
    p := p.Parent;
  end;
end;

procedure TMenuFrame.lvContentItemClickEx(const Sender: TObject;
  ItemIndex: Integer; const LocalClickPos: TPointF;
  const ItemObject: TListItemDrawable);
begin
  FRunFrameProc(TObject(ItemIndex));
end;

procedure TMenuFrame.lvContentUpdatingObjects(const Sender: TObject;
  const AItem: TListViewItem; var AHandled: Boolean);
begin
  Adapter.SetupContent(AItem);
  Adapter.DoLayout(AItem);
  AHandled := true;
end;


{procedure TMenuFrame.lvContentUpdatingObjects(const Sender: TObject;
  const AItem: TListViewItem; var AHandled: Boolean);
var
  iTitle, iGlyph: TListItemText;
  aPos: Single;
  I: integer;
  ColCount: integer;
  ColWidth: single;
  ColOffset: integer;
begin
  colCount := 1;
  ColOffset := lvContent.SideSpace;
  ColWidth := lvContent.Width - ColOffset;

  for I := 1 to ColCount do
  begin
    if not InRange(I, 1, AItem.Tag) then
      continue;

    aPos := (((ColWidth * I) - ColWidth) - 6) + Trunc(ColOffset * I);

    iGlyph := AItem.Objects.FindObjectT<TListItemText>('glyph' + IntToStr(I));
    if iGlyph = nil then
      iGlyph := TListItemText.Create(AItem);
    iGlyph.Name := 'glyph' + IntToStr(I);
    iGlyph.Width := ColWidth - 8;
    iGlyph.Height := ColWidth - 38;
    iGlyph.TextAlign := TTextAlign.Center;
    iGlyph.TextVertAlign := TTextAlign.Center;
    iGlyph.SelectedTextColor := DefColorScheme.MenuPics;
    iGlyph.TextColor := DefColorScheme.MenuPics;
    iGlyph.PlaceOffset.X := aPos;
    iGlyph.PlaceOffset.Y := 4;
    iGlyph.Font.Family := FontAwesomeName;
    iGlyph.Font.Size := ColWidth / 2;
    iGlyph.Text := AItem.Data['glyph' + IntToStr(I)].AsString;

    iTitle := AItem.Objects.FindObjectT<TListItemText>('title' + IntToStr(I));
    if iTitle = nil then
      iTitle := TListItemText.Create(AItem);
    iTitle.Name := 'title' + IntToStr(I);
    iTitle.TextAlign := TTextAlign.Center;
    iTitle.TextVertAlign := TTextAlign.Center;
    iTitle.SelectedTextColor := TAlphaColorRec.Black;
    iTitle.TextColor := TAlphaColorRec.Black;
    iTitle.Font.Size := 14;
    iTitle.WordWrap := true;
    iTitle.Width := iGlyph.Width - 8;
    iTitle.PlaceOffset.X := aPos ;
    iTitle.PlaceOffset.Y := iGlyph.Height;
    iTitle.Height := lvContent.ItemAppearance.ItemHeight - iTitle.PlaceOffset.Y;
    iTitle.Text := AItem.Data['title' + IntToStr(I)].AsString;
  end;

  AHandled := true;
end;
}

procedure TMenuFrame.MakeMenu();
begin

end;

{ TMenuAdapter }

constructor TMenuAdapter.Create(const AListView: TListView);
begin
  inherited Create(AListView);
  Menu := TMenuObject.Create;
  Menu.LoadFromJSON(menuitems);
end;

function TMenuAdapter.List: TObjectList<TMenuItem>;
begin
  Result := Menu.Items;
end;

destructor TMenuAdapter.Destroy;
begin
  FreeAndNil(menu);
  inherited;
end;

procedure TMenuAdapter.SetItemData(const AListViewItem: TListViewItem; const AData: TMenuItem; const AName:string);
begin
  if AnsiSameText( AName, 'ID') then
  begin
    AListViewItem.Data[AName] := AData.id;
  end
end;

procedure TMenuAdapter.SetupDrawableContent(const AListViewItem: TListViewItem; const ADrawable: TListItemDrawable; const AData: TMenuItem);
var
  sz:TSizeF;
begin
  if AnsiSameText( ADrawable.Name, 'text') then
  begin
    (ADrawable as TListItemText).Text := AData.Text;
  end
  else if SameText( ADrawable.Name, 'img') then
  begin
    sz := TSizef.Create(96,96);
    if AnsiSameText(AData.img,sORDERS) then
//      (ADrawable as TListItemImage).ImageSource := TListItemImage.TImageSource.ImageList;
      (ADrawable as TListItemImage).ImageIndex := IMG_ORDERS
    else if AnsiSameText(AData.img,sBUILDINGS) then
      (ADrawable as TListItemImage).ImageIndex := IMG_BUILDINGS
    else if AnsiSameText(AData.img,sACTIONS) then
      (ADrawable as TListItemImage).ImageIndex := IMG_ACTIONS
    else if AnsiSameText(AData.img,sPHONES) then
      (ADrawable as TListItemImage).ImageIndex := IMG_PHONES
    else if AnsiSameText(AData.img,sBOOKMARKS) then
      (ADrawable as TListItemImage).ImageIndex := IMG_BOOKMARKS;
  end;
end;

{ TMenuItems }

procedure TMenuObject.AfterLoad(X: ISuperObject);
begin
  ArrayToList<TMenuItem>(_Items,Items);
end;

procedure TMenuObject.BeforeSave(X: ISuperObject);
begin
  ListToArray<TMenuItem>(Items, _Items);
end;

constructor TMenuObject.Create;
begin
  inherited;
  items := TObjectList<TMenuItem>.Create(True);
end;

destructor TMenuObject.Destroy;
begin
  freeandnil(items);
  inherited;
end;


end.
