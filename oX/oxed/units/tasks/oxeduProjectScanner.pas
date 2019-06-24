{
   oxeduProjectScanner, project scanning
   Copyright (C) 2017. Dejan Boras

   Started On:    24.08.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectScanner;

INTERFACE

   USES
      sysutils, uStd, uLog, StringUtils, uFileUtils, uBuild,
      {app}
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuThreadTask, oxuRun,
      {oxed}
      uOXED, oxeduProject, oxeduProjectManagement, oxeduTasks, oxeduActions;

TYPE
   { oxedTProjectScannerTask }

   oxedTProjectScannerTask = class(oxedTTask)
      constructor Create(); override;
      procedure Run(); override;

      procedure TaskStart(); override;

      procedure ThreadStart(); override;
      procedure ThreadDone(); override;
   end;

   oxedTScannerFile = record
      FileName,
      Extension: StdString;
   end;

   oxedTProjectScannerFileProcedure = procedure(var f: oxedTScannerFile);
   oxedTProjectScannerFileProcedures = specialize TPreallocatedArrayList<oxedTProjectScannerFileProcedure>;

   { oxedTScannerOnFileProceduresHelper }

   oxedTScannerOnFileProceduresHelper = record helper for oxedTProjectScannerFileProcedures
      procedure Call(var f: oxedTScannerFile);
   end;

   { oxedTProjectScannerGlobal }

   oxedTProjectScannerGlobal = record
      Walker: TFileTraverse;
      Task: oxedTProjectScannerTask;

      OnStart,
      OnDone: TProcedures;
      OnFile: oxedTProjectScannerFileProcedures;

      procedure Run();
      class procedure Initialize(); static;
      class procedure RunTask(); static;
   end;

VAR
   oxedProjectScanner: oxedTProjectScannerGlobal;

IMPLEMENTATION

function scanFile(const fn: StdString): boolean; forward;

{ oxedTScannerOnFileProceduresHelper }

procedure oxedTScannerOnFileProceduresHelper.Call(var f: oxedTScannerFile);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](f);
   end;
end;

{ oxedTProjectScannerGlobal }

procedure oxedTProjectScannerGlobal.Run();
begin
   if(oxTThreadTask.IsRunning(Task)) then begin
      log.w('Project scanner already running');
      exit();
   end;

   Task.Start();
end;

class procedure oxedTProjectScannerGlobal.Initialize();
begin
   with oxedProjectScanner do begin
      TFileTraverse.Initialize(Walker);
      Walker.AddExtension('.pas');
      Walker.AddExtension('.inc');

      Walker.OnFile := @scanFile;

      Task := oxedTProjectScannerTask.Create();
      Task.EmitAllEvents();
   end;
end;

class procedure oxedTProjectScannerGlobal.RunTask();
begin
   oxedProjectScanner.Run();
end;

{ TBuildTask }

constructor oxedTProjectScannerTask.Create();
begin
   inherited;

   Name := 'Project Scanner';
end;

procedure oxedTProjectScannerTask.Run();
begin
   inherited Run;

   log.v('Project scan started ...');

   try
     oxedProjectScanner.Walker.Run();
   except
      on e: Exception do begin
         log.e('Project scanner failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;

   oxedProject.Session.InitialScanDone := true;
   log.v('Done project scan');
end;

procedure oxedTProjectScannerTask.TaskStart();
begin
   inherited TaskStart;

   oxedProject.Units.Dispose();
   oxedProject.IncludeFiles.Dispose();
end;

procedure oxedTProjectScannerTask.ThreadStart();
begin
   inherited;

   oxedProjectScanner.OnStart.Call();
end;

procedure oxedTProjectScannerTask.ThreadDone();
begin
   inherited;

   oxedProjectScanner.OnDone.Call();
end;

function scanFile(const fn: StdString): boolean;
var
   ext: StdString;
   f: oxedTScannerFile;

begin
   Result := true;

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fn) = 1) then
      exit;

   ext := ExtractFileExt(fn);
   f.FileName := fn;
   f.Extension := ext;

   oxedProjectScanner.OnFile.Call(f);

   if(oxedProjectScanner.Task.Terminated) then
      exit(false);

   if(oxedProjectScanner.Task.Terminated) then
      exit(false);
end;

procedure deinit();
begin
   FreeObject(oxedProjectScanner.Task);
end;

procedure projectClosed();
begin
   oxedProjectScanner.Walker.Stop();

   // wait to stop running
   while(oxedProjectScanner.Walker.Running) do begin
      oxRun.Sleep(1);
   end;
end;

procedure projectOpen();
begin
   projectClosed();

   oxedProjectScanner.Run();
end;

VAR
   oxedInitRoutines: oxTRunRoutine;

INITIALIZATION
   oxed.Init.Add(oxedInitRoutines, 'project_scanner', @oxedProjectScanner.Initialize, @deinit);

   TProcedures.InitializeValues(oxedProjectScanner.OnStart);
   TProcedures.InitializeValues(oxedProjectScanner.OnDone);
   oxedTProjectScannerFileProcedures.InitializeValues(oxedProjectScanner.OnFile);

   oxedProjectManagement.OnOpen.Add(@projectOpen);
   oxedProjectManagement.OnClosed.Add(@projectClosed);

   oxedActions.RESCAN := appActionEvents.SetCallback(@oxedProjectScanner.RunTask);

END.