unit uBidComplete;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  BasicForma, FGX.ProgressDialog, FMX.Controls.Presentation, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.ListBox, FMX.DateTimeCtrls, FMX.Layouts, FMX.ZMaterialBackButton;

type
  TfrmBidComplete = class(TBasicForm)
    btnBidSave: TButton;
    btnMaterials: TButton;
    pScroll: TVertScrollBox;
    lbTextDateTime: TLabel;
    lbTextTroubleDescr: TLabel;
    Layout1: TLayout;
    DateEdit1: TDateEdit;
    TimeEdit1: TTimeEdit;
    cbResult: TComboBox;
    mTextResult: TMemo;
    Label1: TLabel;
    sbPhoto: TSpeedButton;
    Layout2: TLayout;
    procedure sbPhotoClick(Sender: TObject);
    procedure btnMaterialsClick(Sender: TObject);
    procedure btnBidSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormResize(Sender: TObject);
    procedure sbBackClick(Sender: TObject);
  private
    FKBBounds: TRectF;
    FNeedOffset: Boolean;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure RestorePosition;
    procedure UpdateKBBounds;
    function SaveBidtoFile:Boolean;
  public
    procedure Show(const aID: Integer; const ADateTime, aProblem: string); overload;
  end;

var
  frmBidComplete: TfrmBidComplete;

implementation

uses
  System.Threading, System.DateUtils, Math, FMX.Surfaces,
  modUI, FMX.FontAwesome, modAPI, modJSON, uMain, modDrawer,
  FMX.Pickers.Helper, modNative
{$IFDEF ANDROID}
    , Posix.Unistd
{$ENDIF}
    , uMaterials, uBidPhoto;

const
  aStatusWorkID: array [0 .. 3] of Integer = (0, 2, 3, 4);

{$R *.fmx}

procedure TfrmBidComplete.btnBidSaveClick(Sender: TObject);
var
  aJSON: string;
begin
  inherited;
  if not SaveBidToFile then Exit;

  fgWait.Show;
  TTask.Run(
    procedure
    begin
      aJSON := TmyAPI.closeBid(lbTitle.Tag);

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          fgWait.Hide;
          if TmyJSON.isOK(aJSON) then
          begin
            FNeedUpdateBidList := true;
            ShowToast('Заявка закрыта');
            aJSON := TmyPath.generateBid(lbTitle.Tag);
            if FileExists(aJSON) then
              DeleteFile(aJSON);
            Close;
          end;
        end);
    end);
end;

procedure TfrmBidComplete.RestorePosition;
begin
  pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, 0);
  pScroll.RealignContent;
end;

procedure TfrmBidComplete.btnMaterialsClick(Sender: TObject);
begin
  inherited;
  TfrmMaterials.Create(Application).Show(lbTitle.Tag, lbTitle.Text);
end;

procedure TfrmBidComplete.sbBackClick(Sender: TObject);
begin
  if not SaveBidToFile then Exit;
  inherited;
end;

procedure TfrmBidComplete.sbPhotoClick(Sender: TObject);
begin
  inherited;
  TfrmBidPhoto.Create(Application).Show(lbTitle.Tag);
end;

procedure TfrmBidComplete.FormCreate(Sender: TObject);
begin
  inherited;
  pScroll.OnCalcContentBounds := CalcContentBoundsProc;

//  FontAwesomeAssign(sbBack);
//  sbBack.Font.Size := 18;
//  sbBack.Text := fa_arrow_left;
//  sbBack.FontColor := TAlphaColorRec.White;

  FontAwesomeAssign(sbPhoto);
  sbPhoto.Font.Size := 18;
  sbPhoto.Text := fa_camera;
  sbPhoto.FontColor := TAlphaColorRec.White;

  lbTitle.Font.Size := 18;
  lbTitle.FontColor := TAlphaColorRec.White;
end;

function calcMargins(const aControl: TButton): Single;
begin
  Result := 0;
  if aControl.Visible then
    Result := aControl.Margins.Left + aControl.Margins.Right;
end;

procedure setMargings(aControl: TButton; aLeft, aRight: Single; aAlign: TAlignLayout);
begin
  aControl.Margins.Left := aLeft;
  aControl.Margins.Right := aRight;
  aControl.Align := aAlign;
end;

procedure TfrmBidComplete.FormResize(Sender: TObject);
begin
  inherited;
  btnBidSave.Width := (Layout2.Width - (calcMargins(btnMaterials) + calcMargins(btnBidSave))) / 2;
end;

procedure TfrmBidComplete.UpdateKBBounds;
var
  LFocused: TControl;
  LFocusRect: TRectF;
begin
  FNeedOffset := False;
  if Assigned(Focused) then
  begin
    LFocused := TControl(Focused.GetObject);
    LFocusRect := LFocused.AbsoluteRect;
    LFocusRect.Offset(pScroll.ViewportPosition);
    if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and (LFocusRect.Bottom > FKBBounds.Top) then
    begin
      FNeedOffset := true;
      // layUserAuth.Align := TAlignLayout.Horizontal;
      pScroll.RealignContent;
      Application.ProcessMessages;
      pScroll.ViewportPosition := PointF(pScroll.ViewportPosition.X, LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;
  if not FNeedOffset then
    RestorePosition;
end;

procedure TfrmBidComplete.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := False;
  RestorePosition;
end;

procedure TfrmBidComplete.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  inherited;
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmBidComplete.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
  end;
end;

function TfrmBidComplete.SaveBidtoFile:Boolean;
begin
  Result := False;
  if cbResult.itemIndex = 0 then
  begin
    ShowToast('Укажите результат');
    exit;
  end;

  if mTextResult.Text.IsEmpty then
  begin
    ShowToast('Описание не указано');
    exit;
  end;

  TmyJSON.SaveLocalBidText(lbTitle.Tag, aStatusWorkID[cbResult.itemIndex], mTextResult.Text,
    DateTimeToUnix(DateOf(DateEdit1.Date) + TimeOf(TimeEdit1.Time), true));

  if FileExists(TmyPath.generateBid(lbTitle.Tag))
  then Result := true
  else ShowToast('Ошибка сохранения файла заявки');
end;

procedure TfrmBidComplete.Show(const aID: Integer; const ADateTime, aProblem: string);
var
  aResult, aUnixDateTime: Integer;
  aResultText: string;
  aDT: TDateTime;
begin
  lbTitle.Text := format('Закрыть заявку: %d', [aID]);
  lbTitle.Tag := aID;
  lbTextDateTime.Text := ADateTime;
  lbTextTroubleDescr.Text := aProblem;
  setMargings(btnBidSave, 8, 8, TAlignLayout.Left);
  setMargings(btnMaterials, 0, 8, TAlignLayout.Client);
  btnBidSave.Width := (Layout2.Width - (calcMargins(btnMaterials) + calcMargins(btnBidSave))) / 2;

  TmyJSON.LoadLocalBidText(aID, aResult, aResultText, aUnixDateTime);

  mTextResult.Text := aResultText;
  if aResult > 0 then
    cbResult.itemIndex := aResult - 1
  else
    cbResult.itemIndex := 0;
  aDT := UnixToDateTime(aUnixDateTime, true);

  DateEdit1.Date := DateOf(aDT);
  TimeEdit1.Time := TimeOf(aDT);

  Show;
end;

end.
