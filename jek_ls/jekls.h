#ifndef JEKLS_H
#define JEKLS_H

// Lists the entries of `path`. When `show_all` is non-zero, entries whose
// names begin with '.' (including "." and "..") are included; otherwise they
// are skipped. Returns 0 on success, -1 if the directory cannot be opened.
int list_dir(const char *path, int show_all);

#endif
