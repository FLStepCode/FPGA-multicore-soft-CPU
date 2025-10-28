import os
import shutil
import sys

lst_path = "../../rtl/lists"

new_files = ""

with open(f"{lst_path}/files_rtl.lst", "r") as f:
    rtl_files = f.readlines()

    for file in rtl_files:
        file = file.rstrip('\n')
        new_files = new_files + "../../rtl/" + file + " "

with open(f"files_rtl.lst", "w") as f:
    f.write(new_files)

with open(f"{lst_path}/modules_cctb.lst", "r") as f:
    modules_cctb = f.readlines()

    for module in modules_cctb:
        module = module.rstrip('\n')
        if (os.path.isfile(f"{module.split('/')[-1]}")):
            os.remove(f"{module.split('/')[-1]}")
        shutil.copy(os.path.abspath(f"../../rtl/{module}"), f"./{module.split('/')[-1]}")

with open(f"{lst_path}/files_hex.lst", "r") as f:
    hex_files = f.readlines()

    for file in hex_files:
        file = file.rstrip('\n')
        shutil.copyfile(f"../../rtl/{file}", f"{file.split('/')[-1]}")
