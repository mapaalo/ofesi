"""Make Ollama's qwen3.5 GGUF loadable by upstream llama.cpp.

Ollama writes the rope section lists with 3 entries; upstream llama.cpp expects 4
(its own converter pads with 0). Usage: python pad_rope_sections.py in.gguf out.gguf
"""
import sys
import gguf
from gguf.scripts.gguf_new_metadata import MetadataDetails, copy_with_new_metadata

src, dst = sys.argv[1], sys.argv[2]
reader = gguf.GGUFReader(src)
arch = reader.fields["general.architecture"].contents()
keys = [k for k in reader.fields if k.startswith(f"{arch}.") and k.endswith(("dimension_sections", "mrope_sections", "mrope_section"))]
new = {}
for k in keys:
    vals = list(reader.fields[k].contents())
    assert len(vals) <= 4, (k, vals)
    new[k] = MetadataDetails(gguf.GGUFValueType.ARRAY, vals + [0] * (4 - len(vals)), sub_type=gguf.GGUFValueType.INT32)
# gguf-py refuses to write empty arrays (Ollama leaves vision.deepstack_visual_indexes empty); drop them.
empty = [k for k, f in reader.fields.items() if f.types and f.types[0] == gguf.GGUFValueType.ARRAY and not f.data]
print("padding:", {k: v.value for k, v in new.items()}, "dropping empty:", empty)
writer = gguf.GGUFWriter(dst, arch=arch, endianess=reader.endianess)
copy_with_new_metadata(reader, writer, new, empty)
