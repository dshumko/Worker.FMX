unit modUI;

interface

uses
  System.Types, System.SysUtils, System.UITypes;

type
  TmyColors = class
    class function Content: TAlphaColor; static;
    class function Header: TAlphaColor; static;
    class function MenuPics: TAlphaColor; static;

    class function bidSignOwn: TAlphaColor; static;
    class function bidSignOwnLate: TAlphaColor; static;
    class function bidSignAlien: TAlphaColor; static;
    class function bidSignNobody: TAlphaColor; static;

    class function bidType1: TAlphaColor; static;
    class function bidType2: TAlphaColor; static;

    class function CustomerOffType: TAlphaColor; static;

    class function ContactCall: TAlphaColor; static;

    class function SwitchEnabled: TAlphaColor; static;
    class function SwitchDisabled: TAlphaColor; static;

    class function PaymentsIn: TAlphaColor; static;
    class function PaymentsOut: TAlphaColor; static;
  end;

function VclToFmxColor(const Value: TColor; const Alpha: Byte = $FF): TAlphaColor;
function FmxToVclColor(const Value: TAlphaColor): TColor;

var
  FNeedUpdateBidList: Boolean = false;

implementation

{ TmyColors }

uses
  System.UIConsts;

class function TmyColors.Content: TAlphaColor;
begin
  Result := $FFEEEEEE; // $FFEFEFEF;
end;

class function TmyColors.CustomerOffType: TAlphaColor;
begin
  Result := $FF9E9E9E; // TAlphaColorRec.Silver;
end;

class function TmyColors.Header: TAlphaColor;
begin
  Result := $FFFF6600; // $FF0063B1; // $FFE10606; // $FFFF680C;
end;

class function TmyColors.bidSignAlien: TAlphaColor;
begin
  Result := $FFFFFF00; // TAlphaColorRec.Gold;
end;

class function TmyColors.bidSignNobody: TAlphaColor;
begin
  Result := TAlphaColorRec.White;
end;

class function TmyColors.bidSignOwn: TAlphaColor;
begin
  Result := $FF43A047; // TAlphaColorRec.Lightgreen;
end;

class function TmyColors.bidSignOwnLate: TAlphaColor;
begin
  Result := $FFF44336; // TAlphaColorRec.Red;
end;

class function TmyColors.bidType1: TAlphaColor;
begin
  Result := TAlphaColorRec.Lightsalmon;
end;

class function TmyColors.bidType2: TAlphaColor;
begin
  Result := $FF03A9F4; // TAlphaColorRec.Lightskyblue;
end;

class function TmyColors.ContactCall: TAlphaColor;
begin
  Result := $FF76FF03; // TmyColors.MenuPics;
end;

class function TmyColors.MenuPics: TAlphaColor;
begin
  Result := $FFFB8C00; // TmyColors.Header;
end;

class function TmyColors.PaymentsIn: TAlphaColor;
begin
  Result := $FF4CAF50; // TAlphaColorRec.Green;
end;

class function TmyColors.PaymentsOut: TAlphaColor;
begin
  Result := $FFF44336; // TAlphaColorRec.Red;
end;

class function TmyColors.SwitchDisabled: TAlphaColor;
begin
  Result := $FF9E9E9E; // TAlphaColorRec.Silver;
end;

class function TmyColors.SwitchEnabled: TAlphaColor;
begin
  Result := $FF4CAF50; // TAlphaColorRec.Green;
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

end.
