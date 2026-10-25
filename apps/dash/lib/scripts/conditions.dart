import 'dart:math' as math;

/// Conditions that fire script triggers: a small, safe expression language
/// evaluated by dash on telemetry (no Python, so they also work on a phone
/// without a script host).
///
///     battery.pct < 25 for 3s
///     home.distance > 80 and armed
///     motor_temp.max > 70 or mode == "FAILSAFE"
///
/// Fields, numbers, strings, `true`/`false`, comparisons, `+ - * /`,
/// `and`/`or`/`not`, `abs`, `min`, `max`, parentheses, and an optional
/// `for <duration>` at the end (`3s`, `500ms`, `2min`): true for that long.
class ConditionError implements Exception {
  ConditionError(this.message, [this.at]);
  final String message;

  /// Character offset in the source, when known.
  final int? at;
  @override
  String toString() => message;
}

/// Looks up a field (`battery.pct` → `['battery', 'pct']`); null if unknown.
typedef FieldLookup = Object? Function(List<String> path);

sealed class _Node {
  Object? eval(FieldLookup f);
}

class _Lit extends _Node {
  _Lit(this.v);
  final Object v;
  @override
  Object? eval(FieldLookup f) => v;
}

class _Field extends _Node {
  _Field(this.path);
  final List<String> path;
  @override
  Object? eval(FieldLookup f) {
    final v = f(path);
    if (v == null) throw ConditionError('No field "${path.join('.')}" on this device right now');
    return v;
  }
}

class _Unary extends _Node {
  _Unary(this.op, this.a);
  final String op;
  final _Node a;
  @override
  Object? eval(FieldLookup f) => op == 'not' ? !_bool(a.eval(f)) : -_num(a.eval(f));
}

class _Binary extends _Node {
  _Binary(this.op, this.a, this.b);
  final String op;
  final _Node a, b;
  @override
  Object? eval(FieldLookup f) {
    if (op == 'and') return _bool(a.eval(f)) && _bool(b.eval(f));
    if (op == 'or') return _bool(a.eval(f)) || _bool(b.eval(f));
    final x = a.eval(f), y = b.eval(f);
    switch (op) {
      case '==':
        return _eq(x, y);
      case '!=':
        return !_eq(x, y);
    }
    final p = _num(x), q = _num(y);
    return switch (op) {
      '<' => p < q,
      '<=' => p <= q,
      '>' => p > q,
      '>=' => p >= q,
      '+' => p + q,
      '-' => p - q,
      '*' => p * q,
      '/' => q == 0 ? double.nan : p / q,
      _ => throw StateError(op),
    };
  }
}

class _Call extends _Node {
  _Call(this.fn, this.args);
  final String fn;
  final List<_Node> args;
  @override
  Object? eval(FieldLookup f) {
    final v = [for (final a in args) _num(a.eval(f))];
    return switch (fn) {
      'abs' => v.single.abs(),
      'min' => v.reduce(math.min),
      'max' => v.reduce(math.max),
      _ => throw StateError(fn),
    };
  }
}

bool _eq(Object? x, Object? y) {
  if (x is String || y is String) return '$x'.toUpperCase() == '$y'.toUpperCase();
  if (x is bool || y is bool) return _bool(x) == _bool(y);
  return _num(x) == _num(y);
}

double _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v is List && v.isNotEmpty && v.first is num) return (v.first as num).toDouble();
  throw ConditionError('"$v" is not a number');
}

bool _bool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.isNotEmpty;
  throw ConditionError('"$v" is not true or false');
}

/// A parsed condition.
class Condition {
  Condition._(this.source, this._root, this.holdFor);
  final String source;
  final _Node _root;

  /// How long it must stay true before it counts (the `for` clause).
  final Duration holdFor;

  /// The fields it reads, as dotted paths.
  final Set<String> fields = {};

  bool test(FieldLookup f) => _bool(_root.eval(f));

  static Condition parse(String source) => _Parser(source).parse();
}

class _Tok {
  _Tok(this.kind, this.text, this.at);
  final String kind; // num str id op end
  final String text;
  final int at;
}

class _Parser {
  _Parser(this.src) {
    _lex();
  }
  final String src;
  final List<_Tok> _t = [];
  int _i = 0;
  final Set<String> _fields = {};

  static const _keywords = {'and', 'or', 'not', 'for', 'true', 'false'};

  void _lex() {
    final re = RegExp(
      r'\s*(?:(\d+(?:\.\d+)?|\.\d+)|("[^"]*"|'
      "'[^']*'"
      r')|([A-Za-z_][A-Za-z0-9_]*)|(<=|>=|==|!=|<|>|\+|-|\*|/|\(|\)|,|\.|\[|\])|(\S))',
    );
    var pos = 0;
    while (pos < src.length) {
      final m = re.matchAsPrefix(src, pos);
      if (m == null) break;
      if (m[0]!.trim().isEmpty) break;
      final at = m.start + m[0]!.indexOf(m[0]!.trim()[0]);
      if (m[1] != null) {
        _t.add(_Tok('num', m[1]!, at));
      } else if (m[2] != null) {
        _t.add(_Tok('str', m[2]!.substring(1, m[2]!.length - 1), at));
      } else if (m[3] != null) {
        _t.add(_Tok('id', m[3]!, at));
      } else if (m[4] != null) {
        _t.add(_Tok('op', m[4]!, at));
      } else {
        throw ConditionError('Unexpected "${m[5]}"', at);
      }
      pos = m.end;
    }
    _t.add(_Tok('end', '', src.length));
  }

  _Tok get _peek => _t[_i];
  _Tok _next() => _t[_i++];
  bool _isOp(String s) => _peek.kind == 'op' && _peek.text == s;
  bool _isWord(String s) => _peek.kind == 'id' && _peek.text == s;

  Never _fail(String what) {
    final t = _peek;
    throw ConditionError(t.kind == 'end' ? '$what at the end' : '$what before "${t.text}"', t.at);
  }

  Condition parse() {
    if (src.trim().isEmpty) throw ConditionError('Empty condition', 0);
    final root = _or();
    var hold = Duration.zero;
    if (_isWord('for')) {
      _next();
      hold = _duration();
    }
    if (_peek.kind != 'end') _fail('Expected "and", "or", "for" or a comparison');
    return Condition._(src, root, hold)..fields.addAll(_fields);
  }

  Duration _duration() {
    if (_peek.kind != 'num') _fail('Expected a duration like 3s');
    final n = double.parse(_next().text);
    var unit = 's';
    if (_peek.kind == 'id' && const {'s', 'ms', 'min'}.contains(_peek.text)) unit = _next().text;
    final ms =
        n *
        (unit == 'ms'
            ? 1
            : unit == 'min'
            ? 60000
            : 1000);
    return Duration(milliseconds: ms.round());
  }

  _Node _or() {
    var a = _and();
    while (_isWord('or')) {
      _next();
      a = _Binary('or', a, _and());
    }
    return a;
  }

  _Node _and() {
    var a = _not();
    while (_isWord('and')) {
      _next();
      a = _Binary('and', a, _not());
    }
    return a;
  }

  _Node _not() {
    if (_isWord('not')) {
      _next();
      return _Unary('not', _not());
    }
    return _cmp();
  }

  _Node _cmp() {
    final a = _sum();
    for (final op in const ['<=', '>=', '==', '!=', '<', '>']) {
      if (_isOp(op)) {
        _next();
        return _Binary(op, a, _sum());
      }
    }
    return a;
  }

  _Node _sum() {
    var a = _prod();
    while (_isOp('+') || _isOp('-')) {
      final op = _next().text;
      a = _Binary(op, a, _prod());
    }
    return a;
  }

  _Node _prod() {
    var a = _unary();
    while (_isOp('*') || _isOp('/')) {
      final op = _next().text;
      a = _Binary(op, a, _unary());
    }
    return a;
  }

  _Node _unary() {
    if (_isOp('-')) {
      _next();
      return _Unary('-', _unary());
    }
    return _primary();
  }

  _Node _primary() {
    final t = _peek;
    if (t.kind == 'num') {
      _next();
      return _Lit(double.parse(t.text));
    }
    if (t.kind == 'str') {
      _next();
      return _Lit(t.text);
    }
    if (_isOp('(')) {
      _next();
      final e = _or();
      if (!_isOp(')')) _fail('Expected ")"');
      _next();
      return e;
    }
    if (t.kind == 'id') {
      if (t.text == 'true' || t.text == 'false') {
        _next();
        return _Lit(t.text == 'true');
      }
      if (_keywords.contains(t.text)) _fail('Expected a value');
      _next();
      if (_isOp('(')) {
        if (!const {'abs', 'min', 'max'}.contains(t.text)) throw ConditionError('Unknown function "${t.text}" (abs, min, max)', t.at);
        _next();
        final args = <_Node>[_or()];
        while (_isOp(',')) {
          _next();
          args.add(_or());
        }
        if (!_isOp(')')) _fail('Expected ")"');
        _next();
        if (t.text == 'abs' && args.length != 1) throw ConditionError('abs takes one value', t.at);
        return _Call(t.text, args);
      }
      final path = [t.text];
      while (true) {
        if (_isOp('.')) {
          _next();
          if (_peek.kind != 'id') _fail('Expected a field name');
          path.add(_next().text);
        } else if (_isOp('[')) {
          _next();
          if (_peek.kind != 'num') _fail('Expected an index');
          path.add(_next().text);
          if (!_isOp(']')) _fail('Expected "]"');
          _next();
        } else {
          break;
        }
      }
      _fields.add(path.join('.'));
      return _Field(path);
    }
    _fail('Expected a value');
  }
}

/// A condition watched over time: reports when it becomes true (after its
/// `for` duration) and when it stops being true.
class ConditionWatch {
  ConditionWatch(this.condition);
  final Condition condition;
  bool active = false;
  double _trueFor = 0;

  /// The last evaluation error (an unknown field…), shown next to the trigger.
  String? error;

  /// The current value, for display: null until evaluated.
  bool? now;

  /// Returns true when it fires, false when it clears, null otherwise.
  bool? step(double dt, FieldLookup f) {
    bool v;
    try {
      v = condition.test(f);
      error = null;
    } on ConditionError catch (e) {
      error = e.message;
      v = false;
    }
    now = v;
    _trueFor = v ? _trueFor + dt : 0;
    final held = v && _trueFor * 1000 >= condition.holdFor.inMilliseconds;
    if (held && !active) {
      active = true;
      return true;
    }
    if (!v && active) {
      active = false;
      return false;
    }
    return null;
  }
}

/// A condition as the picker shows it: field, comparison, number, duration.
/// Null when an expression does not fit that shape.
typedef PickedCondition = ({String field, String op, double value, double seconds});

PickedCondition? pickedFrom(String source) {
  final m = RegExp(r'^\s*([A-Za-z_][\w.]*(?:\[\d+\])?)\s*(<=|>=|==|!=|<|>)\s*(-?\d+(?:\.\d+)?)\s*(?:for\s+(\d+(?:\.\d+)?)\s*s)?\s*$').firstMatch(source);
  if (m == null) return null;
  return (field: m[1]!, op: m[2]!, value: double.parse(m[3]!), seconds: m[4] == null ? 0 : double.parse(m[4]!));
}

String expressionOf(PickedCondition p) {
  String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return '${p.field} ${p.op} ${n(p.value)}${p.seconds > 0 ? ' for ${n(p.seconds)}s' : ''}';
}
