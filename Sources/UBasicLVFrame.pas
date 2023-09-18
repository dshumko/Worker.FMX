unit UBasicLVFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  UBasicFrame, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.Layouts,
  FMX.ZMaterialBackButton, FMX.Controls.Presentation, FMX.Objects,
  FGX.ProgressDialog;

type
  TBasicLVFrame = class(TBasicFrame)
    lvContent: TListView;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BasicLVFrame: TBasicLVFrame;

implementation

{$R *.fmx}

end.
