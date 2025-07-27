#include <xkbcommon/xkbregistry.h>
#include <string>
#include <iostream>

int main(int argc, char *argv[]) {
    std::string description = argv[1];

    auto* const context = rxkb_context_new(RXKB_CONTEXT_LOAD_EXOTIC_RULES);
    rxkb_context_parse_default_ruleset(context);

    rxkb_layout* layout = rxkb_layout_first(context);

    std::string brief = "";
    while (layout != nullptr) {
        std::string kbDescription = rxkb_layout_get_description(layout);

        if (kbDescription == description) {
            auto kbBrief = std::string(rxkb_layout_get_brief(layout));
            brief = kbBrief;
            break;
        } else
            layout = rxkb_layout_next(layout);
    }

    std::cout << brief;
    rxkb_context_unref(context);

    return 0;
}
