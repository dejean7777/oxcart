{
   wdguSceneRender, scene renderer widget
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguSceneRender;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      oxuProjection, oxuProjectionType, oxuCamera,
      oxuSceneRender, oxuScene,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets, wdguBase, wdguViewport;

TYPE

   { wdgTSceneRender }

   wdgTSceneRender = class(wdgTViewport)
      {a renderer for the scene}
      SceneRenderer: oxTSceneRenderer;
      {scene projection}
      Projection: oxTProjection;
      {render a specific camera}
      Camera: oxTCamera;

      RenderSceneCameras: boolean;
      {render specified scene, but if set to nil render default scene}
      Scene: oxTScene;

      constructor Create(); override;
      destructor Destroy(); override;

      procedure Render(); override;
      procedure PerformRender(); override;

      procedure ProjectionStart(); override;

      procedure OnSceneRenderEnd(); virtual;
   end;

   wdgTSceneRenderGlobal = object(specialize wdgTBase<wdgTSceneRender>)
   end;

VAR
   wdgSceneRender: wdgTSceneRenderGlobal;

IMPLEMENTATION

{ wdgTSceneRender }

constructor wdgTSceneRender.Create();
begin
   inherited;

   SceneRenderer := oxSceneRender.Default;
   RenderSceneCameras := true;
   oxTProjection.Create(Projection, @Viewport);
   Camera.Initialize();
end;

destructor wdgTSceneRender.Destroy();
begin
   inherited Destroy;

   if(SceneRenderer <> oxSceneRender.Default) then
      FreeObject(SceneRenderer);
end;

procedure wdgTSceneRender.Render();
begin
   if(IsEnabled()) then
      PerformRender();
end;

procedure wdgTSceneRender.PerformRender();
var
   params: oxTSceneRenderParameters;

begin
   oxTSceneRenderParameters.Init(params);

   Projection.UseViewport(Viewport);

   ProjectionStart();

   oxTSceneRenderParameters.Init(params, @Projection, @Camera);
   params.Viewport := @Viewport;
   params.Scene := Scene;

   if(not RenderSceneCameras) then
      SceneRenderer.RenderCamera(params)
   else
      SceneRenderer.Render(params);

   OnSceneRenderEnd();

   CleanupRender();
end;

procedure wdgTSceneRender.ProjectionStart();
begin
   inherited ProjectionStart();

   if(Viewport.Changed) then
      Projection.UpdateViewport();
end;

procedure wdgTSceneRender.OnSceneRenderEnd();
begin

end;

INITIALIZATION
   wdgSceneRender.Create('scene_render');

END.
