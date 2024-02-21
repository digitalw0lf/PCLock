unit Unit1;

{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, AppEvnts, StdCtrls, uUtil, ComCtrls, Generics.Collections,
  AnsiStrings, Win.Registry;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    TrackBar1: TTrackBar;
    ApplicationEvents1: TApplicationEvents;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    Panel28: TPanel;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    FCanClose:boolean;
    //GoodChars:Integer;
    Inp:AnsiString;
    class procedure CreateScreenForms();
    procedure OnChar(C:AnsiChar);
    class procedure SaveSettings();
    class procedure LoadSettings();
    class procedure ApplyTranspValue();
  end;

const
  RegSettingsKey = '\Software\DWF\PCLock';
var
  Form1: TForm1;
  AForms:tList<tForm1>;
  Inited:integer = 0;
  hKbdHook: HHOOK = 0;
  TranspValue: Integer = 200;
  Pwd:AnsiString;

implementation

{$R *.dfm}

type
  KBDLLHOOKSTRUCT = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo:Pointer;
  end;
  PKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

function LowLevelKeyboardProc(nCode:Integer; wPar:WPARAM;
  lPar:LPARAM):LRESULT; winapi;
var
  Kbd:PKBDLLHOOKSTRUCT;
begin
  if (nCode>=0) and ((wPar=WM_KEYDOWN) or (wPar=WM_SYSKEYDOWN)) then
  begin
    Kbd:=Pointer(lPar);
//    if Kbd.vkCode in [VK_CONTROL,VK_LCONTROL,VK_RCONTROL,VK_SHIFT,VK_RSHIFT,VK_LSHIFT,
//      VK_MENU,VK_LMENU,VK_RMENU,
    //Form1.Label1.Caption:=Form1.Label1.Caption+Char(Kbd.vkCode);
    if not CharInSet(Char(Kbd.vkCode),['0'..'9','A'..'Z']) then Exit(1);
  end;
  Result:=CallNextHookEx(hKbdHook,nCode,wPar,lPar);
end;

class procedure TForm1.ApplyTranspValue;
var
  i: Integer;
begin
  for i:=0 to AForms.Count-1 do
  begin
    AForms[i].TrackBar1.Position := TranspValue;
    AForms[i].AlphaBlendValue := TranspValue;
  end;
end;

class procedure TForm1.CreateScreenForms;
var
  f:tForm1;
  i:integer;
begin
  while AForms.Count<Screen.MonitorCount do
    Application.CreateForm(tForm1,f);

  for i:=0 to AForms.Count-1 do
  begin
//    if AForms[i].Monitor<>Screen.Monitors[i] then
    begin
      AForms[i].WindowState:=wsNormal;
      AForms[i].Left:=Screen.Monitors[i].Left;
      AForms[i].Top:=Screen.Monitors[i].Top;
      AForms[i].WindowState:=wsMaximized;
    end;
  end;

  ApplyTranspValue();

  hKbdHook:=SetWindowsHookEx(WH_KEYBOARD_LL,LowLevelKeyboardProc,HInstance,0);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=FCanClose;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AForms.Add(self);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key>=Ord('A')) and (Key<=Ord('Z')) then
    OnChar(AnsiChar(Key));
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  OnChar(' ');
end;

class procedure TForm1.LoadSettings;
var
  Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      if not Reg.OpenKey(RegSettingsKey, False) then Exit;
      if Reg.ValueExists('Alpha') then
        TranspValue := Reg.ReadInteger('Alpha');
      Reg.CloseKey();
    finally
      Reg.Free;
    end;
  except
  end;
end;

procedure TForm1.OnChar(C: AnsiChar);
begin
  Inp:=Inp+C;
  if Length(Inp)>100 then Delete(Inp,1,Length(Inp)-100);
  if (AnsiEndsStr(Pwd,Inp)) or (AnsiEndsStr('UNLOCK',Inp)) then
  begin
    FCanClose:=true;
    Close();
  end;
end;

procedure TForm1.Panel3Click(Sender: TObject);
begin
  OnChar(AnsiChar((Sender as TPanel).Caption[1]));
end;

class procedure TForm1.SaveSettings;
var
  Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create();
    try
      Reg.OpenKey(RegSettingsKey, True);
      Reg.WriteInteger('Alpha', TranspValue);
      Reg.CloseKey();
    finally
      Reg.Free;
    end;
  except
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if Inited= 0 then
  begin
    Inited := 1;
    Pwd := UpperCase(ParamStr(1));
    LoadSettings();
    CreateScreenForms();
    Inited := 2;
  end;
  Application.BringToFront();
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  TranspValue := TrackBar1.Position;
  ApplyTranspValue();
  SaveSettings();
end;

initialization
  AForms:=tList<tForm1>.Create();
finalization
  AForms.Free;
  if hKbdHook<>0 then UnhookWindowsHookEx(hKbdHook);
end.
