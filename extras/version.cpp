#include <iostream>

int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string arg = argv[1];

        if (arg == "-t" || arg == "--terse") {
            std::cout << PROJECT_NAME << std::endl;
            std::cout << VERSION << std::endl;
            std::cout << GIT_REVISION << std::endl;
            std::cout << DISTRIBUTOR << std::endl;
        } else if (arg == "-s" || arg == "--short") {
            std::cout << PROJECT_NAME << " " << VERSION << ", revision " << GIT_REVISION << ", distrubuted by: " << DISTRIBUTOR << std::endl;
        } else {
            std::cout << "Usage: " << argv[0] << " [-t | --terse] [-s | --short]" << std::endl;
            return arg != "-h" && arg != "--help";
        }
    } else {
        std::cout << "Project: " << PROJECT_NAME << std::endl;
        std::cout << "Version: " << VERSION << std::endl;
        std::cout << "Git revision: " << GIT_REVISION << std::endl;
        std::cout << "Distributor: " << DISTRIBUTOR << std::endl;
    }

    return 0;
}
