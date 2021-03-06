{
   uiuSimpleWindowList, simple window list
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuSimpleWindowList;

INTERFACE

   USES
      uStd,
      {ox}
      oxuTypes,
      {ui}
      uiuWindow, uiuWindowTypes;

TYPE
   { uiTSimpleWindowListHelper }

   uiTSimpleWindowListHelper = record helper for uiTSimpleWindowList
      function FindLeftOf(x: loopint): uiTSimpleWindowList;
      function FindRightOf(x: loopint): uiTSimpleWindowList;
      function FindAbove(y: loopint): uiTSimpleWindowList;
      function FindBelow(y: loopint): uiTSimpleWindowList;

      procedure FindLeftOf(x: loopint; var list: uiTSimpleWindowList);
      procedure FindRightOf(x: loopint; var list: uiTsimpleWindowList);
      procedure FindAbove(y: loopint; var list: uiTsimpleWindowList);
      procedure FindBelow(y: loopint; var list: uiTsimpleWindowList);

      function FindFirstLeftOf(x: loopint): uiTWindow;
      function FindFirstRightOf(x: loopint): uiTWindow;

      {finds other windows in contact with the given one on the left side}
      procedure FindContactsLeft(wnd: uiTWindow; var result: uiTSimpleWindowList);
      {finds other windows in contact with the given one on the right side}
      procedure FindContactsRight(wnd: uiTWindow; var result: uiTSimpleWindowList);
      {finds other windows in contact with the given one on the left side}
      procedure FindContactsAbove(wnd: uiTWindow; var result: uiTSimpleWindowList);
      {finds other windows in contact with the given one on the right side}
      procedure FindContactsBelow(wnd: uiTWindow; var result: uiTSimpleWindowList);

      function GetLeftmostCoordinate(): loopint;

      {get total width (including non-client) of all windows}
      function GetTotalWidth(): loopint;
      {get total height (including non-client) of all windows}
      function GetTotalHeight(): loopint;

      {get total window width to the left from the specified x point}
      function GetLeftWidthFrom(px: loopint): loopint;
      {get total window width to the right from the specified x point}
      function GetRightWidthFrom(px: loopint): loopint;

      {get total window height above the specified y point}
      function GetAboveHeightFrom(py: loopint): loopint;
      {get total window height below the specified y point}
      function GetBelowHeightFrom(py: loopint): loopint;
   end;

   { uiTWindowListHelpers }

   uiTWindowListHelpers = record
      {find all windows lined up horizontally with us (including windows that can fit within ours vertically)}
      procedure FindHorizontalLineup(wnd: uiTWindow; var result: uiTSimpleWindowList; fitWithin: boolean = false);
      {find all windows lined up horizontally with us (including windows that can fit within ours horizontally)}
      procedure FindVerticalLineup(wnd: uiTWindow; var result: uiTSimpleWindowList; fitWithin: boolean = false);
      {find all windows lined up horizontally with us}
      function FindHorizontalLineup(wnd: uiTWindow; fitWithin: boolean = false): uiTSimpleWindowList;
      {find all windows lined up horizontally with us}
      function FindVerticalLineup(wnd: uiTWindow; fitWithin: boolean = false): uiTSimpleWindowList;
   end;

VAR
   uiWindowList: uiTWindowListHelpers;

IMPLEMENTATION

{ uiTSimpleWindowListHelper }

function uiTSimpleWindowListHelper.FindLeftOf(x: loopint): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindLeftOf(x, Result);
end;

function uiTSimpleWindowListHelper.FindRightOf(x: loopint): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindRightOf(x, Result);
end;

function uiTSimpleWindowListHelper.FindAbove(y: loopint): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindAbove(y, Result);
end;

function uiTSimpleWindowListHelper.FindBelow(y: loopint): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindBelow(y, Result);
end;

procedure uiTSimpleWindowListHelper.FindLeftOf(x: loopint; var list: uiTsimpleWindowList);
var
   i: loopint;

begin
   list.RemoveAll();

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x < x) then
         list.Add(List[i]);
   end;
end;

procedure uiTSimpleWindowListHelper.FindRightOf(x: loopint; var list: uiTsimpleWindowList);
var
   i: loopint;

begin
   list.RemoveAll();

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x > x) then
         list.Add(List[i]);
   end;
end;

procedure uiTSimpleWindowListHelper.FindAbove(y: loopint; var list: uiTsimpleWindowList);
var
   i: loopint;

begin
   list.RemoveAll();

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y > y) then
         list.Add(List[i]);
   end;
end;

procedure uiTSimpleWindowListHelper.FindBelow(y: loopint; var list: uiTsimpleWindowList);
var
   i: loopint;

begin
   list.RemoveAll();

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y < y) then
         list.Add(List[i]);
   end;
end;

function uiTSimpleWindowListHelper.FindFirstLeftOf(x: loopint): uiTWindow;
var
   i: loopint;

begin
   Result := nil;

   if(n > 0) then begin
      if(List[0].Position.x < x) then
         Result := List[0];

      for i := 0 to (n - 1) do begin
         if(Result <> nil) then
            if(List[i].Position.x > Result.Position.x) and (List[i].Position.x < x) then
               Result := List[i]
         else if(List[i].Position.x < x) then
            Result := List[i];
      end;
   end;
end;

function uiTSimpleWindowListHelper.FindFirstRightOf(x: loopint): uiTWindow;
var
   i: loopint;

begin
   Result := nil;

   if(n > 0) then begin
      if(List[0].Position.x > x) then
         Result := List[0];

      for i := 0 to (n - 1) do begin
         if(Result <> nil) then
            if(
            List[i].Position.x < Result.Position.x) and (List[i].Position.x > x) then
               Result := List[i]
         else if(List[i].Position.x > x) then
            Result := List[i];
      end;
   end;
end;

procedure uiTSimpleWindowListHelper.FindContactsLeft(wnd: uiTWindow; var result: uiTSimpleWindowList);
var
   i: loopint;

begin
   Result.RemoveAll();

   for i := 0 to n - 1 do begin
      if(List[i] <> wnd) then begin
         if(List[i].Position.x + List[i].GetTotalDimensions().w = wnd.Position.x) then
            Result.Add(List[i]);
      end;
   end;
end;

procedure uiTSimpleWindowListHelper.FindContactsRight(wnd: uiTWindow; var result: uiTSimpleWindowList);
var
   i: loopint;

begin
   Result.RemoveAll();

   for i := 0 to n - 1 do begin
      if(List[i] <> wnd) then begin
         if(List[i].Position.x = wnd.Position.x + wnd.GetTotalDimensions().w) then
            Result.Add(List[i]);
      end;
   end;
end;

procedure uiTSimpleWindowListHelper.FindContactsAbove(wnd: uiTWindow; var result: uiTSimpleWindowList);
var
   i: loopint;

begin
   Result.RemoveAll();

   for i := 0 to n - 1 do begin
      if(List[i] <> wnd) then begin
         if(List[i].Position.y - List[i].GetTotalDimensions().h = wnd.Position.y) then
            Result.Add(List[i]);
      end;
   end;
end;

procedure uiTSimpleWindowListHelper.FindContactsBelow(wnd: uiTWindow; var result: uiTSimpleWindowList);
var
   i: loopint;

begin
   Result.RemoveAll();

   for i := 0 to n - 1 do begin
      if(List[i] <> wnd) then begin
         if(wnd.Position.y - wnd.GetTotalDimensions().h = List[i].Position.y) then
            Result.Add(List[i]);
      end;
   end;
end;

function uiTSimpleWindowListHelper.GetLeftmostCoordinate(): loopint;
var
   i: loopint;

begin
   Result := 0;

   if(n > 0) then begin
      Result := List[0].Position.x;

      for i := 1 to n - 1 do begin
         if(List[i].Position.x < Result) then
            Result := List[i].Position.x;
      end;
   end;
end;

function uiTSimpleWindowListHelper.GetTotalWidth(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalWidth());
   end;
end;

function uiTSimpleWindowListHelper.GetTotalHeight(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalHeight());
   end;
end;

function uiTSimpleWindowListHelper.GetLeftWidthFrom(px: loopint): loopint;
var
   i,
   leftMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      leftMost := List[i].Position.x;

      if(px - leftMost> Result) then
         Result := px - leftMost;
   end;
end;

function uiTSimpleWindowListHelper.GetRightWidthFrom(px: loopint): loopint;
var
   i,
   rightMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      rightMost := List[i].Position.x + List[i].GetTotalWidth();

      if(rightMost - px > Result) then
         Result := rightMost - px;
   end;
end;

function uiTSimpleWindowListHelper.GetAboveHeightFrom(py: loopint): loopint;
var
   i,
   aboveMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      aboveMost := List[i].Position.y;

      if(aboveMost - py > Result) then
         Result := aboveMost - py;
   end;
end;

function uiTSimpleWindowListHelper.GetBelowHeightFrom(py: loopint): loopint;
var
   i,
   belowMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      belowMost := List[i].Position.y - List[i].GetTotalHeight();

      if(py - belowMost > Result) then
         Result := py - belowMost;
   end;
end;

{ uiTWindowListHelpers }

procedure uiTWindowListHelpers.FindHorizontalLineup(wnd: uiTWindow; var result: uiTSimpleWindowList; fitWithin: boolean);
var
   i: loopint;
   source,
   cur: uiTWindow;

   d,
   compareD: oxTDimensions;

begin
   Result.RemoveAll();

   source := uiTWindow(wnd.Parent);
   d := wnd.GetTotalDimensions();

   for i := 0 to (source.W.w.n - 1) do begin
      cur := uiTWindow(source.W.w[i]);

      if(cur <> nil) and (cur <> wnd) and (cur.IsVisible()) then begin
         compareD := cur.GetTotalDimensions();

         if(not fitWithin) and (compareD.h = d.h) and (cur.Position.y = wnd.Position.y) then
            Result.Add(cur)
         else if(fitWithin) and (cur.Position.y <= wnd.Position.y) and (cur.Position.y - compareD.h >= wnd.Position.y - d.h) then
            Result.Add(cur);
      end;
   end;
end;

procedure uiTWindowListHelpers.FindVerticalLineup(wnd: uiTWindow; var result: uiTSimpleWindowList; fitWithin: boolean);
var
   i: loopint;
   source,
   cur: uiTWindow;

   d,
   compareD: oxTDimensions;

begin
   Result.RemoveAll();

   source := uiTWindow(wnd.Parent);
   d := wnd.GetTotalDimensions();
   for i := 0 to (source.W.w.n - 1) do begin
      cur := uiTWindow(source.W.w[i]);
      compareD := cur.GetTotalDimensions();

      if(cur <> nil) and (cur <> wnd) and (cur.IsVisible()) then begin
         if(not fitWithin) and (compareD.w = d.w) and (cur.Position.x = wnd.Position.x) then
            Result.Add(cur)
         else if(fitWithin) and (cur.Position.x >= wnd.Position.x) and (cur.Position.x + compareD.w <= wnd.Position.x + d.w) then
            Result.Add(cur);
      end;
   end;
end;

function uiTWindowListHelpers.FindHorizontalLineup(wnd: uiTWindow; fitWithin: boolean): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindHorizontalLineup(wnd, Result, fitWithin);
end;

function uiTWindowListHelpers.FindVerticalLineup(wnd: uiTWindow; fitWithin: boolean): uiTSimpleWindowList;
begin
   uiTSimpleWindowList.Initialize(Result);
   FindVerticalLineup(wnd, Result, fitWithin);
end;

END.
