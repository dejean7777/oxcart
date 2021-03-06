{
   oxuglShader, gl shader support
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglMaterial;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      {ox}
      uOX, oxuMaterial, oxuRunRoutines,
      {gl}
      oxuglRenderer;

TYPE
   oxglMaterial = class(oxTMaterial)
   end;
   
IMPLEMENTATION

function componentReturn(): TObject;
begin
   Result := oxglMaterial.Create();
end;

procedure init();
begin
   oxglRenderer.components.RegisterComponent('material', @componentReturn);
end;

INITIALIZATION
   ox.PreInit.Add('gl.material', @init);

END.
