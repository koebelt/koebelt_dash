/// Check: what would stop a script before it moves anything, found with the
/// script's own Python without running it.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'imports.dart' show pipNameFor;

/// One thing Check found: a line (1-based), what is wrong, and whether it
/// would stop the script (an error) or may be fine (a warning).
class ScriptProblem {
  const ScriptProblem(this.line, this.message, {this.warning = false, this.module});
  final int line;
  final String message;
  final bool warning;

  /// A module the script imports that this Python lacks.
  final String? module;

  @override
  String toString() => 'Line $line: $message';
}

/// The checker, run by the script's Python from the script's folder (so its
/// own modules import), reading the source on stdin:
///
/// - it compiles (syntax, and what only the compiler sees: return outside a
///   function, a misplaced nonlocal…);
/// - its imports resolve, and `from m import name` finds the name;
/// - every name it reads is defined somewhere in it, or is a built-in;
/// - what it calls on the device exists, with arguments that fit.
const _checker = r'''
import ast, builtins, contextlib, difflib, importlib, importlib.util, inspect, io, json, sys

src = sys.stdin.read()
out = []
def say(line, msg, warn=False, module=None):
    out.append({"line": line or 1, "msg": msg, "warn": warn, "module": module})

def close(name, pool):
    m = difflib.get_close_matches(name, list(pool), n=1, cutoff=0.75)
    return f" (did you mean “{m[0]}”?)" if m else ""

try:
    tree = ast.parse(src)
    compile(src, "<script>", "exec")
except SyntaxError as e:
    say(e.lineno, e.msg)
    print("@@koebelt@@" + json.dumps(out)); sys.exit()

parents = {}
for node in ast.walk(tree):
    for child in ast.iter_child_nodes(node):
        parents[child] = node
def in_try(node):
    while node in parents:
        node = parents[node]
        if isinstance(node, ast.Try):
            return True
    return False

quiet = io.StringIO()
def load(name):
    with contextlib.redirect_stdout(quiet), contextlib.redirect_stderr(quiet):
        return importlib.import_module(name)

# Imports.
for node in ast.walk(tree):
    optional = in_try(node)
    if isinstance(node, ast.Import):
        for a in node.names:
            try:
                found = importlib.util.find_spec(a.name) is not None
            except Exception:
                found = False
            if not found:
                say(node.lineno, f"no module “{a.name}” in this Python", optional, a.name.split(".")[0])
    elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
        try:
            mod = load(node.module)
        except ModuleNotFoundError as e:
            say(node.lineno, f"no module “{e.name or node.module}” in this Python", optional, (e.name or node.module).split(".")[0])
            continue
        except BaseException as e:
            say(node.lineno, f"importing “{node.module}” fails: {type(e).__name__}: {e}"[:200], True)
            continue
        for a in node.names:
            if a.name == "*" or hasattr(mod, a.name):
                continue
            try:
                if importlib.util.find_spec(f"{node.module}.{a.name}") is not None:
                    continue
            except Exception:
                pass
            pool = [n for n in dir(mod) if not n.startswith("_")]
            say(node.lineno, f"“{node.module}” has no “{a.name}”{close(a.name, pool)}", optional)

# Names read but never defined anywhere in the script.
bound = set(dir(builtins)) | {"__file__", "__name__", "__doc__"}
star = False
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
        bound.add(node.name)
    elif isinstance(node, ast.Name) and isinstance(node.ctx, (ast.Store, ast.Del)):
        bound.add(node.id)
    elif isinstance(node, ast.arg):
        bound.add(node.arg)
    elif isinstance(node, (ast.Import, ast.ImportFrom)):
        for a in node.names:
            if a.name == "*":
                star = True
            bound.add((a.asname or a.name).split(".")[0])
    elif isinstance(node, ast.ExceptHandler) and node.name:
        bound.add(node.name)
    elif isinstance(node, (ast.Global, ast.Nonlocal)):
        bound.update(node.names)
    elif hasattr(ast, "MatchAs") and isinstance(node, ast.MatchAs) and node.name:
        bound.add(node.name)
    elif hasattr(ast, "MatchStar") and isinstance(node, ast.MatchStar) and node.name:
        bound.add(node.name)
    elif hasattr(ast, "MatchMapping") and isinstance(node, ast.MatchMapping) and node.rest:
        bound.add(node.rest)
seen = set()
if not star:
    for node in ast.walk(tree):
        if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load) and node.id not in bound and node.id not in seen:
            seen.add(node.id)
            say(node.lineno, f"“{node.id}” is not defined{close(node.id, bound)}")

# The device: names bound to connect(), what they use, and how they call it.
try:
    from koebelt_dash_scripts.client import Device
except Exception:
    Device = None
if Device is not None:
    devs = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Call):
            f = node.value.func
            if (isinstance(f, ast.Name) and f.id == "connect") or (isinstance(f, ast.Attribute) and f.attr == "connect"):
                devs.update(t.id for t in node.targets if isinstance(t, ast.Name))
    api = [n for n in dir(Device) if not n.startswith("_")]
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name) and node.value.id in devs):
            continue
        if not hasattr(Device, node.attr) and not node.attr.startswith("_"):
            say(node.lineno, f"the device has no “{node.attr}”{close(node.attr, api)}")
            continue
        call = parents.get(node)
        member = inspect.getattr_static(Device, node.attr, None)
        if not (isinstance(call, ast.Call) and call.func is node and inspect.isfunction(member)):
            continue
        if any(isinstance(a, ast.Starred) for a in call.args) or any(k.arg is None for k in call.keywords):
            continue
        try:
            inspect.signature(member).bind(None, *call.args, **{k.arg: None for k in call.keywords})
        except TypeError as e:
            say(call.lineno, f"{node.attr}(): {e}")

print("@@koebelt@@" + json.dumps(out))
''';

/// What Check finds in [source], with [python] from [folder] (the script's
/// own); sorted by line. Null if this Python could not run the checker.
Future<List<ScriptProblem>?> checkScript(String python, String source, {String? folder}) async {
  try {
    final p = await Process.start(python, ['-c', _checker], workingDirectory: folder != null && Directory(folder).existsSync() ? folder : null);
    p.stdin.write(source);
    await p.stdin.close();
    final out = p.stdout.transform(utf8.decoder).join();
    p.stderr.drain<void>();
    await p.exitCode.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        p.kill();
        return -1;
      },
    );
    final s = await out;
    final i = s.lastIndexOf('@@koebelt@@');
    if (i < 0) return null;
    return [
      for (final j in (jsonDecode(s.substring(i + 11)) as List).cast<Map>())
        ScriptProblem(
          (j['line'] as num).toInt(),
          j['module'] == null ? '${j['msg']}' : '${j['msg']}: pip install ${pipNameFor('${j['module']}')}',
          warning: j['warn'] == true,
          module: j['module'] as String?,
        ),
    ]..sort((a, b) => a.line.compareTo(b.line));
  } catch (_) {
    return null;
  }
}

/// "2 errors, 1 warning", or that it is fine.
String describeCheck(List<ScriptProblem> problems) {
  final e = problems.where((p) => !p.warning).length, w = problems.length - e;
  if (problems.isEmpty) return 'Check: it compiles, its imports resolve, and what it uses exists.';
  String n(int k, String one) => '$k $one${k == 1 ? '' : 's'}';
  return 'Check: ${[if (e > 0) n(e, 'error'), if (w > 0) n(w, 'warning')].join(', ')}';
}
