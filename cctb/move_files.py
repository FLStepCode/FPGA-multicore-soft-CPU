import os

lst_path = "../rtl/lists"

new_files = ""

with open(f"{lst_path}/files_rtl.lst", "r") as f:
    rtl_files = f.readlines()

    for file in rtl_files:
        file = file.rstrip('\n')
        new_files = new_files + "../rtl/" + file + " "

with open(f"sim_build/files_rtl.lst", "w") as f:
    f.write(new_files)

with open(f"{lst_path}/modules_cctb.lst", "r") as f:
    modules_cctb = f.readlines()

    for module in modules_cctb:
        module = module.rstrip('\n')
        os.remove(f"./sim_build/{module.split('/')[-1]}")
        os.symlink(os.path.abspath(f"../rtl/{module}"), f"./sim_build/{module.split('/')[-1]}")