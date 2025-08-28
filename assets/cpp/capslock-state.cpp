#include <iostream>

class CapsLockCheck {
private:
  std::string runCommand(const std::string &cmd) {
    FILE *pipe = popen(cmd.c_str(), "r");
    if (!pipe) {
      throw std::runtime_error("command error");
    }

    char buffer[256];
    std::string result;

    while (fgets(buffer, sizeof(buffer), pipe)) {
      result += buffer;
    }

    pclose(pipe);
    return result;
  }

  bool isCapsLockOn() {
    try {
      std::string output = runCommand("hyprctl devices -j | grep capsLock");
      return output.find("true") != std::string::npos;
    } catch (const std::exception &e) {
      throw e.what();
      return false;
    }
  }

public:
  void printStatus() { printf(isCapsLockOn() ? "1" : "0"); }
};

int main() {
  CapsLockCheck checker;
  checker.printStatus();
  return 0;
}
