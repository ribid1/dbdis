# dbdis
Full screen telemetry window for Jeti Transmitter to display all kind of sensors for helis, aeroplanes and drones  
Latest Version: **3.27**

It bases on the Jlog script  from nichtgedacht: https://github.com/nichtgedacht/JLog-Heli 
  
The dbdis app is specially designed for the jeti transmitters with a coloured display.  
For example the min. values are green, max. values are blue and the alarm values are red, but you can easily change it, how you like them.  
  
* Translations in German and in English available
* Multible Sensors from different devices selectable  
* Free selection of Device ( JLog2.6, S32 and compatible ) 
* Very easy and fast configuration, most of it is self explaining
* The order of the display values can be changed with arrow keys very easily
* Just values are displayed where you have set a sensor value
* A small design helps to display a lot of values in one window
* You can use a template design to configure the the full screen window of all models similar
* One switch for permanent percent capacitiy announcement  
* One switch for permanent remaining capacitiy of mAh or ml announcement
* One switch for permanent voltage announcement  
* One switch starts/stops software clock  
* One switch resets software clock  
* One audio file for capacity alarm selectable  
* One audio file for voltage alarm selectable  
* Adjustable capacity of main battery  
* Adjustable voltage of main battery  
* Adjustable cell count of main battery 
* Adjustable voltage alarm theshold  
* Adjustable percent capacity alarm theshold  
* Calculates initial charge condition  
* Displays Tail-Gyro values for Vstabi 
* Displays voltage per cell
* Displays flight time and engine time
* Displays and counts the total amount of flights and total flight time
* Displays the turbine status from the TStatus app: https://github.com/ribid1/TStatus
* Displays the value of Calculated Capacity 4.1 for Gas or Electric, if you don't have a sensor installed:  
http://swiss-aerodesign.com/calculated-capacity.html

### Video Links:
[Helicopters](https://youtu.be/Zso-oRc5-Y8)  
[Aeroplane with combustion engine](https://youtu.be/Qo8YZW3CySw)  


### Examples:  
![TDF](https://github.com/ribid1/dbdis/blob/master/dbdis-img/TDF.jpg)
![T-Rex700](https://github.com/ribid1/dbdis/blob/master/dbdis-img/T-Rex700.png)
![QC650](https://github.com/ribid1/dbdis/blob/master/dbdis-img/QC650.png)
![Predator](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Predator.jpg)
![Polikarpov](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Polikarpov.png)
![Predator](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Predator2.png)

### Installation:
* Copy the dbdis.lua or the dbdis.lc and the folder dbdis in the folder: \Apps
* If you don't want to make any changes in the program code then take the .lc files.
* Maybe you will edit the code sometime then take the .lua files.
  
### Configuration:  

Select Sensor:  
![Select Category](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Select%20Sensor.png)

Select Category:  
![Select Category](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Select%20Category.png)

Select Sensor Values:  
![Select Sensor Values 1](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Select%20Sensor%20Values%201.png)
![Select Sensor Values 2](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Select%20Sensor%20Values%202.png)
![Select Sensor Values 3](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Select%20Sensor%20Values%203.png)

Setup Announcements:  
(The capacity and percent announcements are used either for the battery as for the fuel)
![Setup Announcements](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Setup%20Announcements.png)

Setup Battery:  
![Setup Battery](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Setup%20Battery.png)

Setup Time Switches:  
![Setup Time Switches](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Setup%20Time%20Switches.png)

Setup History:  
![Setup History](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Setup%20History.png)

### Layout:
Design the Layout (use the arrow keys to change the order):  
- Sep.: determine the thickness of the seperator line (0 = no seperator, -1 = value is edged)  

![Layout 1](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Layout_1.png)
![Layout 2](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Layout_2.png)
![Layout 3](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Layout_3.png)

### Config Batteries:  
You have two possibilities to add a batterie:  
- If you have a Rfid Sensor and the battery has a Rfid Tag, you don't need anything to do. The app will recognize the battery and will store every use of the battery.  
- The other way is to select the "+" on the batteries page and a new entry will be made.
On the first line you can config your battery, and on the second line you could adjust the values if you want.  
![Config Batteries](https://github.com/ribid1/dbdis/blob/master/dbdis-img/Config_Batteries.png)

### Flight book:  
After every flight an entry in the dbdis_Log.txt is made.  
You can look at this file just from your transmitter,  
but you can also copy these entrys by Crtl-C, then navigate to the first empty cell in the dbdis_Log_en.xlsm  
or the dbdis_Log_de.xlsm and then run the included Makro "Import_Data":  
[How to update an excel Flightbook](https://youtu.be/opMr2ESBsqg)

![dbdis_log_en](https://github.com/ribid1/dbdis/blob/master/dbdis-img/dbdis_Log_en.JPG)
![dbdis_log_de](https://github.com/ribid1/dbdis/blob/master/dbdis-img/dbdis_Log_de.JPG)


### History:  
  
V1.0 initial release  
V1.1 Turbine status and turbine telemetry added  
V1.2 improvement of the timer function:
- if you activate the reset switch during the timer runs:  
    The actual flight will not count and the timer starts at zero again.    
- if you activate the reset switch during the timer stops, and you have already reached the time limit:  
    The actual flight will be count and the timer starts at zero again an other flight.  
    
- impliment of the CalCa- Gas and the CalCa-Elec App: If you get values from the app they will be used. 

V1.3 select sensors from different devices  
- save the History (fight counts and total flight time in a file) 
  
V1.4 Rx values of 2nd Receiver and Backup Receiver added  
V1.5 2nd Battery added  
V1.6 moved the drawfunctions in the screen modul  
V1.7 Central box added  
V2.0 Second Form to change the order of the boxes added  
V2.1 Permanent Value Alarm added  
- Tank Volume added  

V2.2 Possibility for a surrounding edge of the value boxes added  
V2.3 The high in pixels of each box is displayed in the layout form
- Not assigned boxes are shown in small letters
- The left space in pixel is shown at the top of the right and the left row  

V2.4 Second page and speed box added  
V2.6 Changed the format of the config file to .jsn  
V3.0 Added an input Window to config batteries  
  - Added Rfid Sensor Values  
  - After every flight in the dbsis_Log.txt a log entry is made with important datas
  - Added  dbdis_Log_en.xlsm and dbdis_Log_de.xlsm with the Makro "Import_Data" as an example how you can Import very easy the log entries from the dbsis_Log.txt to Excel   
  
V3.1 To Interact with the CalCa-Elec from  Walter Loetscher I had to add two lines that his app will get the capacity from the "BAT" site, or the Rfid Sensor in the dbdis app.  
V3.27 Changed beause the DS12 isn't able to unload not used packages  
    - Sensors with no labels like from the spirit system causes a failure
