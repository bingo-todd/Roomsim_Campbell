TITLE: Roomsim, a MATLAB Simulation of “Shoebox” Room Acoustics for use in Teaching and Research

KEYWORDS: room acoustics, reverberation, speech processing, cocktail party effect

SUMMARY: A simulation of “shoebox” room acoustics for those researching and teaching in areas of acoustic signal processing, music technology, auditory perception, psychoacoustics, speech and hearing, environmental acoustics, and digital signal processing.


DESCRIPTION:

A simulation of the acoustics of a simple rectangular prism room has been constructed using the MATLAB m-code programming language. The aim in creating the program Roomsim was to provide a signal generation tool for the speech and hearing research community, and a teaching tool for illustrating the image method of simulating room acoustics and some acoustical effects. The program is menu driven, comes with test data files, and example text and Excel set-up data files, has a comprehensive illustrated user guide, and is freely available (GNU General Public Licence) at the user contributed programs library of MATLAB Central.

A core aim was to provide user interaction having a suitable balance between ease of use for undergraduate students and flexibility for researchers. The m-code has been written to: (1) allow operation on PC and Unix platforms; (2) avoid the need for specialist MATLAB toolboxes; (3) avoid functions that cannot successfully be compiled to produce stand-alone executable code. Thus users need have only the basic MATLAB installation to run and develop the m-code, and users without a MATLAB installation may run the executable version on a Windows PC.

In operation the user specifies the dimensions of the room, its surface materials the type, location and orientation of the receiver system and the location of the primary source(s). This can be done interactively through the menu prompt system, or by submitting either a Microsoft Excel spreadsheet form, a text file, or by selecting a MATLAB *.mat file which saved a configuration from a previous run. The Roomsim program provides the ability to select materials for each of the six major surfaces of the simulated room from a list of standard building materials that have had their frequency dependent absorption coefficients tabulated.

A range of receiver systems are incorporated such as single sensor (e.g. mono microphone), sensor pair (e.g. two element microphone array) and simulated human head. The single and dual sensor receivers can be configured as directionally sensitive and the interpolation process recommended by Peterson [1986] is incorporated. The simulation of a head utilises the Head Related Transfer Function (HRTF) data provided from measurements made either on a Kemar mannequin at the MIT Media Lab. [1996], or on real human subjects and a Kemar at the Center for Image Processing and Integrated Computing (CIPIC), University of California, Davis [2001]. All sensor systems may be oriented in the 3D space by the user. The program also provides a facility to create a multi source “cocktail party” simulation.

The image-source to receiver responses are computed using the method of images, modified to take account of the variation of surface absorption coefficient with frequency and for the attenuation due to acoustic path length. The frequency dependent attenuation due to air is included if desired. If a simulated head has been selected the response from each quantised image-source direction is convolved with the relevant HRTF data. The individual image-source responses are then accumulated to form the complete pressure impulse response from each primary source to the receiver and the results plotted and saved to file.

These two-channel impulse response file(s) can then be convolved within the program with the users’ own monophonic audio files (*.wav, *.au or *.mat format). The resulting monaural, stereo, or “binaural response” can be saved as an audio or MATLAB file and played. The user may elect to create a “cocktail party” by combining the reverberated response files related to each simulated primary source to produce the combined acoustic signal at each sensor/ear from speech and noise signals at different locations.
-------------------------------------------------------------

PC Windows/Unix/Linux installations with MATLAB

The archive Roomsim_3p3_small.zip (20 MB)contains all the source m-code files, the user guide document Roomsim User Guide v3p3 and the support files (but with only three of the CIPIC HRTFs) for running roomsim within MATLAB.

The full version (170MB) is available from http://media.paisley.ac.uk/

To run roomsim on a PC Windows or UNIX/Linux installation with MATLAB rel 13 installed, download Roomsim_3p3_small.zip (20 MB). Extract from this zip file to a suitable directory e.g. <Matlab_ROOT>/work/Roomsim. The Roomsim User Guide contains instructions for running roomsim.

OTHER REQUIREMENTS: This executable version requires ~100MB of disk space for Roomsim, its data files, and the MATLAB run-time libraries. The program was developed on a medium specification PC (1.5 GHz Intel Pentium4, 512 MB RDRAM, 30GB HDD UDMA 100 IDE, AGP Graphics) running Windows 2000 with MATLAB v 6.5 rev. 13 installed. It has been successfully run under Windows 2000, Windows 98, and on desktop and notebook PC’s down to 200 MHz clock frequency with 128 MB RAM.
-------------------------------------------------------------
