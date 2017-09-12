#include <conio.h>
#include <tchar.h>
#include "windows.h"
#include <stdio.h>
#include <time.h>

#define POWERSHIFT 24
const unsigned long BLOCK = 3 << POWERSHIFT;

typedef enum {false, true} bool;
typedef enum {tobin, tohex, enc64, dec64, tobits, bits2bin} cvtmode;

//__bin2hex proc source:DWORD, dest:DWORD, count:DWORD, uppercase: DWORD
//__hex2bin proc source:DWORD, dest:DWORD, count:DWORD

// to simplify conversion with MS Visual C style
#define _bin2hex __bin2hex
#define _hex2bin __hex2bin
#define _base64encode __base64encode
#define _base64decode __base64decode

// in-place conversion, source an dest may be the same.
extern __stdcall void _bin2hex(char * source, char * dest, int count, bool uppercase);
extern __stdcall void _hex2bin(char * source, char * dest, int count);
extern __stdcall unsigned int _base64encode(char * source, char * dest, int count);
extern __stdcall unsigned int _base64decode(char * source, char * dest, int count);

// assemble:	tasm32 /q /la /ml /zn bin2hex.asm - all those switches are don't really matters :)
// compile:	bcc32 /c binhex.c
// link:	ilink32	c0x32	binhex	BBQ,binhex,,import32	cw32

const _TCHAR* ext[] = { ".bin", ".hex", ".b64", ".dec", ".bit", "dat" };

int showhelp(_TCHAR* arg)
{
	_TCHAR *p, *s = arg;

	p = _tcschr(s, '\\');
	while(p) {
		s = ++p;
		p = _tcschr(p, '\\');
	}

	printf(" \n");
	printf(" Version: 0.1.4 build 016\n");
	printf(" Created: 2006.03.14\n");
	printf(" Revised: 2011.09.02\n\n");
	printf(" Assembled/compiled with Borland's TASM32 and BCC 5.5 (Freeware)\n\n");
	printf(" SYNOPSYS:\n");
	printf(" \tTranslate/convert binary files to their hexadecimal\n");
	printf(" \trepresentation (and vice versa)\n\n");
	printf(" \tBase64 encode/decode (See .asm source code for more information)\n\n");
	printf(" \tOriginally created to compress a huge 8GB pi hex data, produces\n");
	printf(" \tsmaller and significantly faster than ordinary packer (zip, 7z)\n\n");
	printf(" USAGE:\n");
	printf(" \t%s -b|-h|-e|-d filenames...\n\n", s);
	printf(" ARGUMENTS:\n");
	printf(" \tThis program expects at least 2 arguments:\n\n");
	printf(" \tOption -b: translate target file to binary (compress)\n");
	printf(" \t       -h or -x: translate to hexadecimal (expand)\n");
	printf(" \t       -H or -X: translate to hexadecimal (uppercase)\n");
	printf(" \t       -e, -d: base64 encode / decode\n");
	//printf(" \t       -i, -n: base2 encode / decode (boolean bits)\n");
	printf("\n");
	printf(" \tFilenames: one or more files to be translated.\n\n");
	//printf(" \toption -u (optional): use uppercase when translating to hex.\n\n");	
	printf(" NOTES:\n");
	printf(" \tFor each processed file, a NEW file created with the same\n");
	printf(" \tname as the original, but with additional extension: \".hex\",\n");
	//printf(" \t\".bin\", \".b64\" (base64), \".dec\" (decoded), \".bit\" or \".dat\",\n");
	//printf(" \trespectively, according to the option/switch given.\n\n");
	printf(" \t\".bin\", \".b64\" (base64) or \".dec\" (decoded), respectively,\n");
	printf(" \taccording to the option/switch given.\n\n");

	//printf(" \tThe .bin file will be half and the .hex will be twice in\n");
	//printf(" \tsize of the original file size.\n\n");
	//printf(" \tThe filesize to be translated to .bin should be even (mult.\n");
	//printf(" \tof 2), otherwise an imaginary '0' char will be appended.\n");
	//printf(" \tIt must also contain hexadecimal characters only, any other\n");
	//printf(" \tcharacters will be simply translated to '0' (zero).\n\n");
	//printf("\n");
	printf(" \tBeware, this program is ridiculously fast!\n\n");
	//printf(" \tNothing can beat a carefully handcrafted asm, FFS.\n\n");
	printf(" EXAMPLES:\n\n");
	printf("   - Create .hex file from each of these binary files:\n");
	printf("\t%s -h sample.dat resource.dll pie.jpg others.iso \n\n", s);
	printf("   - Create .bin file from 1G pi hex data:\n");
	printf("	this program took less than 4 sec. to finish\n");
	printf("	winzip took it for 2.5 min.\n");
	printf("	7z spend 20+ min. and brought down all CPU cores\n\n");
	printf("\t%s -b pi_1024M_hex.txt\n\n", s);
	printf("   - Create .bin file from 8G pi hex data:\n");
	printf("	this program took 27 sec (cached), 7z took 3 hours!\n");
	printf("	and our winzip couldn't even handle it, too big.\n\n");
	printf("\t%s -b pi_8192M_hex.txt\n\n", s);
	printf("   note: pi hex supposed to contain perfect random data\n", s);
	printf("         %s -b creates exactly 50%% of original size,\n", s);
	printf("         other packers will produce a slightly larger result.\n\n", s);
	//printf("\n");
	printf(" ====================================================\n");
	printf(" Copyright (c) 2003-2011\n");
	printf(" Adrian H, Ray AF & Raisa NF of PT SOFTINDO, Jakarta.\n");
	printf(" Email: aa _AT_ softindo.net\n");
	printf(" All rights reserved.\n");
	printf(" ====================================================\n");
	printf(" Press any key to continue..\n"); getch();
	return 1;
}

int showerr(const _TCHAR* msg)
{
	_TCHAR * lem;
	int err = GetLastError();

	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
		FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) &lem, 0, NULL);

	//printf("ERROR: %s.\nLast error code:%d\n%s", msg, err, lem);
	printf("ERROR[%d]: %s.\n", err, msg); // no need to show last error string
	if (err != 183 && err != 0) printf("%s\n", lem);
	LocalFree(lem);
	return 0;
}

int closerr(HANDLE file, const _TCHAR* msg)
{
	CloseHandle(file);
	return showerr(msg);
}

int setEOF(HANDLE file, __int64 size)
{
	LARGE_INTEGER fp;
	fp.QuadPart = size;
	if (!SetFilePointerEx(file, fp, NULL, 0)) return closerr(file, "Seeking file");
	if (!SetEndOfFile(file)) return closerr(file, "Setting EOF");
	return 1;
}


int prepfile(_TCHAR* filename, HANDLE *source, HANDLE *dest, cvtmode mode)
{
	_TCHAR destfile[255];
	LARGE_INTEGER fsz;

	strcpy(destfile, filename);
	strcat(destfile, ext[mode]);

	*source = CreateFile(filename, GENERIC_READ, FILE_SHARE_READ|FILE_SHARE_WRITE,
		NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (*source == INVALID_HANDLE_VALUE)
		return showerr("Open read failed");

	GetFileSizeEx(*source, &fsz);
	if (!fsz.QuadPart) return closerr(*source, "Source file is empty");

	*dest = CreateFile(destfile, GENERIC_WRITE|GENERIC_READ, FILE_SHARE_READ,
		NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (*dest == INVALID_HANDLE_VALUE)
		return closerr(*source, "Open write failed");

	SetFilePointer(*dest, NULL, NULL, 0);
	SetFilePointer(*source, NULL, NULL, 0);
	return 1;
}

int cvtobin(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got;
	ReadFile(source, Buf, BLOCK, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		_hex2bin(Buf, Buf, got);
		WriteFile(dest, Buf, (got + 1) >> 1, &got, NULL); printf(".");
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		if (!got) return showerr("Writing file interrupted");
		ReadFile(source, Buf, BLOCK, &got, NULL);
	}
	//printf("\n");
	return 1;
}

int cvtohex(HANDLE source, HANDLE dest, char * Buf, bool uppercase)
{
	unsigned long got;
	ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		_bin2hex(Buf, Buf, got, uppercase);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, got * 2, &got, NULL); printf(".");
		if (!got) return showerr("Writing file interrupted");
		ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	}
	//printf("\n");
	return 1;
}

int b64enc(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got, ret;
	ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		ret = _base64encode(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Writing file interrupted");
		ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	}
	//printf("\n");
    SetEndOfFile(dest); // truncate
	return 1;
}

int b64dec(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got, ret;
	ReadFile(source, Buf, BLOCK, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		ret = _base64decode(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Writing file interrupted");
		ReadFile(source, Buf, BLOCK, &got, NULL);
	}
	//printf("\n");
    SetEndOfFile(dest); // truncate
	return 1;
}

int _tmain(int c, _TCHAR* args[])
{
	HANDLE source, dest;
	LARGE_INTEGER fsz;
	char * Buf;
	int i;

int ms; clock_t tic, tac, toe;
//const int MS_SECOND = 1000;
//const int MS_MINUTE = 60 * MS_SECOND; // 60000
//const int MS_HOUR = 60 * MS_MINUTE;   // 3600000
//const int MS_DAY = 24 * MS_HOUR;      // 86400000

	cvtmode mode;
	bool uppercase = false;
	const _TCHAR* trx[] = {
		"Hex to bin", "Bin to hex", "Base64 encode",
		"Base64 decode", "Boolean bits", "Bits to bin"
	};
	//const _TCHAR* ext[] = { ".bin", ".hex" };
	//const _TCHAR* ext[] = { ".bin", ".hex", ".b64", ".d64" };

	if (c < 3) return showhelp(args[0]);

	if (strlen(args[1]) == 2 && (args[1][0] == '-' || args[1][0] == '/'))
	switch(args[1][1])
	{
		case 'b': case 'B': mode = tobin; break;
		case 'd': case 'D': mode = dec64; break;
		case 'e': case 'E': mode = enc64; break;
		case 'h': case 'x': mode = tohex; break;
		case 'H': case 'X': mode = tohex; uppercase = true; break;
		default: return showerr(strcat("Invalid option :", args[1]));
	}
	//printf("args2: %s\n", args[2]);

	Buf = malloc(BLOCK);
	if (!Buf) return showerr("Not enough memory");

	//printf("\n");
	printf("Translation mode: %s. Buffer size: %dMB\n\n", trx[mode], BLOCK >> 20);

	//for(i = 2; i < c; i++) { printf("args[%d] = %s\n", i, args[i]); }
	//printf("c = %d\n", c);

	for(i = 2; i < c; i++)
	{
		//printf("args[%d] = %s\n", i, args[i]);
		printf("Processing file: \"%s\", ", args[i]);

		if(prepfile(args[i], &source, &dest, mode))
		{

tic = clock();

			GetFileSizeEx(source, &fsz);
			printf("%I64d bytes. Please wait..\n", fsz.QuadPart);
			switch (mode) {
				case tobin: cvtobin(source, dest, Buf); break;
				case tohex: cvtohex(source, dest, Buf, uppercase); break;
                case enc64: b64enc(source, dest, Buf); break;
                case dec64: b64dec(source, dest, Buf); break;
				default: return showerr(strcat("Invalid option :", args[1]));
			}


tac = clock() - tic; ms = tac * 1000 / CLOCKS_PER_SEC;

			GetFileSizeEx(dest, &fsz);
			printf("\nDone. %I64d bytes written to: \"%s%s\". ", fsz.QuadPart, args[i], ext[mode]);
			//printf("timer: %d days, %.02d:%.02d:%.02d.%d seconds\n", ms/MS_DAY, (ms%MS_DAY)/MS_HOUR, (ms%MS_HOUR)/MS_MINUTE, (ms%MS_MINUTE)/1000, ms%1000);
			printf("timer: %d.%d seconds\n", ms/1000, ms%1000);
			printf("\n");

			CloseHandle(dest);
			CloseHandle(source);
		}
	}
	free(Buf);
	printf("\n");


	return 0;
}
