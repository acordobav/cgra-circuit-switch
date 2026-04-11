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
├── src/
│ ├── mesh_top.sv
│ ├── tile.sv
│ ├── crossbar.sv
│ ├── pe.sv
│ └── cgra_config_pkg.sv
│
├── tb/
│ ├── tb_cgra_mesh.sv
│ └── tb_includes/
│ │ ├── tb_tasks_clear.svh
│ │ ├── tb_tasks_debug.svh
│ │ ├── tb_tasks_routing.svh
│ │ ├── tb_tasks_pipeline.svh
│ │ ├── tb_tasks_setups.svh
│ │ └── tb_tasks_waits.svh
│
└── README.md
```

Analyzing the implemented architecture from bottom to top:

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

</h4> <hr style="border: 1px solid #000;"/>


## RESULTS AND ANALYSIS  

The proposed CGRA interconnect architecture was synthesized using Xilinx Vivado targeting an FPGA device in order to evaluate hardware resource utilization. The analysis focuses on understanding the cost of the interconnect structure and its main components within a circuit-switched communication model, table I summarizes the resource utilization results for the synthesized design.

## Table I. Interconnect Resource utilization for different CGRA sizes

| CGRA Size | LUTs | FFs | DSP | BRAM | WNS (ns) | Fmax (MHz) |
|----------|------|-----|-----|------|----------|------------|
| 2×2      |      |     |     |      |          |            |
| 3×3      |      |     |     |      |          |            |
| 4×4      |      |     |     |      |          |            |

Functional validation of the interconnect was performed using a custom testbench covering representative communication patterns across the CGRA grid.

One-to-one communication scenarios were evaluated to validate correct data propagation across multi-hop paths. These tests confirm that data traverses the grid following the statically configured Manhattan routes, reaching the destination node without loss or corruption.

// RESULTS... 



Scenarios involving intermediate PEs were also evaluated, where selected nodes perform computations on in-flight data. The results confirm that PEs can operate transparently within the routing path, correctly consuming input data and reinjecting results into the interconnect.

// RESULTS... 



One-to-many communication patterns were validated through broadcast scenarios, demonstrating that a single source node can distribute data to multiple destinations simultaneously. These tests confirm the ability of the crossbar-based switches to support concurrent routing paths without conflicts.

// RESULTS... 


Additionally, pipeline behavior was validated by injecting consecutive data packets, demonstrating continuous data flow across the interconnect and confirming its capability to support streaming applications.

// RESULTS... 




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

## Repository

https://github.com/acordobav/cgra-circuit-switch

[Video link](https://drive.google.com/file/d/1KqbiSDTqXnG51SubBWGj0tolq49THO3I/view?usp=sharing)
