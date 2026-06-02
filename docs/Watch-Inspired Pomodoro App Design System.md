# Watch-Inspired Pomodoro App Design System

## Project Vision

Create a premium Pomodoro timer inspired by high-end mechanical watches.

This is NOT a productivity tool.

This is a digital timepiece focused on:

* Time appreciation
* Focus immersion
* Mechanical elegance
* Luxury watch aesthetics

Core philosophy:

> Users should enjoy watching time pass.

---

# Design Direction

Choose ONE visual language.

Do not mix styles.

## Option A — Calatrava Style (Recommended)

Reference:

* Patek Philippe Calatrava
* Minimal Swiss dress watches

Keywords:

* Minimal
* Elegant
* Quiet
* Large whitespace
* Thin typography
* Symmetry

Characteristics:

* Almost no decoration
* Soft silver palette
* Thin markers
* Clean dial layout

Target users:

* Professionals
* Designers
* Writers
* Minimalists

---

## Option B — Saxonia Style

Reference:

* A. Lange & Söhne Saxonia Thin

Keywords:

* German precision
* Engineering
* Mechanical order
* Structured hierarchy

Characteristics:

* Sharp indices
* Strong alignment
* Technical feeling
* High contrast

Target users:

* Developers
* Engineers
* Power users

---

## Option C — Grand Seiko Style

Reference:

* Snowflake
* Shunbun

Keywords:

* Texture
* Light
* Silence
* Nature

Characteristics:

* Rich dial textures
* Dynamic reflections
* Atmospheric visuals

Target users:

* Creative users
* Meditation users
* Focus enthusiasts

---

# Design Principles

## Principle 1

One screen = one purpose.

The screen exists only to display time.

Everything else is secondary.

---

## Principle 2

Reduce interface density.

Avoid:

* Too many buttons
* Too many statistics
* Too many panels

---

## Principle 3

Mechanical feeling over digital feeling.

Avoid:

* Neon colors
* Gaming aesthetics
* Futuristic HUD design
* Cyberpunk effects

Prefer:

* Metal
* Glass
* Shadow
* Texture
* Precision

---

# Asset Architecture

## Folder Structure

assets/

```
dials/
    snowflake.webp
    enamel.webp
    sunburst.webp

hands/
    dauphine.svg
    alpha.svg
    sword.svg

indices/
    baton.svg
    roman.svg

glass/
    reflection.webp

textures/
    brushed.webp
    grain.webp

sounds/
    winding.wav
    click.wav

themes/
    calatrava.json
    saxonia.json
    snowflake.json
```

---

# Asset Specifications

## Dial Textures

Purpose:

Watch face foundation.

Format:

* WEBP
* PNG

Resolution:

2048×2048

Examples:

* Sunburst silver
* Snowflake texture
* Enamel white
* Linen texture

---

## Watch Hands

Purpose:

Animated time display.

Format:

SVG only.

Never use PNG.

Files:

* hour_hand.svg
* minute_hand.svg
* second_hand.svg

Reason:

SVG allows smooth rotation and scaling.

---

## Indices

Purpose:

Hour markers.

Format:

SVG

Examples:

* Baton markers
* Roman numerals
* Applied markers

Must remain independent components.

Do NOT bake into dial textures.

---

## Glass Layer

Purpose:

Luxury appearance.

Layer stack:

Dial
↓
Indices
↓
Hands
↓
Glass Reflection

Reflection opacity:

0.08–0.15

---

## Shadows

Purpose:

Create depth.

Required on:

* Hands
* Applied indices

Effect:

Soft shadow only.

Avoid dramatic shadows.

---

# Theme System

Never hardcode assets.

Bad:

<img src="snowflake.webp"/>

Good:

Theme-driven loading.

Example:

{
"dial": "snowflake",
"hands": "dauphine",
"indices": "baton",
"accent": "silver"
}

Application loads theme dynamically.

---

# Core Interaction Design

## Mechanical Countdown

Do NOT use a simple digital countdown.

Transform Pomodoro into watch movement.

Example:

# 0 minutes

12 o'clock

# 25 minutes

5 o'clock

Visual behavior:

* Minute hand moves slowly
* Second hand sweeps continuously

User experiences time physically.

---

# Premium Interactions

## Crown Winding

Before focus session:

User rotates crown.

Animation:

* Crown rotates
* Spring tension increases

Start session after winding.

---

## Power Reserve

Replace boring progress bars.

Focus energy becomes:

Power Reserve Indicator

Examples:

0%
25%
50%
75%
100%

Displayed like a mechanical watch reserve.

---

## Daily Focus Complication

Replace moonphase.

Examples:

* Today's focus score
* Deep work completion
* Session streak

Presented as a luxury watch complication.

---

# Sound Design

Use subtle mechanical sounds.

Examples:

* Winding
* Click
* Soft ticking
* Rotor movement

Avoid:

* Mobile notification sounds
* Game sound effects

---

# Animation Guidelines

Animation style:

Slow
Precise
Mechanical

Avoid:

* Bouncy animations
* Elastic transitions
* Cartoon motion

Prefer:

* Inertia
* Momentum
* Smooth sweeping motion

---

# Technology Recommendation

Preferred:

Flutter

Reasons:

* High FPS
* Excellent animation system
* SVG support
* Cross-platform

Platforms:

* Windows
* macOS
* iOS
* Android

Alternative:

React + Tauri

Avoid Electron in early stages.

---

# UI References

Study:

* Patek Philippe Calatrava
* A. Lange & Söhne Saxonia Thin
* Grand Seiko Snowflake
* Rolex Oyster Perpetual
* Rolex Datejust

Focus on:

* Proportions
* Negative space
* Marker placement
* Reflection behavior
* Hand design
* Surface textures

Do NOT copy directly.

Extract design principles instead.

---

# Success Criteria

The product should feel like:

A luxury mechanical instrument that happens to be a focus timer.

NOT:

A productivity app with a watch skin.
