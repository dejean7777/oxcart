{
   wdguEmpty, empty widget
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT wdguEmpty;

INTERFACE

   USES
      uStd,
      {oX}
      oxuTypes,
      {ui}
      uiuWidget, uiWidgets, uiuRegisteredWidgets,
      wdguBase;

TYPE
   wdgTEmptyGlobal = object(specialize wdgTBase<uiTWidget>)
   end;

VAR
   wdgEmpty: wdgTEmptyGlobal;

IMPLEMENTATION

INITIALIZATION
   wdgEmpty.Create('empty');

END.
