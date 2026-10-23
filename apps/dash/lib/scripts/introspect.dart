import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What a name in a module (or class) is: (kind, signature, first doc line).
/// kind: module, class, function, value.
typedef Member = ({String kind, String sig, String doc});

/// Asks a Python what its modules hold, for completion: the installed
/// top-level modules, and the members of a module or class by dotted path
/// (numpy, numpy.linalg, cv2.VideoCapture). Only paths the script itself
/// imports are looked at, in the background, each once; what modules print
/// while importing is kept out of the answer.
class PythonIntrospector {
  PythonIntrospector(this.python, {this.onChange});
  final String python;
  final void Function()? onChange;

  List<String>? installed;
  final Map<String, Map<String, Member>> members = {};
  final Map<String, String> errors = {};
  final Set<String> _asking = {};
  bool _askingModules = false;

  static const _code = r'''
import contextlib, importlib, inspect, io, json, pkgutil, sys
out = {}
quiet = io.StringIO()
if sys.argv[1] == "modules":
    names = set(sys.builtin_module_names)
    for m in pkgutil.iter_modules():
        names.add(m.name)
    out = sorted(n for n in names if not n.startswith("_"))
else:
    for path in sys.argv[2:]:
        try:
            with contextlib.redirect_stdout(quiet), contextlib.redirect_stderr(quiet):
                parts = path.split(".")
                obj, i = None, len(parts)
                while i > 0:
                    try:
                        obj = importlib.import_module(".".join(parts[:i]))
                        break
                    except ImportError:
                        i -= 1
                if obj is None:
                    raise ImportError("no module " + parts[0])
                for p in parts[i:]:
                    obj = getattr(obj, p)
            members = {}
            for name in dir(obj)[:3000]:
                if name.startswith("_"):
                    continue
                try:
                    v = getattr(obj, name)
                except Exception:
                    continue
                kind = "module" if inspect.ismodule(v) else "class" if inspect.isclass(v) else "function" if callable(v) else "value"
                sig = ""
                if kind in ("function", "class"):
                    try:
                        sig = str(inspect.signature(v))
                    except Exception:
                        sig = ""
                doc = ((inspect.getdoc(v) or "").strip().split("\n")[0][:160]) if kind != "value" else type(v).__name__
                members[name] = [kind, sig, doc]
            if inspect.ismodule(obj) and hasattr(obj, "__path__"):
                try:
                    for m in pkgutil.iter_modules(obj.__path__):
                        if not m.name.startswith("_"):
                            members.setdefault(m.name, ["module", "", ""])
                except Exception:
                    pass
            out[path] = {"members": members}
        except BaseException as e:
            out[path] = {"error": (type(e).__name__ + ": " + str(e))[:200]}
print("\n@@koebelt@@" + json.dumps(out))
''';

  Future<Object?> _run(List<String> args) async {
    try {
      final r = await Process.run(python, ['-c', _code, ...args]).timeout(const Duration(seconds: 40));
      final s = '${r.stdout}';
      final i = s.lastIndexOf('@@koebelt@@');
      if (i < 0) return null;
      return jsonDecode(s.substring(i + 11));
    } catch (_) {
      return null;
    }
  }

  /// The installed top-level modules (asked once).
  void needModules() {
    if (installed != null || _askingModules) return;
    _askingModules = true;
    _run(['modules']).then((r) {
      installed = r is List ? r.cast<String>() : const [];
      onChange?.call();
    });
  }

  /// The members of [path] (asked once; null until known).
  Map<String, Member>? membersOf(String path) {
    final m = members[path];
    if (m != null || errors.containsKey(path) || _asking.contains(path)) return m;
    _asking.add(path);
    _run(['members', path]).then((r) {
      _asking.remove(path);
      final info = r is Map ? r[path] : null;
      if (info is Map && info['members'] is Map) {
        members[path] = {
          for (final e in (info['members'] as Map).entries)
            '${e.key}': (kind: '${(e.value as List)[0]}', sig: '${(e.value as List)[1]}', doc: '${(e.value as List)[2]}'),
        };
      } else {
        errors[path] = info is Map ? '${info['error']}' : 'no answer from Python';
      }
      onChange?.call();
    });
    return null;
  }
}
