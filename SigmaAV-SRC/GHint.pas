unit GHint;

Interface

type
  TGraphicHintWindow = class(THintWindow)
    constructor Create(AOwner: TComponent); override;
  private
    FActivating: Boolean;
  public
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
  protected
    procedure Paint; override;
  published
    property Caption;
  end;

  {...}
  constructor Create(AOwner: TComponent);


Implementation

constructor TGraphicHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  {
   Hier k�nnen beliebige Schrift Eigenschaften gesetzt
   werden.

   Here you can set custom Font Properties:
   }

  with Canvas.Font do
  begin
    Name := 'Arial';
    Style := Style + [fsBold];
    Color := clBlack;
  end;
end;

procedure TGraphicHintWindow.Paint;
var
  R: TRect;
  bmp: TBitmap;
begin
  R := ClientRect;
  Inc(R.Left, 2);
  Inc(R.Top, 2);

  {*******************************************************
   Der folgende Code ist ein Beispiel wie man die Paint
   Prozedur nutzen kann um einen benutzerdefinierten Hint
   zu erzeugen.

   The folowing Code ist an example how to create a custom
   Hint Object. :
   }

  bmp := TBitmap.Create;
  bmp.LoadfromFile('D:\hint.bmp');

  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clsilver;
    Pen.Color   := clgray;
    Rectangle(0, 0, 18, R.Bottom + 1);
    Draw(2,(R.Bottom div 2) - (bmp.Height div 2), bmp);
  end;

  bmp.Free;
  //Beliebige HintFarbe
  //custom Hint Color
  Color := clWhite;

  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(20, (R.Bottom div 2) - (Canvas.Textheight(Caption) div 2), Caption);
  {********************************************************}
end;

procedure TGraphicHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  FActivating := True;
  try
    Caption := AHint;
    //H�he des Hints setzen setzen
    //Set the "Height" Property of the Hint
    Inc(Rect.Bottom, 14);
    //Breite des Hints setzen
    //Set the "Width" Property of the Hint
    Rect.Right := Rect.Right + 20;
    UpdateBoundsRect(Rect);
    if Rect.Top + Height > Screen.DesktopHeight then
      Rect.Top := Screen.DesktopHeight - Height;
    if Rect.Left + Width > Screen.DesktopWidth then
      Rect.Left := Screen.DesktopWidth - Width;
    if Rect.Left < Screen.DesktopLeft then Rect.Left := Screen.DesktopLeft;
    if Rect.Bottom < Screen.DesktopTop then Rect.Bottom := Screen.DesktopTop;
    SetWindowPos(Handle, HWND_TOPMOST, Rect.Left, Rect.Top, Width, Height,
      SWP_SHOWWINDOW or SWP_NOACTIVATE);
    Invalidate;
  finally
    FActivating := False;
  end;
end;
