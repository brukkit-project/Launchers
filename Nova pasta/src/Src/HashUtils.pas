unit HashUtils;

interface

{$I Definitions.inc}

function HashPassword(Data: string): string;

implementation

uses
  cHash, SysUtils;

function HashPassword(Data: string): string;
begin
  {$IFDEF MD5}
  Data := MD5DigestToHex(CalcMD5(Data));
  {$ENDIF}

  {$IFDEF DOUBLE_MD5}
  Data := MD5DigestToHex(CalcMD5(Data));
  Data := MD5DigestToHex(CalcMD5(Data));
  {$ENDIF}

  {$IFDEF SHA1}
  Data := SHA1DigestToHex(CalcSHA1(Data));
  {$ENDIF}

  {$IFDEF SHA256}
  Data := SHA256DigestToHex(CalcSHA256(Data));
  {$ENDIF}

  {$IFDEF SHA384}
  Data := SHA384DigestToHex(CalcSHA384(Data));
  {$ENDIF}

  {$IFDEF SHA512}
  Data := SHA512DigestToHex(CalcSHA512(Data));
  {$ENDIF}

  Result := Data;
end;

end.
