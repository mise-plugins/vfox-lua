#include <stdlib.h>
#include "linenoise.h"

char *rl_readline_name = "linenoise";
static int history_initialized = 0;

char *readline(const char *prompt) {
    return linenoise(prompt);
}

void add_history(const char *line) {
    if (!history_initialized) {
        linenoiseHistorySetMaxLen(1000);
        history_initialized = 1;
    }
    linenoiseHistoryAdd(line);
}
