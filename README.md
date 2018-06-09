# binhex

Translate/convert binary files to their hexadecimal representation (and vice versa: bin2hex hex2bin)

    Copyright (c) 2003-2011
    Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta.
    Email: aa _AT_ softindo.net
    All rights reserved.

    Version: 0.1.6 build 029
    Created: 2006.03.14
    Revised: 2011.09.29

    Compiled with Borland's BCC 5.5 (freeware), assembler: lzasm (SSE2)
    uasm/jwasm, nasm, masm and lzasm (best) support SSE2, tasm support MMX

    SYNOPSYS:
        - Translate binary files to their hexadecimal representation
          (and vice versa)

        - Base64 encode/decode (See .asm source code for more info)

    Originally created to compress a huge 8GB pi hex data, produces
    smaller and significantly faster than ordinary packer (zip, 7z).

    USAGE:
        binhex.exe <switch> <filenames>...

    ARGUMENTS:
        This program expects at least 2 arguments:

        <switch>: You may use slash: "/" intead of hyphen/dash: "-"
          -b: translate target file to binary (compress)
          -h or -x: translate to hexadecimal (expand)
          -H or -X: translate to hexadecimal (uppercase)

          -e, -d: base64 encode/decode
          -l: prettify base64 encoded data paragraphs with CR/LF
          -t: trim CR/LF (also any other invalid base64 characters)

        <filenames>: One or more files to be translated.

    NOTES:
        For each processed file, a new file will be created with
        the same name as original, but with additional extension:
        ".bin", ".hex", ".enc" (base64 encoded), ".dec" (decoded),
        "-crlf" (delimited) or "-trim" (trimmed), respectively,
        according to the option/switch given.

        Beware, this program is ridiculously fast!

    EXAMPLES:
    
    - Create .hex file from each of these binary files:
        binhex.exe -h sample.dat resource.dll pie.jpg others.iso

    - Create .bin file from 1G pi hex data:
        this program took less than 4 sec. to finish
        winzip took it for 2.5 min.
        7z spend 20+ min. and brought down all CPU cores

        binhex.exe -b pi_1024M_hex.txt

    - Create .bin file from 8G pi hex data:
        this program took 27 sec (cached), 7z took 3 hours!
        and our winzip couldn't even handle it, too big.

        binhex.exe -b pi_8192M_hex.txt

    note: pi hex supposed to contain perfect random data
         binhex.exe -b creates exactly 50% of original size,
         other packers will produce a slightly larger result.
