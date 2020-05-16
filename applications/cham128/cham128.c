#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

/*Cham128 algorithm from: https://tinycrypt.wordpress.com/2018/01/13/cham-block-cipher/ */

/*Function to left rotate n by d bits*/
unsigned int leftRotate(unsigned int n, unsigned int d)
{
	/* In n<<d, last d bits are 0. To put first 3 bits of n at
	  last, do bitwise or of n<<d with n >>(INT_BITS - d) */
	return (n << d) | (n >> (32 - d));
}

void cham128_setkey(uint32_t k[], uint32_t rk[])
{
	int i;
	int KW = 4;


	for (i = 0; i < KW; i++) {
		rk[i] = k[i] ^ leftRotate(k[i], 1) ^ leftRotate(k[i], 8);
		rk[(i + KW) ^ 1] = k[i] ^ leftRotate(k[i], 1) ^ leftRotate(k[i], 11);
	}
}

void cham128_encrypt(uint32_t rk[], uint32_t x[])
{
	int i;
	int R = 80;
	uint32_t x0, x1, x2, x3;
	uint32_t t;

	x0 = x[0]; x1 = x[1];
	x2 = x[2]; x3 = x[3];

	for (i = 0; i < R; i++)
	{
		if ((i & 1) == 0) {
			uint32_t tem = (x0 ^ i) + (leftRotate(x1, 1) ^ rk[i & 7]);
			x0 = leftRotate(tem, 8);
		}
		else {
			uint32_t tem = (x0 ^ i) + (leftRotate(x1, 8) ^ rk[i & 7]);
			x0 = leftRotate(tem, 1);
		}
		uint32_t temp = x0;
		x0 = x1;
		x1 = x2;
		x2 = x3;
		x3 = temp;

	}
	x[0] = x0; x[1] = x1;
	x[2] = x2; x[3] = x3;
}

int main()
{
	
	uint32_t key[4];
	uint32_t data[4];
	/*
	data[0] = 0xfedcba98;
	data[1] = 0x76543210;
	data[2] = 0xfedcba98;
	data[3] = 0x76543210;

	key[0] = 0x08172098;
	key[1] = 0x76543236;
	key[2] = 0xFEDCBA98;
	key[3] = 0x76543225;
	*/
	data[0] = 0x33221100;
	data[1] = 0x77665544;
	data[2] = 0xbbaa9988;
	data[3] = 0xffeeddcc;

	key[0] = 0x03020100;
	key[1] = 0x07060504;
	key[2] = 0x0b0a0908;
	key[3] = 0x0f0e0d0c;

	uint32_t rk[8];

	cham128_setkey(key, rk);

	printf("\nRoundKeys:");
	printf("%x\n", rk[0]);
	printf("%x\n", rk[1]);
	printf("%x\n", rk[2]);
	printf("%x\n", rk[3]);
	printf("%x\n", rk[4]);
	printf("%x\n", rk[5]);
	printf("%x\n", rk[6]);
	printf("%x\n", rk[7]);
	cham128_encrypt(rk, data);

	printf("\nData:\n");
	printf("%x\n", data[0]);
	printf("%x\n", data[1]);
	printf("%x\n", data[2]);
	printf("%x\n", data[3]);


	return 0;
}
