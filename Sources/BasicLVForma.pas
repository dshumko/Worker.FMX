unit BasicLVForma;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Maps, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Objects, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FGX.ProgressDialog, modUI, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TBasicLVForm = class(TForm)
    Content: TRectangle;
    rHeader: TRectangle;
    lbTitle: TLabel;
    lvContent: TListView;
    fgWait: TfgActivityDialog;
    sbBack: TZMaterialBackButton;
    sbBookmark: TSpeedButton;
    procedure sbBackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lvContentApplyStyleLookup(Sender: TObject);
    procedure fgWaitCancel(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormShow(Sender: TObject);
  private
    FKeyboardShowed: Boolean;
    procedure RebuildOrientation;
  public
  end;

implementation

{$R *.fmx}

uses
  System.Threading, FMX.StatusBar, FMX.FontAwesome, modNative;

procedure TBasicLVForm.fgWaitCancel(Sender: TObject);
begin
  Close;
end;

procedure TBasicLVForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TBasicLVForm.FormCreate(Sender: TObject);
begin
  FontAwesomeAssign(sbBookmark);
  sbBookmark.Font.Size := 18;
  sbBookmark.Text := fa_bookmark_o;
  sbBookmark.FontColor := TAlphaColorRec.White;

  lbTitle.Font.Size := 13;
  lbTitle.FontColor := TAlphaColorRec.White;
  lbTitle.WordWrap := true;
  lbTitle.Trimming := TTextTrimming.None;
end;

procedure TBasicLVForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkHardwareBack) or (Key = vkEscape) then
  begin
    if FKeyboardShowed then
    begin
      // hide virtual keyboard
    end
    else
    begin
      Key := 0;
      sbBackClick(Sender);
    end;
  end;
end;

procedure TBasicLVForm.FormResize(Sender: TObject);
begin
  RebuildOrientation;
end;

procedure TBasicLVForm.FormShow(Sender: TObject);
begin
  FKeyboardShowed := False;

  TmyWindow.StatusBarColor(self, TmyColors.Header);
  Content.Fill.Color := TmyColors.Content;
  rHeader.Fill.Color := TmyColors.Header;
  RebuildOrientation;
end;

procedure TBasicLVForm.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKeyboardShowed := KeyboardVisible;
end;

procedure TBasicLVForm.lvContentApplyStyleLookup(Sender: TObject);
begin
  // lvContent.SetColorHeader($FFE0E0E0);
  lvContent.SetColorHeader($FFFFCC80);
  lvContent.SetColorTextHeader($FF212121);
  lvContent.SetColorBackground(TmyColors.Content);
  lvContent.SetColorItemSelected($FFFFF8E1);
end;

procedure TBasicLVForm.lvContentItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  (Sender as TListView).ShowSelection := not(Sender as TListView).IsCustomColorUsed(AItem.Index);
  (Sender as TListView).EnableTouchAnimation((Sender as TListView).ShowSelection);
end;

procedure TBasicLVForm.RebuildOrientation;
begin
  Content.Margins.Top := TmyWindow.StatusBarHeight;
end;

procedure TBasicLVForm.sbBackClick(Sender: TObject);
begin
  Close;
end;

initialization

TmyWindow.Init;

end.
