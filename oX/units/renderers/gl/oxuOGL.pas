{
   oxuOGL, OpenGL
   Copyright (c) 2011. Dejan Boras

   Started On:    10.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuOGL;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, uLog, StringUtils, ParamUtils,
      {ox}
      oxuTypes, oxuTexture,
      {$IFDEF X11}GLX, oxuX11Platform{$ENDIF}
      {$IFDEF WINDOWS}windows, oxuWindowsOS{$ENDIF}
      {$IFDEF COCOA}CocoaAll, oxuCocoaPlatform{$ENDIF};

CONST
   oglNONE = {$IFNDEF GLES}GL_NONE{$ELSE}GL_ZERO{$ENDIF};

TYPE
   oglTProfile = (
      oglPROFILE_ANY,
      oglPROFILE_COMPATIBILITY,
      oglPROFILE_CORE,
      {returned if invalid or unknown profile used/given}
      oglPROFILE_UNKNOWN
   );

   oglTRenderingContext = {$IFDEF WINDOWS}HGLRC{$ENDIF}{$IFDEF COCOA}NSOpenGLContext{$ENDIF}{$IFDEF X11}GLXContext{$ENDIF};

   { oglTVersion }

   oglTVersion = record
      Major,
      Minor,
      Revision: longword;
      Profile: oglTProfile;

      function GetVersionString(): string;
      function RequiresContextAttribs(): boolean;
   end;

   { oglTSettings }

   oglTSettings = record
      {target version}
      Version: oglTVersion;

      class function GetProfileFromString(const profileString: string): oglTProfile; static;
      class function GetProfileString(p: oglTProfile): string; static;
      function GetString(): string;
   end;

   {$IFDEF X11}
   {glx attributes array}
   TXAttrIntPreallocatedArray = specialize TPreallocatedArrayList<XAttrInt>;
   {$ENDIF}

   { oglTWindow }

   oglTWindow = class({$IFDEF WINDOWS}winosTWindow{$ENDIF}{$IFDEF X11}x11TWindow{$ENDIF}{$IFDEF COCOA}cocoaTWindow{$ENDIF})
      gl,
      glDefault,
      glRequired: oglTSettings;

      {$IFDEF X11}
      fbConfig: TGLXFBConfig;
      glxAttribs: TXAttrIntPreallocatedArray;
      {$ENDIF}

      glProperties: record
         Warned32NotSupported: boolean;
      end;

      Info: record
         Renderer,
         Vendor,
         Version: string;
         iVersion: longword;

         GLSL: record
            Version: string;
            Major,
            Minor,
            Compact: longword;
         end;
      end;

      Limits: record
         MaxTextureSize,
         MaxLights,
         MaxClipPlanes,
         MaxProjectionStackDepth,
         MaxModelViewStackDepth,
         MaxTextureStackDepth: GLuint;
      end;

      constructor Create; override;

      function Downgrade32(): boolean;
   end;

   oxglTTextureFilter = record
      min,
      mag: GLuint;
   end;

   { OPENGL }

   oglTBlendFunc       = array[0..1] of GLenum;

   { oglTGlobal }

   oglTGlobal = record
      {raise an opengl error (in case of an error, stackSkip tells how many stack entries to skip reporting on)}
      class function eRaise(out glerror: GLenum; stackSkip: longint = 0): longint; static;
      class function eRaise(stackSkip: longint = 1): longint; static;
      {return a string for the specified OPENGL error}
      class function ErrorString(err: GLenum; includeCode: boolean = true): string; static;

      class procedure InitializePre(); static;
      class procedure ActivateRenderingContext(); static;

      class function ContextRequired(const settings: oglTSettings): boolean; static;

      { INFORMATION }
      {get a string from OpenGL}
      class function GetString(which: GLuint): string; static;
      {get OpenGL version information from a string}
      class procedure GetVersion(const versionString: string; out major, minor, revision: longword; out profile: oglTProfile); static;
      {get OpenGL version information}
      class procedure GetVersion(var major, minor, revision: longword; out profile: oglTProfile); static;
      {get glsl version from string}
      class procedure GetGLSLVersion(const versionString: string; out major, minor, compact: longword); static;
      {compare two OpenGL versions (source and target), 0 is equal, -1 is target lower, +1 is target higher}
      class function CompareVersions(sMajor, sMinor, tMajor, tMinor: longword): longint; static;
      class function CompareVersions(const s, t: oglTVersion): longint; static;

      class function GetShaderTypeString(shaderType: GLenum): string; static;
      function ValidRC(rc: oglTRenderingContext): boolean;

      { INITIALIZATION }

      {initialize OpenGL values to default}
      class procedure InitState(); static;
   end;

CONST
   oxglTexRepeat: array[0..longint(high(oxTTextureRepeat))] of GLenum = (
      GL_REPEAT,
      {$IFNDEF GLES}GL_MIRRORED_REPEAT{$ELSE}GL_REPEAT{$ENDIF},
      GL_CLAMP_TO_EDGE,
      {$IFNDEF GLES}GL_CLAMP_TO_BORDER{$ELSE}GL_CLAMP_TO_EDGE{$ENDIF}
   );

   oxglTexFilters: array[0..longint(high(oxTTextureFilter))] of oxglTTextureFilter = (
      ( {NONE}
         min: GL_NEAREST;
         mag: GL_NEAREST
      ),
      ( {BILINEAR}
         min: GL_NEAREST;
         mag: GL_NEAREST
      ),
      ( {TRILINEAR}
         min: GL_NEAREST;
         mag: GL_NEAREST
      ),
      ( {ANISOTROPIC}
         min: GL_NEAREST;
         mag: GL_NEAREST
      )
   );


   oglRenderingContextNull: oglTRenderingContext = {$IFDEF WINDOWS}0{$ENDIF}{$IFDEF X11}nil{$ENDIF}{$IFDEF COCOA}nil{$ENDIF};

   oglDefaultSettings: oglTSettings = (
      Version: (
         Major:      {$IFNDEF GLES}1{$ELSE}1{$ENDIF};
         Minor:      {$IFNDEF GLES}5{$ELSE}1{$ENDIF};
         Revision:   0;
         Profile:    oglPROFILE_COMPATIBILITY;
      );
   );

   oglRequiredSettings: oglTSettings = (
      Version: (
         Major:         {$IFNDEF GLES}1{$ELSE}1{$ENDIF};
         Minor:         {$IFNDEF GLES}2{$ELSE}1{$ENDIF};
         Revision:      0; {revision is not checked as requirement}
         Profile:       oglPROFILE_COMPATIBILITY;
      );
   );

   oglContextSettings: oglTSettings = (
      Version: (
         Major:         1;
         Minor:         2;
         Revision:      0;
         Profile:       oglPROFILE_COMPATIBILITY;
      );
   );

VAR
   {OPENGL INFRMATION}
   ogl: oglTGlobal;

IMPLEMENTATION

{ oglTWindow }

constructor oglTWindow.Create;
begin
   inherited;

   glDefault := oglDefaultSettings;
   glRequired := oglRequiredSettings;

   {$IFDEF X11}
   glxAttribs.Initialize(glxAttribs);
   {$ENDIF}
end;

function oglTWindow.Downgrade32(): boolean;
begin
   if(glRequired.Version.RequiresContextAttribs()) then begin
      RaiseError(eERR, 'gl > gl 3.2+ not supported (WGL_ARB_create_context_profile extension misisng)');
      Result := false;
   end else begin
      gl.Version.Major := 3;
      gl.Version.Minor := 1;
      gl.Version.Profile := oglPROFILE_COMPATIBILITY;

      {downgrade version}
      if(not glProperties.Warned32NotSupported) then begin
         glProperties.Warned32NotSupported := true;
         log.w('gl > gl 3.2+ not supported, will downgrade to ' + gl.GetString());
      end;
   end;

   Result := true;
end;

{ oglTSettings }

class function oglTSettings.GetProfileFromString(const profileString: string): oglTProfile;
var
   lProfile: string;

begin
   lProfile := LowerCase(profileString);

   if(lProfile = 'core') then
      Result := oglPROFILE_CORE
   else if(lProfile = 'compatibility') then
      Result := oglPROFILE_CORE
   else if((lProfile = 'any') or (lProfile = '')) then
      Result := oglPROFILE_ANY
   else
      Result := oglPROFILE_UNKNOWN;
end;

class function oglTSettings.GetProfileString(p: oglTProfile): string; static;
begin
   if(p = oglPROFILE_ANY) then
      Result := 'any'
   else if (p = oglPROFILE_COMPATIBILITY) then
      Result := 'compatibility'
   else if (p = oglPROFILE_CORE) then
      Result := 'core'
   else
      Result := '';
end;

function oglTSettings.GetString(): string;
var
   profileString: string = '';

begin
   if(Version.Major >= 3) then
      profileString := ' (' + GetProfileString(Version.Profile) + ')';

   Result := Version.GetVersionString() + profileString;
end;

{ oxoglTVersion }

function oglTVersion.GetVersionString(): string;
begin
   Result := sf(Major) + '.' + sf(Minor);
end;

function oglTVersion.RequiresContextAttribs: boolean;
begin
   Result := (Major > 3) or ((Major = 3) and (Minor > 1));
end;

{ ERROR HANDLING }

class function oglTGlobal.eRaise(out glerror: GLenum; stackSkip: longint): longint;
var
   errorCount: loopint;
   tempError: GLenum;

begin
   tempError := 0;
   errorCount := 0;

   repeat
      glerror := tempError;
      tempError := glGetError();

      if(tempError <> 0) then
         inc(errorCount);
   until (tempError = GL_NO_ERROR) or (errorCount >= 64);

   Result := glerror;

   {$IFDEF OX_DEBUG}
   if(glerror <> 0) then begin
      if(errorCount = 0) then
         log.w('gl > error ' + ErrorString(glerror))
      else if(errorCount < 64) then
         log.w('gl > error ' + ErrorString(glerror) + ', count: ' + sf(errorCount))
      else
         log.w('gl > error ' + ErrorString(glerror) + ', count: ' + sf(errorCount) + ', too many errors');

      if(stackSkip > -1) then
         log.e(DumpCallStack(stackSkip));
   end;
   {$ENDIF}
end;

class function oglTGlobal.eRaise(stackSkip: longint): longint;
var
   glerror: GLenum;

begin
   Result := eRaise(glerror, stackSkip);
end;

class function oglTGlobal.ErrorString(err: GLenum; includeCode: boolean = true): string;
begin
   Result := '';

   if(includeCode) then
      Result := '(' + sf(err) + ') ';

   case err of
      GL_INVALID_VALUE:       Result := Result + 'GL_INVALID_VALUE';
      GL_INVALID_OPERATION:   Result := Result + 'GL_INVALID_OPERATION';
      GL_INVALID_ENUM:        Result := Result + 'GL_INVALID_ENUM';
      {$IFNDEF GLES}
      GL_INVALID_FRAMEBUFFER_OPERATION: Result := Result + 'GL_INVALID_FRAMEBUFFER_OPERATION';
      {$ENDIF}
      GL_OUT_OF_MEMORY:       Result := Result + 'GL_OUT_OF_MEMORY';
      GL_STACK_UNDERFLOW:     Result := Result + 'GL_STACK_UNDERFLOW';
      GL_STACK_OVERFLOW:      Result := Result + 'GL_STACK_OVERFLOW';
      else                    Result := Result + 'GL_UNKNOWN';
   end;
end;

class procedure oglTGlobal.InitializePre();
begin
   {$IFNDEF NO_DGL}
   dglOpenGL.InitOpenGL();
   {$ENDIF}
end;

class procedure oglTGlobal.ActivateRenderingContext();
begin
   {$IFNDEF NO_DGL}
   ReadImplementationProperties();
   ReadExtensions();
   {$ENDIF}
end;

class function oglTGlobal.ContextRequired(const settings: oglTSettings): boolean;
begin
   {$IFDEF GLES}
   result := false;
   {$ELSE}
   result := ((settings.version.Major >= 3) and (settings.Version.Profile <> oglPROFILE_COMPATIBILITY))
      or ((settings.version.Major > 3) and (settings.Version.Profile = oglPROFILE_COMPATIBILITY))
      or ((settings.version.Major >= 3) and (settings.version.Minor >= 2) and (settings.Version.Profile = oglPROFILE_COMPATIBILITY));
   {$ENDIF}
end;

{ INFORMATION }

class function oglTGlobal.GetString(which: GLuint): string;
var
   pch: pChar;
   glErr: GLenum;

begin
   {$IFDEF GLES}
   pch := PChar(glGetString(which));
   {$ELSE}
   pch := glGetString(which);
   {$ENDIF}
   if(pch = nil) then
      result := ''
   else
      result := pch;

   glErr := eRaise();
   if(glErr <> 0) then
      log.e('gl > Failed to get string (' + sf(which) + ') with error ' + ogl.ErrorString(glErr));
end;

class procedure oglTGlobal.GetVersion(const versionString: string; out major, minor, revision: longword; out profile: oglTProfile);
var
   ver,
   xver: string;
   lVersion: string;
   code: longint;
   version: longword;

begin
   lVersion := LowerCase(versionString);

   if(Pos('core', lVersion) > 0) then
      profile := oglPROFILE_CORE
   else if(Pos('compatibility', lVersion) > 0) then
      profile := oglPROFILE_COMPATIBILITY
   else
      profile := oglPROFILE_ANY;

   {try to figure out the OpenGL version}
   ver := versionString;

   code := pos('OpenGL ES', ver);
   if(code > 0) then begin
      {handle OpenGL ES}
      Delete(ver, 1, code);

      ver := CopyAfterDel(ver, '-');
      xver := CopyToDel(ver, ' ');
      ver := CopyToDel(ver, ')');
   end else
      ver := CopyToDel(ver);

   xver  := CopyToDel(ver, '.');
   val(xver, version, code);
   if(code = 0) then
      major := version
   else
      major := 0;

   xver  := CopyToDel(ver, '.');
   val(xver, version, code);
   if(code = 0) then
      minor := version
   else
      minor := 0;

   revision := 0;
   if(Length(ver) <> 0) then begin
      val(ver, version, code);
      if(code = 0) then
         revision := version
      else
         revision := 0;
   end;
end;

class procedure oglTGlobal.GetVersion(var major, minor, revision: longword; out profile: oglTProfile);
var
   versionString: string;

begin
   versionString := ogl.GetString(GL_VERSION);

   ogl.GetVersion(versionString, major, minor, revision, profile);
end;

class procedure oglTGlobal.GetGLSLVersion(const versionString: string; out major, minor, compact: longword);
var
   p,
   pE,
   code: loopint;
   s: string;

begin
   major := 0;
   minor := 0;
   compact := 0;

   p := Pos('.', versionString);
   s := copy(versionString, 1, p - 1);
   val(s, major, code);
   if(code <> 0) then
      exit;

   pE := Pos(' ', versionString);

   if(pE = 0) then
      pE := Length(versionString) + 1;

   s := copy(versionString, p + 1, pE - p - 1);

   val(s, minor, code);
   if(code <> 0) then
      exit;

   compact := major * 100 + minor;
end;

class function oglTGlobal.CompareVersions(sMajor, sMinor, tMajor, tMinor: longword): longint;
begin
   if(tMajor < sMajor) then
      result := +1
   else begin
      if(tMajor = sMajor) and (tMinor < sMinor) then
         result := +1
      else if(tMajor = sMajor) and (tMinor = sMinor) then
         result := 0
      else
         result := -1;
   end;
end;

class function oglTGlobal.CompareVersions(const s, t: oglTVersion): longint;
begin
   result := ogl.CompareVersions(s.Major, s.Minor, t.Major, t.Minor);
end;

class function oglTGlobal.GetShaderTypeString(shaderType: GLenum): string;
begin
   {$IFNDEF GLES}
   if(shaderType = GL_VERTEX_SHADER) then
      Result := 'vertex'
   else if(shaderType = GL_FRAGMENT_SHADER) then
      Result := 'fragment'
   else if (shaderType = GL_GEOMETRY_SHADER) then
      Result := 'geometry'
   else if (shaderType = GL_TESS_EVALUATION_SHADER) then
      Result := 'tess_evaluation'
   else if (shaderType = GL_TESS_CONTROL_SHADER) then
      Result := 'tess_control'
   else if (shaderType = GL_COMPUTE_SHADER) then
      Result := 'compute'
   else
      Result := '';
   {$ELSE}
   Result := 'unsupported';
   {$ENDIF}
end;

function oglTGlobal.ValidRC(rc: oglTRenderingContext): boolean;
begin
   {$IF defined(WINDOWS)}
   Result := rc <> 0;
   {$ELSEIF defined(X11)}
   Result := rc <> nil;
   {$ELSEIF defined(COCOA)}
   Result := rc <> nil;
   {$ELSE}
   Result := 0;
   {$ENDIF}
end;

class procedure oglTGlobal.InitState();
begin
   {set default blending function}
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

   {enable vertex arrays by default, since anything we render will require these}
   glEnableClientState(GL_VERTEX_ARRAY);

   {back face culling should be enabled by default}
   glEnable(GL_CULL_FACE);
   glCullFace(GL_BACK);
end;

VAR
   paramHandler: TParameterHandler;

function processParam(const {%H-}paramKey: string; var params: array of string; n: longint): boolean;
var
   major,
   minor,
   revision: longword;
   profile: oglTProfile;

begin
   Result := false;

   if(n = 1) then begin
      ogl.GetVersion(params[0], major, minor, revision, profile);

      if(major <> 0) then begin;
         oglDefaultSettings.Version.Major := major;
         oglDefaultSettings.Version.Minor := minor;
         oglDefaultSettings.Version.Profile := profile;

         log.v('gl version set to: ' + oglDefaultSettings.GetString());
         exit(true);
      end else
         log.e('Invalid gl version specified: ' + params[0]);
   end else
      log.e('Did not specify ' + paramHandler.ParamKey + ' parameter value');
end;

INITIALIZATION
   parameters.AddHandler(paramHandler, 'gl.version', '-gl.version', @processParam);

END.
