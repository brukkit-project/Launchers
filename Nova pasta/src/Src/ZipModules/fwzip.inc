////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : FWZip
//  * Unit Name : fwzip.inc
//  * Purpose   : ����� ������� ��� ���������� ZIP ������
//  * Author    : ��������� (Rouse_) ������
//  * Copyright : � Fangorn Wizards Lab 1998 - 2013.
//  * Version   : 1.0.10
//  * Home Page : http://rouse.drkb.ru
//  * Home Blog : http://alexander-bagel.blogspot.ru
//  ****************************************************************************
//  * Stable Release : http://rouse.drkb.ru/components.php#fwzip
//  * Latest Source  : https://github.com/AlexanderBagel/FWZip
//  ****************************************************************************
//
//  ������������ ���������:
//  ftp://ftp.info-zip.org/pub/infozip/doc/appnote-iz-latest.zip
//  http://zlib.net/zlib-1.2.5.tar.gz
//  http://www.base2ti.com/
//

// ������ ������ ������������ ��� ����������� ���������
// �������� ��������� ������ FWZip

// ���� ���������� ������������ ZLibEx ��������������� ��������� ����
// {$DEFINE USE_ZLIB_EX}

// ���� ���������� ������������ ������� ���������� ��������������� ��������� ����
// {$DEFINE USE_ZLIB_DLL}

// ���� ���������� ��������� ������/���������� �� ������� ��������
// c ���������� ZLib ��������� ��������������� ��������� ����
// �� ���� ����� - ���������� � ���������������� ���������� � ����� ������ �������
// �� ������ ������� ������ ��������� ��� ������ 7Zip
// {$DEFINE USE_AUTOGENERATED_ZLIB_HEADER}




// ��������!!!
// =============================================================================

// ��� ��������� ���� �� ������������ ��� ��������� ������������� �
// �������� ����������� ��������� ��� ���������� FWZip

// ���� ���������� ���������� ZLibEx, ��������� ������������� ������� ����������
{$IFDEF USE_ZLIB_EX}
  {$UNDEF USE_ZLIB_DLL}
{$ENDIF}

// deflateInit2_ � inflateInit2_ ����������� � Delphi ������ �� 2009-��
// ������� ��� ������������� ������ ������ ������ � ������������ ������ ZLib
// ���������� ��������� ������������� ������ �������

{$IF COMPILERVERSION < 20.0 }
  {$DEFINE OLDEST_ZLIB}
{$ELSE}
  {$UNDEF OLDEST_ZLIB}
{$IFEND}

// ���� ���������� ���������� ZLibEx, �� ������������ deflateInit2_ � inflateInit2_ �����
{$IFDEF USE_ZLIB_EX}
  {$UNDEF OLDEST_ZLIB}
{$ENDIF}

// ���� ���������� ������� ����������, �� ������������ deflateInit2_ � inflateInit2_ �����
{$IFDEF USE_ZLIB_DLL}
  {$UNDEF OLDEST_ZLIB}
{$ENDIF}

// ���� ������������ deflateInit2_ � inflateInit2_ ������,
// ������������� ������������� �� ������ ����� ������ � ����������������� �����������
{$IFDEF OLDEST_ZLIB}
  {$DEFINE USE_AUTOGENERATED_ZLIB_HEADER}
{$ENDIF}