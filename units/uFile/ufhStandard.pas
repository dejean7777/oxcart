{
   ufhStandard
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT ufhStandard;

INTERFACE

   USES uStd, uFileUtils, uFile;
   
VAR
   stdfHandler: TFileHandler;
   stdfHandlerBuffered: TFileHandler;

   stdStdFileHandler: TFileStdHandler;

{Copy from a source file to destination. Returns error code.}
function fCopy(const src: StdString; var dst: TFile): longint;
function fCopy(var src: TFile; const dst: StdString; size: fileint): longint;

IMPLEMENTATION

{ ... FILE HANDLERS ... }
TYPE
   stdPData = ^stdTData;
   stdTData = record
      f: file;
   end;

{STANDARD FILE HANDLER}
procedure stdMake(var f: TFile);
begin
   new(stdPData(f.pData));

   if(f.pData <> nil) then
      Zero(f.pData^, SizeOf(stdTData))
   else
      f.RaiseError(eNO_MEMORY);
end;

procedure stdDispose(var f: TFile);
begin
   dispose(stdPData(f.pData));
end;

procedure stdOpen(var f: TFile);
var
   data: stdPData absolute f.pData;

begin
   if(data <> nil) then begin
      UTF8Assign(data^.f, f.fn);

      Reset(data^.f, 1);
      if(f.GetIOError() = 0) then begin
         f.fSize        := FileSize(data^.f);
         f.fSizeLimit   := 0;

         f.AutoSetBuffer();
      end else
         f.RaiseError(feOPEN);
   end;
end;

procedure stdNew(var f: TFile);
var
   data: stdPData absolute f.pData;

begin
   if(data <> nil) then begin
      Assign(data^.f, f.fn);

      Rewrite(data^.f, 1);
      if(f.GetIOError() = 0) then begin
         f.AutoSetBuffer();
      end else
         f.RaiseError(feNEW);
   end;
end;

procedure stdClose(var f: TFile);
var
   data: stdPData absolute f.pData;

begin
   if(data <> nil) then begin
      Close(data^.f);

      if(f.GetIOError() <> 0) then
         f.RaiseError(eIO);
   end;
end;

procedure stdFlush(var f: TFile);
var
   data: stdPData absolute f.pData;

begin
   blockwrite(data^.f, f.bData^, f.bPosition);

   if(f.GetIOError() <> 0) then
      f.RaiseError(eIO);
end;

function stdReadBfrd(var f: TFile; out buf; count: fileint): fileint;
var
   data: stdPData absolute f.pData;
   bRead,
   bLeft,
   rLeft: fileint;

begin
   bLeft := f.bLimit - f.bPosition;
   bRead := 0;

   {if enough data is in the buffer}
   if(count <= bLeft) then begin
      {$PUSH}{$HINTS OFF} // buf does not need to be initialized, since we're moving data into it
      move((f.bData + f.bPosition)^, buf, count);
      {$POP}
      inc(f.bPosition, count);

      Result := count;
   end else begin
      {move what can be moved from the buffer}
      if(bLeft > 0) then begin
         move((f.bData + f.bPosition)^, buf, bLeft);
         f.bPosition    := 0;
         f.bLimit       := 0;
      end;

      {figure out what is left}
      rLeft := (count-bLeft);

      {fill the buffer first and then read from buffer}
      if(rLeft <= f.bSize) then begin
         {$PUSH}{$HINTS OFF}blockread(data^.f, f.bData^, f.bSize, bRead);{$POP}
         if(f.GetIOError() = 0) then begin
            move(f.bData^, (@buf + bLeft)^, rLeft);
            f.bPosition    := rLeft;
            f.bLimit       := bRead;
            Result         := count;
         end else begin
            f.RaiseError(eIO);
            Result := -bLeft;
         end;
      {read directly}
      end else begin
         blockread(data^.f, (@buf + bLeft)^, rLeft, bRead);
         if(f.GetIOError() = 0) then
            Result := bLeft + bRead
         else begin
            f.RaiseError(eIO);
            Result := -(bLeft + bRead);
         end;
      end;
   end;
end;

function stdRead(var f: TFile; out buf; count: fileint): fileint;
var
   data: stdPData absolute f.pData;
   bRead: fileint;

begin
   bRead := 0;

   {$PUSH}{$HINTS OFF}blockread(data^.f, buf, count, bRead);{$POP}

   if(f.GetIOError() = 0) then
      Result := bRead
   else begin
      f.RaiseError(eIO);
      exit(-bRead);
   end;
end;

function stdWriteBfrd(var f: TFile; var buf; count: fileint): fileint;
var
   data: stdPData absolute f.pData;
   bWrite: fileint;

procedure movetobuf(); inline;
begin
   move(buf, (f.bData + f.bPosition)^, count);
   inc(f.bPosition, count);
end;

begin
   {store into buffer}
   if(f.bPosition + count < f.bSize - 1) then begin
      movetobuf();
      Result := count;
   {write out}
   end else begin
      {write out buffer}
      bWrite := 0;
      blockwrite(data^.f, f.bData^, f.bPosition, bWrite);
      f.bPosition := 0;

      {store data into buffer if it can fit}
      if(count < f.bSize) then begin
         movetobuf();
         Result := count;
      {otherwise write contents directly to file}
      end else begin
         blockwrite(data^.f, buf, count, bWrite);

         if(f.GetIOError() = 0) then
            Result := bWrite
         else begin
            f.RaiseError(eIO);
            exit(-bWrite);
         end
      end;
   end;
end;

function stdWrite(var f: TFile; var buf; count: fileint): fileint;
var
   data: stdPData absolute f.pData;
   bWrite: fileint;

begin
   bWrite := 0;
   blockwrite(data^.f, buf, count, bWrite);

   if(f.GetIOError() = 0) then
      Result := bWrite
   else begin
      f.RaiseError(eIO);
      exit(-bWrite);
   end
end;

procedure stdSeek(var f: TFile; pos: fileint);
var
   data: stdPData absolute f.pData;

begin
   if(data <> nil) then begin
      seek(data^.f, pos);

      if(f.GetIOError() <> 0) then
         f.RaiseError(eIO);
   end;
end;

procedure stdOnBufferSet(var f: TFile);
begin
   {if buffering set}
   if(f.bSize > 0) then
      f.pHandler := @stdfHandlerBuffered
   {if buffering not set}
   else
      f.pHandler := @stdfHandler;
end;

function getCopyBuffer(): pbyte;
var
   buf: pbyte = nil;

begin
   GetMem(buf, fFile.CopyBufferSize);
   Result := buf;
end;

function fCopy(const src: StdString; var dst: TFile): longint;
var
   buf: pbyte;
   f: file;
   bread: fileint;
   total: fileint;

   procedure cleanup();
   begin
      XFreeMem(buf);
      Close(f);
      IOResult();
   end;

begin
   bread    := 0;
   total    := 0;
   Result   := eNONE;

   buf := getCopyBuffer();
   if(buf <> nil) then begin
      {open source file}
      Assign(f, src);
      Reset(f, 1);

      if(ioerror() = 0) then begin
         Seek(f, 0);
         {copy}
         repeat
            blockread(f, buf^, fFile.CopyBufferSize, bread);
            total := total + bread;

            if(ioerror() = 0) then begin
               if(bread > 0) then begin
                  dst.Write(buf^, bread);

                  if(dst.error <> 0) then begin
                     cleanup();
                     exit;
                  end;
               end else
                  break;
            end else begin
               cleanup();
               exit(eIO);
            end;
         until eof(f);

         cleanup();
      end else begin
         cleanup();
         exit(eIO);
      end;
   end;
end;

function fCopy(var src: TFile; const dst: StdString; size: fileint): longint;
var
   f: file;
   buf: pbyte;
   bsize: fileint;
   siz, rd: fileint;

   procedure cleanup();
   begin
      XFreeMem(buf);
      Close(f); IOResult();
   end;

begin
   buf      := getCopyBuffer();
   Result   := eNONE;

   if(src.error = 0) then begin
      {create file}
      assign(f, dst);
      rewrite(f, 1);

      if(ioerror() = 0) then begin
         siz := size;
         bsize := fFile.CopyBufferSize;

         {copy}
         repeat
            rd := bsize;
            if(rd > siz) then
               rd := siz;

            src.Read(buf^, rd);
            if(src.error = 0) then begin
               blockwrite(f, buf^, rd);

               if(ioerror() <> 0) then begin
                  cleanup();
                  exit(eIO);
               end;

               dec(siz, rd);
            end else break;
         until (siz <= 0);
      end else
         Result := eIO;

      {done}
      cleanup();
   end;
end;

INITIALIZATION
   {standard file handler}
   stdfHandler                := fFile.DummyHandler;
   stdfHandler.Name           := 'std';
   stdfHandler.make           := fTFileProcedure(@stdMake);
   stdfHandler.dispose        := fTFileProcedure(@stdDispose);
   stdfHandler.open           := fTFileProcedure(@stdOpen);
   stdfHandler.new            := fTFileProcedure(@stdNew);
   stdfHandler.read           := fTReadFunc     (@stdRead);
   stdfHandler.write          := fTWriteFunc    (@stdWrite);
   stdfHandler.close          := fTFileProcedure(@stdClose);
   stdfHandler.flush          := fTFileProcedure(@stdFlush);
   stdfHandler.seek           := fTSeekProc     (@stdSeek);
   stdfHandler.onbufferset    := fTFileProcedure(@stdOnBufferSet);
   stdfHandler.useBuffering   := true;

   stdfHandlerBuffered        := stdfHandler;
   stdfHandlerBuffered.read   := fTReadFunc(@stdReadBfrd);
   stdfHandlerBuffered.write  := fTWriteFunc(@stdWriteBfrd);

   stdStdFileHandler.handler  := @stdfHandler;
   fFile.Handlers.Std := @stdStdFileHandler;
END.
