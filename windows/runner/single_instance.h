#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <windows.h>

// Keeps one copy of the app running at a time.
//
// Two copies share the things that are not shareable: the scratch directory
// where fragments are written, and the preferences file, which each of them
// rewrites whole from whatever it happened to load at startup. A second copy
// is therefore never what someone wants; what they want is the copy they
// already have, in front of them.
//
// Enforced here rather than in Dart because here is early enough that a
// second window never appears, and because bringing another process forward
// is a Win32 errand either way.
class SingleInstance {
 public:
  SingleInstance();
  ~SingleInstance();

  SingleInstance(const SingleInstance&) = delete;
  SingleInstance& operator=(const SingleInstance&) = delete;

  // True when this process is the first one. False when another is already
  // running, in which case that one has been brought to the front and this
  // one should leave without starting an engine.
  bool IsFirst() const { return is_first_; }

 private:
  HANDLE lock_ = nullptr;
  bool is_first_ = true;
};

#endif  // RUNNER_SINGLE_INSTANCE_H_
