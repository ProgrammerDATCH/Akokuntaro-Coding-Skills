"""Delete guard rules; called by delete-guard.sh with: <command> <cwd> <home>.
Prints the reason when the command must be refused, nothing otherwise."""
import os, re, shlex, sys

cmd, cwd, home = sys.argv[1], sys.argv[2] or os.getcwd(), sys.argv[3]

# Heredoc bodies are data, not commands.
cmd = re.sub(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n.*?\n\s*\2\s*(\n|$)", "\n", cmd, flags=re.S)

BUILD_DIRS = {"node_modules", "dist", "build", ".next", "out", "coverage", ".turbo", ".cache",
              ".expo", "__pycache__", ".pytest_cache", ".parcel-cache"}
TEMP_ROOTS = ("/tmp/", "/private/tmp/", "/var/folders/", "/private/var/folders/")
GUARDED = re.compile(r"\$\{[A-Za-z_][A-Za-z0-9_]*:\?[^}]*\}")
WRAPPERS = {"command", "builtin", "exec", "nohup", "time", "nice", "env"}
CONTROL = {";", "&&", "||", "|", "&", "(", ")", "|&", ";;"}

def tokens(text):
    lex = shlex.shlex(text.replace("\n", " ; "), posix=True, punctuation_chars=";&|()")
    lex.whitespace_split = True
    lex.commenters = "#"
    try:
        return list(lex)
    except ValueError:  # unbalanced quotes: let the shell itself complain
        return []

def segments(toks):
    seg = []
    for t in toks:
        if t in CONTROL:
            if seg: yield seg
            seg = []
        else:
            seg.append(t)
    if seg: yield seg

def unguarded_var(arg):
    return "$" in GUARDED.sub("", arg) or "`" in arg

def resolve(arg, here):
    p = arg
    if p == "~" or p.startswith("~/"):
        p = home + p[1:]
    p = re.split(r"[*?\[]", p, maxsplit=1)[0] or "/"      # the part before any glob
    if not p.startswith("/"):
        p = os.path.join(here, p)
    return os.path.normpath(p)

def too_wide(arg, here, recursive):
    """/, home or a temp root itself, always; any glob or recursive delete under three folders deep
    (/Users/david/*), except a named folder inside a temp root."""
    if GUARDED.search(arg):
        return None  # can't be resolved here; ${VAR:?} at least refuses an empty value
    p = resolve(arg, here)
    if p in ("/", home) or p + "/" in TEMP_ROOTS:
        return f"'{arg}' reaches {p}"
    depth = len([c for c in p.split("/") if c])
    if (recursive or re.search(r"[*?\[]", arg)) and depth < 3 and not (p + "/").startswith(TEMP_ROOTS):
        return f"'{arg}' reaches {p}"
    return None

def routine(arg, here):
    if GUARDED.search(arg):
        return True
    p = resolve(arg, here) + "/"
    if p.startswith(TEMP_ROOTS):
        return True
    return any(part in BUILD_DIRS for part in p.split("/"))

def check_rm(args, here, via_xargs=False):
    flags, targets, end = "", [], False
    for a in args:
        if not end and a == "--":
            end = True
        elif not end and a.startswith("--"):
            flags += "r" if a == "--recursive" else ""
        elif not end and a.startswith("-") and len(a) > 1:
            flags += a[1:]
        else:
            targets.append(a)
    recursive = "r" in flags or "R" in flags
    if via_xargs and recursive:
        return "xargs rm -r: the targets can't be checked. List the paths, or delete inside the scratchpad."
    for t in targets:
        if unguarded_var(t):
            return (f"rm on '{t}': an unguarded variable. If it is empty or unset the path collapses "
                    f"(rm $S/* becomes rm /*). Write \"${{S:?}}\" so the shell stops instead, or use a "
                    f"literal path.")
        wide = too_wide(t, here, recursive)
        if wide:
            return f"rm {wide}: far too wide. Name the exact folder."
        if recursive and not routine(t, here):
            return (f"rm -r on '{t}' ({resolve(t, here)}): recursive deletes are only for the "
                    f"session scratchpad, temp folders and build output (node_modules, dist, .next...). "
                    f"Delete the specific files, or ask David to remove the folder.")
    return None

def check_find(args, here):
    if "-delete" not in args and not ("-exec" in args and "rm" in args):
        return None
    paths = []
    for a in args:
        if a.startswith("-") or a in ("(", ")", "!"):
            break
        paths.append(a)
    for p in paths or ["."]:
        if unguarded_var(p):
            return f"find -delete in '{p}': an unguarded variable. Write \"${{S:?}}\" or a literal path."
        wide = too_wide(p, here, True)
        if wide:
            return f"find -delete: {wide}. Name the exact folder."
        if not routine(p, here):
            return (f"find -delete in '{p}' ({resolve(p, here)}): only inside the session scratchpad, temp "
                    f"folders or build output. Delete the specific files instead.")
    return None

here = cwd
for seg in segments(tokens(cmd)):
    i = 0
    while i < len(seg) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", seg[i]):
        i += 1                                   # VAR=value before the command
    while i < len(seg) and seg[i] in WRAPPERS:
        i += 1
    if i >= len(seg):
        continue
    prog, rest = os.path.basename(seg[i]), seg[i + 1:]
    if prog == "sudo":
        print("sudo: never run as root from an agent. If something needs root, ask David to run it."); break
    if prog == "cd" and rest and not unguarded_var(rest[0]):
        here = resolve(rest[0], here) if rest[0] != "-" else here
        continue
    problem = None
    if prog == "rm":
        problem = check_rm(rest, here)
    elif prog == "find":
        problem = check_find(rest, here)
    elif prog == "xargs":
        j = 0
        while j < len(rest) and rest[j].startswith("-"):
            j += 1
        if j < len(rest) and os.path.basename(rest[j]) == "rm":
            problem = check_rm(rest[j + 1:], here, via_xargs=True)
    if problem:
        print(problem); break
