/// Arithmétique exacte partagée par les jeux et les visuels.
///
/// Les manches des jeux sont calculées ici, jamais écrites à la main : une
/// manche est juste par construction.
library;

int gcd(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final t = x % y;
    x = y;
    y = t;
  }
  return x;
}

int lcm(int a, int b) => a == 0 || b == 0 ? 0 : (a ~/ gcd(a, b) * b).abs();

/// Reste euclidien : toujours dans 0 ≤ r < |m|.
int euclideanMod(int a, int m) {
  final r = a % m.abs();
  return r < 0 ? r + m.abs() : r;
}

/// Quotient euclidien associé à [euclideanMod] : a = b·q + r.
int euclideanQuotient(int a, int b) => (a - euclideanMod(a, b)) ~/ b;

/// base^exponent mod m, par exponentiation rapide.
int modPow(int base, int exponent, int m) {
  var result = 1 % m;
  var b = euclideanMod(base, m);
  var e = exponent;
  while (e > 0) {
    if (e.isOdd) result = result * b % m;
    b = b * b % m;
    e >>= 1;
  }
  return result;
}

/// Décomposition en facteurs premiers : premier → exposant (ordre croissant).
Map<int, int> factorize(int n) {
  final factors = <int, int>{};
  var rest = n.abs();
  for (var p = 2; p * p <= rest; p++) {
    while (rest % p == 0) {
      factors[p] = (factors[p] ?? 0) + 1;
      rest ~/= p;
    }
  }
  if (rest > 1) factors[rest] = (factors[rest] ?? 0) + 1;
  return factors;
}

/// Nombre de diviseurs positifs.
int divisorCount(int n) =>
    factorize(n).values.fold(1, (count, exponent) => count * (exponent + 1));

/// Écriture en base 2.
String toBinary(int n) => n.toRadixString(2);
