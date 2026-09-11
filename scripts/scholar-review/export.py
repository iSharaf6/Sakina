"""Export the actual Swift catalog, not a second hand-maintained content copy."""
from pathlib import Path
import subprocess, tempfile, shutil, sys
root = Path(__file__).resolve().parents[2]
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='haneen-review-') as work:
    work = Path(work)
    (work/'main.swift').write_text((root/'scripts/scholar-review/ExportContent.swift').read_text())
    # Extract model-only declarations from files whose remaining content is iOS UI.
    for source, marker, name in [
        ('Sakina/Duas/DailyDuaCatalog.swift','enum DuaPractice:','Daily.swift'),
        ('Sakina/Duas/NamesOfAllahView.swift','struct NamesOfAllahView:','Names.swift')]:
        (work/name).write_text((root/source).read_text().split(marker)[0])
    sources = ['Shared/QuranCatalog.swift','Shared/Localization.swift','Shared/ArabicReflections.swift',
               'Shared/GuidanceCatalog.swift','Shared/CompanionContent.swift','Sakina/Duas/DuaCollection.swift',
               'Sakina/Duas/DuaLibrary.swift','Sakina/Duas/RuqyahCatalog.swift']
    subprocess.run(['swiftc',*[str(root/s) for s in sources],str(work/'Daily.swift'),str(work/'Names.swift'),str(work/'main.swift'),'-o',str(work/'export')],check=True)
    for resource in ['ruqyah.json','verses.json']:
        shutil.copyfile(root/'Shared/Resources'/resource,work/resource)
    subprocess.run([str(work/'export'),str(out)],check=True)
    shutil.copyfile(root/'Shared/Resources/verses.json',out/'verses.json')
    shutil.copyfile(root/'Shared/Resources/quran.json',out/'quran.json')
