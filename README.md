# Godello (aka GodoTrello) ![Godot 3.2](https://img.shields.io/badge/godot-v3.2-%23478cbf)

Trello inspired kanban board made with the [Godot Engine](http://godotengine.org/) and GDScript, powered by an online real-time collaborative backend.

## Motivation

A Godot Engine proof of concept for:

- Business applications
- Advanced GUI
- Complex data architecture and data modeling
- Real-time online data flow
- Connected multi-user collaborative interfaces and interactions

## Features

- Trello-like interface, data organization and interactions:
  - Kanban Boards with Lists and Cards
  - Ordering and positioning of Lists and Cards by dragging and dropping
- Repository data design pattern
- Reactive, [React](https://reactjs.org/)-like, two way data binding and data propagation using Godot's [signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html).
- Real-time online connectivity and multiple user collaboration using Godot's [WebSockets](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html).
  - The backend layer is implemented using an agnostic BackendAdapter, this way any backend language and framework can be used. The BackendAdapter even allows to remove the usage of WebSockets and use only HTTP or local calls.
  - The main backend implementation is made with [Elixir](http://elixir-lang.org/) + [Phoenix Channels](https://phoenixframework.org/) backed by a PostgreSQL database. Communication with Godot is done using the library [GodotPhoenixChannels](https://github.com/alfredbaudisch/GodotPhoenixChannels).
- Multi-user presence detection
- User account flow (sign-up and login)

## Roadmap

- User account improvements:
  - Password recovery
  - Profile management (update user profile and credentials)
- Additional backends and backend adapters:
  - Node.js (Express + socket.io)
  - Kotlin (Ktor)
  - PHP (Laravel)
