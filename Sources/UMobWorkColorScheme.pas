unit UMobWorkColorScheme;

interface

uses
  System.Types, System.SysUtils, System.UITypes;

type
  TMobWorkColorScheme = class
    Content: TAlphaColor;
    Header: TAlphaColor;
    MenuPics: TAlphaColor;

    bidSignOwn: TAlphaColor;
    bidSignOwnLate: TAlphaColor;
    bidSignAlien: TAlphaColor;
    bidSignNobody: TAlphaColor;

    bidType1: TAlphaColor;
    bidType2: TAlphaColor;

    CustomerOffType: TAlphaColor;

    ContactCall: TAlphaColor;

    SwitchEnabled: TAlphaColor;
    SwitchDisabled: TAlphaColor;

    PaymentsIn: TAlphaColor;
    PaymentsOut: TAlphaColor;
    constructor Create;
  end;

function VclToFmxColor(const Value: TColor; const Alpha: Byte = $FF): TAlphaColor;
function FmxToVclColor(const Value: TAlphaColor): TColor;

var
  FNeedUpdateBidList: Boolean = false;
  DefColorScheme:TMobWorkColorScheme;

implementation

{ TmyColors }

uses
  System.UIConsts;

constructor TMobWorkColorScheme.Create;
begin
  Content := $FFEEEEEE;
  CustomerOffType:= $FF9E9E9E; // TAlphaColorRec.Silver;
  Header:= $FFFF6600; // $FF0063B1; // $FFE10606; // $FFFF680C;
  bidSignAlien:= $FFFFFF00; // TAlphaColorRec.Gold;
  bidSignNobody:= TAlphaColorRec.White;
  bidSignOwn:= $FF43A047; // TAlphaColorRec.Lightgreen;
  bidSignOwnLate:= $FFF44336; // TAlphaColorRec.Red;
  bidType1:= TAlphaColorRec.Lightsalmon;
  bidType2:= $FF03A9F4; // TAlphaColorRec.Lightskyblue;
  ContactCall:= $FF76FF03; // TmyColors.MenuPics;
  MenuPics:= $FFFB8C00; // TmyColors.Header;
  PaymentsIn:= $FF4CAF50; // TAlphaColorRec.Green;
  PaymentsOut:= $FFF44336; // TAlphaColorRec.Red;
  SwitchDisabled:= $FF9E9E9E; // TAlphaColorRec.Silver;
  SwitchEnabled:= $FF4CAF50; // TAlphaColorRec.Green;
end;

function VclToFmxColor(const Value: TColor; const Alpha: Byte = $FF): TAlphaColor;
var
  CREC: TColorRec;
  AREC: TAlphaColorRec;
begin
  CREC.Color := Value;

  AREC.A := Alpha;
  AREC.B := CREC.B;
  AREC.G := CREC.G;
  AREC.R := CREC.R;

  Result := AREC.Color;
end;

function FmxToVclColor(const Value: TAlphaColor): TColor;
var
  CREC: TColorRec;
  AREC: TAlphaColorRec;
begin
  AREC.Color := Value;

  CREC.B := AREC.B;
  CREC.G := AREC.G;
  CREC.R := AREC.R;

  Result := CREC.Color;
end;


initialization
  DefColorScheme := TMobWorkColorScheme.Create;

finalization
  FreeAndNil(DefColorScheme);

end.
