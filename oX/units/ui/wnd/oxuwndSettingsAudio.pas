{
   oxuwndSettingsAudio, audio settings tab
   Copyright (C) 2019. Dejan Boras

   Started On:    10.11.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxuwndSettingsAudio;

INTERFACE

   USES
      uStd,
      {oX}
      uOX,  oxuTypes, oxuwndSettings,
      oxuAudio, oxuAudioBase,
      {ui}
      uiWidgets, wdguLabel, wdguDropDownList, wdguDivisor, wdguCheckbox;

IMPLEMENTATION

procedure revertSettings();
begin

end;

procedure addAudioTab();
var
   list: wdgTDropDownList;

begin
   wdgCheckbox.Add('Enabled').Check(oxAudio.Enabled);

   wdgLabel.Add('Backend', uiWidget.LastRect.BelowOf(0, -4), oxNullDimensions);
   list := wdgDropDownList.Add(uiWidget.LastRect.RightOf(0, 4), oxDimensions(90, 20));

   list.Add('Default');

   wdgDivisor.Add('');
end;


procedure init();
begin
   oxwndSettings.OnRevert.Add(@revertSettings);
   oxwndSettings.OnAddTabs.Add(@addAudioTab);
end;

INITIALIZATION
   ox.Init.Add('wnd:settings.audio', @init);

END.
