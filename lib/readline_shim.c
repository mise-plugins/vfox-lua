#include <stdlib.h>
#include "linenoise.h"

char *rl_readline_name = "linenoise";
static int history_initialized = 0;

char *readline(const char *prompt) {
    return linenoise(prompt);
}

void using_history(void) {
    if (!history_initialized) {
        linenoiseHistorySetMaxLen(1000);
        history_initialized = 1;
    }
}

void add_history(const char *line) {
    using_history();
    linenoiseHistoryAdd(line);
}
