#!/usr/bin/env python3
"""Check Markdown language pairs, local links, and inline code formatting."""
from pathlib import Path
from urllib.parse import unquote
import re, sys
ROOT=Path(__file__).resolve().parent.parent
SKIP=set()
IGNORE={".git","node_modules","tmp","log","storage","coverage","vendor",".bundle"}
LINK=re.compile(r"(?<!\!)\[[^\]]*\]\(([^)\s]+)\)|!\[[^\]]*\]\(([^)\s]+)\)")
HTML=re.compile(r'(?:src|href)=["\x27]([^"\x27]+)["\x27]')
FENCE=re.compile(r"^\s*(?:\x60{3,}|~{3,})")
def pair(p):
    n=p.name
    if n.endswith(".en.md"):return p.with_name(n[:-6]+".vi.md")
    if n.endswith(".vi.md"):
        en=p.with_name(n[:-6]+".en.md")
        return en if en.exists() else p.with_name(n[:-6]+".md")
    return p.with_name(n[:-3]+".vi.md")
def run():
    docs=[p for p in ROOT.rglob("*.md") if not set(p.relative_to(ROOT).parts[:-1])&IGNORE]
    errors=[]; checked_links=0;paired=0
    for p in sorted(docs):
        rel=p.relative_to(ROOT).as_posix()
        text=p.read_text(encoding="utf-8")
        if rel not in SKIP:
            counterpart=pair(p)
            if not counterpart.is_file():errors.append(f"{rel}: missing {counterpart.name}")
            else:
                if not p.name.endswith(".vi.md"):paired+=1
                expected="English" if p.name.endswith(".vi.md") else "Tiếng Việt"
                m=re.search(r"\["+expected+r"\]\(([^)]+)\)",text)
                if not m:errors.append(f"{rel}: missing switch to {expected}")
                elif (p.parent/unquote(m.group(1))).resolve()!=counterpart.resolve():
                    errors.append(f"{rel}: switch points to wrong counterpart")
        fenced=False
        for line_no,line in enumerate(text.splitlines(),1):
            if FENCE.match(line):fenced=not fenced;continue
            if fenced:continue
            if '\u00ab' in line or '\u00bb' in line:
                errors.append(f'{rel}:{line_no}: unexpected guillemet in Markdown (check inline code)')
            if line.count('`') % 2:
                errors.append(f'{rel}:{line_no}: unbalanced inline backticks')
            matches=[x for m in LINK.finditer(line) for x in m.groups() if x]
            matches.extend(m.group(1) for m in HTML.finditer(line))
            for dest in matches:
                if dest.startswith(("#","https:","http:","mailto:","data:","//","{")):continue
                target=unquote(dest.strip("<>").split("#",1)[0].split("?",1)[0])
                if not target:continue
                checked_links+=1
                f=(p.parent/target).resolve()
                if not f.is_relative_to(ROOT) or not f.exists():errors.append(f"{rel}: broken local link {target}")
    print(f"DOC_FILES={len(docs)} PAIRS={paired} LOCAL_LINKS={checked_links}")
    for error in errors:print("ERROR:",error)
    print("DOC_AUDIT="+("FAIL" if errors else "PASS"))
    return int(bool(errors))
if __name__=="__main__":sys.exit(run())
