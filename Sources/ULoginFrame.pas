unit ULoginFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FGX.ProgressDialog,modNative,modTypes;

type
  TLoginFrame = class(TFrame)
    Layout1: TLayout;
    btnUserAuth: TButton;
    lbAutoEnter: TLabel;
    swAutoEnter: TSwitch;
    edCompany: TEdit;
    edUserAcc: TEdit;
    edUserPass: TEdit;
    layUserAuth: TLayout;
    fgWait: TfgActivityDialog;
    procedure FrameResize(Sender: TObject);
    procedure btnUserAuthClick(Sender: TObject);
    procedure edCompanyKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure edUserAccKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure edUserPassTyping(Sender: TObject);
    procedure edUserPassKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure swAutoEnterSwitch(Sender: TObject);
  private
    procedure TryAuth();
    procedure AuthFailed;
    procedure AuthSuccessful(const AJson:string);
    procedure GoToMenu;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  UMobWorkSettings, modAPI, modJSON, System.Threading, XSuperObject, UPushes, UCommonAPI, URouter;

{$R *.fmx}

procedure TLoginFrame.btnUserAuthClick(Sender: TObject);
begin
  TryAuth();
end;

constructor TLoginFrame.Create(AOwner: TComponent);
begin
  inherited;
  swAutoEnter.IsChecked := Settings.autoEnter;
  {$IFDEF DEBUG}
  edCompany.Text := 'DEMO';
  edUserAcc.Text := 'USR';
  edUserPass.Text := 'pswd';
  {$ENDIF}
end;

procedure TLoginFrame.FrameResize(Sender: TObject);
begin
  btnUserAuth.Margins.Left := Width / 3;
  btnUserAuth.Margins.Right := Width / 3;
end;


procedure TLoginFrame.AuthSuccessful(const AJson : string);
var
  Auth : TMyTypeAuth;
begin
  try
    Auth := TJSON.Parse<TMyTypeAuth>(aJson);
  except
    // неожиданно! нас тут быть не должно!
    ;
  end;

  Settings.AuthData := API.AuthData;
  Settings.gpsInterval := Auth.struct[0].gps;
  Settings.SaveToFile(TmyPath.SettingsFile);

  PushData.RegisterPushService;
  if (not PushData.diDeviceID.IsEmpty) and (not PushData.diDeviceToken.IsEmpty) then
  begin
    TTask.Run(
      procedure
      begin
        /// TODO - перевести в асинхронный выхов!!!
        API.SaveToken(PushData.diDeviceID, PushData.diDeviceToken);
      end);
  end;
  GoToMenu();
end;

procedure TLoginFrame.GoToMenu();
begin
  Router.Go('tabSplash','tabMenu');
end;

procedure TLoginFrame.swAutoEnterSwitch(Sender: TObject);
begin
  Settings.autoEnter := swAutoEnter.IsChecked;
end;

procedure TLoginFrame.AuthFailed;
begin
  ShowToast(Api.Err.Msg);
end;


procedure TLoginFrame.TryAuth;
var
  aJSON, aJSON2, aRespData: string;
begin
  fgWait.Show;
  API.AuthData.Login := edUserAcc.Text;
  API.AuthData.Password := edUserPass.Text;
  API.AuthData.Company := edCompany.Text;
  TTask.Run(
    procedure
    begin
      if FNeedCheckValidURL then
      begin
        aRespData := API.ObtainCompanyURL;
        if not aRespData.IsEmpty then
        begin
          API.AuthData.ValidURL := aRespData;
          API.AuthData.validURL_date := Now();
        end
        else
          API.AuthData.ValidURL := A4onApiURL;
      end;

      aJSON := API.userAuth();

      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          try
            if API.Err.Status=sOK then
              AuthSuccessful(AJson)
            else
              AuthFailed;
          finally
            fgWait.Hide;
          end;
        end)
    end);
end;


procedure TLoginFrame.edCompanyKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    edUserAcc.SetFocus;
    Key := 0;
  end;
end;

procedure TLoginFrame.edUserAccKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    edUserPass.SetFocus;
    Key := 0;
  end;
end;

procedure TLoginFrame.edUserPassKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    TryAuth();
    Key := 0;
  end;
end;

procedure TLoginFrame.edUserPassTyping(Sender: TObject);
begin
  btnUserAuth.Enabled := (not edUserAcc.Text.IsEmpty) and (not edUserPass.Text.IsEmpty);
end;

end.
