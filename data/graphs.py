import matplotlib.pyplot as plt
import json

fig, ax = plt.subplots(4, 2)

a = ""
with open("pmu_dump_dual_parallel.json", "r") as f:
    a = f.read()
data = json.loads(a)

b = [1, 2, 4, 8]

for j in range(4):

    data_1byte = data[f"DATA_WIDTH = {b[j]} bytes"]

    w_latencies = {
        1: [],
        2: [],
        4: [],
        8: [],
        16: []
    }

    for active_cores in [1, 2, 4, 8, 16]:
        for depth in [1, 2, 4, 8, 16, 32]:
            print(active_cores, depth)
            latency = 0
            for i in range(4):
                snippet = data_1byte[f"ACTIVE_NODE_COUNT = {active_cores}"][f"REQUEST_DEPTH = {depth}"][f"PASS {i} WRITE"]
                for node in snippet:
                    latency += snippet[node]['W']['bvalid_stall'] / snippet[node]['W']['b_handshake']
            w_latencies[active_cores].append(latency / 4 / active_cores)

    for cores in w_latencies:
        hund_percent = w_latencies[cores][0]

        ax[j][0].plot([1, 2, 4, 8, 16, 32], w_latencies[cores], label=f"{cores} active nodes")

        for i in range(len(w_latencies[cores])):
            w_latencies[cores][i] = w_latencies[cores][i] / hund_percent
        
        ax[j][1].plot([1, 2, 4, 8, 16, 32], w_latencies[cores], label=f"{cores} active nodes")

    ax[j][0].legend()
    ax[j][1].legend()

plt.show()