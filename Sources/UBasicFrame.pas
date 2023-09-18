unit UBasicFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.Layouts, FMX.ZMaterialBackButton, FMX.Controls.Presentation,
  FMX.Objects, FGX.ProgressDialog, URouter;

type
  TBasicFrame = class(TFrame)
    rHeader: TRectangle;
    lbTitle: TLabel;
    sbBack: TZMaterialBackButton;
    sbBookmark: TSpeedButton;
    fgWait: TfgActivityDialog;
    procedure sbBackClick(Sender: TObject);
  private
  public
    FreeOnExit:Boolean;
    procedure Init; virtual;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

constructor TBasicFrame.Create(AOwner: TComponent);
begin
  inherited;
  FreeOnExit := true;
end;

procedure TBasicFrame.Init;
begin

end;

procedure TBasicFrame.sbBackClick(Sender: TObject);
begin
  Router.GoBack;
end;

end.
