program mobwork;

uses
  System.StartUpCopy,
  FMX.Forms,
  System.SysUtils,
  FMX.FontGlyphs.Android in 'comps\FMX.FontGlyphs.Android.pas',
  FMX.ListView in 'comps\FMX.ListView.pas',
  FMX.ListView.Types in 'comps\FMX.ListView.Types.pas',
  FMX.FontAwesome in 'modules\FMX.FontAwesome.pas',
  modDrawer in 'modules\modDrawer.pas',
  FMX.ListView.TextButtonFix in 'modules\FMX.ListView.TextButtonFix.pas',
  FMX.StatusBar in 'modules\FMX.StatusBar.pas',
  modAPI in 'modules\modAPI.pas',
  modJSON in 'modules\modJSON.pas',
  modUI in 'modules\modUI.pas',
  modTypes in 'modules\modTypes.pas',
  XSuperJSON in 'comps\XSO\XSuperJSON.pas',
  XSuperObject in 'comps\XSO\XSuperObject.pas',
  FMX.Bitmap.Helper in 'comps\FMX.Bitmap.Helper.pas',
  AnonThread in 'comps\AnonThread.pas',
  modURL in 'modules\modURL.pas',
  FMX.DeviceInfo in 'modules\FMX.DeviceInfo.pas',
  uMain in 'uMain.pas' {frmMain},
  UListItemElements in 'comps\UListItemElements.pas',
  modNative in 'modules\modNative.pas',
  FMX.Pickers.Helper in 'modules\FMX.Pickers.Helper.pas',
  BasicLVForma in 'BasicLVForma.pas' {BasicLVForm},
  uContacts in 'uContacts.pas' {frmContacts},
  uHouse in 'uHouse.pas' {frmHouse},
  uEqipment in 'uEqipment.pas' {frmEqipment},
  uCustomer in 'uCustomer.pas' {frmCustomer},
  uBidList in 'uBidList.pas' {frmBidList},
  uAddress in 'uAddress.pas' {frmAddress},
  uBidInfo in 'uBidInfo.pas' {frmBidInfo},
  uCustomers in 'uCustomers.pas' {frmCustomers},
  uBidPhoto in 'uBidPhoto.pas' {frmBidPhoto},
  uMaterials in 'uMaterials.pas' {frmMaterials},
  BasicForma in 'BasicForma.pas' {BasicForm},
  uBidComplete in 'uBidComplete.pas' {frmBidComplete},
  uPromotions in 'uPromotions.pas' {frmPromotions},
  uNewAbonent in 'uNewAbonent.pas' {frmNewAbonent},
  uServiceAdd in 'uServiceAdd.pas' {frmServiceAdd},
  uEquipmentAdd in 'uEquipmentAdd.pas' {frmEquipmentAdd},
  uDiscountAdd in 'uDiscountAdd.pas' {frmDiscountAdd},
  uBookmarks in 'uBookmarks.pas' {frmBookmarks};

{R *.res}

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  Application.Initialize;

  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ' ';

  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
