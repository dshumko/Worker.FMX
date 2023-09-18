unit BasicForma;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Maps, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Objects, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FGX.ProgressDialog, modUI, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TBasicForm = class(TForm)
    Content: TRectangle;
    rHeader: TRectangle;
    lbTitle: TLabel;
    fgWait: TfgActivityDialog;
    sbBack: TZMaterialBackButton;
    sbBookmark: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fgWaitCancel(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormShow(Sender: TObject);
    procedure sbBackClick(Sender: TObject);
  private
    procedure RebuildOrientation;
  public
    FKeyboardShowed: Boolean;
  end;

implementation

{$R *.fmx}

uses
  System.Threading, FMX.StatusBar, FMX.FontAwesome, modNative;

procedure TBasicForm.fgWaitCancel(Sender: TObject);
begin
  Close;
end;

procedure TBasicForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TBasicForm.FormCreate(Sender: TObject);
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

procedure TBasicForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
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

procedure TBasicForm.FormResize(Sender: TObject);
begin
  RebuildOrientation;
end;

procedure TBasicForm.FormShow(Sender: TObject);
begin
  FKeyboardShowed := False;

  TmyWindow.StatusBarColor(self, TmyColors.Header);
  Content.Fill.Color := TmyColors.Content;
  rHeader.Fill.Color := TmyColors.Header;
  RebuildOrientation;
end;

procedure TBasicForm.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKeyboardShowed := KeyboardVisible;
end;

procedure TBasicForm.RebuildOrientation;
begin
  Content.Margins.Top := TmyWindow.StatusBarHeight;
end;

procedure TBasicForm.sbBackClick(Sender: TObject);
begin
  Close;
end;

initialization

TmyWindow.Init;

end.
