{
   oxuWindowRender, renders oX windows
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowRender;

INTERFACE

   USES
      uStd,
      {oX}
      uOX, oxuWindowTypes, oxuWindow, oxuGlobalInstances,
      oxuViewport, oxuRenderer,
      oxuWindows, oxuUIHooks,
      {$IFDEF OX_LIBRARY}
      oxuRenderers,
      {$ENDIF}
      {io}
      uiuControl;

TYPE
   oxPWindowRender = ^oxTWindowRender;

   { oxTWindowRender }

   oxTWindowRender = object
      {if true, the OnOverrideRender callbacks will be called and no rendering will be done by default}
      OverrideRender: Boolean;

      constructor Create();

      {start rendering for a window (clear)}
      procedure StartRender(wnd: oxTWindow);

      {render window(s)}
      procedure Window(wnd: oxTWindow); virtual;
      procedure All(); virtual;

      {swaps the buffers for all windows}
      procedure SwapBuffers(wnd: oxTWindow);
      procedure SwapBuffers();
   end;

VAR
   oxWindowRender: oxTWindowRender;

IMPLEMENTATION

procedure oxwRenderPost(wnd: oxTWindow);
begin
   oxuiHooks.Render(wnd);
end;

constructor oxTWindowRender.Create();
begin
end;

procedure oxTWindowRender.StartRender(wnd: oxTWindow);
begin
   if(wnd.oxProperties.ApplyDefaultViewport) then
      wnd.Viewport.Apply();
end;

{All window(s)}
procedure oxTWindowRender.Window(wnd: oxTWindow);
begin
   if(not OverrideRender) then begin
      StartRender(wnd);

      if(wnd.Viewport.Changed) then
         oxWindows.OnViewportChanged.Call(wnd);

      oxWindows.OnRender.Call(wnd);
      oxWindows.Internal.OnPostRender.Call(wnd);

      {$IFNDEF OX_LIBRARY}
      oxTRenderer(wnd.Renderer).SwapBuffers(wnd);
      {$ENDIF}

      wnd.Viewport.Changed := false;
   end else
      oxWindows.OnOverrideRender.Call(wnd);
end;

procedure oxTWindowRender.All();
var
   i: loopint;

begin
   for i := 0 to oxWindows.n - 1 do begin
      Window(oxWindows.w[i]);
   end;
end;

procedure oxTWindowRender.SwapBuffers(wnd: oxTWindow);
begin
   oxTRenderer(wnd.Renderer).SwapBuffers(wnd);
end;

{ BUFFERS }
procedure oxTWindowRender.SwapBuffers();
var
   i: longint;

begin
   for i := 0 to (oxWindows.n - 1) do begin
      SwapBuffers(oxWindows.w[i]);
   end;
end;

INITIALIZATION
   oxWindowRender.Create();
   oxGlobalInstances.Add('oxTWindowRender', @oxWindowRender);

END.