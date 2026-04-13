# A Circuit-Switched Routing Architecture for Coarse-Grained Reconfigurable Array (CGRA) Cells

## Project Description

This project focuses on the design and evaluation of a circuit-switched interconnect architecture for Coarse-Grained Reconfigurable Arrays (CGRAs). The proposed design replaces highly flexible routing fabrics with a statically configured communication model, reducing hardware complexity while maintaining deterministic data movement between Processing Elements (PEs).
The architecture is implemented in SystemVerilog and evaluated on FPGA using Xilinx Vivado. The analysis includes resource utilization, timing performance, and functional validation through simulation and hardware testing.

The main objective of this project is to analyze the trade-off between routing flexibility and hardware efficiency in FPGA-based CGRA implementations.

## Architecture Description

The proposed CGRA is composed of a grid of Processing Elements (PEs), each connected to a local crossbar-based switch. Main elements can be found below: 

- **PEs**  
  Perform computation or operate in bypass mode.

- **Crossbar Switches**  
  Provide flexible routing between neighboring nodes.

- **Routing Configuration Logic**  
  Routing paths are configured statically before execution using selection signals.
  
All interconnections are illustrated in Figure 1:


<p align="center">
  <img width="300" height="400" alt="Captura de pantalla 2026-04-04 201707" src="https://github.com/user-attachments/assets/79d4bf7e-5a48-48e6-b0fa-8a6f5e803657" />
</p>
<p align="center">
  Figure 1. Proposed solution for the CGRA interconnection.
</p>




### Routing Model

The interconnect follows a **Manhattan routing scheme**, where data propagates across the grid using orthogonal directions (North, South, East, and West). This behavior is illustrated in Figure 2:

<p align="center">
  <img width="300" height="200" alt="Manhattan" src="https://github.com/user-attachments/assets/b47cab74-f543-416a-bf63-31df54324669" />
</p>
<p align="center">
  Figure 2. Crossbar flow based on Manhattan routing scheme.
</p>





- Routing paths are configured before execution  
- No runtime arbitration is required  
- Data moves deterministically across the network  

Only the PEs involved in the routing path actively participate in data transfer, while the remaining nodes operate in **bypass mode**.

</h4> <hr style="border: 1px solid #000;"/>

## Files tree

```
├── README.md
├── src
│   ├── cgra_config_pkg.sv
│   ├── cgra_tbs
│   │   ├── tb_cgra_2x2.sv
│   │   ├── tb_cgra_4x4_horizontal_not.sv
│   │   ├── tb_cgra_4x4_manual_routing.sv
│   │   ├── tb_cgra_mesh.sv
│   │   └── tb_includes
│   │       ├── tb_tasks_clear.svh
│   │       ├── tb_tasks_debug.svh
│   │       ├── tb_tasks_pipeline.svh
│   │       ├── tb_tasks_routing.svh
│   │       ├── tb_tasks_setups.svh
│   │       └── tb_tasks_waits.svh
│   ├── crossbar
│   │   ├── crossbar.sv
│   │   └── crossbar_tb.sv
│   ├── mesh_top.sv
│   ├── ni
│   │   ├── ni_rx_path
│   │   │   ├── ni_rx_path.sv
│   │   │   └── ni_rx_path_tb.sv
│   │   └── ni_tx_path
│   │       ├── ni_tx_path.sv
│   │       ├── ni_tx_path_tb.sv
│   │       ├── packetizer.sv
│   │       └── packetizer_tb.sv
│   ├── pe
│   │   ├── pe.sv
│   │   └── pe_tb.sv
│   └── tile.sv
│
└── kria_val
    ├── prog_test_kria.sh
    ├── send_bitstream.sh
    ├── send_test.sh
    ├── mesh_wrapper.v
    ├── mesh_bridge.sv
    ├── test_C
    │   ├── cgra_2x2_test.c
    │   ├── cgra_3x3_test.c
    │   └── cgra_4x4_test.c
    └── vivado_bd
        ├── cgra_2x2_circuit_switch.pdf
        ├── cgra_3x3_circuit_switch.pdf
        └── cgra_4x4_circuit_switch.pdf
```


The ```src``` directory contains the hardware modules that implement the proposed CGRA architecture. The structure of the design can be understood by analyzing the modules from bottom to top.

- **cgra_config_pkg.sv**: In this file, all parameters are initialized, including the assigned value for each port (North, South, East, West, Local), the size of the data to be managed and the size of the mesh (row and column scheme).
- pe.sv: This file implements the Processing Element. In this case, it is a sequential module that operates in two different modes: passthrough and NOT operation.
- **crossbar.sv**: This module is combinational, and it is the component that connects the mesh to the Processing Element. It determines whether the received data is simply passing through or needs to be transmitted to the Processing Element.
- **tile.sv**: This file represents the first connection between modules. Here, each crossbar is connected to its Processing Element, including the signal wiring required to enable communication with the neighborhood through the North, South, East, West, and Local ports, as well as with the PE.
- **mesh_top.sv**: Depending on the required size of the mesh as defined on **cgra_config_pkg.sv**, this module generates all the required tiles and connects them to each other, while taking the mesh boundaries into account to avoid misconnections.


Then, the testbench file instanciates the mesh module in order to inject the required data, establish and/or clear routes, and perform other operations needed to fully test the implemented design. 

A quick review on the related testbench files is presented as follows:
- **tb_cgra_mesh.sv**: This file instantiates the mesh to be tested and, through the coordinated use of the other testbench files, generates the required tests to verify the behavior of the modules working together. It creates test cases such as single, pipeline, and broadcast communication, while also clearing routes, creating new routes, and waiting for responses.
- **tb_tasks_clear.svh**: This file clears routes and stimulus required for testing the UUT. Its purpose is to clean up the mesh so that there is independence between test cases within the same main testbench.
- **tb_tasks_debug.svh**: This file periodically checks the mesh, and once a change in the data flowing through the mesh is detected, a set of print statements is enabled so the data can be easily observed from the main testbench file.
- **tb_tasks_routing.svh**: This file implements the mechanisms required to create routes between different nodes through the Manhattan method, including one-to-one, one-to-all, and one-to-middle-destination routes.
- **tb_tasks_pipeline.svh**: This file allows multiple data packets to be sent at once, enabling the implementation of specific test cases.
- **tb_tasks_setups.svh**: This file implements wrappers to set up routes for use as part of the testbench.
- **tb_tasks_waits.svh**: This file includes the mechanisms that allow the testbench to wait for the expected value while verifying the results of a test case.

### Hardware validation on Kria KV260.

The ```kria_val``` directory contains the scripts and software used to validate the CGRA architecture on the Kria KV260 platform. These files allow the FPGA bitstream to be deployed to the board, test programs to be transferred and executed, and the results of the hardware implementation to be verified.

A brief description of the files contained in this directory is presented below:

- **prog_test_kria.sh**: This script programs the FPGA on the Kria platform with the generated bitstream and executes the selected test application.
- **send_bitstream.sh**: This script transfers the compiled bitstream to the Kria board, allowing the programmable logic to be configured with the CGRA design.
- **send_test.sh**: This script sends the compiled test program to the Kria platform and prepares it for execution.
- **mesh_wrapper.v**: This module provides the top-level interface used to integrate the CGRA architecture with the Kria KV260 platform. It exposes the CGRA configuration and data signals through AXI GPIO interfaces, enabling memory-mapped communication between the processing system and the programmable logic.
- **mesh_bridge.sv**: This module translates the flat GPIO-based interface into the internal multi-dimensional configuration signals used by the CGRA mesh. It distributes routing selections, injection controls, and data signals across the mesh structure.

```test_C/```: This directory contains C-based test applications used to validate the CGRA behavior directly on the hardware platform to validate routing behavior and data propagation across the CGRA for 2×2, 3×3, and 4×4 configurations.
- **cgra_2x2_test.c**
- **cgra_3x3_test.c**
- **cgra_4x4_test.c**

```vivado_bd/```: This directory contains exported block design diagrams generated in Vivado that illustrate the hardware integration of the circuit-switched CGRA architecture on the Kria platform for different mesh configurations (2×2, 3×3, and 4×4).
- **cgra_2x2_circuit_switch.pdf**
- **cgra_3x3_circuit_switch.pdf**
- **cgra_4x4_circuit_switch.pdf**

The Figure 3 shows the block design used to integrate the proposed CGRA architecture with the Kria KV260 platform.

<p align="center">
<img width="400" height="300" alt="cgra_3x3_circuit_switch" src="https://github.com/user-attachments/assets/7f5ed877-9782-4c21-becd-2171d26921e1" />
</p>
<p align="center">
  Figure 3. Block design of the 3×3 circuit-switched CGRA implementation used for hardware validation on the Kria platform.
</p>



</h4> <hr style="border: 1px solid #000;"/>


## RESULTS AND ANALYSIS  

The proposed CGRA interconnect architecture was synthesized and implemented in a Kria KV260 Vision AI Starter Kit FPGA using Xilinx Vivado. The critical path delay was estimated using the relationship between clock period and worst negative slack, as defined in (1):

<p align="center">
  T<sub>critical</sub> = T<sub>clock</sub> - WNS      (1)
</p>


Where WNS is Worst Negative Slack and The maximum operating frequency can then be estimated from the critical path delay as defined in (2):

<p align="center">
  F<sub>max</sub> = 1 / T<sub>critical</sub>        (2)
</p>

To determine the operating frequency of the design, multiple clock constraints were evaluated. This analysis was performed using the 3×3 CGRA configuration, which represents the more demanding case in terms of interconnect complexity. An initial test at 300 MHz resulted in a large negative slack (-9.682 ns), indicating that the design exceeds its timing capabilities.


At 50 MHz, the design meets timing with a large margin, while at 80 MHz, it still meets timing but operates very close to the limit (0.311 ns slack). At 75 MHz, a better balance between performance and timing margin is achieved (WNS = 1.182 ns), making it a more robust operating point.


Based on the critical path delay, the estimated maximum operating frequency is approximately 82 MHz for the 3×3 configuration. Therefore, a practical operating range of 70–75 MHz is recommended to ensure reliable operation. This operating range is expected to be valid for smaller configurations, such as the 2×2 mesh, which exhibit lower routing complexity. Timing results for different target frequencies are presented in Table I.


### Table I. Timing Analysis

| Frequency (MHz) | Period (ns) | WNS (ns) | Critical Path (ns) | Timing Condition |
|----------------|------------|----------|--------------------|------------------|
| 50  | 20.00 | 6.700  | 13.30 | Met     |
| 75  | 13.33 | 1.182  | 12.15 | Met     |
| 80  | 12.50 | 0.311  | 12.19 | Met     |
| 300 | 3.33  | -9.682 | 13.01 | Not met |

The design evaluation was performed on 2×2, 3×3, and 4×4 CGRA meshes, analyzing the resource utilization results in Table II to assess the scalability of the interconnect. While the maximum operating frequency was derived from the 3×3 configuration as a representative case, Table II provides an overview of the achievable maximum frequencies across different mesh sizes.

### Table II. Interconnect Resource utilization for different CGRA sizes 

| CGRA Size | LUTs  | FFs  | F7 Muxes | Global Clk Buffers | Fmax Op. (MHz) |
|-----------|-------|------|----------|---------------------|----------------|
| 2×2       | 3988  | 4882 | 4        | 1                   | 300            |
| 3×3       | 7040  | 7436 | 68       | 2                   | 75             |
| 4×4       | 11304 | 9773 | 36       | 2                   | 40             |

LUT and FF counts grow significantly as the CGRA size increases, due to the higher number of processing elements and, more importantly, the expanded interconnect required between them.
A particularly notable increase is observed in the number of F7 multiplexers. This growth is primarily driven by the expansion of the crossbar-based switching fabric, where each additional node introduces new routing options and connectivity requirements, resulting in a larger number of multiplexing structures.
In terms of performance, the maximum operating frequency decreases as the mesh size increases. This behavior indicates that the critical path becomes dominated by the interconnect, as data must traverse a greater number of switches and longer combinational paths.

Functional validation of the interconnect was performed using a custom testbench covering representative communication patterns across the CGRA grid.

One-to-one communication scenarios were evaluated to validate correct data propagation across multi-hop paths. These tests confirm that data traverses the grid following the statically configured Manhattan routes, reaching the destination node without loss or corruption. Figure 2 illustrates this routing behavior.

Scenarios involving intermediate PEs were also evaluated, where selected nodes perform computations on in-flight data. The results confirm that PEs can operate transparently within the routing path, correctly consuming input data and reinjecting results into the interconnect. As can be illustrated in Figure 4: 

<p align="center">
  <img width="350" height="250" alt="fig3" src="https://github.com/user-attachments/assets/34bd9d87-23f8-4260-adec-fb085f950839" />
</p>
<p align="center">
  Figure 4. Crossbar flow based on a one-to-one route with middle observation.
</p>

One-to-many communication patterns were validated through broadcast scenarios, demonstrating that a single source node can distribute data to multiple destinations simultaneously. These tests confirm the ability of the crossbar-based switches to support concurrent routing paths without conflicts.
Figure 5 illustrates this routing behavior.
<p align="center">
   <img width="350" height="250" alt="fig4" src="https://github.com/user-attachments/assets/171e2f75-0f90-4971-94ac-ea156a8e2de8" />
</p>
<p align="center">
  Figure 5. Crossbar flow-based full broadcast route.

</p>


Additionally, concurrent multi-route behavior was validated by configuring multiple independent communication paths across the CGRA grid. In these tests, several horizontal routes were activated simultaneously, each injecting distinct data streams from different source nodes.
Two scenarios were evaluated: routing with intermediate processing, where selected PEs apply a NOT operation to in-flight data, and manual routing, where data is forwarded without modification. The results confirm that the interconnect supports concurrent data transfers across multiple paths without interference, while enabling selective computation within the routing fabric. This behavior can be illustrated by Figure 6. 
<p align="center">
  <img width="350" height="250" alt="fig5" src="https://github.com/user-attachments/assets/baa28435-0cac-4c79-b112-6d2c27d13e2e" />

</p>
<p align="center">
   Figure 6. Crossbar flow-based parallel routes.

</p>




 ## FUTURE WORK  

While the proposed architecture demonstrates the feasibility and effectiveness of the current design choices, several opportunities remain for further improvement and exploration. Future work will focus on enhancing performance, scalability, and flexibility by revisiting key architectural decisions and investigating alternative design approaches.

In this initial implementation, combinational switches were adopted to simplify the communication mechanism, as they require fewer control signals and reduce design complexity. However, synchronous switch-based designs present several advantages that merit further exploration. In particular, synchronous switches can achieve improved timing closure at higher clock frequencies by introducing pipeline registers that break long combinational paths. This also enhances scalability and robustness, especially in larger network topologies.

These benefits come at the cost of increased latency, typically adding one or more clock cycles per stage. Therefore, future work will involve evaluating the trade-offs between combinational and synchronous switching approaches across different system configurations. While combinational switches may remain suitable for smaller systems operating at lower frequencies, synchronous designs are expected to be more appropriate for larger-scale architectures targeting higher performance.

Another promising direction for future work is the exploration of data packetization within the proposed architecture. Although the current design employs a circuit-switching approach for data routing, this does not preclude the possibility of transmitting data sequentially to effectively reuse the existing link bandwidth. By introducing packetization, larger data transfers could be supported over fixed-width links without increasing physical interconnect complexity. This approach would preserve the simplicity of routing and flow control inherent to circuit switching, while enabling more efficient hardware utilization and improved flexibility in handling varying data sizes.




## CONCLUSIONS  

A circuit-switched interconnect architecture for A circuit-switched interconnect architecture for CGRAs was proposed, reducing routing complexity through static configuration. The elimination of dynamic arbitration and buffering simplifies the interconnect microarchitecture while preserving deterministic communication.

FPGA results show stable timing behavior, achieving up to 80 MHz for the 3×3 mesh configuration, which was used as a representative case for timing characterization. A practical operating range of 70–75 MHz is identified to ensure reliable operation for this configuration and smaller CGRA sizes.

Evaluation across multiple mesh sizes shows that hardware cost increases with the CGRA dimensions, primarily due to the expansion of the interconnect and crossbar-based switching fabric, which introduces additional routing resources and multiplexing structures. At the same time, the maximum operating frequency decreases as the mesh size increases, indicating that the interconnect becomes the dominant factor in the critical path.

Functional validation confirms reliable operation across multiple communication patterns, including one-to-one, one-to-many, and concurrent multi-route scenarios, without interference between data paths. The architecture also supports in-path computation, allowing intermediate PEs to process data while preserving end-to-end communication.

Additionally, the proposed routing model enables predictable data movement through statically defined Manhattan paths and supports parallel data flows under a structured configuration scheme. These results demonstrate that reduced routing flexibility can still sustain representative CGRA communication patterns while simplifying the overall interconnect design.

## USE OF AI-ASSISTED TOOLS

In this project, AI tools, including ChatGPT, Copilot, and Grok, were used solely as supportive resources to assist with concept exploration, clarification of ideas, and improvement of the manuscript’s wording. All technical decisions, interpretations, and final content were determined by the authors.


## Repository

https://github.com/acordobav/cgra-circuit-switch

[Video link](https://drive.google.com/file/d/1KqbiSDTqXnG51SubBWGj0tolq49THO3I/view?usp=sharing)

## General Information

Advanced FPGA Design Course

Master’s Program in Electronics Eng.

Tecnológico de Costa Rica

Professor: Luis León Vega (l.leon@itcr.ac.cr)

### Students

- Arturo Córdoba (arturocv16@estudiantec.cr)
- Jill Carranza (gcarranza@estudiantec.cr)
- Juan Pablo Ureña (juurena@estudiantec.cr)
- Víctor Sánchez (vicsma2409@estudiantec.cr)


