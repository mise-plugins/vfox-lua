#ifndef _READLINE_H_
#define _READLINE_H_

extern char *rl_readline_name;

char *readline(const char *);
void rl_free(void *);

#endif
