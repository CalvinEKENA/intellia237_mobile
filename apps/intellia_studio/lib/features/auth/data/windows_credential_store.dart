import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/auth_session.dart';

abstract class CredentialStore {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clearSession();
}

final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

typedef _CryptProtectDataC =
    Int32 Function(
      Pointer<_DataBlob> pDataIn,
      Pointer<Utf16> szDataDescr,
      Pointer<_DataBlob> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      Uint32 dwFlags,
      Pointer<_DataBlob> pDataOut,
    );

typedef _CryptProtectDataDart =
    int Function(
      Pointer<_DataBlob> pDataIn,
      Pointer<Utf16> szDataDescr,
      Pointer<_DataBlob> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      int dwFlags,
      Pointer<_DataBlob> pDataOut,
    );

typedef _CryptUnprotectDataC =
    Int32 Function(
      Pointer<_DataBlob> pDataIn,
      Pointer<Pointer<Utf16>> ppszDataDescr,
      Pointer<_DataBlob> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      Uint32 dwFlags,
      Pointer<_DataBlob> pDataOut,
    );

typedef _CryptUnprotectDataDart =
    int Function(
      Pointer<_DataBlob> pDataIn,
      Pointer<Pointer<Utf16>> ppszDataDescr,
      Pointer<_DataBlob> pOptionalEntropy,
      Pointer<Void> pvReserved,
      Pointer<Void> pPromptStruct,
      int dwFlags,
      Pointer<_DataBlob> pDataOut,
    );

typedef _LocalFreeC = Pointer<Void> Function(Pointer<Void> hMem);
typedef _LocalFreeDart = Pointer<Void> Function(Pointer<Void> hMem);

class WindowsDpapiHelper {
  static Uint8List encrypt(Uint8List plainBytes) {
    if (!Platform.isWindows) return plainBytes;

    final crypt32 = DynamicLibrary.open('Crypt32.dll');
    final kernel32 = DynamicLibrary.open('Kernel32.dll');

    final cryptProtectData = crypt32
        .lookupFunction<_CryptProtectDataC, _CryptProtectDataDart>(
          'CryptProtectData',
        );
    final localFree = kernel32.lookupFunction<_LocalFreeC, _LocalFreeDart>(
      'LocalFree',
    );

    final inBlob = calloc<_DataBlob>();
    final outBlob = calloc<_DataBlob>();
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
        .lookupFunction<_CryptUnprotectDataC, _CryptUnprotectDataDart>(
          'CryptUnprotectData',
        );
    final localFree = kernel32.lookupFunction<_LocalFreeC, _LocalFreeDart>(
      'LocalFree',
    );

    final inBlob = calloc<_DataBlob>();
    final outBlob = calloc<_DataBlob>();
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

class WindowsSecureCredentialStore implements CredentialStore {
  static const _kPrefKey = 'intellia_studio_session_dpapi';

  @override
  Future<void> saveSession(AuthSession session) async {
    final rawJson = jsonEncode(session.toJson());
    final plainBytes = Uint8List.fromList(utf8.encode(rawJson));
    final encryptedBytes = WindowsDpapiHelper.encrypt(plainBytes);
    final cipherBase64 = base64Encode(encryptedBytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, cipherBase64);
  }

  @override
  Future<AuthSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cipherBase64 = prefs.getString(_kPrefKey);
    if (cipherBase64 == null || cipherBase64.isEmpty) return null;

    try {
      final cipherBytes = base64Decode(cipherBase64);
      final decryptedBytes = WindowsDpapiHelper.decrypt(cipherBytes);
      final rawJson = utf8.decode(decryptedBytes);
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return AuthSession.fromJson(map);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefKey);
  }
}
