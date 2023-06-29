         section code

         trap     #0
         ori.w    #$700,sr
         lea      q68rom(pc),a0
         suba.l   a1,a1
         move.w   #96*1024/4-1,d0
copy     move.l   (a0)+,(a1)+
         dbra     d0,copy
         movem.l  0,a0-a1
         move.l   a0,a7
         jmp      (a1)

q68rom   equ      *

         end

