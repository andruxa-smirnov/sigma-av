unit procpath;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, PsAPI, TlHelp32;


// portions by Project Jedi www.delphi-jedi.org/
const
  RsSystemIdleProcess = 'System Idle Process';
  RsSystemProcess = 'System Process';


function RunningProcessesList(const List: TStrings; FullPath: Boolean): Boolean;

implementation

function IsWinXP: Boolean;
begin
  Result := (Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion = 5) and (Win32MinorVersion = 1);
end;

function IsWin2k: Boolean;
begin
  Result := (Win32MajorVersion >= 5) and (Win32Platform = VER_PLATFORM_WIN32_NT);
end;

function IsWinNT4: Boolean;
begin
  Result := Win32Platform = VER_PLATFORM_WIN32_NT;
  Result := Result and (Win32MajorVersion = 4);
end;

function IsWin3X: Boolean;
begin
  Result := Win32Platform = VER_PLATFORM_WIN32_NT;
  Result := Result and (Win32MajorVersion = 3) and
  ((Win32MinorVersion = 1) or (Win32MinorVersion = 5) or
  (Win32MinorVersion = 51));
end;

function RunningProcessesList(const List: TStrings; FullPath: Boolean): Boolean;

function ProcessFileName(PID: DWORD): string;
var
  Handle: THandle;
begin
  Result := '';
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if Handle <> 0 then
  try
    SetLength(Result, MAX_PATH);
  if FullPath then
  begin
    if GetModuleFileNameEx(Handle, 0, PChar(Result), MAX_PATH) > 0 then
    SetLength(Result, StrLen(PChar(Result)))
  else
    Result := '';
  end
else
  begin
    if GetModuleBaseNameA(Handle, 0, PChar(Result), MAX_PATH) > 0 then
    SetLength(Result, StrLen(PChar(Result)))
  else
    Result := '';
  end;
  finally
    CloseHandle(Handle);
  end;
end;

function BuildListTH: Boolean;
var
  SnapProcHandle: THandle;
  ProcEntry: TProcessEntry32;
  NextProc: Boolean;
  FileName: string;
begin
  SnapProcHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  Result := (SnapProcHandle <> INVALID_HANDLE_VALUE);
  if Result then
  try
    ProcEntry.dwSize := SizeOf(ProcEntry);
    NextProc := Process32First(SnapProcHandle, ProcEntry);
    while NextProc do
  begin
    if ProcEntry.th32ProcessID = 0 then
    begin
    // PID 0 is always the "System Idle Process" but this name cannot be
    // retrieved from the system and has to be fabricated.
      FileName := RsSystemIdleProcess;
    end
  else
    begin
      if IsWin2k or IsWinXP then
      begin
        FileName := ProcessFileName(ProcEntry.th32ProcessID);
        if FileName = '' then
        FileName := ProcEntry.szExeFile;
      end
    else
      begin
        FileName := ProcEntry.szExeFile;
        if not FullPath then
          FileName := ExtractFileName(FileName);
      end;
    end;
    List.AddObject(FileName, Pointer(ProcEntry.th32ProcessID));
    NextProc := Process32Next(SnapProcHandle, ProcEntry);
  end;
  finally
    CloseHandle(SnapProcHandle);
  end;
end;

function BuildListPS: Boolean;
var
PIDs: array [0..1024] of DWORD;
Needed: DWORD;
I: Integer;
FileName: string;
begin
Result := EnumProcesses(@PIDs, SizeOf(PIDs), Needed);
if Result then
begin
for I := 0 to (Needed div SizeOf(DWORD)) - 1 do
begin
case PIDs[i] of
0:
// PID 0 is always the "System Idle Process" but this name cannot be
// retrieved from the system and has to be fabricated.
FileName := RsSystemIdleProcess;
2:
// On NT 4 PID 2 is the "System Process" but this name cannot be
// retrieved from the system and has to be fabricated.
if IsWinNT4 then
FileName := RsSystemProcess
else
FileName := ProcessFileName(PIDs[i]);
8:
// On Win2K PID 8 is the "System Process" but this name cannot be
// retrieved from the system and has to be fabricated.
if IsWin2k or IsWinXP then
FileName := RsSystemProcess
else
FileName := ProcessFileName(PIDs[i]);
else
FileName := ProcessFileName(PIDs[i]);
end;
if FileName <> '' then
List.AddObject(FileName, Pointer(PIDs[i]));
end;
end;
end;
begin
if IsWin3X or IsWinNT4 then
Result := BuildListPS
else
Result := BuildListTH;
end;

function GetProcessNameFromWnd(Wnd: HWND): string;
var
List: TStringList;
PID: DWORD;
I: Integer;
begin
Result := '';
if IsWindow(Wnd) then
begin
PID := INVALID_HANDLE_VALUE;
GetWindowThreadProcessId(Wnd, @PID);
List := TStringList.Create;
try
if RunningProcessesList(List, True) then
begin
I := List.IndexOfObject(Pointer(PID));
if I > -1 then
Result := List[i];
end;
finally
List.Free;
end;
end;
end;


end.