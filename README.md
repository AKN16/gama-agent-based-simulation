# Agent-Based Simulation using GAMA

An agent-based ecosystem simulation built on the [GAMA Platform](https://gama-platform.org/). Three types of autonomous agents share one environment: prey that wander, flee and reproduce; a **mouse-controlled predator** that grows by eating; and **guardians** that defend the prey. The rules are simple, but their interaction produces game-like dynamics (growth, danger, escape, win/lose conditions).

## Demo

Demo video: [https://youtu.be/-liIjN8j6pQ](https://youtu.be/-liIjN8j6pQ)

The repository also contains `demo.mp4`, a screen recording of a simulation run.

## Agents

| Role | Species in code | Behavior |
|---|---|---|
| Prey | `qiqi` | Wanders randomly and turns back near the edges. Flees (turns orange) when a larger predator is within 30 units, steering mostly toward the nearest guardian. Reproduces with a small probability each cycle. |
| Predator | `hutao` | Follows the mouse cursor. Eats prey small enough to consume and grows; loses size when it tries to eat prey that is too large, hits the boundary, or is hit by a guardian. Dies when its size reaches the minimum. |
| Guardian | `baizhu` | Wanders slowly. When the predator enters its protection radius, chases it, shrinks it on contact, and knocks it back. |

## Rules and mechanics

- **Environment:** 300 × 300 world, starting with 200 prey (adjustable from 50 to 500), 1 predator at the center, and 15 guardians spawned at least 50 units from the center.
- **Eating:** the predator eats a prey agent within its radius only if `prey size × √2 < predator diameter`. A successful meal grows the predator by half the prey's size (capped at a maximum diameter). Attempting to eat prey that is too large costs the predator 1 unit of diameter (at most once per cycle).
- **Fleeing:** prey flee only from predators larger than themselves, with a heading blended 60% toward the nearest guardian and 40% away from the predator.
- **Guardians:** inside a guardian's protection radius (26 units) the predator gets a speed boost, while the guardian chases it. Each contact reduces the predator's diameter by 2 and pushes it back by 5 units.
- **Boundary interaction:** when the predator reaches the edge, it is pushed back toward the center and its diameter is halved. Prey and guardians turn around near the edges.
- **Reproduction:** each prey agent has a per-cycle chance (`qiqi_reproduction_rate`, default `0.002`) to spawn a new prey agent nearby.
- **HP bar:** the predator's size is displayed as a health percentage above it.
- **End conditions:** the simulation pauses when all prey are gone or the predator dies.

## How to run

1. Install the GAMA Platform and import this project (File → Import → existing project).
2. Open `models/test_2.gaml`.
3. Run the experiment **`qiqi_experiment`** (GUI).
4. Move the mouse over the `main_display` to steer the predator.

**Adjustable parameters** (in the experiment panel; labels are in Vietnamese):

| Parameter | Range | Description |
|---|---|---|
| Số lượng qiqi ban đầu | 50 – 500 | Initial number of prey |
| Tỉ lệ sinh sản qiqi | 0.0 – 1.0 | Prey reproduction probability per cycle |

A monitor shows the current number of prey.

## Project structure

```
├── models/
│   └── test_2.gaml    # Model: agents, behaviors, experiment
├── demo.mp4           # Screen recording of a run
└── README.md
```

## Technologies

- GAMA Platform (GAML)
- Agent-based modeling
- Simulation design

## Author

Huỳnh Thị Kim Ngọc ([@AKN16](https://github.com/AKN16))
