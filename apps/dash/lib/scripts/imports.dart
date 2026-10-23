/// What a script imports, and what pip calls those packages: to offer to
/// install the ones its Python lacks.
library;

/// The top-level modules [source] imports: `import cv2`, `import numpy as
/// np`, `from torch.nn import Linear` → cv2, numpy, torch. Not relative
/// imports, nor imports inside `try:` (optional ones, with a fallback), nor
/// koebelt_dash_scripts (dash sets that up itself).
Set<String> importedModules(String source) {
  final out = <String>{};
  final lines = source.split('\n');
  var inString = false;
  for (var n = 0; n < lines.length; n++) {
    final l = lines[n];
    // Skip docstrings and other triple-quoted text.
    final quotes = RegExp(r'"""|' "'''").allMatches(l).length;
    if (inString) {
      if (quotes.isOdd) inString = false;
      continue;
    }
    if (quotes.isOdd) {
      inString = true;
      continue;
    }
    final m = RegExp(r'^(\s*)(?:import\s+([\w.]+(?:\s+as\s+\w+)?(?:\s*,\s*[\w.]+(?:\s+as\s+\w+)?)*)|from\s+([\w.]+)\s+import\b)').firstMatch(l);
    if (m == null || _inTry(lines, n, m[1]!.length)) continue;
    final names = m[2] != null ? [for (final p in m[2]!.split(',')) p.trim().split(RegExp(r'\s+')).first] : [m[3]!];
    for (final name in names) {
      final top = name.split('.').first;
      if (top.isNotEmpty && top != 'koebelt_dash_scripts' && top != '__future__') out.add(top);
    }
  }
  return out;
}

/// Whether line [n], indented by [indent], is inside a `try:` block.
bool _inTry(List<String> lines, int n, int indent) {
  if (indent == 0) return false;
  for (var i = n - 1; i >= 0; i--) {
    final l = lines[i];
    if (l.trim().isEmpty || l.trimLeft().startsWith('#')) continue;
    final ind = l.length - l.trimLeft().length;
    if (ind < indent) {
      if (RegExp(r'^\s*try\s*:').hasMatch(l)) return true;
      indent = ind;
      if (ind == 0) return false;
    }
  }
  return false;
}

/// Modules whose pip package has another name.
const _pipNames = {
  'cv2': 'opencv-python',
  'PIL': 'pillow',
  'sklearn': 'scikit-learn',
  'skimage': 'scikit-image',
  'yaml': 'pyyaml',
  'bs4': 'beautifulsoup4',
  'serial': 'pyserial',
  'usb': 'pyusb',
  'dateutil': 'python-dateutil',
  'dotenv': 'python-dotenv',
  'Crypto': 'pycryptodome',
  'jwt': 'pyjwt',
  'attr': 'attrs',
  'zmq': 'pyzmq',
  'fitz': 'pymupdf',
  'OpenGL': 'pyopengl',
  'gi': 'pygobject',
  'mpl_toolkits': 'matplotlib',
  'tflite_runtime': 'tflite-runtime',
  'RPi': 'RPi.GPIO',
  'Xlib': 'python-xlib',
  'win32api': 'pywin32',
  'win32con': 'pywin32',
  'magic': 'python-magic',
  'docx': 'python-docx',
  'pptx': 'python-pptx',
  'osgeo': 'gdal',
};

/// What `pip install` calls the package that provides [module].
String pipNameFor(String module) => _pipNames[module] ?? module.replaceAll('_', '-');
