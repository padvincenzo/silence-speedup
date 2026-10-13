#include "single_instance.h"

#include <string>

namespace {

// Named per user, not globally: a per-user install of this app belongs to the
// session that started it, and two people signed in at once are two separate
// desktops with separate scratch space and separate preferences.
constexpr wchar_t kLockName[] = L"SilenceSpeedUp.SingleInstance";

// The class every Flutter desktop window is registered under. It is shared
// with every other Flutter app, so it narrows the search and settles nothing
// on its own.
constexpr wchar_t kFlutterWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

struct Search {
  DWORD own_process = 0;
  std::wstring own_image;
  HWND found = nullptr;
};

// The full path of the executable behind a process, or empty when it cannot
// be read — which is the usual answer for a process owned by someone else.
std::wstring ImageOf(DWORD process_id) {
  HANDLE handle =
      ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process_id);
  if (handle == nullptr) {
    return std::wstring();
  }

  wchar_t buffer[MAX_PATH] = {};
  DWORD length = MAX_PATH;
  std::wstring image;
  if (::QueryFullProcessImageNameW(handle, 0, buffer, &length)) {
    image.assign(buffer, length);
  }
  ::CloseHandle(handle);
  return image;
}

BOOL CALLBACK OnWindow(HWND window, LPARAM data) {
  Search* search = reinterpret_cast<Search*>(data);

  DWORD process_id = 0;
  ::GetWindowThreadProcessId(window, &process_id);
  if (process_id == 0 || process_id == search->own_process) {
    return TRUE;
  }

  wchar_t class_name[64] = {};
  ::GetClassNameW(window, class_name, 64);
  if (::wcscmp(class_name, kFlutterWindowClass) != 0) {
    return TRUE;
  }

  // Every Flutter app answers to that class name, so the executable behind
  // the window is what decides. Comparing paths also means a copy running
  // from somewhere else is left alone.
  if (ImageOf(process_id) != search->own_image) {
    return TRUE;
  }

  search->found = window;
  return FALSE;
}

// The window of the copy already running, if it has one yet.
HWND FindRunningWindow() {
  Search search;
  search.own_process = ::GetCurrentProcessId();
  search.own_image = ImageOf(search.own_process);
  if (search.own_image.empty()) {
    return nullptr;
  }

  ::EnumWindows(OnWindow, reinterpret_cast<LPARAM>(&search));
  return search.found;
}

// Brings [window] to the front, as far as Windows will allow.
void BringForward(HWND window) {
  if (::IsIconic(window)) {
    ::ShowWindow(window, SW_RESTORE);
  }

  if (::SetForegroundWindow(window)) {
    return;
  }

  // Windows refuses the foreground to a process that has not been given it,
  // and a refusal cannot be argued with. Flashing the taskbar button is what
  // is left: it says where the app went instead of leaving nothing at all.
  ::FlashWindow(window, TRUE);
}

}  // namespace

SingleInstance::SingleInstance() {
  lock_ = ::CreateMutexW(nullptr, TRUE, kLockName);
  if (lock_ == nullptr) {
    // Without the lock there is no way to tell; carrying on is better than
    // refusing to start.
    return;
  }

  if (::GetLastError() != ERROR_ALREADY_EXISTS) {
    return;
  }

  is_first_ = false;

  // The other copy may still be starting and have no window yet. Nothing is
  // gained by waiting for it: this process is leaving either way, and the
  // window it would have shown is the one about to appear.
  HWND running = FindRunningWindow();
  if (running != nullptr) {
    BringForward(running);
  }
}

SingleInstance::~SingleInstance() {
  if (lock_ == nullptr) {
    return;
  }
  // Releasing the mutex before closing it lets the next copy start the
  // moment this one is gone, rather than when the handle happens to be
  // reclaimed.
  if (is_first_) {
    ::ReleaseMutex(lock_);
  }
  ::CloseHandle(lock_);
}
