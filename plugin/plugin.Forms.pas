{ *************************************************************************** }
{ }
{ }
{ Copyright (C) Amarildo Lacerda }
{ }
{ https://github.com/amarildolacerda }
{ }
{ }
{ *************************************************************************** }
{ }
{ Licensed under the Apache License, Version 2.0 (the "License"); }
{ you may not use this file except in compliance with the License. }
{ You may obtain a copy of the License at }
{ }
{ http://www.apache.org/licenses/LICENSE-2.0 }
{ }
{ Unless required by applicable law or agreed to in writing, software }
{ distributed under the License is distributed on an "AS IS" BASIS, }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{ See the License for the specific language governing permissions and }
{ limitations under the License. }
{ }
{ *************************************************************************** }

unit Plugin.Forms;

interface

uses WinApi.windows, {$IFDEF FMX} FMX.Forms, FMX.Controls, {$ELSE} VCL.Forms,
  VCL.Controls, {$ENDIF} System.classes, System.SysUtils,
  Plugin.Service, Plugin.Interf;

type

  TPluginExecuteService = class(TPluginService, IPluginExecute)
  protected
    FSubTypeID: Int64;
    FParams: String;
    FConnectionString: string;
    FFilial: integer;
    FAppUser: string;
  private
    FOnNotify: TNotifyEvent;
    procedure SetSubTypeID(const Value: Int64);
    procedure SetOnNotify(const Value: TNotifyEvent);
  protected
    destructor Destroy; override;
    procedure SetForm(const Value: TForm); virtual;
    function GetForm(AParent: THandle): TForm; virtual;
    function GetCaption: string; virtual;
    function GetSubTypeID: Int64; virtual;
    procedure DoNotify;

    { function GetHandle:THandle;
      procedure SetHandle(AHandle:THandle);
    }
    procedure Connection(const AConnectionString: string); virtual;
    procedure User(const AFilial: integer; const AAppUser: string); virtual;
    procedure Sync(const AJson: string); virtual;
    procedure Execute(const AModal: boolean); virtual;
    procedure SetParams(AJsonParams: String);

    function GetAuthor: string; virtual;
    function GetName: string; virtual;
    function GetVersion: string; virtual;
    function GetDescription: string; virtual;
  public
    property SubTypeID: Int64 read GetSubTypeID write SetSubTypeID;
    property Usuario: string read FAppUser;
    property Filial: integer read FFilial;
    property ConnectionString: string read FConnectionString;
    property Params: string read FParams;
    property OnNotify: TNotifyEvent read FOnNotify write SetOnNotify;
  end;

{$IFDEF FMX}

  TFormClass = class of TForm;
{$ENDIF}

  TPluginFormService = class(TPluginExecuteService)
  protected
    FCaption: string;
    FFormClass: TFormClass;
    procedure Init; virtual;
  public
    constructor Create(AFormClass: TFormClass; ACaption: String); virtual;
    destructor Destroy; override;
    function GetCaption: string; override;

    procedure Execute(const AModal: boolean); override;
    procedure Embedded(const AParent: THandle); override;
{$IFNDEF DLL}
    function EmbeddedControl(const FParent: TWinControl): boolean;
      overload; override;
{$ENDIF}
    procedure DoStart; override;
  end;

procedure Register;

implementation

uses System.classes.Helper, System.Rtti;

procedure Register;
begin
  // RegisterComponents('Store',[TPluginFormService]);
end;

procedure TPluginExecuteService.Connection(const AConnectionString: string);
begin
  FConnectionString := AConnectionString;
  if not assigned(FForm) then
    exit;
  if Supports(FForm, IPluginExecuteConnection) then
    (FForm as IPluginExecuteConnection).Connection(AConnectionString)
  else
  begin
    // DO NOT CHANGE NAMES
    FForm.ContextProperties['ConnectionString'] := AConnectionString;
  end;
  DoNotify;

end;

destructor TPluginExecuteService.Destroy;
begin
  if FOwned then
    FreeAndNil(FForm);
  inherited;
end;

procedure TPluginExecuteService.DoNotify;
begin
  if assigned(FOnNotify) then
    FOnNotify(self);
end;

procedure TPluginExecuteService.Execute(const AModal: boolean);
begin
  if not assigned(FForm) then
    exit;
  if AModal then
    try
      FForm.ShowModal
    finally
      FForm.Release
    end
  else
    FForm.Show;
end;

function TPluginExecuteService.GetAuthor: string;
begin
  result := 'Storeware';
end;

function TPluginExecuteService.GetCaption: string;
begin
  if assigned(FForm) then
    result := FForm.Caption
  else
    result := '';
end;

function TPluginExecuteService.GetDescription: string;
begin
  result := 'Plugin';
end;

function TPluginExecuteService.GetForm(AParent: THandle): TForm;
begin
  result := FForm;
  if AParent > 0 then
  begin
{$IFDEF FMX}
{$ELSE}
    WinApi.windows.SetParent(FForm.Handle, AParent);
{$ENDIF}
  end;
end;

{
  function TPluginExecuteService.GetHandle: THandle;
  begin
  result := FHandle;
  end;
}
function TPluginExecuteService.GetName: string;
begin
  result := 'Storeware';
end;

function TPluginExecuteService.GetVersion: string;
begin
  result := '01.00';
end;

function TPluginExecuteService.GetSubTypeID: Int64;
begin
  result := FSubTypeID;
end;

procedure TPluginExecuteService.SetForm(const Value: TForm);
begin
  FOwned := false;
  if assigned(FForm) then
    FreeAndNil(FForm);
  FForm := Value;
  Connection(FConnectionString);
  User(FFilial, FAppUser);

end;

procedure TPluginExecuteService.SetOnNotify(const Value: TNotifyEvent);
begin
  FOnNotify := Value;
end;

procedure TPluginExecuteService.SetParams(AJsonParams: String);
begin
  FParams := AJsonParams;
  DoNotify;
end;

procedure TPluginExecuteService.SetSubTypeID(const Value: Int64);
begin
  FSubTypeID := Value;
end;

{ procedure TPluginExecuteService.SetHandle(AHandle: THandle);
  begin
  FHandle := AHandle;
  end;
}
procedure TPluginExecuteService.Sync(const AJson: string);
begin
  if not assigned(FForm) then
    exit;
  if Supports(FForm, IPluginExecuteSync) then
    (FForm as IPluginExecuteSync).Sync(AJson)
  else if Supports(FForm, IPluginExecuteConnection) then
    (FForm as IPluginExecuteConnection).Sync(AJson)
  else
  begin
    FForm.ContextInvokeMethod('Sync', [AJson]);
  end;
  DoNotify;
end;

procedure TPluginExecuteService.User(const AFilial: integer;
  const AAppUser: string);
begin
  FFilial := AFilial;
  FAppUser := AAppUser;
  if not assigned(FForm) then
    exit;
  if Supports(FForm, IPluginExecuteConnection) then
    (FForm as IPluginExecuteConnection).User(AFilial, AAppUser)
  else
  begin
    FForm.ContextProperties['Filial'] := AFilial;
    FForm.ContextProperties['Usuario'] := AAppUser;
  end;
  DoNotify;
end;

{ TPluginFormService }

constructor TPluginFormService.Create(AFormClass: TFormClass; ACaption: String);
begin
  inherited Create;
  FFormClass := AFormClass;
  FCaption := ACaption;
end;

destructor TPluginFormService.Destroy;
begin
  FCaption := '';
  FFormClass := nil;
  inherited;
end;

procedure TPluginFormService.DoStart;
begin
  inherited;
end;

procedure TPluginFormService.Embedded(const AParent: THandle);
begin
  Init;
  inherited;
end;

{$IFNDEF DLL}

function TPluginFormService.EmbeddedControl(const FParent: TWinControl)
  : boolean;
begin
  Init;
  result := inherited;
end;
{$ENDIF}

procedure TPluginFormService.Execute(const AModal: boolean);
begin
  Init;
  inherited;

end;

function TPluginFormService.GetCaption: string;
begin
  if FCaption <> '' then
    result := FCaption
  else
    result := inherited GetCaption;
end;

procedure TPluginFormService.Init;
begin
  if not assigned(FForm) then
  begin
    // FreeAndNil(FForm);
    SetForm(FFormClass.Create(TPluginService.OwnedComponents));
  end;
  FForm.Caption := FCaption;
  FOwned := true;

end;

end.
