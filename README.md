# Sample Implementations for Agent Specifications

This repository contains sample implementations for agent specifications in rules, specifically [Notation3 syntax](https://www.w3.org/TeamSubmission/n3/) with [ASM4LD semantics](https://ceur-ws.org/Vol-2073/article-05.pdf). Those implementations can be run using the [Linked Data-Fu](https://linked-data-fu.github.io/) engine.

The agent specifications require the [BOLD server](https://github.com/bold-benchmark/bold-server) to be initialised with the data from Building 3.

A self-contained simple example can be found in [ts0_demo-coffeedesk-on.n3](ts0_demo-coffeedesk-on.n3), which turns on the lights at the Coffee Desk.

The other implementations in the folders are of the following behaviour (here we split the rules into multiple files to allow for scalability experiments). Next to the behaviour, we describe what behaviour we would consider as faulty.

Two shell scripts ([run-agent.sh](run-agent.sh) and [benchmarking.sh](benchmarking.sh)) can serve as examples for how to run those agents, and for how to run all agents for benchmarking, respectively.

## Running instructions for the self-contained simple example
* Get the [BOLD server](https://github.com/bold-benchmark/bold-server)
* Get [Linked Data-Fu](https://linked-data-fu.github.io/)
* Unpack Linked Data-Fu
* Create `ldfu.sh` in the root of the bold-agents folder (probably the same as this readme) based on `ldfu.sh.template`
* Start the BOLD server on `127.0.1.1:8080` (i.e. the default) with task name `ts1`
* Inspect `http://127.0.1.1:8080/gsp/Room_CoffeeDesk`, e.g. preferably using CURL, RAPPER or Firefox with the RDF browser extension installed.
  * Find that the coffee desk is fed by a lighting system `http://127.0.1.1:8080/gsp/Lighting_System_42GFLCoffeeDock`
  * Follow the link to this lighting system by now dereferencing its URI and inspect the representation
  * where you find a SSN property resource `http://127.0.1.1:8080/gsp/property-Lighting_System_42GFLCoffeeDock#it`
  * that has the value `"off"`
* Inspect `ts0_demo-coffeedesk-on.n3` and think about what it may do.
* Run the ts0 agent `./ldfu.sh -p brick*n3 -p ts0_demo-coffeedesk-on.n3`
  * that with the first set of rules considers the Brick ontology, e.g. that "feeds" is the inverse of "isFedby"
  * that with `ts0_demo-coffeedesk-on.n3` retrieves the data and turns on the light
* Dereference the property resource again and see that the value is `"on"` 💡

Congratulations, you just ran a simple rule-based agent that performed dereferencing, reasoning, link following, and interaction, which turned on the lights at the Coffee Desk. 🥳

You now deserve a coffee. ☕ 

## Single-Loop: Simple control of lights
We implement the behaviour that a janitor would trigger when the whole building closes (TS1) or when they test functionalities of the system (TS2 and TS3).

### TS1: All Lights Off
A light that is on is considered a fault. This task does not require any data
point to be read, the agent must merely find all lights and turn them off.

### TS2: Toggle All Lights
In this task, a light that has not been toggled since the beginning of the
run is considered a fault. In contrast to TS1, this task involves perception.
The agent must first read the state of a luminance command and then toggle.

### TS3: All Lights Off (with reasoning)
Similar to TS1, but only a subset of the lights has to be switched off, namely
those in rooms dedicated to ‘personal hygiene’ (toilet and shower). Agents
must properly classify rooms, which requires that they first read sub-class
axioms defined in the environment in a custom RDF vocabulary. These
axioms specify, e.g. that ‘disabled toilets’ are a kind of ‘toilets’, themselves
a kind of ‘personal hygiene’ rooms. As in TS1, a light in a toilet or shower
that is on is considered a fault. To ensure agents correctly classify rooms,
any light that has been toggled in other rooms is also considered a fault.

## Continuous-Loop: Control of lights based on the environment

We implement continous-loop control to consider the following:
In single-loop tasks, changes in the environment have no effect on success. This
is not true of continuous-loop tasks. In continuous-loop tasks, changes in the
environment may cause faults to appear, agents must thus continuously monitor
the environment. The initial value of all lights is randomized so that fault rate
always equals 0 in the absence of agent operation, regardless of the task.
Continuous tasks TC1 and TC2 involve time only. TC3 and TC4 involve
illuminance sensors. TC5-TC7 introduce occupancy sensors.

### TC1: Weather report
In this scenario, a weather report provides sunrise and sunset times. A light
that is off during the day is considered a fault, under the assumption that the
building is likely to be occupied. Conversely, lights should be off during the
night as no one is expected to be in the building. An agent needs to retrieve
sunrise and sunset timestamps, and turn lights on or off accordingly.
### TC2: Working hours
In this scenario, in addition to sunrise and sunset times, parts of the
building (floors) expose different opening and closing times beyond which no
light should be on. The ground floor is assumed to close later (11pm) than
other floors (7pm). All floors open at 8am. When a floor is open, any light on
the floor that is off is considered a fault. In this task, the agent must perform
automated reasoning to infer what room belongs to each floor in order to
decide whether lights in the room should be on or off at a given point in time.
### TC3: Global light sensor
In task TC3, a light that is off is a fault if outside illuminance is below a
certain threshold (10,000 lux). In this scenario, we assume the building is
equipped with a weather station mounted on its rooftop that includes a light
sensor. By applying a threshold, we want to determine whether the lights
in the entire building should be on or off. In contrast to TC1 and TC2, the
times at which light should be on or off is randomly generated to simulate
cloud coverage. Yet, agents could anticipate when to perform an action, as
illuminance on the surface of the building varies from sunrise until sunset.
### TC4: Per-room light sensor
In task TC4, a fault is defined as in TC3 but at the level of a single room.
We only consider the rooms in the building that are equipped with luminance
sensors so as to decide for each room whether lights should be on or off by
applying a global threshold (500 lux).
### TC5: Per-room occupancy sensor
In TC5, a fault is any light that is off while an occupant is detected in
the room. In this scenario, we assume that the rooms in the building are
equipped with occupancy sensors. Using those sensors only, we want to
determine whether the lights should be on or off. The challenge for agents
in this task is to continuously monitor occupants coming in and leaving the
building in a non-deterministic fashion. Although the simulated environment
displays a clear occupancy pattern throughout the day, an agent cannot know
it upfront, and can only build a model of occupancy by repeated observation.
### TC6: Per-room occupancy and light sensor
This task combines TC5 with the constraints of TC4: a fault is any light
that is off while an occupant is detected in the room and illuminance is below
500 lux. In this scenario, we want to raise energy efficiency and only turn
on light in rooms with occupants and low illuminance. An agent faces less
potential faults but overcoming them requires a more advanced model of the
environment (or faster perception-action loops).
### TC7: Per-room occupancy and custom light sensor
TC7, the most challenging task of the benchmark adds one more constraint
to TC6: instead of a global illuminance threshold, agents have to make decision
based on the preferences of occupants, which they can update at any time

