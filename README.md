# dbdis
Full screen telemetry window for Jeti Transmitter to display all kind of sensors for helis, aeroplanes and drones

It bases on the Jlog script  from nichtgedacht: https://github.com/nichtgedacht/JLog-Heli 
  
The dbdis app is specially designed for the jeti transmitters with a coloured display.  
For example the min. values are green, max. values are blue and the alarm values are red, but you can easily change it, how you like them.  
  
* Multible Sensors from different devices selectable  
* Free selection of Device ( JLog2.6, S32 and compatible ) 
* Very easy and fast configuration, most of it is self explaining
* The order of the display values can changed with arrow keys very easy
* Just values are displayed where you have set a sensor value
* A small design helps to diplay a lot of values in one window
* You can use a template design to configure the the full screen window of all models similar
* One switch for permanent percent capacitiy announcement  
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


### Examples:  
![TDF](https://github.com/ribid1/dbdis/blob/master/TDF.jpg)  
![QC650](https://github.com/ribid1/dbdis/blob/master/QC650.jpg)
![Predator](https://github.com/ribid1/dbdis/blob/master/Predator.jpg)

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
  
V1.4 Rx values of 2nd Receiver and Backup Receiver addedV1.5 2nd Battery added  
V1.6 moved the drawfunctions in the screen modul  
V1.7 Central box added  
V2.0 Second Form to change the order of the boxes added  
