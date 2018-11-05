# KingsApp
KingsApp is a macOS menu bar app which shows lectures and tutorials for King's College London, based on intercepted tokens from the official KCL app. It contains a LaunchAgent installer which allows it to start automatically upon login.

## How to build
- Clone the project
- Build with Xcode

## How to install
- Download the latest stable release from the [Releases](https://github.com/frannyfx/kingsapp/releases) page.
- Extract the zip file.
- Drag `KingsApp.app` into the `/Applications` folder.

## Usage
- Launch the app and enter your details (they're stored locally in an **unsafe** manner for testing purposes).
- You can manually refresh the timetable by scrolling down and clicking *Refresh*.
- You can change your KCL details by clicking on *Preferences*.

## Tidbits
- The API was very particular about the order of the XML keys and the namespaces, hence I had to hardcode a static request structure and format it dynamically with data.
- The API is also fussy about the date format.
- Initially I thought the *Authorization* header sent by the app to the server was dynamic and changed depending on the user. Upon further testing, it turned out that any request from any account requires that static token. Decoding the token using base64 didn't reveal much.

## Known issues
- Upon first draw, some of the UI items may not render. This can be solved by clicking on any part of the UI.

## Screenshots
The UI adjusts to macOS 10.14 Mojave's light/dark modes automatically.

![Dark mode screenshot.](/docs/img/dark.png)
![Light mode screenshot.](/docs/img/light.png)
