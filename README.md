# EMS Dispatch Modernized 🚑

A standalone, high-performance, and feature-rich EMS dispatch system designed for FiveM servers using the **Qbox** or **QBCore** framework. This resource provides a premium dispatching experience with a focus on ease of use and clinical aesthetics.

## ✨ Features

*   **Premium Modern UI**: A clean, dark-themed notification and history interface with professional clinical blue accents.
*   **311 Emergency System**: A dedicated `/311` command for citizens to report medical emergencies, featuring automatic street and zone detection.
*   **Responder Tracking**: Real-time logging of which medical staff member acknowledged a call. "Responded by: [Name]" appears in the history for team coordination.
*   **Instant GPS Sync**: Paramedics can press the **`[E]`** key to instantly mark the location of the most recent emergency on their GPS.
*   **Efficient History (HUB)**: A dispatch history list (default key **`U`**) that automatically filters out calls older than 5 minutes to keep operations relevant and the system lightweight.
*   **Dynamic Map Blips**: Incoming calls generate a pulsing red person icon on the map for all on-duty EMS, automatically removed after 2 minutes.
*   **Performance Optimized**: Features intelligent thread throttling for a baseline idle usage of **0.00ms - 0.01ms**.

## 🛠️ Installation

1.  Download or clone this repository into your `resources` folder.
2.  Add `ensure ems-dispatch` to your `server.cfg`.
3.  Ensure you have the following dependencies:
    *   [ox_lib](https://github.com/overextended/ox_lib)
    *   [qbx_core](https://github.com/Qbox-Project/qbx_core) (or standard QBCore with minor edits)
    *   [oxmysql](https://github.com/overextended/oxmysql)

The database table `ems_calls` will be created/updated automatically upon the first resource start.

## 🕹️ Controls

*   **Citizens**: `/311 [message]`
*   **EMS (On-Duty)**: 
    *   **`U`**: Open/Close Dispatch History Hub.
    *   **`E`**: Mark GPS to the latest inbound call.
    *   **Click [E] MARK GPS**: Manual UI response from history.

## 📝 Customization

You can adjust specific job names and default keybinds in the `config.lua` file.

---
*Created with focus on modern Roleplay standards.*
