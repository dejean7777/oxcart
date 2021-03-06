{
   oxuModelFile, model file loader and writer support
   Copyright (C) 2009. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuModelFile;

INTERFACE

   USES uStd,
      {uFile}
      uFile,
      {oX}
      uOX, oxuRunRoutines, oxuFile, oxuModel;

TYPE
   oxPModelFileOptions = ^oxTModelFileOptions;

   { oxTModelFileOptions }

   oxTModelFileOptions = record
      {convert quads to triangles}
      ConvertQuads: boolean;
      {model object which to store, or which to load}
      Model: oxTModel;
   end;

   { oxTModelFile }

   oxTModelFile = object(oxTFileRW)
      class procedure Init(out options: oxTModelFileOptions); static;

      function Read(const name: string): oxTModel;
      function Read(var f: TFile; const fn: string = '.oxmdl'): oxTModel;

      function OnRead(var data: oxTFileRWData): loopint; virtual;
   end;

VAR
   oxfModel: oxTModelFile;

IMPLEMENTATION

{ oxTModelFile }

class procedure oxTModelFile.Init(out options: oxTModelFileOptions);
begin
   ZeroOut(options, SizeOf(options));
   options.ConvertQuads := true;
end;

function oxTModelFile.Read(const name: string): oxTModel;
var
   options: oxTModelFileOptions;

begin
   Init(options);

   inherited Read(name, @options);

   Result := options.Model;
end;

function oxTModelFile.Read(var f: TFile; const fn: string): oxTModel;
var
   options: oxTModelFileOptions;

begin
   Init(options);

   inherited Read(f, fn, @options);

   Result := options.Model;
end;

function oxTModelFile.OnRead(var data: oxTFileRWData): loopint;
var
   options: oxPModelFileOptions;

begin
   options := data.Options;

  if(options^.Model = nil) then
      options^.Model := oxModel.Instance();

   data.Handler^.CallHandler(@data);

   Result := data.GetError();
end;

INITIALIZATION
   oxfModel.Create();

END.
