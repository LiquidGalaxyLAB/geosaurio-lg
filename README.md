# 🦖 GeoSaurio

GeoSaurio is an interactive Flutter application developed for **Liquid Galaxy** that allows users to explore dinosaurs through geography, geological periods and interactive visualizations.

Users can explore dinosaurs by period, continent and country, navigate to their locations in Liquid Galaxy, view additional information, listen to narrations and use interactive features such as orbit, skeleton visualization and dinosaur comparison.

---

## Table of Contents

1. [Overview](#overview-)
2. [Key Features](#key-features)
3. [Technologies Used](#technologies-used)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Liquid Galaxy Integration](#liquid-galaxy-integration)
7. [Contact](#contact)
8. [License](#license)
9. [Acknowledgements](#acknowledgements)

---

## Overview

GeoSaurio combines dinosaur information with the immersive visualization capabilities of **Liquid Galaxy**.

The application allows users to explore dinosaurs using the following hierarchy:

**Geological Period → Continent → Country → Dinosaur**

As the user explores the application, GeoSaurio communicates with Liquid Galaxy to move the camera, display dinosaur locations and show additional information on the different screens.

Once a dinosaur is selected, the user can access different interactive features such as a 360° orbit, audio narration, skeleton visualization and dinosaur comparison.

The application also includes an interactive mini map synchronized with Liquid Galaxy.

---

## Key Features

### Dinosaur Exploration

- Explore dinosaurs by geological period.
- Filter dinosaurs by continent and country.
- View detailed information about each dinosaur.
- Navigate directly to dinosaur locations.

### Liquid Galaxy Navigation

- FlyTo continents.
- FlyTo countries.
- FlyTo dinosaur locations.
- Camera positioning using KML LookAt.
- Synchronization between the application and Liquid Galaxy.

### Dinosaur Orbit

GeoSaurio includes an interactive **360° orbit** around the selected dinosaur.

The orbit uses the dinosaur position as its center and continuously updates the camera heading to create a smooth rotation around it.

The rotation is divided into multiple steps that are sent to Liquid Galaxy through SSH.

### Interactive Mini Map

The application includes an interactive map where dinosaur locations are displayed using markers.

Users can:

- Move around the map.
- Zoom in and out.
- Select dinosaurs using their markers.
- Synchronize the map position with Liquid Galaxy.

### 📍 Dinosaur Markers

GeoSaurio uses KML to display dinosaur locations in Liquid Galaxy.

The application can:

- Display dinosaur markers.
- Remove markers.
- Display the selected dinosaur cube.
- Clean the KML content when necessary.

### Skeleton Visualization

Users can display a skeleton visualization of the selected dinosaur using the Liquid Galaxy screens.

### Dinosaur Comparison

The comparison feature provides an additional visualization that helps users understand the dimensions of the selected dinosaur.

### Narration

GeoSaurio includes audio narration for dinosaurs.

The user can:

- Start the narration.
- Pause the narration.
- Stop the narration.

### Light and Dark Mode

The application supports both light and dark themes.

### Liquid Galaxy Settings

Users can configure the Liquid Galaxy connection directly from the application:

- IP address
- Port
- Username
- Password
- Number of screens

The configuration is stored locally using **SharedPreferences**.

### Liquid Galaxy Tools

GeoSaurio also provides system controls for Liquid Galaxy, including:

- Clean KML content.
- Manage logos.
- Relaunch Liquid Galaxy.
- Reboot the system.
- Shut down the system.

---

## Technologies Used

GeoSaurio was developed using:

- **Flutter**
- **Dart**
- **Liquid Galaxy**
- **KML**
- **SSH**
- **SFTP**
- **Provider**
- **SharedPreferences**
- **flutter_map**
- **OpenStreetMap**
- **just_audio**

---

## Installation

### Prerequisites

Before running GeoSaurio, make sure you have:

- Flutter installed.
- Dart installed.
- A compatible Android device or emulator.
- Access to a Liquid Galaxy installation if you want to use the Liquid Galaxy features.

### Clone the Repository

```bash
git clone <https://github.com/LiquidGalaxyLAB/geosaurio-lg>
```

Enter the project directory:

```bash
cd geosaurio-lg
```

Install the Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## Usage

### 1. Configure Liquid Galaxy

Open **LG Settings** and enter the connection information:

- IP address
- SSH port
- Username
- Password
- Number of screens

Connect GeoSaurio to Liquid Galaxy.

### 2. Select a Geological Period

From the main screen, select the geological period you want to explore.

### 3. Select a Continent

GeoSaurio displays the continents containing dinosaurs from the selected period.

Selecting a continent also moves the Liquid Galaxy camera to that location.

### 4. Select a Country

Choose one of the available countries to display its dinosaurs and geographical information.

### 5. Select a Dinosaur

Select a dinosaur to navigate to its location and open its detail screen.

### 6. Explore the Dinosaur

From the dinosaur detail screen, you can use:

- **Orbit** — Start a 360° camera orbit around the dinosaur.
- **Narration** — Listen to the dinosaur description.
- **Skeleton** — Display the dinosaur skeleton visualization.
- **Comparison** — Display the dinosaur comparison visualization.

---

## Liquid Galaxy Integration

GeoSaurio communicates with Liquid Galaxy primarily through an **SSH connection**.

`LgService` acts as the main communication point and maintains the connection with the Liquid Galaxy system.

The architecture separates the different responsibilities:

```text
                     LgService
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   Navigation          Orbit           Markers
        │                │                │
     FlyTo          360° Orbit       KML Markers
        │
        ├───────────────┬───────────────┐
        │               │               │
     Overlays          Media           System
```

The specialized services use `LgService` to execute the required commands without duplicating the SSH connection logic.

### SSH

SSH is used to:

- Send camera movements.
- Execute Liquid Galaxy commands.
- Manage KML content.
- Execute system operations.

### SFTP

SFTP is used when GeoSaurio needs to transfer files to Liquid Galaxy, such as images used by the different visualizations.

### KML

KML is used to display and control different elements in Liquid Galaxy, including:

- Dinosaur markers.
- Dinosaur information.
- Country information.
- Continent information.
- Dinosaur cube.
- Logos.
- Camera LookAt positions.

---

## License

GeoSaurio for Liquid Galaxy is licensed under the [MIT License](https://opensource.org/license/MIT)

---

## Contact

**Developer:** Josep Miquel Sert Esteban

**Project:** GeoSaurio

**GitHub:** [Project](https://github.com/LiquidGalaxyLAB/geosaurio-lg)

**Liquid Galaxy:** [Website](https://www.liquidgalaxy.eu/) | [GitHub](https://github.com/LiquidGalaxyLAB)

**Google Summer of Code 2026:** [Website](https://summerofcode.withgoogle.com/programs/2026)