import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: camel_case_types
final class DATA_BLOB extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

typedef CryptProtectDataC =
    Int32 Function(
      Pointer<DATA_BLOB> pDataIn,
      Pointer<Utf16> szDataDescr,
      Pointer<DATA_BLOB> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      Uint32 dwFlags,
      Pointer<DATA_BLOB> pDataOut,
    );

typedef CryptProtectDataDart =
    int Function(
      Pointer<DATA_BLOB> pDataIn,
      Pointer<Utf16> szDataDescr,
      Pointer<DATA_BLOB> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      int dwFlags,
      Pointer<DATA_BLOB> pDataOut,
    );

typedef CryptUnprotectDataC =
    Int32 Function(
      Pointer<DATA_BLOB> pDataIn,
      Pointer<Pointer<Utf16>> ppszDataDescr,
      Pointer<DATA_BLOB> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      Uint32 dwFlags,
      Pointer<DATA_BLOB> pDataOut,
    );

typedef CryptUnprotectDataDart =
    int Function(
      Pointer<DATA_BLOB> pDataIn,
      Pointer<Pointer<Utf16>> ppszDataDescr,
      Pointer<DATA_BLOB> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      int dwFlags,
      Pointer<DATA_BLOB> pDataOut,
    );

typedef LocalFreeC = Pointer<Void> Function(Pointer<Void> hMem);
typedef LocalFreeDart = Pointer<Void> Function(Pointer<Void> hMem);

class WindowsDpapi {
  static Uint8List encrypt(Uint8List plainBytes) {
    if (!Platform.isWindows) return plainBytes;

    final crypt32 = DynamicLibrary.open('Crypt32.dll');
    final kernel32 = DynamicLibrary.open('Kernel32.dll');

    final cryptProtectData = crypt32
        .lookupFunction<CryptProtectDataC, CryptProtectDataDart>(
          'CryptProtectData',
        );
    final localFree = kernel32.lookupFunction<LocalFreeC, LocalFreeDart>(
      'LocalFree',
    );

    final inBlob = calloc<DATA_BLOB>();
    final outBlob = calloc<DATA_BLOB>();
    final pData = calloc<Uint8>(plainBytes.length);

    try {
      final byteList = pData.asTypedList(plainBytes.length);
      byteList.setAll(0, plainBytes);

      inBlob.ref.cbData = plainBytes.length;
      inBlob.ref.pbData = pData;

      // CRYPTPROTECT_UI_FORBIDDEN = 0x1
      final res = cryptProtectData(
        inBlob,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        0x1,
        outBlob,
      );

      if (res == 0) {
        throw Exception('CryptProtectData a échoué.');
      }

      final outBytes = Uint8List.fromList(
        outBlob.ref.pbData.asTypedList(outBlob.ref.cbData),
      );
      localFree(outBlob.ref.pbData.cast());
      return outBytes;
    } finally {
      calloc.free(pData);
      calloc.free(inBlob);
      calloc.free(outBlob);
    }
  }

  static Uint8List decrypt(Uint8List cipherBytes) {
    if (!Platform.isWindows) return cipherBytes;

    final crypt32 = DynamicLibrary.open('Crypt32.dll');
    final kernel32 = DynamicLibrary.open('Kernel32.dll');

    final cryptUnprotectData = crypt32
        .lookupFunction<CryptUnprotectDataC, CryptUnprotectDataDart>(
          'CryptUnprotectData',
        );
    final localFree = kernel32.lookupFunction<LocalFreeC, LocalFreeDart>(
      'LocalFree',
    );

    final inBlob = calloc<DATA_BLOB>();
    final outBlob = calloc<DATA_BLOB>();
    final pData = calloc<Uint8>(cipherBytes.length);

    try {
      final byteList = pData.asTypedList(cipherBytes.length);
      byteList.setAll(0, cipherBytes);

      inBlob.ref.cbData = cipherBytes.length;
      inBlob.ref.pbData = pData;

      final res = cryptUnprotectData(
        inBlob,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        0x1,
        outBlob,
      );

      if (res == 0) {
        throw Exception('CryptUnprotectData a échoué.');
      }

      final outBytes = Uint8List.fromList(
        outBlob.ref.pbData.asTypedList(outBlob.ref.cbData),
      );
      localFree(outBlob.ref.pbData.cast());
      return outBytes;
    } finally {
      calloc.free(pData);
      calloc.free(inBlob);
      calloc.free(outBlob);
    }
  }
}

void main() {
  test('Windows DPAPI encryption and decryption round-trip', () {
    const secret = 'super-secret-refresh-token-12345';
    final plainBytes = Uint8List.fromList(utf8.encode(secret));

    final cipherBytes = WindowsDpapi.encrypt(plainBytes);
    expect(cipherBytes, isNot(equals(plainBytes)));

    final decryptedBytes = WindowsDpapi.decrypt(cipherBytes);
    expect(utf8.decode(decryptedBytes), equals(secret));
  });
}
