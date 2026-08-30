#include <iostream>

int main(int argc, char* argv[]) {
    if (argc > 1) {
        const std::string arg = argv[1];

        if (arg == "-t" || arg == "--terse") {
            std::cout << PROJECT_NAME << '\n';
            std::cout << VERSION << '\n';
            std::cout << GIT_REVISION << '\n';
            std::cout << DISTRIBUTOR << '\n';
        } else if (arg == "-s" || arg == "--short") {
            std::cout << PROJECT_NAME << " " << VERSION << ", revision " << GIT_REVISION
                      << ", distributed by: " << DISTRIBUTOR << '\n';
        } else {
            std::cout << "Usage: " << argv[0] << " [-t | --terse] [-s | --short]" << '\n';
            return arg != "-h" && arg != "--help";
        }
    } else {
        std::cout << "Project: " << PROJECT_NAME << '\n';
        std::cout << "Version: " << VERSION << '\n';
        std::cout << "Git revision: " << GIT_REVISION << '\n';
        std::cout << "Distributor: " << DISTRIBUTOR << '\n';
    }

    return 0;
}
