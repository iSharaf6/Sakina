#!/usr/bin/env python3
"""Register new source/resource files in Sakina.xcodeproj (app target only).
Usage: register_files.py <repo-relative path> [...]
Idempotent: paths already referenced are skipped. Creates PBXGroups for
new directories directly under Sakina/ and adds Shared/Resources files to the
Shared/Resources group."""
import re, sys, secrets, os
PBX = "Sakina.xcodeproj/project.pbxproj"
SAKINA_GROUP = "E7765FE3C400A4D239818254"      # /* Sakina */
SHARED_RES_GROUP = "4437C01E203EBF9D07991845"  # Shared/Resources
APP_SOURCES = "FAA20BA8A79231457ADE6F50"       # Sakina target Sources phase
APP_RESOURCES = "DD6231B5458C8E9918794B0A"     # Sakina target Resources phase
src = open(PBX).read()
def uid():
    return secrets.token_hex(12).upper()
def group_id(name):
    m = re.search(r"([0-9A-F]{24}) /\* %s \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \((?:.|\n)*?path = %s;" % (re.escape(name), re.escape(name)), src)
    return m.group(1) if m else None
def add_child(gid, ref, name):
    global src
    pat = re.compile(r"(%s /\* [^*]* \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)" % gid)
    assert pat.search(src), gid
    src = pat.sub(lambda m: m.group(1) + "\t\t\t\t%s /* %s */,\n" % (ref, name), src, count=1)
def add_phase(pid, bf, name, phase):
    global src
    pat = re.compile(r"(%s /\* %s \*/ = \{\n\t\t\tisa = PBX\w+BuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \(\n)" % (pid, phase))
    assert pat.search(src), pid
    src = pat.sub(lambda m: m.group(1) + "\t\t\t\t%s /* %s in %s */,\n" % (bf, name, phase), src, count=1)
def ensure_group(dirname):
    gid = group_id(dirname)
    if gid: return gid
    gid = uid()
    block = "\t\t%s /* %s */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t);\n\t\t\tpath = %s;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n" % (gid, dirname, dirname)
    global src
    src = src.replace("/* End PBXGroup section */", block + "/* End PBXGroup section */")
    add_child(SAKINA_GROUP, gid, dirname)
    return gid
for path in sys.argv[1:]:
    name = os.path.basename(path)
    if "/* %s */" % name in src:
        print("skip (already referenced):", path); continue
    ref, bf = uid(), uid()
    if name.endswith(".swift"):
        ftype, phase_id, phase = "sourcecode.swift", APP_SOURCES, "Sources"
    elif name.endswith(".json"):
        ftype, phase_id, phase = "text.json", APP_RESOURCES, "Resources"
    else:
        sys.exit("unsupported file type: " + path)
    src = src.replace("/* End PBXFileReference section */",
        "\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; path = %s; sourceTree = \"<group>\"; };\n/* End PBXFileReference section */" % (ref, name, ftype, name))
    src = src.replace("/* End PBXBuildFile section */",
        "\t\t%s /* %s in %s */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n/* End PBXBuildFile section */" % (bf, name, phase, ref, name))
    parts = path.split("/")
    if parts[0] == "Shared" and parts[1] == "Resources":
        gid = SHARED_RES_GROUP
    elif parts[0] == "Sakina" and len(parts) == 3:
        gid = ensure_group(parts[1])
    else:
        sys.exit("unsupported location: " + path)
    add_child(gid, ref, name)
    add_phase(phase_id, bf, name, phase)
    print("registered:", path)
open(PBX, "w").write(src)
