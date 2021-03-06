{
   oxuSysInfo, provides system information
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSysInfo;

INTERFACE

   USES
      {$IFNDEF OX_LIBRARY}
      appuSysInfo
      {$IFDEF OX_LIBRARY_SUPPORT}, appuSysInfoBase, oxuGlobalInstances{$ENDIF}
      {$ELSE}
      uLog,
      uApp, appuSysInfoBase,
      uOX, oxuRunRoutines, oxuGlobalInstances
      {$ENDIF};

IMPLEMENTATION

{$IFDEF OX_LIBRARY}
procedure initialize();
var
   instance: appPSystemInformation;

begin
   instance := oxExternalGlobalInstances^.FindInstancePtr('appTSystemInformation');

   if(instance <> nil) then
      appSI := instance^
end;
{$ENDIF}

INITIALIZATION
   {$IFDEF OX_LIBRARY_SUPPORT}
   oxGlobalInstances.Add('appTSystemInformation', @appSI);
   {$ENDIF}

   {$IFDEF OX_LIBRARY}
   app.InitializationProcs.Add('ox.system_information', @initialize);
   {$ENDIF}

END.
