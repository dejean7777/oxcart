{
   oxeduBuildPlatform, handling build specifics for various platforms
   Copyright (C) 2017. Dejan Boras

   Started On:    19.07.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduPlatform;

INTERFACE

   USES
      uStd, udvars,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED;

TYPE
   oxedTPlatformArchitecture = record
      Name,
      Architecture: string;
   end;

   oxedTPlatformArchitectureList = specialize TSimpleList<oxedTPlatformArchitecture>;

   { oxedTPlatform }
   oxedTPlatform = class
      {is this platform enabled}
      Enabled: boolean;

      {platform name}
      Name,
      {platform id, should match the fpc compiler define for the platform (windows, linux, android, darwin)}
      Id: string;

      Architectures: oxedTPlatformArchitectureList;

      GlyphName: string;
      GlyphCode: longword;

      {compiler symbols to use when building}
      CompilerSymbols: TPreallocatedStringArrayList;

      constructor Create(); virtual;

      procedure AddArchitecture(archName, arch: string);
   end;

   oxedTPlatformsList = specialize TSimpleList<oxedTPlatform>;

   { oxedTPlatforms }

   oxedTPlatforms = record
      List: oxedTPlatformsList;
      CurrentId: string;

      procedure Initialize();
      procedure DeInitialize();

      procedure Add(platform: oxedTPlatform);
      function FindById(const id: string): oxedTPlatform;
      procedure Dispose();
   end;

VAR
   oxedPlatforms: oxedTPlatforms;
   {current platform on which the editor is running}
   oxedPlatform: oxedTPlatform;

IMPLEMENTATION

{ oxedTPlatform }

constructor oxedTPlatform.Create();
begin
   Name := 'Unknown';
   id := 'unknown';

   Architectures.InitializeValues(Architectures);
end;

procedure oxedTPlatform.AddArchitecture(archName, arch: string);
var
   a: oxedTPlatformArchitecture;

begin
   a.Name := archName;
   a.Architecture := arch;

   Architectures.Add(a);
end;

{ oxedTPlatforms }

procedure oxedTPlatforms.Initialize;
begin
   CurrentId := 'none';

   {$IFDEF WINDOWS}
   CurrentId := 'windows';
   {$ENDIF}
   {$IFDEF LINUX}
   CurrentId := 'linux';
   {$ENDIF}
   {$IFDEF ANDROID}
   CurrentId := 'android';
   {$ENDIF}
   {$IFDEF DARWIN}
   CurrentId := 'darwin';
   {$ENDIF}

   oxedPlatform := FindById(CurrentId);
   if(oxedPlatform = nil) then
      oxedPlatform := oxedTPlatform.Create();
end;

procedure oxedTPlatforms.DeInitialize;
begin
   if(oxedPlatform <> nil) and (oxedPlatform.Id = 'unknown') then
      FreeObject(oxedPlatform);
end;

procedure oxedTPlatforms.Add(platform: oxedTPlatform);
begin
   List.Add(platform);
end;

function oxedTPlatforms.FindById(const id: string): oxedTPlatform;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].id = id) then
         exit(List.List[i]);
   end;

   Result := nil;
end;

procedure oxedTPlatforms.Dispose();
var
   i: loopint;

begin
   for i := 0 to (List.n - 1) do begin
      FreeObject(List.List[i]);
   end;

   List.Dispose();
end;

procedure deinit();
begin
   oxedPlatforms.Dispose();
end;

VAR
   platformEnabled: boolean;
   dvPlatformEnabled: TDVar;
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   dvgOXED.Add(dvPlatformEnabled, 'platform_enabled', dtcBOOL, @platformEnabled);

   oxed.Init.dAdd(oxedInitRoutines, 'platforms', @deinit);

   oxedPlatforms.List.InitializeValues(oxedPlatforms.List);

END.
