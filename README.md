
# Layin
### A floating keyboard layout indicator

Switching between more than two active keyboard layouts can become really annoying - you discover that you're on a wrong layout when you already started typing and have to remove what's typed and carefully check the system tray while switching again to make sure the next time you choose the correct one. 

*Layin* shows the currently active layout as an indicator floating next to the mouse pointer. This indicator is permanently visible when the cursor is hovering over any input field (has the I-beam shape). Outside input fields the indicator pops up for a short time when the layout is switched.

This is a simplistic alternative to apps like *Aml Maple*, *Mouse Flying Indicator* and *langcursor*.

### Setup
1. You can either download a [prebuilt executable](https://github.com/unconditional/layin/releases/latest/download/layin.exe) from the [Releases](https://github.com/unconditional/layin/releases/) section or build it yourself.
    To build an executable you will need [AutoHotkey](https://www.autohotkey.com/) installed. Download the source `.ahk` file, right-click it and choose `Compile Script`. This will create an executable in the directory of the source file by default.
2. Download and drop the example `.ini` file in the same directory and tweak it as desired (see below for more info).
3. Run the executable and have fun.

### Configuration
The tool is configured via an INI file that must reside in the same directory and have the same name as the executable, e.g. `layin.ini`.

The following parameters are supported in the `[Indicator]` section:
| Parameter | Description | Example value |
| --------- | ----------- | ------------- |
| `width` | width of the indicator in pixels | `30`
| `height` | height of the indicator in pixels | `20`
| `fontColor` | indicator font color in hex (`rrggbb`) | `ffffff`
| `fontSize` | indicator font size in points | `12`
| `transparency` | level of transparency of the indicator, from 0 (invisible) to 255 (non-transparent)  | `180`
| `layoutScanPeriodMs` | current layout checking time interval in milliseconds | `100`

The `[Languages]` section allows to customize indicator text and the background color for any keyboard layout available in your OS. It should contain records in the following format:
```
<display-text> = <layout-code>;<background-color>
``` 
where 

 - `<display-text>` is the text that will be displayed in the indicator, e.g. `EN` for the English layout
 - `<layout-code>` - the code of the corresponding layout in decimal, e.g. `1033` for the English layout. The list of the language codes can be found for example at https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oe376/6c085406-a698-4e12-9d4d-c3b0ee3dbc4a .
 - `<background-color>` - the indicator background color in hex for this layout, e.g. `00bb00`

Here's an example of what the layout configuration might looks like:
```ini
[Languages]
EN = 1033;00bb00
ES = 1034;ff6666
HE = 1037;5555ff
```

### License
MIT

**Free Software, Hell Yeah!**
