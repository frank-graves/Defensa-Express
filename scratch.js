const fs = require('fs');
let content = fs.readFileSync('lib/services/evidence_service.dart', 'utf8');

if (!content.includes('package:flutter/foundation.dart')) {
    content = content.replace("import 'dart:io';", "import 'dart:io';\nimport 'package:flutter/foundation.dart';");
}

content = content.replace(/(?<!if \(kDebugMode\) \{ )print\((.*?)\);/gs, 'if (kDebugMode) { print($1); }');

fs.writeFileSync('lib/services/evidence_service.dart', content);
