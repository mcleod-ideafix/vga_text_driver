#include <stdio.h>

int main()
{
    FILE *f;
    char bm[32768];
    int i,b,x,y,s;
    unsigned char scan;
    
    f = fopen ("ibm_vga_8x16.raw", "rb");
    fread (bm, 1, 32768, f);
    fclose (f);
    
    f = fopen ("ibm_vga_8x16.bin", "wb");
    for (y=0;y<256;y+=16)
    {
        for (x=0;x<128;x+=8)
        {
            for (s=0;s<16;s++)
            {
                i = (y+s)*128+x;
                scan = 0;
                for (b=0;b<8;b++)
                {
                    scan = scan<<1;
                    if (bm[i+b])
                        scan++;
                }
                fwrite (&scan, 1, 1, f);
            }
        }
    }
    fclose(f);
}
