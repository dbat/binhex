#include <conio.h>
#include <tchar.h>
#include "windows.h"
#include <stdio.h>
#include <time.h>

#define POWERSHIFT 24
const unsigned long BLOCK = 3 << POWERSHIFT;

typedef enum {false, true} bool;
typedef enum {tobin, tohex, enc64, dec64, tobits, bits2bin, trim64, delim64 } cvtmode;

//__bin2hex proc source:DWORD, dest:DWORD, count:DWORD, uppercase: DWORD
//__hex2bin proc source:DWORD, dest:DWORD, count:DWORD

#define xstr(s) str(s)
#define str(s) #s

// to simplify conversion with MS Visual C style
#ifdef assm
	#ifdef tasm32
		#define supp MMX
		#define _bin2hex __bin2hex_mmx
		#define _hex2bin __hex2bin_mmx
	#else
		#define supp SSE2
		#define _bin2hex __bin2hex_sse2
		#define _hex2bin __hex2bin_sse2
	#endif /* assm==TASM32 */
#else
	#define assm unknown
	#define supp standard
	#define _bin2hex __bin2hex
	#define _hex2bin __hex2bin
#endif /*assm */

#define _base64encode __base64encode
#define _base64decode __base64decode
//#define _base64encode_LF __base64encode_LF
#define _base64trim __base64trim
#define _base64delim __base64delim
// in-place conversion, source an dest may be the same.
extern __stdcall void _bin2hex(char * source, char * dest, int count, bool uppercase);
extern __stdcall void _hex2bin(char * source, char * dest, int count);
extern __stdcall unsigned int _base64encode(char * source, char * dest, int count);
extern __stdcall unsigned int _base64decode(char * source, char * dest, int count);
extern __stdcall unsigned int _base64trim(char * source, char * dest, int count);
extern __stdcall unsigned int _base64delim(char * source, char * dest, int count);
//extern __fastcall unsigned int _base64delim(char * source, char * dest, int count);

// assemble:	tasm32 /q /la /ml /zn bin2hex.asm - all those switches are don't really matters :)
// compile:	bcc32 /c binhex.c
// link:	ilink32	c0x32	binhex	BBQ,binhex,,import32	cw32

const _TCHAR* ext[] = { ".bin", ".hex", ".enc", ".dec", ".bit", ".dat", "-trim", "-crlf" };

int showhelp(_TCHAR* arg)
{
	_TCHAR *p, *s = arg;

	p = _tcschr(s, '\\');
	while(p) {
		s = ++p;
		p = _tcschr(p, '\\');
	}

	printf(" \n");
	printf(" Version: 0.1.6 build 029\n");
	printf(" Created: 2006.03.14\n");
	printf(" Revised: 2011.09.29\n\n");
	printf(" Compiled with Borland's BCC 5.5 (freeware), assembler: %s (%s)\n", xstr(assm), xstr(supp));
	printf(" uasm/jwasm,nasm,masm and lzasm (best) support SSE2, tasm support MMX\n\n");
	printf(" SYNOPSYS:\n");
	printf(" \t- Translate binary files to their hexadecimal representation\n");
	printf(" \t  (and vice versa)\n");
	printf("\n");
	printf(" \t- Base64 encode/decode (See .asm source code for more info)\n");
	printf("\n");
	printf(" Originally created to compress a huge 8GB pi hex data, produces\n");
	printf(" smaller and significantly faster than ordinary packer (zip, 7z).\n");
	printf("\n");
	printf(" USAGE:\n");
	printf(" \t%s <switch> <filenames>...\n\n", s);
	printf(" ARGUMENTS:\n");
	printf(" \tThis program expects at least 2 arguments:\n\n");
	printf(" \t<switch>: You may use slash: \"/\" intead of hyphen/dash: \"-\"\n");
	printf(" \t  -b: translate target file to binary (compress)\n");
	printf(" \t  -h or -x: translate to hexadecimal (expand)\n");
	printf(" \t  -H or -X: translate to hexadecimal (uppercase)\n");
	printf("\n");
	printf(" \t  -e, -d: base64 encode/decode\n");
	printf(" \t  -l: prettify base64 encoded data paragraphs with CR/LF\n");
	printf(" \t  -t: trim CR/LF (also any other invalid base64 characters)\n");
	//printf(" \t  -i, -n: base2 encode / decode (boolean bits)\n");
	printf("\n");
	printf(" \t<filenames>: One or more files to be translated.\n\n");
	//printf(" \toption -u (optional): use uppercase when translating to hex.\n\n");	
	printf(" NOTES:\n");
	printf(" \tFor each processed file, a new file will be created with\n");
	printf(" \tthe same name as original, but with additional extension:\n");
	printf(" \t\"%s\", \"%s\", \"%s\" (base64 encoded), \"%s\" (decoded),\n", ext[tobin], ext[tohex], ext[enc64], ext[dec64]);

	//printf(" \t\"%s\" (delimited), \"%s\" (trimmed), \"%s\", \"%s\" etc.\n", ext[delim64], ext[trim64], ext[tobits], ext[bits2bin]);
	//printf(" \trespectively, according to the option/switch given.\n\n");

	printf(" \t\"%s\" (delimited) or \"%s\" (trimmed), respectively,\n", ext[delim64], ext[trim64]);
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
	printf("   note: pi hex supposed to contain perfect random data\n");
	printf("         %s -b creates exactly 50%% of original size,\n", s);
	printf("         other packers will produce a slightly larger result.\n\n");
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
    //char * q;
    //char * b;
    //q = malloc(BLOCK+32);
    //b = (char *)((int)(q + 15) & 0xfffffff0); // align 16
    
	unsigned long got;
	ReadFile(source, Buf, BLOCK, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		if (got & 1) Buf[got] = 0; // make sure zero padded on odd size
		_hex2bin(Buf, Buf, got);
		WriteFile(dest, Buf, (got + 1) >> 1, &got, NULL); printf(".");
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		if (!got) return showerr("Writing file interrupted");
		ReadFile(source, Buf, BLOCK, &got, NULL);
	}
	//printf("\n");
	//free(q);
	return 1;
}

int cvtohex(HANDLE source, HANDLE dest, char * Buf, bool uppercase)
{
    //char * q;
    //char * b;
    //q = malloc(BLOCK+32);
    //b = (char *)((int)(q + 15) & 0xfffffff0); // align 16

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
	//free(q);
	return 1;
}

int b64enc(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got, ret;
	ReadFile(source, Buf, (BLOCK >> 2) * 3, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		ret = _base64encode(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Skip encoding 0 filesize");
		ReadFile(source, Buf, (BLOCK >> 2) * 3, &got, NULL);
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
	SetEndOfFile(dest); // truncate
	while (got)
	{
		ret = _base64decode(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Skip decoding 0 filesize");
		ReadFile(source, Buf, BLOCK, &got, NULL);
	}
	//printf("\n");
    SetEndOfFile(dest); // truncate
	return 1;
}

int b64trim(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got, ret;
	ReadFile(source, Buf, BLOCK, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		ret = _base64trim(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Skip trimming 0 filesize");
		ReadFile(source, Buf, BLOCK, &got, NULL);
	}
	//printf("\n");
    SetEndOfFile(dest); // truncate
	return 1;
}

int b64delim(HANDLE source, HANDLE dest, char * Buf)
{
	unsigned long got, ret;
	ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	//printf("got %d bytes. Buf: %p\n", got, Buf); getch();
	while (got)
	{
		ret = _base64delim(Buf, Buf, got);
		//printf("got to be: %d bytes. Buf: %p\n", got, Buf); getch();
		WriteFile(dest, Buf, ret, &got, NULL); printf(".");
		if (!got) return showerr("Skip processing 0 filesize");
		ReadFile(source, Buf, BLOCK >> 1, &got, NULL);
	}
	//printf("\n");
	SetEndOfFile(dest); // truncate
	return 1;
}

int _tmain(int c, _TCHAR* args[])
{
	HANDLE source, dest;
	LARGE_INTEGER fsz;
	char * BUF;
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
		"Base64 decode", "Boolean bits", "Bits to bin",
		"Trim/sanitize Base64 encoded data", "Delimits/prettify Base64 encoded data"
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
		case 't': case 'T': mode = trim64; break;
		case 'l': case 'L': mode = delim64; break;
		case 'i': case 'I': mode = tobits; break;
		case 'n': case 'N': mode = bits2bin; break;
		case 'h': case 'x': mode = tohex; break;
		case 'H': case 'X': mode = tohex; uppercase = true; break;
		default: return showerr(strcat("Invalid option :", args[1]));
	}
	//printf("args2: %s\n", args[2]);

	BUF = malloc(BLOCK+32);
	if (!BUF) return showerr("Not enough memory");

	i = ((int)BUF + 15) & 0xfffffff0; //align 16
	Buf = (char*)i;

	//printf("\n");
	printf("Translation mode: %s. Buffer size: %dMB at %pH\n\n", trx[mode], (int)BLOCK >> 20, Buf);

	//for(i = 2; i < c; i++) { printf("args[%d] = %s\n", i, args[i]); }
	//printf("c = %d\n", c);

	for(i = 2; i < c; i++)
	{
		//printf("args[%d] = %s\n", i, args[i]);
		printf("Processing file: \"%s\", ", args[i]);

		if(prepfile(args[i], &source, &dest, mode))
		{

//----------------------------------------------------
tic = clock();
//----------------------------------------------------
			GetFileSizeEx(source, &fsz);
			printf("%I64d bytes. Please wait..\n", fsz.QuadPart);
			switch (mode) {
				case tobin: cvtobin(source, dest, Buf); break;
				case tohex: cvtohex(source, dest, Buf, uppercase); break;
				case enc64: b64enc(source, dest, Buf); break;
				case dec64: b64dec(source, dest, Buf); break;
				case trim64: b64trim(source, dest, Buf); break;
				case delim64: b64delim(source, dest, Buf); break;
				default: return showerr(strcat("Invalid option :", args[1]));
			}
//----------------------------------------------------
tac = clock() - tic; ms = tac * 1000 / CLOCKS_PER_SEC;
//----------------------------------------------------
			GetFileSizeEx(dest, &fsz);
			printf("\nDone. %I64d bytes written to: \"%s%s\". ", fsz.QuadPart, args[i], ext[mode]);
			//printf("timer: %d days, %.02d:%.02d:%.02d.%d seconds\n", ms/MS_DAY, (ms%MS_DAY)/MS_HOUR, (ms%MS_HOUR)/MS_MINUTE, (ms%MS_MINUTE)/1000, ms%1000);
			printf("timer: %d.%d seconds\n", ms/1000, ms%1000);
			printf("\n");

			CloseHandle(dest);
			CloseHandle(source);
		}
	}
	free(BUF);
	printf("\n");

	return 0;
}
