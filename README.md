# Wake Up Word Using FPGA

This was a "Wake up word" prediction project it was designed on FPGA development kit Dev DE2i-150. This kit uses Altera Cyclone 4 (FPGA). As FPGA have a constraint on resources the front end ran on MATLAB which did most of the pre-processing, as it is resource hungry but the prediction was done on FPGA. GUI was made in Matlab to capture the wake up word seamlessly from all users. 



# Requirments 

* Microphone 
* Computer (Matlab)
* DE2i-150 (Altera Cyclon 4 FPGA)

# System block diagram 

![System Design](https://github.com/adolfdcosta91/Wake-Up-Word-Using-FPGA/blob/master/GitHub/System.png)

# Operation 

![System Design](https://github.com/adolfdcosta91/Wake-Up-Word-Using-FPGA/blob/master/GitHub/Capture.png)

As soon as you click on capture voice, the program open a one-second window to capture the wake up word. The signal is processed and plotted by MatLab, the data is then sent over the serial channel to the Altera Cyclone 4 FPGA. This signal is stored in the buffer and the model is used to predict the input. The system was designed only to recognise ONE or ZERO. 

# Results

**"ONE" was detected successfully**



**"ZERO" was detected successfully**
