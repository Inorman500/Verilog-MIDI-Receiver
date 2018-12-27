# Verilog-MIDI-Receiver

The goal of the project is to design a serial port for the MIDI device that will read a MIDI signal, interpret its content and display the note number
(from the second byte) in binary on seven LEDs. The note number will remain on the LEDs only as long as the note remains on. The
MIDI signal will come from the PC via MIDI OX. The notes played on the computer’s keyboard will cause MIDI data
to be sent serially out the MIDI OUT connector. This signal will be connected to a MIDI IN connector on the breadboard.

Design for schematic can be seen here
