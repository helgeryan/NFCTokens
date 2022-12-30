# Xeal Example App - Ryan Helgeson

## Description
Example app used to display ability to implement a simple app to read/write NFC Tags. App required to meet the following requirements: 

### Design
1. Figma Link to view the screens and inspect components
2. Tap the play button in top right to see the prototype and animations
3. Use Lottie to add the included JSON files (checkmark, spinner) as animations to the app
4. Fonts files for the text within the app
5. While checkmark is being shown, implement some slight haptics 

### NFC
1. Pressing the “Funds Available” rectangle shall read the user’s name & account balance from an NFC tag.
2. After “paying/adding” funds, the new balance shall be written back to the NFC tag. 
 
## XCode Version - 14.2 (14C18)

## CocoaPods Used
lottie-ios: https://airbnb.io/lottie/#/ios 

## Steps to Run
1. Download/clone all project files. Provided in zip file (or from GitHub upon request).
2. Install pods (already included in zip, but to insure you have pods installed).
    a. Open up Terminal
    b. Navigate to the folder that contains 'Podfile'
    c. run a 'pod install'
3. Open up 'Xeal Challenge App.xcworkspace' (opening Xeal Challenge App.xcodeproj will not run because pods are not included).
4. Hook up a iPhone desired iPhone device to computer.
   NOTE: Project is set to run on a device of iOS 16.0 or newer, make sure deivce is the correct version. (If a 16.0 device is unavailable change minimum deployment by opening Xeal Challenge App.xcodeproj > General > Minimum Deployments. Rerun step 2 for installing pods)
5. Select the iPhone as the target run device
6. Build/Run

## Coding Decisions
### Tags originally have no user
To first initiate a tag to have user data in the app, a check was implemented to read from the token. If a token was not able to be read, the user is prompted to write demo data to the tag for the example use of the app. The example in this case is a user named Amanda Gonzalez with an account balance of $0.00 and an ID of 1.

### No formal data structure to follow
Since no data structure was provided, a JSON data block was the chosen method to pass data back and forth from the NFC tags. The choice of JSON simplifies the data transfer and makes for quick verification of data using inherit decoders/encoders available in Swift.

Example JSON block: 
{
    accountValue = 0;
    firstName = Amanda;
    id = 1;
    lastName = Gonzalez;
}

### Model–View–ViewModel (MVVM)
Though the app is a simple single view application, the architectural structure chosen for the app of MVVM provides separation of GUI and data operations. This use of MVVM reduces the responsibility for the View and ViewModel and reduces cluttering of code and long View/ViewController files.

### Pay now button spinner
Since there is no payment processing that is done in the app the spinner would never be observed by a user. To mimic a background payment processing a 6 second timer was implemented to ensure the spinner is visible in the demo of the app.

### Confirmation Haptics
Once a confirmation is presented to the user, there must be some way to navigate back to the previous screen. A simple tap gesture is added to the page and tapping the screen will dismiss and navigate back to the original screen.

