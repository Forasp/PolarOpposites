# Giskard High-Level Design Specification

## Status

This document captures the current intended high-level design for the Giskard project based on:

- the existing repository structure and code
- the current editor implementation
- the product direction provided by the project owner

It is intentionally high level. It defines package responsibilities, primary runtime boundaries, and the expected feature surface without locking down low-level implementation details yet.

## 1. Product Overview

Giskard is intended to be a native Apple-platform game development toolchain written primarily in Swift, with Metal used where graphics or compute performance is required.

The initial product family consists of:

- `Giskard Editor`: the desktop editor application for project, scene, entity, and asset authoring
- `Giskard Engine`: the shared runtime core and primary integration layer for simulation systems
- `Giskard Vision`: the rendering package
- `Giskard Hearing`: the audio package
- `Giskard Brain`: the AI package
- `Giskard Touch`: the input package

Primary target platform:

- macOS

Secondary compatibility target:

- iOS-compatible code and architecture where practical, even when a package is not initially shipped as a user-facing iOS product

## 2. Design Goals

The project should prioritize:

- native macOS implementation using Swift
- modular package boundaries with clear ownership
- minimal coupling between subsystems
- editor functionality comparable in broad category to Unity, Godot, and Unreal Editor
- public APIs that are simple and stable, with implementation complexity kept internal
- cross-package interoperability through engine-owned coordination patterns rather than direct subsystem entanglement

## 3. Current Repository Baseline

The current repository already establishes the early form of this architecture.

### 3.1 Existing packages and targets

- `Giskard` app target: macOS SwiftUI editor shell
- `GiskardEngine` Swift package: shared scene/entity/capability/runtime logic
- `GiskardVision` Swift package: Metal-backed renderer package exported as `Renderer`

### 3.2 Existing editor functionality

The current editor already includes:

- project creation and opening
- recent project tracking
- file and folder browsing
- file-backed `.scene` and `.entity` asset authoring
- scene hierarchy browsing
- entity inspection and editing
- image inspection
- an embedded scene preview surface backed by `GiskardVision`

### 3.3 Existing engine and renderer patterns

The current codebase already shows these architectural directions:

- entities represented as serializable runtime/editor data
- capabilities attached to entities by type name
- scene files represented as serializable scene graphs
- renderer interaction through handles and command submission rather than exposing Metal internals to the editor

These existing patterns should be preserved and refined rather than replaced arbitrarily.

## 4. System Architecture

At a high level, Giskard should be organized as follows:

### 4.1 Editor

`Giskard Editor` is an authoring tool, not the owner of runtime systems.

Its responsibilities are:

- project lifecycle management
- scene creation and modification
- entity creation and modification
- asset and folder exploration inside a project
- inspector panels and editing workflows
- scene preview and runtime debugging views
- editor-only tooling, authoring metadata, and workflow UX

The editor should delegate non-editor-specific behavior to the appropriate package instead of embedding its own runtime implementations.

### 4.2 Engine

`Giskard Engine` is the core package and the integration hub for the rest of the stack.

Its responsibilities are:

- core entity and scene abstractions
- simulation update coordination
- physics, motion, and collision ownership
- event system and message passing infrastructure
- subsystem orchestration across rendering, audio, input, and AI
- runtime-facing asset references and scene state

The engine should be the primary dependency for gameplay/runtime code and the primary coordination layer between other packages.

### 4.3 Vision

`Giskard Vision` is the rendering subsystem.

Its responsibilities are:

- 2D rendering
- 3D rendering
- GPU resource management
- scene submission and draw execution
- visibility, culling, and render-pipeline internals
- Metal-specific implementation details

Its public API should remain narrow. Callers should express intent such as:

- upload or resolve a mesh
- upload or resolve a texture or material
- provide camera state
- provide renderable instances or render commands

Callers should not be responsible for internal renderer policy such as:

- asset loading internals
- GPU residency details
- occlusion logic
- frustum culling
- render pass scheduling

### 4.4 Hearing

`Giskard Hearing` is the audio output and audio-processing subsystem.

Its responsibilities are:

- sound playback
- music playback
- mixing
- volume management
- distance-based attenuation
- 3D audio processing
- runtime audio resource coordination

This package is output-focused. It does not need to own voice input or speech recognition unless that becomes a later explicit requirement.

### 4.5 Brain

`Giskard Brain` is the AI subsystem.

Its responsibilities are:

- decision trees or behavior logic systems
- pathfinding
- utility or state-based AI orchestration
- future AI-related simulation support

If compute acceleration becomes necessary, Metal compute may be used internally, but the package should remain usable without exposing GPU complexity in its public surface.

### 4.6 Touch

`Giskard Touch` is the input subsystem.

Its responsibilities are:

- mouse input
- keyboard input
- touch input
- gamepad input
- action/state translation from platform events into engine-readable input data

The input package should normalize platform-specific details into engine-facing abstractions.

## 5. Dependency Direction

The intended dependency direction is:

- `Giskard Editor` depends on `Giskard Engine` and may depend directly on other packages only for editor-specific integration surfaces
- `Giskard Engine` coordinates with `Giskard Vision`, `Giskard Hearing`, `Giskard Brain`, and `Giskard Touch`
- feature packages should avoid depending on the editor

Preferred rule:

- editor-only concerns stay in the editor
- shared runtime concerns stay in engine or a feature package
- cross-subsystem coordination flows through engine-owned abstractions

## 6. Communication Model

`Giskard Engine` must provide one unified event system that also serves as the engine's message-passing interface. These are not separate subsystems.

This system is intended to reduce direct class-to-class dependencies and support subsystem decoupling.

### 6.1 Core Requirements

- messages may be submitted from any thread
- the event system owns a dedicated thread for receiving and routing messages
- publishers should not need hard references to consumers
- the system should be usable by engine systems, gameplay logic, and package integrations
- editor-observable workflows may listen to engine activity through this same event model

### 6.2 Subscription Model

Normal event consumption should happen through an `EventListener` member owned by the subscribing class or object.

Expected behavior:

- objects subscribe to one or more message types
- each `EventListener` has an integer priority value used by the event system for delivery order
- the event system routes matching messages to each subscriber's `EventListener`
- the listener queues accepted messages for later handling by its owner
- the owning object decides when to consume queued events

Subscribers should not normally reach into the event system directly during regular runtime handling. The `EventListener` is the intended boundary.

Priority rules:

- listener priority collisions are invalid
- if two matching listeners have the same priority for a given delivery set, the engine should assert and terminate with an error rather than applying an implicit tie-breaker
- beyond this validation rule, tie-breaking behavior is intentionally undefined because equal-priority delivery is not allowed

### 6.3 Callback Registration

The system may also support direct callback registration, but this is an escape hatch rather than the preferred model.

Requirements:

- callback-based subscriptions must be documented as thread unsafe
- callback-based subscriptions should be discouraged for normal gameplay/runtime logic
- the `EventListener` subscription pattern is the default and recommended approach

### 6.4 Threading and Delivery Model

The intended flow is:

- a sender creates a message and submits it from any thread
- the event system buffers inbound messages
- on its own event-thread tick, the event system transfers buffered messages into the main event queue
- the event system iterates through queued messages and routes each message to matching subscribers in priority order
- each subscriber's `EventListener` decides whether to accept and queue the message locally
- a subscriber may report that it consumes the message
- once a message is consumed, it is removed from further delivery and later subscribers do not receive it
- if a message is not consumed during that tick, it is deleted at the end of the tick
- after event-thread routing is complete, engine-owned scene/object update logic proceeds
- scene objects then process their listener-queued events on the main thread at their own discretion

This design keeps message routing off the main simulation thread while preserving main-thread object handling for ordinary runtime behavior.

Thread-safety requirements:

- subscription changes may happen at any time
- listener destruction may happen at any time
- queue reads and queue writes must be safe by design
- listener internals should use mutexes and a swappable buffer strategy so the actively read buffer is not written to while it is being processed
- reading queued events should not block event-thread writes to the listener's pending buffer
- when a listener is destroyed, any queued messages owned by that listener are discarded

### 6.5 Consumption Semantics

The event system should support both:

- non-consuming delivery, where multiple subscribers may observe and queue the same message
- consuming delivery, where a subscriber can stop further propagation

Further rules:

- a message may be consumed at most once
- once consumed, delivery stops immediately
- unconsumed messages do not persist across ticks
- a message with no matching subscribers simply expires at the end of that tick

This allows the engine to support both broadcast-style notifications and ownership-style handling while keeping event lifetime simple and bounded.

### 6.6 Listener Queue Rules

Each `EventListener` should own a fixed-size queue.

Initial requirements:

- default listener queue capacity is `128` events
- if a listener queue exceeds capacity, the engine should assert in debug/development builds so the overload is visible immediately
- in release builds, queue overflow should behave as a circular buffer and overwrite from the beginning
- queue overflow handling may be made more sophisticated later, but the initial design should fail loudly in development and remain bounded in release

### 6.7 Event Payload Representation

The payload model should preserve flexibility without relying on unmanaged raw-pointer lifetime rules as if this were C++.

Recommended direction for Swift:

- each event contains a type, subtype, and opaque payload bytes
- payload bytes should be represented using `Data` or an equivalent owned byte buffer
- the event system owns the payload storage for the event instance while it is in the system
- when an `EventListener` accepts an event, it should copy the payload bytes into its own queue entry
- listener owners may then decode those bytes into the concrete payload type they expect when processing on the main thread

This is the Swift-safe equivalent of an untyped payload block. It preserves:

- ambiguous payload support
- copy-based ownership boundaries
- explicit lifetime control
- thread-safe transfer between the event thread and main-thread consumers

Raw pointer payloads are technically possible in Swift through unsafe pointer types, but they are a poor default for this system because ownership, copying, deallocation, and thread-safety become much easier to get wrong.

Payload interpretation rules:

- payloads are raw binary bytes
- the engine does not impose a schema on payload contents
- endpoints interpret payload bytes at their own discretion
- a payload may represent a primitive value, a string encoding, or a caller-defined struct layout
- event matching is based on event type only; subtype exists for listener-local interpretation and filtering rather than event-system-level routing
- events do not carry extra standard metadata such as timestamps, sender IDs, target IDs, or frame numbers unless a future design revision adds them explicitly
- raw payload layouts are internal and free to change across engine versions

### 6.8 Example Flow

One intended example is input handling:

- the input system receives a key-down platform event
- it creates an event with type `Input`, subtype `keyboard`, and a payload containing key name, press type, and related input data
- it submits that event to the unified event system
- on the event system's next tick, that message is moved from the inbound buffer into the main event queue
- the event system begins routing the message to matching subscribers
- the first few subscribers accept the event into their `EventListener` queues and report that they do not consume it
- another subscriber may reject the event because the subtype or payload is not relevant and therefore does not queue it
- a later subscriber may accept the event and report that it does consume it
- once consumed, remaining subscribers do not receive that event
- later, when `Giskard Engine` updates scene objects on the main thread, the relevant entities process the queued input events from their `EventListener`s

Examples of intended use beyond input:

- collision and trigger events
- audio playback requests triggered by gameplay or editor preview
- renderer synchronization requests emitted from scene/runtime state
- editor tools observing scene changes without tightly coupling to simulation classes

## 7. Data Model Direction

The current repository uses filesystem-backed JSON-like assets for projects, scenes, and entities. That direction is acceptable for the initial phase.

High-level asset/data expectations:

- projects define global settings and entry points
- scenes define scene graphs and scene-level metadata
- entities define reusable object data and capability composition
- asset references should be stable and portable within a project

The current split between `.scene` and `.entity` files should be treated as the initial authoring format unless future requirements justify a different asset pipeline.

Scene composition direction:

- scenes may contain inline entity data
- scenes may also reference reusable standalone `.entity` assets
- the asset model should support both approaches from the start
- referenced `.entity` instances should store both source path and source UUID
- referenced `.entity` instances should store scene-local divergences from the source asset
- scene instances may override any field from the referenced `.entity` asset

## 8. Editor Feature Scope

The target editor should provide the majority of the broad authoring workflows expected from modern game editors, including:

- scene creation
- scene modification
- entity creation
- entity modification
- scene preview
- project folder and file exploration

Comparable category coverage to Unity, Godot, and Unreal Editor means broad workflow parity, not immediate full feature parity.

Initial scope should focus on foundational workflows before advanced tooling such as:

- animation editors
- material graph editors
- prefab/blueprint-style authoring systems
- terrain tools
- multiplayer debugging
- profiler tooling

Preview mode direction:

- the default editor preview mode is visual preview only
- full runtime simulation may be added later as a separate mode rather than being assumed by default

## 9. Platform Expectations

All packages should:

- run on macOS
- be written in Swift where practical
- remain architecturally compatible with iOS where possible

Additional package-specific expectations:

- `Giskard Vision` uses Metal
- `Giskard Editor` uses Swift and Metal-backed rendering
- `Giskard Brain` may optionally use Metal compute

Platform compatibility should be enforced through API choices and separation of platform-specific code paths, not by weakening the macOS-first editor experience.

## 10. Package-Specific Specifications

### 10.1 Giskard Editor

Requirements:

- macOS-native desktop application
- Swift implementation
- Metal-backed scene preview
- scene hierarchy browsing and editing
- entity inspection and editing
- project asset browser
- editor-only UI state and workflow logic

Non-responsibilities:

- owning the primary runtime physics implementation
- owning renderer internals
- owning audio processing internals
- owning gameplay AI internals

### 10.2 Giskard Engine

Requirements:

- macOS runtime target
- iOS-compliant architecture
- Swift implementation
- event and message-passing systems
- core physics, motion, and collision responsibility
- subsystem unification and update coordination
- reusable framework boundary for shared runtime systems

Code ownership rules:

- game-specific runtime code should always live in separate packages
- `GiskardEngine` should remain a reusable framework package rather than a home for game-specific behavior
- each engine or world instance should own its own event system rather than relying on a single global process-wide event bus

Initial simulation scope:

- simple transforms
- velocity
- collisions
- triggers
- both 2D and 3D support from the start

Non-responsibilities:

- full renderer implementation details
- audio mixing implementation details
- device-specific input handling details

### 10.3 Giskard Vision

Requirements:

- macOS runtime target
- iOS-compliant architecture
- Swift and Metal implementation
- 2D and 3D rendering support
- simple public interfaces
- internalized resource loading and render complexity
- ownership of asset loading for renderer-managed assets
- engine-to-renderer asset references should initially be communicated as file paths

### 10.4 Giskard Hearing

Requirements:

- macOS runtime target
- iOS-compliant architecture
- Swift implementation
- audio playback and processing
- spatial audio support
- mixing and volume control

### 10.5 Giskard Brain

Requirements:

- macOS runtime target
- iOS-compliant architecture
- Swift implementation
- support for decision systems and pathfinding
- optional Metal compute acceleration where justified

### 10.6 Giskard Touch

Requirements:

- macOS runtime target
- iOS-compliant architecture
- Swift implementation
- keyboard, mouse, touch, and gamepad support
- support for both raw device events and higher-level action mappings
- action mappings should live in gameplay code or gameplay-owned data assets rather than core project or scene settings

## 11. Current Gaps Between Existing Code and Target Direction

Based on the current repository, the following gaps are visible:

- `Giskard Hearing`, `Giskard Brain`, and `Giskard Touch` do not yet exist as packages
- `Giskard Engine` currently contains entity/capability/scene foundations, but not the full event bus, message bus, or physics stack described in the target design
- `Giskard Vision` already exposes a handle-and-command API, but its rendering implementation is still an early placeholder
- the editor already supports project browsing and scene/entity editing, but it is still an early shell rather than a full production editor
- the current scene preview path is driven by a timer and direct file reloads, which is acceptable for early development but should later evolve into a cleaner editor-runtime synchronization model

## 12. Guiding Architectural Rules

To keep the system coherent as it grows, the project should follow these rules:

- package APIs should expose intent, not internal mechanics
- engine-facing abstractions should be stable before expanding editor features aggressively
- the editor should edit authored state, not silently become the runtime system
- rendering, audio, input, and AI packages should be replaceable internally without forcing broad upstream changes
- shared serialization and asset identity rules should be defined early

## 13. Immediate Next Specification Areas

The next documents that should be written after this one are:

- engine architecture spec
- editor architecture spec
- asset and project format spec
- scene and entity model spec
- event/message system spec
- rendering API contract for engine-to-vision communication
- package dependency and ownership spec

## 14. Open Questions

The following product decisions still need explicit specification:

- what the stable public API boundary between `Giskard Engine` and `Giskard Vision` should be
- whether package names are final for public distribution and long-term source layout
- whether the long-term capability model should stay string-based or evolve into a registration system with stable IDs
- how inline scene entities and referenced `.entity` assets should resolve into runtime instances
- how scene-local divergences from referenced `.entity` assets should be represented and merged
- what the stable project/package layout should be for game-specific packages that depend on `GiskardEngine`

## 15. Summary

Giskard should evolve into a macOS-first, Swift-native, package-oriented game editor and engine stack. The editor owns authoring workflows. The engine owns runtime coordination and simulation fundamentals. Vision, Hearing, Brain, and Touch own their specialized domains behind simple public interfaces. The current repository already contains the beginning of this architecture and should be extended in that direction with clearer subsystem contracts.
