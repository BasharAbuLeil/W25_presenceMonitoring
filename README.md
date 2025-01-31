# W25_presenceMonitoring
# Movement Detection and Treatment Monitoring System

## Project Description
This project is an IoT-based movement detection and treatment monitoring system designed for Snoezelen therapy rooms in nursing homes. It helps track patient movement and responses during therapy sessions by utilizing two ESP32 microcontrollers.

The system collects and stores data using Firestore, and healthcare providers can access it via a web application.

## Group Members
- Bashar Abu Leil
- Jad Agbaria
- Abeer Mhameed

## Libraries and Versions

### ESP32 Libraries
- Adafruit_SSD1306 (v2.5.7) - OLED display driver
- ESP32 Arduino Core (v2.0.14)
- Firebase_ESP_Client (v4.3.19)
- MyLD2410 (v1.0.0) - Radar sensor library
- SD (v2.0.0) - SD card operations
- WiFi (v2.0.0)
- esp_now (v2.0.0)

### Web Application
- React (v18.2.0)
- Firebase (v10.1.0)
- Tailwind CSS (v3.3.0)
- shadcn/ui (v0.7.0)

## Repository Structure
```
├── hardware/
│   ├── mainESP/             # Main ESP32 code
│   ├── display/             # Display handling
│   ├── espNowFunctions/     # ESP-NOW communication
│   ├── firestore/           # Firebase integration
│   └── SD_functions/        # SD card operations
├── webapp/
│   ├── src/                 # React application source
│   ├── public/              # Static files
│   └── package.json         # Dependencies
├── docs/
│   ├── wiring_diagram.png   # Hardware connections
│   └── poster.jpg           # Project poster
├── parameters.h             # Configuration parameters
└── secrets_template.h       # Credentials template
```

## Hardware Components

### Required Components
1. Main Controller
   - ESP32 Development Board (×2)
   - USB-C Cable for programming (×2)

2. Sensors and Display
   - LD2410 Radar Sensor (×2)
   - SSD1306 OLED Display 128×32 (×1)
   - 4×4 Matrix Keypad (×1)

3. Storage and Connectivity
   - Micro SD Card Module (×1)
   - Micro SD Card 8GB+ (×1)

4. Power Supply
   - 5V Power Supply (×1)
   - Power Jack (×1)

5. Miscellaneous
   - Jumper Wires (×20)
   - Project Box/Enclosure (×2)
   - Mounting Hardware (assorted)
### System Components
1. Main ESP32 (Primary Unit)
This microcontroller serves as the core of the system and is responsible for:
- Receiving patient ID via a 4×4 keypad.
- Detecting movement using an LD2410 radar sensor.
- Displaying session information on an OLED screen.
- Uploading collected data to Firebase Firestore.
- Storing backup data on an SD card.
- Communicating wirelessly with the Slave ESP32 using ESP-NOW.

2. Slave ESP32 (Secondary Unit)
This unit assists in improving motion detection accuracy and environment monitoring. It is responsible for:
- Monitoring additional movement using a second LD2410 radar sensor.
- Detecting light conditions in the room using a TCS230 color sensor.
- Sending sensor data to the Main ESP32 via ESP-NOW.

## Wiring Diagram
![WhatsApp Image 2025-01-28 at 16 23 54](https://github.com/user-attachments/assets/cdf26f92-8304-4949-aa22-0a607be3dfe6)
![WhatsApp Image 2025-01-28 at 16 24 07](https://github.com/user-attachments/assets/57a80382-17ab-40de-bd75-d642ea3de1c9)

### Pin Connections
1. OLED Display (I2C)
   - SDA → GPIO21
   - SCL → GPIO22
   - VCC → 3.3V
   - GND → GND

2. LD2410 Radar
   - RX → GPIO16
   - TX → GPIO17
   - VCC → 5V
   - GND → GND

3. Matrix Keypad
   - Rows: GPIO12, 14, 27, 26
   - Columns: GPIO25, 33, 32, 4

4. SD Card Module
   - CS → GPIO5
   - MOSI → GPIO23
   - MISO → GPIO19
   - SCK → GPIO18
   - VCC → 3.3V
   - GND → GND

## Software Setup

### 1. Hardware Configuration
Before using the system, configure the SD card with required credentials:

1. `wifi.txt`:
```
[WIFI_SSID]
[WIFI_PASSWORD]
```

2. `fireBaseCreds.txt`:
```
[PROJECT_ID]
[API_KEY]
[DATABASE_URL]
[USER_EMAIL]
[USER_PASSWORD]
```

### 2. Web Application Access
The web interface allows healthcare providers to:
- Search patients by 6-digit ID
- View sessions by date or date range
- Analyze movement patterns and treatment progress
- Access detailed minute-by-minute session data

## User Interface

### Hardware Interface
1. OLED Display Messages:
   - System status
   - Session information
   - WiFi connection status
   - Error messages

2. Keypad Functions:
   - Numbers (0-9): ID entry
   - D: Backspace
   - Any key during session: Stop monitoring

# Web App - User Guide

## Overview
This web application helps track and manage treatment sessions for patients. It provides features for viewing individual patient histories and accessing global treatment data across different date ranges.

## Relax Field Definition
In our project, we define the "Relax" field to indicate whether the patient is in a relaxed state based on their activity level. The value of this field is determined as follows:
"Yes" → If the activity level is below 60%.
"No" → If the activity level is 60% or higher.

## Activity Level Measurement
The activity level is calculated by monitoring patient motion over a 60-second interval using the two LD2410 radar sensors. The process is as follows:

Every second, each motion sensor detects whether movement has occurred (binary: motion detected or no motion).
We count the total number of motion detections (peaks) over 60 seconds for each sensor.
The final activity level is determined by taking the maximum count between the two sensors.
This approach ensures that we capture the highest level of movement in the room, making our monitoring system more reliable in detecting patient activity.

## Getting Started

### Login
1. Access the application through your web browser
2. Enter your email and password on the login screen
3. Use the theme toggle in the top-right corner to switch between light and dark modes

### Main Features

#### Patient ID Search
1. After logging in, you can search for specific patients:
   - Enter a 6-digit patient ID in the ID field
   - Click "Search ID" to view that patient's complete treatment history
   - The system will show all sessions for that specific patient

#### Date-Based Search
You can search for treatment sessions by date in two ways:

1. **Single Date Search**:
   - Enter year (YYYY), month (MM), and day (DD)
   - Click "Show History" to view all sessions from that day

2. **Date Range Search**:
   - Toggle "Searching by Date Range" switch
   - Enter start date and end date
   - Click "Show Range History" to view sessions within that period

### Viewing Session Data

#### Treatment Sessions View
When viewing sessions, you'll see a table with the following information:
- Date and time of session
- Duration in minutes
- Average activity percentage
- Color values
- Intensity levels
- Relaxation status
- View button for detailed session data

#### Detailed Session View
Clicking "View" on any session shows:
- Complete session information
- Duration
- Average activity
- Relaxation status
- Minute-by-minute logs showing:
  - Color values
  - Intensity levels
  - Activity percentages
  - Relaxation status for each minute

### Edge cases
- Future dates are not accepted for searches
- Invalid patient IDs will show an error message
- If no data exists for a selected date/range, you'll receive a notification
- All data is displayed in chronological order
- Session times are shown in 24-hour format

## Tips
- Use the date range search for analyzing trends over time
- The single date view is perfect for daily session reviews
- Patient ID search is useful for tracking individual progress
- Tables can be scrolled horizontally if all columns don't fit on screen
- Dark mode may be easier on the eyes in low-light conditions



## Project Poster
<img width="765" alt="Screenshot 2025-01-30 at 11 53 38" src="https://github.com/user-attachments/assets/131d32a3-f100-458d-992d-e41a3e01c618" />


## Parameters 
```cpp
// Display Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

// Sensor Configuration
#define RX_PIN 16
#define TX_PIN 17
#define INDICATOR_PIN 2

// Session Parameters
#define ID_LENGTH 6
#define SAMPLE_INTERVAL 1000  // 1 second
#define SESSION_TIMEOUT 1800  // 30 minutes
```

## Secrets Template 
```cpp
// WiFi Configuration
#define WIFI_SSID ""
#define WIFI_PASSWORD ""

// Firebase Configuration
#define FIREBASE_PROJECT_ID ""
#define FIREBASE_API_KEY ""
#define FIREBASE_DATABASE_URL ""
#define FIREBASE_USER_EMAIL ""
#define FIREBASE_USER_PASSWORD ""
```



## Security Considerations
- All Firebase credentials are stored securely
- WiFi credentials are kept on SD card
- Web application uses secure authentication
- Data transmission is encrypted
- Patient data is protected and access-controlled


