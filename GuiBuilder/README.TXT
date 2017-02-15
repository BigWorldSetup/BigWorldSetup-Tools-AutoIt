
Prototype for New AutoBuilder - CyberSlug
-----------------------------------------

*** Info for 11 January 2005 ****

Very minor updates to allow AutoBuilder to work with latest AutoIt version
- GuiSendMsg reanamed to GuiCtrlSendMsg
- Did not re-declare variables that were CONST
- fixed missing quotation mark bug in generated script with GuiCtrlCreateIcon
- probably other stuff



*** Info for 27 November 2004 ***

I'm too lazy to put much here :)
I haven't worked directly on the AutoBuilder prototype file....
but I've worked on wrapper functions and libraries of constants....
The prototype is mostly for testing of ideas, and the code is ugly.
Final version of AutoBuilder will start from a clean slate, but will
incorporate ideas and functions from the prototype.




*** Supported features as of 16 October 2004 ***


- Most controls available; unsupported controls are grayed out.
- Creation and moving by mouseDown-drag-mouseUp
- "Grippy" control resizing
- VERY BASIC GUI SCRIPT GENERATION
- Copy and Paste hotkeys (Ctrl+C and Ctrl+V)
- Control deletion (Delete hotkey)
- Menus to toggle grid and snap-to-grid stuff
- Menu to change control text


To-do:  Lots of stuff.  This is idea code, so the script is messy.
The final code will be modular and use good variable conventions.







Plan for AutoBuilder - 10 Oct 2004 - CyberSlug
----------------------------------------------

Core Goals:
- Provide a VisualBasic-like GUI for drawing an AutoIt GUIs (create/move/resize controls)
- Generate AutoIt code from the user-created GUI
- Allow user to save and open GUIs created with AutoBuilder
- Support all controls that AutoIt supports

Other Goals:
- Let user update styles and exStyles
- Snap-to-grid
- HotKey support
- Allow copy and delete of controls
- Allow "control arrays"
- View the generated AutoIt code in realtime? IDE features???
- MultiGui support?

