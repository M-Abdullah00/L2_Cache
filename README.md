# L2 Cache — Implementation, Verification and Physical Design

A non-blocking, 4-way set-associative L2 cache designed in synthesizable SystemVerilog.

## Architectural Parameters

| Parameter | Value |
|---|---|
| Cache Size | 64 KB |
| Line Size | 128 Bytes |
| Associativity | 4-Way |
| Number of Sets | 128 |
| Replacement Policy | Pseudo-LRU |
| Write Policy | Write-Through |
| MSHR Depth | 4 Entries |
| Write Buffer Depth | 4 Entries |
| Address Width | 32 bits |

## Address Breakdown

```
[31:14] Tag (18 bits)
[13:7]  Index (7 bits → 128 sets)
[6:0]   Offset (7 bits → 128 bytes per line)
```

## Implemented Modules

| Module | Type | Description |
|---|---|---|
| `add_split` | Combinational | Splits 32-bit address into tag, index, and offset |
| `comparator` | Combinational | 4-way parallel tag comparison with hit/miss detection |
| `input_arbiter` | Combinational | Priority mux (MSHR replay > CPU write > CPU read) |
| `tag_ram` | Mixed | Tag/valid storage with pseudo-LRU replacement logic |
| `pipeline_register1` | Sequential | Pipeline register (Stage 0 → Stage 1) |
| `pipeline_register2` | Sequential | Pipeline register (Stage 1 → Stage 2) |

## Pipeline Structure

```
Stage 0 (Combinational)          Stage 1 (Combinational)       Stage 2 (Combinational)
┌──────────┐  ┌───────────┐      ┌────────────┐                ┌──────────────┐
│  Input   │→ │  Address   │  ┌──→│ Comparator │──┐             │   Control    │
│  Arbiter │  │  Splitter  │──┤   └────────────┘  ├── [PR2] ──→│   Block      │
└──────────┘  └───────────┘  │   ┌────────────┐   │             │  (hit/miss)  │
                             └──→│  Tag RAM   │──┘             └──────────────┘
                                 │  (read)    │
                                 └────────────┘
                                       │
                                    [PR1]
```

## Testbenches

Each module has a standalone self-checking testbench:

| Testbench | Tests | Coverage |
|---|---|---|
| `add_split_tb` | 6 | Boundary values, isolated fields, mixed addresses |
| `comparator_tb` | 8 | Hit per way, miss, valid-bit gating, duplicate tags |
| `input_arbiter_tb` | 8 | Priority order, backpressure, full-flag blocking |
| `pipeline_register1_tb` | 5 | Reset, latching, hold behavior, mid-op reset |
| `pipeline_register2_tb` | 5 | Reset, latching, back-to-back, mid-op reset |
| `tag_ram_tb` | 10 | Read/write, cross-set isolation, PLRU correctness |

## Project Status

- **Phase 1** — Literature review, architecture specification, interface definition. *Complete.*
- **Phase 2** — RTL implementation of pipeline modules, module-level verification, bug fixes. *Complete.*
- **Phase 3** — Control block, data RAM, MSHR, write buffer, AXI interface, top-level integration. *Planned.*

## Team

- Aqib Muhammad
- Abdullah Zafar
- Muhammad Abbas
