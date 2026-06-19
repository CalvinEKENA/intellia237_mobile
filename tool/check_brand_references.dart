import 'dart:convert';
import 'dart:io';

final _legacyPattern = RegExp(
  r'edunova|edu_nova|edu-nova|com\.edunova|edunova-aabd1',
  caseSensitive: false,
);

const _skipDirectories = {
  '.dart_tool',
  '.firebase',
  '.git',
  '.gradle',
  '.idea',
  '.claude',
  'build',
  'node_modules',
};

const _skipFiles = {
  'analyze_output.txt',
  'docs/architecture/FIREBASE_ENVIRONMENTS.md',
  'docs/stabilization/FOUNDATION_STABILIZATION_REPORT.md',
};

const _skipPathPrefixes = {
  'assets/lottie/',
  'docs/audits/',
  'docs/rebranding/',
  'functions/lib/',
  'functions/node_modules/',
  'intellia237/',
  'intellia237/node_modules/',
  'intellia237/.next/',
  'intellia237/build/',
  'intellia237/dist/',
};

const _textExtensions = {
  '.dart',
  '.html',
  '.js',
  '.json',
  '.kts',
  '.kt',
  '.md',
  '.plist',
  '.py',
  '.rc',
  '.ts',
  '.tsx',
  '.txt',
  '.xcconfig',
  '.xcscheme',
  '.xml',
  '.yaml',
  '.yml',
};

const _textFileNames = {
  '.firebaserc',
  'CMakeLists.txt',
  'README.md',
  'project.pbxproj',
};

void main() {
  final root = Directory.current;
  final violations = <String>[];

  for (final file in _sourceFiles(root)) {
    final path = _normalize(file.path, root.path);
    if (_legacyPattern.hasMatch(path) && !_isAllowed(path, 0, path)) {
      violations.add('$path: path contains a legacy EDUNOVA reference');
    }

    final String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      continue;
    } on FormatException {
      continue;
    }

    final lines = const LineSplitter().convert(content);
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_legacyPattern.hasMatch(line)) {
        continue;
      }
      final lineNumber = index + 1;
      if (_isAllowed(path, lineNumber, line)) {
        continue;
      }
      violations.add('$path:$lineNumber: ${line.trim()}');
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Brand reference check passed.');
    return;
  }

  stderr.writeln('Unallowed legacy EDUNOVA references found:');
  for (final violation in violations) {
    stderr.writeln('- $violation');
  }
  stderr.writeln(
    'Update the reference, or document and allowlist an intentional legacy '
    'identifier in tool/check_brand_references.dart.',
  );
  exitCode = 1;
}

Iterable<File> _sourceFiles(Directory root) sync* {
  yield* _sourceFilesIn(root, root);
}

Iterable<File> _sourceFilesIn(Directory directory, Directory root) sync* {
  for (final entity in directory.listSync(followLinks: false)) {
    final relativePath = _normalize(entity.path, root.path);
    if (_isSkippedPath(relativePath)) {
      continue;
    }
    if (entity is Directory) {
      yield* _sourceFilesIn(entity, root);
    } else if (entity is File && _shouldScan(entity.path)) {
      yield entity;
    }
  }
}

bool _isSkippedPath(String path) {
  if (_skipFiles.contains(path)) {
    return true;
  }

  final parts = path.split('/');
  if (parts.any(_skipDirectories.contains)) {
    return true;
  }
  return _skipPathPrefixes.any(path.startsWith);
}

bool _shouldScan(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  if (_textFileNames.contains(fileName)) {
    return true;
  }

  final dot = fileName.lastIndexOf('.');
  if (dot < 0) {
    return false;
  }
  return _textExtensions.contains(fileName.substring(dot));
}

String _normalize(String path, String rootPath) {
  final relative = path.startsWith(rootPath)
      ? path.substring(rootPath.length)
      : path;
  return relative.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
}

bool _isAllowed(String path, int lineNumber, String line) {
  if (path == 'tool/check_brand_references.dart') {
    return true;
  }

  if (path.startsWith('docs/audits/') ||
      path.startsWith('docs/rebranding/') ||
      path == 'docs/architecture/FIREBASE_ENVIRONMENTS.md' ||
      path == 'docs/stabilization/FOUNDATION_STABILIZATION_REPORT.md') {
    return true;
  }

  if (path == 'assets/icons/edunova.png') {
    return true;
  }

  if (path.startsWith('assets/lottie/') && line.contains('Edunova')) {
    return true;
  }

  if (path == '.firebaserc' && line.contains('edunova-aabd1')) {
    return true;
  }

  if (path == 'README.md' && _containsProductionIdentifier(line)) {
    return true;
  }

  if (path == 'android/app/build.gradle.kts' &&
      line.contains('com.edunova.app')) {
    return true;
  }

  if (path == 'android/app/google-services.json' &&
      (line.contains('edunova-aabd1') ||
          line.contains('com.edunova.app') ||
          line.contains('com.example.edunova'))) {
    return true;
  }

  if (path == 'android/app/src/main/kotlin/com/edunova/app/MainActivity.kt' &&
      (lineNumber == 0 || line.contains('com.edunova.app'))) {
    return true;
  }

  if (path == 'ios/Runner.xcodeproj/project.pbxproj' &&
      line.contains('PRODUCT_BUNDLE_IDENTIFIER = com.edunova.app')) {
    return true;
  }

  if (path == 'lib/app/config/app_config.dart' &&
      _containsProductionIdentifier(line)) {
    return true;
  }

  if (path == 'lib/firebase_options.dart' &&
      _containsProductionIdentifier(line)) {
    return true;
  }

  if (path == 'test/app/config/app_config_test.dart' &&
      _containsProductionIdentifier(line)) {
    return true;
  }

  if (path.startsWith('scripts/') && _containsProductionIdentifier(line)) {
    return true;
  }

  if (path.startsWith('functions/') && _containsProductionIdentifier(line)) {
    return true;
  }

  return false;
}

bool _containsProductionIdentifier(String line) =>
    line.contains('edunova-aabd1') ||
    line.contains('edunova-aabd1.firebasestorage.app') ||
    line.contains('com.edunova.app');
