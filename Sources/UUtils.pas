unit UUtils;

interface
uses
  System.types, System.classes, Sysutils, System.hash,
  System.NetEncoding, FMX.Graphics;

function md5(const aValue: string): string;
function urlEnc(const aValue: string): string;
function Base64enc(const aValue: string): string;
function Base64dec(const aValue: string): string;
function Base64BitmapEnc(const aValue: TBitmap): string;
function Base64BitmapStreamEnc(const aValue: TMemoryStream): string;
procedure Base64BitmapStreamDec(const aValue: string; out aImage: TBitmap);

const
  B2S: array [Boolean] of string = ('0', '1');

var
  fs:TFormatSettings;

implementation


function md5(const aValue: string): string;
begin
  Result := THashMD5.GetHashString(aValue);
{  Result := '';
  with TIdHashMessageDigest5.Create do
  begin
    try
      try
        Result := LowerCase(HashStringAsHex(aValue, IndyTextEncoding_UTF8));
      except
        Result := '';
      end;
    finally
      Free;
    end;
  end;
  }
end;


function urlEnc(const aValue: string): string;
begin
  Result := TNetEncoding.URL.Encode(aValue);
end;


function Base64enc(const aValue: string): string;
begin
  Result := TNetEncoding.Base64.Encode(aValue);
end;


function Base64dec(const aValue: string): string;
begin
  Result := TNetEncoding.Base64.Decode(aValue);
end;


function Base64BitmapEnc(const aValue: TBitmap): string;
var
  aStr: TMemoryStream;
begin
  Result := '';
  if aValue = nil then
    exit;
  if aValue.IsEmpty then
    exit;

  aStr := TMemoryStream.Create;
  try
    aValue.SaveToStream(aStr);
    Base64BitmapStreamEnc(aStr);
  finally
    FreeAndNil(aStr);
  end;
end;


function Base64BitmapStreamEnc(const aValue: TMemoryStream): string;
begin
  Result := '';
  if aValue = nil then
    exit;
  if aValue.Size = 0 then
    exit;

  Result := TNetEncoding.Base64.EncodeBytesToString(aValue.Memory, aValue.Size);
end;


procedure Base64BitmapStreamDec(const aValue: string; out aImage: TBitmap);
var
  aMem: TMemoryStream;
  aStrMem: TBytesStream;
begin
  if aValue.IsEmpty then
    exit;

  aMem := TMemoryStream.Create;
  aStrMem := TBytesStream.Create(BytesOf(aValue));

  if TNetEncoding.Base64.Decode(aStrMem, aMem) > 0 then
  begin
    aMem.Position := 0;
    if aImage = nil then
      aImage := TBitmap.CreateFromStream(aMem)
    else
      aImage.LoadFromStream(aMem);
  end;

  FreeAndNil(aMem);
  FreeAndNil(aStrMem);
end;

initialization
  fs := TFormatSettings.Create();

finalization
  fs := TFormatSettings.Create();
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ' ';


end.
