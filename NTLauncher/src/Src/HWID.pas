unit HWID;

interface

function GetCPUSerialNumber: string;
function GetHDDSerialNumber: string;
function GetHWID: string;

implementation

uses
  Windows, SysUtils;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetCPUSerialNumber: string;
var
  _eax, _ebx, _ecx, _edx, MaxFuncSize: LongWord;
begin
  asm
    push ebx
    mov eax, 1
    cpuid
    mov _eax, eax
    and ebx,  0F0FFFFFFh
    mov _ebx, ebx
    mov _ecx, ecx
    mov _edx, edx

    xor eax, eax
    cpuid
    mov MaxFuncSize, eax
    pop ebx
  end;
  Result := IntToHex(_eax, 8) + IntToHex(_ebx, 8) + IntToHex(_ecx, 8) + IntToHex(_edx, 8) + IntToHex(MaxFuncSize, 2)
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetHDDSerialNumber: string;
type
  STORAGE_PROPERTY_QUERY = record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array [0..1] of WORD;
  end;

  STORAGE_DEVICE_DESCRIPTOR = record
    Version: ULONG;
    Size: ULONG;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: ULONG;         // 0x0C Vendor ID
    ProductIdOffset: ULONG;        // 0x10 Product ID
    ProductRevisionOffset: ULONG;  // 0x15 Revision
    SerialNumberOffset: ULONG;     // 0x18 Serial Number
    STORAGE_BUS_TYPE: DWORD;
    RawPropertiesLength: ULONG;
    RawDeviceProperties: array [0..2048] of Byte;
  end;

  PCharArray = ^TCharArray;
  TCharArray = array [0..32767] of Char;

const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;

var
  DriveHandle: THandle;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  Status: LongBool;
  Returned: LongWord;
begin
  DriveHandle := CreateFile (
                              PChar('\\.\PhysicalDrive0'),
                              GENERIC_READ,
                              FILE_SHARE_READ or FILE_SHARE_WRITE,
                              nil,
                              OPEN_EXISTING,
                              0,
                              0
                             );

  ZeroMemory(@PropQuery, SizeOf(PropQuery));
  Status := DeviceIoControl(
                             DriveHandle,
                             IOCTL_STORAGE_QUERY_PROPERTY,
                             @PropQuery,
                             SizeOf(PropQuery),
                             @DeviceDescriptor,
                             SizeOf(DeviceDescriptor),
                             Returned,
                             nil
                            );

  CloseHandle(DriveHandle);
  
  if not Status then Exit;

  Result := PAnsiChar(@PCharArray(@DeviceDescriptor)^[DeviceDescriptor.SerialNumberOffset + 12]);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function GetHWID: string;
begin
  Result := GetCPUSerialNumber + GetHDDSerialNumber;
end;

end.
