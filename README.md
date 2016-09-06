# binhex

Translate/convert binary files to their hexadecimal representation (and vice versa)

    Copyright (c) 2003-2011
    Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta.
    Email: aa _AT_ softindo.net
    All rights reserved.

    Version: 0.1.3 build 006
    Created: 2006.03.14
    Revised: 2009.11.02

   Assembled/compiled with Borland's TASM32 and BCC 5.5 (Freeware)

 SYNOPSYS:
 
        Translate/convert binary files to their hexadecimal
        representation (and vice versa)

        Originally created to compress huge pi hex data, produces
        smaller and significantly faster than ordinary packer (zip,7z)

 USAGE:
 
        binhex.exe -b|-h filenames...

 ARGUMENTS:
 
        This program expects at least 2 arguments.

        option -b: translate target file to binary (compress).
               -h or -x: translate to hexadecimal (expand).
               -H or -X: translate to hexadecimal (uppercase).

        filenames: one or more files to be translated.

 NOTES:
 
        For each processed file, a NEW file created with the same
        name as the original, but with additional extension: ".hex"
        or ".bin". respectively according to the option switch.

        The .bin file will be half and the .hex will be twice in
        size of the original file size.

        The filesize to be translated to .bin should be even (mult.
        of 2), otherwise an imaginary '0' char will be appended.
        It must also contain hexadecimal characters only, any other
        characters will be simply translated to '0' (zero).

        Beware, this program is ridiculously fast!

 EXAMPLES:

   - Create .hex file from each of these binary files:
        binhex.exe -h sample.dat resource.dll pie.jpg others.iso

   - Create .bin file from 1G pi hex data:
     (this program took less than 4 sec. while winzip took 2.5 min.
     7z took 20+ minutes and brought down all CPU cores)

        binhex.exe -b pi_1024M_hex.txt

   - Create .bin file from 8G pi hex data:
     (this program took 27 sec (cached), 7z took it in 2h:49min
     and our winzip couldn't even handle it, too big!)

        binhex.exe -b pi_8192M_hex.txt

   note: pi hex supposed to contain perfect random data
         binhex.exe -b creates exactly 50% of original size,
         other packers will produce a slightly larger result.

 Press any key to continue..

.
