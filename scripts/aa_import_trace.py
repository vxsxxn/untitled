"""Static import trace: which hermes_cli modules do Aa's entry points reach?"""
import ast, os

root = "/opt/vxsxxn_bot/aa"
ENTRY = ("Aa_desktop.py", "Aa_selftest.py", "Aa_memory.py", "Aa_usage.py")

def imports_of(path):
    try:
        tree = ast.parse(open(path, encoding="utf-8", errors="replace").read())
    except SyntaxError:
        return []
    out = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            out += [a.name for a in node.names]
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            out.append(node.module)
    return out

def cli_files(mod_name):
    """map module name -> candidate files inside repo"""
    rel = mod_name.replace(".", "/")
    cands = [rel + ".py", os.path.join(rel, "__init__.py")]
    return [os.path.join(root, c) for c in cands if os.path.isfile(os.path.join(root, c))]

seed = [os.path.join(root, "scripts", e) for e in ENTRY]
reachable, seen, queue = set(), set(), list(seed)
while queue:
    path = queue.pop()
    if path in seen or not os.path.isfile(path):
        continue
    seen.add(path)
    for name in imports_of(path):
        top = name.split(".")[0]
        if top in ("hermes_cli", "hermes", "hermes_agent"):
            reachable.add(name)
            for fp in cli_files(name):
                if fp not in seen:
                    queue.append(fp)

total = sum(len(fs) for fs in [f for f in []])  # placeholder
count_cli = 0
for dp, dn, fn in os.walk(os.path.join(root, "hermes_cli")):
    dn[:] = [d for d in dn if d != "__pycache__"]
    count_cli += sum(1 for f in fn if f.endswith(".py"))

print(f"hermes_cli .py files total: {count_cli}")
print(f"reachable hermes_cli-family module names: {len(reachable)}")
for m in sorted(reachable):
    print(" ", m)
