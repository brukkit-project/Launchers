unit SkinSystem;

interface

uses
  Classes, ExtCtrls, Graphics, PNGImage, SysUtils;

procedure ClearImage(var Image: TImage);
procedure DrawSkin(const Skin: TMemoryStream; var Image: TImage);
procedure DrawCloak(const Cloak: TMemoryStream; var Image: TImage);

implementation

procedure ClearImage(var Image: TImage);
begin
  Image.Transparent := false;
  Image.Picture := nil;
  Image.Canvas.Pen.Color := $ffd185;
  Image.Canvas.Brush.Color := clWhite;
  Image.Canvas.Rectangle(0, 0, Image.Width, Image.Height);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure DrawSkin(const Skin: TMemoryStream; var Image: TImage);
var
  PNG: TPNGObject;
  StretchX, StretchY: single;
  x8, x15, x16, x23, x24, x31: Word;
  y16, y40, y64: Word;
begin
  Image.Picture := nil;
  Image.Transparent := true;

  StretchX := 2.2; // Коэффициенты масштабирования
  StretchY := 2.2;

  x8 := Round(8 * StretchX);
  x15 := Round(15 * StretchX);
  x16 := Round(16 * StretchX);
  x23 := Round(23 * StretchX);
  x24 := Round(24 * StretchX);
  x31 := Round(31 * StretchX);

  y16 := Round(16 * StretchY);
  y40 := Round(40 * StretchY);
  y64 := Round(64 * StretchY);

  Image.Canvas.Pen.Color := clBtnFace;
  Image.Canvas.Brush.Color := clBtnFace;
  Image.Canvas.Rectangle(0, 0, Image.Width, Image.Height);

  PNG := TPNGObject.Create;
  PNG.LoadFromStream(Skin);
    Image.Canvas.CopyRect(Rect(x8,   0,    x24,  y16), PNG.Canvas, Rect(8,  8,  16, 16)); // Голова
    Image.Canvas.CopyRect(Rect(x8,   y16,  x24,  y40), PNG.Canvas, Rect(20, 16, 28, 32)); // Корпус
    Image.Canvas.CopyRect(Rect(x8,   y40,  x16,  y64), PNG.Canvas, Rect(4,  20, 8,  32)); // Левая нога
    Image.Canvas.CopyRect(Rect(x23,  y40,  x15,  y64), PNG.Canvas, Rect(4,  20, 8,  32)); // Правая нога
    Image.Canvas.CopyRect(Rect(0,    y16,  x8,   y40), PNG.Canvas, Rect(44, 20, 48, 32)); // Левая рука
    Image.Canvas.CopyRect(Rect(x31,  y16,  x23,  y40), PNG.Canvas, Rect(44, 20, 48, 32)); // Правая рука
  FreeAndNil(PNG);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure DrawCloak(const Cloak: TMemoryStream; var Image: TImage);
var
  PNG: TPNGObject;
begin
  Image.Picture := nil;
  Image.Transparent := true;

  Image.Canvas.Pen.Color := clBtnFace;
  Image.Canvas.Brush.Color := clBtnFace;
  Image.Canvas.Rectangle(0, 0, Image.Width, Image.Height);

  PNG := TPNGObject.Create;
  PNG.LoadFromStream(Cloak);
    PNG.Canvas.CopyRect(Rect(0,0,12,16),PNG.Canvas,Rect(0,1,12,17));
    PNG.Resize(12,16);
    Image.Picture.Graphic := PNG;
  FreeAndNil(PNG);
end;


end.
