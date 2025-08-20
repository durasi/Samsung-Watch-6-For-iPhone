# Samsung Watch 6 For iPhone

This project aims to provide basic integration between the Samsung Galaxy Watch 6 and iPhone. The main goal is to enable connectivity for Notifications, Calls, and limited features via non-official methods.

## Table of Contents

* [Overview](#overview)
* [Features](#features)
* [Installation](#installation)
* [Running](#running)
* [Usage](#usage)
* [Limitations & Warnings](#limitations--warnings)
* [Contributing](#contributing)
* [License](#license)

## Overview

Samsung Galaxy Watch 6 is a Wear OS 3/4 smartwatch that is not natively compatible with Apple’s iOS ecosystem. This project provides a workaround to establish a basic connection between these two devices using Bluetooth LE (ANCS) technology or third-party solutions.

## Features

* Forward basic notifications from iPhone to Galaxy Watch
* Display incoming calls on the watch (if supported)
* Bluetooth Low Energy (BLE) connection
* Optional: background service support

## Installation

### Requirements

* Samsung Galaxy Watch 6 (Wear OS 3/4)
* iPhone with BLE support (latest iOS version recommended)
* Development environment: Android Studio or ADB tools
* (Optional) Familiarity with third-party solutions like **Merge**

### Steps

1. Clone this repository:

   ```bash
   git clone https://github.com/durasi/Samsung-Watch-6-For-iPhone.git
   cd Samsung-Watch-6-For-iPhone
   ```
2. Set up your development environment and install dependencies if needed.
3. Build the project and sideload it onto your Galaxy Watch (via ADB or Android Studio).
4. Launch the app on the watch and grant necessary permissions.

## Running

* Open the app on the watch.
* Enable pairing mode in Bluetooth settings.
* On your iPhone, select the watch from the Bluetooth devices list.
* The app will start forwarding notifications from iPhone to the watch.

## Usage

| Step | Action                                                      |
| ---- | ----------------------------------------------------------- |
| 1    | Launch the app on the watch                                 |
| 2    | Grant required permissions (notifications, Bluetooth, etc.) |
| 3    | Pair the iPhone and the Galaxy Watch via Bluetooth          |
| 4    | Test if notifications appear on the watch screen            |

---

## Limitations & Warnings

* This solution is **not officially supported** and does not provide full integration between iOS and Wear OS (e.g., health data sync, Samsung Pay, etc. may not work).
* A third-party app called **Merge** offers an alternative to connect Galaxy Watch 6 with iPhone for notifications and calls, but it may require a subscription. ([apps.apple.com](https://apps.apple.com/us/app/merge-connect-android-watches/id6698894276?utm_source=chatgpt.com), [merge.watch](https://www.merge.watch/galaxy-watch-6/?utm_source=chatgpt.com))
* Merge and similar solutions rely on Bluetooth LE (ANCS) to integrate with iOS notification system. For a more technical explanation, check out [libz.dev](https://libz.dev/posts/samsung-watch-ios/?utm_source=chatgpt.com).

## Contributing

Contributions are welcome!

* Please fork the repo and create a branch (`develop` or `feature/...`) for your changes.
* Pull requests with new features, bug fixes, or documentation updates are highly appreciated.

## License

Specify the open-source license of your choice (MIT, Apache 2.0, etc.).
If a `LICENSE` file already exists in the repository, please refer to it here.
