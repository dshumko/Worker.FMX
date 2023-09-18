unit uListItemElements;

interface
uses
  FMX.Objects,
  FMX.Graphics,
  FMX.ListView.Types,
  FMX.TextLayout,
  FMX.Types,
  System.UITypes,
  System.Types,
  System.Math.Vectors,
  Generics.Collections;

type
  TListItemCircle = class(TListItemDrawable)
  private
    FColor: TAlphaColor;
    FBorderColor: TAlphaColor;
    FLineWidth: Single;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetBorderColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
  public

    constructor Create(const AOwner: TListItem); override;
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color: TAlphaColor read FColor write SetColor;
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    property LineWidth: Single read FLineWidth write SetLineWidth;
  end;

  TListItemCorner = class(TListItemDrawable)
  private
    FColor: TAlphaColor;
    FSize: Integer;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetSize(const Value: Integer);
  public
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color: TAlphaColor read FColor write SetColor;
    property Size: Integer read FSize write SetSize;
  end;

  TListItemRect = class(TListItemDrawable)
  private
    FColor: TAlphaColor;
    FBorderColor: TAlphaColor;
    FLineWidth: Single;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetBorderColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
  public
    constructor Create(const AOwner: TListItem); override;
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color: TAlphaColor read FColor write SetColor;
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    property LineWidth: Single read FLineWidth write SetLineWidth;
  end;

  TListItemRoundedRect = class(TListItemRect)
  private
    FRounded: Single;
    procedure SetRounded(const Value: Single);
  public
    constructor Create(const AOwner: TListItem); override;
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color;
    property BorderColor;
    property LineWidth;
    property Rounded: Single read FRounded write SetRounded;
  end;

  TListItemLine = class(TListItemDrawable)
  private
    FColor: TAlphaColor;
    FLineWidth: Single;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
  public
    constructor Create(const AOwner: TListItem); override;
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color: TAlphaColor read FColor write SetColor;
    property LineWidth: Single read FLineWidth write SetLineWidth;
  end;

  TListItemArc = class(TListItemDrawable)
  private
    FColor: TAlphaColor;
    FBorderColor: TAlphaColor;
    FLineWidth: Single;
    FStartAngle: Single;
    FSweepAngle: Single;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetBorderColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
    procedure SetStartAngle(const Value: Single);
    procedure SetSweepAngle(const Value: Single);
  public
    constructor Create(const AOwner: TListItem); override;
    procedure Render(const Canvas: TCanvas;
                     const DrawItemindex: Integer;
                     const DrawStates: TListItemDrawStates;
                     const Resources: TListItemStyleResources;
                     const Params: FMX.ListView.Types.TListItemDrawable.TParams;
                     const SubPassNo: Integer = 0); override;
    property Color: TAlphaColor read FColor write SetColor;
    property BorderColor: TAlphaColor read FBorderColor write SetBorderColor;
    property LineWidth: Single read FLineWidth write SetLineWidth;
    property StartAngle: Single read FStartAngle write SetStartAngle;
    property SweepAngle: Single read FSweepAngle write SetSweepAngle;
  end;

implementation

{ TListItemCircleText }

constructor TListItemCircle.Create(const AOwner: TListItem);
begin
  inherited;
  FLineWidth := 1;
end;

procedure TListItemCircle.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources; const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
begin
  if SubPassNo <> 0 then
    Exit;

  Canvas.Fill.Color := Color;
  Canvas.FillEllipse(LocalRect, Params.AbsoluteOpacity);
  Canvas.Stroke.Color := BorderColor;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := LineWidth;
  Canvas.DrawEllipse(LocalRect, Params.AbsoluteOpacity);
end;


procedure TListItemCircle.SetBorderColor(const Value: TAlphaColor);
begin
  FBorderColor := Value;
  Invalidate;
end;

procedure TListItemCircle.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure TListItemCircle.SetLineWidth(const Value: Single);
begin
  FLineWidth := Value;
  Invalidate;
end;

{ TListItemCorner }

procedure TListItemCorner.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources; const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
var
  pts: TPolygon;
begin
  if SubPassNo <> 0 then
    Exit;
  SetLength(pts, 4);
  Canvas.Fill.Color := Color;
  Canvas.Fill.Kind := TBrushKind.Solid;
  pts[0] := LocalRect.BottomRight;
  pts[1] := LocalRect.BottomRight;
  pts[2] := LocalRect.BottomRight;
  pts[3] := pts[0];
  pts[1].Offset(0, - Size);
  pts[2].Offset(- Size, 0);
  Canvas.FillPolygon(pts, Params.AbsoluteOpacity);
end;

procedure TListItemCorner.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure TListItemCorner.SetSize(const Value: Integer);
begin
  FSize := Value;
  Invalidate;
end;

{ TListItemRect }

constructor TListItemRect.Create(const AOwner: TListItem);
begin
  inherited;
  FLineWidth := 1;
end;

procedure TListItemRect.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources; const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
begin
  if SubPassNo <> 0 then
    Exit;
  Canvas.Fill.Color := Color;
  Canvas.FillRect(LocalRect, 0, 0, [], Params.AbsoluteOpacity);
  Canvas.Stroke.Color := BorderColor;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := LineWidth;
  Canvas.DrawRect(LocalRect, 0, 0, [], Params.AbsoluteOpacity);
end;

procedure TListItemRect.SetBorderColor(const Value: TAlphaColor);
begin
  FBorderColor := Value;
  Invalidate;
end;

procedure TListItemRect.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure TListItemRect.SetLineWidth(const Value: Single);
begin
  FLineWidth := Value;
  Invalidate;
end;

{ TListItemRoundedRect }

constructor TListItemRoundedRect.Create(const AOwner: TListItem);
begin
  inherited;
  FRounded := 0;
end;

procedure TListItemRoundedRect.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources; const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
begin
  if SubPassNo <> 0 then
    Exit;
  Canvas.Fill.Color := Color;
  Canvas.FillRect(LocalRect, FRounded, FRounded, [TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight],
                  Params.AbsoluteOpacity, TCornerType.Round);
  Canvas.Stroke.Color := BorderColor;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := LineWidth;
  Canvas.DrawRect(LocalRect, FRounded, FRounded,[TCorner.TopLeft, TCorner.TopRight, TCorner.BottomLeft, TCorner.BottomRight],
                  Params.AbsoluteOpacity, TCornerType.Round);
end;

procedure TListItemRoundedRect.SetRounded(const Value: Single);
begin
  FRounded := Value;
  Invalidate;
end;

{ TListItemLine }

constructor TListItemLine.Create(const AOwner: TListItem);
begin
  inherited;
  FLineWidth := 1;
end;

procedure TListItemLine.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources;
  const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
var
  p1, p2: TPointF;
begin
  if SubPassNo <> 0 then
    Exit;

  Canvas.Stroke.Color := Color;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  p1 := LocalRect.TopLeft;
  p2 := LocalRect.BottomRight;
  Canvas.Stroke.Thickness := LineWidth;
  Canvas.DrawLine(p1, p2, Params.AbsoluteOpacity);
end;

procedure TListItemLine.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure TListItemLine.SetLineWidth(const Value: Single);
begin
  FLineWidth := Value;
  Invalidate;
end;

{ TListItemArc }

constructor TListItemArc.Create(const AOwner: TListItem);
begin
  inherited;
  FLineWidth := 1;
  FStartAngle := 0;
  FSweepAngle := 45;
end;

procedure TListItemArc.Render(const Canvas: TCanvas;
  const DrawItemindex: Integer; const DrawStates: TListItemDrawStates;
  const Resources: TListItemStyleResources; const Params: FMX.ListView.Types.TListItemDrawable.TParams;
  const SubPassNo: Integer);
begin
  if SubPassNo <> 0 then
    Exit;

  Canvas.Fill.Color := Color;
  Canvas.FillArc(LocalRect.CenterPoint, TPointF.Create(LocalRect.Width / 2, LocalRect.Height / 2), FStartAngle,
                 FSweepAngle, Params.AbsoluteOpacity);
  Canvas.Stroke.Color := BorderColor;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Thickness := LineWidth;
  Canvas.DrawArc(LocalRect.CenterPoint, TPointF.Create(LocalRect.Width / 2, LocalRect.Height / 2), FStartAngle,
                 FSweepAngle, Params.AbsoluteOpacity);
end;

procedure TListItemArc.SetBorderColor(const Value: TAlphaColor);
begin
  FBorderColor := Value;
  Invalidate;
end;

procedure TListItemArc.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Invalidate;
end;

procedure TListItemArc.SetLineWidth(const Value: Single);
begin
  FLineWidth := Value;
  Invalidate;
end;

procedure TListItemArc.SetStartAngle(const Value: Single);
begin
  FStartAngle := Value;
  Invalidate;
end;

procedure TListItemArc.SetSweepAngle(const Value: Single);
begin
  FSweepAngle := Value;
  Invalidate;
end;

end.

