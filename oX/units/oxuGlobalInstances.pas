{
   oxuGlobalInstances, handles global instances
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuGlobalInstances;

INTERFACE

   USES
      uStd, uLog;

TYPE
   oxTGlobalInstanceMethod = function(): TObject;

   oxPGlobalInstance = ^oxTGlobalInstance;
   oxTGlobalInstance = record
      InstanceType: TClass;
      InstanceName: String;
      InstanceMethod: oxTGlobalInstanceMethod;
      Location: pointer;
      Allocate,
      CopyOverReference,
      External: boolean;
   end;

   oxTGlobalInstancesList = specialize TSimpleList<oxTGlobalInstance>;

   oxTGlobalInstancesReferenceChangeCallback = procedure(const instanceType: StdString; newReference: Pointer);
   oxTGlobalInstancesReferenceChangeCallbacks = specialize TSimpleList<oxTGlobalInstancesReferenceChangeCallback>;

   { oxTGlobalInstancesReferenceChangeCallbacksHelper }

   oxTGlobalInstancesReferenceChangeCallbacksHelper = record helper for oxTGlobalInstancesReferenceChangeCallbacks
      procedure Call(const instanceType: StdString; newReference: pointer);
   end;


   oxPGlobalInstances = ^oxTGlobalInstances;

   { oxTGlobalInstances }

   oxTGlobalInstances = object
      Name: StdString;
      List: oxTGlobalInstancesList;
      OnReferenceChange: oxTGlobalInstancesReferenceChangeCallbacks;
      {should we log instances we cannot find}
      LogNotFound: boolean;

      constructor Create();

      {add class based instance}
      function Add(instanceType: TClass; location: pointer; method: oxTGlobalInstanceMethod = nil): oxPGlobalInstance;
      {add instance of other type (record)}
      function Add(const instanceName: StdString; location: pointer): oxPGlobalInstance;

      procedure Initialize();
      procedure Deinitialize();

      {find an instance reference by classname, and return the index, or -1 if nothing found}
      function FindReference(const cName: StdString): loopint;
      {find an instance reference by classname, and return the instance reference, or -1 if nothing found}
      function FindInstance(const cName: StdString): TObject;
      {find an instance reference by type name, and return pointer to the instance, or -1 if nothing found}
      function FindInstancePtr(const typeName: StdString): pointer;

      procedure CopyOver(target: oxTGlobalInstances);
      procedure CopyOverReferences(target: oxTGlobalInstances);
   end;

VAR
   oxGlobalInstances: oxTGlobalInstances;
   oxExternalGlobalInstances: oxPGlobalInstances;

IMPLEMENTATION

{ oxTGlobalInstancesReferenceChangeCallbacksHelper }

procedure oxTGlobalInstancesReferenceChangeCallbacksHelper.Call(const instanceType: StdString; newReference: pointer);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](instanceType, newReference);
   end;
end;

{ oxTGlobalInstances }

constructor oxTGlobalInstances.Create();
begin
   oxTGlobalInstancesList.Initialize(List);
   OnReferenceChange.Initialize(OnReferenceChange);
   LogNotFound := true;

   {$IFNDEF OX_LIBRARY}
   Name := 'global';
   {$ELSE}
   Name := 'library';
   {$ENDIF}
end;

function oxTGlobalInstances.Add(instanceType: TClass; location: pointer; method: oxTGlobalInstanceMethod): oxPGlobalInstance;
var
   instance: oxTGlobalInstance;

begin
   ZeroOut(instance, SizeOf(instance));
   instance.InstanceType := instanceType;
   instance.InstanceName := instanceType.ClassName;
   instance.Location := location;
   instance.Allocate := true;
   instance.InstanceMethod := method;

   List.Add(instance);

   result := List.GetLast();
end;

function oxTGlobalInstances.Add(const instanceName: StdString; location: pointer): oxPGlobalInstance;
var
   instance: oxTGlobalInstance;

begin
   ZeroOut(instance, SizeOf(instance));
   instance.InstanceName := instanceName;
   instance.Location := location;

   List.Add(instance);

   result := List.GetLast();
end;

procedure oxTGlobalInstances.Initialize();
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].Allocate) and (TObject(List.List[i].Location^) = nil) then begin
         if(List.List[i].InstanceMethod <> nil) then
            TObject(List.List[i].Location^) := List.List[i].InstanceMethod()
         else
            TObject(List.List[i].Location^) := List.List[i].InstanceType.Create();
      end;
   end;
end;

procedure oxTGlobalInstances.Deinitialize();
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].Allocate) and (not List.List[i].External) then
         FreeObject(List.List[i].Location^);
   end;
end;

function oxTGlobalInstances.FindReference(const cName: StdString): loopint;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].InstanceName = cName) then
        exit(i);
   end;

   log.w('Could not find global reference ' + cName + ' in ' + Name);

   Result := -1;
end;

function oxTGlobalInstances.FindInstance(const cName: StdString): TObject;
var
   ref: longint;
   instance: oxPGlobalInstance;

begin
   ref := FindReference(cName);

   if(ref > -1) then begin
      instance := @List.List[ref];

      exit(TObject(instance^.Location^));
   end;

   log.w('Could not find global reference ' + cName + ' in ' + Name);

   Result := nil;
end;

function oxTGlobalInstances.FindInstancePtr(const typeName: StdString): pointer;
var
   ref: longint;
   instance: oxPGlobalInstance;

begin
   ref := FindReference(typeName);

   if(ref > -1) then begin
      instance := @List.List[ref];

      exit(instance^.Location);
   end;

   Result := nil;
end;

procedure oxTGlobalInstances.CopyOver(target: oxTGlobalInstances);
var
   i: loopint;

begin
   target.List.Allocate(List.n);

   for i := 0 to List.n - 1 do begin
      target.List.List[i] := List.List[i];
   end;
end;

procedure oxTGlobalInstances.CopyOverReferences(target: oxTGlobalInstances);
var
   i,
   ref: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].CopyOverReference) then begin
         ref := target.FindReference(List.List[i].InstanceType.ClassName);

         if(ref > -1) then begin
            target.List.List[ref].External := true;
            TObject(target.List.List[ref].Location^) := TObject(List.List[i].Location^);

            target.OnReferenceChange.Call(List.List[i].InstanceType.ClassName, pointer(target.List.List[ref].Location^));
         end;
      end;
   end;
end;

INITIALIZATION
   oxGlobalInstances.Create();

   oxGlobalInstances.Add('oxTGlobalInstances', @oxGlobalInstances)^.Allocate := False;

END.
