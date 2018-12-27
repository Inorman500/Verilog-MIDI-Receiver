# Verilog-MIDI-Receiver

MIDI messages are transmitted asynchronously, as groups of bytes. Each byte is preceded by one START bit and followed by one STOP bit in order to synchronize reception of the data, as shown in the timing diagram of a MIDI byte. A typical MIDI message is composed of three bytes. The second byte contains the note number; it can specify 128 different musical note numbers, spanning about 10 octaves. In this assignment, you are going to store and display only the 7 least significant bits of the second byte, which is the note number, in binary. 


THe goal of this lab is to design a hardware version of a serial MIDI receiver. The design is implemented in Altera’s Complex Programmable Logic Device (CPLD) MAX 7000S, with part number EPM7064SLC44-10. Input to the Altera device is the single-bit input line from the MIDI interface cable through the opto-isolator circuit. The Altera chip will be clocked by a 4MHz crystal oscillator. Output pins of the device will drive seven LEDs to display the note number of the note played on computer keyboard in binary. 

Timing diagram of a MIDI byte can be seen here https://imgur.com/NbamwNN


Design for schematic can be seen here https://imgur.com/RbBXpfw


