// RUN: %clang_cc1 -triple x86_64-linux-gnu -fsyntax-only -DCHECK_ERROR %s -verify 

float function_scope(float a) {
#pragma float_control(precise, on) junk // expected-warning {{extra tokens at end of '#pragma float_control' - ignored}}
  return a;
}

#ifdef CHECK_ERROR
#pragma float_control(push)
#pragma float_control(pop)
#pragma float_control(precise, on, push)
void check_stack() {
#pragma float_control(push)                   // expected-error {{can only appear at file scope}}
#pragma float_control(pop)                    // expected-error {{can only appear at file scope}}
#pragma float_control(precise, on, push)      // expected-error {{can only appear at file scope}}
#pragma float_control(except, on, push)       // expected-error {{can only appear at file scope}}
#pragma float_control(except, on, push, junk) // expected-error {{float_control is malformed}}
  return;
}
#endif

// RUN: %clang_cc1 -triple x86_64-linux-gnu -fdenormal-fp-math=preserve-sign,preserve-sign -ftrapping-math -fsyntax-only %s -DDEFAULT -verify
// RUN: %clang_cc1 -triple x86_64-linux-gnu -fsyntax-only %s -ffp-contract=fast -DPRECISE -verify
// RUN: %clang_cc1 -triple x86_64-linux-gnu -fsyntax-only %s -ftrapping-math -ffp-contract=off -frounding-math -ffp-exception-behavior=strict -DSTRICT -verify
// RUN: %clang_cc1 -triple x86_64-linux-gnu -menable-no-infs -menable-no-nans -menable-unsafe-fp-math -fno-signed-zeros -mreassociate -freciprocal-math -ffp-contract=fast -ffast-math -ffinite-math-only -fsyntax-only %s -DFAST -verify
double a = 0.0;
double b = 1.0;

//FIXME At some point this warning will be removed, until then
//      document the warning
#ifdef FAST
// expected-warning@+1{{pragma STDC FENV_ACCESS ON is not supported, ignoring pragma}}
#pragma STDC FENV_ACCESS ON // expected-error{{'#pragma STDC FENV_ACCESS ON' is illegal when precise is disabled}}
#else
#pragma STDC FENV_ACCESS ON // expected-warning{{pragma STDC FENV_ACCESS ON is not supported, ignoring pragma}}
#endif
#ifdef STRICT
#pragma float_control(precise, off) // expected-error {{'#pragma float_control(precise, off)' is illegal when except is enabled}}
#else
#pragma float_control(precise, off) // expected-error {{'#pragma float_control(precise, off)' is illegal when fenv_access is enabled}}
#endif

#pragma float_control(precise, on)
#pragma float_control(except, on) // OK
#ifndef STRICT
#pragma float_control(except, on)
#pragma float_control(precise, off) // expected-error {{'#pragma float_control(precise, off)' is illegal when except is enabled}}
#endif
int main() {
#ifdef STRICT
#pragma float_control(precise, off) // expected-error {{'#pragma float_control(precise, off)' is illegal when except is enabled}}
#else
#pragma float_control(precise, off) // expected-error {{'#pragma float_control(precise, off)' is illegal when except is enabled}}
#endif
#pragma float_control(except, on)
  //  error: '#pragma float_control(except, on)' is illegal when precise is disabled
  double x = b / a; // only used for fp flag setting
  if (a == a)       // only used for fp flag setting
    return 0;       //(int)x;
}
