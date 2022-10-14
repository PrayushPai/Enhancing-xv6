
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b4013103          	ld	sp,-1216(sp) # 80008b40 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	b5070713          	addi	a4,a4,-1200 # 80008ba0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	78e78793          	addi	a5,a5,1934 # 800067f0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb8f4f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f0278793          	addi	a5,a5,-254 # 80000fae <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	854080e7          	jalr	-1964(ra) # 8000297e <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	b5650513          	addi	a0,a0,-1194 # 80010ce0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b7a080e7          	jalr	-1158(ra) # 80000d0c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b4648493          	addi	s1,s1,-1210 # 80010ce0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bd690913          	addi	s2,s2,-1066 # 80010d78 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	93c080e7          	jalr	-1732(ra) # 80001afc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	600080e7          	jalr	1536(ra) # 800027c8 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	34a080e7          	jalr	842(ra) # 80002520 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	716080e7          	jalr	1814(ra) # 80002928 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	aba50513          	addi	a0,a0,-1350 # 80010ce0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b92080e7          	jalr	-1134(ra) # 80000dc0 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	aa450513          	addi	a0,a0,-1372 # 80010ce0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b7c080e7          	jalr	-1156(ra) # 80000dc0 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	b0f72323          	sw	a5,-1274(a4) # 80010d78 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a1450513          	addi	a0,a0,-1516 # 80010ce0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a38080e7          	jalr	-1480(ra) # 80000d0c <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	6e2080e7          	jalr	1762(ra) # 800029d4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	9e650513          	addi	a0,a0,-1562 # 80010ce0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	abe080e7          	jalr	-1346(ra) # 80000dc0 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9c270713          	addi	a4,a4,-1598 # 80010ce0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	99878793          	addi	a5,a5,-1640 # 80010ce0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a027a783          	lw	a5,-1534(a5) # 80010d78 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	95670713          	addi	a4,a4,-1706 # 80010ce0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	94648493          	addi	s1,s1,-1722 # 80010ce0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	90a70713          	addi	a4,a4,-1782 # 80010ce0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	98f72a23          	sw	a5,-1644(a4) # 80010d80 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8ce78793          	addi	a5,a5,-1842 # 80010ce0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	94c7a323          	sw	a2,-1722(a5) # 80010d7c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	93a50513          	addi	a0,a0,-1734 # 80010d78 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	13e080e7          	jalr	318(ra) # 80002584 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	88050513          	addi	a0,a0,-1920 # 80010ce0 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	814080e7          	jalr	-2028(ra) # 80000c7c <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00244797          	auipc	a5,0x244
    8000047c:	2a078793          	addi	a5,a5,672 # 80244718 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8407aa23          	sw	zero,-1964(a5) # 80010da0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b9250513          	addi	a0,a0,-1134 # 80008100 <digits+0xc0>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	5ef72023          	sw	a5,1504(a4) # 80008b60 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	7e4dad83          	lw	s11,2020(s11) # 80010da0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	78e50513          	addi	a0,a0,1934 # 80010d88 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	70a080e7          	jalr	1802(ra) # 80000d0c <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	63050513          	addi	a0,a0,1584 # 80010d88 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	660080e7          	jalr	1632(ra) # 80000dc0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	61448493          	addi	s1,s1,1556 # 80010d88 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	4f6080e7          	jalr	1270(ra) # 80000c7c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	5d450513          	addi	a0,a0,1492 # 80010da8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	4a0080e7          	jalr	1184(ra) # 80000c7c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	4c8080e7          	jalr	1224(ra) # 80000cc0 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3607a783          	lw	a5,864(a5) # 80008b60 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	53a080e7          	jalr	1338(ra) # 80000d60 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3307b783          	ld	a5,816(a5) # 80008b68 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	33073703          	ld	a4,816(a4) # 80008b70 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	546a0a13          	addi	s4,s4,1350 # 80010da8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	2fe48493          	addi	s1,s1,766 # 80008b68 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	2fe98993          	addi	s3,s3,766 # 80008b70 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	cf0080e7          	jalr	-784(ra) # 80002584 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	4d850513          	addi	a0,a0,1240 # 80010da8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	434080e7          	jalr	1076(ra) # 80000d0c <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2807a783          	lw	a5,640(a5) # 80008b60 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	28673703          	ld	a4,646(a4) # 80008b70 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2767b783          	ld	a5,630(a5) # 80008b68 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4aa98993          	addi	s3,s3,1194 # 80010da8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	26248493          	addi	s1,s1,610 # 80008b68 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	26290913          	addi	s2,s2,610 # 80008b70 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	c02080e7          	jalr	-1022(ra) # 80002520 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	47448493          	addi	s1,s1,1140 # 80010da8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	22e7b423          	sd	a4,552(a5) # 80008b70 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	466080e7          	jalr	1126(ra) # 80000dc0 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	3ee48493          	addi	s1,s1,1006 # 80010da8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	348080e7          	jalr	840(ra) # 80000d0c <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	3ea080e7          	jalr	1002(ra) # 80000dc0 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <addit>:
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)

// increase the reference count of the page
void addit(uint64 pa)
{ 
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	1000                	addi	s0,sp,32
    800009f2:	84aa                	mv	s1,a0
  //acquire the lock
  acquire(&kmem.lock);
    800009f4:	00010517          	auipc	a0,0x10
    800009f8:	3ec50513          	addi	a0,a0,1004 # 80010de0 <kmem>
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	310080e7          	jalr	784(ra) # 80000d0c <acquire>
  int pn = pa / PGSIZE;
  if(pa>PHYSTOP || refcnt[pn]<1){
    80000a04:	4745                	li	a4,17
    80000a06:	076e                	slli	a4,a4,0x1b
    80000a08:	04976463          	bltu	a4,s1,80000a50 <addit+0x68>
    80000a0c:	00c4d793          	srli	a5,s1,0xc
    80000a10:	2781                	sext.w	a5,a5
    80000a12:	00279693          	slli	a3,a5,0x2
    80000a16:	00010717          	auipc	a4,0x10
    80000a1a:	3ea70713          	addi	a4,a4,1002 # 80010e00 <refcnt>
    80000a1e:	9736                	add	a4,a4,a3
    80000a20:	4318                	lw	a4,0(a4)
    80000a22:	02e05763          	blez	a4,80000a50 <addit+0x68>
    panic("increase ref cnt");
  }
  refcnt[pn]++;
    80000a26:	078a                	slli	a5,a5,0x2
    80000a28:	00010697          	auipc	a3,0x10
    80000a2c:	3d868693          	addi	a3,a3,984 # 80010e00 <refcnt>
    80000a30:	97b6                	add	a5,a5,a3
    80000a32:	2705                	addiw	a4,a4,1
    80000a34:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a36:	00010517          	auipc	a0,0x10
    80000a3a:	3aa50513          	addi	a0,a0,938 # 80010de0 <kmem>
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	382080e7          	jalr	898(ra) # 80000dc0 <release>
}
    80000a46:	60e2                	ld	ra,24(sp)
    80000a48:	6442                	ld	s0,16(sp)
    80000a4a:	64a2                	ld	s1,8(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("increase ref cnt");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae8080e7          	jalr	-1304(ra) # 80000540 <panic>

0000000080000a60 <kfree>:

void kfree(void *pa)
{
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	e04a                	sd	s2,0(sp)
    80000a6a:	1000                	addi	s0,sp,32
  struct run *r;
  r = (struct run *)pa;
  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a6c:	03451793          	slli	a5,a0,0x34
    80000a70:	ebbd                	bnez	a5,80000ae6 <kfree+0x86>
    80000a72:	84aa                	mv	s1,a0
    80000a74:	00245797          	auipc	a5,0x245
    80000a78:	e3c78793          	addi	a5,a5,-452 # 802458b0 <end>
    80000a7c:	06f56563          	bltu	a0,a5,80000ae6 <kfree+0x86>
    80000a80:	47c5                	li	a5,17
    80000a82:	07ee                	slli	a5,a5,0x1b
    80000a84:	06f57163          	bgeu	a0,a5,80000ae6 <kfree+0x86>
    panic("kfree");                                                             // free the page decrease the refcnt of the pa 
  acquire(&kmem.lock);                                                          // acquire the lock and get the current cnt for the current fucntion
    80000a88:	00010517          	auipc	a0,0x10
    80000a8c:	35850513          	addi	a0,a0,856 # 80010de0 <kmem>
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	27c080e7          	jalr	636(ra) # 80000d0c <acquire>
  int pn = (uint64)r / PGSIZE;
    80000a98:	00c4d793          	srli	a5,s1,0xc
    80000a9c:	2781                	sext.w	a5,a5
  if (refcnt[pn] < 1)
    80000a9e:	00279693          	slli	a3,a5,0x2
    80000aa2:	00010717          	auipc	a4,0x10
    80000aa6:	35e70713          	addi	a4,a4,862 # 80010e00 <refcnt>
    80000aaa:	9736                	add	a4,a4,a3
    80000aac:	4318                	lw	a4,0(a4)
    80000aae:	04e05463          	blez	a4,80000af6 <kfree+0x96>
    panic("kfree panic");
  refcnt[pn] -= 1;
    80000ab2:	377d                	addiw	a4,a4,-1
    80000ab4:	0007091b          	sext.w	s2,a4
    80000ab8:	078a                	slli	a5,a5,0x2
    80000aba:	00010697          	auipc	a3,0x10
    80000abe:	34668693          	addi	a3,a3,838 # 80010e00 <refcnt>
    80000ac2:	97b6                	add	a5,a5,a3
    80000ac4:	c398                	sw	a4,0(a5)
  int tmp = refcnt[pn];
  release(&kmem.lock);
    80000ac6:	00010517          	auipc	a0,0x10
    80000aca:	31a50513          	addi	a0,a0,794 # 80010de0 <kmem>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	2f2080e7          	jalr	754(ra) # 80000dc0 <release>

  if (tmp >0)
    80000ad6:	03205863          	blez	s2,80000b06 <kfree+0xa6>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000ada:	60e2                	ld	ra,24(sp)
    80000adc:	6442                	ld	s0,16(sp)
    80000ade:	64a2                	ld	s1,8(sp)
    80000ae0:	6902                	ld	s2,0(sp)
    80000ae2:	6105                	addi	sp,sp,32
    80000ae4:	8082                	ret
    panic("kfree");                                                             // free the page decrease the refcnt of the pa 
    80000ae6:	00007517          	auipc	a0,0x7
    80000aea:	59250513          	addi	a0,a0,1426 # 80008078 <digits+0x38>
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	a52080e7          	jalr	-1454(ra) # 80000540 <panic>
    panic("kfree panic");
    80000af6:	00007517          	auipc	a0,0x7
    80000afa:	58a50513          	addi	a0,a0,1418 # 80008080 <digits+0x40>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	a42080e7          	jalr	-1470(ra) # 80000540 <panic>
  memset(pa, 1, PGSIZE);
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4585                	li	a1,1
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	2fc080e7          	jalr	764(ra) # 80000e08 <memset>
  acquire(&kmem.lock);
    80000b14:	00010917          	auipc	s2,0x10
    80000b18:	2cc90913          	addi	s2,s2,716 # 80010de0 <kmem>
    80000b1c:	854a                	mv	a0,s2
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	1ee080e7          	jalr	494(ra) # 80000d0c <acquire>
  r->next = kmem.freelist;
    80000b26:	01893783          	ld	a5,24(s2)
    80000b2a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b2c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b30:	854a                	mv	a0,s2
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	28e080e7          	jalr	654(ra) # 80000dc0 <release>
    80000b3a:	b745                	j	80000ada <kfree+0x7a>

0000000080000b3c <freerange>:
{
    80000b3c:	7139                	addi	sp,sp,-64
    80000b3e:	fc06                	sd	ra,56(sp)
    80000b40:	f822                	sd	s0,48(sp)
    80000b42:	f426                	sd	s1,40(sp)
    80000b44:	f04a                	sd	s2,32(sp)
    80000b46:	ec4e                	sd	s3,24(sp)
    80000b48:	e852                	sd	s4,16(sp)
    80000b4a:	e456                	sd	s5,8(sp)
    80000b4c:	e05a                	sd	s6,0(sp)
    80000b4e:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000b50:	6785                	lui	a5,0x1
    80000b52:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b56:	953a                	add	a0,a0,a4
    80000b58:	777d                	lui	a4,0xfffff
    80000b5a:	00e574b3          	and	s1,a0,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b5e:	97a6                	add	a5,a5,s1
    80000b60:	02f5ea63          	bltu	a1,a5,80000b94 <freerange+0x58>
    80000b64:	892e                	mv	s2,a1
    refcnt[(uint64)p / PGSIZE] = 1;
    80000b66:	00010b17          	auipc	s6,0x10
    80000b6a:	29ab0b13          	addi	s6,s6,666 # 80010e00 <refcnt>
    80000b6e:	4a85                	li	s5,1
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b70:	6a05                	lui	s4,0x1
    80000b72:	6989                	lui	s3,0x2
    refcnt[(uint64)p / PGSIZE] = 1;
    80000b74:	00c4d793          	srli	a5,s1,0xc
    80000b78:	078a                	slli	a5,a5,0x2
    80000b7a:	97da                	add	a5,a5,s6
    80000b7c:	0157a023          	sw	s5,0(a5)
    kfree(p);                               // we call kfree which decreases the refcnt for every page
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	ede080e7          	jalr	-290(ra) # 80000a60 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b8a:	87a6                	mv	a5,s1
    80000b8c:	94d2                	add	s1,s1,s4
    80000b8e:	97ce                	add	a5,a5,s3
    80000b90:	fef972e3          	bgeu	s2,a5,80000b74 <freerange+0x38>
}
    80000b94:	70e2                	ld	ra,56(sp)
    80000b96:	7442                	ld	s0,48(sp)
    80000b98:	74a2                	ld	s1,40(sp)
    80000b9a:	7902                	ld	s2,32(sp)
    80000b9c:	69e2                	ld	s3,24(sp)
    80000b9e:	6a42                	ld	s4,16(sp)
    80000ba0:	6aa2                	ld	s5,8(sp)
    80000ba2:	6b02                	ld	s6,0(sp)
    80000ba4:	6121                	addi	sp,sp,64
    80000ba6:	8082                	ret

0000000080000ba8 <kinit>:
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e406                	sd	ra,8(sp)
    80000bac:	e022                	sd	s0,0(sp)
    80000bae:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bb0:	00007597          	auipc	a1,0x7
    80000bb4:	4e058593          	addi	a1,a1,1248 # 80008090 <digits+0x50>
    80000bb8:	00010517          	auipc	a0,0x10
    80000bbc:	22850513          	addi	a0,a0,552 # 80010de0 <kmem>
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	0bc080e7          	jalr	188(ra) # 80000c7c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bc8:	45c5                	li	a1,17
    80000bca:	05ee                	slli	a1,a1,0x1b
    80000bcc:	00245517          	auipc	a0,0x245
    80000bd0:	ce450513          	addi	a0,a0,-796 # 802458b0 <end>
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	f68080e7          	jalr	-152(ra) # 80000b3c <freerange>
}
    80000bdc:	60a2                	ld	ra,8(sp)
    80000bde:	6402                	ld	s0,0(sp)
    80000be0:	0141                	addi	sp,sp,16
    80000be2:	8082                	ret

0000000080000be4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
// This function will allocate a pa and if ref cnt of pa is invalid, then send an assert
void *kalloc(void)
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bee:	00010497          	auipc	s1,0x10
    80000bf2:	1f248493          	addi	s1,s1,498 # 80010de0 <kmem>
    80000bf6:	8526                	mv	a0,s1
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	114080e7          	jalr	276(ra) # 80000d0c <acquire>
  r = kmem.freelist;
    80000c00:	6c84                	ld	s1,24(s1)
  if (r)
    80000c02:	c4a5                	beqz	s1,80000c6a <kalloc+0x86>
  {
    int pn = (uint64)r / PGSIZE;
    80000c04:	00c4d793          	srli	a5,s1,0xc
    80000c08:	2781                	sext.w	a5,a5
    if(refcnt[pn]!=0){
    80000c0a:	00279693          	slli	a3,a5,0x2
    80000c0e:	00010717          	auipc	a4,0x10
    80000c12:	1f270713          	addi	a4,a4,498 # 80010e00 <refcnt>
    80000c16:	9736                	add	a4,a4,a3
    80000c18:	4318                	lw	a4,0(a4)
    80000c1a:	e321                	bnez	a4,80000c5a <kalloc+0x76>
      panic("refcnt kalloc");
    }
    refcnt[pn] = 1;
    80000c1c:	078a                	slli	a5,a5,0x2
    80000c1e:	00010717          	auipc	a4,0x10
    80000c22:	1e270713          	addi	a4,a4,482 # 80010e00 <refcnt>
    80000c26:	97ba                	add	a5,a5,a4
    80000c28:	4705                	li	a4,1
    80000c2a:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c2c:	609c                	ld	a5,0(s1)
    80000c2e:	00010517          	auipc	a0,0x10
    80000c32:	1b250513          	addi	a0,a0,434 # 80010de0 <kmem>
    80000c36:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	188080e7          	jalr	392(ra) # 80000dc0 <release>

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000c40:	6605                	lui	a2,0x1
    80000c42:	4595                	li	a1,5
    80000c44:	8526                	mv	a0,s1
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	1c2080e7          	jalr	450(ra) # 80000e08 <memset>
  return (void *)r;
}
    80000c4e:	8526                	mv	a0,s1
    80000c50:	60e2                	ld	ra,24(sp)
    80000c52:	6442                	ld	s0,16(sp)
    80000c54:	64a2                	ld	s1,8(sp)
    80000c56:	6105                	addi	sp,sp,32
    80000c58:	8082                	ret
      panic("refcnt kalloc");
    80000c5a:	00007517          	auipc	a0,0x7
    80000c5e:	43e50513          	addi	a0,a0,1086 # 80008098 <digits+0x58>
    80000c62:	00000097          	auipc	ra,0x0
    80000c66:	8de080e7          	jalr	-1826(ra) # 80000540 <panic>
  release(&kmem.lock);
    80000c6a:	00010517          	auipc	a0,0x10
    80000c6e:	17650513          	addi	a0,a0,374 # 80010de0 <kmem>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	14e080e7          	jalr	334(ra) # 80000dc0 <release>
  if (r)
    80000c7a:	bfd1                	j	80000c4e <kalloc+0x6a>

0000000080000c7c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c7c:	1141                	addi	sp,sp,-16
    80000c7e:	e422                	sd	s0,8(sp)
    80000c80:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c82:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c84:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c88:	00053823          	sd	zero,16(a0)
}
    80000c8c:	6422                	ld	s0,8(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret

0000000080000c92 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c92:	411c                	lw	a5,0(a0)
    80000c94:	e399                	bnez	a5,80000c9a <holding+0x8>
    80000c96:	4501                	li	a0,0
  return r;
}
    80000c98:	8082                	ret
{
    80000c9a:	1101                	addi	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca4:	6904                	ld	s1,16(a0)
    80000ca6:	00001097          	auipc	ra,0x1
    80000caa:	e3a080e7          	jalr	-454(ra) # 80001ae0 <mycpu>
    80000cae:	40a48533          	sub	a0,s1,a0
    80000cb2:	00153513          	seqz	a0,a0
}
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6105                	addi	sp,sp,32
    80000cbe:	8082                	ret

0000000080000cc0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc0:	1101                	addi	sp,sp,-32
    80000cc2:	ec06                	sd	ra,24(sp)
    80000cc4:	e822                	sd	s0,16(sp)
    80000cc6:	e426                	sd	s1,8(sp)
    80000cc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cca:	100024f3          	csrr	s1,sstatus
    80000cce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cd8:	00001097          	auipc	ra,0x1
    80000cdc:	e08080e7          	jalr	-504(ra) # 80001ae0 <mycpu>
    80000ce0:	5d3c                	lw	a5,120(a0)
    80000ce2:	cf89                	beqz	a5,80000cfc <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce4:	00001097          	auipc	ra,0x1
    80000ce8:	dfc080e7          	jalr	-516(ra) # 80001ae0 <mycpu>
    80000cec:	5d3c                	lw	a5,120(a0)
    80000cee:	2785                	addiw	a5,a5,1
    80000cf0:	dd3c                	sw	a5,120(a0)
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    mycpu()->intena = old;
    80000cfc:	00001097          	auipc	ra,0x1
    80000d00:	de4080e7          	jalr	-540(ra) # 80001ae0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d04:	8085                	srli	s1,s1,0x1
    80000d06:	8885                	andi	s1,s1,1
    80000d08:	dd64                	sw	s1,124(a0)
    80000d0a:	bfe9                	j	80000ce4 <push_off+0x24>

0000000080000d0c <acquire>:
{
    80000d0c:	1101                	addi	sp,sp,-32
    80000d0e:	ec06                	sd	ra,24(sp)
    80000d10:	e822                	sd	s0,16(sp)
    80000d12:	e426                	sd	s1,8(sp)
    80000d14:	1000                	addi	s0,sp,32
    80000d16:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	fa8080e7          	jalr	-88(ra) # 80000cc0 <push_off>
  if(holding(lk))
    80000d20:	8526                	mv	a0,s1
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f70080e7          	jalr	-144(ra) # 80000c92 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2a:	4705                	li	a4,1
  if(holding(lk))
    80000d2c:	e115                	bnez	a0,80000d50 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2e:	87ba                	mv	a5,a4
    80000d30:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d34:	2781                	sext.w	a5,a5
    80000d36:	ffe5                	bnez	a5,80000d2e <acquire+0x22>
  __sync_synchronize();
    80000d38:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	da4080e7          	jalr	-604(ra) # 80001ae0 <mycpu>
    80000d44:	e888                	sd	a0,16(s1)
}
    80000d46:	60e2                	ld	ra,24(sp)
    80000d48:	6442                	ld	s0,16(sp)
    80000d4a:	64a2                	ld	s1,8(sp)
    80000d4c:	6105                	addi	sp,sp,32
    80000d4e:	8082                	ret
    panic("acquire");
    80000d50:	00007517          	auipc	a0,0x7
    80000d54:	35850513          	addi	a0,a0,856 # 800080a8 <digits+0x68>
    80000d58:	fffff097          	auipc	ra,0xfffff
    80000d5c:	7e8080e7          	jalr	2024(ra) # 80000540 <panic>

0000000080000d60 <pop_off>:

void
pop_off(void)
{
    80000d60:	1141                	addi	sp,sp,-16
    80000d62:	e406                	sd	ra,8(sp)
    80000d64:	e022                	sd	s0,0(sp)
    80000d66:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d68:	00001097          	auipc	ra,0x1
    80000d6c:	d78080e7          	jalr	-648(ra) # 80001ae0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d74:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d76:	e78d                	bnez	a5,80000da0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d78:	5d3c                	lw	a5,120(a0)
    80000d7a:	02f05b63          	blez	a5,80000db0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d7e:	37fd                	addiw	a5,a5,-1
    80000d80:	0007871b          	sext.w	a4,a5
    80000d84:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d86:	eb09                	bnez	a4,80000d98 <pop_off+0x38>
    80000d88:	5d7c                	lw	a5,124(a0)
    80000d8a:	c799                	beqz	a5,80000d98 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d94:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d98:	60a2                	ld	ra,8(sp)
    80000d9a:	6402                	ld	s0,0(sp)
    80000d9c:	0141                	addi	sp,sp,16
    80000d9e:	8082                	ret
    panic("pop_off - interruptible");
    80000da0:	00007517          	auipc	a0,0x7
    80000da4:	31050513          	addi	a0,a0,784 # 800080b0 <digits+0x70>
    80000da8:	fffff097          	auipc	ra,0xfffff
    80000dac:	798080e7          	jalr	1944(ra) # 80000540 <panic>
    panic("pop_off");
    80000db0:	00007517          	auipc	a0,0x7
    80000db4:	31850513          	addi	a0,a0,792 # 800080c8 <digits+0x88>
    80000db8:	fffff097          	auipc	ra,0xfffff
    80000dbc:	788080e7          	jalr	1928(ra) # 80000540 <panic>

0000000080000dc0 <release>:
{
    80000dc0:	1101                	addi	sp,sp,-32
    80000dc2:	ec06                	sd	ra,24(sp)
    80000dc4:	e822                	sd	s0,16(sp)
    80000dc6:	e426                	sd	s1,8(sp)
    80000dc8:	1000                	addi	s0,sp,32
    80000dca:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	ec6080e7          	jalr	-314(ra) # 80000c92 <holding>
    80000dd4:	c115                	beqz	a0,80000df8 <release+0x38>
  lk->cpu = 0;
    80000dd6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dda:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dde:	0f50000f          	fence	iorw,ow
    80000de2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	f7a080e7          	jalr	-134(ra) # 80000d60 <pop_off>
}
    80000dee:	60e2                	ld	ra,24(sp)
    80000df0:	6442                	ld	s0,16(sp)
    80000df2:	64a2                	ld	s1,8(sp)
    80000df4:	6105                	addi	sp,sp,32
    80000df6:	8082                	ret
    panic("release");
    80000df8:	00007517          	auipc	a0,0x7
    80000dfc:	2d850513          	addi	a0,a0,728 # 800080d0 <digits+0x90>
    80000e00:	fffff097          	auipc	ra,0xfffff
    80000e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>

0000000080000e08 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e08:	1141                	addi	sp,sp,-16
    80000e0a:	e422                	sd	s0,8(sp)
    80000e0c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e0e:	ca19                	beqz	a2,80000e24 <memset+0x1c>
    80000e10:	87aa                	mv	a5,a0
    80000e12:	1602                	slli	a2,a2,0x20
    80000e14:	9201                	srli	a2,a2,0x20
    80000e16:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e1a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e1e:	0785                	addi	a5,a5,1
    80000e20:	fee79de3          	bne	a5,a4,80000e1a <memset+0x12>
  }
  return dst;
}
    80000e24:	6422                	ld	s0,8(sp)
    80000e26:	0141                	addi	sp,sp,16
    80000e28:	8082                	ret

0000000080000e2a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e30:	ca05                	beqz	a2,80000e60 <memcmp+0x36>
    80000e32:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	0685                	addi	a3,a3,1
    80000e3c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e3e:	00054783          	lbu	a5,0(a0)
    80000e42:	0005c703          	lbu	a4,0(a1)
    80000e46:	00e79863          	bne	a5,a4,80000e56 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e4e:	fed518e3          	bne	a0,a3,80000e3e <memcmp+0x14>
  }

  return 0;
    80000e52:	4501                	li	a0,0
    80000e54:	a019                	j	80000e5a <memcmp+0x30>
      return *s1 - *s2;
    80000e56:	40e7853b          	subw	a0,a5,a4
}
    80000e5a:	6422                	ld	s0,8(sp)
    80000e5c:	0141                	addi	sp,sp,16
    80000e5e:	8082                	ret
  return 0;
    80000e60:	4501                	li	a0,0
    80000e62:	bfe5                	j	80000e5a <memcmp+0x30>

0000000080000e64 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e6a:	c205                	beqz	a2,80000e8a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e6c:	02a5e263          	bltu	a1,a0,80000e90 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e70:	1602                	slli	a2,a2,0x20
    80000e72:	9201                	srli	a2,a2,0x20
    80000e74:	00c587b3          	add	a5,a1,a2
{
    80000e78:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e7a:	0585                	addi	a1,a1,1
    80000e7c:	0705                	addi	a4,a4,1
    80000e7e:	fff5c683          	lbu	a3,-1(a1)
    80000e82:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e86:	fef59ae3          	bne	a1,a5,80000e7a <memmove+0x16>

  return dst;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  if(s < d && s + n > d){
    80000e90:	02061693          	slli	a3,a2,0x20
    80000e94:	9281                	srli	a3,a3,0x20
    80000e96:	00d58733          	add	a4,a1,a3
    80000e9a:	fce57be3          	bgeu	a0,a4,80000e70 <memmove+0xc>
    d += n;
    80000e9e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ea0:	fff6079b          	addiw	a5,a2,-1
    80000ea4:	1782                	slli	a5,a5,0x20
    80000ea6:	9381                	srli	a5,a5,0x20
    80000ea8:	fff7c793          	not	a5,a5
    80000eac:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000eae:	177d                	addi	a4,a4,-1
    80000eb0:	16fd                	addi	a3,a3,-1
    80000eb2:	00074603          	lbu	a2,0(a4)
    80000eb6:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000eba:	fee79ae3          	bne	a5,a4,80000eae <memmove+0x4a>
    80000ebe:	b7f1                	j	80000e8a <memmove+0x26>

0000000080000ec0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ec0:	1141                	addi	sp,sp,-16
    80000ec2:	e406                	sd	ra,8(sp)
    80000ec4:	e022                	sd	s0,0(sp)
    80000ec6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	f9c080e7          	jalr	-100(ra) # 80000e64 <memmove>
}
    80000ed0:	60a2                	ld	ra,8(sp)
    80000ed2:	6402                	ld	s0,0(sp)
    80000ed4:	0141                	addi	sp,sp,16
    80000ed6:	8082                	ret

0000000080000ed8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ed8:	1141                	addi	sp,sp,-16
    80000eda:	e422                	sd	s0,8(sp)
    80000edc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ede:	ce11                	beqz	a2,80000efa <strncmp+0x22>
    80000ee0:	00054783          	lbu	a5,0(a0)
    80000ee4:	cf89                	beqz	a5,80000efe <strncmp+0x26>
    80000ee6:	0005c703          	lbu	a4,0(a1)
    80000eea:	00f71a63          	bne	a4,a5,80000efe <strncmp+0x26>
    n--, p++, q++;
    80000eee:	367d                	addiw	a2,a2,-1
    80000ef0:	0505                	addi	a0,a0,1
    80000ef2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ef4:	f675                	bnez	a2,80000ee0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ef6:	4501                	li	a0,0
    80000ef8:	a809                	j	80000f0a <strncmp+0x32>
    80000efa:	4501                	li	a0,0
    80000efc:	a039                	j	80000f0a <strncmp+0x32>
  if(n == 0)
    80000efe:	ca09                	beqz	a2,80000f10 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f00:	00054503          	lbu	a0,0(a0)
    80000f04:	0005c783          	lbu	a5,0(a1)
    80000f08:	9d1d                	subw	a0,a0,a5
}
    80000f0a:	6422                	ld	s0,8(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret
    return 0;
    80000f10:	4501                	li	a0,0
    80000f12:	bfe5                	j	80000f0a <strncmp+0x32>

0000000080000f14 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f14:	1141                	addi	sp,sp,-16
    80000f16:	e422                	sd	s0,8(sp)
    80000f18:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f1a:	872a                	mv	a4,a0
    80000f1c:	8832                	mv	a6,a2
    80000f1e:	367d                	addiw	a2,a2,-1
    80000f20:	01005963          	blez	a6,80000f32 <strncpy+0x1e>
    80000f24:	0705                	addi	a4,a4,1
    80000f26:	0005c783          	lbu	a5,0(a1)
    80000f2a:	fef70fa3          	sb	a5,-1(a4)
    80000f2e:	0585                	addi	a1,a1,1
    80000f30:	f7f5                	bnez	a5,80000f1c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f32:	86ba                	mv	a3,a4
    80000f34:	00c05c63          	blez	a2,80000f4c <strncpy+0x38>
    *s++ = 0;
    80000f38:	0685                	addi	a3,a3,1
    80000f3a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f3e:	40d707bb          	subw	a5,a4,a3
    80000f42:	37fd                	addiw	a5,a5,-1
    80000f44:	010787bb          	addw	a5,a5,a6
    80000f48:	fef048e3          	bgtz	a5,80000f38 <strncpy+0x24>
  return os;
}
    80000f4c:	6422                	ld	s0,8(sp)
    80000f4e:	0141                	addi	sp,sp,16
    80000f50:	8082                	ret

0000000080000f52 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f52:	1141                	addi	sp,sp,-16
    80000f54:	e422                	sd	s0,8(sp)
    80000f56:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f58:	02c05363          	blez	a2,80000f7e <safestrcpy+0x2c>
    80000f5c:	fff6069b          	addiw	a3,a2,-1
    80000f60:	1682                	slli	a3,a3,0x20
    80000f62:	9281                	srli	a3,a3,0x20
    80000f64:	96ae                	add	a3,a3,a1
    80000f66:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f68:	00d58963          	beq	a1,a3,80000f7a <safestrcpy+0x28>
    80000f6c:	0585                	addi	a1,a1,1
    80000f6e:	0785                	addi	a5,a5,1
    80000f70:	fff5c703          	lbu	a4,-1(a1)
    80000f74:	fee78fa3          	sb	a4,-1(a5)
    80000f78:	fb65                	bnez	a4,80000f68 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f7a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f7e:	6422                	ld	s0,8(sp)
    80000f80:	0141                	addi	sp,sp,16
    80000f82:	8082                	ret

0000000080000f84 <strlen>:

int
strlen(const char *s)
{
    80000f84:	1141                	addi	sp,sp,-16
    80000f86:	e422                	sd	s0,8(sp)
    80000f88:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f8a:	00054783          	lbu	a5,0(a0)
    80000f8e:	cf91                	beqz	a5,80000faa <strlen+0x26>
    80000f90:	0505                	addi	a0,a0,1
    80000f92:	87aa                	mv	a5,a0
    80000f94:	4685                	li	a3,1
    80000f96:	9e89                	subw	a3,a3,a0
    80000f98:	00f6853b          	addw	a0,a3,a5
    80000f9c:	0785                	addi	a5,a5,1
    80000f9e:	fff7c703          	lbu	a4,-1(a5)
    80000fa2:	fb7d                	bnez	a4,80000f98 <strlen+0x14>
    ;
  return n;
}
    80000fa4:	6422                	ld	s0,8(sp)
    80000fa6:	0141                	addi	sp,sp,16
    80000fa8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000faa:	4501                	li	a0,0
    80000fac:	bfe5                	j	80000fa4 <strlen+0x20>

0000000080000fae <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e406                	sd	ra,8(sp)
    80000fb2:	e022                	sd	s0,0(sp)
    80000fb4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fb6:	00001097          	auipc	ra,0x1
    80000fba:	b1a080e7          	jalr	-1254(ra) # 80001ad0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	bba70713          	addi	a4,a4,-1094 # 80008b78 <started>
  if(cpuid() == 0){
    80000fc6:	c139                	beqz	a0,8000100c <main+0x5e>
    while(started == 0)
    80000fc8:	431c                	lw	a5,0(a4)
    80000fca:	2781                	sext.w	a5,a5
    80000fcc:	dff5                	beqz	a5,80000fc8 <main+0x1a>
      ;
    __sync_synchronize();
    80000fce:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	afe080e7          	jalr	-1282(ra) # 80001ad0 <cpuid>
    80000fda:	85aa                	mv	a1,a0
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	11450513          	addi	a0,a0,276 # 800080f0 <digits+0xb0>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	5a6080e7          	jalr	1446(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000fec:	00000097          	auipc	ra,0x0
    80000ff0:	0d8080e7          	jalr	216(ra) # 800010c4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ff4:	00002097          	auipc	ra,0x2
    80000ff8:	fb2080e7          	jalr	-78(ra) # 80002fa6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ffc:	00006097          	auipc	ra,0x6
    80001000:	834080e7          	jalr	-1996(ra) # 80006830 <plicinithart>
  }

  scheduler();        
    80001004:	00001097          	auipc	ra,0x1
    80001008:	182080e7          	jalr	386(ra) # 80002186 <scheduler>
    consoleinit();
    8000100c:	fffff097          	auipc	ra,0xfffff
    80001010:	444080e7          	jalr	1092(ra) # 80000450 <consoleinit>
    printfinit();
    80001014:	fffff097          	auipc	ra,0xfffff
    80001018:	756080e7          	jalr	1878(ra) # 8000076a <printfinit>
    printf("\n");
    8000101c:	00007517          	auipc	a0,0x7
    80001020:	0e450513          	addi	a0,a0,228 # 80008100 <digits+0xc0>
    80001024:	fffff097          	auipc	ra,0xfffff
    80001028:	566080e7          	jalr	1382(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	0ac50513          	addi	a0,a0,172 # 800080d8 <digits+0x98>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	556080e7          	jalr	1366(ra) # 8000058a <printf>
    printf("\n");
    8000103c:	00007517          	auipc	a0,0x7
    80001040:	0c450513          	addi	a0,a0,196 # 80008100 <digits+0xc0>
    80001044:	fffff097          	auipc	ra,0xfffff
    80001048:	546080e7          	jalr	1350(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    8000104c:	00000097          	auipc	ra,0x0
    80001050:	b5c080e7          	jalr	-1188(ra) # 80000ba8 <kinit>
    kvminit();       // create kernel page table
    80001054:	00000097          	auipc	ra,0x0
    80001058:	326080e7          	jalr	806(ra) # 8000137a <kvminit>
    kvminithart();   // turn on paging
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	068080e7          	jalr	104(ra) # 800010c4 <kvminithart>
    procinit();      // process table
    80001064:	00001097          	auipc	ra,0x1
    80001068:	9b8080e7          	jalr	-1608(ra) # 80001a1c <procinit>
    trapinit();      // trap vectors
    8000106c:	00002097          	auipc	ra,0x2
    80001070:	f12080e7          	jalr	-238(ra) # 80002f7e <trapinit>
    trapinithart();  // install kernel trap vector
    80001074:	00002097          	auipc	ra,0x2
    80001078:	f32080e7          	jalr	-206(ra) # 80002fa6 <trapinithart>
    plicinit();      // set up interrupt controller
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	79e080e7          	jalr	1950(ra) # 8000681a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001084:	00005097          	auipc	ra,0x5
    80001088:	7ac080e7          	jalr	1964(ra) # 80006830 <plicinithart>
    binit();         // buffer cache
    8000108c:	00003097          	auipc	ra,0x3
    80001090:	944080e7          	jalr	-1724(ra) # 800039d0 <binit>
    iinit();         // inode table
    80001094:	00003097          	auipc	ra,0x3
    80001098:	fe4080e7          	jalr	-28(ra) # 80004078 <iinit>
    fileinit();      // file table
    8000109c:	00004097          	auipc	ra,0x4
    800010a0:	f8a080e7          	jalr	-118(ra) # 80005026 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a4:	00006097          	auipc	ra,0x6
    800010a8:	894080e7          	jalr	-1900(ra) # 80006938 <virtio_disk_init>
    userinit();      // first user process
    800010ac:	00001097          	auipc	ra,0x1
    800010b0:	e1c080e7          	jalr	-484(ra) # 80001ec8 <userinit>
    __sync_synchronize();
    800010b4:	0ff0000f          	fence
    started = 1;
    800010b8:	4785                	li	a5,1
    800010ba:	00008717          	auipc	a4,0x8
    800010be:	aaf72f23          	sw	a5,-1346(a4) # 80008b78 <started>
    800010c2:	b789                	j	80001004 <main+0x56>

00000000800010c4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010c4:	1141                	addi	sp,sp,-16
    800010c6:	e422                	sd	s0,8(sp)
    800010c8:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ca:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010ce:	00008797          	auipc	a5,0x8
    800010d2:	ab27b783          	ld	a5,-1358(a5) # 80008b80 <kernel_pagetable>
    800010d6:	83b1                	srli	a5,a5,0xc
    800010d8:	577d                	li	a4,-1
    800010da:	177e                	slli	a4,a4,0x3f
    800010dc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010de:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010e2:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010e6:	6422                	ld	s0,8(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret

00000000800010ec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010ec:	7139                	addi	sp,sp,-64
    800010ee:	fc06                	sd	ra,56(sp)
    800010f0:	f822                	sd	s0,48(sp)
    800010f2:	f426                	sd	s1,40(sp)
    800010f4:	f04a                	sd	s2,32(sp)
    800010f6:	ec4e                	sd	s3,24(sp)
    800010f8:	e852                	sd	s4,16(sp)
    800010fa:	e456                	sd	s5,8(sp)
    800010fc:	e05a                	sd	s6,0(sp)
    800010fe:	0080                	addi	s0,sp,64
    80001100:	84aa                	mv	s1,a0
    80001102:	89ae                	mv	s3,a1
    80001104:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001106:	57fd                	li	a5,-1
    80001108:	83e9                	srli	a5,a5,0x1a
    8000110a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000110c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000110e:	04b7f263          	bgeu	a5,a1,80001152 <walk+0x66>
    panic("walk");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	ff650513          	addi	a0,a0,-10 # 80008108 <digits+0xc8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001122:	060a8663          	beqz	s5,8000118e <walk+0xa2>
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	abe080e7          	jalr	-1346(ra) # 80000be4 <kalloc>
    8000112e:	84aa                	mv	s1,a0
    80001130:	c529                	beqz	a0,8000117a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001132:	6605                	lui	a2,0x1
    80001134:	4581                	li	a1,0
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	cd2080e7          	jalr	-814(ra) # 80000e08 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000113e:	00c4d793          	srli	a5,s1,0xc
    80001142:	07aa                	slli	a5,a5,0xa
    80001144:	0017e793          	ori	a5,a5,1
    80001148:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000114c:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    8000114e:	036a0063          	beq	s4,s6,8000116e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001152:	0149d933          	srl	s2,s3,s4
    80001156:	1ff97913          	andi	s2,s2,511
    8000115a:	090e                	slli	s2,s2,0x3
    8000115c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000115e:	00093483          	ld	s1,0(s2)
    80001162:	0014f793          	andi	a5,s1,1
    80001166:	dfd5                	beqz	a5,80001122 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001168:	80a9                	srli	s1,s1,0xa
    8000116a:	04b2                	slli	s1,s1,0xc
    8000116c:	b7c5                	j	8000114c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000116e:	00c9d513          	srli	a0,s3,0xc
    80001172:	1ff57513          	andi	a0,a0,511
    80001176:	050e                	slli	a0,a0,0x3
    80001178:	9526                	add	a0,a0,s1
}
    8000117a:	70e2                	ld	ra,56(sp)
    8000117c:	7442                	ld	s0,48(sp)
    8000117e:	74a2                	ld	s1,40(sp)
    80001180:	7902                	ld	s2,32(sp)
    80001182:	69e2                	ld	s3,24(sp)
    80001184:	6a42                	ld	s4,16(sp)
    80001186:	6aa2                	ld	s5,8(sp)
    80001188:	6b02                	ld	s6,0(sp)
    8000118a:	6121                	addi	sp,sp,64
    8000118c:	8082                	ret
        return 0;
    8000118e:	4501                	li	a0,0
    80001190:	b7ed                	j	8000117a <walk+0x8e>

0000000080001192 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001192:	57fd                	li	a5,-1
    80001194:	83e9                	srli	a5,a5,0x1a
    80001196:	00b7f463          	bgeu	a5,a1,8000119e <walkaddr+0xc>
    return 0;
    8000119a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000119c:	8082                	ret
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e406                	sd	ra,8(sp)
    800011a2:	e022                	sd	s0,0(sp)
    800011a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a6:	4601                	li	a2,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	f44080e7          	jalr	-188(ra) # 800010ec <walk>
  if(pte == 0)
    800011b0:	c105                	beqz	a0,800011d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011b4:	0117f693          	andi	a3,a5,17
    800011b8:	4745                	li	a4,17
    return 0;
    800011ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011bc:	00e68663          	beq	a3,a4,800011c8 <walkaddr+0x36>
}
    800011c0:	60a2                	ld	ra,8(sp)
    800011c2:	6402                	ld	s0,0(sp)
    800011c4:	0141                	addi	sp,sp,16
    800011c6:	8082                	ret
  pa = PTE2PA(*pte);
    800011c8:	83a9                	srli	a5,a5,0xa
    800011ca:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011ce:	bfcd                	j	800011c0 <walkaddr+0x2e>
    return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7fd                	j	800011c0 <walkaddr+0x2e>

00000000800011d4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d4:	715d                	addi	sp,sp,-80
    800011d6:	e486                	sd	ra,72(sp)
    800011d8:	e0a2                	sd	s0,64(sp)
    800011da:	fc26                	sd	s1,56(sp)
    800011dc:	f84a                	sd	s2,48(sp)
    800011de:	f44e                	sd	s3,40(sp)
    800011e0:	f052                	sd	s4,32(sp)
    800011e2:	ec56                	sd	s5,24(sp)
    800011e4:	e85a                	sd	s6,16(sp)
    800011e6:	e45e                	sd	s7,8(sp)
    800011e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011ea:	c639                	beqz	a2,80001238 <mappages+0x64>
    800011ec:	8aaa                	mv	s5,a0
    800011ee:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011f0:	777d                	lui	a4,0xfffff
    800011f2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011f6:	fff58993          	addi	s3,a1,-1
    800011fa:	99b2                	add	s3,s3,a2
    800011fc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001200:	893e                	mv	s2,a5
    80001202:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001206:	6b85                	lui	s7,0x1
    80001208:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120c:	4605                	li	a2,1
    8000120e:	85ca                	mv	a1,s2
    80001210:	8556                	mv	a0,s5
    80001212:	00000097          	auipc	ra,0x0
    80001216:	eda080e7          	jalr	-294(ra) # 800010ec <walk>
    8000121a:	cd1d                	beqz	a0,80001258 <mappages+0x84>
    if(*pte & PTE_V)
    8000121c:	611c                	ld	a5,0(a0)
    8000121e:	8b85                	andi	a5,a5,1
    80001220:	e785                	bnez	a5,80001248 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001222:	80b1                	srli	s1,s1,0xc
    80001224:	04aa                	slli	s1,s1,0xa
    80001226:	0164e4b3          	or	s1,s1,s6
    8000122a:	0014e493          	ori	s1,s1,1
    8000122e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001230:	05390063          	beq	s2,s3,80001270 <mappages+0x9c>
    a += PGSIZE;
    80001234:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001236:	bfc9                	j	80001208 <mappages+0x34>
    panic("mappages: size");
    80001238:	00007517          	auipc	a0,0x7
    8000123c:	ed850513          	addi	a0,a0,-296 # 80008110 <digits+0xd0>
    80001240:	fffff097          	auipc	ra,0xfffff
    80001244:	300080e7          	jalr	768(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001248:	00007517          	auipc	a0,0x7
    8000124c:	ed850513          	addi	a0,a0,-296 # 80008120 <digits+0xe0>
    80001250:	fffff097          	auipc	ra,0xfffff
    80001254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>
      return -1;
    80001258:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000125a:	60a6                	ld	ra,72(sp)
    8000125c:	6406                	ld	s0,64(sp)
    8000125e:	74e2                	ld	s1,56(sp)
    80001260:	7942                	ld	s2,48(sp)
    80001262:	79a2                	ld	s3,40(sp)
    80001264:	7a02                	ld	s4,32(sp)
    80001266:	6ae2                	ld	s5,24(sp)
    80001268:	6b42                	ld	s6,16(sp)
    8000126a:	6ba2                	ld	s7,8(sp)
    8000126c:	6161                	addi	sp,sp,80
    8000126e:	8082                	ret
  return 0;
    80001270:	4501                	li	a0,0
    80001272:	b7e5                	j	8000125a <mappages+0x86>

0000000080001274 <kvmmap>:
{
    80001274:	1141                	addi	sp,sp,-16
    80001276:	e406                	sd	ra,8(sp)
    80001278:	e022                	sd	s0,0(sp)
    8000127a:	0800                	addi	s0,sp,16
    8000127c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000127e:	86b2                	mv	a3,a2
    80001280:	863e                	mv	a2,a5
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f52080e7          	jalr	-174(ra) # 800011d4 <mappages>
    8000128a:	e509                	bnez	a0,80001294 <kvmmap+0x20>
}
    8000128c:	60a2                	ld	ra,8(sp)
    8000128e:	6402                	ld	s0,0(sp)
    80001290:	0141                	addi	sp,sp,16
    80001292:	8082                	ret
    panic("kvmmap");
    80001294:	00007517          	auipc	a0,0x7
    80001298:	e9c50513          	addi	a0,a0,-356 # 80008130 <digits+0xf0>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2a4080e7          	jalr	676(ra) # 80000540 <panic>

00000000800012a4 <kvmmake>:
{
    800012a4:	1101                	addi	sp,sp,-32
    800012a6:	ec06                	sd	ra,24(sp)
    800012a8:	e822                	sd	s0,16(sp)
    800012aa:	e426                	sd	s1,8(sp)
    800012ac:	e04a                	sd	s2,0(sp)
    800012ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	934080e7          	jalr	-1740(ra) # 80000be4 <kalloc>
    800012b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012ba:	6605                	lui	a2,0x1
    800012bc:	4581                	li	a1,0
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	b4a080e7          	jalr	-1206(ra) # 80000e08 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c6:	4719                	li	a4,6
    800012c8:	6685                	lui	a3,0x1
    800012ca:	10000637          	lui	a2,0x10000
    800012ce:	100005b7          	lui	a1,0x10000
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	fa0080e7          	jalr	-96(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012dc:	4719                	li	a4,6
    800012de:	6685                	lui	a3,0x1
    800012e0:	10001637          	lui	a2,0x10001
    800012e4:	100015b7          	lui	a1,0x10001
    800012e8:	8526                	mv	a0,s1
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	f8a080e7          	jalr	-118(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f2:	4719                	li	a4,6
    800012f4:	004006b7          	lui	a3,0x400
    800012f8:	0c000637          	lui	a2,0xc000
    800012fc:	0c0005b7          	lui	a1,0xc000
    80001300:	8526                	mv	a0,s1
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f72080e7          	jalr	-142(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000130a:	00007917          	auipc	s2,0x7
    8000130e:	cf690913          	addi	s2,s2,-778 # 80008000 <etext>
    80001312:	4729                	li	a4,10
    80001314:	80007697          	auipc	a3,0x80007
    80001318:	cec68693          	addi	a3,a3,-788 # 8000 <_entry-0x7fff8000>
    8000131c:	4605                	li	a2,1
    8000131e:	067e                	slli	a2,a2,0x1f
    80001320:	85b2                	mv	a1,a2
    80001322:	8526                	mv	a0,s1
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f50080e7          	jalr	-176(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000132c:	4719                	li	a4,6
    8000132e:	46c5                	li	a3,17
    80001330:	06ee                	slli	a3,a3,0x1b
    80001332:	412686b3          	sub	a3,a3,s2
    80001336:	864a                	mv	a2,s2
    80001338:	85ca                	mv	a1,s2
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	f38080e7          	jalr	-200(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001344:	4729                	li	a4,10
    80001346:	6685                	lui	a3,0x1
    80001348:	00006617          	auipc	a2,0x6
    8000134c:	cb860613          	addi	a2,a2,-840 # 80007000 <_trampoline>
    80001350:	040005b7          	lui	a1,0x4000
    80001354:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001356:	05b2                	slli	a1,a1,0xc
    80001358:	8526                	mv	a0,s1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f1a080e7          	jalr	-230(ra) # 80001274 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001362:	8526                	mv	a0,s1
    80001364:	00000097          	auipc	ra,0x0
    80001368:	622080e7          	jalr	1570(ra) # 80001986 <proc_mapstacks>
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6902                	ld	s2,0(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <kvminit>:
{
    8000137a:	1141                	addi	sp,sp,-16
    8000137c:	e406                	sd	ra,8(sp)
    8000137e:	e022                	sd	s0,0(sp)
    80001380:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001382:	00000097          	auipc	ra,0x0
    80001386:	f22080e7          	jalr	-222(ra) # 800012a4 <kvmmake>
    8000138a:	00007797          	auipc	a5,0x7
    8000138e:	7ea7bb23          	sd	a0,2038(a5) # 80008b80 <kernel_pagetable>
}
    80001392:	60a2                	ld	ra,8(sp)
    80001394:	6402                	ld	s0,0(sp)
    80001396:	0141                	addi	sp,sp,16
    80001398:	8082                	ret

000000008000139a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000139a:	715d                	addi	sp,sp,-80
    8000139c:	e486                	sd	ra,72(sp)
    8000139e:	e0a2                	sd	s0,64(sp)
    800013a0:	fc26                	sd	s1,56(sp)
    800013a2:	f84a                	sd	s2,48(sp)
    800013a4:	f44e                	sd	s3,40(sp)
    800013a6:	f052                	sd	s4,32(sp)
    800013a8:	ec56                	sd	s5,24(sp)
    800013aa:	e85a                	sd	s6,16(sp)
    800013ac:	e45e                	sd	s7,8(sp)
    800013ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013b0:	03459793          	slli	a5,a1,0x34
    800013b4:	e795                	bnez	a5,800013e0 <uvmunmap+0x46>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	892e                	mv	s2,a1
    800013ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013bc:	0632                	slli	a2,a2,0xc
    800013be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c4:	6b05                	lui	s6,0x1
    800013c6:	0735e263          	bltu	a1,s3,8000142a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013ca:	60a6                	ld	ra,72(sp)
    800013cc:	6406                	ld	s0,64(sp)
    800013ce:	74e2                	ld	s1,56(sp)
    800013d0:	7942                	ld	s2,48(sp)
    800013d2:	79a2                	ld	s3,40(sp)
    800013d4:	7a02                	ld	s4,32(sp)
    800013d6:	6ae2                	ld	s5,24(sp)
    800013d8:	6b42                	ld	s6,16(sp)
    800013da:	6ba2                	ld	s7,8(sp)
    800013dc:	6161                	addi	sp,sp,80
    800013de:	8082                	ret
    panic("uvmunmap: not aligned");
    800013e0:	00007517          	auipc	a0,0x7
    800013e4:	d5850513          	addi	a0,a0,-680 # 80008138 <digits+0xf8>
    800013e8:	fffff097          	auipc	ra,0xfffff
    800013ec:	158080e7          	jalr	344(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800013f0:	00007517          	auipc	a0,0x7
    800013f4:	d6050513          	addi	a0,a0,-672 # 80008150 <digits+0x110>
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	148080e7          	jalr	328(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001400:	00007517          	auipc	a0,0x7
    80001404:	d6050513          	addi	a0,a0,-672 # 80008160 <digits+0x120>
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	138080e7          	jalr	312(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001410:	00007517          	auipc	a0,0x7
    80001414:	d6850513          	addi	a0,a0,-664 # 80008178 <digits+0x138>
    80001418:	fffff097          	auipc	ra,0xfffff
    8000141c:	128080e7          	jalr	296(ra) # 80000540 <panic>
    *pte = 0;
    80001420:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001424:	995a                	add	s2,s2,s6
    80001426:	fb3972e3          	bgeu	s2,s3,800013ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000142a:	4601                	li	a2,0
    8000142c:	85ca                	mv	a1,s2
    8000142e:	8552                	mv	a0,s4
    80001430:	00000097          	auipc	ra,0x0
    80001434:	cbc080e7          	jalr	-836(ra) # 800010ec <walk>
    80001438:	84aa                	mv	s1,a0
    8000143a:	d95d                	beqz	a0,800013f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000143c:	6108                	ld	a0,0(a0)
    8000143e:	00157793          	andi	a5,a0,1
    80001442:	dfdd                	beqz	a5,80001400 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001444:	3ff57793          	andi	a5,a0,1023
    80001448:	fd7784e3          	beq	a5,s7,80001410 <uvmunmap+0x76>
    if(do_free){
    8000144c:	fc0a8ae3          	beqz	s5,80001420 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001450:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001452:	0532                	slli	a0,a0,0xc
    80001454:	fffff097          	auipc	ra,0xfffff
    80001458:	60c080e7          	jalr	1548(ra) # 80000a60 <kfree>
    8000145c:	b7d1                	j	80001420 <uvmunmap+0x86>

000000008000145e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000145e:	1101                	addi	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	77c080e7          	jalr	1916(ra) # 80000be4 <kalloc>
    80001470:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001472:	c519                	beqz	a0,80001480 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	990080e7          	jalr	-1648(ra) # 80000e08 <memset>
  return pagetable;
}
    80001480:	8526                	mv	a0,s1
    80001482:	60e2                	ld	ra,24(sp)
    80001484:	6442                	ld	s0,16(sp)
    80001486:	64a2                	ld	s1,8(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret

000000008000148c <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000148c:	7179                	addi	sp,sp,-48
    8000148e:	f406                	sd	ra,40(sp)
    80001490:	f022                	sd	s0,32(sp)
    80001492:	ec26                	sd	s1,24(sp)
    80001494:	e84a                	sd	s2,16(sp)
    80001496:	e44e                	sd	s3,8(sp)
    80001498:	e052                	sd	s4,0(sp)
    8000149a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000149c:	6785                	lui	a5,0x1
    8000149e:	04f67863          	bgeu	a2,a5,800014ee <uvmfirst+0x62>
    800014a2:	8a2a                	mv	s4,a0
    800014a4:	89ae                	mv	s3,a1
    800014a6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	73c080e7          	jalr	1852(ra) # 80000be4 <kalloc>
    800014b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	952080e7          	jalr	-1710(ra) # 80000e08 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014be:	4779                	li	a4,30
    800014c0:	86ca                	mv	a3,s2
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	8552                	mv	a0,s4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	d0c080e7          	jalr	-756(ra) # 800011d4 <mappages>
  memmove(mem, src, sz);
    800014d0:	8626                	mv	a2,s1
    800014d2:	85ce                	mv	a1,s3
    800014d4:	854a                	mv	a0,s2
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	98e080e7          	jalr	-1650(ra) # 80000e64 <memmove>
}
    800014de:	70a2                	ld	ra,40(sp)
    800014e0:	7402                	ld	s0,32(sp)
    800014e2:	64e2                	ld	s1,24(sp)
    800014e4:	6942                	ld	s2,16(sp)
    800014e6:	69a2                	ld	s3,8(sp)
    800014e8:	6a02                	ld	s4,0(sp)
    800014ea:	6145                	addi	sp,sp,48
    800014ec:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ee:	00007517          	auipc	a0,0x7
    800014f2:	ca250513          	addi	a0,a0,-862 # 80008190 <digits+0x150>
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	04a080e7          	jalr	74(ra) # 80000540 <panic>

00000000800014fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014fe:	1101                	addi	sp,sp,-32
    80001500:	ec06                	sd	ra,24(sp)
    80001502:	e822                	sd	s0,16(sp)
    80001504:	e426                	sd	s1,8(sp)
    80001506:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001508:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000150a:	00b67d63          	bgeu	a2,a1,80001524 <uvmdealloc+0x26>
    8000150e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001510:	6785                	lui	a5,0x1
    80001512:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001514:	00f60733          	add	a4,a2,a5
    80001518:	76fd                	lui	a3,0xfffff
    8000151a:	8f75                	and	a4,a4,a3
    8000151c:	97ae                	add	a5,a5,a1
    8000151e:	8ff5                	and	a5,a5,a3
    80001520:	00f76863          	bltu	a4,a5,80001530 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001524:	8526                	mv	a0,s1
    80001526:	60e2                	ld	ra,24(sp)
    80001528:	6442                	ld	s0,16(sp)
    8000152a:	64a2                	ld	s1,8(sp)
    8000152c:	6105                	addi	sp,sp,32
    8000152e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001530:	8f99                	sub	a5,a5,a4
    80001532:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001534:	4685                	li	a3,1
    80001536:	0007861b          	sext.w	a2,a5
    8000153a:	85ba                	mv	a1,a4
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	e5e080e7          	jalr	-418(ra) # 8000139a <uvmunmap>
    80001544:	b7c5                	j	80001524 <uvmdealloc+0x26>

0000000080001546 <uvmalloc>:
  if(newsz < oldsz)
    80001546:	0ab66563          	bltu	a2,a1,800015f0 <uvmalloc+0xaa>
{
    8000154a:	7139                	addi	sp,sp,-64
    8000154c:	fc06                	sd	ra,56(sp)
    8000154e:	f822                	sd	s0,48(sp)
    80001550:	f426                	sd	s1,40(sp)
    80001552:	f04a                	sd	s2,32(sp)
    80001554:	ec4e                	sd	s3,24(sp)
    80001556:	e852                	sd	s4,16(sp)
    80001558:	e456                	sd	s5,8(sp)
    8000155a:	e05a                	sd	s6,0(sp)
    8000155c:	0080                	addi	s0,sp,64
    8000155e:	8aaa                	mv	s5,a0
    80001560:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001562:	6785                	lui	a5,0x1
    80001564:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001566:	95be                	add	a1,a1,a5
    80001568:	77fd                	lui	a5,0xfffff
    8000156a:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000156e:	08c9f363          	bgeu	s3,a2,800015f4 <uvmalloc+0xae>
    80001572:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001574:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001578:	fffff097          	auipc	ra,0xfffff
    8000157c:	66c080e7          	jalr	1644(ra) # 80000be4 <kalloc>
    80001580:	84aa                	mv	s1,a0
    if(mem == 0){
    80001582:	c51d                	beqz	a0,800015b0 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001584:	6605                	lui	a2,0x1
    80001586:	4581                	li	a1,0
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	880080e7          	jalr	-1920(ra) # 80000e08 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001590:	875a                	mv	a4,s6
    80001592:	86a6                	mv	a3,s1
    80001594:	6605                	lui	a2,0x1
    80001596:	85ca                	mv	a1,s2
    80001598:	8556                	mv	a0,s5
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	c3a080e7          	jalr	-966(ra) # 800011d4 <mappages>
    800015a2:	e90d                	bnez	a0,800015d4 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a4:	6785                	lui	a5,0x1
    800015a6:	993e                	add	s2,s2,a5
    800015a8:	fd4968e3          	bltu	s2,s4,80001578 <uvmalloc+0x32>
  return newsz;
    800015ac:	8552                	mv	a0,s4
    800015ae:	a809                	j	800015c0 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015b0:	864e                	mv	a2,s3
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f48080e7          	jalr	-184(ra) # 800014fe <uvmdealloc>
      return 0;
    800015be:	4501                	li	a0,0
}
    800015c0:	70e2                	ld	ra,56(sp)
    800015c2:	7442                	ld	s0,48(sp)
    800015c4:	74a2                	ld	s1,40(sp)
    800015c6:	7902                	ld	s2,32(sp)
    800015c8:	69e2                	ld	s3,24(sp)
    800015ca:	6a42                	ld	s4,16(sp)
    800015cc:	6aa2                	ld	s5,8(sp)
    800015ce:	6b02                	ld	s6,0(sp)
    800015d0:	6121                	addi	sp,sp,64
    800015d2:	8082                	ret
      kfree(mem);
    800015d4:	8526                	mv	a0,s1
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	48a080e7          	jalr	1162(ra) # 80000a60 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015de:	864e                	mv	a2,s3
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	f1a080e7          	jalr	-230(ra) # 800014fe <uvmdealloc>
      return 0;
    800015ec:	4501                	li	a0,0
    800015ee:	bfc9                	j	800015c0 <uvmalloc+0x7a>
    return oldsz;
    800015f0:	852e                	mv	a0,a1
}
    800015f2:	8082                	ret
  return newsz;
    800015f4:	8532                	mv	a0,a2
    800015f6:	b7e9                	j	800015c0 <uvmalloc+0x7a>

00000000800015f8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f8:	7179                	addi	sp,sp,-48
    800015fa:	f406                	sd	ra,40(sp)
    800015fc:	f022                	sd	s0,32(sp)
    800015fe:	ec26                	sd	s1,24(sp)
    80001600:	e84a                	sd	s2,16(sp)
    80001602:	e44e                	sd	s3,8(sp)
    80001604:	e052                	sd	s4,0(sp)
    80001606:	1800                	addi	s0,sp,48
    80001608:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000160a:	84aa                	mv	s1,a0
    8000160c:	6905                	lui	s2,0x1
    8000160e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001610:	4985                	li	s3,1
    80001612:	a829                	j	8000162c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001614:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001616:	00c79513          	slli	a0,a5,0xc
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	fde080e7          	jalr	-34(ra) # 800015f8 <freewalk>
      pagetable[i] = 0;
    80001622:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001626:	04a1                	addi	s1,s1,8
    80001628:	03248163          	beq	s1,s2,8000164a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000162c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162e:	00f7f713          	andi	a4,a5,15
    80001632:	ff3701e3          	beq	a4,s3,80001614 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001636:	8b85                	andi	a5,a5,1
    80001638:	d7fd                	beqz	a5,80001626 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	b7650513          	addi	a0,a0,-1162 # 800081b0 <digits+0x170>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	efe080e7          	jalr	-258(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000164a:	8552                	mv	a0,s4
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	414080e7          	jalr	1044(ra) # 80000a60 <kfree>
}
    80001654:	70a2                	ld	ra,40(sp)
    80001656:	7402                	ld	s0,32(sp)
    80001658:	64e2                	ld	s1,24(sp)
    8000165a:	6942                	ld	s2,16(sp)
    8000165c:	69a2                	ld	s3,8(sp)
    8000165e:	6a02                	ld	s4,0(sp)
    80001660:	6145                	addi	sp,sp,48
    80001662:	8082                	ret

0000000080001664 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001664:	1101                	addi	sp,sp,-32
    80001666:	ec06                	sd	ra,24(sp)
    80001668:	e822                	sd	s0,16(sp)
    8000166a:	e426                	sd	s1,8(sp)
    8000166c:	1000                	addi	s0,sp,32
    8000166e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001670:	e999                	bnez	a1,80001686 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001672:	8526                	mv	a0,s1
    80001674:	00000097          	auipc	ra,0x0
    80001678:	f84080e7          	jalr	-124(ra) # 800015f8 <freewalk>
}
    8000167c:	60e2                	ld	ra,24(sp)
    8000167e:	6442                	ld	s0,16(sp)
    80001680:	64a2                	ld	s1,8(sp)
    80001682:	6105                	addi	sp,sp,32
    80001684:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001686:	6785                	lui	a5,0x1
    80001688:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000168a:	95be                	add	a1,a1,a5
    8000168c:	4685                	li	a3,1
    8000168e:	00c5d613          	srli	a2,a1,0xc
    80001692:	4581                	li	a1,0
    80001694:	00000097          	auipc	ra,0x0
    80001698:	d06080e7          	jalr	-762(ra) # 8000139a <uvmunmap>
    8000169c:	bfd9                	j	80001672 <uvmfree+0xe>

000000008000169e <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE)
    8000169e:	ca55                	beqz	a2,80001752 <uvmcopy+0xb4>
{
    800016a0:	7139                	addi	sp,sp,-64
    800016a2:	fc06                	sd	ra,56(sp)
    800016a4:	f822                	sd	s0,48(sp)
    800016a6:	f426                	sd	s1,40(sp)
    800016a8:	f04a                	sd	s2,32(sp)
    800016aa:	ec4e                	sd	s3,24(sp)
    800016ac:	e852                	sd	s4,16(sp)
    800016ae:	e456                	sd	s5,8(sp)
    800016b0:	e05a                	sd	s6,0(sp)
    800016b2:	0080                	addi	s0,sp,64
    800016b4:	8b2a                	mv	s6,a0
    800016b6:	8aae                	mv	s5,a1
    800016b8:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    800016ba:	4901                	li	s2,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    800016bc:	4601                	li	a2,0
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	a2a080e7          	jalr	-1494(ra) # 800010ec <walk>
    800016ca:	c121                	beqz	a0,8000170a <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800016cc:	6118                	ld	a4,0(a0)
    800016ce:	00177793          	andi	a5,a4,1
    800016d2:	c7a1                	beqz	a5,8000171a <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    //fix the permission bits
    pa = PTE2PA(*pte);
    800016d4:	00a75993          	srli	s3,a4,0xa
    800016d8:	09b2                	slli	s3,s3,0xc
    // make it not writable
    *pte &= ~PTE_W;
    800016da:	ffb77493          	andi	s1,a4,-5
    800016de:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);

    addit(pa);
    800016e0:	854e                	mv	a0,s3
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	306080e7          	jalr	774(ra) # 800009e8 <addit>
    //map the va to the same pa using flags
    if (mappages(new, i, PGSIZE, (uint64)pa, flags) != 0)
    800016ea:	3fb4f713          	andi	a4,s1,1019
    800016ee:	86ce                	mv	a3,s3
    800016f0:	6605                	lui	a2,0x1
    800016f2:	85ca                	mv	a1,s2
    800016f4:	8556                	mv	a0,s5
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	ade080e7          	jalr	-1314(ra) # 800011d4 <mappages>
    800016fe:	e515                	bnez	a0,8000172a <uvmcopy+0x8c>
  for (i = 0; i < sz; i += PGSIZE)
    80001700:	6785                	lui	a5,0x1
    80001702:	993e                	add	s2,s2,a5
    80001704:	fb496ce3          	bltu	s2,s4,800016bc <uvmcopy+0x1e>
    80001708:	a81d                	j	8000173e <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000170a:	00007517          	auipc	a0,0x7
    8000170e:	ab650513          	addi	a0,a0,-1354 # 800081c0 <digits+0x180>
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	e2e080e7          	jalr	-466(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000171a:	00007517          	auipc	a0,0x7
    8000171e:	ac650513          	addi	a0,a0,-1338 # 800081e0 <digits+0x1a0>
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	e1e080e7          	jalr	-482(ra) # 80000540 <panic>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000172a:	4685                	li	a3,1
    8000172c:	00c95613          	srli	a2,s2,0xc
    80001730:	4581                	li	a1,0
    80001732:	8556                	mv	a0,s5
    80001734:	00000097          	auipc	ra,0x0
    80001738:	c66080e7          	jalr	-922(ra) # 8000139a <uvmunmap>
  return -1;
    8000173c:	557d                	li	a0,-1
}
    8000173e:	70e2                	ld	ra,56(sp)
    80001740:	7442                	ld	s0,48(sp)
    80001742:	74a2                	ld	s1,40(sp)
    80001744:	7902                	ld	s2,32(sp)
    80001746:	69e2                	ld	s3,24(sp)
    80001748:	6a42                	ld	s4,16(sp)
    8000174a:	6aa2                	ld	s5,8(sp)
    8000174c:	6b02                	ld	s6,0(sp)
    8000174e:	6121                	addi	sp,sp,64
    80001750:	8082                	ret
  return 0;
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret

0000000080001756 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001756:	1141                	addi	sp,sp,-16
    80001758:	e406                	sd	ra,8(sp)
    8000175a:	e022                	sd	s0,0(sp)
    8000175c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000175e:	4601                	li	a2,0
    80001760:	00000097          	auipc	ra,0x0
    80001764:	98c080e7          	jalr	-1652(ra) # 800010ec <walk>
  if(pte == 0)
    80001768:	c901                	beqz	a0,80001778 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000176a:	611c                	ld	a5,0(a0)
    8000176c:	9bbd                	andi	a5,a5,-17
    8000176e:	e11c                	sd	a5,0(a0)
}
    80001770:	60a2                	ld	ra,8(sp)
    80001772:	6402                	ld	s0,0(sp)
    80001774:	0141                	addi	sp,sp,16
    80001776:	8082                	ret
    panic("uvmclear");
    80001778:	00007517          	auipc	a0,0x7
    8000177c:	a8850513          	addi	a0,a0,-1400 # 80008200 <digits+0x1c0>
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>

0000000080001788 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001788:	cad1                	beqz	a3,8000181c <copyout+0x94>
{
    8000178a:	711d                	addi	sp,sp,-96
    8000178c:	ec86                	sd	ra,88(sp)
    8000178e:	e8a2                	sd	s0,80(sp)
    80001790:	e4a6                	sd	s1,72(sp)
    80001792:	e0ca                	sd	s2,64(sp)
    80001794:	fc4e                	sd	s3,56(sp)
    80001796:	f852                	sd	s4,48(sp)
    80001798:	f456                	sd	s5,40(sp)
    8000179a:	f05a                	sd	s6,32(sp)
    8000179c:	ec5e                	sd	s7,24(sp)
    8000179e:	e862                	sd	s8,16(sp)
    800017a0:	e466                	sd	s9,8(sp)
    800017a2:	1080                	addi	s0,sp,96
    800017a4:	8baa                	mv	s7,a0
    800017a6:	8aae                	mv	s5,a1
    800017a8:	8b32                	mv	s6,a2
    800017aa:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017ac:	74fd                	lui	s1,0xfffff
    800017ae:	8ced                	and	s1,s1,a1
    if (va0 > MAXVA)
    800017b0:	4785                	li	a5,1
    800017b2:	179a                	slli	a5,a5,0x26
    800017b4:	0697e663          	bltu	a5,s1,80001820 <copyout+0x98>
    800017b8:	6c85                	lui	s9,0x1
    800017ba:	04000c37          	lui	s8,0x4000
    800017be:	0c05                	addi	s8,s8,1 # 4000001 <_entry-0x7bffffff>
    800017c0:	0c32                	slli	s8,s8,0xc
    800017c2:	a025                	j	800017ea <copyout+0x62>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c4:	409a84b3          	sub	s1,s5,s1
    800017c8:	0009061b          	sext.w	a2,s2
    800017cc:	85da                	mv	a1,s6
    800017ce:	9526                	add	a0,a0,s1
    800017d0:	fffff097          	auipc	ra,0xfffff
    800017d4:	694080e7          	jalr	1684(ra) # 80000e64 <memmove>

    len -= n;
    800017d8:	412989b3          	sub	s3,s3,s2
    src += n;
    800017dc:	9b4a                	add	s6,s6,s2
  while(len > 0){
    800017de:	02098d63          	beqz	s3,80001818 <copyout+0x90>
    if (va0 > MAXVA)
    800017e2:	058a0163          	beq	s4,s8,80001824 <copyout+0x9c>
    va0 = PGROUNDDOWN(dstva);
    800017e6:	84d2                	mv	s1,s4
    dstva = va0 + PGSIZE;
    800017e8:	8ad2                	mv	s5,s4
    if(cowfault(pagetable,va0)<0){
    800017ea:	85a6                	mv	a1,s1
    800017ec:	855e                	mv	a0,s7
    800017ee:	00002097          	auipc	ra,0x2
    800017f2:	aa6080e7          	jalr	-1370(ra) # 80003294 <cowfault>
    800017f6:	02054963          	bltz	a0,80001828 <copyout+0xa0>
    pa0 = walkaddr(pagetable, va0);
    800017fa:	85a6                	mv	a1,s1
    800017fc:	855e                	mv	a0,s7
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	994080e7          	jalr	-1644(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    80001806:	cd1d                	beqz	a0,80001844 <copyout+0xbc>
    n = PGSIZE - (dstva - va0);
    80001808:	01948a33          	add	s4,s1,s9
    8000180c:	415a0933          	sub	s2,s4,s5
    80001810:	fb29fae3          	bgeu	s3,s2,800017c4 <copyout+0x3c>
    80001814:	894e                	mv	s2,s3
    80001816:	b77d                	j	800017c4 <copyout+0x3c>
  }
  return 0;
    80001818:	4501                	li	a0,0
    8000181a:	a801                	j	8000182a <copyout+0xa2>
    8000181c:	4501                	li	a0,0
}
    8000181e:	8082                	ret
        return -1;    
    80001820:	557d                	li	a0,-1
    80001822:	a021                	j	8000182a <copyout+0xa2>
    80001824:	557d                	li	a0,-1
    80001826:	a011                	j	8000182a <copyout+0xa2>
      return -1;
    80001828:	557d                	li	a0,-1
}
    8000182a:	60e6                	ld	ra,88(sp)
    8000182c:	6446                	ld	s0,80(sp)
    8000182e:	64a6                	ld	s1,72(sp)
    80001830:	6906                	ld	s2,64(sp)
    80001832:	79e2                	ld	s3,56(sp)
    80001834:	7a42                	ld	s4,48(sp)
    80001836:	7aa2                	ld	s5,40(sp)
    80001838:	7b02                	ld	s6,32(sp)
    8000183a:	6be2                	ld	s7,24(sp)
    8000183c:	6c42                	ld	s8,16(sp)
    8000183e:	6ca2                	ld	s9,8(sp)
    80001840:	6125                	addi	sp,sp,96
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
    80001846:	b7d5                	j	8000182a <copyout+0xa2>

0000000080001848 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001848:	caa5                	beqz	a3,800018b8 <copyin+0x70>
{
    8000184a:	715d                	addi	sp,sp,-80
    8000184c:	e486                	sd	ra,72(sp)
    8000184e:	e0a2                	sd	s0,64(sp)
    80001850:	fc26                	sd	s1,56(sp)
    80001852:	f84a                	sd	s2,48(sp)
    80001854:	f44e                	sd	s3,40(sp)
    80001856:	f052                	sd	s4,32(sp)
    80001858:	ec56                	sd	s5,24(sp)
    8000185a:	e85a                	sd	s6,16(sp)
    8000185c:	e45e                	sd	s7,8(sp)
    8000185e:	e062                	sd	s8,0(sp)
    80001860:	0880                	addi	s0,sp,80
    80001862:	8b2a                	mv	s6,a0
    80001864:	8a2e                	mv	s4,a1
    80001866:	8c32                	mv	s8,a2
    80001868:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000186a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186c:	6a85                	lui	s5,0x1
    8000186e:	a01d                	j	80001894 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001870:	018505b3          	add	a1,a0,s8
    80001874:	0004861b          	sext.w	a2,s1
    80001878:	412585b3          	sub	a1,a1,s2
    8000187c:	8552                	mv	a0,s4
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	5e6080e7          	jalr	1510(ra) # 80000e64 <memmove>

    len -= n;
    80001886:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000188a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000188c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001890:	02098263          	beqz	s3,800018b4 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001894:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001898:	85ca                	mv	a1,s2
    8000189a:	855a                	mv	a0,s6
    8000189c:	00000097          	auipc	ra,0x0
    800018a0:	8f6080e7          	jalr	-1802(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    800018a4:	cd01                	beqz	a0,800018bc <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a6:	418904b3          	sub	s1,s2,s8
    800018aa:	94d6                	add	s1,s1,s5
    800018ac:	fc99f2e3          	bgeu	s3,s1,80001870 <copyin+0x28>
    800018b0:	84ce                	mv	s1,s3
    800018b2:	bf7d                	j	80001870 <copyin+0x28>
  }
  return 0;
    800018b4:	4501                	li	a0,0
    800018b6:	a021                	j	800018be <copyin+0x76>
    800018b8:	4501                	li	a0,0
}
    800018ba:	8082                	ret
      return -1;
    800018bc:	557d                	li	a0,-1
}
    800018be:	60a6                	ld	ra,72(sp)
    800018c0:	6406                	ld	s0,64(sp)
    800018c2:	74e2                	ld	s1,56(sp)
    800018c4:	7942                	ld	s2,48(sp)
    800018c6:	79a2                	ld	s3,40(sp)
    800018c8:	7a02                	ld	s4,32(sp)
    800018ca:	6ae2                	ld	s5,24(sp)
    800018cc:	6b42                	ld	s6,16(sp)
    800018ce:	6ba2                	ld	s7,8(sp)
    800018d0:	6c02                	ld	s8,0(sp)
    800018d2:	6161                	addi	sp,sp,80
    800018d4:	8082                	ret

00000000800018d6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d6:	c2dd                	beqz	a3,8000197c <copyinstr+0xa6>
{
    800018d8:	715d                	addi	sp,sp,-80
    800018da:	e486                	sd	ra,72(sp)
    800018dc:	e0a2                	sd	s0,64(sp)
    800018de:	fc26                	sd	s1,56(sp)
    800018e0:	f84a                	sd	s2,48(sp)
    800018e2:	f44e                	sd	s3,40(sp)
    800018e4:	f052                	sd	s4,32(sp)
    800018e6:	ec56                	sd	s5,24(sp)
    800018e8:	e85a                	sd	s6,16(sp)
    800018ea:	e45e                	sd	s7,8(sp)
    800018ec:	0880                	addi	s0,sp,80
    800018ee:	8a2a                	mv	s4,a0
    800018f0:	8b2e                	mv	s6,a1
    800018f2:	8bb2                	mv	s7,a2
    800018f4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f8:	6985                	lui	s3,0x1
    800018fa:	a02d                	j	80001924 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018fc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001900:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001902:	37fd                	addiw	a5,a5,-1
    80001904:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001908:	60a6                	ld	ra,72(sp)
    8000190a:	6406                	ld	s0,64(sp)
    8000190c:	74e2                	ld	s1,56(sp)
    8000190e:	7942                	ld	s2,48(sp)
    80001910:	79a2                	ld	s3,40(sp)
    80001912:	7a02                	ld	s4,32(sp)
    80001914:	6ae2                	ld	s5,24(sp)
    80001916:	6b42                	ld	s6,16(sp)
    80001918:	6ba2                	ld	s7,8(sp)
    8000191a:	6161                	addi	sp,sp,80
    8000191c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001922:	c8a9                	beqz	s1,80001974 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001924:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001928:	85ca                	mv	a1,s2
    8000192a:	8552                	mv	a0,s4
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	866080e7          	jalr	-1946(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    80001934:	c131                	beqz	a0,80001978 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001936:	417906b3          	sub	a3,s2,s7
    8000193a:	96ce                	add	a3,a3,s3
    8000193c:	00d4f363          	bgeu	s1,a3,80001942 <copyinstr+0x6c>
    80001940:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001942:	955e                	add	a0,a0,s7
    80001944:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001948:	daf9                	beqz	a3,8000191e <copyinstr+0x48>
    8000194a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000194c:	41650633          	sub	a2,a0,s6
    80001950:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdb974f>
    80001954:	95da                	add	a1,a1,s6
    while(n > 0){
    80001956:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001958:	00f60733          	add	a4,a2,a5
    8000195c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9750>
    80001960:	df51                	beqz	a4,800018fc <copyinstr+0x26>
        *dst = *p;
    80001962:	00e78023          	sb	a4,0(a5)
      --max;
    80001966:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000196a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000196c:	fed796e3          	bne	a5,a3,80001958 <copyinstr+0x82>
      dst++;
    80001970:	8b3e                	mv	s6,a5
    80001972:	b775                	j	8000191e <copyinstr+0x48>
    80001974:	4781                	li	a5,0
    80001976:	b771                	j	80001902 <copyinstr+0x2c>
      return -1;
    80001978:	557d                	li	a0,-1
    8000197a:	b779                	j	80001908 <copyinstr+0x32>
  int got_null = 0;
    8000197c:	4781                	li	a5,0
  if(got_null){
    8000197e:	37fd                	addiw	a5,a5,-1
    80001980:	0007851b          	sext.w	a0,a5
}
    80001984:	8082                	ret

0000000080001986 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001986:	7139                	addi	sp,sp,-64
    80001988:	fc06                	sd	ra,56(sp)
    8000198a:	f822                	sd	s0,48(sp)
    8000198c:	f426                	sd	s1,40(sp)
    8000198e:	f04a                	sd	s2,32(sp)
    80001990:	ec4e                	sd	s3,24(sp)
    80001992:	e852                	sd	s4,16(sp)
    80001994:	e456                	sd	s5,8(sp)
    80001996:	e05a                	sd	s6,0(sp)
    80001998:	0080                	addi	s0,sp,64
    8000199a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199c:	00230497          	auipc	s1,0x230
    800019a0:	89448493          	addi	s1,s1,-1900 # 80231230 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019a4:	8b26                	mv	s6,s1
    800019a6:	00006a97          	auipc	s5,0x6
    800019aa:	65aa8a93          	addi	s5,s5,1626 # 80008000 <etext>
    800019ae:	04000937          	lui	s2,0x4000
    800019b2:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019b4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b6:	00238a17          	auipc	s4,0x238
    800019ba:	07aa0a13          	addi	s4,s4,122 # 80239a30 <mlfq_q>
    char *pa = kalloc();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	226080e7          	jalr	550(ra) # 80000be4 <kalloc>
    800019c6:	862a                	mv	a2,a0
    if(pa == 0)
    800019c8:	c131                	beqz	a0,80001a0c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019ca:	416485b3          	sub	a1,s1,s6
    800019ce:	8595                	srai	a1,a1,0x5
    800019d0:	000ab783          	ld	a5,0(s5)
    800019d4:	02f585b3          	mul	a1,a1,a5
    800019d8:	2585                	addiw	a1,a1,1
    800019da:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019de:	4719                	li	a4,6
    800019e0:	6685                	lui	a3,0x1
    800019e2:	40b905b3          	sub	a1,s2,a1
    800019e6:	854e                	mv	a0,s3
    800019e8:	00000097          	auipc	ra,0x0
    800019ec:	88c080e7          	jalr	-1908(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	22048493          	addi	s1,s1,544
    800019f4:	fd4495e3          	bne	s1,s4,800019be <proc_mapstacks+0x38>
  }
}
    800019f8:	70e2                	ld	ra,56(sp)
    800019fa:	7442                	ld	s0,48(sp)
    800019fc:	74a2                	ld	s1,40(sp)
    800019fe:	7902                	ld	s2,32(sp)
    80001a00:	69e2                	ld	s3,24(sp)
    80001a02:	6a42                	ld	s4,16(sp)
    80001a04:	6aa2                	ld	s5,8(sp)
    80001a06:	6b02                	ld	s6,0(sp)
    80001a08:	6121                	addi	sp,sp,64
    80001a0a:	8082                	ret
      panic("kalloc");
    80001a0c:	00007517          	auipc	a0,0x7
    80001a10:	80450513          	addi	a0,a0,-2044 # 80008210 <digits+0x1d0>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	b2c080e7          	jalr	-1236(ra) # 80000540 <panic>

0000000080001a1c <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a1c:	7139                	addi	sp,sp,-64
    80001a1e:	fc06                	sd	ra,56(sp)
    80001a20:	f822                	sd	s0,48(sp)
    80001a22:	f426                	sd	s1,40(sp)
    80001a24:	f04a                	sd	s2,32(sp)
    80001a26:	ec4e                	sd	s3,24(sp)
    80001a28:	e852                	sd	s4,16(sp)
    80001a2a:	e456                	sd	s5,8(sp)
    80001a2c:	e05a                	sd	s6,0(sp)
    80001a2e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a30:	00006597          	auipc	a1,0x6
    80001a34:	7e858593          	addi	a1,a1,2024 # 80008218 <digits+0x1d8>
    80001a38:	0022f517          	auipc	a0,0x22f
    80001a3c:	3c850513          	addi	a0,a0,968 # 80230e00 <pid_lock>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	23c080e7          	jalr	572(ra) # 80000c7c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7d858593          	addi	a1,a1,2008 # 80008220 <digits+0x1e0>
    80001a50:	0022f517          	auipc	a0,0x22f
    80001a54:	3c850513          	addi	a0,a0,968 # 80230e18 <wait_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	224080e7          	jalr	548(ra) # 80000c7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	0022f497          	auipc	s1,0x22f
    80001a64:	7d048493          	addi	s1,s1,2000 # 80231230 <proc>
      initlock(&p->lock, "proc");
    80001a68:	00006b17          	auipc	s6,0x6
    80001a6c:	7c8b0b13          	addi	s6,s6,1992 # 80008230 <digits+0x1f0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a70:	8aa6                	mv	s5,s1
    80001a72:	00006a17          	auipc	s4,0x6
    80001a76:	58ea0a13          	addi	s4,s4,1422 # 80008000 <etext>
    80001a7a:	04000937          	lui	s2,0x4000
    80001a7e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a80:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a82:	00238997          	auipc	s3,0x238
    80001a86:	fae98993          	addi	s3,s3,-82 # 80239a30 <mlfq_q>
      initlock(&p->lock, "proc");
    80001a8a:	85da                	mv	a1,s6
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	1ee080e7          	jalr	494(ra) # 80000c7c <initlock>
      p->state = UNUSED;
    80001a96:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a9a:	415487b3          	sub	a5,s1,s5
    80001a9e:	8795                	srai	a5,a5,0x5
    80001aa0:	000a3703          	ld	a4,0(s4)
    80001aa4:	02e787b3          	mul	a5,a5,a4
    80001aa8:	2785                	addiw	a5,a5,1
    80001aaa:	00d7979b          	slliw	a5,a5,0xd
    80001aae:	40f907b3          	sub	a5,s2,a5
    80001ab2:	e8bc                	sd	a5,80(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab4:	22048493          	addi	s1,s1,544
    80001ab8:	fd3499e3          	bne	s1,s3,80001a8a <procinit+0x6e>
  }
}
    80001abc:	70e2                	ld	ra,56(sp)
    80001abe:	7442                	ld	s0,48(sp)
    80001ac0:	74a2                	ld	s1,40(sp)
    80001ac2:	7902                	ld	s2,32(sp)
    80001ac4:	69e2                	ld	s3,24(sp)
    80001ac6:	6a42                	ld	s4,16(sp)
    80001ac8:	6aa2                	ld	s5,8(sp)
    80001aca:	6b02                	ld	s6,0(sp)
    80001acc:	6121                	addi	sp,sp,64
    80001ace:	8082                	ret

0000000080001ad0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ad0:	1141                	addi	sp,sp,-16
    80001ad2:	e422                	sd	s0,8(sp)
    80001ad4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad8:	2501                	sext.w	a0,a0
    80001ada:	6422                	ld	s0,8(sp)
    80001adc:	0141                	addi	sp,sp,16
    80001ade:	8082                	ret

0000000080001ae0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001ae0:	1141                	addi	sp,sp,-16
    80001ae2:	e422                	sd	s0,8(sp)
    80001ae4:	0800                	addi	s0,sp,16
    80001ae6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aec:	0022f517          	auipc	a0,0x22f
    80001af0:	34450513          	addi	a0,a0,836 # 80230e30 <cpus>
    80001af4:	953e                	add	a0,a0,a5
    80001af6:	6422                	ld	s0,8(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret

0000000080001afc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001afc:	1101                	addi	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	1000                	addi	s0,sp,32
  push_off();
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	1ba080e7          	jalr	442(ra) # 80000cc0 <push_off>
    80001b0e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b10:	2781                	sext.w	a5,a5
    80001b12:	079e                	slli	a5,a5,0x7
    80001b14:	0022f717          	auipc	a4,0x22f
    80001b18:	2ec70713          	addi	a4,a4,748 # 80230e00 <pid_lock>
    80001b1c:	97ba                	add	a5,a5,a4
    80001b1e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	240080e7          	jalr	576(ra) # 80000d60 <pop_off>
  return p;
}
    80001b28:	8526                	mv	a0,s1
    80001b2a:	60e2                	ld	ra,24(sp)
    80001b2c:	6442                	ld	s0,16(sp)
    80001b2e:	64a2                	ld	s1,8(sp)
    80001b30:	6105                	addi	sp,sp,32
    80001b32:	8082                	ret

0000000080001b34 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b34:	1141                	addi	sp,sp,-16
    80001b36:	e406                	sd	ra,8(sp)
    80001b38:	e022                	sd	s0,0(sp)
    80001b3a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	fc0080e7          	jalr	-64(ra) # 80001afc <myproc>
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	27c080e7          	jalr	636(ra) # 80000dc0 <release>

  if (first) {
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	fa47a783          	lw	a5,-92(a5) # 80008af0 <first.1>
    80001b54:	eb89                	bnez	a5,80001b66 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b56:	00001097          	auipc	ra,0x1
    80001b5a:	4e6080e7          	jalr	1254(ra) # 8000303c <usertrapret>
}
    80001b5e:	60a2                	ld	ra,8(sp)
    80001b60:	6402                	ld	s0,0(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret
    first = 0;
    80001b66:	00007797          	auipc	a5,0x7
    80001b6a:	f807a523          	sw	zero,-118(a5) # 80008af0 <first.1>
    fsinit(ROOTDEV);
    80001b6e:	4505                	li	a0,1
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	488080e7          	jalr	1160(ra) # 80003ff8 <fsinit>
    80001b78:	bff9                	j	80001b56 <forkret+0x22>

0000000080001b7a <allocpid>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b86:	0022f917          	auipc	s2,0x22f
    80001b8a:	27a90913          	addi	s2,s2,634 # 80230e00 <pid_lock>
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	17c080e7          	jalr	380(ra) # 80000d0c <acquire>
  pid = nextpid;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	f5c78793          	addi	a5,a5,-164 # 80008af4 <nextpid>
    80001ba0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba2:	0014871b          	addiw	a4,s1,1
    80001ba6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba8:	854a                	mv	a0,s2
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	216080e7          	jalr	534(ra) # 80000dc0 <release>
}
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <proc_pagetable>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	addi	s0,sp,32
    80001bcc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	890080e7          	jalr	-1904(ra) # 8000145e <uvmcreate>
    80001bd6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd8:	c121                	beqz	a0,80001c18 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bda:	4729                	li	a4,10
    80001bdc:	00005697          	auipc	a3,0x5
    80001be0:	42468693          	addi	a3,a3,1060 # 80007000 <_trampoline>
    80001be4:	6605                	lui	a2,0x1
    80001be6:	040005b7          	lui	a1,0x4000
    80001bea:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bec:	05b2                	slli	a1,a1,0xc
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	5e6080e7          	jalr	1510(ra) # 800011d4 <mappages>
    80001bf6:	02054863          	bltz	a0,80001c26 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bfa:	4719                	li	a4,6
    80001bfc:	06893683          	ld	a3,104(s2)
    80001c00:	6605                	lui	a2,0x1
    80001c02:	020005b7          	lui	a1,0x2000
    80001c06:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c08:	05b6                	slli	a1,a1,0xd
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	5c8080e7          	jalr	1480(ra) # 800011d4 <mappages>
    80001c14:	02054163          	bltz	a0,80001c36 <proc_pagetable+0x76>
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    uvmfree(pagetable, 0);
    80001c26:	4581                	li	a1,0
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	a3a080e7          	jalr	-1478(ra) # 80001664 <uvmfree>
    return 0;
    80001c32:	4481                	li	s1,0
    80001c34:	b7d5                	j	80001c18 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	040005b7          	lui	a1,0x4000
    80001c3e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c40:	05b2                	slli	a1,a1,0xc
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	756080e7          	jalr	1878(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c4c:	4581                	li	a1,0
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	a14080e7          	jalr	-1516(ra) # 80001664 <uvmfree>
    return 0;
    80001c58:	4481                	li	s1,0
    80001c5a:	bf7d                	j	80001c18 <proc_pagetable+0x58>

0000000080001c5c <proc_freepagetable>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	84aa                	mv	s1,a0
    80001c6a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c6c:	4681                	li	a3,0
    80001c6e:	4605                	li	a2,1
    80001c70:	040005b7          	lui	a1,0x4000
    80001c74:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c76:	05b2                	slli	a1,a1,0xc
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	722080e7          	jalr	1826(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c80:	4681                	li	a3,0
    80001c82:	4605                	li	a2,1
    80001c84:	020005b7          	lui	a1,0x2000
    80001c88:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c8a:	05b6                	slli	a1,a1,0xd
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	70c080e7          	jalr	1804(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001c96:	85ca                	mv	a1,s2
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	9ca080e7          	jalr	-1590(ra) # 80001664 <uvmfree>
}
    80001ca2:	60e2                	ld	ra,24(sp)
    80001ca4:	6442                	ld	s0,16(sp)
    80001ca6:	64a2                	ld	s1,8(sp)
    80001ca8:	6902                	ld	s2,0(sp)
    80001caa:	6105                	addi	sp,sp,32
    80001cac:	8082                	ret

0000000080001cae <freeproc>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	1000                	addi	s0,sp,32
    80001cb8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cba:	7528                	ld	a0,104(a0)
    80001cbc:	c509                	beqz	a0,80001cc6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	da2080e7          	jalr	-606(ra) # 80000a60 <kfree>
  p->trapframe = 0;
    80001cc6:	0604b423          	sd	zero,104(s1)
  if(p->alarm_trapframe)
    80001cca:	7c88                	ld	a0,56(s1)
    80001ccc:	c509                	beqz	a0,80001cd6 <freeproc+0x28>
    kfree((void*)p->alarm_trapframe);
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	d92080e7          	jalr	-622(ra) # 80000a60 <kfree>
  p->alarm_trapframe = 0;
    80001cd6:	0204bc23          	sd	zero,56(s1)
  if(p->pagetable)
    80001cda:	70a8                	ld	a0,96(s1)
    80001cdc:	c511                	beqz	a0,80001ce8 <freeproc+0x3a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cde:	6cac                	ld	a1,88(s1)
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	f7c080e7          	jalr	-132(ra) # 80001c5c <proc_freepagetable>
  p->pagetable = 0;
    80001ce8:	0604b023          	sd	zero,96(s1)
  p->sz = 0;
    80001cec:	0404bc23          	sd	zero,88(s1)
  p->pid = 0;
    80001cf0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cf4:	0404b423          	sd	zero,72(s1)
  p->name[0] = 0;
    80001cf8:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001cfc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d00:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d04:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d08:	0004ac23          	sw	zero,24(s1)
  p->alarm_interval = 0;
    80001d0c:	2004a423          	sw	zero,520(s1)
  p->alarm_goingoff = 0;
    80001d10:	0404a023          	sw	zero,64(s1)
  p->alarm_ticks = 0;
    80001d14:	2004ac23          	sw	zero,536(s1)
  p->alarm_handler = 0;  
    80001d18:	2004b823          	sd	zero,528(s1)
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <allocproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d32:	0022f497          	auipc	s1,0x22f
    80001d36:	4fe48493          	addi	s1,s1,1278 # 80231230 <proc>
    80001d3a:	00238917          	auipc	s2,0x238
    80001d3e:	cf690913          	addi	s2,s2,-778 # 80239a30 <mlfq_q>
    acquire(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	fc8080e7          	jalr	-56(ra) # 80000d0c <acquire>
    if(p->state == UNUSED) {
    80001d4c:	4c9c                	lw	a5,24(s1)
    80001d4e:	cf81                	beqz	a5,80001d66 <allocproc+0x40>
      release(&p->lock);
    80001d50:	8526                	mv	a0,s1
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	06e080e7          	jalr	110(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d5a:	22048493          	addi	s1,s1,544
    80001d5e:	ff2492e3          	bne	s1,s2,80001d42 <allocproc+0x1c>
  return 0;
    80001d62:	4481                	li	s1,0
    80001d64:	a05d                	j	80001e0a <allocproc+0xe4>
  p->pid = allocpid();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	e14080e7          	jalr	-492(ra) # 80001b7a <allocpid>
    80001d6e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d70:	4785                	li	a5,1
    80001d72:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	e70080e7          	jalr	-400(ra) # 80000be4 <kalloc>
    80001d7c:	892a                	mv	s2,a0
    80001d7e:	f4a8                	sd	a0,104(s1)
    80001d80:	cd41                	beqz	a0,80001e18 <allocproc+0xf2>
  if((p->alarm_trapframe = (struct trapframe *)kalloc()) == 0){
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	e62080e7          	jalr	-414(ra) # 80000be4 <kalloc>
    80001d8a:	892a                	mv	s2,a0
    80001d8c:	fc88                	sd	a0,56(s1)
    80001d8e:	cd41                	beqz	a0,80001e26 <allocproc+0x100>
  p->alarm_goingoff = 0;
    80001d90:	0404a023          	sw	zero,64(s1)
  p->alarm_interval = 0;
    80001d94:	2004a423          	sw	zero,520(s1)
  p->alarm_ticks = 0;
    80001d98:	2004ac23          	sw	zero,536(s1)
  p->alarm_handler = 0;
    80001d9c:	2004b823          	sd	zero,528(s1)
  p->pagetable = proc_pagetable(p);
    80001da0:	8526                	mv	a0,s1
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	e1e080e7          	jalr	-482(ra) # 80001bc0 <proc_pagetable>
    80001daa:	892a                	mv	s2,a0
    80001dac:	f0a8                	sd	a0,96(s1)
  if(p->pagetable == 0){
    80001dae:	c159                	beqz	a0,80001e34 <allocproc+0x10e>
  memset(&p->context, 0, sizeof(p->context));
    80001db0:	07000613          	li	a2,112
    80001db4:	4581                	li	a1,0
    80001db6:	07048513          	addi	a0,s1,112
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	04e080e7          	jalr	78(ra) # 80000e08 <memset>
  p->context.ra = (uint64)forkret;
    80001dc2:	00000797          	auipc	a5,0x0
    80001dc6:	d7278793          	addi	a5,a5,-654 # 80001b34 <forkret>
    80001dca:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dcc:	68bc                	ld	a5,80(s1)
    80001dce:	6705                	lui	a4,0x1
    80001dd0:	97ba                	add	a5,a5,a4
    80001dd2:	fcbc                	sd	a5,120(s1)
  p->in_time = ticks;
    80001dd4:	00007797          	auipc	a5,0x7
    80001dd8:	dbc7a783          	lw	a5,-580(a5) # 80008b90 <ticks>
    80001ddc:	16f4ac23          	sw	a5,376(s1)
  p->ctime = ticks;
    80001de0:	16f4ae23          	sw	a5,380(s1)
  p->sleep_ticks = 0;
    80001de4:	1804b423          	sd	zero,392(s1)
  p->run_ticks = 0;
    80001de8:	1804b823          	sd	zero,400(s1)
  p->priority = 0;
    80001dec:	1804bc23          	sd	zero,408(s1)
  p->no_sched = 0;
    80001df0:	1a04b023          	sd	zero,416(s1)
  p->rtime = 0;
    80001df4:	1804a023          	sw	zero,384(s1)
  p->etime = 0;
    80001df8:	1804a223          	sw	zero,388(s1)
  p->def_pri = 60;
    80001dfc:	03c00793          	li	a5,60
    80001e00:	1af4b423          	sd	a5,424(s1)
  p->tickets = 1;
    80001e04:	4785                	li	a5,1
    80001e06:	1af4b823          	sd	a5,432(s1)
}
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	60e2                	ld	ra,24(sp)
    80001e0e:	6442                	ld	s0,16(sp)
    80001e10:	64a2                	ld	s1,8(sp)
    80001e12:	6902                	ld	s2,0(sp)
    80001e14:	6105                	addi	sp,sp,32
    80001e16:	8082                	ret
    release(&p->lock);
    80001e18:	8526                	mv	a0,s1
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	fa6080e7          	jalr	-90(ra) # 80000dc0 <release>
    return 0;
    80001e22:	84ca                	mv	s1,s2
    80001e24:	b7dd                	j	80001e0a <allocproc+0xe4>
    release(&p->lock);
    80001e26:	8526                	mv	a0,s1
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	f98080e7          	jalr	-104(ra) # 80000dc0 <release>
    return 0;
    80001e30:	84ca                	mv	s1,s2
    80001e32:	bfe1                	j	80001e0a <allocproc+0xe4>
    freeproc(p);
    80001e34:	8526                	mv	a0,s1
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	e78080e7          	jalr	-392(ra) # 80001cae <freeproc>
    release(&p->lock);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	f80080e7          	jalr	-128(ra) # 80000dc0 <release>
    return 0;
    80001e48:	84ca                	mv	s1,s2
    80001e4a:	b7c1                	j	80001e0a <allocproc+0xe4>

0000000080001e4c <update_time>:
{
    80001e4c:	7179                	addi	sp,sp,-48
    80001e4e:	f406                	sd	ra,40(sp)
    80001e50:	f022                	sd	s0,32(sp)
    80001e52:	ec26                	sd	s1,24(sp)
    80001e54:	e84a                	sd	s2,16(sp)
    80001e56:	e44e                	sd	s3,8(sp)
    80001e58:	e052                	sd	s4,0(sp)
    80001e5a:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001e5c:	0022f497          	auipc	s1,0x22f
    80001e60:	3d448493          	addi	s1,s1,980 # 80231230 <proc>
    if (p->state == RUNNING)
    80001e64:	4991                	li	s3,4
    if (p->state == SLEEPING)
    80001e66:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    80001e68:	00238917          	auipc	s2,0x238
    80001e6c:	bc890913          	addi	s2,s2,-1080 # 80239a30 <mlfq_q>
    80001e70:	a025                	j	80001e98 <update_time+0x4c>
      p->rtime++;
    80001e72:	1804a783          	lw	a5,384(s1)
    80001e76:	2785                	addiw	a5,a5,1
    80001e78:	18f4a023          	sw	a5,384(s1)
      p->run_ticks++;
    80001e7c:	1904b783          	ld	a5,400(s1)
    80001e80:	0785                	addi	a5,a5,1
    80001e82:	18f4b823          	sd	a5,400(s1)
    release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	f38080e7          	jalr	-200(ra) # 80000dc0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e90:	22048493          	addi	s1,s1,544
    80001e94:	03248263          	beq	s1,s2,80001eb8 <update_time+0x6c>
    acquire(&p->lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e72080e7          	jalr	-398(ra) # 80000d0c <acquire>
    if (p->state == RUNNING)
    80001ea2:	4c9c                	lw	a5,24(s1)
    80001ea4:	fd3787e3          	beq	a5,s3,80001e72 <update_time+0x26>
    if (p->state == SLEEPING)
    80001ea8:	fd479fe3          	bne	a5,s4,80001e86 <update_time+0x3a>
      p->sleep_ticks++;
    80001eac:	1884b783          	ld	a5,392(s1)
    80001eb0:	0785                	addi	a5,a5,1
    80001eb2:	18f4b423          	sd	a5,392(s1)
    80001eb6:	bfc1                	j	80001e86 <update_time+0x3a>
}
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret

0000000080001ec8 <userinit>:
{
    80001ec8:	1101                	addi	sp,sp,-32
    80001eca:	ec06                	sd	ra,24(sp)
    80001ecc:	e822                	sd	s0,16(sp)
    80001ece:	e426                	sd	s1,8(sp)
    80001ed0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	e54080e7          	jalr	-428(ra) # 80001d26 <allocproc>
    80001eda:	84aa                	mv	s1,a0
  initproc = p;
    80001edc:	00007797          	auipc	a5,0x7
    80001ee0:	caa7b623          	sd	a0,-852(a5) # 80008b88 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ee4:	03400613          	li	a2,52
    80001ee8:	00007597          	auipc	a1,0x7
    80001eec:	c1858593          	addi	a1,a1,-1000 # 80008b00 <initcode>
    80001ef0:	7128                	ld	a0,96(a0)
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	59a080e7          	jalr	1434(ra) # 8000148c <uvmfirst>
  p->sz = PGSIZE;
    80001efa:	6785                	lui	a5,0x1
    80001efc:	ecbc                	sd	a5,88(s1)
  p->trapframe->epc = 0;      // user program counter
    80001efe:	74b8                	ld	a4,104(s1)
    80001f00:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f04:	74b8                	ld	a4,104(s1)
    80001f06:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f08:	4641                	li	a2,16
    80001f0a:	00006597          	auipc	a1,0x6
    80001f0e:	32e58593          	addi	a1,a1,814 # 80008238 <digits+0x1f8>
    80001f12:	16848513          	addi	a0,s1,360
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	03c080e7          	jalr	60(ra) # 80000f52 <safestrcpy>
  p->cwd = namei("/");
    80001f1e:	00006517          	auipc	a0,0x6
    80001f22:	32a50513          	addi	a0,a0,810 # 80008248 <digits+0x208>
    80001f26:	00003097          	auipc	ra,0x3
    80001f2a:	afc080e7          	jalr	-1284(ra) # 80004a22 <namei>
    80001f2e:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001f32:	478d                	li	a5,3
    80001f34:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	e88080e7          	jalr	-376(ra) # 80000dc0 <release>
}
    80001f40:	60e2                	ld	ra,24(sp)
    80001f42:	6442                	ld	s0,16(sp)
    80001f44:	64a2                	ld	s1,8(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret

0000000080001f4a <growproc>:
{
    80001f4a:	1101                	addi	sp,sp,-32
    80001f4c:	ec06                	sd	ra,24(sp)
    80001f4e:	e822                	sd	s0,16(sp)
    80001f50:	e426                	sd	s1,8(sp)
    80001f52:	e04a                	sd	s2,0(sp)
    80001f54:	1000                	addi	s0,sp,32
    80001f56:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f58:	00000097          	auipc	ra,0x0
    80001f5c:	ba4080e7          	jalr	-1116(ra) # 80001afc <myproc>
    80001f60:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f62:	6d2c                	ld	a1,88(a0)
  if(n > 0){
    80001f64:	01204c63          	bgtz	s2,80001f7c <growproc+0x32>
  } else if(n < 0){
    80001f68:	02094663          	bltz	s2,80001f94 <growproc+0x4a>
  p->sz = sz;
    80001f6c:	ecac                	sd	a1,88(s1)
  return 0;
    80001f6e:	4501                	li	a0,0
}
    80001f70:	60e2                	ld	ra,24(sp)
    80001f72:	6442                	ld	s0,16(sp)
    80001f74:	64a2                	ld	s1,8(sp)
    80001f76:	6902                	ld	s2,0(sp)
    80001f78:	6105                	addi	sp,sp,32
    80001f7a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f7c:	4691                	li	a3,4
    80001f7e:	00b90633          	add	a2,s2,a1
    80001f82:	7128                	ld	a0,96(a0)
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	5c2080e7          	jalr	1474(ra) # 80001546 <uvmalloc>
    80001f8c:	85aa                	mv	a1,a0
    80001f8e:	fd79                	bnez	a0,80001f6c <growproc+0x22>
      return -1;
    80001f90:	557d                	li	a0,-1
    80001f92:	bff9                	j	80001f70 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f94:	00b90633          	add	a2,s2,a1
    80001f98:	7128                	ld	a0,96(a0)
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	564080e7          	jalr	1380(ra) # 800014fe <uvmdealloc>
    80001fa2:	85aa                	mv	a1,a0
    80001fa4:	b7e1                	j	80001f6c <growproc+0x22>

0000000080001fa6 <fork>:
{
    80001fa6:	7139                	addi	sp,sp,-64
    80001fa8:	fc06                	sd	ra,56(sp)
    80001faa:	f822                	sd	s0,48(sp)
    80001fac:	f426                	sd	s1,40(sp)
    80001fae:	f04a                	sd	s2,32(sp)
    80001fb0:	ec4e                	sd	s3,24(sp)
    80001fb2:	e852                	sd	s4,16(sp)
    80001fb4:	e456                	sd	s5,8(sp)
    80001fb6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	b44080e7          	jalr	-1212(ra) # 80001afc <myproc>
    80001fc0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	d64080e7          	jalr	-668(ra) # 80001d26 <allocproc>
    80001fca:	10050c63          	beqz	a0,800020e2 <fork+0x13c>
    80001fce:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fd0:	058ab603          	ld	a2,88(s5)
    80001fd4:	712c                	ld	a1,96(a0)
    80001fd6:	060ab503          	ld	a0,96(s5)
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	6c4080e7          	jalr	1732(ra) # 8000169e <uvmcopy>
    80001fe2:	04054863          	bltz	a0,80002032 <fork+0x8c>
  np->sz = p->sz;
    80001fe6:	058ab783          	ld	a5,88(s5)
    80001fea:	04fa3c23          	sd	a5,88(s4)
  *(np->trapframe) = *(p->trapframe);
    80001fee:	068ab683          	ld	a3,104(s5)
    80001ff2:	87b6                	mv	a5,a3
    80001ff4:	068a3703          	ld	a4,104(s4)
    80001ff8:	12068693          	addi	a3,a3,288
    80001ffc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002000:	6788                	ld	a0,8(a5)
    80002002:	6b8c                	ld	a1,16(a5)
    80002004:	6f90                	ld	a2,24(a5)
    80002006:	01073023          	sd	a6,0(a4)
    8000200a:	e708                	sd	a0,8(a4)
    8000200c:	eb0c                	sd	a1,16(a4)
    8000200e:	ef10                	sd	a2,24(a4)
    80002010:	02078793          	addi	a5,a5,32
    80002014:	02070713          	addi	a4,a4,32
    80002018:	fed792e3          	bne	a5,a3,80001ffc <fork+0x56>
  np->trapframe->a0 = 0;
    8000201c:	068a3783          	ld	a5,104(s4)
    80002020:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002024:	0e0a8493          	addi	s1,s5,224
    80002028:	0e0a0913          	addi	s2,s4,224
    8000202c:	160a8993          	addi	s3,s5,352
    80002030:	a00d                	j	80002052 <fork+0xac>
    freeproc(np);
    80002032:	8552                	mv	a0,s4
    80002034:	00000097          	auipc	ra,0x0
    80002038:	c7a080e7          	jalr	-902(ra) # 80001cae <freeproc>
    release(&np->lock);
    8000203c:	8552                	mv	a0,s4
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	d82080e7          	jalr	-638(ra) # 80000dc0 <release>
    return -1;
    80002046:	597d                	li	s2,-1
    80002048:	a059                	j	800020ce <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    8000204a:	04a1                	addi	s1,s1,8
    8000204c:	0921                	addi	s2,s2,8
    8000204e:	01348b63          	beq	s1,s3,80002064 <fork+0xbe>
    if(p->ofile[i])
    80002052:	6088                	ld	a0,0(s1)
    80002054:	d97d                	beqz	a0,8000204a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002056:	00003097          	auipc	ra,0x3
    8000205a:	062080e7          	jalr	98(ra) # 800050b8 <filedup>
    8000205e:	00a93023          	sd	a0,0(s2)
    80002062:	b7e5                	j	8000204a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002064:	160ab503          	ld	a0,352(s5)
    80002068:	00002097          	auipc	ra,0x2
    8000206c:	1d0080e7          	jalr	464(ra) # 80004238 <idup>
    80002070:	16aa3023          	sd	a0,352(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002074:	4641                	li	a2,16
    80002076:	168a8593          	addi	a1,s5,360
    8000207a:	168a0513          	addi	a0,s4,360
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	ed4080e7          	jalr	-300(ra) # 80000f52 <safestrcpy>
  pid = np->pid;
    80002086:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    8000208a:	8552                	mv	a0,s4
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	d34080e7          	jalr	-716(ra) # 80000dc0 <release>
  acquire(&wait_lock);
    80002094:	0022f497          	auipc	s1,0x22f
    80002098:	d8448493          	addi	s1,s1,-636 # 80230e18 <wait_lock>
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	c6e080e7          	jalr	-914(ra) # 80000d0c <acquire>
  np->parent = p;
    800020a6:	055a3423          	sd	s5,72(s4)
  release(&wait_lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	d14080e7          	jalr	-748(ra) # 80000dc0 <release>
  acquire(&np->lock);
    800020b4:	8552                	mv	a0,s4
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	c56080e7          	jalr	-938(ra) # 80000d0c <acquire>
  np->state = RUNNABLE;
    800020be:	478d                	li	a5,3
    800020c0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020c4:	8552                	mv	a0,s4
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	cfa080e7          	jalr	-774(ra) # 80000dc0 <release>
}
    800020ce:	854a                	mv	a0,s2
    800020d0:	70e2                	ld	ra,56(sp)
    800020d2:	7442                	ld	s0,48(sp)
    800020d4:	74a2                	ld	s1,40(sp)
    800020d6:	7902                	ld	s2,32(sp)
    800020d8:	69e2                	ld	s3,24(sp)
    800020da:	6a42                	ld	s4,16(sp)
    800020dc:	6aa2                	ld	s5,8(sp)
    800020de:	6121                	addi	sp,sp,64
    800020e0:	8082                	ret
    return -1;
    800020e2:	597d                	li	s2,-1
    800020e4:	b7ed                	j	800020ce <fork+0x128>

00000000800020e6 <round_robin>:
{
    800020e6:	7139                	addi	sp,sp,-64
    800020e8:	fc06                	sd	ra,56(sp)
    800020ea:	f822                	sd	s0,48(sp)
    800020ec:	f426                	sd	s1,40(sp)
    800020ee:	f04a                	sd	s2,32(sp)
    800020f0:	ec4e                	sd	s3,24(sp)
    800020f2:	e852                	sd	s4,16(sp)
    800020f4:	e456                	sd	s5,8(sp)
    800020f6:	e05a                	sd	s6,0(sp)
    800020f8:	0080                	addi	s0,sp,64
    800020fa:	8792                	mv	a5,tp
  int id = r_tp();
    800020fc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020fe:	00779a93          	slli	s5,a5,0x7
    80002102:	0022f717          	auipc	a4,0x22f
    80002106:	cfe70713          	addi	a4,a4,-770 # 80230e00 <pid_lock>
    8000210a:	9756                	add	a4,a4,s5
    8000210c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002110:	0022f717          	auipc	a4,0x22f
    80002114:	d2870713          	addi	a4,a4,-728 # 80230e38 <cpus+0x8>
    80002118:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000211a:	498d                	li	s3,3
        p->state = RUNNING;
    8000211c:	4b11                	li	s6,4
        c->proc = p;
    8000211e:	079e                	slli	a5,a5,0x7
    80002120:	0022fa17          	auipc	s4,0x22f
    80002124:	ce0a0a13          	addi	s4,s4,-800 # 80230e00 <pid_lock>
    80002128:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000212a:	00238917          	auipc	s2,0x238
    8000212e:	90690913          	addi	s2,s2,-1786 # 80239a30 <mlfq_q>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002132:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002136:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000213a:	10079073          	csrw	sstatus,a5
    8000213e:	0022f497          	auipc	s1,0x22f
    80002142:	0f248493          	addi	s1,s1,242 # 80231230 <proc>
    80002146:	a811                	j	8000215a <round_robin+0x74>
      release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	c76080e7          	jalr	-906(ra) # 80000dc0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002152:	22048493          	addi	s1,s1,544
    80002156:	fd248ee3          	beq	s1,s2,80002132 <round_robin+0x4c>
      acquire(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	bb0080e7          	jalr	-1104(ra) # 80000d0c <acquire>
      if (p->state == RUNNABLE)
    80002164:	4c9c                	lw	a5,24(s1)
    80002166:	ff3791e3          	bne	a5,s3,80002148 <round_robin+0x62>
        p->state = RUNNING;
    8000216a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000216e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002172:	07048593          	addi	a1,s1,112
    80002176:	8556                	mv	a0,s5
    80002178:	00001097          	auipc	ra,0x1
    8000217c:	d9c080e7          	jalr	-612(ra) # 80002f14 <swtch>
        c->proc = 0;
    80002180:	020a3823          	sd	zero,48(s4)
    80002184:	b7d1                	j	80002148 <round_robin+0x62>

0000000080002186 <scheduler>:
{
    80002186:	1141                	addi	sp,sp,-16
    80002188:	e406                	sd	ra,8(sp)
    8000218a:	e022                	sd	s0,0(sp)
    8000218c:	0800                	addi	s0,sp,16
  round_robin();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	f58080e7          	jalr	-168(ra) # 800020e6 <round_robin>

0000000080002196 <FCFS>:
{
    80002196:	715d                	addi	sp,sp,-80
    80002198:	e486                	sd	ra,72(sp)
    8000219a:	e0a2                	sd	s0,64(sp)
    8000219c:	fc26                	sd	s1,56(sp)
    8000219e:	f84a                	sd	s2,48(sp)
    800021a0:	f44e                	sd	s3,40(sp)
    800021a2:	f052                	sd	s4,32(sp)
    800021a4:	ec56                	sd	s5,24(sp)
    800021a6:	e85a                	sd	s6,16(sp)
    800021a8:	e45e                	sd	s7,8(sp)
    800021aa:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ac:	8792                	mv	a5,tp
  int id = r_tp();
    800021ae:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021b0:	00779693          	slli	a3,a5,0x7
    800021b4:	0022f717          	auipc	a4,0x22f
    800021b8:	c4c70713          	addi	a4,a4,-948 # 80230e00 <pid_lock>
    800021bc:	9736                	add	a4,a4,a3
    800021be:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &first_proc->context);
    800021c2:	0022f717          	auipc	a4,0x22f
    800021c6:	c7670713          	addi	a4,a4,-906 # 80230e38 <cpus+0x8>
    800021ca:	00e68bb3          	add	s7,a3,a4
    first_proc = 0;
    800021ce:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800021d0:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800021d2:	00238a17          	auipc	s4,0x238
    800021d6:	85ea0a13          	addi	s4,s4,-1954 # 80239a30 <mlfq_q>
        c->proc = first_proc;
    800021da:	0022fb17          	auipc	s6,0x22f
    800021de:	c26b0b13          	addi	s6,s6,-986 # 80230e00 <pid_lock>
    800021e2:	9b36                	add	s6,s6,a3
    800021e4:	a889                	j	80002236 <FCFS+0xa0>
        if (first_proc == 0)
    800021e6:	00090d63          	beqz	s2,80002200 <FCFS+0x6a>
        else if (p->in_time < first_proc->in_time)
    800021ea:	1784a703          	lw	a4,376(s1)
    800021ee:	17892783          	lw	a5,376(s2)
    800021f2:	02f75563          	bge	a4,a5,8000221c <FCFS+0x86>
          release(&first_proc->lock);
    800021f6:	854a                	mv	a0,s2
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	bc8080e7          	jalr	-1080(ra) # 80000dc0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002200:	22048793          	addi	a5,s1,544
    80002204:	05478663          	beq	a5,s4,80002250 <FCFS+0xba>
    80002208:	8926                	mv	s2,s1
    8000220a:	84be                	mv	s1,a5
      acquire(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	afe080e7          	jalr	-1282(ra) # 80000d0c <acquire>
      if (p->state == RUNNABLE)
    80002216:	4c9c                	lw	a5,24(s1)
    80002218:	fd3787e3          	beq	a5,s3,800021e6 <FCFS+0x50>
      if (first_proc != p)
    8000221c:	fe9902e3          	beq	s2,s1,80002200 <FCFS+0x6a>
        release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	b9e080e7          	jalr	-1122(ra) # 80000dc0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000222a:	22048493          	addi	s1,s1,544
    8000222e:	fd449fe3          	bne	s1,s4,8000220c <FCFS+0x76>
    if (first_proc != 0)
    80002232:	00091e63          	bnez	s2,8000224e <FCFS+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002236:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000223e:	10079073          	csrw	sstatus,a5
    first_proc = 0;
    80002242:	8956                	mv	s2,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002244:	0022f497          	auipc	s1,0x22f
    80002248:	fec48493          	addi	s1,s1,-20 # 80231230 <proc>
    8000224c:	b7c1                	j	8000220c <FCFS+0x76>
    8000224e:	84ca                	mv	s1,s2
      if (first_proc->state == RUNNABLE)
    80002250:	4c9c                	lw	a5,24(s1)
    80002252:	01379f63          	bne	a5,s3,80002270 <FCFS+0xda>
        first_proc->state = RUNNING;
    80002256:	4791                	li	a5,4
    80002258:	cc9c                	sw	a5,24(s1)
        c->proc = first_proc;
    8000225a:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &first_proc->context);
    8000225e:	07048593          	addi	a1,s1,112
    80002262:	855e                	mv	a0,s7
    80002264:	00001097          	auipc	ra,0x1
    80002268:	cb0080e7          	jalr	-848(ra) # 80002f14 <swtch>
        c->proc = 0;
    8000226c:	020b3823          	sd	zero,48(s6)
      release(&first_proc->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	b4e080e7          	jalr	-1202(ra) # 80000dc0 <release>
    8000227a:	bf75                	j	80002236 <FCFS+0xa0>

000000008000227c <niceness>:
{
    8000227c:	1141                	addi	sp,sp,-16
    8000227e:	e422                	sd	s0,8(sp)
    80002280:	0800                	addi	s0,sp,16
  if (p->priority == 1 || p->no_sched == 0)
    80002282:	19853683          	ld	a3,408(a0)
    80002286:	4705                	li	a4,1
    80002288:	02e68663          	beq	a3,a4,800022b4 <niceness+0x38>
    8000228c:	87aa                	mv	a5,a0
    8000228e:	1a053703          	ld	a4,416(a0)
    return 5;
    80002292:	4515                	li	a0,5
  if (p->priority == 1 || p->no_sched == 0)
    80002294:	cf09                	beqz	a4,800022ae <niceness+0x32>
    int val = (int)((p->sleep_ticks / (p->run_ticks + p->sleep_ticks)) * 10);
    80002296:	1887b703          	ld	a4,392(a5)
    8000229a:	1907b783          	ld	a5,400(a5)
    8000229e:	97ba                	add	a5,a5,a4
    800022a0:	02f757b3          	divu	a5,a4,a5
    800022a4:	0027951b          	slliw	a0,a5,0x2
    800022a8:	9d3d                	addw	a0,a0,a5
    800022aa:	0015151b          	slliw	a0,a0,0x1
}
    800022ae:	6422                	ld	s0,8(sp)
    800022b0:	0141                	addi	sp,sp,16
    800022b2:	8082                	ret
    return 5;
    800022b4:	4515                	li	a0,5
    800022b6:	bfe5                	j	800022ae <niceness+0x32>

00000000800022b8 <PBS>:
{
    800022b8:	7159                	addi	sp,sp,-112
    800022ba:	f486                	sd	ra,104(sp)
    800022bc:	f0a2                	sd	s0,96(sp)
    800022be:	eca6                	sd	s1,88(sp)
    800022c0:	e8ca                	sd	s2,80(sp)
    800022c2:	e4ce                	sd	s3,72(sp)
    800022c4:	e0d2                	sd	s4,64(sp)
    800022c6:	fc56                	sd	s5,56(sp)
    800022c8:	f85a                	sd	s6,48(sp)
    800022ca:	f45e                	sd	s7,40(sp)
    800022cc:	f062                	sd	s8,32(sp)
    800022ce:	ec66                	sd	s9,24(sp)
    800022d0:	e86a                	sd	s10,16(sp)
    800022d2:	e46e                	sd	s11,8(sp)
    800022d4:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d6:	8792                	mv	a5,tp
  int id = r_tp();
    800022d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022da:	00779d13          	slli	s10,a5,0x7
    800022de:	0022f717          	auipc	a4,0x22f
    800022e2:	b2270713          	addi	a4,a4,-1246 # 80230e00 <pid_lock>
    800022e6:	976a                	add	a4,a4,s10
    800022e8:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &top_pri->context);
    800022ec:	0022f717          	auipc	a4,0x22f
    800022f0:	b4c70713          	addi	a4,a4,-1204 # 80230e38 <cpus+0x8>
    800022f4:	9d3a                	add	s10,s10,a4
    for (p = proc; p < &proc[NPROC]; p++)
    800022f6:	00237a17          	auipc	s4,0x237
    800022fa:	73aa0a13          	addi	s4,s4,1850 # 80239a30 <mlfq_q>
        dp = max(0, min(p->def_pri - nice + 5, 100));
    800022fe:	06400b13          	li	s6,100
      c->proc = top_pri;
    80002302:	079e                	slli	a5,a5,0x7
    80002304:	0022fc97          	auipc	s9,0x22f
    80002308:	afcc8c93          	addi	s9,s9,-1284 # 80230e00 <pid_lock>
    8000230c:	9cbe                	add	s9,s9,a5
    8000230e:	a0d9                	j	800023d4 <PBS+0x11c>
        nice = niceness(p);
    80002310:	8526                	mv	a0,s1
    80002312:	00000097          	auipc	ra,0x0
    80002316:	f6a080e7          	jalr	-150(ra) # 8000227c <niceness>
        dp = max(0, min(p->def_pri - nice + 5, 100));
    8000231a:	1a84b783          	ld	a5,424(s1)
    8000231e:	0795                	addi	a5,a5,5
    80002320:	40a78533          	sub	a0,a5,a0
    80002324:	00ab7363          	bgeu	s6,a0,8000232a <PBS+0x72>
    80002328:	855a                	mv	a0,s6
    8000232a:	00050d9b          	sext.w	s11,a0
        if (top_pri == 0)
    8000232e:	02090963          	beqz	s2,80002360 <PBS+0xa8>
        else if (dp_min > dp)
    80002332:	035dc263          	blt	s11,s5,80002356 <PBS+0x9e>
        else if (dp_min == dp)
    80002336:	055d9463          	bne	s11,s5,8000237e <PBS+0xc6>
          if (top_pri->no_sched == p->no_sched && top_pri->ctime < p->ctime)
    8000233a:	1a093703          	ld	a4,416(s2)
    8000233e:	1a04b783          	ld	a5,416(s1)
    80002342:	0af70a63          	beq	a4,a5,800023f6 <PBS+0x13e>
          else if (top_pri->no_sched > p->no_sched)
    80002346:	02e7fc63          	bgeu	a5,a4,8000237e <PBS+0xc6>
            release(&top_pri->lock);
    8000234a:	854a                	mv	a0,s2
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	a74080e7          	jalr	-1420(ra) # 80000dc0 <release>
            top_pri = p;
    80002354:	a031                	j	80002360 <PBS+0xa8>
          release(&top_pri->lock);
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	a68080e7          	jalr	-1432(ra) # 80000dc0 <release>
      if (top_pri != p)
    80002360:	8aee                	mv	s5,s11
    for (p = proc; p < &proc[NPROC]; p++)
    80002362:	22048793          	addi	a5,s1,544
    80002366:	03478a63          	beq	a5,s4,8000239a <PBS+0xe2>
    8000236a:	8926                	mv	s2,s1
    8000236c:	84be                	mv	s1,a5
      acquire(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	99c080e7          	jalr	-1636(ra) # 80000d0c <acquire>
      if (p->state == RUNNABLE)
    80002378:	4c9c                	lw	a5,24(s1)
    8000237a:	f9378be3          	beq	a5,s3,80002310 <PBS+0x58>
      if (top_pri != p)
    8000237e:	fe9902e3          	beq	s2,s1,80002362 <PBS+0xaa>
        release(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	a3c080e7          	jalr	-1476(ra) # 80000dc0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000238c:	22048493          	addi	s1,s1,544
    80002390:	fd449fe3          	bne	s1,s4,8000236e <PBS+0xb6>
    if (top_pri)
    80002394:	04090463          	beqz	s2,800023dc <PBS+0x124>
    80002398:	84ca                	mv	s1,s2
      top_pri->state = RUNNING;
    8000239a:	4791                	li	a5,4
    8000239c:	cc9c                	sw	a5,24(s1)
      c->proc = top_pri;
    8000239e:	029cb823          	sd	s1,48(s9)
      swtch(&c->context, &top_pri->context);
    800023a2:	07048593          	addi	a1,s1,112
    800023a6:	856a                	mv	a0,s10
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	b6c080e7          	jalr	-1172(ra) # 80002f14 <swtch>
      c->proc = 0;
    800023b0:	020cb823          	sd	zero,48(s9)
      top_pri->sleep_ticks = 0;
    800023b4:	1804b423          	sd	zero,392(s1)
      top_pri->run_ticks = 0;
    800023b8:	1804b823          	sd	zero,400(s1)
      top_pri->priority = 0;
    800023bc:	1804bc23          	sd	zero,408(s1)
      top_pri->no_sched++;
    800023c0:	1a04b783          	ld	a5,416(s1)
    800023c4:	0785                	addi	a5,a5,1
    800023c6:	1af4b023          	sd	a5,416(s1)
      release(&top_pri->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	9f4080e7          	jalr	-1548(ra) # 80000dc0 <release>
    dp_min = 101;
    800023d4:	06500c13          	li	s8,101
    top_pri = 0;
    800023d8:	4b81                	li	s7,0
      if (p->state == RUNNABLE)
    800023da:	498d                	li	s3,3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023e4:	10079073          	csrw	sstatus,a5
    dp_min = 101;
    800023e8:	8ae2                	mv	s5,s8
    top_pri = 0;
    800023ea:	895e                	mv	s2,s7
    for (p = proc; p < &proc[NPROC]; p++)
    800023ec:	0022f497          	auipc	s1,0x22f
    800023f0:	e4448493          	addi	s1,s1,-444 # 80231230 <proc>
    800023f4:	bfad                	j	8000236e <PBS+0xb6>
          if (top_pri->no_sched == p->no_sched && top_pri->ctime < p->ctime)
    800023f6:	17c92703          	lw	a4,380(s2)
    800023fa:	17c4a783          	lw	a5,380(s1)
    800023fe:	f8f750e3          	bge	a4,a5,8000237e <PBS+0xc6>
            release(&top_pri->lock);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	9bc080e7          	jalr	-1604(ra) # 80000dc0 <release>
            top_pri = p;
    8000240c:	bf91                	j	80002360 <PBS+0xa8>

000000008000240e <sched>:
{
    8000240e:	7179                	addi	sp,sp,-48
    80002410:	f406                	sd	ra,40(sp)
    80002412:	f022                	sd	s0,32(sp)
    80002414:	ec26                	sd	s1,24(sp)
    80002416:	e84a                	sd	s2,16(sp)
    80002418:	e44e                	sd	s3,8(sp)
    8000241a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	6e0080e7          	jalr	1760(ra) # 80001afc <myproc>
    80002424:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	86c080e7          	jalr	-1940(ra) # 80000c92 <holding>
    8000242e:	c93d                	beqz	a0,800024a4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002430:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002432:	2781                	sext.w	a5,a5
    80002434:	079e                	slli	a5,a5,0x7
    80002436:	0022f717          	auipc	a4,0x22f
    8000243a:	9ca70713          	addi	a4,a4,-1590 # 80230e00 <pid_lock>
    8000243e:	97ba                	add	a5,a5,a4
    80002440:	0a87a703          	lw	a4,168(a5)
    80002444:	4785                	li	a5,1
    80002446:	06f71763          	bne	a4,a5,800024b4 <sched+0xa6>
  if(p->state == RUNNING)
    8000244a:	4c98                	lw	a4,24(s1)
    8000244c:	4791                	li	a5,4
    8000244e:	06f70b63          	beq	a4,a5,800024c4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002452:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002456:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002458:	efb5                	bnez	a5,800024d4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000245a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000245c:	0022f917          	auipc	s2,0x22f
    80002460:	9a490913          	addi	s2,s2,-1628 # 80230e00 <pid_lock>
    80002464:	2781                	sext.w	a5,a5
    80002466:	079e                	slli	a5,a5,0x7
    80002468:	97ca                	add	a5,a5,s2
    8000246a:	0ac7a983          	lw	s3,172(a5)
    8000246e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002470:	2781                	sext.w	a5,a5
    80002472:	079e                	slli	a5,a5,0x7
    80002474:	0022f597          	auipc	a1,0x22f
    80002478:	9c458593          	addi	a1,a1,-1596 # 80230e38 <cpus+0x8>
    8000247c:	95be                	add	a1,a1,a5
    8000247e:	07048513          	addi	a0,s1,112
    80002482:	00001097          	auipc	ra,0x1
    80002486:	a92080e7          	jalr	-1390(ra) # 80002f14 <swtch>
    8000248a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000248c:	2781                	sext.w	a5,a5
    8000248e:	079e                	slli	a5,a5,0x7
    80002490:	993e                	add	s2,s2,a5
    80002492:	0b392623          	sw	s3,172(s2)
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6145                	addi	sp,sp,48
    800024a2:	8082                	ret
    panic("sched p->lock");
    800024a4:	00006517          	auipc	a0,0x6
    800024a8:	dac50513          	addi	a0,a0,-596 # 80008250 <digits+0x210>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	094080e7          	jalr	148(ra) # 80000540 <panic>
    panic("sched locks");
    800024b4:	00006517          	auipc	a0,0x6
    800024b8:	dac50513          	addi	a0,a0,-596 # 80008260 <digits+0x220>
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	084080e7          	jalr	132(ra) # 80000540 <panic>
    panic("sched running");
    800024c4:	00006517          	auipc	a0,0x6
    800024c8:	dac50513          	addi	a0,a0,-596 # 80008270 <digits+0x230>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	074080e7          	jalr	116(ra) # 80000540 <panic>
    panic("sched interruptible");
    800024d4:	00006517          	auipc	a0,0x6
    800024d8:	dac50513          	addi	a0,a0,-596 # 80008280 <digits+0x240>
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	064080e7          	jalr	100(ra) # 80000540 <panic>

00000000800024e4 <yield>:
{
    800024e4:	1101                	addi	sp,sp,-32
    800024e6:	ec06                	sd	ra,24(sp)
    800024e8:	e822                	sd	s0,16(sp)
    800024ea:	e426                	sd	s1,8(sp)
    800024ec:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	60e080e7          	jalr	1550(ra) # 80001afc <myproc>
    800024f6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	814080e7          	jalr	-2028(ra) # 80000d0c <acquire>
  p->state = RUNNABLE;
    80002500:	478d                	li	a5,3
    80002502:	cc9c                	sw	a5,24(s1)
  sched();
    80002504:	00000097          	auipc	ra,0x0
    80002508:	f0a080e7          	jalr	-246(ra) # 8000240e <sched>
  release(&p->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	8b2080e7          	jalr	-1870(ra) # 80000dc0 <release>
}
    80002516:	60e2                	ld	ra,24(sp)
    80002518:	6442                	ld	s0,16(sp)
    8000251a:	64a2                	ld	s1,8(sp)
    8000251c:	6105                	addi	sp,sp,32
    8000251e:	8082                	ret

0000000080002520 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002520:	7179                	addi	sp,sp,-48
    80002522:	f406                	sd	ra,40(sp)
    80002524:	f022                	sd	s0,32(sp)
    80002526:	ec26                	sd	s1,24(sp)
    80002528:	e84a                	sd	s2,16(sp)
    8000252a:	e44e                	sd	s3,8(sp)
    8000252c:	1800                	addi	s0,sp,48
    8000252e:	89aa                	mv	s3,a0
    80002530:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	5ca080e7          	jalr	1482(ra) # 80001afc <myproc>
    8000253a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	7d0080e7          	jalr	2000(ra) # 80000d0c <acquire>
  release(lk);
    80002544:	854a                	mv	a0,s2
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	87a080e7          	jalr	-1926(ra) # 80000dc0 <release>

  // Go to sleep.
  p->chan = chan;
    8000254e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002552:	4789                	li	a5,2
    80002554:	cc9c                	sw	a5,24(s1)

  sched();
    80002556:	00000097          	auipc	ra,0x0
    8000255a:	eb8080e7          	jalr	-328(ra) # 8000240e <sched>

  // Tidy up.
  p->chan = 0;
    8000255e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	85c080e7          	jalr	-1956(ra) # 80000dc0 <release>
  acquire(lk);
    8000256c:	854a                	mv	a0,s2
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	79e080e7          	jalr	1950(ra) # 80000d0c <acquire>
}
    80002576:	70a2                	ld	ra,40(sp)
    80002578:	7402                	ld	s0,32(sp)
    8000257a:	64e2                	ld	s1,24(sp)
    8000257c:	6942                	ld	s2,16(sp)
    8000257e:	69a2                	ld	s3,8(sp)
    80002580:	6145                	addi	sp,sp,48
    80002582:	8082                	ret

0000000080002584 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002584:	7139                	addi	sp,sp,-64
    80002586:	fc06                	sd	ra,56(sp)
    80002588:	f822                	sd	s0,48(sp)
    8000258a:	f426                	sd	s1,40(sp)
    8000258c:	f04a                	sd	s2,32(sp)
    8000258e:	ec4e                	sd	s3,24(sp)
    80002590:	e852                	sd	s4,16(sp)
    80002592:	e456                	sd	s5,8(sp)
    80002594:	0080                	addi	s0,sp,64
    80002596:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002598:	0022f497          	auipc	s1,0x22f
    8000259c:	c9848493          	addi	s1,s1,-872 # 80231230 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025a0:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025a2:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800025a4:	00237917          	auipc	s2,0x237
    800025a8:	48c90913          	addi	s2,s2,1164 # 80239a30 <mlfq_q>
    800025ac:	a811                	j	800025c0 <wakeup+0x3c>
      }
      release(&p->lock);
    800025ae:	8526                	mv	a0,s1
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	810080e7          	jalr	-2032(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b8:	22048493          	addi	s1,s1,544
    800025bc:	03248663          	beq	s1,s2,800025e8 <wakeup+0x64>
    if(p != myproc()){
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	53c080e7          	jalr	1340(ra) # 80001afc <myproc>
    800025c8:	fea488e3          	beq	s1,a0,800025b8 <wakeup+0x34>
      acquire(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	73e080e7          	jalr	1854(ra) # 80000d0c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025d6:	4c9c                	lw	a5,24(s1)
    800025d8:	fd379be3          	bne	a5,s3,800025ae <wakeup+0x2a>
    800025dc:	709c                	ld	a5,32(s1)
    800025de:	fd4798e3          	bne	a5,s4,800025ae <wakeup+0x2a>
        p->state = RUNNABLE;
    800025e2:	0154ac23          	sw	s5,24(s1)
    800025e6:	b7e1                	j	800025ae <wakeup+0x2a>
    }
  }
}
    800025e8:	70e2                	ld	ra,56(sp)
    800025ea:	7442                	ld	s0,48(sp)
    800025ec:	74a2                	ld	s1,40(sp)
    800025ee:	7902                	ld	s2,32(sp)
    800025f0:	69e2                	ld	s3,24(sp)
    800025f2:	6a42                	ld	s4,16(sp)
    800025f4:	6aa2                	ld	s5,8(sp)
    800025f6:	6121                	addi	sp,sp,64
    800025f8:	8082                	ret

00000000800025fa <reparent>:
{
    800025fa:	7179                	addi	sp,sp,-48
    800025fc:	f406                	sd	ra,40(sp)
    800025fe:	f022                	sd	s0,32(sp)
    80002600:	ec26                	sd	s1,24(sp)
    80002602:	e84a                	sd	s2,16(sp)
    80002604:	e44e                	sd	s3,8(sp)
    80002606:	e052                	sd	s4,0(sp)
    80002608:	1800                	addi	s0,sp,48
    8000260a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000260c:	0022f497          	auipc	s1,0x22f
    80002610:	c2448493          	addi	s1,s1,-988 # 80231230 <proc>
      pp->parent = initproc;
    80002614:	00006a17          	auipc	s4,0x6
    80002618:	574a0a13          	addi	s4,s4,1396 # 80008b88 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000261c:	00237997          	auipc	s3,0x237
    80002620:	41498993          	addi	s3,s3,1044 # 80239a30 <mlfq_q>
    80002624:	a029                	j	8000262e <reparent+0x34>
    80002626:	22048493          	addi	s1,s1,544
    8000262a:	01348d63          	beq	s1,s3,80002644 <reparent+0x4a>
    if(pp->parent == p){
    8000262e:	64bc                	ld	a5,72(s1)
    80002630:	ff279be3          	bne	a5,s2,80002626 <reparent+0x2c>
      pp->parent = initproc;
    80002634:	000a3503          	ld	a0,0(s4)
    80002638:	e4a8                	sd	a0,72(s1)
      wakeup(initproc);
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	f4a080e7          	jalr	-182(ra) # 80002584 <wakeup>
    80002642:	b7d5                	j	80002626 <reparent+0x2c>
}
    80002644:	70a2                	ld	ra,40(sp)
    80002646:	7402                	ld	s0,32(sp)
    80002648:	64e2                	ld	s1,24(sp)
    8000264a:	6942                	ld	s2,16(sp)
    8000264c:	69a2                	ld	s3,8(sp)
    8000264e:	6a02                	ld	s4,0(sp)
    80002650:	6145                	addi	sp,sp,48
    80002652:	8082                	ret

0000000080002654 <exit>:
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	496080e7          	jalr	1174(ra) # 80001afc <myproc>
    8000266e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002670:	00006797          	auipc	a5,0x6
    80002674:	5187b783          	ld	a5,1304(a5) # 80008b88 <initproc>
    80002678:	0e050493          	addi	s1,a0,224
    8000267c:	16050913          	addi	s2,a0,352
    80002680:	02a79363          	bne	a5,a0,800026a6 <exit+0x52>
    panic("init exiting");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	c1450513          	addi	a0,a0,-1004 # 80008298 <digits+0x258>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	eb4080e7          	jalr	-332(ra) # 80000540 <panic>
      fileclose(f);
    80002694:	00003097          	auipc	ra,0x3
    80002698:	a76080e7          	jalr	-1418(ra) # 8000510a <fileclose>
      p->ofile[fd] = 0;
    8000269c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026a0:	04a1                	addi	s1,s1,8
    800026a2:	01248563          	beq	s1,s2,800026ac <exit+0x58>
    if(p->ofile[fd]){
    800026a6:	6088                	ld	a0,0(s1)
    800026a8:	f575                	bnez	a0,80002694 <exit+0x40>
    800026aa:	bfdd                	j	800026a0 <exit+0x4c>
  begin_op();
    800026ac:	00002097          	auipc	ra,0x2
    800026b0:	596080e7          	jalr	1430(ra) # 80004c42 <begin_op>
  iput(p->cwd);
    800026b4:	1609b503          	ld	a0,352(s3)
    800026b8:	00002097          	auipc	ra,0x2
    800026bc:	d78080e7          	jalr	-648(ra) # 80004430 <iput>
  end_op();
    800026c0:	00002097          	auipc	ra,0x2
    800026c4:	600080e7          	jalr	1536(ra) # 80004cc0 <end_op>
  p->cwd = 0;
    800026c8:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    800026cc:	0022e497          	auipc	s1,0x22e
    800026d0:	74c48493          	addi	s1,s1,1868 # 80230e18 <wait_lock>
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	636080e7          	jalr	1590(ra) # 80000d0c <acquire>
  reparent(p);
    800026de:	854e                	mv	a0,s3
    800026e0:	00000097          	auipc	ra,0x0
    800026e4:	f1a080e7          	jalr	-230(ra) # 800025fa <reparent>
  wakeup(p->parent);
    800026e8:	0489b503          	ld	a0,72(s3)
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	e98080e7          	jalr	-360(ra) # 80002584 <wakeup>
  acquire(&p->lock);
    800026f4:	854e                	mv	a0,s3
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	616080e7          	jalr	1558(ra) # 80000d0c <acquire>
  p->xstate = status;
    800026fe:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002702:	4795                	li	a5,5
    80002704:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	6b6080e7          	jalr	1718(ra) # 80000dc0 <release>
  sched();
    80002712:	00000097          	auipc	ra,0x0
    80002716:	cfc080e7          	jalr	-772(ra) # 8000240e <sched>
  panic("zombie exit");
    8000271a:	00006517          	auipc	a0,0x6
    8000271e:	b8e50513          	addi	a0,a0,-1138 # 800082a8 <digits+0x268>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	e1e080e7          	jalr	-482(ra) # 80000540 <panic>

000000008000272a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000272a:	7179                	addi	sp,sp,-48
    8000272c:	f406                	sd	ra,40(sp)
    8000272e:	f022                	sd	s0,32(sp)
    80002730:	ec26                	sd	s1,24(sp)
    80002732:	e84a                	sd	s2,16(sp)
    80002734:	e44e                	sd	s3,8(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000273a:	0022f497          	auipc	s1,0x22f
    8000273e:	af648493          	addi	s1,s1,-1290 # 80231230 <proc>
    80002742:	00237997          	auipc	s3,0x237
    80002746:	2ee98993          	addi	s3,s3,750 # 80239a30 <mlfq_q>
    acquire(&p->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	5c0080e7          	jalr	1472(ra) # 80000d0c <acquire>
    if(p->pid == pid){
    80002754:	589c                	lw	a5,48(s1)
    80002756:	01278d63          	beq	a5,s2,80002770 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	664080e7          	jalr	1636(ra) # 80000dc0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002764:	22048493          	addi	s1,s1,544
    80002768:	ff3491e3          	bne	s1,s3,8000274a <kill+0x20>
  }
  return -1;
    8000276c:	557d                	li	a0,-1
    8000276e:	a829                	j	80002788 <kill+0x5e>
      p->killed = 1;
    80002770:	4785                	li	a5,1
    80002772:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002774:	4c98                	lw	a4,24(s1)
    80002776:	4789                	li	a5,2
    80002778:	00f70f63          	beq	a4,a5,80002796 <kill+0x6c>
      release(&p->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	642080e7          	jalr	1602(ra) # 80000dc0 <release>
      return 0;
    80002786:	4501                	li	a0,0
}
    80002788:	70a2                	ld	ra,40(sp)
    8000278a:	7402                	ld	s0,32(sp)
    8000278c:	64e2                	ld	s1,24(sp)
    8000278e:	6942                	ld	s2,16(sp)
    80002790:	69a2                	ld	s3,8(sp)
    80002792:	6145                	addi	sp,sp,48
    80002794:	8082                	ret
        p->state = RUNNABLE;
    80002796:	478d                	li	a5,3
    80002798:	cc9c                	sw	a5,24(s1)
    8000279a:	b7cd                	j	8000277c <kill+0x52>

000000008000279c <setkilled>:

void
setkilled(struct proc *p)
{
    8000279c:	1101                	addi	sp,sp,-32
    8000279e:	ec06                	sd	ra,24(sp)
    800027a0:	e822                	sd	s0,16(sp)
    800027a2:	e426                	sd	s1,8(sp)
    800027a4:	1000                	addi	s0,sp,32
    800027a6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	564080e7          	jalr	1380(ra) # 80000d0c <acquire>
  p->killed = 1;
    800027b0:	4785                	li	a5,1
    800027b2:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800027b4:	8526                	mv	a0,s1
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	60a080e7          	jalr	1546(ra) # 80000dc0 <release>
}
    800027be:	60e2                	ld	ra,24(sp)
    800027c0:	6442                	ld	s0,16(sp)
    800027c2:	64a2                	ld	s1,8(sp)
    800027c4:	6105                	addi	sp,sp,32
    800027c6:	8082                	ret

00000000800027c8 <killed>:

int
killed(struct proc *p)
{
    800027c8:	1101                	addi	sp,sp,-32
    800027ca:	ec06                	sd	ra,24(sp)
    800027cc:	e822                	sd	s0,16(sp)
    800027ce:	e426                	sd	s1,8(sp)
    800027d0:	e04a                	sd	s2,0(sp)
    800027d2:	1000                	addi	s0,sp,32
    800027d4:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	536080e7          	jalr	1334(ra) # 80000d0c <acquire>
  k = p->killed;
    800027de:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	5dc080e7          	jalr	1500(ra) # 80000dc0 <release>
  return k;
}
    800027ec:	854a                	mv	a0,s2
    800027ee:	60e2                	ld	ra,24(sp)
    800027f0:	6442                	ld	s0,16(sp)
    800027f2:	64a2                	ld	s1,8(sp)
    800027f4:	6902                	ld	s2,0(sp)
    800027f6:	6105                	addi	sp,sp,32
    800027f8:	8082                	ret

00000000800027fa <wait>:
{
    800027fa:	715d                	addi	sp,sp,-80
    800027fc:	e486                	sd	ra,72(sp)
    800027fe:	e0a2                	sd	s0,64(sp)
    80002800:	fc26                	sd	s1,56(sp)
    80002802:	f84a                	sd	s2,48(sp)
    80002804:	f44e                	sd	s3,40(sp)
    80002806:	f052                	sd	s4,32(sp)
    80002808:	ec56                	sd	s5,24(sp)
    8000280a:	e85a                	sd	s6,16(sp)
    8000280c:	e45e                	sd	s7,8(sp)
    8000280e:	e062                	sd	s8,0(sp)
    80002810:	0880                	addi	s0,sp,80
    80002812:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	2e8080e7          	jalr	744(ra) # 80001afc <myproc>
    8000281c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000281e:	0022e517          	auipc	a0,0x22e
    80002822:	5fa50513          	addi	a0,a0,1530 # 80230e18 <wait_lock>
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	4e6080e7          	jalr	1254(ra) # 80000d0c <acquire>
    havekids = 0;
    8000282e:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002830:	4a15                	li	s4,5
        havekids = 1;
    80002832:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002834:	00237997          	auipc	s3,0x237
    80002838:	1fc98993          	addi	s3,s3,508 # 80239a30 <mlfq_q>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000283c:	0022ec17          	auipc	s8,0x22e
    80002840:	5dcc0c13          	addi	s8,s8,1500 # 80230e18 <wait_lock>
    havekids = 0;
    80002844:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002846:	0022f497          	auipc	s1,0x22f
    8000284a:	9ea48493          	addi	s1,s1,-1558 # 80231230 <proc>
    8000284e:	a0bd                	j	800028bc <wait+0xc2>
          pid = pp->pid;
    80002850:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002854:	000b0e63          	beqz	s6,80002870 <wait+0x76>
    80002858:	4691                	li	a3,4
    8000285a:	02c48613          	addi	a2,s1,44
    8000285e:	85da                	mv	a1,s6
    80002860:	06093503          	ld	a0,96(s2)
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	f24080e7          	jalr	-220(ra) # 80001788 <copyout>
    8000286c:	02054563          	bltz	a0,80002896 <wait+0x9c>
          freeproc(pp);
    80002870:	8526                	mv	a0,s1
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	43c080e7          	jalr	1084(ra) # 80001cae <freeproc>
          release(&pp->lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	544080e7          	jalr	1348(ra) # 80000dc0 <release>
          release(&wait_lock);
    80002884:	0022e517          	auipc	a0,0x22e
    80002888:	59450513          	addi	a0,a0,1428 # 80230e18 <wait_lock>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	534080e7          	jalr	1332(ra) # 80000dc0 <release>
          return pid;
    80002894:	a0b5                	j	80002900 <wait+0x106>
            release(&pp->lock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	528080e7          	jalr	1320(ra) # 80000dc0 <release>
            release(&wait_lock);
    800028a0:	0022e517          	auipc	a0,0x22e
    800028a4:	57850513          	addi	a0,a0,1400 # 80230e18 <wait_lock>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	518080e7          	jalr	1304(ra) # 80000dc0 <release>
            return -1;
    800028b0:	59fd                	li	s3,-1
    800028b2:	a0b9                	j	80002900 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800028b4:	22048493          	addi	s1,s1,544
    800028b8:	03348463          	beq	s1,s3,800028e0 <wait+0xe6>
      if(pp->parent == p){
    800028bc:	64bc                	ld	a5,72(s1)
    800028be:	ff279be3          	bne	a5,s2,800028b4 <wait+0xba>
        acquire(&pp->lock);
    800028c2:	8526                	mv	a0,s1
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	448080e7          	jalr	1096(ra) # 80000d0c <acquire>
        if(pp->state == ZOMBIE){
    800028cc:	4c9c                	lw	a5,24(s1)
    800028ce:	f94781e3          	beq	a5,s4,80002850 <wait+0x56>
        release(&pp->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	4ec080e7          	jalr	1260(ra) # 80000dc0 <release>
        havekids = 1;
    800028dc:	8756                	mv	a4,s5
    800028de:	bfd9                	j	800028b4 <wait+0xba>
    if(!havekids || killed(p)){
    800028e0:	c719                	beqz	a4,800028ee <wait+0xf4>
    800028e2:	854a                	mv	a0,s2
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	ee4080e7          	jalr	-284(ra) # 800027c8 <killed>
    800028ec:	c51d                	beqz	a0,8000291a <wait+0x120>
      release(&wait_lock);
    800028ee:	0022e517          	auipc	a0,0x22e
    800028f2:	52a50513          	addi	a0,a0,1322 # 80230e18 <wait_lock>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	4ca080e7          	jalr	1226(ra) # 80000dc0 <release>
      return -1;
    800028fe:	59fd                	li	s3,-1
}
    80002900:	854e                	mv	a0,s3
    80002902:	60a6                	ld	ra,72(sp)
    80002904:	6406                	ld	s0,64(sp)
    80002906:	74e2                	ld	s1,56(sp)
    80002908:	7942                	ld	s2,48(sp)
    8000290a:	79a2                	ld	s3,40(sp)
    8000290c:	7a02                	ld	s4,32(sp)
    8000290e:	6ae2                	ld	s5,24(sp)
    80002910:	6b42                	ld	s6,16(sp)
    80002912:	6ba2                	ld	s7,8(sp)
    80002914:	6c02                	ld	s8,0(sp)
    80002916:	6161                	addi	sp,sp,80
    80002918:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000291a:	85e2                	mv	a1,s8
    8000291c:	854a                	mv	a0,s2
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	c02080e7          	jalr	-1022(ra) # 80002520 <sleep>
    havekids = 0;
    80002926:	bf39                	j	80002844 <wait+0x4a>

0000000080002928 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002928:	7179                	addi	sp,sp,-48
    8000292a:	f406                	sd	ra,40(sp)
    8000292c:	f022                	sd	s0,32(sp)
    8000292e:	ec26                	sd	s1,24(sp)
    80002930:	e84a                	sd	s2,16(sp)
    80002932:	e44e                	sd	s3,8(sp)
    80002934:	e052                	sd	s4,0(sp)
    80002936:	1800                	addi	s0,sp,48
    80002938:	84aa                	mv	s1,a0
    8000293a:	892e                	mv	s2,a1
    8000293c:	89b2                	mv	s3,a2
    8000293e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	1bc080e7          	jalr	444(ra) # 80001afc <myproc>
  if(user_dst){
    80002948:	c08d                	beqz	s1,8000296a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000294a:	86d2                	mv	a3,s4
    8000294c:	864e                	mv	a2,s3
    8000294e:	85ca                	mv	a1,s2
    80002950:	7128                	ld	a0,96(a0)
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	e36080e7          	jalr	-458(ra) # 80001788 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000295a:	70a2                	ld	ra,40(sp)
    8000295c:	7402                	ld	s0,32(sp)
    8000295e:	64e2                	ld	s1,24(sp)
    80002960:	6942                	ld	s2,16(sp)
    80002962:	69a2                	ld	s3,8(sp)
    80002964:	6a02                	ld	s4,0(sp)
    80002966:	6145                	addi	sp,sp,48
    80002968:	8082                	ret
    memmove((char *)dst, src, len);
    8000296a:	000a061b          	sext.w	a2,s4
    8000296e:	85ce                	mv	a1,s3
    80002970:	854a                	mv	a0,s2
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	4f2080e7          	jalr	1266(ra) # 80000e64 <memmove>
    return 0;
    8000297a:	8526                	mv	a0,s1
    8000297c:	bff9                	j	8000295a <either_copyout+0x32>

000000008000297e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000297e:	7179                	addi	sp,sp,-48
    80002980:	f406                	sd	ra,40(sp)
    80002982:	f022                	sd	s0,32(sp)
    80002984:	ec26                	sd	s1,24(sp)
    80002986:	e84a                	sd	s2,16(sp)
    80002988:	e44e                	sd	s3,8(sp)
    8000298a:	e052                	sd	s4,0(sp)
    8000298c:	1800                	addi	s0,sp,48
    8000298e:	892a                	mv	s2,a0
    80002990:	84ae                	mv	s1,a1
    80002992:	89b2                	mv	s3,a2
    80002994:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	166080e7          	jalr	358(ra) # 80001afc <myproc>
  if(user_src){
    8000299e:	c08d                	beqz	s1,800029c0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029a0:	86d2                	mv	a3,s4
    800029a2:	864e                	mv	a2,s3
    800029a4:	85ca                	mv	a1,s2
    800029a6:	7128                	ld	a0,96(a0)
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	ea0080e7          	jalr	-352(ra) # 80001848 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800029b0:	70a2                	ld	ra,40(sp)
    800029b2:	7402                	ld	s0,32(sp)
    800029b4:	64e2                	ld	s1,24(sp)
    800029b6:	6942                	ld	s2,16(sp)
    800029b8:	69a2                	ld	s3,8(sp)
    800029ba:	6a02                	ld	s4,0(sp)
    800029bc:	6145                	addi	sp,sp,48
    800029be:	8082                	ret
    memmove(dst, (char*)src, len);
    800029c0:	000a061b          	sext.w	a2,s4
    800029c4:	85ce                	mv	a1,s3
    800029c6:	854a                	mv	a0,s2
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	49c080e7          	jalr	1180(ra) # 80000e64 <memmove>
    return 0;
    800029d0:	8526                	mv	a0,s1
    800029d2:	bff9                	j	800029b0 <either_copyin+0x32>

00000000800029d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800029d4:	715d                	addi	sp,sp,-80
    800029d6:	e486                	sd	ra,72(sp)
    800029d8:	e0a2                	sd	s0,64(sp)
    800029da:	fc26                	sd	s1,56(sp)
    800029dc:	f84a                	sd	s2,48(sp)
    800029de:	f44e                	sd	s3,40(sp)
    800029e0:	f052                	sd	s4,32(sp)
    800029e2:	ec56                	sd	s5,24(sp)
    800029e4:	e85a                	sd	s6,16(sp)
    800029e6:	e45e                	sd	s7,8(sp)
    800029e8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029ea:	00005517          	auipc	a0,0x5
    800029ee:	71650513          	addi	a0,a0,1814 # 80008100 <digits+0xc0>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	b98080e7          	jalr	-1128(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029fa:	0022f497          	auipc	s1,0x22f
    800029fe:	99e48493          	addi	s1,s1,-1634 # 80231398 <proc+0x168>
    80002a02:	00237917          	auipc	s2,0x237
    80002a06:	19690913          	addi	s2,s2,406 # 80239b98 <mlfq_q+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a0c:	00006997          	auipc	s3,0x6
    80002a10:	8ac98993          	addi	s3,s3,-1876 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002a14:	00006a97          	auipc	s5,0x6
    80002a18:	8aca8a93          	addi	s5,s5,-1876 # 800082c0 <digits+0x280>
    printf("\n");
    80002a1c:	00005a17          	auipc	s4,0x5
    80002a20:	6e4a0a13          	addi	s4,s4,1764 # 80008100 <digits+0xc0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a24:	00006b97          	auipc	s7,0x6
    80002a28:	8dcb8b93          	addi	s7,s7,-1828 # 80008300 <states.0>
    80002a2c:	a00d                	j	80002a4e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a2e:	ec86a583          	lw	a1,-312(a3)
    80002a32:	8556                	mv	a0,s5
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b56080e7          	jalr	-1194(ra) # 8000058a <printf>
    printf("\n");
    80002a3c:	8552                	mv	a0,s4
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b4c080e7          	jalr	-1204(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a46:	22048493          	addi	s1,s1,544
    80002a4a:	03248263          	beq	s1,s2,80002a6e <procdump+0x9a>
    if(p->state == UNUSED)
    80002a4e:	86a6                	mv	a3,s1
    80002a50:	eb04a783          	lw	a5,-336(s1)
    80002a54:	dbed                	beqz	a5,80002a46 <procdump+0x72>
      state = "???";
    80002a56:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a58:	fcfb6be3          	bltu	s6,a5,80002a2e <procdump+0x5a>
    80002a5c:	02079713          	slli	a4,a5,0x20
    80002a60:	01d75793          	srli	a5,a4,0x1d
    80002a64:	97de                	add	a5,a5,s7
    80002a66:	6390                	ld	a2,0(a5)
    80002a68:	f279                	bnez	a2,80002a2e <procdump+0x5a>
      state = "???";
    80002a6a:	864e                	mv	a2,s3
    80002a6c:	b7c9                	j	80002a2e <procdump+0x5a>
  }
}
    80002a6e:	60a6                	ld	ra,72(sp)
    80002a70:	6406                	ld	s0,64(sp)
    80002a72:	74e2                	ld	s1,56(sp)
    80002a74:	7942                	ld	s2,48(sp)
    80002a76:	79a2                	ld	s3,40(sp)
    80002a78:	7a02                	ld	s4,32(sp)
    80002a7a:	6ae2                	ld	s5,24(sp)
    80002a7c:	6b42                	ld	s6,16(sp)
    80002a7e:	6ba2                	ld	s7,8(sp)
    80002a80:	6161                	addi	sp,sp,80
    80002a82:	8082                	ret

0000000080002a84 <pinit>:
// }

#define RAND_MAX 32767

void pinit(void)
{
    80002a84:	1141                	addi	sp,sp,-16
    80002a86:	e422                	sd	s0,8(sp)
    80002a88:	0800                	addi	s0,sp,16
  for (int i = 0; i < NMLFQ; i++)
    80002a8a:	00237797          	auipc	a5,0x237
    80002a8e:	fa678793          	addi	a5,a5,-90 # 80239a30 <mlfq_q>
    80002a92:	00238717          	auipc	a4,0x238
    80002a96:	a3e70713          	addi	a4,a4,-1474 # 8023a4d0 <tickslock>
  {
    mlfq_q[i].size = 0;
    80002a9a:	2007ac23          	sw	zero,536(a5)
    mlfq_q[i].head = 0;
    80002a9e:	0007b023          	sd	zero,0(a5)
    mlfq_q[i].tail = 0;
    80002aa2:	0007b423          	sd	zero,8(a5)
  for (int i = 0; i < NMLFQ; i++)
    80002aa6:	22078793          	addi	a5,a5,544
    80002aaa:	fee798e3          	bne	a5,a4,80002a9a <pinit+0x16>
  }
}
    80002aae:	6422                	ld	s0,8(sp)
    80002ab0:	0141                	addi	sp,sp,16
    80002ab2:	8082                	ret

0000000080002ab4 <random_max>:

int random_max(int n)
{
    80002ab4:	1141                	addi	sp,sp,-16
    80002ab6:	e422                	sd	s0,8(sp)
    80002ab8:	0800                	addi	s0,sp,16
  // generate a random number less than n
  unsigned int num_bins = (unsigned int)n + 1;
    80002aba:	0015071b          	addiw	a4,a0,1
  unsigned int num_rand = (unsigned int)RAND_MAX + 1;
  unsigned int bin_size = num_rand / num_bins;
    80002abe:	67a1                	lui	a5,0x8
    80002ac0:	02e7d53b          	divuw	a0,a5,a4
  unsigned int defect = num_rand % num_bins;
    80002ac4:	02e7f6bb          	remuw	a3,a5,a4

  int x;
  do
  {
    x = ticks;
    80002ac8:	00006717          	auipc	a4,0x6
    80002acc:	0c872703          	lw	a4,200(a4) # 80008b90 <ticks>
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned int)x);
    80002ad0:	9f95                	subw	a5,a5,a3
    80002ad2:	00f77063          	bgeu	a4,a5,80002ad2 <random_max+0x1e>

  // Truncated division is intentional
  return x / bin_size;
}
    80002ad6:	02a7553b          	divuw	a0,a4,a0
    80002ada:	6422                	ld	s0,8(sp)
    80002adc:	0141                	addi	sp,sp,16
    80002ade:	8082                	ret

0000000080002ae0 <LBS>:
{
    80002ae0:	7159                	addi	sp,sp,-112
    80002ae2:	f486                	sd	ra,104(sp)
    80002ae4:	f0a2                	sd	s0,96(sp)
    80002ae6:	eca6                	sd	s1,88(sp)
    80002ae8:	e8ca                	sd	s2,80(sp)
    80002aea:	e4ce                	sd	s3,72(sp)
    80002aec:	e0d2                	sd	s4,64(sp)
    80002aee:	fc56                	sd	s5,56(sp)
    80002af0:	f85a                	sd	s6,48(sp)
    80002af2:	f45e                	sd	s7,40(sp)
    80002af4:	f062                	sd	s8,32(sp)
    80002af6:	ec66                	sd	s9,24(sp)
    80002af8:	e86a                	sd	s10,16(sp)
    80002afa:	e46e                	sd	s11,8(sp)
    80002afc:	1880                	addi	s0,sp,112
    80002afe:	8792                	mv	a5,tp
  int id = r_tp();
    80002b00:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002b02:	00779693          	slli	a3,a5,0x7
    80002b06:	0022e717          	auipc	a4,0x22e
    80002b0a:	2fa70713          	addi	a4,a4,762 # 80230e00 <pid_lock>
    80002b0e:	9736                	add	a4,a4,a3
    80002b10:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &prize->context);
    80002b14:	0022e717          	auipc	a4,0x22e
    80002b18:	32470713          	addi	a4,a4,804 # 80230e38 <cpus+0x8>
    80002b1c:	00e68db3          	add	s11,a3,a4
    total_tickets = 0;
    80002b20:	4a81                	li	s5,0
    for (p = proc; p < &proc[NPROC]; p++)
    80002b22:	00237997          	auipc	s3,0x237
    80002b26:	f0e98993          	addi	s3,s3,-242 # 80239a30 <mlfq_q>
          c->proc = prize;
    80002b2a:	0022eb17          	auipc	s6,0x22e
    80002b2e:	2d6b0b13          	addi	s6,s6,726 # 80230e00 <pid_lock>
    80002b32:	9b36                	add	s6,s6,a3
    80002b34:	a0c5                	j	80002c14 <LBS+0x134>
      release(&p->lock);
    80002b36:	8526                	mv	a0,s1
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	288080e7          	jalr	648(ra) # 80000dc0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002b40:	22048493          	addi	s1,s1,544
    80002b44:	01348f63          	beq	s1,s3,80002b62 <LBS+0x82>
      acquire(&p->lock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	1c2080e7          	jalr	450(ra) # 80000d0c <acquire>
      if (p->state == RUNNABLE)
    80002b52:	4c9c                	lw	a5,24(s1)
    80002b54:	ff2791e3          	bne	a5,s2,80002b36 <LBS+0x56>
        total_tickets += p->tickets;
    80002b58:	1b04b783          	ld	a5,432(s1)
    80002b5c:	01478a3b          	addw	s4,a5,s4
    80002b60:	bfd9                	j	80002b36 <LBS+0x56>
    if (total_tickets > 0)
    80002b62:	01404e63          	bgtz	s4,80002b7e <LBS+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6e:	10079073          	csrw	sstatus,a5
    total_tickets = 0;
    80002b72:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002b74:	0022e497          	auipc	s1,0x22e
    80002b78:	6bc48493          	addi	s1,s1,1724 # 80231230 <proc>
    80002b7c:	b7f1                	j	80002b48 <LBS+0x68>
      ticket = random_max(total_tickets);
    80002b7e:	8552                	mv	a0,s4
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	f34080e7          	jalr	-204(ra) # 80002ab4 <random_max>
    80002b88:	8caa                	mv	s9,a0
      for (p = proc; p < &proc[NPROC]; p++)
    80002b8a:	0022ea17          	auipc	s4,0x22e
    80002b8e:	6a6a0a13          	addi	s4,s4,1702 # 80231230 <proc>
    80002b92:	0022f497          	auipc	s1,0x22f
    80002b96:	8be48493          	addi	s1,s1,-1858 # 80231450 <proc+0x220>
    prize = 0;
    80002b9a:	8d56                	mv	s10,s5
    80002b9c:	a821                	j	80002bb4 <LBS+0xd4>
        release(&p->lock);
    80002b9e:	855e                	mv	a0,s7
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	220080e7          	jalr	544(ra) # 80000dc0 <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002ba8:	073c7863          	bgeu	s8,s3,80002c18 <LBS+0x138>
    80002bac:	220a0a13          	addi	s4,s4,544
    80002bb0:	22048493          	addi	s1,s1,544
    80002bb4:	8bd2                	mv	s7,s4
        acquire(&p->lock);
    80002bb6:	8552                	mv	a0,s4
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	154080e7          	jalr	340(ra) # 80000d0c <acquire>
        if (p->state == RUNNABLE)
    80002bc0:	8c26                	mv	s8,s1
    80002bc2:	df84a783          	lw	a5,-520(s1)
    80002bc6:	fd279ce3          	bne	a5,s2,80002b9e <LBS+0xbe>
          if (temp_sum >= ticket && prize == 0)
    80002bca:	f904b783          	ld	a5,-112(s1)
    80002bce:	fd97e8e3          	bltu	a5,s9,80002b9e <LBS+0xbe>
    80002bd2:	040d0663          	beqz	s10,80002c1e <LBS+0x13e>
        release(&p->lock);
    80002bd6:	8552                	mv	a0,s4
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	1e8080e7          	jalr	488(ra) # 80000dc0 <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002be0:	fd34e6e3          	bltu	s1,s3,80002bac <LBS+0xcc>
        if (prize->state == RUNNABLE)
    80002be4:	018d2703          	lw	a4,24(s10)
    80002be8:	478d                	li	a5,3
    80002bea:	02f71063          	bne	a4,a5,80002c0a <LBS+0x12a>
          prize->state = RUNNING;
    80002bee:	4791                	li	a5,4
    80002bf0:	00fd2c23          	sw	a5,24(s10)
          c->proc = prize;
    80002bf4:	03ab3823          	sd	s10,48(s6)
          swtch(&c->context, &prize->context);
    80002bf8:	070d0593          	addi	a1,s10,112
    80002bfc:	856e                	mv	a0,s11
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	316080e7          	jalr	790(ra) # 80002f14 <swtch>
          c->proc = 0;
    80002c06:	020b3823          	sd	zero,48(s6)
        release(&prize->lock);
    80002c0a:	856a                	mv	a0,s10
    80002c0c:	ffffe097          	auipc	ra,0xffffe
    80002c10:	1b4080e7          	jalr	436(ra) # 80000dc0 <release>
      if (p->state == RUNNABLE)
    80002c14:	490d                	li	s2,3
    80002c16:	bf81                	j	80002b66 <LBS+0x86>
      if (prize != 0)
    80002c18:	f40d07e3          	beqz	s10,80002b66 <LBS+0x86>
    80002c1c:	b7e1                	j	80002be4 <LBS+0x104>
      for (p = proc; p < &proc[NPROC]; p++)
    80002c1e:	0134f463          	bgeu	s1,s3,80002c26 <LBS+0x146>
    80002c22:	8d5e                	mv	s10,s7
    80002c24:	b761                	j	80002bac <LBS+0xcc>
    80002c26:	8d52                	mv	s10,s4
    80002c28:	bf75                	j	80002be4 <LBS+0x104>

0000000080002c2a <push>:

void push(struct Queue *array, struct proc *p)
{
    80002c2a:	1141                	addi	sp,sp,-16
    80002c2c:	e422                	sd	s0,8(sp)
    80002c2e:	0800                	addi	s0,sp,16
  array->array[array->tail] = p;
    80002c30:	651c                	ld	a5,8(a0)
    80002c32:	00278713          	addi	a4,a5,2 # 8002 <_entry-0x7fff7ffe>
    80002c36:	070e                	slli	a4,a4,0x3
    80002c38:	972a                	add	a4,a4,a0
    80002c3a:	e30c                	sd	a1,0(a4)
  array->tail = (array->tail + 1) % NPROC;
    80002c3c:	0785                	addi	a5,a5,1
    80002c3e:	03f7f793          	andi	a5,a5,63
    80002c42:	e51c                	sd	a5,8(a0)

  if (array->tail == NPROC + 1)
  {
    array->tail = 0;
  }
  else if (array->tail > array->head)
    80002c44:	6118                	ld	a4,0(a0)
    80002c46:	00f77563          	bgeu	a4,a5,80002c50 <push+0x26>
  {
    array->size = array->tail - array->head;
    80002c4a:	9f99                	subw	a5,a5,a4
    80002c4c:	20f52c23          	sw	a5,536(a0)
  }

  array->size++;
    80002c50:	21852783          	lw	a5,536(a0)
    80002c54:	2785                	addiw	a5,a5,1
    80002c56:	20f52c23          	sw	a5,536(a0)
}
    80002c5a:	6422                	ld	s0,8(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret

0000000080002c60 <pop>:

void pop(struct Queue *array)
{
    80002c60:	1141                	addi	sp,sp,-16
    80002c62:	e422                	sd	s0,8(sp)
    80002c64:	0800                	addi	s0,sp,16
  array->head++;
    80002c66:	611c                	ld	a5,0(a0)
    80002c68:	0785                	addi	a5,a5,1

  if (array->head == NPROC + 1)
    80002c6a:	04100713          	li	a4,65
    80002c6e:	00e78b63          	beq	a5,a4,80002c84 <pop+0x24>
    80002c72:	e11c                	sd	a5,0(a0)
  {
    array->head = 0;
  }

  array->size--;
    80002c74:	21852783          	lw	a5,536(a0)
    80002c78:	37fd                	addiw	a5,a5,-1
    80002c7a:	20f52c23          	sw	a5,536(a0)
}
    80002c7e:	6422                	ld	s0,8(sp)
    80002c80:	0141                	addi	sp,sp,16
    80002c82:	8082                	ret
    array->head = 0;
    80002c84:	4781                	li	a5,0
    80002c86:	b7f5                	j	80002c72 <pop+0x12>

0000000080002c88 <front>:

struct proc *front(struct Queue *array)
{
    80002c88:	1141                	addi	sp,sp,-16
    80002c8a:	e422                	sd	s0,8(sp)
    80002c8c:	0800                	addi	s0,sp,16
  if (array->head == array->tail)
    80002c8e:	611c                	ld	a5,0(a0)
    80002c90:	6518                	ld	a4,8(a0)
    80002c92:	00e78963          	beq	a5,a4,80002ca4 <front+0x1c>
  {
    return 0;
  }

  return array->array[array->head];
    80002c96:	0789                	addi	a5,a5,2
    80002c98:	078e                	slli	a5,a5,0x3
    80002c9a:	953e                	add	a0,a0,a5
    80002c9c:	6108                	ld	a0,0(a0)
}
    80002c9e:	6422                	ld	s0,8(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret
    return 0;
    80002ca4:	4501                	li	a0,0
    80002ca6:	bfe5                	j	80002c9e <front+0x16>

0000000080002ca8 <waitx>:

int waitx(uint64 addr, uint* wtime, uint* rtime)
		
{
    80002ca8:	711d                	addi	sp,sp,-96
    80002caa:	ec86                	sd	ra,88(sp)
    80002cac:	e8a2                	sd	s0,80(sp)
    80002cae:	e4a6                	sd	s1,72(sp)
    80002cb0:	e0ca                	sd	s2,64(sp)
    80002cb2:	fc4e                	sd	s3,56(sp)
    80002cb4:	f852                	sd	s4,48(sp)
    80002cb6:	f456                	sd	s5,40(sp)
    80002cb8:	f05a                	sd	s6,32(sp)
    80002cba:	ec5e                	sd	s7,24(sp)
    80002cbc:	e862                	sd	s8,16(sp)
    80002cbe:	e466                	sd	s9,8(sp)
    80002cc0:	e06a                	sd	s10,0(sp)
    80002cc2:	1080                	addi	s0,sp,96
    80002cc4:	8b2a                	mv	s6,a0
    80002cc6:	8bae                	mv	s7,a1
    80002cc8:	8c32                	mv	s8,a2
		
  struct proc *np;
		
  int havekids, pid;
		
  struct proc *p = myproc();
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	e32080e7          	jalr	-462(ra) # 80001afc <myproc>
    80002cd2:	892a                	mv	s2,a0
		

		
  acquire(&wait_lock);
    80002cd4:	0022e517          	auipc	a0,0x22e
    80002cd8:	14450513          	addi	a0,a0,324 # 80230e18 <wait_lock>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	030080e7          	jalr	48(ra) # 80000d0c <acquire>
		
  for(;;){
		
    // Scan through table looking for exited children.
		
    havekids = 0;
    80002ce4:	4c81                	li	s9,0
		

		
        havekids = 1;
		
        if(np->state == ZOMBIE){
    80002ce6:	4a15                	li	s4,5
        havekids = 1;
    80002ce8:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002cea:	00237997          	auipc	s3,0x237
    80002cee:	d4698993          	addi	s3,s3,-698 # 80239a30 <mlfq_q>
		
    }
		
    // Wait for a child to exit.
		
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002cf2:	0022ed17          	auipc	s10,0x22e
    80002cf6:	126d0d13          	addi	s10,s10,294 # 80230e18 <wait_lock>
    havekids = 0;
    80002cfa:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002cfc:	0022e497          	auipc	s1,0x22e
    80002d00:	53448493          	addi	s1,s1,1332 # 80231230 <proc>
    80002d04:	a059                	j	80002d8a <waitx+0xe2>
          pid = np->pid;
    80002d06:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002d0a:	1804a703          	lw	a4,384(s1)
    80002d0e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002d12:	1844a783          	lw	a5,388(s1)
    80002d16:	9f99                	subw	a5,a5,a4
    80002d18:	17c4a703          	lw	a4,380(s1)
    80002d1c:	9f99                	subw	a5,a5,a4
    80002d1e:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d22:	000b0e63          	beqz	s6,80002d3e <waitx+0x96>
    80002d26:	4691                	li	a3,4
    80002d28:	02c48613          	addi	a2,s1,44
    80002d2c:	85da                	mv	a1,s6
    80002d2e:	06093503          	ld	a0,96(s2)
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	a56080e7          	jalr	-1450(ra) # 80001788 <copyout>
    80002d3a:	02054563          	bltz	a0,80002d64 <waitx+0xbc>
          freeproc(np);
    80002d3e:	8526                	mv	a0,s1
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	f6e080e7          	jalr	-146(ra) # 80001cae <freeproc>
          release(&np->lock);
    80002d48:	8526                	mv	a0,s1
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	076080e7          	jalr	118(ra) # 80000dc0 <release>
          release(&wait_lock);
    80002d52:	0022e517          	auipc	a0,0x22e
    80002d56:	0c650513          	addi	a0,a0,198 # 80230e18 <wait_lock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	066080e7          	jalr	102(ra) # 80000dc0 <release>
          return pid;
    80002d62:	a09d                	j	80002dc8 <waitx+0x120>
            release(&np->lock);
    80002d64:	8526                	mv	a0,s1
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	05a080e7          	jalr	90(ra) # 80000dc0 <release>
            release(&wait_lock);
    80002d6e:	0022e517          	auipc	a0,0x22e
    80002d72:	0aa50513          	addi	a0,a0,170 # 80230e18 <wait_lock>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	04a080e7          	jalr	74(ra) # 80000dc0 <release>
            return -1;
    80002d7e:	59fd                	li	s3,-1
    80002d80:	a0a1                	j	80002dc8 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002d82:	22048493          	addi	s1,s1,544
    80002d86:	03348463          	beq	s1,s3,80002dae <waitx+0x106>
      if(np->parent == p){
    80002d8a:	64bc                	ld	a5,72(s1)
    80002d8c:	ff279be3          	bne	a5,s2,80002d82 <waitx+0xda>
        acquire(&np->lock);
    80002d90:	8526                	mv	a0,s1
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	f7a080e7          	jalr	-134(ra) # 80000d0c <acquire>
        if(np->state == ZOMBIE){
    80002d9a:	4c9c                	lw	a5,24(s1)
    80002d9c:	f74785e3          	beq	a5,s4,80002d06 <waitx+0x5e>
        release(&np->lock);
    80002da0:	8526                	mv	a0,s1
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	01e080e7          	jalr	30(ra) # 80000dc0 <release>
        havekids = 1;
    80002daa:	8756                	mv	a4,s5
    80002dac:	bfd9                	j	80002d82 <waitx+0xda>
    if(!havekids || p->killed){
    80002dae:	c701                	beqz	a4,80002db6 <waitx+0x10e>
    80002db0:	02892783          	lw	a5,40(s2)
    80002db4:	cb8d                	beqz	a5,80002de6 <waitx+0x13e>
      release(&wait_lock);
    80002db6:	0022e517          	auipc	a0,0x22e
    80002dba:	06250513          	addi	a0,a0,98 # 80230e18 <wait_lock>
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	002080e7          	jalr	2(ra) # 80000dc0 <release>
      return -1;
    80002dc6:	59fd                	li	s3,-1
		
  }
		
}
    80002dc8:	854e                	mv	a0,s3
    80002dca:	60e6                	ld	ra,88(sp)
    80002dcc:	6446                	ld	s0,80(sp)
    80002dce:	64a6                	ld	s1,72(sp)
    80002dd0:	6906                	ld	s2,64(sp)
    80002dd2:	79e2                	ld	s3,56(sp)
    80002dd4:	7a42                	ld	s4,48(sp)
    80002dd6:	7aa2                	ld	s5,40(sp)
    80002dd8:	7b02                	ld	s6,32(sp)
    80002dda:	6be2                	ld	s7,24(sp)
    80002ddc:	6c42                	ld	s8,16(sp)
    80002dde:	6ca2                	ld	s9,8(sp)
    80002de0:	6d02                	ld	s10,0(sp)
    80002de2:	6125                	addi	sp,sp,96
    80002de4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002de6:	85ea                	mv	a1,s10
    80002de8:	854a                	mv	a0,s2
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	736080e7          	jalr	1846(ra) # 80002520 <sleep>
    havekids = 0;
    80002df2:	b721                	j	80002cfa <waitx+0x52>

0000000080002df4 <qerase>:
		



void qerase(struct Queue *list, struct proc *p)
{
    80002df4:	1141                	addi	sp,sp,-16
    80002df6:	e422                	sd	s0,8(sp)
    80002df8:	0800                	addi	s0,sp,16
  int pid = p->pid;
    80002dfa:	0305a803          	lw	a6,48(a1)
  for (int i = list->head; i < list->tail; i++)
    80002dfe:	6118                	ld	a4,0(a0)
    80002e00:	0007079b          	sext.w	a5,a4
    80002e04:	00853883          	ld	a7,8(a0)
    80002e08:	0317fd63          	bgeu	a5,a7,80002e42 <qerase+0x4e>
    80002e0c:	078e                	slli	a5,a5,0x3
    80002e0e:	97aa                	add	a5,a5,a0
    80002e10:	2705                	addiw	a4,a4,1
    80002e12:	00389593          	slli	a1,a7,0x3
    80002e16:	95aa                	add	a1,a1,a0
  {
    if (list->array[i]->pid == pid)
    {
      struct proc *temp = list->array[i];
      list->array[i] = list->array[(i + 1) % (NPROC + 1)];
    80002e18:	04100e13          	li	t3,65
    80002e1c:	a029                	j	80002e26 <qerase+0x32>
  for (int i = list->head; i < list->tail; i++)
    80002e1e:	07a1                	addi	a5,a5,8
    80002e20:	2705                	addiw	a4,a4,1
    80002e22:	02b78063          	beq	a5,a1,80002e42 <qerase+0x4e>
    if (list->array[i]->pid == pid)
    80002e26:	6b90                	ld	a2,16(a5)
    80002e28:	5a14                	lw	a3,48(a2)
    80002e2a:	ff069ae3          	bne	a3,a6,80002e1e <qerase+0x2a>
      list->array[i] = list->array[(i + 1) % (NPROC + 1)];
    80002e2e:	03c766bb          	remw	a3,a4,t3
    80002e32:	068e                	slli	a3,a3,0x3
    80002e34:	96aa                	add	a3,a3,a0
    80002e36:	0106b303          	ld	t1,16(a3)
    80002e3a:	0067b823          	sd	t1,16(a5)
      list->array[(i + 1) % (NPROC + 1)] = temp;
    80002e3e:	ea90                	sd	a2,16(a3)
    80002e40:	bff9                	j	80002e1e <qerase+0x2a>
    }
  }

  list->tail--;
    80002e42:	18fd                	addi	a7,a7,-1
    80002e44:	01153423          	sd	a7,8(a0)
  list->size--;
    80002e48:	21852783          	lw	a5,536(a0)
    80002e4c:	37fd                	addiw	a5,a5,-1
    80002e4e:	20f52c23          	sw	a5,536(a0)
  if (list->tail < 0)
  {
    list->tail = NPROC;
  }
}
    80002e52:	6422                	ld	s0,8(sp)
    80002e54:	0141                	addi	sp,sp,16
    80002e56:	8082                	ret

0000000080002e58 <ageing>:

void ageing(void)
{
    80002e58:	715d                	addi	sp,sp,-80
    80002e5a:	e486                	sd	ra,72(sp)
    80002e5c:	e0a2                	sd	s0,64(sp)
    80002e5e:	fc26                	sd	s1,56(sp)
    80002e60:	f84a                	sd	s2,48(sp)
    80002e62:	f44e                	sd	s3,40(sp)
    80002e64:	f052                	sd	s4,32(sp)
    80002e66:	ec56                	sd	s5,24(sp)
    80002e68:	e85a                	sd	s6,16(sp)
    80002e6a:	e45e                	sd	s7,8(sp)
    80002e6c:	0880                	addi	s0,sp,80
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002e6e:	0022e497          	auipc	s1,0x22e
    80002e72:	3c248493          	addi	s1,s1,962 # 80231230 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNABLE && ticks - p->enter_q >= 128)
    80002e76:	498d                	li	s3,3
    80002e78:	00006b17          	auipc	s6,0x6
    80002e7c:	d18b0b13          	addi	s6,s6,-744 # 80008b90 <ticks>
    80002e80:	07f00a93          	li	s5,127
    {
      if (p->cur_q)
      {
        qerase(&mlfq_q[p->level], p);
    80002e84:	00237b97          	auipc	s7,0x237
    80002e88:	bacb8b93          	addi	s7,s7,-1108 # 80239a30 <mlfq_q>
  for (p = proc; p < &proc[NPROC]; p++)
    80002e8c:	00237917          	auipc	s2,0x237
    80002e90:	ba490913          	addi	s2,s2,-1116 # 80239a30 <mlfq_q>
    80002e94:	a81d                	j	80002eca <ageing+0x72>
        qerase(&mlfq_q[p->level], p);
    80002e96:	2004b783          	ld	a5,512(s1)
    80002e9a:	00479513          	slli	a0,a5,0x4
    80002e9e:	953e                	add	a0,a0,a5
    80002ea0:	0516                	slli	a0,a0,0x5
    80002ea2:	85a6                	mv	a1,s1
    80002ea4:	955e                	add	a0,a0,s7
    80002ea6:	00000097          	auipc	ra,0x0
    80002eaa:	f4e080e7          	jalr	-178(ra) # 80002df4 <qerase>
        p->cur_q = 0;
    80002eae:	1e04b023          	sd	zero,480(s1)
    80002eb2:	a83d                	j	80002ef0 <ageing+0x98>
      }
      if (p->level != 0)
      {
        p->level--;
      }
      p->enter_q = ticks;
    80002eb4:	1f44bc23          	sd	s4,504(s1)
    }
    release(&p->lock);
    80002eb8:	8526                	mv	a0,s1
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	f06080e7          	jalr	-250(ra) # 80000dc0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ec2:	22048493          	addi	s1,s1,544
    80002ec6:	03248c63          	beq	s1,s2,80002efe <ageing+0xa6>
    acquire(&p->lock);
    80002eca:	8526                	mv	a0,s1
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	e40080e7          	jalr	-448(ra) # 80000d0c <acquire>
    if (p->state == RUNNABLE && ticks - p->enter_q >= 128)
    80002ed4:	4c9c                	lw	a5,24(s1)
    80002ed6:	ff3791e3          	bne	a5,s3,80002eb8 <ageing+0x60>
    80002eda:	000b6a03          	lwu	s4,0(s6)
    80002ede:	1f84b783          	ld	a5,504(s1)
    80002ee2:	40fa07b3          	sub	a5,s4,a5
    80002ee6:	fcfaf9e3          	bgeu	s5,a5,80002eb8 <ageing+0x60>
      if (p->cur_q)
    80002eea:	1e04b783          	ld	a5,480(s1)
    80002eee:	f7c5                	bnez	a5,80002e96 <ageing+0x3e>
      if (p->level != 0)
    80002ef0:	2004b783          	ld	a5,512(s1)
    80002ef4:	d3e1                	beqz	a5,80002eb4 <ageing+0x5c>
        p->level--;
    80002ef6:	17fd                	addi	a5,a5,-1
    80002ef8:	20f4b023          	sd	a5,512(s1)
    80002efc:	bf65                	j	80002eb4 <ageing+0x5c>
  }
}
    80002efe:	60a6                	ld	ra,72(sp)
    80002f00:	6406                	ld	s0,64(sp)
    80002f02:	74e2                	ld	s1,56(sp)
    80002f04:	7942                	ld	s2,48(sp)
    80002f06:	79a2                	ld	s3,40(sp)
    80002f08:	7a02                	ld	s4,32(sp)
    80002f0a:	6ae2                	ld	s5,24(sp)
    80002f0c:	6b42                	ld	s6,16(sp)
    80002f0e:	6ba2                	ld	s7,8(sp)
    80002f10:	6161                	addi	sp,sp,80
    80002f12:	8082                	ret

0000000080002f14 <swtch>:
    80002f14:	00153023          	sd	ra,0(a0)
    80002f18:	00253423          	sd	sp,8(a0)
    80002f1c:	e900                	sd	s0,16(a0)
    80002f1e:	ed04                	sd	s1,24(a0)
    80002f20:	03253023          	sd	s2,32(a0)
    80002f24:	03353423          	sd	s3,40(a0)
    80002f28:	03453823          	sd	s4,48(a0)
    80002f2c:	03553c23          	sd	s5,56(a0)
    80002f30:	05653023          	sd	s6,64(a0)
    80002f34:	05753423          	sd	s7,72(a0)
    80002f38:	05853823          	sd	s8,80(a0)
    80002f3c:	05953c23          	sd	s9,88(a0)
    80002f40:	07a53023          	sd	s10,96(a0)
    80002f44:	07b53423          	sd	s11,104(a0)
    80002f48:	0005b083          	ld	ra,0(a1)
    80002f4c:	0085b103          	ld	sp,8(a1)
    80002f50:	6980                	ld	s0,16(a1)
    80002f52:	6d84                	ld	s1,24(a1)
    80002f54:	0205b903          	ld	s2,32(a1)
    80002f58:	0285b983          	ld	s3,40(a1)
    80002f5c:	0305ba03          	ld	s4,48(a1)
    80002f60:	0385ba83          	ld	s5,56(a1)
    80002f64:	0405bb03          	ld	s6,64(a1)
    80002f68:	0485bb83          	ld	s7,72(a1)
    80002f6c:	0505bc03          	ld	s8,80(a1)
    80002f70:	0585bc83          	ld	s9,88(a1)
    80002f74:	0605bd03          	ld	s10,96(a1)
    80002f78:	0685bd83          	ld	s11,104(a1)
    80002f7c:	8082                	ret

0000000080002f7e <trapinit>:
int cowfault(pagetable_t pagetable, uint64 va);
extern int devintr();

void
trapinit(void)
{
    80002f7e:	1141                	addi	sp,sp,-16
    80002f80:	e406                	sd	ra,8(sp)
    80002f82:	e022                	sd	s0,0(sp)
    80002f84:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f86:	00005597          	auipc	a1,0x5
    80002f8a:	3aa58593          	addi	a1,a1,938 # 80008330 <states.0+0x30>
    80002f8e:	00237517          	auipc	a0,0x237
    80002f92:	54250513          	addi	a0,a0,1346 # 8023a4d0 <tickslock>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	ce6080e7          	jalr	-794(ra) # 80000c7c <initlock>
}
    80002f9e:	60a2                	ld	ra,8(sp)
    80002fa0:	6402                	ld	s0,0(sp)
    80002fa2:	0141                	addi	sp,sp,16
    80002fa4:	8082                	ret

0000000080002fa6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002fa6:	1141                	addi	sp,sp,-16
    80002fa8:	e422                	sd	s0,8(sp)
    80002faa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fac:	00003797          	auipc	a5,0x3
    80002fb0:	7b478793          	addi	a5,a5,1972 # 80006760 <kernelvec>
    80002fb4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002fb8:	6422                	ld	s0,8(sp)
    80002fba:	0141                	addi	sp,sp,16
    80002fbc:	8082                	ret

0000000080002fbe <sigalarm>:


  usertrapret();
}

int sigalarm(int ticks, void(*handler)()) {
    80002fbe:	1101                	addi	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	e426                	sd	s1,8(sp)
    80002fc6:	e04a                	sd	s2,0(sp)
    80002fc8:	1000                	addi	s0,sp,32
    80002fca:	84aa                	mv	s1,a0
    80002fcc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	b2e080e7          	jalr	-1234(ra) # 80001afc <myproc>
  int temp = ticks;
  p->alarm_interval = temp;
    80002fd6:	20952423          	sw	s1,520(a0)
  p->alarm_ticks = ticks;
    80002fda:	20952c23          	sw	s1,536(a0)
  p->alarm_handler = handler;
    80002fde:	21253823          	sd	s2,528(a0)
  return 0;
}
    80002fe2:	4501                	li	a0,0
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6902                	ld	s2,0(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <sigreturn>:

int sigreturn() {
    80002ff0:	1141                	addi	sp,sp,-16
    80002ff2:	e406                	sd	ra,8(sp)
    80002ff4:	e022                	sd	s0,0(sp)
    80002ff6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	b04080e7          	jalr	-1276(ra) # 80001afc <myproc>
  *p->trapframe = *p->alarm_trapframe;
    80003000:	7d14                	ld	a3,56(a0)
    80003002:	87b6                	mv	a5,a3
    80003004:	7538                	ld	a4,104(a0)
    80003006:	12068693          	addi	a3,a3,288
    8000300a:	0007b883          	ld	a7,0(a5)
    8000300e:	0087b803          	ld	a6,8(a5)
    80003012:	6b8c                	ld	a1,16(a5)
    80003014:	6f90                	ld	a2,24(a5)
    80003016:	01173023          	sd	a7,0(a4)
    8000301a:	01073423          	sd	a6,8(a4)
    8000301e:	eb0c                	sd	a1,16(a4)
    80003020:	ef10                	sd	a2,24(a4)
    80003022:	02078793          	addi	a5,a5,32
    80003026:	02070713          	addi	a4,a4,32
    8000302a:	fed790e3          	bne	a5,a3,8000300a <sigreturn+0x1a>
  p->alarm_goingoff = 0;
    8000302e:	04052023          	sw	zero,64(a0)
  return 0;
}
    80003032:	4501                	li	a0,0
    80003034:	60a2                	ld	ra,8(sp)
    80003036:	6402                	ld	s0,0(sp)
    80003038:	0141                	addi	sp,sp,16
    8000303a:	8082                	ret

000000008000303c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000303c:	1141                	addi	sp,sp,-16
    8000303e:	e406                	sd	ra,8(sp)
    80003040:	e022                	sd	s0,0(sp)
    80003042:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	ab8080e7          	jalr	-1352(ra) # 80001afc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000304c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003050:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003052:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003056:	00004697          	auipc	a3,0x4
    8000305a:	faa68693          	addi	a3,a3,-86 # 80007000 <_trampoline>
    8000305e:	00004717          	auipc	a4,0x4
    80003062:	fa270713          	addi	a4,a4,-94 # 80007000 <_trampoline>
    80003066:	8f15                	sub	a4,a4,a3
    80003068:	040007b7          	lui	a5,0x4000
    8000306c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000306e:	07b2                	slli	a5,a5,0xc
    80003070:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003072:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003076:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003078:	18002673          	csrr	a2,satp
    8000307c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000307e:	7530                	ld	a2,104(a0)
    80003080:	6938                	ld	a4,80(a0)
    80003082:	6585                	lui	a1,0x1
    80003084:	972e                	add	a4,a4,a1
    80003086:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003088:	7538                	ld	a4,104(a0)
    8000308a:	00000617          	auipc	a2,0x0
    8000308e:	29660613          	addi	a2,a2,662 # 80003320 <usertrap>
    80003092:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003094:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003096:	8612                	mv	a2,tp
    80003098:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000309a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000309e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800030a2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030a6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800030aa:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ac:	6f18                	ld	a4,24(a4)
    800030ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800030b2:	7128                	ld	a0,96(a0)
    800030b4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800030b6:	00004717          	auipc	a4,0x4
    800030ba:	fe670713          	addi	a4,a4,-26 # 8000709c <userret>
    800030be:	8f15                	sub	a4,a4,a3
    800030c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800030c2:	577d                	li	a4,-1
    800030c4:	177e                	slli	a4,a4,0x3f
    800030c6:	8d59                	or	a0,a0,a4
    800030c8:	9782                	jalr	a5
}
    800030ca:	60a2                	ld	ra,8(sp)
    800030cc:	6402                	ld	s0,0(sp)
    800030ce:	0141                	addi	sp,sp,16
    800030d0:	8082                	ret

00000000800030d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	e04a                	sd	s2,0(sp)
    800030dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030de:	00237917          	auipc	s2,0x237
    800030e2:	3f290913          	addi	s2,s2,1010 # 8023a4d0 <tickslock>
    800030e6:	854a                	mv	a0,s2
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	c24080e7          	jalr	-988(ra) # 80000d0c <acquire>
  ticks++;
    800030f0:	00006497          	auipc	s1,0x6
    800030f4:	aa048493          	addi	s1,s1,-1376 # 80008b90 <ticks>
    800030f8:	409c                	lw	a5,0(s1)
    800030fa:	2785                	addiw	a5,a5,1
    800030fc:	c09c                	sw	a5,0(s1)
  update_time();
    800030fe:	fffff097          	auipc	ra,0xfffff
    80003102:	d4e080e7          	jalr	-690(ra) # 80001e4c <update_time>
  wakeup(&ticks);
    80003106:	8526                	mv	a0,s1
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	47c080e7          	jalr	1148(ra) # 80002584 <wakeup>
  release(&tickslock);
    80003110:	854a                	mv	a0,s2
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	cae080e7          	jalr	-850(ra) # 80000dc0 <release>
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6902                	ld	s2,0(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003126:	1101                	addi	sp,sp,-32
    80003128:	ec06                	sd	ra,24(sp)
    8000312a:	e822                	sd	s0,16(sp)
    8000312c:	e426                	sd	s1,8(sp)
    8000312e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003130:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003134:	00074d63          	bltz	a4,8000314e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003138:	57fd                	li	a5,-1
    8000313a:	17fe                	slli	a5,a5,0x3f
    8000313c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000313e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003140:	06f70363          	beq	a4,a5,800031a6 <devintr+0x80>
  }
}
    80003144:	60e2                	ld	ra,24(sp)
    80003146:	6442                	ld	s0,16(sp)
    80003148:	64a2                	ld	s1,8(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
     (scause & 0xff) == 9){
    8000314e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80003152:	46a5                	li	a3,9
    80003154:	fed792e3          	bne	a5,a3,80003138 <devintr+0x12>
    int irq = plic_claim();
    80003158:	00003097          	auipc	ra,0x3
    8000315c:	710080e7          	jalr	1808(ra) # 80006868 <plic_claim>
    80003160:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003162:	47a9                	li	a5,10
    80003164:	02f50763          	beq	a0,a5,80003192 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003168:	4785                	li	a5,1
    8000316a:	02f50963          	beq	a0,a5,8000319c <devintr+0x76>
    return 1;
    8000316e:	4505                	li	a0,1
    } else if(irq){
    80003170:	d8f1                	beqz	s1,80003144 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003172:	85a6                	mv	a1,s1
    80003174:	00005517          	auipc	a0,0x5
    80003178:	1c450513          	addi	a0,a0,452 # 80008338 <states.0+0x38>
    8000317c:	ffffd097          	auipc	ra,0xffffd
    80003180:	40e080e7          	jalr	1038(ra) # 8000058a <printf>
      plic_complete(irq);
    80003184:	8526                	mv	a0,s1
    80003186:	00003097          	auipc	ra,0x3
    8000318a:	706080e7          	jalr	1798(ra) # 8000688c <plic_complete>
    return 1;
    8000318e:	4505                	li	a0,1
    80003190:	bf55                	j	80003144 <devintr+0x1e>
      uartintr();
    80003192:	ffffe097          	auipc	ra,0xffffe
    80003196:	806080e7          	jalr	-2042(ra) # 80000998 <uartintr>
    8000319a:	b7ed                	j	80003184 <devintr+0x5e>
      virtio_disk_intr();
    8000319c:	00004097          	auipc	ra,0x4
    800031a0:	bb8080e7          	jalr	-1096(ra) # 80006d54 <virtio_disk_intr>
    800031a4:	b7c5                	j	80003184 <devintr+0x5e>
    if(cpuid() == 0){
    800031a6:	fffff097          	auipc	ra,0xfffff
    800031aa:	92a080e7          	jalr	-1750(ra) # 80001ad0 <cpuid>
    800031ae:	c901                	beqz	a0,800031be <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800031b0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800031b4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800031b6:	14479073          	csrw	sip,a5
    return 2;
    800031ba:	4509                	li	a0,2
    800031bc:	b761                	j	80003144 <devintr+0x1e>
      clockintr();
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	f14080e7          	jalr	-236(ra) # 800030d2 <clockintr>
    800031c6:	b7ed                	j	800031b0 <devintr+0x8a>

00000000800031c8 <kerneltrap>:
{
    800031c8:	7179                	addi	sp,sp,-48
    800031ca:	f406                	sd	ra,40(sp)
    800031cc:	f022                	sd	s0,32(sp)
    800031ce:	ec26                	sd	s1,24(sp)
    800031d0:	e84a                	sd	s2,16(sp)
    800031d2:	e44e                	sd	s3,8(sp)
    800031d4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031d6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031da:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031de:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031e2:	1004f793          	andi	a5,s1,256
    800031e6:	cb85                	beqz	a5,80003216 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031ec:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031ee:	ef85                	bnez	a5,80003226 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	f36080e7          	jalr	-202(ra) # 80003126 <devintr>
    800031f8:	cd1d                	beqz	a0,80003236 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031fa:	4789                	li	a5,2
    800031fc:	06f50a63          	beq	a0,a5,80003270 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003200:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003204:	10049073          	csrw	sstatus,s1
}
    80003208:	70a2                	ld	ra,40(sp)
    8000320a:	7402                	ld	s0,32(sp)
    8000320c:	64e2                	ld	s1,24(sp)
    8000320e:	6942                	ld	s2,16(sp)
    80003210:	69a2                	ld	s3,8(sp)
    80003212:	6145                	addi	sp,sp,48
    80003214:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	14250513          	addi	a0,a0,322 # 80008358 <states.0+0x58>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	322080e7          	jalr	802(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	15a50513          	addi	a0,a0,346 # 80008380 <states.0+0x80>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	312080e7          	jalr	786(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003236:	85ce                	mv	a1,s3
    80003238:	00005517          	auipc	a0,0x5
    8000323c:	16850513          	addi	a0,a0,360 # 800083a0 <states.0+0xa0>
    80003240:	ffffd097          	auipc	ra,0xffffd
    80003244:	34a080e7          	jalr	842(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003248:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000324c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003250:	00005517          	auipc	a0,0x5
    80003254:	16050513          	addi	a0,a0,352 # 800083b0 <states.0+0xb0>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	332080e7          	jalr	818(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003260:	00005517          	auipc	a0,0x5
    80003264:	16850513          	addi	a0,a0,360 # 800083c8 <states.0+0xc8>
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	2d8080e7          	jalr	728(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	88c080e7          	jalr	-1908(ra) # 80001afc <myproc>
    80003278:	d541                	beqz	a0,80003200 <kerneltrap+0x38>
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	882080e7          	jalr	-1918(ra) # 80001afc <myproc>
    80003282:	4d18                	lw	a4,24(a0)
    80003284:	4791                	li	a5,4
    80003286:	f6f71de3          	bne	a4,a5,80003200 <kerneltrap+0x38>
    yield();
    8000328a:	fffff097          	auipc	ra,0xfffff
    8000328e:	25a080e7          	jalr	602(ra) # 800024e4 <yield>
    80003292:	b7bd                	j	80003200 <kerneltrap+0x38>

0000000080003294 <cowfault>:
int cowfault(pagetable_t pagetable, uint64 va)
{
  // invalid if va is more than max va
  if (va >= MAXVA)
    return -1;
  if(va == 0)
    80003294:	fff58713          	addi	a4,a1,-1 # fff <_entry-0x7ffff001>
    80003298:	f80007b7          	lui	a5,0xf8000
    8000329c:	83e9                	srli	a5,a5,0x1a
    8000329e:	06e7e963          	bltu	a5,a4,80003310 <cowfault+0x7c>
{
    800032a2:	7179                	addi	sp,sp,-48
    800032a4:	f406                	sd	ra,40(sp)
    800032a6:	f022                	sd	s0,32(sp)
    800032a8:	ec26                	sd	s1,24(sp)
    800032aa:	e84a                	sd	s2,16(sp)
    800032ac:	e44e                	sd	s3,8(sp)
    800032ae:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pte = walk(pagetable, va, 0);
    800032b0:	4601                	li	a2,0
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	e3a080e7          	jalr	-454(ra) # 800010ec <walk>
    800032ba:	892a                	mv	s2,a0
  // invalid if va is not in pg table
  if (pte == 0)
    800032bc:	cd21                	beqz	a0,80003314 <cowfault+0x80>
    return -1;
  // invalid if va is not set user bit or valid bit
  if ((*pte & PTE_V) == 0 || (*pte & PTE_U) == 0)
    800032be:	611c                	ld	a5,0(a0)
    800032c0:	8bc5                	andi	a5,a5,17
    800032c2:	4745                	li	a4,17
    800032c4:	04e79a63          	bne	a5,a4,80003318 <cowfault+0x84>
    return -1;
  uint64 page2 = (uint64)kalloc();
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	91c080e7          	jalr	-1764(ra) # 80000be4 <kalloc>
    800032d0:	84aa                	mv	s1,a0
  uint64 page1 = PTE2PA(*pte);
    800032d2:	00093983          	ld	s3,0(s2)
    800032d6:	00a9d993          	srli	s3,s3,0xa
    800032da:	09b2                	slli	s3,s3,0xc
  
  // error handling
  if (page2 == 0){
    800032dc:	c121                	beqz	a0,8000331c <cowfault+0x88>
    return -1;
  }
 
  memmove((void *)page2, (void *)page1, PGSIZE);
    800032de:	6605                	lui	a2,0x1
    800032e0:	85ce                	mv	a1,s3
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	b82080e7          	jalr	-1150(ra) # 80000e64 <memmove>
  *pte = PA2PTE(page2) | PTE_U | PTE_V | PTE_W | PTE_X|PTE_R;
    800032ea:	80b1                	srli	s1,s1,0xc
    800032ec:	04aa                	slli	s1,s1,0xa
    800032ee:	01f4e493          	ori	s1,s1,31
    800032f2:	00993023          	sd	s1,0(s2)
   kfree((void *)page1);
    800032f6:	854e                	mv	a0,s3
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	768080e7          	jalr	1896(ra) # 80000a60 <kfree>
  return 0;
    80003300:	4501                	li	a0,0
    80003302:	70a2                	ld	ra,40(sp)
    80003304:	7402                	ld	s0,32(sp)
    80003306:	64e2                	ld	s1,24(sp)
    80003308:	6942                	ld	s2,16(sp)
    8000330a:	69a2                	ld	s3,8(sp)
    8000330c:	6145                	addi	sp,sp,48
    8000330e:	8082                	ret
    return -1;
    80003310:	557d                	li	a0,-1
    80003312:	8082                	ret
    return -1;
    80003314:	557d                	li	a0,-1
    80003316:	b7f5                	j	80003302 <cowfault+0x6e>
    return -1;
    80003318:	557d                	li	a0,-1
    8000331a:	b7e5                	j	80003302 <cowfault+0x6e>
    return -1;
    8000331c:	557d                	li	a0,-1
    8000331e:	b7d5                	j	80003302 <cowfault+0x6e>

0000000080003320 <usertrap>:
{
    80003320:	1101                	addi	sp,sp,-32
    80003322:	ec06                	sd	ra,24(sp)
    80003324:	e822                	sd	s0,16(sp)
    80003326:	e426                	sd	s1,8(sp)
    80003328:	e04a                	sd	s2,0(sp)
    8000332a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000332c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003330:	1007f793          	andi	a5,a5,256
    80003334:	e7b9                	bnez	a5,80003382 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003336:	00003797          	auipc	a5,0x3
    8000333a:	42a78793          	addi	a5,a5,1066 # 80006760 <kernelvec>
    8000333e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	7ba080e7          	jalr	1978(ra) # 80001afc <myproc>
    8000334a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000334c:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000334e:	14102773          	csrr	a4,sepc
    80003352:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003354:	14202773          	csrr	a4,scause
  if (r_scause() == 15)
    80003358:	47bd                	li	a5,15
    8000335a:	02f70c63          	beq	a4,a5,80003392 <usertrap+0x72>
    8000335e:	14202773          	csrr	a4,scause
  else if(r_scause() == 8){
    80003362:	47a1                	li	a5,8
    80003364:	04f70363          	beq	a4,a5,800033aa <usertrap+0x8a>
  } else if((which_dev = devintr()) != 0){
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	dbe080e7          	jalr	-578(ra) # 80003126 <devintr>
    80003370:	892a                	mv	s2,a0
    80003372:	c549                	beqz	a0,800033fc <usertrap+0xdc>
  if(killed(p))
    80003374:	8526                	mv	a0,s1
    80003376:	fffff097          	auipc	ra,0xfffff
    8000337a:	452080e7          	jalr	1106(ra) # 800027c8 <killed>
    8000337e:	c171                	beqz	a0,80003442 <usertrap+0x122>
    80003380:	a865                	j	80003438 <usertrap+0x118>
    panic("usertrap: not from user mode");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	05650513          	addi	a0,a0,86 # 800083d8 <states.0+0xd8>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003392:	143025f3          	csrr	a1,stval
   if ((cowfault(p->pagetable, r_stval()) )< 0)
    80003396:	7128                	ld	a0,96(a0)
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	efc080e7          	jalr	-260(ra) # 80003294 <cowfault>
    800033a0:	02055863          	bgez	a0,800033d0 <usertrap+0xb0>
     p->killed = 1;
    800033a4:	4785                	li	a5,1
    800033a6:	d49c                	sw	a5,40(s1)
    800033a8:	a025                	j	800033d0 <usertrap+0xb0>
    if(killed(p))
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	41e080e7          	jalr	1054(ra) # 800027c8 <killed>
    800033b2:	ed1d                	bnez	a0,800033f0 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800033b4:	74b8                	ld	a4,104(s1)
    800033b6:	6f1c                	ld	a5,24(a4)
    800033b8:	0791                	addi	a5,a5,4
    800033ba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800033c0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033c4:	10079073          	csrw	sstatus,a5
    syscall();
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	264080e7          	jalr	612(ra) # 8000362c <syscall>
  if(killed(p))
    800033d0:	8526                	mv	a0,s1
    800033d2:	fffff097          	auipc	ra,0xfffff
    800033d6:	3f6080e7          	jalr	1014(ra) # 800027c8 <killed>
    800033da:	ed31                	bnez	a0,80003436 <usertrap+0x116>
  usertrapret();
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	c60080e7          	jalr	-928(ra) # 8000303c <usertrapret>
}
    800033e4:	60e2                	ld	ra,24(sp)
    800033e6:	6442                	ld	s0,16(sp)
    800033e8:	64a2                	ld	s1,8(sp)
    800033ea:	6902                	ld	s2,0(sp)
    800033ec:	6105                	addi	sp,sp,32
    800033ee:	8082                	ret
      exit(-1);
    800033f0:	557d                	li	a0,-1
    800033f2:	fffff097          	auipc	ra,0xfffff
    800033f6:	262080e7          	jalr	610(ra) # 80002654 <exit>
    800033fa:	bf6d                	j	800033b4 <usertrap+0x94>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033fc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003400:	5890                	lw	a2,48(s1)
    80003402:	00005517          	auipc	a0,0x5
    80003406:	ff650513          	addi	a0,a0,-10 # 800083f8 <states.0+0xf8>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	180080e7          	jalr	384(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003412:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003416:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	00e50513          	addi	a0,a0,14 # 80008428 <states.0+0x128>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	168080e7          	jalr	360(ra) # 8000058a <printf>
    setkilled(p);
    8000342a:	8526                	mv	a0,s1
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	370080e7          	jalr	880(ra) # 8000279c <setkilled>
    80003434:	bf71                	j	800033d0 <usertrap+0xb0>
  if(killed(p))
    80003436:	4901                	li	s2,0
    exit(-1);
    80003438:	557d                	li	a0,-1
    8000343a:	fffff097          	auipc	ra,0xfffff
    8000343e:	21a080e7          	jalr	538(ra) # 80002654 <exit>
  if(which_dev == 2)
    80003442:	4789                	li	a5,2
    80003444:	f8f91ce3          	bne	s2,a5,800033dc <usertrap+0xbc>
    if(p->alarm_interval != 0) 
    80003448:	2084a703          	lw	a4,520(s1)
    8000344c:	cb11                	beqz	a4,80003460 <usertrap+0x140>
      if(--p->alarm_ticks <= 0) 
    8000344e:	2184a783          	lw	a5,536(s1)
    80003452:	37fd                	addiw	a5,a5,-1
    80003454:	0007869b          	sext.w	a3,a5
    80003458:	20f4ac23          	sw	a5,536(s1)
    8000345c:	00d05763          	blez	a3,8000346a <usertrap+0x14a>
    yield();
    80003460:	fffff097          	auipc	ra,0xfffff
    80003464:	084080e7          	jalr	132(ra) # 800024e4 <yield>
    80003468:	bf95                	j	800033dc <usertrap+0xbc>
        if(!p->alarm_goingoff) 
    8000346a:	40bc                	lw	a5,64(s1)
    8000346c:	fbf5                	bnez	a5,80003460 <usertrap+0x140>
          p->alarm_ticks = p->alarm_interval;
    8000346e:	20e4ac23          	sw	a4,536(s1)
          *p->alarm_trapframe = *p->trapframe; // backup trapframe
    80003472:	74b4                	ld	a3,104(s1)
    80003474:	87b6                	mv	a5,a3
    80003476:	7c98                	ld	a4,56(s1)
    80003478:	12068693          	addi	a3,a3,288
    8000347c:	0007b803          	ld	a6,0(a5)
    80003480:	6788                	ld	a0,8(a5)
    80003482:	6b8c                	ld	a1,16(a5)
    80003484:	6f90                	ld	a2,24(a5)
    80003486:	01073023          	sd	a6,0(a4)
    8000348a:	e708                	sd	a0,8(a4)
    8000348c:	eb0c                	sd	a1,16(a4)
    8000348e:	ef10                	sd	a2,24(a4)
    80003490:	02078793          	addi	a5,a5,32
    80003494:	02070713          	addi	a4,a4,32
    80003498:	fed792e3          	bne	a5,a3,8000347c <usertrap+0x15c>
          p->trapframe->epc = (uint64)p->alarm_handler;
    8000349c:	74bc                	ld	a5,104(s1)
    8000349e:	2104b703          	ld	a4,528(s1)
    800034a2:	ef98                	sd	a4,24(a5)
          p->alarm_goingoff = 1;
    800034a4:	4785                	li	a5,1
    800034a6:	c0bc                	sw	a5,64(s1)
    800034a8:	bf65                	j	80003460 <usertrap+0x140>

00000000800034aa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800034aa:	1101                	addi	sp,sp,-32
    800034ac:	ec06                	sd	ra,24(sp)
    800034ae:	e822                	sd	s0,16(sp)
    800034b0:	e426                	sd	s1,8(sp)
    800034b2:	1000                	addi	s0,sp,32
    800034b4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800034b6:	ffffe097          	auipc	ra,0xffffe
    800034ba:	646080e7          	jalr	1606(ra) # 80001afc <myproc>
  switch (n)
    800034be:	4795                	li	a5,5
    800034c0:	0497e163          	bltu	a5,s1,80003502 <argraw+0x58>
    800034c4:	048a                	slli	s1,s1,0x2
    800034c6:	00005717          	auipc	a4,0x5
    800034ca:	0e270713          	addi	a4,a4,226 # 800085a8 <states.0+0x2a8>
    800034ce:	94ba                	add	s1,s1,a4
    800034d0:	409c                	lw	a5,0(s1)
    800034d2:	97ba                	add	a5,a5,a4
    800034d4:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800034d6:	753c                	ld	a5,104(a0)
    800034d8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800034da:	60e2                	ld	ra,24(sp)
    800034dc:	6442                	ld	s0,16(sp)
    800034de:	64a2                	ld	s1,8(sp)
    800034e0:	6105                	addi	sp,sp,32
    800034e2:	8082                	ret
    return p->trapframe->a1;
    800034e4:	753c                	ld	a5,104(a0)
    800034e6:	7fa8                	ld	a0,120(a5)
    800034e8:	bfcd                	j	800034da <argraw+0x30>
    return p->trapframe->a2;
    800034ea:	753c                	ld	a5,104(a0)
    800034ec:	63c8                	ld	a0,128(a5)
    800034ee:	b7f5                	j	800034da <argraw+0x30>
    return p->trapframe->a3;
    800034f0:	753c                	ld	a5,104(a0)
    800034f2:	67c8                	ld	a0,136(a5)
    800034f4:	b7dd                	j	800034da <argraw+0x30>
    return p->trapframe->a4;
    800034f6:	753c                	ld	a5,104(a0)
    800034f8:	6bc8                	ld	a0,144(a5)
    800034fa:	b7c5                	j	800034da <argraw+0x30>
    return p->trapframe->a5;
    800034fc:	753c                	ld	a5,104(a0)
    800034fe:	6fc8                	ld	a0,152(a5)
    80003500:	bfe9                	j	800034da <argraw+0x30>
  panic("argraw");
    80003502:	00005517          	auipc	a0,0x5
    80003506:	f4650513          	addi	a0,a0,-186 # 80008448 <states.0+0x148>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	036080e7          	jalr	54(ra) # 80000540 <panic>

0000000080003512 <fetchaddr>:
{
    80003512:	1101                	addi	sp,sp,-32
    80003514:	ec06                	sd	ra,24(sp)
    80003516:	e822                	sd	s0,16(sp)
    80003518:	e426                	sd	s1,8(sp)
    8000351a:	e04a                	sd	s2,0(sp)
    8000351c:	1000                	addi	s0,sp,32
    8000351e:	84aa                	mv	s1,a0
    80003520:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003522:	ffffe097          	auipc	ra,0xffffe
    80003526:	5da080e7          	jalr	1498(ra) # 80001afc <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000352a:	6d3c                	ld	a5,88(a0)
    8000352c:	02f4f863          	bgeu	s1,a5,8000355c <fetchaddr+0x4a>
    80003530:	00848713          	addi	a4,s1,8
    80003534:	02e7e663          	bltu	a5,a4,80003560 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003538:	46a1                	li	a3,8
    8000353a:	8626                	mv	a2,s1
    8000353c:	85ca                	mv	a1,s2
    8000353e:	7128                	ld	a0,96(a0)
    80003540:	ffffe097          	auipc	ra,0xffffe
    80003544:	308080e7          	jalr	776(ra) # 80001848 <copyin>
    80003548:	00a03533          	snez	a0,a0
    8000354c:	40a00533          	neg	a0,a0
}
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	64a2                	ld	s1,8(sp)
    80003556:	6902                	ld	s2,0(sp)
    80003558:	6105                	addi	sp,sp,32
    8000355a:	8082                	ret
    return -1;
    8000355c:	557d                	li	a0,-1
    8000355e:	bfcd                	j	80003550 <fetchaddr+0x3e>
    80003560:	557d                	li	a0,-1
    80003562:	b7fd                	j	80003550 <fetchaddr+0x3e>

0000000080003564 <fetchstr>:
{
    80003564:	7179                	addi	sp,sp,-48
    80003566:	f406                	sd	ra,40(sp)
    80003568:	f022                	sd	s0,32(sp)
    8000356a:	ec26                	sd	s1,24(sp)
    8000356c:	e84a                	sd	s2,16(sp)
    8000356e:	e44e                	sd	s3,8(sp)
    80003570:	1800                	addi	s0,sp,48
    80003572:	892a                	mv	s2,a0
    80003574:	84ae                	mv	s1,a1
    80003576:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003578:	ffffe097          	auipc	ra,0xffffe
    8000357c:	584080e7          	jalr	1412(ra) # 80001afc <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003580:	86ce                	mv	a3,s3
    80003582:	864a                	mv	a2,s2
    80003584:	85a6                	mv	a1,s1
    80003586:	7128                	ld	a0,96(a0)
    80003588:	ffffe097          	auipc	ra,0xffffe
    8000358c:	34e080e7          	jalr	846(ra) # 800018d6 <copyinstr>
    80003590:	00054e63          	bltz	a0,800035ac <fetchstr+0x48>
  return strlen(buf);
    80003594:	8526                	mv	a0,s1
    80003596:	ffffe097          	auipc	ra,0xffffe
    8000359a:	9ee080e7          	jalr	-1554(ra) # 80000f84 <strlen>
}
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6145                	addi	sp,sp,48
    800035aa:	8082                	ret
    return -1;
    800035ac:	557d                	li	a0,-1
    800035ae:	bfc5                	j	8000359e <fetchstr+0x3a>

00000000800035b0 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    800035b0:	1101                	addi	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	e426                	sd	s1,8(sp)
    800035b8:	1000                	addi	s0,sp,32
    800035ba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	eee080e7          	jalr	-274(ra) # 800034aa <argraw>
    800035c4:	c088                	sw	a0,0(s1)
  return (0);
}
    800035c6:	4501                	li	a0,0
    800035c8:	60e2                	ld	ra,24(sp)
    800035ca:	6442                	ld	s0,16(sp)
    800035cc:	64a2                	ld	s1,8(sp)
    800035ce:	6105                	addi	sp,sp,32
    800035d0:	8082                	ret

00000000800035d2 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    800035d2:	1101                	addi	sp,sp,-32
    800035d4:	ec06                	sd	ra,24(sp)
    800035d6:	e822                	sd	s0,16(sp)
    800035d8:	e426                	sd	s1,8(sp)
    800035da:	1000                	addi	s0,sp,32
    800035dc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	ecc080e7          	jalr	-308(ra) # 800034aa <argraw>
    800035e6:	e088                	sd	a0,0(s1)
  return (0);
}
    800035e8:	4501                	li	a0,0
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret

00000000800035f4 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800035f4:	7179                	addi	sp,sp,-48
    800035f6:	f406                	sd	ra,40(sp)
    800035f8:	f022                	sd	s0,32(sp)
    800035fa:	ec26                	sd	s1,24(sp)
    800035fc:	e84a                	sd	s2,16(sp)
    800035fe:	1800                	addi	s0,sp,48
    80003600:	84ae                	mv	s1,a1
    80003602:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003604:	fd840593          	addi	a1,s0,-40
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	fca080e7          	jalr	-54(ra) # 800035d2 <argaddr>
  return fetchstr(addr, buf, max);
    80003610:	864a                	mv	a2,s2
    80003612:	85a6                	mv	a1,s1
    80003614:	fd843503          	ld	a0,-40(s0)
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	f4c080e7          	jalr	-180(ra) # 80003564 <fetchstr>
}
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	6145                	addi	sp,sp,48
    8000362a:	8082                	ret

000000008000362c <syscall>:
static char *syscall_list[25] = {
    "mkdir", "close", "trace", "-", "fork", "exit", "wait", "pipe", "open", "write", "mknod", "unlink", "link", "dup", "getpid", "sbrk", "sleep", "uptime", "read", "kill", "exec", "fstat", "chdir", "sigalarm", "sigreturn"
};

void syscall(void)
{
    8000362c:	7179                	addi	sp,sp,-48
    8000362e:	f406                	sd	ra,40(sp)
    80003630:	f022                	sd	s0,32(sp)
    80003632:	ec26                	sd	s1,24(sp)
    80003634:	e84a                	sd	s2,16(sp)
    80003636:	e44e                	sd	s3,8(sp)
    80003638:	e052                	sd	s4,0(sp)
    8000363a:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    8000363c:	ffffe097          	auipc	ra,0xffffe
    80003640:	4c0080e7          	jalr	1216(ra) # 80001afc <myproc>
    80003644:	84aa                	mv	s1,a0
  
  num = p->trapframe->a7;
    80003646:	06853903          	ld	s2,104(a0)
    8000364a:	0a893783          	ld	a5,168(s2)
    8000364e:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003652:	37fd                	addiw	a5,a5,-1
    80003654:	475d                	li	a4,23
    80003656:	0cf76963          	bltu	a4,a5,80003728 <syscall+0xfc>
    8000365a:	00399713          	slli	a4,s3,0x3
    8000365e:	00005797          	auipc	a5,0x5
    80003662:	f6278793          	addi	a5,a5,-158 # 800085c0 <syscalls>
    80003666:	97ba                	add	a5,a5,a4
    80003668:	639c                	ld	a5,0(a5)
    8000366a:	cfdd                	beqz	a5,80003728 <syscall+0xfc>
  {
    // Use num to lookup the system call function for num, call it, and store its return value in p->trapframe->a0
    int x = p->trapframe->a0;
    8000366c:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80003670:	9782                	jalr	a5
    80003672:	06a93823          	sd	a0,112(s2)
    if (p->mask & (1 << num))           // using bitwise operator to compute through the mask
    80003676:	58dc                	lw	a5,52(s1)
    80003678:	4137d7bb          	sraw	a5,a5,s3
    8000367c:	8b85                	andi	a5,a5,1
    8000367e:	c7e1                	beqz	a5,80003746 <syscall+0x11a>
    int x = p->trapframe->a0;
    80003680:	000a069b          	sext.w	a3,s4
    {
      if (numargs[num] == 3)
    80003684:	00299713          	slli	a4,s3,0x2
    80003688:	00005797          	auipc	a5,0x5
    8000368c:	f3878793          	addi	a5,a5,-200 # 800085c0 <syscalls>
    80003690:	97ba                	add	a5,a5,a4
    80003692:	0c87a783          	lw	a5,200(a5)
    80003696:	470d                	li	a4,3
    80003698:	02e78d63          	beq	a5,a4,800036d2 <syscall+0xa6>
        printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_list[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
      if (numargs[num] == 1)
    8000369c:	4705                	li	a4,1
    8000369e:	06e78163          	beq	a5,a4,80003700 <syscall+0xd4>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_list[num], x, p->trapframe->a0);
      if (numargs[num] == 2)
    800036a2:	4709                	li	a4,2
    800036a4:	0ae79163          	bne	a5,a4,80003746 <syscall+0x11a>
        printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_list[num], x, p->trapframe->a1, p->trapframe->a0);
    800036a8:	74b8                	ld	a4,104(s1)
    800036aa:	098e                	slli	s3,s3,0x3
    800036ac:	00005617          	auipc	a2,0x5
    800036b0:	f1460613          	addi	a2,a2,-236 # 800085c0 <syscalls>
    800036b4:	964e                	add	a2,a2,s3
    800036b6:	7b3c                	ld	a5,112(a4)
    800036b8:	7f38                	ld	a4,120(a4)
    800036ba:	13063603          	ld	a2,304(a2)
    800036be:	588c                	lw	a1,48(s1)
    800036c0:	00005517          	auipc	a0,0x5
    800036c4:	dd850513          	addi	a0,a0,-552 # 80008498 <states.0+0x198>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	ec2080e7          	jalr	-318(ra) # 8000058a <printf>
    800036d0:	a89d                	j	80003746 <syscall+0x11a>
        printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_list[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
    800036d2:	74b8                	ld	a4,104(s1)
    800036d4:	098e                	slli	s3,s3,0x3
    800036d6:	00005617          	auipc	a2,0x5
    800036da:	eea60613          	addi	a2,a2,-278 # 800085c0 <syscalls>
    800036de:	964e                	add	a2,a2,s3
    800036e0:	07073803          	ld	a6,112(a4)
    800036e4:	635c                	ld	a5,128(a4)
    800036e6:	7f38                	ld	a4,120(a4)
    800036e8:	13063603          	ld	a2,304(a2)
    800036ec:	588c                	lw	a1,48(s1)
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	d6250513          	addi	a0,a0,-670 # 80008450 <states.0+0x150>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e94080e7          	jalr	-364(ra) # 8000058a <printf>
      if (numargs[num] == 2)
    800036fe:	a0a1                	j	80003746 <syscall+0x11a>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_list[num], x, p->trapframe->a0);
    80003700:	74b8                	ld	a4,104(s1)
    80003702:	098e                	slli	s3,s3,0x3
    80003704:	00005797          	auipc	a5,0x5
    80003708:	ebc78793          	addi	a5,a5,-324 # 800085c0 <syscalls>
    8000370c:	97ce                	add	a5,a5,s3
    8000370e:	7b38                	ld	a4,112(a4)
    80003710:	1307b603          	ld	a2,304(a5)
    80003714:	588c                	lw	a1,48(s1)
    80003716:	00005517          	auipc	a0,0x5
    8000371a:	d6250513          	addi	a0,a0,-670 # 80008478 <states.0+0x178>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e6c080e7          	jalr	-404(ra) # 8000058a <printf>
      if (numargs[num] == 2)
    80003726:	a005                	j	80003746 <syscall+0x11a>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003728:	86ce                	mv	a3,s3
    8000372a:	16848613          	addi	a2,s1,360
    8000372e:	588c                	lw	a1,48(s1)
    80003730:	00005517          	auipc	a0,0x5
    80003734:	d8850513          	addi	a0,a0,-632 # 800084b8 <states.0+0x1b8>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e52080e7          	jalr	-430(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003740:	74bc                	ld	a5,104(s1)
    80003742:	577d                	li	a4,-1
    80003744:	fbb8                	sd	a4,112(a5)
  }
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6a02                	ld	s4,0(sp)
    80003752:	6145                	addi	sp,sp,48
    80003754:	8082                	ret

0000000080003756 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000375e:	fec40593          	addi	a1,s0,-20
    80003762:	4501                	li	a0,0
    80003764:	00000097          	auipc	ra,0x0
    80003768:	e4c080e7          	jalr	-436(ra) # 800035b0 <argint>
  exit(n);
    8000376c:	fec42503          	lw	a0,-20(s0)
    80003770:	fffff097          	auipc	ra,0xfffff
    80003774:	ee4080e7          	jalr	-284(ra) # 80002654 <exit>
  return 0; // not reached
}
    80003778:	4501                	li	a0,0
    8000377a:	60e2                	ld	ra,24(sp)
    8000377c:	6442                	ld	s0,16(sp)
    8000377e:	6105                	addi	sp,sp,32
    80003780:	8082                	ret

0000000080003782 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003782:	1141                	addi	sp,sp,-16
    80003784:	e406                	sd	ra,8(sp)
    80003786:	e022                	sd	s0,0(sp)
    80003788:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000378a:	ffffe097          	auipc	ra,0xffffe
    8000378e:	372080e7          	jalr	882(ra) # 80001afc <myproc>
}
    80003792:	5908                	lw	a0,48(a0)
    80003794:	60a2                	ld	ra,8(sp)
    80003796:	6402                	ld	s0,0(sp)
    80003798:	0141                	addi	sp,sp,16
    8000379a:	8082                	ret

000000008000379c <sys_fork>:

uint64
sys_fork(void)
{
    8000379c:	1141                	addi	sp,sp,-16
    8000379e:	e406                	sd	ra,8(sp)
    800037a0:	e022                	sd	s0,0(sp)
    800037a2:	0800                	addi	s0,sp,16
  return fork();
    800037a4:	fffff097          	auipc	ra,0xfffff
    800037a8:	802080e7          	jalr	-2046(ra) # 80001fa6 <fork>
}
    800037ac:	60a2                	ld	ra,8(sp)
    800037ae:	6402                	ld	s0,0(sp)
    800037b0:	0141                	addi	sp,sp,16
    800037b2:	8082                	ret

00000000800037b4 <sys_wait>:

uint64
sys_wait(void)
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800037bc:	fe840593          	addi	a1,s0,-24
    800037c0:	4501                	li	a0,0
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	e10080e7          	jalr	-496(ra) # 800035d2 <argaddr>
  return wait(p);
    800037ca:	fe843503          	ld	a0,-24(s0)
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	02c080e7          	jalr	44(ra) # 800027fa <wait>
}
    800037d6:	60e2                	ld	ra,24(sp)
    800037d8:	6442                	ld	s0,16(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret

00000000800037de <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800037de:	7179                	addi	sp,sp,-48
    800037e0:	f406                	sd	ra,40(sp)
    800037e2:	f022                	sd	s0,32(sp)
    800037e4:	ec26                	sd	s1,24(sp)
    800037e6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800037e8:	fdc40593          	addi	a1,s0,-36
    800037ec:	4501                	li	a0,0
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	dc2080e7          	jalr	-574(ra) # 800035b0 <argint>
  addr = myproc()->sz;
    800037f6:	ffffe097          	auipc	ra,0xffffe
    800037fa:	306080e7          	jalr	774(ra) # 80001afc <myproc>
    800037fe:	6d24                	ld	s1,88(a0)
  if (growproc(n) < 0)
    80003800:	fdc42503          	lw	a0,-36(s0)
    80003804:	ffffe097          	auipc	ra,0xffffe
    80003808:	746080e7          	jalr	1862(ra) # 80001f4a <growproc>
    8000380c:	00054863          	bltz	a0,8000381c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003810:	8526                	mv	a0,s1
    80003812:	70a2                	ld	ra,40(sp)
    80003814:	7402                	ld	s0,32(sp)
    80003816:	64e2                	ld	s1,24(sp)
    80003818:	6145                	addi	sp,sp,48
    8000381a:	8082                	ret
    return -1;
    8000381c:	54fd                	li	s1,-1
    8000381e:	bfcd                	j	80003810 <sys_sbrk+0x32>

0000000080003820 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003820:	7139                	addi	sp,sp,-64
    80003822:	fc06                	sd	ra,56(sp)
    80003824:	f822                	sd	s0,48(sp)
    80003826:	f426                	sd	s1,40(sp)
    80003828:	f04a                	sd	s2,32(sp)
    8000382a:	ec4e                	sd	s3,24(sp)
    8000382c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000382e:	fcc40593          	addi	a1,s0,-52
    80003832:	4501                	li	a0,0
    80003834:	00000097          	auipc	ra,0x0
    80003838:	d7c080e7          	jalr	-644(ra) # 800035b0 <argint>
  acquire(&tickslock);
    8000383c:	00237517          	auipc	a0,0x237
    80003840:	c9450513          	addi	a0,a0,-876 # 8023a4d0 <tickslock>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	4c8080e7          	jalr	1224(ra) # 80000d0c <acquire>
  ticks0 = ticks;
    8000384c:	00005917          	auipc	s2,0x5
    80003850:	34492903          	lw	s2,836(s2) # 80008b90 <ticks>
  while (ticks - ticks0 < n)
    80003854:	fcc42783          	lw	a5,-52(s0)
    80003858:	cf9d                	beqz	a5,80003896 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000385a:	00237997          	auipc	s3,0x237
    8000385e:	c7698993          	addi	s3,s3,-906 # 8023a4d0 <tickslock>
    80003862:	00005497          	auipc	s1,0x5
    80003866:	32e48493          	addi	s1,s1,814 # 80008b90 <ticks>
    if (killed(myproc()))
    8000386a:	ffffe097          	auipc	ra,0xffffe
    8000386e:	292080e7          	jalr	658(ra) # 80001afc <myproc>
    80003872:	fffff097          	auipc	ra,0xfffff
    80003876:	f56080e7          	jalr	-170(ra) # 800027c8 <killed>
    8000387a:	ed15                	bnez	a0,800038b6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000387c:	85ce                	mv	a1,s3
    8000387e:	8526                	mv	a0,s1
    80003880:	fffff097          	auipc	ra,0xfffff
    80003884:	ca0080e7          	jalr	-864(ra) # 80002520 <sleep>
  while (ticks - ticks0 < n)
    80003888:	409c                	lw	a5,0(s1)
    8000388a:	412787bb          	subw	a5,a5,s2
    8000388e:	fcc42703          	lw	a4,-52(s0)
    80003892:	fce7ece3          	bltu	a5,a4,8000386a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003896:	00237517          	auipc	a0,0x237
    8000389a:	c3a50513          	addi	a0,a0,-966 # 8023a4d0 <tickslock>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	522080e7          	jalr	1314(ra) # 80000dc0 <release>
  return 0;
    800038a6:	4501                	li	a0,0
}
    800038a8:	70e2                	ld	ra,56(sp)
    800038aa:	7442                	ld	s0,48(sp)
    800038ac:	74a2                	ld	s1,40(sp)
    800038ae:	7902                	ld	s2,32(sp)
    800038b0:	69e2                	ld	s3,24(sp)
    800038b2:	6121                	addi	sp,sp,64
    800038b4:	8082                	ret
      release(&tickslock);
    800038b6:	00237517          	auipc	a0,0x237
    800038ba:	c1a50513          	addi	a0,a0,-998 # 8023a4d0 <tickslock>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	502080e7          	jalr	1282(ra) # 80000dc0 <release>
      return -1;
    800038c6:	557d                	li	a0,-1
    800038c8:	b7c5                	j	800038a8 <sys_sleep+0x88>

00000000800038ca <sys_kill>:

uint64
sys_kill(void)
{
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800038d2:	fec40593          	addi	a1,s0,-20
    800038d6:	4501                	li	a0,0
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	cd8080e7          	jalr	-808(ra) # 800035b0 <argint>
  return kill(pid);
    800038e0:	fec42503          	lw	a0,-20(s0)
    800038e4:	fffff097          	auipc	ra,0xfffff
    800038e8:	e46080e7          	jalr	-442(ra) # 8000272a <kill>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	6105                	addi	sp,sp,32
    800038f2:	8082                	ret

00000000800038f4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038fe:	00237517          	auipc	a0,0x237
    80003902:	bd250513          	addi	a0,a0,-1070 # 8023a4d0 <tickslock>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	406080e7          	jalr	1030(ra) # 80000d0c <acquire>
  xticks = ticks;
    8000390e:	00005497          	auipc	s1,0x5
    80003912:	2824a483          	lw	s1,642(s1) # 80008b90 <ticks>
  release(&tickslock);
    80003916:	00237517          	auipc	a0,0x237
    8000391a:	bba50513          	addi	a0,a0,-1094 # 8023a4d0 <tickslock>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	4a2080e7          	jalr	1186(ra) # 80000dc0 <release>
  return xticks;
}
    80003926:	02049513          	slli	a0,s1,0x20
    8000392a:	9101                	srli	a0,a0,0x20
    8000392c:	60e2                	ld	ra,24(sp)
    8000392e:	6442                	ld	s0,16(sp)
    80003930:	64a2                	ld	s1,8(sp)
    80003932:	6105                	addi	sp,sp,32
    80003934:	8082                	ret

0000000080003936 <sys_trace>:

// implement trace system call
uint64
sys_trace(void)
{
    80003936:	1101                	addi	sp,sp,-32
    80003938:	ec06                	sd	ra,24(sp)
    8000393a:	e822                	sd	s0,16(sp)
    8000393c:	1000                	addi	s0,sp,32
  int mask;
  if (argint(0, &mask) < 0)
    8000393e:	fec40593          	addi	a1,s0,-20
    80003942:	4501                	li	a0,0
    80003944:	00000097          	auipc	ra,0x0
    80003948:	c6c080e7          	jalr	-916(ra) # 800035b0 <argint>
    return -1;
    8000394c:	57fd                	li	a5,-1
  if (argint(0, &mask) < 0)
    8000394e:	00054a63          	bltz	a0,80003962 <sys_trace+0x2c>
  myproc()->mask = mask;
    80003952:	ffffe097          	auipc	ra,0xffffe
    80003956:	1aa080e7          	jalr	426(ra) # 80001afc <myproc>
    8000395a:	fec42783          	lw	a5,-20(s0)
    8000395e:	d95c                	sw	a5,52(a0)
  return 0;
    80003960:	4781                	li	a5,0
}
    80003962:	853e                	mv	a0,a5
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	6105                	addi	sp,sp,32
    8000396a:	8082                	ret

000000008000396c <sys_sigalarm>:

uint64 sys_sigalarm(void) {
    8000396c:	1101                	addi	sp,sp,-32
    8000396e:	ec06                	sd	ra,24(sp)
    80003970:	e822                	sd	s0,16(sp)
    80003972:	1000                	addi	s0,sp,32
  int n;
  uint64 fn;
  // if number of ticks is negative, return -1
  if(argint(0, &n) < 0)
    80003974:	fec40593          	addi	a1,s0,-20
    80003978:	4501                	li	a0,0
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	c36080e7          	jalr	-970(ra) # 800035b0 <argint>
    return -1;
    80003982:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003984:	02054563          	bltz	a0,800039ae <sys_sigalarm+0x42>
  // if function pointer is not valid, return -1
  if(argaddr(1, &fn) < 0)
    80003988:	fe040593          	addi	a1,s0,-32
    8000398c:	4505                	li	a0,1
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	c44080e7          	jalr	-956(ra) # 800035d2 <argaddr>
    return -1;
    80003996:	57fd                	li	a5,-1
  if(argaddr(1, &fn) < 0)
    80003998:	00054b63          	bltz	a0,800039ae <sys_sigalarm+0x42>
  // if no problems with the arguments, sigalarm is called
  return sigalarm(n, (void(*)())(fn));
    8000399c:	fe043583          	ld	a1,-32(s0)
    800039a0:	fec42503          	lw	a0,-20(s0)
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	61a080e7          	jalr	1562(ra) # 80002fbe <sigalarm>
    800039ac:	87aa                	mv	a5,a0
}
    800039ae:	853e                	mv	a0,a5
    800039b0:	60e2                	ld	ra,24(sp)
    800039b2:	6442                	ld	s0,16(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <sys_sigreturn>:

uint64 sys_sigreturn(void) {
    800039b8:	1141                	addi	sp,sp,-16
    800039ba:	e406                	sd	ra,8(sp)
    800039bc:	e022                	sd	s0,0(sp)
    800039be:	0800                	addi	s0,sp,16
	return sigreturn();
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	630080e7          	jalr	1584(ra) # 80002ff0 <sigreturn>
    800039c8:	60a2                	ld	ra,8(sp)
    800039ca:	6402                	ld	s0,0(sp)
    800039cc:	0141                	addi	sp,sp,16
    800039ce:	8082                	ret

00000000800039d0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800039d0:	7179                	addi	sp,sp,-48
    800039d2:	f406                	sd	ra,40(sp)
    800039d4:	f022                	sd	s0,32(sp)
    800039d6:	ec26                	sd	s1,24(sp)
    800039d8:	e84a                	sd	s2,16(sp)
    800039da:	e44e                	sd	s3,8(sp)
    800039dc:	e052                	sd	s4,0(sp)
    800039de:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800039e0:	00005597          	auipc	a1,0x5
    800039e4:	dd858593          	addi	a1,a1,-552 # 800087b8 <syscall_list+0xc8>
    800039e8:	00237517          	auipc	a0,0x237
    800039ec:	b0050513          	addi	a0,a0,-1280 # 8023a4e8 <bcache>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	28c080e7          	jalr	652(ra) # 80000c7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800039f8:	0023f797          	auipc	a5,0x23f
    800039fc:	af078793          	addi	a5,a5,-1296 # 802424e8 <bcache+0x8000>
    80003a00:	0023f717          	auipc	a4,0x23f
    80003a04:	d5070713          	addi	a4,a4,-688 # 80242750 <bcache+0x8268>
    80003a08:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a0c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a10:	00237497          	auipc	s1,0x237
    80003a14:	af048493          	addi	s1,s1,-1296 # 8023a500 <bcache+0x18>
    b->next = bcache.head.next;
    80003a18:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a1a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a1c:	00005a17          	auipc	s4,0x5
    80003a20:	da4a0a13          	addi	s4,s4,-604 # 800087c0 <syscall_list+0xd0>
    b->next = bcache.head.next;
    80003a24:	2b893783          	ld	a5,696(s2)
    80003a28:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a2a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a2e:	85d2                	mv	a1,s4
    80003a30:	01048513          	addi	a0,s1,16
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	4c8080e7          	jalr	1224(ra) # 80004efc <initsleeplock>
    bcache.head.next->prev = b;
    80003a3c:	2b893783          	ld	a5,696(s2)
    80003a40:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a42:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a46:	45848493          	addi	s1,s1,1112
    80003a4a:	fd349de3          	bne	s1,s3,80003a24 <binit+0x54>
  }
}
    80003a4e:	70a2                	ld	ra,40(sp)
    80003a50:	7402                	ld	s0,32(sp)
    80003a52:	64e2                	ld	s1,24(sp)
    80003a54:	6942                	ld	s2,16(sp)
    80003a56:	69a2                	ld	s3,8(sp)
    80003a58:	6a02                	ld	s4,0(sp)
    80003a5a:	6145                	addi	sp,sp,48
    80003a5c:	8082                	ret

0000000080003a5e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003a5e:	7179                	addi	sp,sp,-48
    80003a60:	f406                	sd	ra,40(sp)
    80003a62:	f022                	sd	s0,32(sp)
    80003a64:	ec26                	sd	s1,24(sp)
    80003a66:	e84a                	sd	s2,16(sp)
    80003a68:	e44e                	sd	s3,8(sp)
    80003a6a:	1800                	addi	s0,sp,48
    80003a6c:	892a                	mv	s2,a0
    80003a6e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003a70:	00237517          	auipc	a0,0x237
    80003a74:	a7850513          	addi	a0,a0,-1416 # 8023a4e8 <bcache>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	294080e7          	jalr	660(ra) # 80000d0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003a80:	0023f497          	auipc	s1,0x23f
    80003a84:	d204b483          	ld	s1,-736(s1) # 802427a0 <bcache+0x82b8>
    80003a88:	0023f797          	auipc	a5,0x23f
    80003a8c:	cc878793          	addi	a5,a5,-824 # 80242750 <bcache+0x8268>
    80003a90:	02f48f63          	beq	s1,a5,80003ace <bread+0x70>
    80003a94:	873e                	mv	a4,a5
    80003a96:	a021                	j	80003a9e <bread+0x40>
    80003a98:	68a4                	ld	s1,80(s1)
    80003a9a:	02e48a63          	beq	s1,a4,80003ace <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003a9e:	449c                	lw	a5,8(s1)
    80003aa0:	ff279ce3          	bne	a5,s2,80003a98 <bread+0x3a>
    80003aa4:	44dc                	lw	a5,12(s1)
    80003aa6:	ff3799e3          	bne	a5,s3,80003a98 <bread+0x3a>
      b->refcnt++;
    80003aaa:	40bc                	lw	a5,64(s1)
    80003aac:	2785                	addiw	a5,a5,1
    80003aae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003ab0:	00237517          	auipc	a0,0x237
    80003ab4:	a3850513          	addi	a0,a0,-1480 # 8023a4e8 <bcache>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	308080e7          	jalr	776(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    80003ac0:	01048513          	addi	a0,s1,16
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	472080e7          	jalr	1138(ra) # 80004f36 <acquiresleep>
      return b;
    80003acc:	a8b9                	j	80003b2a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ace:	0023f497          	auipc	s1,0x23f
    80003ad2:	cca4b483          	ld	s1,-822(s1) # 80242798 <bcache+0x82b0>
    80003ad6:	0023f797          	auipc	a5,0x23f
    80003ada:	c7a78793          	addi	a5,a5,-902 # 80242750 <bcache+0x8268>
    80003ade:	00f48863          	beq	s1,a5,80003aee <bread+0x90>
    80003ae2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003ae4:	40bc                	lw	a5,64(s1)
    80003ae6:	cf81                	beqz	a5,80003afe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ae8:	64a4                	ld	s1,72(s1)
    80003aea:	fee49de3          	bne	s1,a4,80003ae4 <bread+0x86>
  panic("bget: no buffers");
    80003aee:	00005517          	auipc	a0,0x5
    80003af2:	cda50513          	addi	a0,a0,-806 # 800087c8 <syscall_list+0xd8>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	a4a080e7          	jalr	-1462(ra) # 80000540 <panic>
      b->dev = dev;
    80003afe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003b02:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003b06:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b0a:	4785                	li	a5,1
    80003b0c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b0e:	00237517          	auipc	a0,0x237
    80003b12:	9da50513          	addi	a0,a0,-1574 # 8023a4e8 <bcache>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	2aa080e7          	jalr	682(ra) # 80000dc0 <release>
      acquiresleep(&b->lock);
    80003b1e:	01048513          	addi	a0,s1,16
    80003b22:	00001097          	auipc	ra,0x1
    80003b26:	414080e7          	jalr	1044(ra) # 80004f36 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b2a:	409c                	lw	a5,0(s1)
    80003b2c:	cb89                	beqz	a5,80003b3e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b2e:	8526                	mv	a0,s1
    80003b30:	70a2                	ld	ra,40(sp)
    80003b32:	7402                	ld	s0,32(sp)
    80003b34:	64e2                	ld	s1,24(sp)
    80003b36:	6942                	ld	s2,16(sp)
    80003b38:	69a2                	ld	s3,8(sp)
    80003b3a:	6145                	addi	sp,sp,48
    80003b3c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b3e:	4581                	li	a1,0
    80003b40:	8526                	mv	a0,s1
    80003b42:	00003097          	auipc	ra,0x3
    80003b46:	fe0080e7          	jalr	-32(ra) # 80006b22 <virtio_disk_rw>
    b->valid = 1;
    80003b4a:	4785                	li	a5,1
    80003b4c:	c09c                	sw	a5,0(s1)
  return b;
    80003b4e:	b7c5                	j	80003b2e <bread+0xd0>

0000000080003b50 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b50:	1101                	addi	sp,sp,-32
    80003b52:	ec06                	sd	ra,24(sp)
    80003b54:	e822                	sd	s0,16(sp)
    80003b56:	e426                	sd	s1,8(sp)
    80003b58:	1000                	addi	s0,sp,32
    80003b5a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b5c:	0541                	addi	a0,a0,16
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	472080e7          	jalr	1138(ra) # 80004fd0 <holdingsleep>
    80003b66:	cd01                	beqz	a0,80003b7e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003b68:	4585                	li	a1,1
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	00003097          	auipc	ra,0x3
    80003b70:	fb6080e7          	jalr	-74(ra) # 80006b22 <virtio_disk_rw>
}
    80003b74:	60e2                	ld	ra,24(sp)
    80003b76:	6442                	ld	s0,16(sp)
    80003b78:	64a2                	ld	s1,8(sp)
    80003b7a:	6105                	addi	sp,sp,32
    80003b7c:	8082                	ret
    panic("bwrite");
    80003b7e:	00005517          	auipc	a0,0x5
    80003b82:	c6250513          	addi	a0,a0,-926 # 800087e0 <syscall_list+0xf0>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>

0000000080003b8e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003b8e:	1101                	addi	sp,sp,-32
    80003b90:	ec06                	sd	ra,24(sp)
    80003b92:	e822                	sd	s0,16(sp)
    80003b94:	e426                	sd	s1,8(sp)
    80003b96:	e04a                	sd	s2,0(sp)
    80003b98:	1000                	addi	s0,sp,32
    80003b9a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b9c:	01050913          	addi	s2,a0,16
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	00001097          	auipc	ra,0x1
    80003ba6:	42e080e7          	jalr	1070(ra) # 80004fd0 <holdingsleep>
    80003baa:	c92d                	beqz	a0,80003c1c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	3de080e7          	jalr	990(ra) # 80004f8c <releasesleep>

  acquire(&bcache.lock);
    80003bb6:	00237517          	auipc	a0,0x237
    80003bba:	93250513          	addi	a0,a0,-1742 # 8023a4e8 <bcache>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	14e080e7          	jalr	334(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003bc6:	40bc                	lw	a5,64(s1)
    80003bc8:	37fd                	addiw	a5,a5,-1
    80003bca:	0007871b          	sext.w	a4,a5
    80003bce:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003bd0:	eb05                	bnez	a4,80003c00 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003bd2:	68bc                	ld	a5,80(s1)
    80003bd4:	64b8                	ld	a4,72(s1)
    80003bd6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003bd8:	64bc                	ld	a5,72(s1)
    80003bda:	68b8                	ld	a4,80(s1)
    80003bdc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003bde:	0023f797          	auipc	a5,0x23f
    80003be2:	90a78793          	addi	a5,a5,-1782 # 802424e8 <bcache+0x8000>
    80003be6:	2b87b703          	ld	a4,696(a5)
    80003bea:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003bec:	0023f717          	auipc	a4,0x23f
    80003bf0:	b6470713          	addi	a4,a4,-1180 # 80242750 <bcache+0x8268>
    80003bf4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003bf6:	2b87b703          	ld	a4,696(a5)
    80003bfa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003bfc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c00:	00237517          	auipc	a0,0x237
    80003c04:	8e850513          	addi	a0,a0,-1816 # 8023a4e8 <bcache>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	1b8080e7          	jalr	440(ra) # 80000dc0 <release>
}
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6902                	ld	s2,0(sp)
    80003c18:	6105                	addi	sp,sp,32
    80003c1a:	8082                	ret
    panic("brelse");
    80003c1c:	00005517          	auipc	a0,0x5
    80003c20:	bcc50513          	addi	a0,a0,-1076 # 800087e8 <syscall_list+0xf8>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	91c080e7          	jalr	-1764(ra) # 80000540 <panic>

0000000080003c2c <bpin>:

void
bpin(struct buf *b) {
    80003c2c:	1101                	addi	sp,sp,-32
    80003c2e:	ec06                	sd	ra,24(sp)
    80003c30:	e822                	sd	s0,16(sp)
    80003c32:	e426                	sd	s1,8(sp)
    80003c34:	1000                	addi	s0,sp,32
    80003c36:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c38:	00237517          	auipc	a0,0x237
    80003c3c:	8b050513          	addi	a0,a0,-1872 # 8023a4e8 <bcache>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	0cc080e7          	jalr	204(ra) # 80000d0c <acquire>
  b->refcnt++;
    80003c48:	40bc                	lw	a5,64(s1)
    80003c4a:	2785                	addiw	a5,a5,1
    80003c4c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c4e:	00237517          	auipc	a0,0x237
    80003c52:	89a50513          	addi	a0,a0,-1894 # 8023a4e8 <bcache>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	16a080e7          	jalr	362(ra) # 80000dc0 <release>
}
    80003c5e:	60e2                	ld	ra,24(sp)
    80003c60:	6442                	ld	s0,16(sp)
    80003c62:	64a2                	ld	s1,8(sp)
    80003c64:	6105                	addi	sp,sp,32
    80003c66:	8082                	ret

0000000080003c68 <bunpin>:

void
bunpin(struct buf *b) {
    80003c68:	1101                	addi	sp,sp,-32
    80003c6a:	ec06                	sd	ra,24(sp)
    80003c6c:	e822                	sd	s0,16(sp)
    80003c6e:	e426                	sd	s1,8(sp)
    80003c70:	1000                	addi	s0,sp,32
    80003c72:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c74:	00237517          	auipc	a0,0x237
    80003c78:	87450513          	addi	a0,a0,-1932 # 8023a4e8 <bcache>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	090080e7          	jalr	144(ra) # 80000d0c <acquire>
  b->refcnt--;
    80003c84:	40bc                	lw	a5,64(s1)
    80003c86:	37fd                	addiw	a5,a5,-1
    80003c88:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c8a:	00237517          	auipc	a0,0x237
    80003c8e:	85e50513          	addi	a0,a0,-1954 # 8023a4e8 <bcache>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	12e080e7          	jalr	302(ra) # 80000dc0 <release>
}
    80003c9a:	60e2                	ld	ra,24(sp)
    80003c9c:	6442                	ld	s0,16(sp)
    80003c9e:	64a2                	ld	s1,8(sp)
    80003ca0:	6105                	addi	sp,sp,32
    80003ca2:	8082                	ret

0000000080003ca4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ca4:	1101                	addi	sp,sp,-32
    80003ca6:	ec06                	sd	ra,24(sp)
    80003ca8:	e822                	sd	s0,16(sp)
    80003caa:	e426                	sd	s1,8(sp)
    80003cac:	e04a                	sd	s2,0(sp)
    80003cae:	1000                	addi	s0,sp,32
    80003cb0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003cb2:	00d5d59b          	srliw	a1,a1,0xd
    80003cb6:	0023f797          	auipc	a5,0x23f
    80003cba:	f0e7a783          	lw	a5,-242(a5) # 80242bc4 <sb+0x1c>
    80003cbe:	9dbd                	addw	a1,a1,a5
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	d9e080e7          	jalr	-610(ra) # 80003a5e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003cc8:	0074f713          	andi	a4,s1,7
    80003ccc:	4785                	li	a5,1
    80003cce:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003cd2:	14ce                	slli	s1,s1,0x33
    80003cd4:	90d9                	srli	s1,s1,0x36
    80003cd6:	00950733          	add	a4,a0,s1
    80003cda:	05874703          	lbu	a4,88(a4)
    80003cde:	00e7f6b3          	and	a3,a5,a4
    80003ce2:	c69d                	beqz	a3,80003d10 <bfree+0x6c>
    80003ce4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003ce6:	94aa                	add	s1,s1,a0
    80003ce8:	fff7c793          	not	a5,a5
    80003cec:	8f7d                	and	a4,a4,a5
    80003cee:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	126080e7          	jalr	294(ra) # 80004e18 <log_write>
  brelse(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	e92080e7          	jalr	-366(ra) # 80003b8e <brelse>
}
    80003d04:	60e2                	ld	ra,24(sp)
    80003d06:	6442                	ld	s0,16(sp)
    80003d08:	64a2                	ld	s1,8(sp)
    80003d0a:	6902                	ld	s2,0(sp)
    80003d0c:	6105                	addi	sp,sp,32
    80003d0e:	8082                	ret
    panic("freeing free block");
    80003d10:	00005517          	auipc	a0,0x5
    80003d14:	ae050513          	addi	a0,a0,-1312 # 800087f0 <syscall_list+0x100>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	828080e7          	jalr	-2008(ra) # 80000540 <panic>

0000000080003d20 <balloc>:
{
    80003d20:	711d                	addi	sp,sp,-96
    80003d22:	ec86                	sd	ra,88(sp)
    80003d24:	e8a2                	sd	s0,80(sp)
    80003d26:	e4a6                	sd	s1,72(sp)
    80003d28:	e0ca                	sd	s2,64(sp)
    80003d2a:	fc4e                	sd	s3,56(sp)
    80003d2c:	f852                	sd	s4,48(sp)
    80003d2e:	f456                	sd	s5,40(sp)
    80003d30:	f05a                	sd	s6,32(sp)
    80003d32:	ec5e                	sd	s7,24(sp)
    80003d34:	e862                	sd	s8,16(sp)
    80003d36:	e466                	sd	s9,8(sp)
    80003d38:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d3a:	0023f797          	auipc	a5,0x23f
    80003d3e:	e727a783          	lw	a5,-398(a5) # 80242bac <sb+0x4>
    80003d42:	cff5                	beqz	a5,80003e3e <balloc+0x11e>
    80003d44:	8baa                	mv	s7,a0
    80003d46:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d48:	0023fb17          	auipc	s6,0x23f
    80003d4c:	e60b0b13          	addi	s6,s6,-416 # 80242ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d50:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d52:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d54:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d56:	6c89                	lui	s9,0x2
    80003d58:	a061                	j	80003de0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003d5a:	97ca                	add	a5,a5,s2
    80003d5c:	8e55                	or	a2,a2,a3
    80003d5e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003d62:	854a                	mv	a0,s2
    80003d64:	00001097          	auipc	ra,0x1
    80003d68:	0b4080e7          	jalr	180(ra) # 80004e18 <log_write>
        brelse(bp);
    80003d6c:	854a                	mv	a0,s2
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	e20080e7          	jalr	-480(ra) # 80003b8e <brelse>
  bp = bread(dev, bno);
    80003d76:	85a6                	mv	a1,s1
    80003d78:	855e                	mv	a0,s7
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	ce4080e7          	jalr	-796(ra) # 80003a5e <bread>
    80003d82:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003d84:	40000613          	li	a2,1024
    80003d88:	4581                	li	a1,0
    80003d8a:	05850513          	addi	a0,a0,88
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	07a080e7          	jalr	122(ra) # 80000e08 <memset>
  log_write(bp);
    80003d96:	854a                	mv	a0,s2
    80003d98:	00001097          	auipc	ra,0x1
    80003d9c:	080080e7          	jalr	128(ra) # 80004e18 <log_write>
  brelse(bp);
    80003da0:	854a                	mv	a0,s2
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	dec080e7          	jalr	-532(ra) # 80003b8e <brelse>
}
    80003daa:	8526                	mv	a0,s1
    80003dac:	60e6                	ld	ra,88(sp)
    80003dae:	6446                	ld	s0,80(sp)
    80003db0:	64a6                	ld	s1,72(sp)
    80003db2:	6906                	ld	s2,64(sp)
    80003db4:	79e2                	ld	s3,56(sp)
    80003db6:	7a42                	ld	s4,48(sp)
    80003db8:	7aa2                	ld	s5,40(sp)
    80003dba:	7b02                	ld	s6,32(sp)
    80003dbc:	6be2                	ld	s7,24(sp)
    80003dbe:	6c42                	ld	s8,16(sp)
    80003dc0:	6ca2                	ld	s9,8(sp)
    80003dc2:	6125                	addi	sp,sp,96
    80003dc4:	8082                	ret
    brelse(bp);
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	dc6080e7          	jalr	-570(ra) # 80003b8e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dd0:	015c87bb          	addw	a5,s9,s5
    80003dd4:	00078a9b          	sext.w	s5,a5
    80003dd8:	004b2703          	lw	a4,4(s6)
    80003ddc:	06eaf163          	bgeu	s5,a4,80003e3e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003de0:	41fad79b          	sraiw	a5,s5,0x1f
    80003de4:	0137d79b          	srliw	a5,a5,0x13
    80003de8:	015787bb          	addw	a5,a5,s5
    80003dec:	40d7d79b          	sraiw	a5,a5,0xd
    80003df0:	01cb2583          	lw	a1,28(s6)
    80003df4:	9dbd                	addw	a1,a1,a5
    80003df6:	855e                	mv	a0,s7
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	c66080e7          	jalr	-922(ra) # 80003a5e <bread>
    80003e00:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e02:	004b2503          	lw	a0,4(s6)
    80003e06:	000a849b          	sext.w	s1,s5
    80003e0a:	8762                	mv	a4,s8
    80003e0c:	faa4fde3          	bgeu	s1,a0,80003dc6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003e10:	00777693          	andi	a3,a4,7
    80003e14:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e18:	41f7579b          	sraiw	a5,a4,0x1f
    80003e1c:	01d7d79b          	srliw	a5,a5,0x1d
    80003e20:	9fb9                	addw	a5,a5,a4
    80003e22:	4037d79b          	sraiw	a5,a5,0x3
    80003e26:	00f90633          	add	a2,s2,a5
    80003e2a:	05864603          	lbu	a2,88(a2)
    80003e2e:	00c6f5b3          	and	a1,a3,a2
    80003e32:	d585                	beqz	a1,80003d5a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e34:	2705                	addiw	a4,a4,1
    80003e36:	2485                	addiw	s1,s1,1
    80003e38:	fd471ae3          	bne	a4,s4,80003e0c <balloc+0xec>
    80003e3c:	b769                	j	80003dc6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	9ca50513          	addi	a0,a0,-1590 # 80008808 <syscall_list+0x118>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	744080e7          	jalr	1860(ra) # 8000058a <printf>
  return 0;
    80003e4e:	4481                	li	s1,0
    80003e50:	bfa9                	j	80003daa <balloc+0x8a>

0000000080003e52 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e52:	7179                	addi	sp,sp,-48
    80003e54:	f406                	sd	ra,40(sp)
    80003e56:	f022                	sd	s0,32(sp)
    80003e58:	ec26                	sd	s1,24(sp)
    80003e5a:	e84a                	sd	s2,16(sp)
    80003e5c:	e44e                	sd	s3,8(sp)
    80003e5e:	e052                	sd	s4,0(sp)
    80003e60:	1800                	addi	s0,sp,48
    80003e62:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003e64:	47ad                	li	a5,11
    80003e66:	02b7e863          	bltu	a5,a1,80003e96 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003e6a:	02059793          	slli	a5,a1,0x20
    80003e6e:	01e7d593          	srli	a1,a5,0x1e
    80003e72:	00b504b3          	add	s1,a0,a1
    80003e76:	0504a903          	lw	s2,80(s1)
    80003e7a:	06091e63          	bnez	s2,80003ef6 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003e7e:	4108                	lw	a0,0(a0)
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	ea0080e7          	jalr	-352(ra) # 80003d20 <balloc>
    80003e88:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e8c:	06090563          	beqz	s2,80003ef6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003e90:	0524a823          	sw	s2,80(s1)
    80003e94:	a08d                	j	80003ef6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003e96:	ff45849b          	addiw	s1,a1,-12
    80003e9a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003e9e:	0ff00793          	li	a5,255
    80003ea2:	08e7e563          	bltu	a5,a4,80003f2c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003ea6:	08052903          	lw	s2,128(a0)
    80003eaa:	00091d63          	bnez	s2,80003ec4 <bmap+0x72>
      addr = balloc(ip->dev);
    80003eae:	4108                	lw	a0,0(a0)
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	e70080e7          	jalr	-400(ra) # 80003d20 <balloc>
    80003eb8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ebc:	02090d63          	beqz	s2,80003ef6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ec0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ec4:	85ca                	mv	a1,s2
    80003ec6:	0009a503          	lw	a0,0(s3)
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	b94080e7          	jalr	-1132(ra) # 80003a5e <bread>
    80003ed2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ed4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ed8:	02049713          	slli	a4,s1,0x20
    80003edc:	01e75593          	srli	a1,a4,0x1e
    80003ee0:	00b784b3          	add	s1,a5,a1
    80003ee4:	0004a903          	lw	s2,0(s1)
    80003ee8:	02090063          	beqz	s2,80003f08 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003eec:	8552                	mv	a0,s4
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	ca0080e7          	jalr	-864(ra) # 80003b8e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	70a2                	ld	ra,40(sp)
    80003efa:	7402                	ld	s0,32(sp)
    80003efc:	64e2                	ld	s1,24(sp)
    80003efe:	6942                	ld	s2,16(sp)
    80003f00:	69a2                	ld	s3,8(sp)
    80003f02:	6a02                	ld	s4,0(sp)
    80003f04:	6145                	addi	sp,sp,48
    80003f06:	8082                	ret
      addr = balloc(ip->dev);
    80003f08:	0009a503          	lw	a0,0(s3)
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	e14080e7          	jalr	-492(ra) # 80003d20 <balloc>
    80003f14:	0005091b          	sext.w	s2,a0
      if(addr){
    80003f18:	fc090ae3          	beqz	s2,80003eec <bmap+0x9a>
        a[bn] = addr;
    80003f1c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003f20:	8552                	mv	a0,s4
    80003f22:	00001097          	auipc	ra,0x1
    80003f26:	ef6080e7          	jalr	-266(ra) # 80004e18 <log_write>
    80003f2a:	b7c9                	j	80003eec <bmap+0x9a>
  panic("bmap: out of range");
    80003f2c:	00005517          	auipc	a0,0x5
    80003f30:	8f450513          	addi	a0,a0,-1804 # 80008820 <syscall_list+0x130>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	60c080e7          	jalr	1548(ra) # 80000540 <panic>

0000000080003f3c <iget>:
{
    80003f3c:	7179                	addi	sp,sp,-48
    80003f3e:	f406                	sd	ra,40(sp)
    80003f40:	f022                	sd	s0,32(sp)
    80003f42:	ec26                	sd	s1,24(sp)
    80003f44:	e84a                	sd	s2,16(sp)
    80003f46:	e44e                	sd	s3,8(sp)
    80003f48:	e052                	sd	s4,0(sp)
    80003f4a:	1800                	addi	s0,sp,48
    80003f4c:	89aa                	mv	s3,a0
    80003f4e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f50:	0023f517          	auipc	a0,0x23f
    80003f54:	c7850513          	addi	a0,a0,-904 # 80242bc8 <itable>
    80003f58:	ffffd097          	auipc	ra,0xffffd
    80003f5c:	db4080e7          	jalr	-588(ra) # 80000d0c <acquire>
  empty = 0;
    80003f60:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f62:	0023f497          	auipc	s1,0x23f
    80003f66:	c7e48493          	addi	s1,s1,-898 # 80242be0 <itable+0x18>
    80003f6a:	00240697          	auipc	a3,0x240
    80003f6e:	70668693          	addi	a3,a3,1798 # 80244670 <log>
    80003f72:	a039                	j	80003f80 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f74:	02090b63          	beqz	s2,80003faa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f78:	08848493          	addi	s1,s1,136
    80003f7c:	02d48a63          	beq	s1,a3,80003fb0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003f80:	449c                	lw	a5,8(s1)
    80003f82:	fef059e3          	blez	a5,80003f74 <iget+0x38>
    80003f86:	4098                	lw	a4,0(s1)
    80003f88:	ff3716e3          	bne	a4,s3,80003f74 <iget+0x38>
    80003f8c:	40d8                	lw	a4,4(s1)
    80003f8e:	ff4713e3          	bne	a4,s4,80003f74 <iget+0x38>
      ip->ref++;
    80003f92:	2785                	addiw	a5,a5,1
    80003f94:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003f96:	0023f517          	auipc	a0,0x23f
    80003f9a:	c3250513          	addi	a0,a0,-974 # 80242bc8 <itable>
    80003f9e:	ffffd097          	auipc	ra,0xffffd
    80003fa2:	e22080e7          	jalr	-478(ra) # 80000dc0 <release>
      return ip;
    80003fa6:	8926                	mv	s2,s1
    80003fa8:	a03d                	j	80003fd6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003faa:	f7f9                	bnez	a5,80003f78 <iget+0x3c>
    80003fac:	8926                	mv	s2,s1
    80003fae:	b7e9                	j	80003f78 <iget+0x3c>
  if(empty == 0)
    80003fb0:	02090c63          	beqz	s2,80003fe8 <iget+0xac>
  ip->dev = dev;
    80003fb4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003fb8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003fbc:	4785                	li	a5,1
    80003fbe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003fc2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003fc6:	0023f517          	auipc	a0,0x23f
    80003fca:	c0250513          	addi	a0,a0,-1022 # 80242bc8 <itable>
    80003fce:	ffffd097          	auipc	ra,0xffffd
    80003fd2:	df2080e7          	jalr	-526(ra) # 80000dc0 <release>
}
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	70a2                	ld	ra,40(sp)
    80003fda:	7402                	ld	s0,32(sp)
    80003fdc:	64e2                	ld	s1,24(sp)
    80003fde:	6942                	ld	s2,16(sp)
    80003fe0:	69a2                	ld	s3,8(sp)
    80003fe2:	6a02                	ld	s4,0(sp)
    80003fe4:	6145                	addi	sp,sp,48
    80003fe6:	8082                	ret
    panic("iget: no inodes");
    80003fe8:	00005517          	auipc	a0,0x5
    80003fec:	85050513          	addi	a0,a0,-1968 # 80008838 <syscall_list+0x148>
    80003ff0:	ffffc097          	auipc	ra,0xffffc
    80003ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080003ff8 <fsinit>:
fsinit(int dev) {
    80003ff8:	7179                	addi	sp,sp,-48
    80003ffa:	f406                	sd	ra,40(sp)
    80003ffc:	f022                	sd	s0,32(sp)
    80003ffe:	ec26                	sd	s1,24(sp)
    80004000:	e84a                	sd	s2,16(sp)
    80004002:	e44e                	sd	s3,8(sp)
    80004004:	1800                	addi	s0,sp,48
    80004006:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004008:	4585                	li	a1,1
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	a54080e7          	jalr	-1452(ra) # 80003a5e <bread>
    80004012:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004014:	0023f997          	auipc	s3,0x23f
    80004018:	b9498993          	addi	s3,s3,-1132 # 80242ba8 <sb>
    8000401c:	02000613          	li	a2,32
    80004020:	05850593          	addi	a1,a0,88
    80004024:	854e                	mv	a0,s3
    80004026:	ffffd097          	auipc	ra,0xffffd
    8000402a:	e3e080e7          	jalr	-450(ra) # 80000e64 <memmove>
  brelse(bp);
    8000402e:	8526                	mv	a0,s1
    80004030:	00000097          	auipc	ra,0x0
    80004034:	b5e080e7          	jalr	-1186(ra) # 80003b8e <brelse>
  if(sb.magic != FSMAGIC)
    80004038:	0009a703          	lw	a4,0(s3)
    8000403c:	102037b7          	lui	a5,0x10203
    80004040:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004044:	02f71263          	bne	a4,a5,80004068 <fsinit+0x70>
  initlog(dev, &sb);
    80004048:	0023f597          	auipc	a1,0x23f
    8000404c:	b6058593          	addi	a1,a1,-1184 # 80242ba8 <sb>
    80004050:	854a                	mv	a0,s2
    80004052:	00001097          	auipc	ra,0x1
    80004056:	b4a080e7          	jalr	-1206(ra) # 80004b9c <initlog>
}
    8000405a:	70a2                	ld	ra,40(sp)
    8000405c:	7402                	ld	s0,32(sp)
    8000405e:	64e2                	ld	s1,24(sp)
    80004060:	6942                	ld	s2,16(sp)
    80004062:	69a2                	ld	s3,8(sp)
    80004064:	6145                	addi	sp,sp,48
    80004066:	8082                	ret
    panic("invalid file system");
    80004068:	00004517          	auipc	a0,0x4
    8000406c:	7e050513          	addi	a0,a0,2016 # 80008848 <syscall_list+0x158>
    80004070:	ffffc097          	auipc	ra,0xffffc
    80004074:	4d0080e7          	jalr	1232(ra) # 80000540 <panic>

0000000080004078 <iinit>:
{
    80004078:	7179                	addi	sp,sp,-48
    8000407a:	f406                	sd	ra,40(sp)
    8000407c:	f022                	sd	s0,32(sp)
    8000407e:	ec26                	sd	s1,24(sp)
    80004080:	e84a                	sd	s2,16(sp)
    80004082:	e44e                	sd	s3,8(sp)
    80004084:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004086:	00004597          	auipc	a1,0x4
    8000408a:	7da58593          	addi	a1,a1,2010 # 80008860 <syscall_list+0x170>
    8000408e:	0023f517          	auipc	a0,0x23f
    80004092:	b3a50513          	addi	a0,a0,-1222 # 80242bc8 <itable>
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	be6080e7          	jalr	-1050(ra) # 80000c7c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000409e:	0023f497          	auipc	s1,0x23f
    800040a2:	b5248493          	addi	s1,s1,-1198 # 80242bf0 <itable+0x28>
    800040a6:	00240997          	auipc	s3,0x240
    800040aa:	5da98993          	addi	s3,s3,1498 # 80244680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040ae:	00004917          	auipc	s2,0x4
    800040b2:	7ba90913          	addi	s2,s2,1978 # 80008868 <syscall_list+0x178>
    800040b6:	85ca                	mv	a1,s2
    800040b8:	8526                	mv	a0,s1
    800040ba:	00001097          	auipc	ra,0x1
    800040be:	e42080e7          	jalr	-446(ra) # 80004efc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040c2:	08848493          	addi	s1,s1,136
    800040c6:	ff3498e3          	bne	s1,s3,800040b6 <iinit+0x3e>
}
    800040ca:	70a2                	ld	ra,40(sp)
    800040cc:	7402                	ld	s0,32(sp)
    800040ce:	64e2                	ld	s1,24(sp)
    800040d0:	6942                	ld	s2,16(sp)
    800040d2:	69a2                	ld	s3,8(sp)
    800040d4:	6145                	addi	sp,sp,48
    800040d6:	8082                	ret

00000000800040d8 <ialloc>:
{
    800040d8:	715d                	addi	sp,sp,-80
    800040da:	e486                	sd	ra,72(sp)
    800040dc:	e0a2                	sd	s0,64(sp)
    800040de:	fc26                	sd	s1,56(sp)
    800040e0:	f84a                	sd	s2,48(sp)
    800040e2:	f44e                	sd	s3,40(sp)
    800040e4:	f052                	sd	s4,32(sp)
    800040e6:	ec56                	sd	s5,24(sp)
    800040e8:	e85a                	sd	s6,16(sp)
    800040ea:	e45e                	sd	s7,8(sp)
    800040ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800040ee:	0023f717          	auipc	a4,0x23f
    800040f2:	ac672703          	lw	a4,-1338(a4) # 80242bb4 <sb+0xc>
    800040f6:	4785                	li	a5,1
    800040f8:	04e7fa63          	bgeu	a5,a4,8000414c <ialloc+0x74>
    800040fc:	8aaa                	mv	s5,a0
    800040fe:	8bae                	mv	s7,a1
    80004100:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004102:	0023fa17          	auipc	s4,0x23f
    80004106:	aa6a0a13          	addi	s4,s4,-1370 # 80242ba8 <sb>
    8000410a:	00048b1b          	sext.w	s6,s1
    8000410e:	0044d593          	srli	a1,s1,0x4
    80004112:	018a2783          	lw	a5,24(s4)
    80004116:	9dbd                	addw	a1,a1,a5
    80004118:	8556                	mv	a0,s5
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	944080e7          	jalr	-1724(ra) # 80003a5e <bread>
    80004122:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004124:	05850993          	addi	s3,a0,88
    80004128:	00f4f793          	andi	a5,s1,15
    8000412c:	079a                	slli	a5,a5,0x6
    8000412e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004130:	00099783          	lh	a5,0(s3)
    80004134:	c3a1                	beqz	a5,80004174 <ialloc+0x9c>
    brelse(bp);
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	a58080e7          	jalr	-1448(ra) # 80003b8e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000413e:	0485                	addi	s1,s1,1
    80004140:	00ca2703          	lw	a4,12(s4)
    80004144:	0004879b          	sext.w	a5,s1
    80004148:	fce7e1e3          	bltu	a5,a4,8000410a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	72450513          	addi	a0,a0,1828 # 80008870 <syscall_list+0x180>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	436080e7          	jalr	1078(ra) # 8000058a <printf>
  return 0;
    8000415c:	4501                	li	a0,0
}
    8000415e:	60a6                	ld	ra,72(sp)
    80004160:	6406                	ld	s0,64(sp)
    80004162:	74e2                	ld	s1,56(sp)
    80004164:	7942                	ld	s2,48(sp)
    80004166:	79a2                	ld	s3,40(sp)
    80004168:	7a02                	ld	s4,32(sp)
    8000416a:	6ae2                	ld	s5,24(sp)
    8000416c:	6b42                	ld	s6,16(sp)
    8000416e:	6ba2                	ld	s7,8(sp)
    80004170:	6161                	addi	sp,sp,80
    80004172:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004174:	04000613          	li	a2,64
    80004178:	4581                	li	a1,0
    8000417a:	854e                	mv	a0,s3
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	c8c080e7          	jalr	-884(ra) # 80000e08 <memset>
      dip->type = type;
    80004184:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004188:	854a                	mv	a0,s2
    8000418a:	00001097          	auipc	ra,0x1
    8000418e:	c8e080e7          	jalr	-882(ra) # 80004e18 <log_write>
      brelse(bp);
    80004192:	854a                	mv	a0,s2
    80004194:	00000097          	auipc	ra,0x0
    80004198:	9fa080e7          	jalr	-1542(ra) # 80003b8e <brelse>
      return iget(dev, inum);
    8000419c:	85da                	mv	a1,s6
    8000419e:	8556                	mv	a0,s5
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	d9c080e7          	jalr	-612(ra) # 80003f3c <iget>
    800041a8:	bf5d                	j	8000415e <ialloc+0x86>

00000000800041aa <iupdate>:
{
    800041aa:	1101                	addi	sp,sp,-32
    800041ac:	ec06                	sd	ra,24(sp)
    800041ae:	e822                	sd	s0,16(sp)
    800041b0:	e426                	sd	s1,8(sp)
    800041b2:	e04a                	sd	s2,0(sp)
    800041b4:	1000                	addi	s0,sp,32
    800041b6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041b8:	415c                	lw	a5,4(a0)
    800041ba:	0047d79b          	srliw	a5,a5,0x4
    800041be:	0023f597          	auipc	a1,0x23f
    800041c2:	a025a583          	lw	a1,-1534(a1) # 80242bc0 <sb+0x18>
    800041c6:	9dbd                	addw	a1,a1,a5
    800041c8:	4108                	lw	a0,0(a0)
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	894080e7          	jalr	-1900(ra) # 80003a5e <bread>
    800041d2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041d4:	05850793          	addi	a5,a0,88
    800041d8:	40d8                	lw	a4,4(s1)
    800041da:	8b3d                	andi	a4,a4,15
    800041dc:	071a                	slli	a4,a4,0x6
    800041de:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800041e0:	04449703          	lh	a4,68(s1)
    800041e4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800041e8:	04649703          	lh	a4,70(s1)
    800041ec:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800041f0:	04849703          	lh	a4,72(s1)
    800041f4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800041f8:	04a49703          	lh	a4,74(s1)
    800041fc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004200:	44f8                	lw	a4,76(s1)
    80004202:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004204:	03400613          	li	a2,52
    80004208:	05048593          	addi	a1,s1,80
    8000420c:	00c78513          	addi	a0,a5,12
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	c54080e7          	jalr	-940(ra) # 80000e64 <memmove>
  log_write(bp);
    80004218:	854a                	mv	a0,s2
    8000421a:	00001097          	auipc	ra,0x1
    8000421e:	bfe080e7          	jalr	-1026(ra) # 80004e18 <log_write>
  brelse(bp);
    80004222:	854a                	mv	a0,s2
    80004224:	00000097          	auipc	ra,0x0
    80004228:	96a080e7          	jalr	-1686(ra) # 80003b8e <brelse>
}
    8000422c:	60e2                	ld	ra,24(sp)
    8000422e:	6442                	ld	s0,16(sp)
    80004230:	64a2                	ld	s1,8(sp)
    80004232:	6902                	ld	s2,0(sp)
    80004234:	6105                	addi	sp,sp,32
    80004236:	8082                	ret

0000000080004238 <idup>:
{
    80004238:	1101                	addi	sp,sp,-32
    8000423a:	ec06                	sd	ra,24(sp)
    8000423c:	e822                	sd	s0,16(sp)
    8000423e:	e426                	sd	s1,8(sp)
    80004240:	1000                	addi	s0,sp,32
    80004242:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004244:	0023f517          	auipc	a0,0x23f
    80004248:	98450513          	addi	a0,a0,-1660 # 80242bc8 <itable>
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	ac0080e7          	jalr	-1344(ra) # 80000d0c <acquire>
  ip->ref++;
    80004254:	449c                	lw	a5,8(s1)
    80004256:	2785                	addiw	a5,a5,1
    80004258:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000425a:	0023f517          	auipc	a0,0x23f
    8000425e:	96e50513          	addi	a0,a0,-1682 # 80242bc8 <itable>
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	b5e080e7          	jalr	-1186(ra) # 80000dc0 <release>
}
    8000426a:	8526                	mv	a0,s1
    8000426c:	60e2                	ld	ra,24(sp)
    8000426e:	6442                	ld	s0,16(sp)
    80004270:	64a2                	ld	s1,8(sp)
    80004272:	6105                	addi	sp,sp,32
    80004274:	8082                	ret

0000000080004276 <ilock>:
{
    80004276:	1101                	addi	sp,sp,-32
    80004278:	ec06                	sd	ra,24(sp)
    8000427a:	e822                	sd	s0,16(sp)
    8000427c:	e426                	sd	s1,8(sp)
    8000427e:	e04a                	sd	s2,0(sp)
    80004280:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004282:	c115                	beqz	a0,800042a6 <ilock+0x30>
    80004284:	84aa                	mv	s1,a0
    80004286:	451c                	lw	a5,8(a0)
    80004288:	00f05f63          	blez	a5,800042a6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000428c:	0541                	addi	a0,a0,16
    8000428e:	00001097          	auipc	ra,0x1
    80004292:	ca8080e7          	jalr	-856(ra) # 80004f36 <acquiresleep>
  if(ip->valid == 0){
    80004296:	40bc                	lw	a5,64(s1)
    80004298:	cf99                	beqz	a5,800042b6 <ilock+0x40>
}
    8000429a:	60e2                	ld	ra,24(sp)
    8000429c:	6442                	ld	s0,16(sp)
    8000429e:	64a2                	ld	s1,8(sp)
    800042a0:	6902                	ld	s2,0(sp)
    800042a2:	6105                	addi	sp,sp,32
    800042a4:	8082                	ret
    panic("ilock");
    800042a6:	00004517          	auipc	a0,0x4
    800042aa:	5e250513          	addi	a0,a0,1506 # 80008888 <syscall_list+0x198>
    800042ae:	ffffc097          	auipc	ra,0xffffc
    800042b2:	292080e7          	jalr	658(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042b6:	40dc                	lw	a5,4(s1)
    800042b8:	0047d79b          	srliw	a5,a5,0x4
    800042bc:	0023f597          	auipc	a1,0x23f
    800042c0:	9045a583          	lw	a1,-1788(a1) # 80242bc0 <sb+0x18>
    800042c4:	9dbd                	addw	a1,a1,a5
    800042c6:	4088                	lw	a0,0(s1)
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	796080e7          	jalr	1942(ra) # 80003a5e <bread>
    800042d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042d2:	05850593          	addi	a1,a0,88
    800042d6:	40dc                	lw	a5,4(s1)
    800042d8:	8bbd                	andi	a5,a5,15
    800042da:	079a                	slli	a5,a5,0x6
    800042dc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800042de:	00059783          	lh	a5,0(a1)
    800042e2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800042e6:	00259783          	lh	a5,2(a1)
    800042ea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800042ee:	00459783          	lh	a5,4(a1)
    800042f2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800042f6:	00659783          	lh	a5,6(a1)
    800042fa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800042fe:	459c                	lw	a5,8(a1)
    80004300:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004302:	03400613          	li	a2,52
    80004306:	05b1                	addi	a1,a1,12
    80004308:	05048513          	addi	a0,s1,80
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	b58080e7          	jalr	-1192(ra) # 80000e64 <memmove>
    brelse(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	878080e7          	jalr	-1928(ra) # 80003b8e <brelse>
    ip->valid = 1;
    8000431e:	4785                	li	a5,1
    80004320:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004322:	04449783          	lh	a5,68(s1)
    80004326:	fbb5                	bnez	a5,8000429a <ilock+0x24>
      panic("ilock: no type");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	56850513          	addi	a0,a0,1384 # 80008890 <syscall_list+0x1a0>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	210080e7          	jalr	528(ra) # 80000540 <panic>

0000000080004338 <iunlock>:
{
    80004338:	1101                	addi	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	e426                	sd	s1,8(sp)
    80004340:	e04a                	sd	s2,0(sp)
    80004342:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004344:	c905                	beqz	a0,80004374 <iunlock+0x3c>
    80004346:	84aa                	mv	s1,a0
    80004348:	01050913          	addi	s2,a0,16
    8000434c:	854a                	mv	a0,s2
    8000434e:	00001097          	auipc	ra,0x1
    80004352:	c82080e7          	jalr	-894(ra) # 80004fd0 <holdingsleep>
    80004356:	cd19                	beqz	a0,80004374 <iunlock+0x3c>
    80004358:	449c                	lw	a5,8(s1)
    8000435a:	00f05d63          	blez	a5,80004374 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000435e:	854a                	mv	a0,s2
    80004360:	00001097          	auipc	ra,0x1
    80004364:	c2c080e7          	jalr	-980(ra) # 80004f8c <releasesleep>
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6902                	ld	s2,0(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret
    panic("iunlock");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	52c50513          	addi	a0,a0,1324 # 800088a0 <syscall_list+0x1b0>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c4080e7          	jalr	452(ra) # 80000540 <panic>

0000000080004384 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004384:	7179                	addi	sp,sp,-48
    80004386:	f406                	sd	ra,40(sp)
    80004388:	f022                	sd	s0,32(sp)
    8000438a:	ec26                	sd	s1,24(sp)
    8000438c:	e84a                	sd	s2,16(sp)
    8000438e:	e44e                	sd	s3,8(sp)
    80004390:	e052                	sd	s4,0(sp)
    80004392:	1800                	addi	s0,sp,48
    80004394:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004396:	05050493          	addi	s1,a0,80
    8000439a:	08050913          	addi	s2,a0,128
    8000439e:	a021                	j	800043a6 <itrunc+0x22>
    800043a0:	0491                	addi	s1,s1,4
    800043a2:	01248d63          	beq	s1,s2,800043bc <itrunc+0x38>
    if(ip->addrs[i]){
    800043a6:	408c                	lw	a1,0(s1)
    800043a8:	dde5                	beqz	a1,800043a0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043aa:	0009a503          	lw	a0,0(s3)
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	8f6080e7          	jalr	-1802(ra) # 80003ca4 <bfree>
      ip->addrs[i] = 0;
    800043b6:	0004a023          	sw	zero,0(s1)
    800043ba:	b7dd                	j	800043a0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043bc:	0809a583          	lw	a1,128(s3)
    800043c0:	e185                	bnez	a1,800043e0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043c2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043c6:	854e                	mv	a0,s3
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	de2080e7          	jalr	-542(ra) # 800041aa <iupdate>
}
    800043d0:	70a2                	ld	ra,40(sp)
    800043d2:	7402                	ld	s0,32(sp)
    800043d4:	64e2                	ld	s1,24(sp)
    800043d6:	6942                	ld	s2,16(sp)
    800043d8:	69a2                	ld	s3,8(sp)
    800043da:	6a02                	ld	s4,0(sp)
    800043dc:	6145                	addi	sp,sp,48
    800043de:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800043e0:	0009a503          	lw	a0,0(s3)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	67a080e7          	jalr	1658(ra) # 80003a5e <bread>
    800043ec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800043ee:	05850493          	addi	s1,a0,88
    800043f2:	45850913          	addi	s2,a0,1112
    800043f6:	a021                	j	800043fe <itrunc+0x7a>
    800043f8:	0491                	addi	s1,s1,4
    800043fa:	01248b63          	beq	s1,s2,80004410 <itrunc+0x8c>
      if(a[j])
    800043fe:	408c                	lw	a1,0(s1)
    80004400:	dde5                	beqz	a1,800043f8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004402:	0009a503          	lw	a0,0(s3)
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	89e080e7          	jalr	-1890(ra) # 80003ca4 <bfree>
    8000440e:	b7ed                	j	800043f8 <itrunc+0x74>
    brelse(bp);
    80004410:	8552                	mv	a0,s4
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	77c080e7          	jalr	1916(ra) # 80003b8e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000441a:	0809a583          	lw	a1,128(s3)
    8000441e:	0009a503          	lw	a0,0(s3)
    80004422:	00000097          	auipc	ra,0x0
    80004426:	882080e7          	jalr	-1918(ra) # 80003ca4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000442a:	0809a023          	sw	zero,128(s3)
    8000442e:	bf51                	j	800043c2 <itrunc+0x3e>

0000000080004430 <iput>:
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000443e:	0023e517          	auipc	a0,0x23e
    80004442:	78a50513          	addi	a0,a0,1930 # 80242bc8 <itable>
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	8c6080e7          	jalr	-1850(ra) # 80000d0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000444e:	4498                	lw	a4,8(s1)
    80004450:	4785                	li	a5,1
    80004452:	02f70363          	beq	a4,a5,80004478 <iput+0x48>
  ip->ref--;
    80004456:	449c                	lw	a5,8(s1)
    80004458:	37fd                	addiw	a5,a5,-1
    8000445a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000445c:	0023e517          	auipc	a0,0x23e
    80004460:	76c50513          	addi	a0,a0,1900 # 80242bc8 <itable>
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	95c080e7          	jalr	-1700(ra) # 80000dc0 <release>
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004478:	40bc                	lw	a5,64(s1)
    8000447a:	dff1                	beqz	a5,80004456 <iput+0x26>
    8000447c:	04a49783          	lh	a5,74(s1)
    80004480:	fbf9                	bnez	a5,80004456 <iput+0x26>
    acquiresleep(&ip->lock);
    80004482:	01048913          	addi	s2,s1,16
    80004486:	854a                	mv	a0,s2
    80004488:	00001097          	auipc	ra,0x1
    8000448c:	aae080e7          	jalr	-1362(ra) # 80004f36 <acquiresleep>
    release(&itable.lock);
    80004490:	0023e517          	auipc	a0,0x23e
    80004494:	73850513          	addi	a0,a0,1848 # 80242bc8 <itable>
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	928080e7          	jalr	-1752(ra) # 80000dc0 <release>
    itrunc(ip);
    800044a0:	8526                	mv	a0,s1
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	ee2080e7          	jalr	-286(ra) # 80004384 <itrunc>
    ip->type = 0;
    800044aa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044ae:	8526                	mv	a0,s1
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	cfa080e7          	jalr	-774(ra) # 800041aa <iupdate>
    ip->valid = 0;
    800044b8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044bc:	854a                	mv	a0,s2
    800044be:	00001097          	auipc	ra,0x1
    800044c2:	ace080e7          	jalr	-1330(ra) # 80004f8c <releasesleep>
    acquire(&itable.lock);
    800044c6:	0023e517          	auipc	a0,0x23e
    800044ca:	70250513          	addi	a0,a0,1794 # 80242bc8 <itable>
    800044ce:	ffffd097          	auipc	ra,0xffffd
    800044d2:	83e080e7          	jalr	-1986(ra) # 80000d0c <acquire>
    800044d6:	b741                	j	80004456 <iput+0x26>

00000000800044d8 <iunlockput>:
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
  iunlock(ip);
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	e54080e7          	jalr	-428(ra) # 80004338 <iunlock>
  iput(ip);
    800044ec:	8526                	mv	a0,s1
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	f42080e7          	jalr	-190(ra) # 80004430 <iput>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6105                	addi	sp,sp,32
    800044fe:	8082                	ret

0000000080004500 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004500:	1141                	addi	sp,sp,-16
    80004502:	e422                	sd	s0,8(sp)
    80004504:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004506:	411c                	lw	a5,0(a0)
    80004508:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000450a:	415c                	lw	a5,4(a0)
    8000450c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000450e:	04451783          	lh	a5,68(a0)
    80004512:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004516:	04a51783          	lh	a5,74(a0)
    8000451a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000451e:	04c56783          	lwu	a5,76(a0)
    80004522:	e99c                	sd	a5,16(a1)
}
    80004524:	6422                	ld	s0,8(sp)
    80004526:	0141                	addi	sp,sp,16
    80004528:	8082                	ret

000000008000452a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000452a:	457c                	lw	a5,76(a0)
    8000452c:	0ed7e963          	bltu	a5,a3,8000461e <readi+0xf4>
{
    80004530:	7159                	addi	sp,sp,-112
    80004532:	f486                	sd	ra,104(sp)
    80004534:	f0a2                	sd	s0,96(sp)
    80004536:	eca6                	sd	s1,88(sp)
    80004538:	e8ca                	sd	s2,80(sp)
    8000453a:	e4ce                	sd	s3,72(sp)
    8000453c:	e0d2                	sd	s4,64(sp)
    8000453e:	fc56                	sd	s5,56(sp)
    80004540:	f85a                	sd	s6,48(sp)
    80004542:	f45e                	sd	s7,40(sp)
    80004544:	f062                	sd	s8,32(sp)
    80004546:	ec66                	sd	s9,24(sp)
    80004548:	e86a                	sd	s10,16(sp)
    8000454a:	e46e                	sd	s11,8(sp)
    8000454c:	1880                	addi	s0,sp,112
    8000454e:	8b2a                	mv	s6,a0
    80004550:	8bae                	mv	s7,a1
    80004552:	8a32                	mv	s4,a2
    80004554:	84b6                	mv	s1,a3
    80004556:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004558:	9f35                	addw	a4,a4,a3
    return 0;
    8000455a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000455c:	0ad76063          	bltu	a4,a3,800045fc <readi+0xd2>
  if(off + n > ip->size)
    80004560:	00e7f463          	bgeu	a5,a4,80004568 <readi+0x3e>
    n = ip->size - off;
    80004564:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004568:	0a0a8963          	beqz	s5,8000461a <readi+0xf0>
    8000456c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000456e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004572:	5c7d                	li	s8,-1
    80004574:	a82d                	j	800045ae <readi+0x84>
    80004576:	020d1d93          	slli	s11,s10,0x20
    8000457a:	020ddd93          	srli	s11,s11,0x20
    8000457e:	05890613          	addi	a2,s2,88
    80004582:	86ee                	mv	a3,s11
    80004584:	963a                	add	a2,a2,a4
    80004586:	85d2                	mv	a1,s4
    80004588:	855e                	mv	a0,s7
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	39e080e7          	jalr	926(ra) # 80002928 <either_copyout>
    80004592:	05850d63          	beq	a0,s8,800045ec <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004596:	854a                	mv	a0,s2
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	5f6080e7          	jalr	1526(ra) # 80003b8e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045a0:	013d09bb          	addw	s3,s10,s3
    800045a4:	009d04bb          	addw	s1,s10,s1
    800045a8:	9a6e                	add	s4,s4,s11
    800045aa:	0559f763          	bgeu	s3,s5,800045f8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800045ae:	00a4d59b          	srliw	a1,s1,0xa
    800045b2:	855a                	mv	a0,s6
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	89e080e7          	jalr	-1890(ra) # 80003e52 <bmap>
    800045bc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800045c0:	cd85                	beqz	a1,800045f8 <readi+0xce>
    bp = bread(ip->dev, addr);
    800045c2:	000b2503          	lw	a0,0(s6)
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	498080e7          	jalr	1176(ra) # 80003a5e <bread>
    800045ce:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045d0:	3ff4f713          	andi	a4,s1,1023
    800045d4:	40ec87bb          	subw	a5,s9,a4
    800045d8:	413a86bb          	subw	a3,s5,s3
    800045dc:	8d3e                	mv	s10,a5
    800045de:	2781                	sext.w	a5,a5
    800045e0:	0006861b          	sext.w	a2,a3
    800045e4:	f8f679e3          	bgeu	a2,a5,80004576 <readi+0x4c>
    800045e8:	8d36                	mv	s10,a3
    800045ea:	b771                	j	80004576 <readi+0x4c>
      brelse(bp);
    800045ec:	854a                	mv	a0,s2
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	5a0080e7          	jalr	1440(ra) # 80003b8e <brelse>
      tot = -1;
    800045f6:	59fd                	li	s3,-1
  }
  return tot;
    800045f8:	0009851b          	sext.w	a0,s3
}
    800045fc:	70a6                	ld	ra,104(sp)
    800045fe:	7406                	ld	s0,96(sp)
    80004600:	64e6                	ld	s1,88(sp)
    80004602:	6946                	ld	s2,80(sp)
    80004604:	69a6                	ld	s3,72(sp)
    80004606:	6a06                	ld	s4,64(sp)
    80004608:	7ae2                	ld	s5,56(sp)
    8000460a:	7b42                	ld	s6,48(sp)
    8000460c:	7ba2                	ld	s7,40(sp)
    8000460e:	7c02                	ld	s8,32(sp)
    80004610:	6ce2                	ld	s9,24(sp)
    80004612:	6d42                	ld	s10,16(sp)
    80004614:	6da2                	ld	s11,8(sp)
    80004616:	6165                	addi	sp,sp,112
    80004618:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000461a:	89d6                	mv	s3,s5
    8000461c:	bff1                	j	800045f8 <readi+0xce>
    return 0;
    8000461e:	4501                	li	a0,0
}
    80004620:	8082                	ret

0000000080004622 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004622:	457c                	lw	a5,76(a0)
    80004624:	10d7e863          	bltu	a5,a3,80004734 <writei+0x112>
{
    80004628:	7159                	addi	sp,sp,-112
    8000462a:	f486                	sd	ra,104(sp)
    8000462c:	f0a2                	sd	s0,96(sp)
    8000462e:	eca6                	sd	s1,88(sp)
    80004630:	e8ca                	sd	s2,80(sp)
    80004632:	e4ce                	sd	s3,72(sp)
    80004634:	e0d2                	sd	s4,64(sp)
    80004636:	fc56                	sd	s5,56(sp)
    80004638:	f85a                	sd	s6,48(sp)
    8000463a:	f45e                	sd	s7,40(sp)
    8000463c:	f062                	sd	s8,32(sp)
    8000463e:	ec66                	sd	s9,24(sp)
    80004640:	e86a                	sd	s10,16(sp)
    80004642:	e46e                	sd	s11,8(sp)
    80004644:	1880                	addi	s0,sp,112
    80004646:	8aaa                	mv	s5,a0
    80004648:	8bae                	mv	s7,a1
    8000464a:	8a32                	mv	s4,a2
    8000464c:	8936                	mv	s2,a3
    8000464e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004650:	00e687bb          	addw	a5,a3,a4
    80004654:	0ed7e263          	bltu	a5,a3,80004738 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004658:	00043737          	lui	a4,0x43
    8000465c:	0ef76063          	bltu	a4,a5,8000473c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004660:	0c0b0863          	beqz	s6,80004730 <writei+0x10e>
    80004664:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004666:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000466a:	5c7d                	li	s8,-1
    8000466c:	a091                	j	800046b0 <writei+0x8e>
    8000466e:	020d1d93          	slli	s11,s10,0x20
    80004672:	020ddd93          	srli	s11,s11,0x20
    80004676:	05848513          	addi	a0,s1,88
    8000467a:	86ee                	mv	a3,s11
    8000467c:	8652                	mv	a2,s4
    8000467e:	85de                	mv	a1,s7
    80004680:	953a                	add	a0,a0,a4
    80004682:	ffffe097          	auipc	ra,0xffffe
    80004686:	2fc080e7          	jalr	764(ra) # 8000297e <either_copyin>
    8000468a:	07850263          	beq	a0,s8,800046ee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000468e:	8526                	mv	a0,s1
    80004690:	00000097          	auipc	ra,0x0
    80004694:	788080e7          	jalr	1928(ra) # 80004e18 <log_write>
    brelse(bp);
    80004698:	8526                	mv	a0,s1
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	4f4080e7          	jalr	1268(ra) # 80003b8e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046a2:	013d09bb          	addw	s3,s10,s3
    800046a6:	012d093b          	addw	s2,s10,s2
    800046aa:	9a6e                	add	s4,s4,s11
    800046ac:	0569f663          	bgeu	s3,s6,800046f8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800046b0:	00a9559b          	srliw	a1,s2,0xa
    800046b4:	8556                	mv	a0,s5
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	79c080e7          	jalr	1948(ra) # 80003e52 <bmap>
    800046be:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046c2:	c99d                	beqz	a1,800046f8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800046c4:	000aa503          	lw	a0,0(s5)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	396080e7          	jalr	918(ra) # 80003a5e <bread>
    800046d0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046d2:	3ff97713          	andi	a4,s2,1023
    800046d6:	40ec87bb          	subw	a5,s9,a4
    800046da:	413b06bb          	subw	a3,s6,s3
    800046de:	8d3e                	mv	s10,a5
    800046e0:	2781                	sext.w	a5,a5
    800046e2:	0006861b          	sext.w	a2,a3
    800046e6:	f8f674e3          	bgeu	a2,a5,8000466e <writei+0x4c>
    800046ea:	8d36                	mv	s10,a3
    800046ec:	b749                	j	8000466e <writei+0x4c>
      brelse(bp);
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	49e080e7          	jalr	1182(ra) # 80003b8e <brelse>
  }

  if(off > ip->size)
    800046f8:	04caa783          	lw	a5,76(s5)
    800046fc:	0127f463          	bgeu	a5,s2,80004704 <writei+0xe2>
    ip->size = off;
    80004700:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004704:	8556                	mv	a0,s5
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	aa4080e7          	jalr	-1372(ra) # 800041aa <iupdate>

  return tot;
    8000470e:	0009851b          	sext.w	a0,s3
}
    80004712:	70a6                	ld	ra,104(sp)
    80004714:	7406                	ld	s0,96(sp)
    80004716:	64e6                	ld	s1,88(sp)
    80004718:	6946                	ld	s2,80(sp)
    8000471a:	69a6                	ld	s3,72(sp)
    8000471c:	6a06                	ld	s4,64(sp)
    8000471e:	7ae2                	ld	s5,56(sp)
    80004720:	7b42                	ld	s6,48(sp)
    80004722:	7ba2                	ld	s7,40(sp)
    80004724:	7c02                	ld	s8,32(sp)
    80004726:	6ce2                	ld	s9,24(sp)
    80004728:	6d42                	ld	s10,16(sp)
    8000472a:	6da2                	ld	s11,8(sp)
    8000472c:	6165                	addi	sp,sp,112
    8000472e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004730:	89da                	mv	s3,s6
    80004732:	bfc9                	j	80004704 <writei+0xe2>
    return -1;
    80004734:	557d                	li	a0,-1
}
    80004736:	8082                	ret
    return -1;
    80004738:	557d                	li	a0,-1
    8000473a:	bfe1                	j	80004712 <writei+0xf0>
    return -1;
    8000473c:	557d                	li	a0,-1
    8000473e:	bfd1                	j	80004712 <writei+0xf0>

0000000080004740 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004740:	1141                	addi	sp,sp,-16
    80004742:	e406                	sd	ra,8(sp)
    80004744:	e022                	sd	s0,0(sp)
    80004746:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004748:	4639                	li	a2,14
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	78e080e7          	jalr	1934(ra) # 80000ed8 <strncmp>
}
    80004752:	60a2                	ld	ra,8(sp)
    80004754:	6402                	ld	s0,0(sp)
    80004756:	0141                	addi	sp,sp,16
    80004758:	8082                	ret

000000008000475a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000475a:	7139                	addi	sp,sp,-64
    8000475c:	fc06                	sd	ra,56(sp)
    8000475e:	f822                	sd	s0,48(sp)
    80004760:	f426                	sd	s1,40(sp)
    80004762:	f04a                	sd	s2,32(sp)
    80004764:	ec4e                	sd	s3,24(sp)
    80004766:	e852                	sd	s4,16(sp)
    80004768:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000476a:	04451703          	lh	a4,68(a0)
    8000476e:	4785                	li	a5,1
    80004770:	00f71a63          	bne	a4,a5,80004784 <dirlookup+0x2a>
    80004774:	892a                	mv	s2,a0
    80004776:	89ae                	mv	s3,a1
    80004778:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000477a:	457c                	lw	a5,76(a0)
    8000477c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000477e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004780:	e79d                	bnez	a5,800047ae <dirlookup+0x54>
    80004782:	a8a5                	j	800047fa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004784:	00004517          	auipc	a0,0x4
    80004788:	12450513          	addi	a0,a0,292 # 800088a8 <syscall_list+0x1b8>
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	db4080e7          	jalr	-588(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004794:	00004517          	auipc	a0,0x4
    80004798:	12c50513          	addi	a0,a0,300 # 800088c0 <syscall_list+0x1d0>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	da4080e7          	jalr	-604(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047a4:	24c1                	addiw	s1,s1,16
    800047a6:	04c92783          	lw	a5,76(s2)
    800047aa:	04f4f763          	bgeu	s1,a5,800047f8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047ae:	4741                	li	a4,16
    800047b0:	86a6                	mv	a3,s1
    800047b2:	fc040613          	addi	a2,s0,-64
    800047b6:	4581                	li	a1,0
    800047b8:	854a                	mv	a0,s2
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	d70080e7          	jalr	-656(ra) # 8000452a <readi>
    800047c2:	47c1                	li	a5,16
    800047c4:	fcf518e3          	bne	a0,a5,80004794 <dirlookup+0x3a>
    if(de.inum == 0)
    800047c8:	fc045783          	lhu	a5,-64(s0)
    800047cc:	dfe1                	beqz	a5,800047a4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800047ce:	fc240593          	addi	a1,s0,-62
    800047d2:	854e                	mv	a0,s3
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	f6c080e7          	jalr	-148(ra) # 80004740 <namecmp>
    800047dc:	f561                	bnez	a0,800047a4 <dirlookup+0x4a>
      if(poff)
    800047de:	000a0463          	beqz	s4,800047e6 <dirlookup+0x8c>
        *poff = off;
    800047e2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800047e6:	fc045583          	lhu	a1,-64(s0)
    800047ea:	00092503          	lw	a0,0(s2)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	74e080e7          	jalr	1870(ra) # 80003f3c <iget>
    800047f6:	a011                	j	800047fa <dirlookup+0xa0>
  return 0;
    800047f8:	4501                	li	a0,0
}
    800047fa:	70e2                	ld	ra,56(sp)
    800047fc:	7442                	ld	s0,48(sp)
    800047fe:	74a2                	ld	s1,40(sp)
    80004800:	7902                	ld	s2,32(sp)
    80004802:	69e2                	ld	s3,24(sp)
    80004804:	6a42                	ld	s4,16(sp)
    80004806:	6121                	addi	sp,sp,64
    80004808:	8082                	ret

000000008000480a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000480a:	711d                	addi	sp,sp,-96
    8000480c:	ec86                	sd	ra,88(sp)
    8000480e:	e8a2                	sd	s0,80(sp)
    80004810:	e4a6                	sd	s1,72(sp)
    80004812:	e0ca                	sd	s2,64(sp)
    80004814:	fc4e                	sd	s3,56(sp)
    80004816:	f852                	sd	s4,48(sp)
    80004818:	f456                	sd	s5,40(sp)
    8000481a:	f05a                	sd	s6,32(sp)
    8000481c:	ec5e                	sd	s7,24(sp)
    8000481e:	e862                	sd	s8,16(sp)
    80004820:	e466                	sd	s9,8(sp)
    80004822:	e06a                	sd	s10,0(sp)
    80004824:	1080                	addi	s0,sp,96
    80004826:	84aa                	mv	s1,a0
    80004828:	8b2e                	mv	s6,a1
    8000482a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000482c:	00054703          	lbu	a4,0(a0)
    80004830:	02f00793          	li	a5,47
    80004834:	02f70363          	beq	a4,a5,8000485a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004838:	ffffd097          	auipc	ra,0xffffd
    8000483c:	2c4080e7          	jalr	708(ra) # 80001afc <myproc>
    80004840:	16053503          	ld	a0,352(a0)
    80004844:	00000097          	auipc	ra,0x0
    80004848:	9f4080e7          	jalr	-1548(ra) # 80004238 <idup>
    8000484c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000484e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004852:	4cb5                	li	s9,13
  len = path - s;
    80004854:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004856:	4c05                	li	s8,1
    80004858:	a87d                	j	80004916 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000485a:	4585                	li	a1,1
    8000485c:	4505                	li	a0,1
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	6de080e7          	jalr	1758(ra) # 80003f3c <iget>
    80004866:	8a2a                	mv	s4,a0
    80004868:	b7dd                	j	8000484e <namex+0x44>
      iunlockput(ip);
    8000486a:	8552                	mv	a0,s4
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	c6c080e7          	jalr	-916(ra) # 800044d8 <iunlockput>
      return 0;
    80004874:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004876:	8552                	mv	a0,s4
    80004878:	60e6                	ld	ra,88(sp)
    8000487a:	6446                	ld	s0,80(sp)
    8000487c:	64a6                	ld	s1,72(sp)
    8000487e:	6906                	ld	s2,64(sp)
    80004880:	79e2                	ld	s3,56(sp)
    80004882:	7a42                	ld	s4,48(sp)
    80004884:	7aa2                	ld	s5,40(sp)
    80004886:	7b02                	ld	s6,32(sp)
    80004888:	6be2                	ld	s7,24(sp)
    8000488a:	6c42                	ld	s8,16(sp)
    8000488c:	6ca2                	ld	s9,8(sp)
    8000488e:	6d02                	ld	s10,0(sp)
    80004890:	6125                	addi	sp,sp,96
    80004892:	8082                	ret
      iunlock(ip);
    80004894:	8552                	mv	a0,s4
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	aa2080e7          	jalr	-1374(ra) # 80004338 <iunlock>
      return ip;
    8000489e:	bfe1                	j	80004876 <namex+0x6c>
      iunlockput(ip);
    800048a0:	8552                	mv	a0,s4
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	c36080e7          	jalr	-970(ra) # 800044d8 <iunlockput>
      return 0;
    800048aa:	8a4e                	mv	s4,s3
    800048ac:	b7e9                	j	80004876 <namex+0x6c>
  len = path - s;
    800048ae:	40998633          	sub	a2,s3,s1
    800048b2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800048b6:	09acd863          	bge	s9,s10,80004946 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800048ba:	4639                	li	a2,14
    800048bc:	85a6                	mv	a1,s1
    800048be:	8556                	mv	a0,s5
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	5a4080e7          	jalr	1444(ra) # 80000e64 <memmove>
    800048c8:	84ce                	mv	s1,s3
  while(*path == '/')
    800048ca:	0004c783          	lbu	a5,0(s1)
    800048ce:	01279763          	bne	a5,s2,800048dc <namex+0xd2>
    path++;
    800048d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048d4:	0004c783          	lbu	a5,0(s1)
    800048d8:	ff278de3          	beq	a5,s2,800048d2 <namex+0xc8>
    ilock(ip);
    800048dc:	8552                	mv	a0,s4
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	998080e7          	jalr	-1640(ra) # 80004276 <ilock>
    if(ip->type != T_DIR){
    800048e6:	044a1783          	lh	a5,68(s4)
    800048ea:	f98790e3          	bne	a5,s8,8000486a <namex+0x60>
    if(nameiparent && *path == '\0'){
    800048ee:	000b0563          	beqz	s6,800048f8 <namex+0xee>
    800048f2:	0004c783          	lbu	a5,0(s1)
    800048f6:	dfd9                	beqz	a5,80004894 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800048f8:	865e                	mv	a2,s7
    800048fa:	85d6                	mv	a1,s5
    800048fc:	8552                	mv	a0,s4
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	e5c080e7          	jalr	-420(ra) # 8000475a <dirlookup>
    80004906:	89aa                	mv	s3,a0
    80004908:	dd41                	beqz	a0,800048a0 <namex+0x96>
    iunlockput(ip);
    8000490a:	8552                	mv	a0,s4
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	bcc080e7          	jalr	-1076(ra) # 800044d8 <iunlockput>
    ip = next;
    80004914:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004916:	0004c783          	lbu	a5,0(s1)
    8000491a:	01279763          	bne	a5,s2,80004928 <namex+0x11e>
    path++;
    8000491e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004920:	0004c783          	lbu	a5,0(s1)
    80004924:	ff278de3          	beq	a5,s2,8000491e <namex+0x114>
  if(*path == 0)
    80004928:	cb9d                	beqz	a5,8000495e <namex+0x154>
  while(*path != '/' && *path != 0)
    8000492a:	0004c783          	lbu	a5,0(s1)
    8000492e:	89a6                	mv	s3,s1
  len = path - s;
    80004930:	8d5e                	mv	s10,s7
    80004932:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004934:	01278963          	beq	a5,s2,80004946 <namex+0x13c>
    80004938:	dbbd                	beqz	a5,800048ae <namex+0xa4>
    path++;
    8000493a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000493c:	0009c783          	lbu	a5,0(s3)
    80004940:	ff279ce3          	bne	a5,s2,80004938 <namex+0x12e>
    80004944:	b7ad                	j	800048ae <namex+0xa4>
    memmove(name, s, len);
    80004946:	2601                	sext.w	a2,a2
    80004948:	85a6                	mv	a1,s1
    8000494a:	8556                	mv	a0,s5
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	518080e7          	jalr	1304(ra) # 80000e64 <memmove>
    name[len] = 0;
    80004954:	9d56                	add	s10,s10,s5
    80004956:	000d0023          	sb	zero,0(s10)
    8000495a:	84ce                	mv	s1,s3
    8000495c:	b7bd                	j	800048ca <namex+0xc0>
  if(nameiparent){
    8000495e:	f00b0ce3          	beqz	s6,80004876 <namex+0x6c>
    iput(ip);
    80004962:	8552                	mv	a0,s4
    80004964:	00000097          	auipc	ra,0x0
    80004968:	acc080e7          	jalr	-1332(ra) # 80004430 <iput>
    return 0;
    8000496c:	4a01                	li	s4,0
    8000496e:	b721                	j	80004876 <namex+0x6c>

0000000080004970 <dirlink>:
{
    80004970:	7139                	addi	sp,sp,-64
    80004972:	fc06                	sd	ra,56(sp)
    80004974:	f822                	sd	s0,48(sp)
    80004976:	f426                	sd	s1,40(sp)
    80004978:	f04a                	sd	s2,32(sp)
    8000497a:	ec4e                	sd	s3,24(sp)
    8000497c:	e852                	sd	s4,16(sp)
    8000497e:	0080                	addi	s0,sp,64
    80004980:	892a                	mv	s2,a0
    80004982:	8a2e                	mv	s4,a1
    80004984:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004986:	4601                	li	a2,0
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	dd2080e7          	jalr	-558(ra) # 8000475a <dirlookup>
    80004990:	e93d                	bnez	a0,80004a06 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004992:	04c92483          	lw	s1,76(s2)
    80004996:	c49d                	beqz	s1,800049c4 <dirlink+0x54>
    80004998:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000499a:	4741                	li	a4,16
    8000499c:	86a6                	mv	a3,s1
    8000499e:	fc040613          	addi	a2,s0,-64
    800049a2:	4581                	li	a1,0
    800049a4:	854a                	mv	a0,s2
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	b84080e7          	jalr	-1148(ra) # 8000452a <readi>
    800049ae:	47c1                	li	a5,16
    800049b0:	06f51163          	bne	a0,a5,80004a12 <dirlink+0xa2>
    if(de.inum == 0)
    800049b4:	fc045783          	lhu	a5,-64(s0)
    800049b8:	c791                	beqz	a5,800049c4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049ba:	24c1                	addiw	s1,s1,16
    800049bc:	04c92783          	lw	a5,76(s2)
    800049c0:	fcf4ede3          	bltu	s1,a5,8000499a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049c4:	4639                	li	a2,14
    800049c6:	85d2                	mv	a1,s4
    800049c8:	fc240513          	addi	a0,s0,-62
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	548080e7          	jalr	1352(ra) # 80000f14 <strncpy>
  de.inum = inum;
    800049d4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049d8:	4741                	li	a4,16
    800049da:	86a6                	mv	a3,s1
    800049dc:	fc040613          	addi	a2,s0,-64
    800049e0:	4581                	li	a1,0
    800049e2:	854a                	mv	a0,s2
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	c3e080e7          	jalr	-962(ra) # 80004622 <writei>
    800049ec:	1541                	addi	a0,a0,-16
    800049ee:	00a03533          	snez	a0,a0
    800049f2:	40a00533          	neg	a0,a0
}
    800049f6:	70e2                	ld	ra,56(sp)
    800049f8:	7442                	ld	s0,48(sp)
    800049fa:	74a2                	ld	s1,40(sp)
    800049fc:	7902                	ld	s2,32(sp)
    800049fe:	69e2                	ld	s3,24(sp)
    80004a00:	6a42                	ld	s4,16(sp)
    80004a02:	6121                	addi	sp,sp,64
    80004a04:	8082                	ret
    iput(ip);
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	a2a080e7          	jalr	-1494(ra) # 80004430 <iput>
    return -1;
    80004a0e:	557d                	li	a0,-1
    80004a10:	b7dd                	j	800049f6 <dirlink+0x86>
      panic("dirlink read");
    80004a12:	00004517          	auipc	a0,0x4
    80004a16:	ebe50513          	addi	a0,a0,-322 # 800088d0 <syscall_list+0x1e0>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	b26080e7          	jalr	-1242(ra) # 80000540 <panic>

0000000080004a22 <namei>:

struct inode*
namei(char *path)
{
    80004a22:	1101                	addi	sp,sp,-32
    80004a24:	ec06                	sd	ra,24(sp)
    80004a26:	e822                	sd	s0,16(sp)
    80004a28:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a2a:	fe040613          	addi	a2,s0,-32
    80004a2e:	4581                	li	a1,0
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	dda080e7          	jalr	-550(ra) # 8000480a <namex>
}
    80004a38:	60e2                	ld	ra,24(sp)
    80004a3a:	6442                	ld	s0,16(sp)
    80004a3c:	6105                	addi	sp,sp,32
    80004a3e:	8082                	ret

0000000080004a40 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a40:	1141                	addi	sp,sp,-16
    80004a42:	e406                	sd	ra,8(sp)
    80004a44:	e022                	sd	s0,0(sp)
    80004a46:	0800                	addi	s0,sp,16
    80004a48:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a4a:	4585                	li	a1,1
    80004a4c:	00000097          	auipc	ra,0x0
    80004a50:	dbe080e7          	jalr	-578(ra) # 8000480a <namex>
}
    80004a54:	60a2                	ld	ra,8(sp)
    80004a56:	6402                	ld	s0,0(sp)
    80004a58:	0141                	addi	sp,sp,16
    80004a5a:	8082                	ret

0000000080004a5c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a5c:	1101                	addi	sp,sp,-32
    80004a5e:	ec06                	sd	ra,24(sp)
    80004a60:	e822                	sd	s0,16(sp)
    80004a62:	e426                	sd	s1,8(sp)
    80004a64:	e04a                	sd	s2,0(sp)
    80004a66:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a68:	00240917          	auipc	s2,0x240
    80004a6c:	c0890913          	addi	s2,s2,-1016 # 80244670 <log>
    80004a70:	01892583          	lw	a1,24(s2)
    80004a74:	02892503          	lw	a0,40(s2)
    80004a78:	fffff097          	auipc	ra,0xfffff
    80004a7c:	fe6080e7          	jalr	-26(ra) # 80003a5e <bread>
    80004a80:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a82:	02c92683          	lw	a3,44(s2)
    80004a86:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a88:	02d05863          	blez	a3,80004ab8 <write_head+0x5c>
    80004a8c:	00240797          	auipc	a5,0x240
    80004a90:	c1478793          	addi	a5,a5,-1004 # 802446a0 <log+0x30>
    80004a94:	05c50713          	addi	a4,a0,92
    80004a98:	36fd                	addiw	a3,a3,-1
    80004a9a:	02069613          	slli	a2,a3,0x20
    80004a9e:	01e65693          	srli	a3,a2,0x1e
    80004aa2:	00240617          	auipc	a2,0x240
    80004aa6:	c0260613          	addi	a2,a2,-1022 # 802446a4 <log+0x34>
    80004aaa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004aac:	4390                	lw	a2,0(a5)
    80004aae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ab0:	0791                	addi	a5,a5,4
    80004ab2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004ab4:	fed79ce3          	bne	a5,a3,80004aac <write_head+0x50>
  }
  bwrite(buf);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	096080e7          	jalr	150(ra) # 80003b50 <bwrite>
  brelse(buf);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	0ca080e7          	jalr	202(ra) # 80003b8e <brelse>
}
    80004acc:	60e2                	ld	ra,24(sp)
    80004ace:	6442                	ld	s0,16(sp)
    80004ad0:	64a2                	ld	s1,8(sp)
    80004ad2:	6902                	ld	s2,0(sp)
    80004ad4:	6105                	addi	sp,sp,32
    80004ad6:	8082                	ret

0000000080004ad8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad8:	00240797          	auipc	a5,0x240
    80004adc:	bc47a783          	lw	a5,-1084(a5) # 8024469c <log+0x2c>
    80004ae0:	0af05d63          	blez	a5,80004b9a <install_trans+0xc2>
{
    80004ae4:	7139                	addi	sp,sp,-64
    80004ae6:	fc06                	sd	ra,56(sp)
    80004ae8:	f822                	sd	s0,48(sp)
    80004aea:	f426                	sd	s1,40(sp)
    80004aec:	f04a                	sd	s2,32(sp)
    80004aee:	ec4e                	sd	s3,24(sp)
    80004af0:	e852                	sd	s4,16(sp)
    80004af2:	e456                	sd	s5,8(sp)
    80004af4:	e05a                	sd	s6,0(sp)
    80004af6:	0080                	addi	s0,sp,64
    80004af8:	8b2a                	mv	s6,a0
    80004afa:	00240a97          	auipc	s5,0x240
    80004afe:	ba6a8a93          	addi	s5,s5,-1114 # 802446a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b02:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b04:	00240997          	auipc	s3,0x240
    80004b08:	b6c98993          	addi	s3,s3,-1172 # 80244670 <log>
    80004b0c:	a00d                	j	80004b2e <install_trans+0x56>
    brelse(lbuf);
    80004b0e:	854a                	mv	a0,s2
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	07e080e7          	jalr	126(ra) # 80003b8e <brelse>
    brelse(dbuf);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	074080e7          	jalr	116(ra) # 80003b8e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b22:	2a05                	addiw	s4,s4,1
    80004b24:	0a91                	addi	s5,s5,4
    80004b26:	02c9a783          	lw	a5,44(s3)
    80004b2a:	04fa5e63          	bge	s4,a5,80004b86 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b2e:	0189a583          	lw	a1,24(s3)
    80004b32:	014585bb          	addw	a1,a1,s4
    80004b36:	2585                	addiw	a1,a1,1
    80004b38:	0289a503          	lw	a0,40(s3)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	f22080e7          	jalr	-222(ra) # 80003a5e <bread>
    80004b44:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b46:	000aa583          	lw	a1,0(s5)
    80004b4a:	0289a503          	lw	a0,40(s3)
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	f10080e7          	jalr	-240(ra) # 80003a5e <bread>
    80004b56:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b58:	40000613          	li	a2,1024
    80004b5c:	05890593          	addi	a1,s2,88
    80004b60:	05850513          	addi	a0,a0,88
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	300080e7          	jalr	768(ra) # 80000e64 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	fe2080e7          	jalr	-30(ra) # 80003b50 <bwrite>
    if(recovering == 0)
    80004b76:	f80b1ce3          	bnez	s6,80004b0e <install_trans+0x36>
      bunpin(dbuf);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	0ec080e7          	jalr	236(ra) # 80003c68 <bunpin>
    80004b84:	b769                	j	80004b0e <install_trans+0x36>
}
    80004b86:	70e2                	ld	ra,56(sp)
    80004b88:	7442                	ld	s0,48(sp)
    80004b8a:	74a2                	ld	s1,40(sp)
    80004b8c:	7902                	ld	s2,32(sp)
    80004b8e:	69e2                	ld	s3,24(sp)
    80004b90:	6a42                	ld	s4,16(sp)
    80004b92:	6aa2                	ld	s5,8(sp)
    80004b94:	6b02                	ld	s6,0(sp)
    80004b96:	6121                	addi	sp,sp,64
    80004b98:	8082                	ret
    80004b9a:	8082                	ret

0000000080004b9c <initlog>:
{
    80004b9c:	7179                	addi	sp,sp,-48
    80004b9e:	f406                	sd	ra,40(sp)
    80004ba0:	f022                	sd	s0,32(sp)
    80004ba2:	ec26                	sd	s1,24(sp)
    80004ba4:	e84a                	sd	s2,16(sp)
    80004ba6:	e44e                	sd	s3,8(sp)
    80004ba8:	1800                	addi	s0,sp,48
    80004baa:	892a                	mv	s2,a0
    80004bac:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bae:	00240497          	auipc	s1,0x240
    80004bb2:	ac248493          	addi	s1,s1,-1342 # 80244670 <log>
    80004bb6:	00004597          	auipc	a1,0x4
    80004bba:	d2a58593          	addi	a1,a1,-726 # 800088e0 <syscall_list+0x1f0>
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	0bc080e7          	jalr	188(ra) # 80000c7c <initlock>
  log.start = sb->logstart;
    80004bc8:	0149a583          	lw	a1,20(s3)
    80004bcc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004bce:	0109a783          	lw	a5,16(s3)
    80004bd2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004bd4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004bd8:	854a                	mv	a0,s2
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	e84080e7          	jalr	-380(ra) # 80003a5e <bread>
  log.lh.n = lh->n;
    80004be2:	4d34                	lw	a3,88(a0)
    80004be4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004be6:	02d05663          	blez	a3,80004c12 <initlog+0x76>
    80004bea:	05c50793          	addi	a5,a0,92
    80004bee:	00240717          	auipc	a4,0x240
    80004bf2:	ab270713          	addi	a4,a4,-1358 # 802446a0 <log+0x30>
    80004bf6:	36fd                	addiw	a3,a3,-1
    80004bf8:	02069613          	slli	a2,a3,0x20
    80004bfc:	01e65693          	srli	a3,a2,0x1e
    80004c00:	06050613          	addi	a2,a0,96
    80004c04:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c06:	4390                	lw	a2,0(a5)
    80004c08:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c0a:	0791                	addi	a5,a5,4
    80004c0c:	0711                	addi	a4,a4,4
    80004c0e:	fed79ce3          	bne	a5,a3,80004c06 <initlog+0x6a>
  brelse(buf);
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	f7c080e7          	jalr	-132(ra) # 80003b8e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c1a:	4505                	li	a0,1
    80004c1c:	00000097          	auipc	ra,0x0
    80004c20:	ebc080e7          	jalr	-324(ra) # 80004ad8 <install_trans>
  log.lh.n = 0;
    80004c24:	00240797          	auipc	a5,0x240
    80004c28:	a607ac23          	sw	zero,-1416(a5) # 8024469c <log+0x2c>
  write_head(); // clear the log
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	e30080e7          	jalr	-464(ra) # 80004a5c <write_head>
}
    80004c34:	70a2                	ld	ra,40(sp)
    80004c36:	7402                	ld	s0,32(sp)
    80004c38:	64e2                	ld	s1,24(sp)
    80004c3a:	6942                	ld	s2,16(sp)
    80004c3c:	69a2                	ld	s3,8(sp)
    80004c3e:	6145                	addi	sp,sp,48
    80004c40:	8082                	ret

0000000080004c42 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c42:	1101                	addi	sp,sp,-32
    80004c44:	ec06                	sd	ra,24(sp)
    80004c46:	e822                	sd	s0,16(sp)
    80004c48:	e426                	sd	s1,8(sp)
    80004c4a:	e04a                	sd	s2,0(sp)
    80004c4c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c4e:	00240517          	auipc	a0,0x240
    80004c52:	a2250513          	addi	a0,a0,-1502 # 80244670 <log>
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	0b6080e7          	jalr	182(ra) # 80000d0c <acquire>
  while(1){
    if(log.committing){
    80004c5e:	00240497          	auipc	s1,0x240
    80004c62:	a1248493          	addi	s1,s1,-1518 # 80244670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c66:	4979                	li	s2,30
    80004c68:	a039                	j	80004c76 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c6a:	85a6                	mv	a1,s1
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffe097          	auipc	ra,0xffffe
    80004c72:	8b2080e7          	jalr	-1870(ra) # 80002520 <sleep>
    if(log.committing){
    80004c76:	50dc                	lw	a5,36(s1)
    80004c78:	fbed                	bnez	a5,80004c6a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c7a:	5098                	lw	a4,32(s1)
    80004c7c:	2705                	addiw	a4,a4,1
    80004c7e:	0007069b          	sext.w	a3,a4
    80004c82:	0027179b          	slliw	a5,a4,0x2
    80004c86:	9fb9                	addw	a5,a5,a4
    80004c88:	0017979b          	slliw	a5,a5,0x1
    80004c8c:	54d8                	lw	a4,44(s1)
    80004c8e:	9fb9                	addw	a5,a5,a4
    80004c90:	00f95963          	bge	s2,a5,80004ca2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c94:	85a6                	mv	a1,s1
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffe097          	auipc	ra,0xffffe
    80004c9c:	888080e7          	jalr	-1912(ra) # 80002520 <sleep>
    80004ca0:	bfd9                	j	80004c76 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ca2:	00240517          	auipc	a0,0x240
    80004ca6:	9ce50513          	addi	a0,a0,-1586 # 80244670 <log>
    80004caa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	114080e7          	jalr	276(ra) # 80000dc0 <release>
      break;
    }
  }
}
    80004cb4:	60e2                	ld	ra,24(sp)
    80004cb6:	6442                	ld	s0,16(sp)
    80004cb8:	64a2                	ld	s1,8(sp)
    80004cba:	6902                	ld	s2,0(sp)
    80004cbc:	6105                	addi	sp,sp,32
    80004cbe:	8082                	ret

0000000080004cc0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cc0:	7139                	addi	sp,sp,-64
    80004cc2:	fc06                	sd	ra,56(sp)
    80004cc4:	f822                	sd	s0,48(sp)
    80004cc6:	f426                	sd	s1,40(sp)
    80004cc8:	f04a                	sd	s2,32(sp)
    80004cca:	ec4e                	sd	s3,24(sp)
    80004ccc:	e852                	sd	s4,16(sp)
    80004cce:	e456                	sd	s5,8(sp)
    80004cd0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004cd2:	00240497          	auipc	s1,0x240
    80004cd6:	99e48493          	addi	s1,s1,-1634 # 80244670 <log>
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	030080e7          	jalr	48(ra) # 80000d0c <acquire>
  log.outstanding -= 1;
    80004ce4:	509c                	lw	a5,32(s1)
    80004ce6:	37fd                	addiw	a5,a5,-1
    80004ce8:	0007891b          	sext.w	s2,a5
    80004cec:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004cee:	50dc                	lw	a5,36(s1)
    80004cf0:	e7b9                	bnez	a5,80004d3e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004cf2:	04091e63          	bnez	s2,80004d4e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004cf6:	00240497          	auipc	s1,0x240
    80004cfa:	97a48493          	addi	s1,s1,-1670 # 80244670 <log>
    80004cfe:	4785                	li	a5,1
    80004d00:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	0bc080e7          	jalr	188(ra) # 80000dc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d0c:	54dc                	lw	a5,44(s1)
    80004d0e:	06f04763          	bgtz	a5,80004d7c <end_op+0xbc>
    acquire(&log.lock);
    80004d12:	00240497          	auipc	s1,0x240
    80004d16:	95e48493          	addi	s1,s1,-1698 # 80244670 <log>
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	ff0080e7          	jalr	-16(ra) # 80000d0c <acquire>
    log.committing = 0;
    80004d24:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d28:	8526                	mv	a0,s1
    80004d2a:	ffffe097          	auipc	ra,0xffffe
    80004d2e:	85a080e7          	jalr	-1958(ra) # 80002584 <wakeup>
    release(&log.lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	08c080e7          	jalr	140(ra) # 80000dc0 <release>
}
    80004d3c:	a03d                	j	80004d6a <end_op+0xaa>
    panic("log.committing");
    80004d3e:	00004517          	auipc	a0,0x4
    80004d42:	baa50513          	addi	a0,a0,-1110 # 800088e8 <syscall_list+0x1f8>
    80004d46:	ffffb097          	auipc	ra,0xffffb
    80004d4a:	7fa080e7          	jalr	2042(ra) # 80000540 <panic>
    wakeup(&log);
    80004d4e:	00240497          	auipc	s1,0x240
    80004d52:	92248493          	addi	s1,s1,-1758 # 80244670 <log>
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffe097          	auipc	ra,0xffffe
    80004d5c:	82c080e7          	jalr	-2004(ra) # 80002584 <wakeup>
  release(&log.lock);
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	05e080e7          	jalr	94(ra) # 80000dc0 <release>
}
    80004d6a:	70e2                	ld	ra,56(sp)
    80004d6c:	7442                	ld	s0,48(sp)
    80004d6e:	74a2                	ld	s1,40(sp)
    80004d70:	7902                	ld	s2,32(sp)
    80004d72:	69e2                	ld	s3,24(sp)
    80004d74:	6a42                	ld	s4,16(sp)
    80004d76:	6aa2                	ld	s5,8(sp)
    80004d78:	6121                	addi	sp,sp,64
    80004d7a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d7c:	00240a97          	auipc	s5,0x240
    80004d80:	924a8a93          	addi	s5,s5,-1756 # 802446a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d84:	00240a17          	auipc	s4,0x240
    80004d88:	8eca0a13          	addi	s4,s4,-1812 # 80244670 <log>
    80004d8c:	018a2583          	lw	a1,24(s4)
    80004d90:	012585bb          	addw	a1,a1,s2
    80004d94:	2585                	addiw	a1,a1,1
    80004d96:	028a2503          	lw	a0,40(s4)
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	cc4080e7          	jalr	-828(ra) # 80003a5e <bread>
    80004da2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004da4:	000aa583          	lw	a1,0(s5)
    80004da8:	028a2503          	lw	a0,40(s4)
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	cb2080e7          	jalr	-846(ra) # 80003a5e <bread>
    80004db4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004db6:	40000613          	li	a2,1024
    80004dba:	05850593          	addi	a1,a0,88
    80004dbe:	05848513          	addi	a0,s1,88
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	0a2080e7          	jalr	162(ra) # 80000e64 <memmove>
    bwrite(to);  // write the log
    80004dca:	8526                	mv	a0,s1
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	d84080e7          	jalr	-636(ra) # 80003b50 <bwrite>
    brelse(from);
    80004dd4:	854e                	mv	a0,s3
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	db8080e7          	jalr	-584(ra) # 80003b8e <brelse>
    brelse(to);
    80004dde:	8526                	mv	a0,s1
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	dae080e7          	jalr	-594(ra) # 80003b8e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004de8:	2905                	addiw	s2,s2,1
    80004dea:	0a91                	addi	s5,s5,4
    80004dec:	02ca2783          	lw	a5,44(s4)
    80004df0:	f8f94ee3          	blt	s2,a5,80004d8c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	c68080e7          	jalr	-920(ra) # 80004a5c <write_head>
    install_trans(0); // Now install writes to home locations
    80004dfc:	4501                	li	a0,0
    80004dfe:	00000097          	auipc	ra,0x0
    80004e02:	cda080e7          	jalr	-806(ra) # 80004ad8 <install_trans>
    log.lh.n = 0;
    80004e06:	00240797          	auipc	a5,0x240
    80004e0a:	8807ab23          	sw	zero,-1898(a5) # 8024469c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	c4e080e7          	jalr	-946(ra) # 80004a5c <write_head>
    80004e16:	bdf5                	j	80004d12 <end_op+0x52>

0000000080004e18 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e18:	1101                	addi	sp,sp,-32
    80004e1a:	ec06                	sd	ra,24(sp)
    80004e1c:	e822                	sd	s0,16(sp)
    80004e1e:	e426                	sd	s1,8(sp)
    80004e20:	e04a                	sd	s2,0(sp)
    80004e22:	1000                	addi	s0,sp,32
    80004e24:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e26:	00240917          	auipc	s2,0x240
    80004e2a:	84a90913          	addi	s2,s2,-1974 # 80244670 <log>
    80004e2e:	854a                	mv	a0,s2
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	edc080e7          	jalr	-292(ra) # 80000d0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e38:	02c92603          	lw	a2,44(s2)
    80004e3c:	47f5                	li	a5,29
    80004e3e:	06c7c563          	blt	a5,a2,80004ea8 <log_write+0x90>
    80004e42:	00240797          	auipc	a5,0x240
    80004e46:	84a7a783          	lw	a5,-1974(a5) # 8024468c <log+0x1c>
    80004e4a:	37fd                	addiw	a5,a5,-1
    80004e4c:	04f65e63          	bge	a2,a5,80004ea8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e50:	00240797          	auipc	a5,0x240
    80004e54:	8407a783          	lw	a5,-1984(a5) # 80244690 <log+0x20>
    80004e58:	06f05063          	blez	a5,80004eb8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e5c:	4781                	li	a5,0
    80004e5e:	06c05563          	blez	a2,80004ec8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e62:	44cc                	lw	a1,12(s1)
    80004e64:	00240717          	auipc	a4,0x240
    80004e68:	83c70713          	addi	a4,a4,-1988 # 802446a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e6c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e6e:	4314                	lw	a3,0(a4)
    80004e70:	04b68c63          	beq	a3,a1,80004ec8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e74:	2785                	addiw	a5,a5,1
    80004e76:	0711                	addi	a4,a4,4
    80004e78:	fef61be3          	bne	a2,a5,80004e6e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e7c:	0621                	addi	a2,a2,8
    80004e7e:	060a                	slli	a2,a2,0x2
    80004e80:	0023f797          	auipc	a5,0x23f
    80004e84:	7f078793          	addi	a5,a5,2032 # 80244670 <log>
    80004e88:	97b2                	add	a5,a5,a2
    80004e8a:	44d8                	lw	a4,12(s1)
    80004e8c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e8e:	8526                	mv	a0,s1
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	d9c080e7          	jalr	-612(ra) # 80003c2c <bpin>
    log.lh.n++;
    80004e98:	0023f717          	auipc	a4,0x23f
    80004e9c:	7d870713          	addi	a4,a4,2008 # 80244670 <log>
    80004ea0:	575c                	lw	a5,44(a4)
    80004ea2:	2785                	addiw	a5,a5,1
    80004ea4:	d75c                	sw	a5,44(a4)
    80004ea6:	a82d                	j	80004ee0 <log_write+0xc8>
    panic("too big a transaction");
    80004ea8:	00004517          	auipc	a0,0x4
    80004eac:	a5050513          	addi	a0,a0,-1456 # 800088f8 <syscall_list+0x208>
    80004eb0:	ffffb097          	auipc	ra,0xffffb
    80004eb4:	690080e7          	jalr	1680(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004eb8:	00004517          	auipc	a0,0x4
    80004ebc:	a5850513          	addi	a0,a0,-1448 # 80008910 <syscall_list+0x220>
    80004ec0:	ffffb097          	auipc	ra,0xffffb
    80004ec4:	680080e7          	jalr	1664(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004ec8:	00878693          	addi	a3,a5,8
    80004ecc:	068a                	slli	a3,a3,0x2
    80004ece:	0023f717          	auipc	a4,0x23f
    80004ed2:	7a270713          	addi	a4,a4,1954 # 80244670 <log>
    80004ed6:	9736                	add	a4,a4,a3
    80004ed8:	44d4                	lw	a3,12(s1)
    80004eda:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004edc:	faf609e3          	beq	a2,a5,80004e8e <log_write+0x76>
  }
  release(&log.lock);
    80004ee0:	0023f517          	auipc	a0,0x23f
    80004ee4:	79050513          	addi	a0,a0,1936 # 80244670 <log>
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	ed8080e7          	jalr	-296(ra) # 80000dc0 <release>
}
    80004ef0:	60e2                	ld	ra,24(sp)
    80004ef2:	6442                	ld	s0,16(sp)
    80004ef4:	64a2                	ld	s1,8(sp)
    80004ef6:	6902                	ld	s2,0(sp)
    80004ef8:	6105                	addi	sp,sp,32
    80004efa:	8082                	ret

0000000080004efc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004efc:	1101                	addi	sp,sp,-32
    80004efe:	ec06                	sd	ra,24(sp)
    80004f00:	e822                	sd	s0,16(sp)
    80004f02:	e426                	sd	s1,8(sp)
    80004f04:	e04a                	sd	s2,0(sp)
    80004f06:	1000                	addi	s0,sp,32
    80004f08:	84aa                	mv	s1,a0
    80004f0a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f0c:	00004597          	auipc	a1,0x4
    80004f10:	a2458593          	addi	a1,a1,-1500 # 80008930 <syscall_list+0x240>
    80004f14:	0521                	addi	a0,a0,8
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	d66080e7          	jalr	-666(ra) # 80000c7c <initlock>
  lk->name = name;
    80004f1e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f22:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f26:	0204a423          	sw	zero,40(s1)
}
    80004f2a:	60e2                	ld	ra,24(sp)
    80004f2c:	6442                	ld	s0,16(sp)
    80004f2e:	64a2                	ld	s1,8(sp)
    80004f30:	6902                	ld	s2,0(sp)
    80004f32:	6105                	addi	sp,sp,32
    80004f34:	8082                	ret

0000000080004f36 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f36:	1101                	addi	sp,sp,-32
    80004f38:	ec06                	sd	ra,24(sp)
    80004f3a:	e822                	sd	s0,16(sp)
    80004f3c:	e426                	sd	s1,8(sp)
    80004f3e:	e04a                	sd	s2,0(sp)
    80004f40:	1000                	addi	s0,sp,32
    80004f42:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f44:	00850913          	addi	s2,a0,8
    80004f48:	854a                	mv	a0,s2
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	dc2080e7          	jalr	-574(ra) # 80000d0c <acquire>
  while (lk->locked) {
    80004f52:	409c                	lw	a5,0(s1)
    80004f54:	cb89                	beqz	a5,80004f66 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f56:	85ca                	mv	a1,s2
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	5c6080e7          	jalr	1478(ra) # 80002520 <sleep>
  while (lk->locked) {
    80004f62:	409c                	lw	a5,0(s1)
    80004f64:	fbed                	bnez	a5,80004f56 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f66:	4785                	li	a5,1
    80004f68:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	b92080e7          	jalr	-1134(ra) # 80001afc <myproc>
    80004f72:	591c                	lw	a5,48(a0)
    80004f74:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f76:	854a                	mv	a0,s2
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	e48080e7          	jalr	-440(ra) # 80000dc0 <release>
}
    80004f80:	60e2                	ld	ra,24(sp)
    80004f82:	6442                	ld	s0,16(sp)
    80004f84:	64a2                	ld	s1,8(sp)
    80004f86:	6902                	ld	s2,0(sp)
    80004f88:	6105                	addi	sp,sp,32
    80004f8a:	8082                	ret

0000000080004f8c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f8c:	1101                	addi	sp,sp,-32
    80004f8e:	ec06                	sd	ra,24(sp)
    80004f90:	e822                	sd	s0,16(sp)
    80004f92:	e426                	sd	s1,8(sp)
    80004f94:	e04a                	sd	s2,0(sp)
    80004f96:	1000                	addi	s0,sp,32
    80004f98:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f9a:	00850913          	addi	s2,a0,8
    80004f9e:	854a                	mv	a0,s2
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	d6c080e7          	jalr	-660(ra) # 80000d0c <acquire>
  lk->locked = 0;
    80004fa8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fac:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	5d2080e7          	jalr	1490(ra) # 80002584 <wakeup>
  release(&lk->lk);
    80004fba:	854a                	mv	a0,s2
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	e04080e7          	jalr	-508(ra) # 80000dc0 <release>
}
    80004fc4:	60e2                	ld	ra,24(sp)
    80004fc6:	6442                	ld	s0,16(sp)
    80004fc8:	64a2                	ld	s1,8(sp)
    80004fca:	6902                	ld	s2,0(sp)
    80004fcc:	6105                	addi	sp,sp,32
    80004fce:	8082                	ret

0000000080004fd0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004fd0:	7179                	addi	sp,sp,-48
    80004fd2:	f406                	sd	ra,40(sp)
    80004fd4:	f022                	sd	s0,32(sp)
    80004fd6:	ec26                	sd	s1,24(sp)
    80004fd8:	e84a                	sd	s2,16(sp)
    80004fda:	e44e                	sd	s3,8(sp)
    80004fdc:	1800                	addi	s0,sp,48
    80004fde:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004fe0:	00850913          	addi	s2,a0,8
    80004fe4:	854a                	mv	a0,s2
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	d26080e7          	jalr	-730(ra) # 80000d0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fee:	409c                	lw	a5,0(s1)
    80004ff0:	ef99                	bnez	a5,8000500e <holdingsleep+0x3e>
    80004ff2:	4481                	li	s1,0
  release(&lk->lk);
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	dca080e7          	jalr	-566(ra) # 80000dc0 <release>
  return r;
}
    80004ffe:	8526                	mv	a0,s1
    80005000:	70a2                	ld	ra,40(sp)
    80005002:	7402                	ld	s0,32(sp)
    80005004:	64e2                	ld	s1,24(sp)
    80005006:	6942                	ld	s2,16(sp)
    80005008:	69a2                	ld	s3,8(sp)
    8000500a:	6145                	addi	sp,sp,48
    8000500c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000500e:	0284a983          	lw	s3,40(s1)
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	aea080e7          	jalr	-1302(ra) # 80001afc <myproc>
    8000501a:	5904                	lw	s1,48(a0)
    8000501c:	413484b3          	sub	s1,s1,s3
    80005020:	0014b493          	seqz	s1,s1
    80005024:	bfc1                	j	80004ff4 <holdingsleep+0x24>

0000000080005026 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005026:	1141                	addi	sp,sp,-16
    80005028:	e406                	sd	ra,8(sp)
    8000502a:	e022                	sd	s0,0(sp)
    8000502c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000502e:	00004597          	auipc	a1,0x4
    80005032:	91258593          	addi	a1,a1,-1774 # 80008940 <syscall_list+0x250>
    80005036:	0023f517          	auipc	a0,0x23f
    8000503a:	78250513          	addi	a0,a0,1922 # 802447b8 <ftable>
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c3e080e7          	jalr	-962(ra) # 80000c7c <initlock>
}
    80005046:	60a2                	ld	ra,8(sp)
    80005048:	6402                	ld	s0,0(sp)
    8000504a:	0141                	addi	sp,sp,16
    8000504c:	8082                	ret

000000008000504e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000504e:	1101                	addi	sp,sp,-32
    80005050:	ec06                	sd	ra,24(sp)
    80005052:	e822                	sd	s0,16(sp)
    80005054:	e426                	sd	s1,8(sp)
    80005056:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005058:	0023f517          	auipc	a0,0x23f
    8000505c:	76050513          	addi	a0,a0,1888 # 802447b8 <ftable>
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	cac080e7          	jalr	-852(ra) # 80000d0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005068:	0023f497          	auipc	s1,0x23f
    8000506c:	76848493          	addi	s1,s1,1896 # 802447d0 <ftable+0x18>
    80005070:	00240717          	auipc	a4,0x240
    80005074:	70070713          	addi	a4,a4,1792 # 80245770 <disk>
    if(f->ref == 0){
    80005078:	40dc                	lw	a5,4(s1)
    8000507a:	cf99                	beqz	a5,80005098 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000507c:	02848493          	addi	s1,s1,40
    80005080:	fee49ce3          	bne	s1,a4,80005078 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005084:	0023f517          	auipc	a0,0x23f
    80005088:	73450513          	addi	a0,a0,1844 # 802447b8 <ftable>
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	d34080e7          	jalr	-716(ra) # 80000dc0 <release>
  return 0;
    80005094:	4481                	li	s1,0
    80005096:	a819                	j	800050ac <filealloc+0x5e>
      f->ref = 1;
    80005098:	4785                	li	a5,1
    8000509a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000509c:	0023f517          	auipc	a0,0x23f
    800050a0:	71c50513          	addi	a0,a0,1820 # 802447b8 <ftable>
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	d1c080e7          	jalr	-740(ra) # 80000dc0 <release>
}
    800050ac:	8526                	mv	a0,s1
    800050ae:	60e2                	ld	ra,24(sp)
    800050b0:	6442                	ld	s0,16(sp)
    800050b2:	64a2                	ld	s1,8(sp)
    800050b4:	6105                	addi	sp,sp,32
    800050b6:	8082                	ret

00000000800050b8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050b8:	1101                	addi	sp,sp,-32
    800050ba:	ec06                	sd	ra,24(sp)
    800050bc:	e822                	sd	s0,16(sp)
    800050be:	e426                	sd	s1,8(sp)
    800050c0:	1000                	addi	s0,sp,32
    800050c2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800050c4:	0023f517          	auipc	a0,0x23f
    800050c8:	6f450513          	addi	a0,a0,1780 # 802447b8 <ftable>
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	c40080e7          	jalr	-960(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    800050d4:	40dc                	lw	a5,4(s1)
    800050d6:	02f05263          	blez	a5,800050fa <filedup+0x42>
    panic("filedup");
  f->ref++;
    800050da:	2785                	addiw	a5,a5,1
    800050dc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800050de:	0023f517          	auipc	a0,0x23f
    800050e2:	6da50513          	addi	a0,a0,1754 # 802447b8 <ftable>
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	cda080e7          	jalr	-806(ra) # 80000dc0 <release>
  return f;
}
    800050ee:	8526                	mv	a0,s1
    800050f0:	60e2                	ld	ra,24(sp)
    800050f2:	6442                	ld	s0,16(sp)
    800050f4:	64a2                	ld	s1,8(sp)
    800050f6:	6105                	addi	sp,sp,32
    800050f8:	8082                	ret
    panic("filedup");
    800050fa:	00004517          	auipc	a0,0x4
    800050fe:	84e50513          	addi	a0,a0,-1970 # 80008948 <syscall_list+0x258>
    80005102:	ffffb097          	auipc	ra,0xffffb
    80005106:	43e080e7          	jalr	1086(ra) # 80000540 <panic>

000000008000510a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000510a:	7139                	addi	sp,sp,-64
    8000510c:	fc06                	sd	ra,56(sp)
    8000510e:	f822                	sd	s0,48(sp)
    80005110:	f426                	sd	s1,40(sp)
    80005112:	f04a                	sd	s2,32(sp)
    80005114:	ec4e                	sd	s3,24(sp)
    80005116:	e852                	sd	s4,16(sp)
    80005118:	e456                	sd	s5,8(sp)
    8000511a:	0080                	addi	s0,sp,64
    8000511c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000511e:	0023f517          	auipc	a0,0x23f
    80005122:	69a50513          	addi	a0,a0,1690 # 802447b8 <ftable>
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	be6080e7          	jalr	-1050(ra) # 80000d0c <acquire>
  if(f->ref < 1)
    8000512e:	40dc                	lw	a5,4(s1)
    80005130:	06f05163          	blez	a5,80005192 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005134:	37fd                	addiw	a5,a5,-1
    80005136:	0007871b          	sext.w	a4,a5
    8000513a:	c0dc                	sw	a5,4(s1)
    8000513c:	06e04363          	bgtz	a4,800051a2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005140:	0004a903          	lw	s2,0(s1)
    80005144:	0094ca83          	lbu	s5,9(s1)
    80005148:	0104ba03          	ld	s4,16(s1)
    8000514c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005150:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005154:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005158:	0023f517          	auipc	a0,0x23f
    8000515c:	66050513          	addi	a0,a0,1632 # 802447b8 <ftable>
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	c60080e7          	jalr	-928(ra) # 80000dc0 <release>

  if(ff.type == FD_PIPE){
    80005168:	4785                	li	a5,1
    8000516a:	04f90d63          	beq	s2,a5,800051c4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000516e:	3979                	addiw	s2,s2,-2
    80005170:	4785                	li	a5,1
    80005172:	0527e063          	bltu	a5,s2,800051b2 <fileclose+0xa8>
    begin_op();
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	acc080e7          	jalr	-1332(ra) # 80004c42 <begin_op>
    iput(ff.ip);
    8000517e:	854e                	mv	a0,s3
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	2b0080e7          	jalr	688(ra) # 80004430 <iput>
    end_op();
    80005188:	00000097          	auipc	ra,0x0
    8000518c:	b38080e7          	jalr	-1224(ra) # 80004cc0 <end_op>
    80005190:	a00d                	j	800051b2 <fileclose+0xa8>
    panic("fileclose");
    80005192:	00003517          	auipc	a0,0x3
    80005196:	7be50513          	addi	a0,a0,1982 # 80008950 <syscall_list+0x260>
    8000519a:	ffffb097          	auipc	ra,0xffffb
    8000519e:	3a6080e7          	jalr	934(ra) # 80000540 <panic>
    release(&ftable.lock);
    800051a2:	0023f517          	auipc	a0,0x23f
    800051a6:	61650513          	addi	a0,a0,1558 # 802447b8 <ftable>
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	c16080e7          	jalr	-1002(ra) # 80000dc0 <release>
  }
}
    800051b2:	70e2                	ld	ra,56(sp)
    800051b4:	7442                	ld	s0,48(sp)
    800051b6:	74a2                	ld	s1,40(sp)
    800051b8:	7902                	ld	s2,32(sp)
    800051ba:	69e2                	ld	s3,24(sp)
    800051bc:	6a42                	ld	s4,16(sp)
    800051be:	6aa2                	ld	s5,8(sp)
    800051c0:	6121                	addi	sp,sp,64
    800051c2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800051c4:	85d6                	mv	a1,s5
    800051c6:	8552                	mv	a0,s4
    800051c8:	00000097          	auipc	ra,0x0
    800051cc:	34c080e7          	jalr	844(ra) # 80005514 <pipeclose>
    800051d0:	b7cd                	j	800051b2 <fileclose+0xa8>

00000000800051d2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800051d2:	715d                	addi	sp,sp,-80
    800051d4:	e486                	sd	ra,72(sp)
    800051d6:	e0a2                	sd	s0,64(sp)
    800051d8:	fc26                	sd	s1,56(sp)
    800051da:	f84a                	sd	s2,48(sp)
    800051dc:	f44e                	sd	s3,40(sp)
    800051de:	0880                	addi	s0,sp,80
    800051e0:	84aa                	mv	s1,a0
    800051e2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	918080e7          	jalr	-1768(ra) # 80001afc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800051ec:	409c                	lw	a5,0(s1)
    800051ee:	37f9                	addiw	a5,a5,-2
    800051f0:	4705                	li	a4,1
    800051f2:	04f76763          	bltu	a4,a5,80005240 <filestat+0x6e>
    800051f6:	892a                	mv	s2,a0
    ilock(f->ip);
    800051f8:	6c88                	ld	a0,24(s1)
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	07c080e7          	jalr	124(ra) # 80004276 <ilock>
    stati(f->ip, &st);
    80005202:	fb840593          	addi	a1,s0,-72
    80005206:	6c88                	ld	a0,24(s1)
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	2f8080e7          	jalr	760(ra) # 80004500 <stati>
    iunlock(f->ip);
    80005210:	6c88                	ld	a0,24(s1)
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	126080e7          	jalr	294(ra) # 80004338 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000521a:	46e1                	li	a3,24
    8000521c:	fb840613          	addi	a2,s0,-72
    80005220:	85ce                	mv	a1,s3
    80005222:	06093503          	ld	a0,96(s2)
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	562080e7          	jalr	1378(ra) # 80001788 <copyout>
    8000522e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005232:	60a6                	ld	ra,72(sp)
    80005234:	6406                	ld	s0,64(sp)
    80005236:	74e2                	ld	s1,56(sp)
    80005238:	7942                	ld	s2,48(sp)
    8000523a:	79a2                	ld	s3,40(sp)
    8000523c:	6161                	addi	sp,sp,80
    8000523e:	8082                	ret
  return -1;
    80005240:	557d                	li	a0,-1
    80005242:	bfc5                	j	80005232 <filestat+0x60>

0000000080005244 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005244:	7179                	addi	sp,sp,-48
    80005246:	f406                	sd	ra,40(sp)
    80005248:	f022                	sd	s0,32(sp)
    8000524a:	ec26                	sd	s1,24(sp)
    8000524c:	e84a                	sd	s2,16(sp)
    8000524e:	e44e                	sd	s3,8(sp)
    80005250:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005252:	00854783          	lbu	a5,8(a0)
    80005256:	c3d5                	beqz	a5,800052fa <fileread+0xb6>
    80005258:	84aa                	mv	s1,a0
    8000525a:	89ae                	mv	s3,a1
    8000525c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000525e:	411c                	lw	a5,0(a0)
    80005260:	4705                	li	a4,1
    80005262:	04e78963          	beq	a5,a4,800052b4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005266:	470d                	li	a4,3
    80005268:	04e78d63          	beq	a5,a4,800052c2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000526c:	4709                	li	a4,2
    8000526e:	06e79e63          	bne	a5,a4,800052ea <fileread+0xa6>
    ilock(f->ip);
    80005272:	6d08                	ld	a0,24(a0)
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	002080e7          	jalr	2(ra) # 80004276 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000527c:	874a                	mv	a4,s2
    8000527e:	5094                	lw	a3,32(s1)
    80005280:	864e                	mv	a2,s3
    80005282:	4585                	li	a1,1
    80005284:	6c88                	ld	a0,24(s1)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	2a4080e7          	jalr	676(ra) # 8000452a <readi>
    8000528e:	892a                	mv	s2,a0
    80005290:	00a05563          	blez	a0,8000529a <fileread+0x56>
      f->off += r;
    80005294:	509c                	lw	a5,32(s1)
    80005296:	9fa9                	addw	a5,a5,a0
    80005298:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000529a:	6c88                	ld	a0,24(s1)
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	09c080e7          	jalr	156(ra) # 80004338 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052a4:	854a                	mv	a0,s2
    800052a6:	70a2                	ld	ra,40(sp)
    800052a8:	7402                	ld	s0,32(sp)
    800052aa:	64e2                	ld	s1,24(sp)
    800052ac:	6942                	ld	s2,16(sp)
    800052ae:	69a2                	ld	s3,8(sp)
    800052b0:	6145                	addi	sp,sp,48
    800052b2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052b4:	6908                	ld	a0,16(a0)
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	3c6080e7          	jalr	966(ra) # 8000567c <piperead>
    800052be:	892a                	mv	s2,a0
    800052c0:	b7d5                	j	800052a4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052c2:	02451783          	lh	a5,36(a0)
    800052c6:	03079693          	slli	a3,a5,0x30
    800052ca:	92c1                	srli	a3,a3,0x30
    800052cc:	4725                	li	a4,9
    800052ce:	02d76863          	bltu	a4,a3,800052fe <fileread+0xba>
    800052d2:	0792                	slli	a5,a5,0x4
    800052d4:	0023f717          	auipc	a4,0x23f
    800052d8:	44470713          	addi	a4,a4,1092 # 80244718 <devsw>
    800052dc:	97ba                	add	a5,a5,a4
    800052de:	639c                	ld	a5,0(a5)
    800052e0:	c38d                	beqz	a5,80005302 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052e2:	4505                	li	a0,1
    800052e4:	9782                	jalr	a5
    800052e6:	892a                	mv	s2,a0
    800052e8:	bf75                	j	800052a4 <fileread+0x60>
    panic("fileread");
    800052ea:	00003517          	auipc	a0,0x3
    800052ee:	67650513          	addi	a0,a0,1654 # 80008960 <syscall_list+0x270>
    800052f2:	ffffb097          	auipc	ra,0xffffb
    800052f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>
    return -1;
    800052fa:	597d                	li	s2,-1
    800052fc:	b765                	j	800052a4 <fileread+0x60>
      return -1;
    800052fe:	597d                	li	s2,-1
    80005300:	b755                	j	800052a4 <fileread+0x60>
    80005302:	597d                	li	s2,-1
    80005304:	b745                	j	800052a4 <fileread+0x60>

0000000080005306 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005306:	715d                	addi	sp,sp,-80
    80005308:	e486                	sd	ra,72(sp)
    8000530a:	e0a2                	sd	s0,64(sp)
    8000530c:	fc26                	sd	s1,56(sp)
    8000530e:	f84a                	sd	s2,48(sp)
    80005310:	f44e                	sd	s3,40(sp)
    80005312:	f052                	sd	s4,32(sp)
    80005314:	ec56                	sd	s5,24(sp)
    80005316:	e85a                	sd	s6,16(sp)
    80005318:	e45e                	sd	s7,8(sp)
    8000531a:	e062                	sd	s8,0(sp)
    8000531c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000531e:	00954783          	lbu	a5,9(a0)
    80005322:	10078663          	beqz	a5,8000542e <filewrite+0x128>
    80005326:	892a                	mv	s2,a0
    80005328:	8b2e                	mv	s6,a1
    8000532a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000532c:	411c                	lw	a5,0(a0)
    8000532e:	4705                	li	a4,1
    80005330:	02e78263          	beq	a5,a4,80005354 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005334:	470d                	li	a4,3
    80005336:	02e78663          	beq	a5,a4,80005362 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000533a:	4709                	li	a4,2
    8000533c:	0ee79163          	bne	a5,a4,8000541e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005340:	0ac05d63          	blez	a2,800053fa <filewrite+0xf4>
    int i = 0;
    80005344:	4981                	li	s3,0
    80005346:	6b85                	lui	s7,0x1
    80005348:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000534c:	6c05                	lui	s8,0x1
    8000534e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005352:	a861                	j	800053ea <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005354:	6908                	ld	a0,16(a0)
    80005356:	00000097          	auipc	ra,0x0
    8000535a:	22e080e7          	jalr	558(ra) # 80005584 <pipewrite>
    8000535e:	8a2a                	mv	s4,a0
    80005360:	a045                	j	80005400 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005362:	02451783          	lh	a5,36(a0)
    80005366:	03079693          	slli	a3,a5,0x30
    8000536a:	92c1                	srli	a3,a3,0x30
    8000536c:	4725                	li	a4,9
    8000536e:	0cd76263          	bltu	a4,a3,80005432 <filewrite+0x12c>
    80005372:	0792                	slli	a5,a5,0x4
    80005374:	0023f717          	auipc	a4,0x23f
    80005378:	3a470713          	addi	a4,a4,932 # 80244718 <devsw>
    8000537c:	97ba                	add	a5,a5,a4
    8000537e:	679c                	ld	a5,8(a5)
    80005380:	cbdd                	beqz	a5,80005436 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005382:	4505                	li	a0,1
    80005384:	9782                	jalr	a5
    80005386:	8a2a                	mv	s4,a0
    80005388:	a8a5                	j	80005400 <filewrite+0xfa>
    8000538a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	8b4080e7          	jalr	-1868(ra) # 80004c42 <begin_op>
      ilock(f->ip);
    80005396:	01893503          	ld	a0,24(s2)
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	edc080e7          	jalr	-292(ra) # 80004276 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053a2:	8756                	mv	a4,s5
    800053a4:	02092683          	lw	a3,32(s2)
    800053a8:	01698633          	add	a2,s3,s6
    800053ac:	4585                	li	a1,1
    800053ae:	01893503          	ld	a0,24(s2)
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	270080e7          	jalr	624(ra) # 80004622 <writei>
    800053ba:	84aa                	mv	s1,a0
    800053bc:	00a05763          	blez	a0,800053ca <filewrite+0xc4>
        f->off += r;
    800053c0:	02092783          	lw	a5,32(s2)
    800053c4:	9fa9                	addw	a5,a5,a0
    800053c6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800053ca:	01893503          	ld	a0,24(s2)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	f6a080e7          	jalr	-150(ra) # 80004338 <iunlock>
      end_op();
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	8ea080e7          	jalr	-1814(ra) # 80004cc0 <end_op>

      if(r != n1){
    800053de:	009a9f63          	bne	s5,s1,800053fc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800053e2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800053e6:	0149db63          	bge	s3,s4,800053fc <filewrite+0xf6>
      int n1 = n - i;
    800053ea:	413a04bb          	subw	s1,s4,s3
    800053ee:	0004879b          	sext.w	a5,s1
    800053f2:	f8fbdce3          	bge	s7,a5,8000538a <filewrite+0x84>
    800053f6:	84e2                	mv	s1,s8
    800053f8:	bf49                	j	8000538a <filewrite+0x84>
    int i = 0;
    800053fa:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053fc:	013a1f63          	bne	s4,s3,8000541a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005400:	8552                	mv	a0,s4
    80005402:	60a6                	ld	ra,72(sp)
    80005404:	6406                	ld	s0,64(sp)
    80005406:	74e2                	ld	s1,56(sp)
    80005408:	7942                	ld	s2,48(sp)
    8000540a:	79a2                	ld	s3,40(sp)
    8000540c:	7a02                	ld	s4,32(sp)
    8000540e:	6ae2                	ld	s5,24(sp)
    80005410:	6b42                	ld	s6,16(sp)
    80005412:	6ba2                	ld	s7,8(sp)
    80005414:	6c02                	ld	s8,0(sp)
    80005416:	6161                	addi	sp,sp,80
    80005418:	8082                	ret
    ret = (i == n ? n : -1);
    8000541a:	5a7d                	li	s4,-1
    8000541c:	b7d5                	j	80005400 <filewrite+0xfa>
    panic("filewrite");
    8000541e:	00003517          	auipc	a0,0x3
    80005422:	55250513          	addi	a0,a0,1362 # 80008970 <syscall_list+0x280>
    80005426:	ffffb097          	auipc	ra,0xffffb
    8000542a:	11a080e7          	jalr	282(ra) # 80000540 <panic>
    return -1;
    8000542e:	5a7d                	li	s4,-1
    80005430:	bfc1                	j	80005400 <filewrite+0xfa>
      return -1;
    80005432:	5a7d                	li	s4,-1
    80005434:	b7f1                	j	80005400 <filewrite+0xfa>
    80005436:	5a7d                	li	s4,-1
    80005438:	b7e1                	j	80005400 <filewrite+0xfa>

000000008000543a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000543a:	7179                	addi	sp,sp,-48
    8000543c:	f406                	sd	ra,40(sp)
    8000543e:	f022                	sd	s0,32(sp)
    80005440:	ec26                	sd	s1,24(sp)
    80005442:	e84a                	sd	s2,16(sp)
    80005444:	e44e                	sd	s3,8(sp)
    80005446:	e052                	sd	s4,0(sp)
    80005448:	1800                	addi	s0,sp,48
    8000544a:	84aa                	mv	s1,a0
    8000544c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000544e:	0005b023          	sd	zero,0(a1)
    80005452:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005456:	00000097          	auipc	ra,0x0
    8000545a:	bf8080e7          	jalr	-1032(ra) # 8000504e <filealloc>
    8000545e:	e088                	sd	a0,0(s1)
    80005460:	c551                	beqz	a0,800054ec <pipealloc+0xb2>
    80005462:	00000097          	auipc	ra,0x0
    80005466:	bec080e7          	jalr	-1044(ra) # 8000504e <filealloc>
    8000546a:	00aa3023          	sd	a0,0(s4)
    8000546e:	c92d                	beqz	a0,800054e0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005470:	ffffb097          	auipc	ra,0xffffb
    80005474:	774080e7          	jalr	1908(ra) # 80000be4 <kalloc>
    80005478:	892a                	mv	s2,a0
    8000547a:	c125                	beqz	a0,800054da <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000547c:	4985                	li	s3,1
    8000547e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005482:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005486:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000548a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000548e:	00003597          	auipc	a1,0x3
    80005492:	08258593          	addi	a1,a1,130 # 80008510 <states.0+0x210>
    80005496:	ffffb097          	auipc	ra,0xffffb
    8000549a:	7e6080e7          	jalr	2022(ra) # 80000c7c <initlock>
  (*f0)->type = FD_PIPE;
    8000549e:	609c                	ld	a5,0(s1)
    800054a0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054a4:	609c                	ld	a5,0(s1)
    800054a6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054aa:	609c                	ld	a5,0(s1)
    800054ac:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054b0:	609c                	ld	a5,0(s1)
    800054b2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054b6:	000a3783          	ld	a5,0(s4)
    800054ba:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800054be:	000a3783          	ld	a5,0(s4)
    800054c2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800054c6:	000a3783          	ld	a5,0(s4)
    800054ca:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800054ce:	000a3783          	ld	a5,0(s4)
    800054d2:	0127b823          	sd	s2,16(a5)
  return 0;
    800054d6:	4501                	li	a0,0
    800054d8:	a025                	j	80005500 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800054da:	6088                	ld	a0,0(s1)
    800054dc:	e501                	bnez	a0,800054e4 <pipealloc+0xaa>
    800054de:	a039                	j	800054ec <pipealloc+0xb2>
    800054e0:	6088                	ld	a0,0(s1)
    800054e2:	c51d                	beqz	a0,80005510 <pipealloc+0xd6>
    fileclose(*f0);
    800054e4:	00000097          	auipc	ra,0x0
    800054e8:	c26080e7          	jalr	-986(ra) # 8000510a <fileclose>
  if(*f1)
    800054ec:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800054f0:	557d                	li	a0,-1
  if(*f1)
    800054f2:	c799                	beqz	a5,80005500 <pipealloc+0xc6>
    fileclose(*f1);
    800054f4:	853e                	mv	a0,a5
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	c14080e7          	jalr	-1004(ra) # 8000510a <fileclose>
  return -1;
    800054fe:	557d                	li	a0,-1
}
    80005500:	70a2                	ld	ra,40(sp)
    80005502:	7402                	ld	s0,32(sp)
    80005504:	64e2                	ld	s1,24(sp)
    80005506:	6942                	ld	s2,16(sp)
    80005508:	69a2                	ld	s3,8(sp)
    8000550a:	6a02                	ld	s4,0(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret
  return -1;
    80005510:	557d                	li	a0,-1
    80005512:	b7fd                	j	80005500 <pipealloc+0xc6>

0000000080005514 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005514:	1101                	addi	sp,sp,-32
    80005516:	ec06                	sd	ra,24(sp)
    80005518:	e822                	sd	s0,16(sp)
    8000551a:	e426                	sd	s1,8(sp)
    8000551c:	e04a                	sd	s2,0(sp)
    8000551e:	1000                	addi	s0,sp,32
    80005520:	84aa                	mv	s1,a0
    80005522:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005524:	ffffb097          	auipc	ra,0xffffb
    80005528:	7e8080e7          	jalr	2024(ra) # 80000d0c <acquire>
  if(writable){
    8000552c:	02090d63          	beqz	s2,80005566 <pipeclose+0x52>
    pi->writeopen = 0;
    80005530:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005534:	21848513          	addi	a0,s1,536
    80005538:	ffffd097          	auipc	ra,0xffffd
    8000553c:	04c080e7          	jalr	76(ra) # 80002584 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005540:	2204b783          	ld	a5,544(s1)
    80005544:	eb95                	bnez	a5,80005578 <pipeclose+0x64>
    release(&pi->lock);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffc097          	auipc	ra,0xffffc
    8000554c:	878080e7          	jalr	-1928(ra) # 80000dc0 <release>
    kfree((char*)pi);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	50e080e7          	jalr	1294(ra) # 80000a60 <kfree>
  } else
    release(&pi->lock);
}
    8000555a:	60e2                	ld	ra,24(sp)
    8000555c:	6442                	ld	s0,16(sp)
    8000555e:	64a2                	ld	s1,8(sp)
    80005560:	6902                	ld	s2,0(sp)
    80005562:	6105                	addi	sp,sp,32
    80005564:	8082                	ret
    pi->readopen = 0;
    80005566:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000556a:	21c48513          	addi	a0,s1,540
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	016080e7          	jalr	22(ra) # 80002584 <wakeup>
    80005576:	b7e9                	j	80005540 <pipeclose+0x2c>
    release(&pi->lock);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	846080e7          	jalr	-1978(ra) # 80000dc0 <release>
}
    80005582:	bfe1                	j	8000555a <pipeclose+0x46>

0000000080005584 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005584:	711d                	addi	sp,sp,-96
    80005586:	ec86                	sd	ra,88(sp)
    80005588:	e8a2                	sd	s0,80(sp)
    8000558a:	e4a6                	sd	s1,72(sp)
    8000558c:	e0ca                	sd	s2,64(sp)
    8000558e:	fc4e                	sd	s3,56(sp)
    80005590:	f852                	sd	s4,48(sp)
    80005592:	f456                	sd	s5,40(sp)
    80005594:	f05a                	sd	s6,32(sp)
    80005596:	ec5e                	sd	s7,24(sp)
    80005598:	e862                	sd	s8,16(sp)
    8000559a:	1080                	addi	s0,sp,96
    8000559c:	84aa                	mv	s1,a0
    8000559e:	8aae                	mv	s5,a1
    800055a0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	55a080e7          	jalr	1370(ra) # 80001afc <myproc>
    800055aa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffb097          	auipc	ra,0xffffb
    800055b2:	75e080e7          	jalr	1886(ra) # 80000d0c <acquire>
  while(i < n){
    800055b6:	0b405663          	blez	s4,80005662 <pipewrite+0xde>
  int i = 0;
    800055ba:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055bc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800055be:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800055c2:	21c48b93          	addi	s7,s1,540
    800055c6:	a089                	j	80005608 <pipewrite+0x84>
      release(&pi->lock);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	7f6080e7          	jalr	2038(ra) # 80000dc0 <release>
      return -1;
    800055d2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800055d4:	854a                	mv	a0,s2
    800055d6:	60e6                	ld	ra,88(sp)
    800055d8:	6446                	ld	s0,80(sp)
    800055da:	64a6                	ld	s1,72(sp)
    800055dc:	6906                	ld	s2,64(sp)
    800055de:	79e2                	ld	s3,56(sp)
    800055e0:	7a42                	ld	s4,48(sp)
    800055e2:	7aa2                	ld	s5,40(sp)
    800055e4:	7b02                	ld	s6,32(sp)
    800055e6:	6be2                	ld	s7,24(sp)
    800055e8:	6c42                	ld	s8,16(sp)
    800055ea:	6125                	addi	sp,sp,96
    800055ec:	8082                	ret
      wakeup(&pi->nread);
    800055ee:	8562                	mv	a0,s8
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	f94080e7          	jalr	-108(ra) # 80002584 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800055f8:	85a6                	mv	a1,s1
    800055fa:	855e                	mv	a0,s7
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	f24080e7          	jalr	-220(ra) # 80002520 <sleep>
  while(i < n){
    80005604:	07495063          	bge	s2,s4,80005664 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005608:	2204a783          	lw	a5,544(s1)
    8000560c:	dfd5                	beqz	a5,800055c8 <pipewrite+0x44>
    8000560e:	854e                	mv	a0,s3
    80005610:	ffffd097          	auipc	ra,0xffffd
    80005614:	1b8080e7          	jalr	440(ra) # 800027c8 <killed>
    80005618:	f945                	bnez	a0,800055c8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000561a:	2184a783          	lw	a5,536(s1)
    8000561e:	21c4a703          	lw	a4,540(s1)
    80005622:	2007879b          	addiw	a5,a5,512
    80005626:	fcf704e3          	beq	a4,a5,800055ee <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000562a:	4685                	li	a3,1
    8000562c:	01590633          	add	a2,s2,s5
    80005630:	faf40593          	addi	a1,s0,-81
    80005634:	0609b503          	ld	a0,96(s3)
    80005638:	ffffc097          	auipc	ra,0xffffc
    8000563c:	210080e7          	jalr	528(ra) # 80001848 <copyin>
    80005640:	03650263          	beq	a0,s6,80005664 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005644:	21c4a783          	lw	a5,540(s1)
    80005648:	0017871b          	addiw	a4,a5,1
    8000564c:	20e4ae23          	sw	a4,540(s1)
    80005650:	1ff7f793          	andi	a5,a5,511
    80005654:	97a6                	add	a5,a5,s1
    80005656:	faf44703          	lbu	a4,-81(s0)
    8000565a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000565e:	2905                	addiw	s2,s2,1
    80005660:	b755                	j	80005604 <pipewrite+0x80>
  int i = 0;
    80005662:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005664:	21848513          	addi	a0,s1,536
    80005668:	ffffd097          	auipc	ra,0xffffd
    8000566c:	f1c080e7          	jalr	-228(ra) # 80002584 <wakeup>
  release(&pi->lock);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffb097          	auipc	ra,0xffffb
    80005676:	74e080e7          	jalr	1870(ra) # 80000dc0 <release>
  return i;
    8000567a:	bfa9                	j	800055d4 <pipewrite+0x50>

000000008000567c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000567c:	715d                	addi	sp,sp,-80
    8000567e:	e486                	sd	ra,72(sp)
    80005680:	e0a2                	sd	s0,64(sp)
    80005682:	fc26                	sd	s1,56(sp)
    80005684:	f84a                	sd	s2,48(sp)
    80005686:	f44e                	sd	s3,40(sp)
    80005688:	f052                	sd	s4,32(sp)
    8000568a:	ec56                	sd	s5,24(sp)
    8000568c:	e85a                	sd	s6,16(sp)
    8000568e:	0880                	addi	s0,sp,80
    80005690:	84aa                	mv	s1,a0
    80005692:	892e                	mv	s2,a1
    80005694:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	466080e7          	jalr	1126(ra) # 80001afc <myproc>
    8000569e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	66a080e7          	jalr	1642(ra) # 80000d0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056aa:	2184a703          	lw	a4,536(s1)
    800056ae:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056b2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056b6:	02f71763          	bne	a4,a5,800056e4 <piperead+0x68>
    800056ba:	2244a783          	lw	a5,548(s1)
    800056be:	c39d                	beqz	a5,800056e4 <piperead+0x68>
    if(killed(pr)){
    800056c0:	8552                	mv	a0,s4
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	106080e7          	jalr	262(ra) # 800027c8 <killed>
    800056ca:	e949                	bnez	a0,8000575c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056cc:	85a6                	mv	a1,s1
    800056ce:	854e                	mv	a0,s3
    800056d0:	ffffd097          	auipc	ra,0xffffd
    800056d4:	e50080e7          	jalr	-432(ra) # 80002520 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056d8:	2184a703          	lw	a4,536(s1)
    800056dc:	21c4a783          	lw	a5,540(s1)
    800056e0:	fcf70de3          	beq	a4,a5,800056ba <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056e4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056e6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056e8:	05505463          	blez	s5,80005730 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800056ec:	2184a783          	lw	a5,536(s1)
    800056f0:	21c4a703          	lw	a4,540(s1)
    800056f4:	02f70e63          	beq	a4,a5,80005730 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800056f8:	0017871b          	addiw	a4,a5,1
    800056fc:	20e4ac23          	sw	a4,536(s1)
    80005700:	1ff7f793          	andi	a5,a5,511
    80005704:	97a6                	add	a5,a5,s1
    80005706:	0187c783          	lbu	a5,24(a5)
    8000570a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000570e:	4685                	li	a3,1
    80005710:	fbf40613          	addi	a2,s0,-65
    80005714:	85ca                	mv	a1,s2
    80005716:	060a3503          	ld	a0,96(s4)
    8000571a:	ffffc097          	auipc	ra,0xffffc
    8000571e:	06e080e7          	jalr	110(ra) # 80001788 <copyout>
    80005722:	01650763          	beq	a0,s6,80005730 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005726:	2985                	addiw	s3,s3,1
    80005728:	0905                	addi	s2,s2,1
    8000572a:	fd3a91e3          	bne	s5,s3,800056ec <piperead+0x70>
    8000572e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005730:	21c48513          	addi	a0,s1,540
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	e50080e7          	jalr	-432(ra) # 80002584 <wakeup>
  release(&pi->lock);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	682080e7          	jalr	1666(ra) # 80000dc0 <release>
  return i;
}
    80005746:	854e                	mv	a0,s3
    80005748:	60a6                	ld	ra,72(sp)
    8000574a:	6406                	ld	s0,64(sp)
    8000574c:	74e2                	ld	s1,56(sp)
    8000574e:	7942                	ld	s2,48(sp)
    80005750:	79a2                	ld	s3,40(sp)
    80005752:	7a02                	ld	s4,32(sp)
    80005754:	6ae2                	ld	s5,24(sp)
    80005756:	6b42                	ld	s6,16(sp)
    80005758:	6161                	addi	sp,sp,80
    8000575a:	8082                	ret
      release(&pi->lock);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffb097          	auipc	ra,0xffffb
    80005762:	662080e7          	jalr	1634(ra) # 80000dc0 <release>
      return -1;
    80005766:	59fd                	li	s3,-1
    80005768:	bff9                	j	80005746 <piperead+0xca>

000000008000576a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000576a:	1141                	addi	sp,sp,-16
    8000576c:	e422                	sd	s0,8(sp)
    8000576e:	0800                	addi	s0,sp,16
    80005770:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005772:	8905                	andi	a0,a0,1
    80005774:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005776:	8b89                	andi	a5,a5,2
    80005778:	c399                	beqz	a5,8000577e <flags2perm+0x14>
      perm |= PTE_W;
    8000577a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000577e:	6422                	ld	s0,8(sp)
    80005780:	0141                	addi	sp,sp,16
    80005782:	8082                	ret

0000000080005784 <exec>:

int
exec(char *path, char **argv)
{
    80005784:	de010113          	addi	sp,sp,-544
    80005788:	20113c23          	sd	ra,536(sp)
    8000578c:	20813823          	sd	s0,528(sp)
    80005790:	20913423          	sd	s1,520(sp)
    80005794:	21213023          	sd	s2,512(sp)
    80005798:	ffce                	sd	s3,504(sp)
    8000579a:	fbd2                	sd	s4,496(sp)
    8000579c:	f7d6                	sd	s5,488(sp)
    8000579e:	f3da                	sd	s6,480(sp)
    800057a0:	efde                	sd	s7,472(sp)
    800057a2:	ebe2                	sd	s8,464(sp)
    800057a4:	e7e6                	sd	s9,456(sp)
    800057a6:	e3ea                	sd	s10,448(sp)
    800057a8:	ff6e                	sd	s11,440(sp)
    800057aa:	1400                	addi	s0,sp,544
    800057ac:	892a                	mv	s2,a0
    800057ae:	dea43423          	sd	a0,-536(s0)
    800057b2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057b6:	ffffc097          	auipc	ra,0xffffc
    800057ba:	346080e7          	jalr	838(ra) # 80001afc <myproc>
    800057be:	84aa                	mv	s1,a0

  begin_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	482080e7          	jalr	1154(ra) # 80004c42 <begin_op>

  if((ip = namei(path)) == 0){
    800057c8:	854a                	mv	a0,s2
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	258080e7          	jalr	600(ra) # 80004a22 <namei>
    800057d2:	c93d                	beqz	a0,80005848 <exec+0xc4>
    800057d4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	aa0080e7          	jalr	-1376(ra) # 80004276 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800057de:	04000713          	li	a4,64
    800057e2:	4681                	li	a3,0
    800057e4:	e5040613          	addi	a2,s0,-432
    800057e8:	4581                	li	a1,0
    800057ea:	8556                	mv	a0,s5
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	d3e080e7          	jalr	-706(ra) # 8000452a <readi>
    800057f4:	04000793          	li	a5,64
    800057f8:	00f51a63          	bne	a0,a5,8000580c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800057fc:	e5042703          	lw	a4,-432(s0)
    80005800:	464c47b7          	lui	a5,0x464c4
    80005804:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005808:	04f70663          	beq	a4,a5,80005854 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000580c:	8556                	mv	a0,s5
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	cca080e7          	jalr	-822(ra) # 800044d8 <iunlockput>
    end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	4aa080e7          	jalr	1194(ra) # 80004cc0 <end_op>
  }
  return -1;
    8000581e:	557d                	li	a0,-1
}
    80005820:	21813083          	ld	ra,536(sp)
    80005824:	21013403          	ld	s0,528(sp)
    80005828:	20813483          	ld	s1,520(sp)
    8000582c:	20013903          	ld	s2,512(sp)
    80005830:	79fe                	ld	s3,504(sp)
    80005832:	7a5e                	ld	s4,496(sp)
    80005834:	7abe                	ld	s5,488(sp)
    80005836:	7b1e                	ld	s6,480(sp)
    80005838:	6bfe                	ld	s7,472(sp)
    8000583a:	6c5e                	ld	s8,464(sp)
    8000583c:	6cbe                	ld	s9,456(sp)
    8000583e:	6d1e                	ld	s10,448(sp)
    80005840:	7dfa                	ld	s11,440(sp)
    80005842:	22010113          	addi	sp,sp,544
    80005846:	8082                	ret
    end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	478080e7          	jalr	1144(ra) # 80004cc0 <end_op>
    return -1;
    80005850:	557d                	li	a0,-1
    80005852:	b7f9                	j	80005820 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005854:	8526                	mv	a0,s1
    80005856:	ffffc097          	auipc	ra,0xffffc
    8000585a:	36a080e7          	jalr	874(ra) # 80001bc0 <proc_pagetable>
    8000585e:	8b2a                	mv	s6,a0
    80005860:	d555                	beqz	a0,8000580c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005862:	e7042783          	lw	a5,-400(s0)
    80005866:	e8845703          	lhu	a4,-376(s0)
    8000586a:	c735                	beqz	a4,800058d6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000586c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000586e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005872:	6a05                	lui	s4,0x1
    80005874:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005878:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000587c:	6d85                	lui	s11,0x1
    8000587e:	7d7d                	lui	s10,0xfffff
    80005880:	ac3d                	j	80005abe <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005882:	00003517          	auipc	a0,0x3
    80005886:	0fe50513          	addi	a0,a0,254 # 80008980 <syscall_list+0x290>
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	cb6080e7          	jalr	-842(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005892:	874a                	mv	a4,s2
    80005894:	009c86bb          	addw	a3,s9,s1
    80005898:	4581                	li	a1,0
    8000589a:	8556                	mv	a0,s5
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	c8e080e7          	jalr	-882(ra) # 8000452a <readi>
    800058a4:	2501                	sext.w	a0,a0
    800058a6:	1aa91963          	bne	s2,a0,80005a58 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800058aa:	009d84bb          	addw	s1,s11,s1
    800058ae:	013d09bb          	addw	s3,s10,s3
    800058b2:	1f74f663          	bgeu	s1,s7,80005a9e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800058b6:	02049593          	slli	a1,s1,0x20
    800058ba:	9181                	srli	a1,a1,0x20
    800058bc:	95e2                	add	a1,a1,s8
    800058be:	855a                	mv	a0,s6
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	8d2080e7          	jalr	-1838(ra) # 80001192 <walkaddr>
    800058c8:	862a                	mv	a2,a0
    if(pa == 0)
    800058ca:	dd45                	beqz	a0,80005882 <exec+0xfe>
      n = PGSIZE;
    800058cc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800058ce:	fd49f2e3          	bgeu	s3,s4,80005892 <exec+0x10e>
      n = sz - i;
    800058d2:	894e                	mv	s2,s3
    800058d4:	bf7d                	j	80005892 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058d6:	4901                	li	s2,0
  iunlockput(ip);
    800058d8:	8556                	mv	a0,s5
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	bfe080e7          	jalr	-1026(ra) # 800044d8 <iunlockput>
  end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	3de080e7          	jalr	990(ra) # 80004cc0 <end_op>
  p = myproc();
    800058ea:	ffffc097          	auipc	ra,0xffffc
    800058ee:	212080e7          	jalr	530(ra) # 80001afc <myproc>
    800058f2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800058f4:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    800058f8:	6785                	lui	a5,0x1
    800058fa:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800058fc:	97ca                	add	a5,a5,s2
    800058fe:	777d                	lui	a4,0xfffff
    80005900:	8ff9                	and	a5,a5,a4
    80005902:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005906:	4691                	li	a3,4
    80005908:	6609                	lui	a2,0x2
    8000590a:	963e                	add	a2,a2,a5
    8000590c:	85be                	mv	a1,a5
    8000590e:	855a                	mv	a0,s6
    80005910:	ffffc097          	auipc	ra,0xffffc
    80005914:	c36080e7          	jalr	-970(ra) # 80001546 <uvmalloc>
    80005918:	8c2a                	mv	s8,a0
  ip = 0;
    8000591a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000591c:	12050e63          	beqz	a0,80005a58 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005920:	75f9                	lui	a1,0xffffe
    80005922:	95aa                	add	a1,a1,a0
    80005924:	855a                	mv	a0,s6
    80005926:	ffffc097          	auipc	ra,0xffffc
    8000592a:	e30080e7          	jalr	-464(ra) # 80001756 <uvmclear>
  stackbase = sp - PGSIZE;
    8000592e:	7afd                	lui	s5,0xfffff
    80005930:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005932:	df043783          	ld	a5,-528(s0)
    80005936:	6388                	ld	a0,0(a5)
    80005938:	c925                	beqz	a0,800059a8 <exec+0x224>
    8000593a:	e9040993          	addi	s3,s0,-368
    8000593e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005942:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005944:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	63e080e7          	jalr	1598(ra) # 80000f84 <strlen>
    8000594e:	0015079b          	addiw	a5,a0,1
    80005952:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005956:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000595a:	13596663          	bltu	s2,s5,80005a86 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000595e:	df043d83          	ld	s11,-528(s0)
    80005962:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005966:	8552                	mv	a0,s4
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	61c080e7          	jalr	1564(ra) # 80000f84 <strlen>
    80005970:	0015069b          	addiw	a3,a0,1
    80005974:	8652                	mv	a2,s4
    80005976:	85ca                	mv	a1,s2
    80005978:	855a                	mv	a0,s6
    8000597a:	ffffc097          	auipc	ra,0xffffc
    8000597e:	e0e080e7          	jalr	-498(ra) # 80001788 <copyout>
    80005982:	10054663          	bltz	a0,80005a8e <exec+0x30a>
    ustack[argc] = sp;
    80005986:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000598a:	0485                	addi	s1,s1,1
    8000598c:	008d8793          	addi	a5,s11,8
    80005990:	def43823          	sd	a5,-528(s0)
    80005994:	008db503          	ld	a0,8(s11)
    80005998:	c911                	beqz	a0,800059ac <exec+0x228>
    if(argc >= MAXARG)
    8000599a:	09a1                	addi	s3,s3,8
    8000599c:	fb3c95e3          	bne	s9,s3,80005946 <exec+0x1c2>
  sz = sz1;
    800059a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059a4:	4a81                	li	s5,0
    800059a6:	a84d                	j	80005a58 <exec+0x2d4>
  sp = sz;
    800059a8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800059aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800059ac:	00349793          	slli	a5,s1,0x3
    800059b0:	f9078793          	addi	a5,a5,-112
    800059b4:	97a2                	add	a5,a5,s0
    800059b6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800059ba:	00148693          	addi	a3,s1,1
    800059be:	068e                	slli	a3,a3,0x3
    800059c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059c8:	01597663          	bgeu	s2,s5,800059d4 <exec+0x250>
  sz = sz1;
    800059cc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059d0:	4a81                	li	s5,0
    800059d2:	a059                	j	80005a58 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059d4:	e9040613          	addi	a2,s0,-368
    800059d8:	85ca                	mv	a1,s2
    800059da:	855a                	mv	a0,s6
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	dac080e7          	jalr	-596(ra) # 80001788 <copyout>
    800059e4:	0a054963          	bltz	a0,80005a96 <exec+0x312>
  p->trapframe->a1 = sp;
    800059e8:	068bb783          	ld	a5,104(s7)
    800059ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800059f0:	de843783          	ld	a5,-536(s0)
    800059f4:	0007c703          	lbu	a4,0(a5)
    800059f8:	cf11                	beqz	a4,80005a14 <exec+0x290>
    800059fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800059fc:	02f00693          	li	a3,47
    80005a00:	a039                	j	80005a0e <exec+0x28a>
      last = s+1;
    80005a02:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005a06:	0785                	addi	a5,a5,1
    80005a08:	fff7c703          	lbu	a4,-1(a5)
    80005a0c:	c701                	beqz	a4,80005a14 <exec+0x290>
    if(*s == '/')
    80005a0e:	fed71ce3          	bne	a4,a3,80005a06 <exec+0x282>
    80005a12:	bfc5                	j	80005a02 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a14:	4641                	li	a2,16
    80005a16:	de843583          	ld	a1,-536(s0)
    80005a1a:	168b8513          	addi	a0,s7,360
    80005a1e:	ffffb097          	auipc	ra,0xffffb
    80005a22:	534080e7          	jalr	1332(ra) # 80000f52 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a26:	060bb503          	ld	a0,96(s7)
  p->pagetable = pagetable;
    80005a2a:	076bb023          	sd	s6,96(s7)
  p->sz = sz;
    80005a2e:	058bbc23          	sd	s8,88(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a32:	068bb783          	ld	a5,104(s7)
    80005a36:	e6843703          	ld	a4,-408(s0)
    80005a3a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a3c:	068bb783          	ld	a5,104(s7)
    80005a40:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a44:	85ea                	mv	a1,s10
    80005a46:	ffffc097          	auipc	ra,0xffffc
    80005a4a:	216080e7          	jalr	534(ra) # 80001c5c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a4e:	0004851b          	sext.w	a0,s1
    80005a52:	b3f9                	j	80005820 <exec+0x9c>
    80005a54:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005a58:	df843583          	ld	a1,-520(s0)
    80005a5c:	855a                	mv	a0,s6
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	1fe080e7          	jalr	510(ra) # 80001c5c <proc_freepagetable>
  if(ip){
    80005a66:	da0a93e3          	bnez	s5,8000580c <exec+0x88>
  return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	bb55                	j	80005820 <exec+0x9c>
    80005a6e:	df243c23          	sd	s2,-520(s0)
    80005a72:	b7dd                	j	80005a58 <exec+0x2d4>
    80005a74:	df243c23          	sd	s2,-520(s0)
    80005a78:	b7c5                	j	80005a58 <exec+0x2d4>
    80005a7a:	df243c23          	sd	s2,-520(s0)
    80005a7e:	bfe9                	j	80005a58 <exec+0x2d4>
    80005a80:	df243c23          	sd	s2,-520(s0)
    80005a84:	bfd1                	j	80005a58 <exec+0x2d4>
  sz = sz1;
    80005a86:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a8a:	4a81                	li	s5,0
    80005a8c:	b7f1                	j	80005a58 <exec+0x2d4>
  sz = sz1;
    80005a8e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a92:	4a81                	li	s5,0
    80005a94:	b7d1                	j	80005a58 <exec+0x2d4>
  sz = sz1;
    80005a96:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a9a:	4a81                	li	s5,0
    80005a9c:	bf75                	j	80005a58 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a9e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aa2:	e0843783          	ld	a5,-504(s0)
    80005aa6:	0017869b          	addiw	a3,a5,1
    80005aaa:	e0d43423          	sd	a3,-504(s0)
    80005aae:	e0043783          	ld	a5,-512(s0)
    80005ab2:	0387879b          	addiw	a5,a5,56
    80005ab6:	e8845703          	lhu	a4,-376(s0)
    80005aba:	e0e6dfe3          	bge	a3,a4,800058d8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005abe:	2781                	sext.w	a5,a5
    80005ac0:	e0f43023          	sd	a5,-512(s0)
    80005ac4:	03800713          	li	a4,56
    80005ac8:	86be                	mv	a3,a5
    80005aca:	e1840613          	addi	a2,s0,-488
    80005ace:	4581                	li	a1,0
    80005ad0:	8556                	mv	a0,s5
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	a58080e7          	jalr	-1448(ra) # 8000452a <readi>
    80005ada:	03800793          	li	a5,56
    80005ade:	f6f51be3          	bne	a0,a5,80005a54 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005ae2:	e1842783          	lw	a5,-488(s0)
    80005ae6:	4705                	li	a4,1
    80005ae8:	fae79de3          	bne	a5,a4,80005aa2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005aec:	e4043483          	ld	s1,-448(s0)
    80005af0:	e3843783          	ld	a5,-456(s0)
    80005af4:	f6f4ede3          	bltu	s1,a5,80005a6e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005af8:	e2843783          	ld	a5,-472(s0)
    80005afc:	94be                	add	s1,s1,a5
    80005afe:	f6f4ebe3          	bltu	s1,a5,80005a74 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005b02:	de043703          	ld	a4,-544(s0)
    80005b06:	8ff9                	and	a5,a5,a4
    80005b08:	fbad                	bnez	a5,80005a7a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b0a:	e1c42503          	lw	a0,-484(s0)
    80005b0e:	00000097          	auipc	ra,0x0
    80005b12:	c5c080e7          	jalr	-932(ra) # 8000576a <flags2perm>
    80005b16:	86aa                	mv	a3,a0
    80005b18:	8626                	mv	a2,s1
    80005b1a:	85ca                	mv	a1,s2
    80005b1c:	855a                	mv	a0,s6
    80005b1e:	ffffc097          	auipc	ra,0xffffc
    80005b22:	a28080e7          	jalr	-1496(ra) # 80001546 <uvmalloc>
    80005b26:	dea43c23          	sd	a0,-520(s0)
    80005b2a:	d939                	beqz	a0,80005a80 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b2c:	e2843c03          	ld	s8,-472(s0)
    80005b30:	e2042c83          	lw	s9,-480(s0)
    80005b34:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b38:	f60b83e3          	beqz	s7,80005a9e <exec+0x31a>
    80005b3c:	89de                	mv	s3,s7
    80005b3e:	4481                	li	s1,0
    80005b40:	bb9d                	j	800058b6 <exec+0x132>

0000000080005b42 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b42:	7179                	addi	sp,sp,-48
    80005b44:	f406                	sd	ra,40(sp)
    80005b46:	f022                	sd	s0,32(sp)
    80005b48:	ec26                	sd	s1,24(sp)
    80005b4a:	e84a                	sd	s2,16(sp)
    80005b4c:	1800                	addi	s0,sp,48
    80005b4e:	892e                	mv	s2,a1
    80005b50:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005b52:	fdc40593          	addi	a1,s0,-36
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	a5a080e7          	jalr	-1446(ra) # 800035b0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b5e:	fdc42703          	lw	a4,-36(s0)
    80005b62:	47bd                	li	a5,15
    80005b64:	02e7eb63          	bltu	a5,a4,80005b9a <argfd+0x58>
    80005b68:	ffffc097          	auipc	ra,0xffffc
    80005b6c:	f94080e7          	jalr	-108(ra) # 80001afc <myproc>
    80005b70:	fdc42703          	lw	a4,-36(s0)
    80005b74:	01c70793          	addi	a5,a4,28 # fffffffffffff01c <end+0xffffffff7fdb976c>
    80005b78:	078e                	slli	a5,a5,0x3
    80005b7a:	953e                	add	a0,a0,a5
    80005b7c:	611c                	ld	a5,0(a0)
    80005b7e:	c385                	beqz	a5,80005b9e <argfd+0x5c>
    return -1;
  if(pfd)
    80005b80:	00090463          	beqz	s2,80005b88 <argfd+0x46>
    *pfd = fd;
    80005b84:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b88:	4501                	li	a0,0
  if(pf)
    80005b8a:	c091                	beqz	s1,80005b8e <argfd+0x4c>
    *pf = f;
    80005b8c:	e09c                	sd	a5,0(s1)
}
    80005b8e:	70a2                	ld	ra,40(sp)
    80005b90:	7402                	ld	s0,32(sp)
    80005b92:	64e2                	ld	s1,24(sp)
    80005b94:	6942                	ld	s2,16(sp)
    80005b96:	6145                	addi	sp,sp,48
    80005b98:	8082                	ret
    return -1;
    80005b9a:	557d                	li	a0,-1
    80005b9c:	bfcd                	j	80005b8e <argfd+0x4c>
    80005b9e:	557d                	li	a0,-1
    80005ba0:	b7fd                	j	80005b8e <argfd+0x4c>

0000000080005ba2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005ba2:	1101                	addi	sp,sp,-32
    80005ba4:	ec06                	sd	ra,24(sp)
    80005ba6:	e822                	sd	s0,16(sp)
    80005ba8:	e426                	sd	s1,8(sp)
    80005baa:	1000                	addi	s0,sp,32
    80005bac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	f4e080e7          	jalr	-178(ra) # 80001afc <myproc>
    80005bb6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bb8:	0e050793          	addi	a5,a0,224
    80005bbc:	4501                	li	a0,0
    80005bbe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bc0:	6398                	ld	a4,0(a5)
    80005bc2:	cb19                	beqz	a4,80005bd8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005bc4:	2505                	addiw	a0,a0,1
    80005bc6:	07a1                	addi	a5,a5,8
    80005bc8:	fed51ce3          	bne	a0,a3,80005bc0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bcc:	557d                	li	a0,-1
}
    80005bce:	60e2                	ld	ra,24(sp)
    80005bd0:	6442                	ld	s0,16(sp)
    80005bd2:	64a2                	ld	s1,8(sp)
    80005bd4:	6105                	addi	sp,sp,32
    80005bd6:	8082                	ret
      p->ofile[fd] = f;
    80005bd8:	01c50793          	addi	a5,a0,28
    80005bdc:	078e                	slli	a5,a5,0x3
    80005bde:	963e                	add	a2,a2,a5
    80005be0:	e204                	sd	s1,0(a2)
      return fd;
    80005be2:	b7f5                	j	80005bce <fdalloc+0x2c>

0000000080005be4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005be4:	715d                	addi	sp,sp,-80
    80005be6:	e486                	sd	ra,72(sp)
    80005be8:	e0a2                	sd	s0,64(sp)
    80005bea:	fc26                	sd	s1,56(sp)
    80005bec:	f84a                	sd	s2,48(sp)
    80005bee:	f44e                	sd	s3,40(sp)
    80005bf0:	f052                	sd	s4,32(sp)
    80005bf2:	ec56                	sd	s5,24(sp)
    80005bf4:	e85a                	sd	s6,16(sp)
    80005bf6:	0880                	addi	s0,sp,80
    80005bf8:	8b2e                	mv	s6,a1
    80005bfa:	89b2                	mv	s3,a2
    80005bfc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bfe:	fb040593          	addi	a1,s0,-80
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	e3e080e7          	jalr	-450(ra) # 80004a40 <nameiparent>
    80005c0a:	84aa                	mv	s1,a0
    80005c0c:	14050f63          	beqz	a0,80005d6a <create+0x186>
    return 0;

  ilock(dp);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	666080e7          	jalr	1638(ra) # 80004276 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c18:	4601                	li	a2,0
    80005c1a:	fb040593          	addi	a1,s0,-80
    80005c1e:	8526                	mv	a0,s1
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	b3a080e7          	jalr	-1222(ra) # 8000475a <dirlookup>
    80005c28:	8aaa                	mv	s5,a0
    80005c2a:	c931                	beqz	a0,80005c7e <create+0x9a>
    iunlockput(dp);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	8aa080e7          	jalr	-1878(ra) # 800044d8 <iunlockput>
    ilock(ip);
    80005c36:	8556                	mv	a0,s5
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	63e080e7          	jalr	1598(ra) # 80004276 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c40:	000b059b          	sext.w	a1,s6
    80005c44:	4789                	li	a5,2
    80005c46:	02f59563          	bne	a1,a5,80005c70 <create+0x8c>
    80005c4a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdb9794>
    80005c4e:	37f9                	addiw	a5,a5,-2
    80005c50:	17c2                	slli	a5,a5,0x30
    80005c52:	93c1                	srli	a5,a5,0x30
    80005c54:	4705                	li	a4,1
    80005c56:	00f76d63          	bltu	a4,a5,80005c70 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005c5a:	8556                	mv	a0,s5
    80005c5c:	60a6                	ld	ra,72(sp)
    80005c5e:	6406                	ld	s0,64(sp)
    80005c60:	74e2                	ld	s1,56(sp)
    80005c62:	7942                	ld	s2,48(sp)
    80005c64:	79a2                	ld	s3,40(sp)
    80005c66:	7a02                	ld	s4,32(sp)
    80005c68:	6ae2                	ld	s5,24(sp)
    80005c6a:	6b42                	ld	s6,16(sp)
    80005c6c:	6161                	addi	sp,sp,80
    80005c6e:	8082                	ret
    iunlockput(ip);
    80005c70:	8556                	mv	a0,s5
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	866080e7          	jalr	-1946(ra) # 800044d8 <iunlockput>
    return 0;
    80005c7a:	4a81                	li	s5,0
    80005c7c:	bff9                	j	80005c5a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005c7e:	85da                	mv	a1,s6
    80005c80:	4088                	lw	a0,0(s1)
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	456080e7          	jalr	1110(ra) # 800040d8 <ialloc>
    80005c8a:	8a2a                	mv	s4,a0
    80005c8c:	c539                	beqz	a0,80005cda <create+0xf6>
  ilock(ip);
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	5e8080e7          	jalr	1512(ra) # 80004276 <ilock>
  ip->major = major;
    80005c96:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005c9a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005c9e:	4905                	li	s2,1
    80005ca0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005ca4:	8552                	mv	a0,s4
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	504080e7          	jalr	1284(ra) # 800041aa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cae:	000b059b          	sext.w	a1,s6
    80005cb2:	03258b63          	beq	a1,s2,80005ce8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cb6:	004a2603          	lw	a2,4(s4)
    80005cba:	fb040593          	addi	a1,s0,-80
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	cb0080e7          	jalr	-848(ra) # 80004970 <dirlink>
    80005cc8:	06054f63          	bltz	a0,80005d46 <create+0x162>
  iunlockput(dp);
    80005ccc:	8526                	mv	a0,s1
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	80a080e7          	jalr	-2038(ra) # 800044d8 <iunlockput>
  return ip;
    80005cd6:	8ad2                	mv	s5,s4
    80005cd8:	b749                	j	80005c5a <create+0x76>
    iunlockput(dp);
    80005cda:	8526                	mv	a0,s1
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	7fc080e7          	jalr	2044(ra) # 800044d8 <iunlockput>
    return 0;
    80005ce4:	8ad2                	mv	s5,s4
    80005ce6:	bf95                	j	80005c5a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ce8:	004a2603          	lw	a2,4(s4)
    80005cec:	00003597          	auipc	a1,0x3
    80005cf0:	cb458593          	addi	a1,a1,-844 # 800089a0 <syscall_list+0x2b0>
    80005cf4:	8552                	mv	a0,s4
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	c7a080e7          	jalr	-902(ra) # 80004970 <dirlink>
    80005cfe:	04054463          	bltz	a0,80005d46 <create+0x162>
    80005d02:	40d0                	lw	a2,4(s1)
    80005d04:	00003597          	auipc	a1,0x3
    80005d08:	ca458593          	addi	a1,a1,-860 # 800089a8 <syscall_list+0x2b8>
    80005d0c:	8552                	mv	a0,s4
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	c62080e7          	jalr	-926(ra) # 80004970 <dirlink>
    80005d16:	02054863          	bltz	a0,80005d46 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d1a:	004a2603          	lw	a2,4(s4)
    80005d1e:	fb040593          	addi	a1,s0,-80
    80005d22:	8526                	mv	a0,s1
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	c4c080e7          	jalr	-948(ra) # 80004970 <dirlink>
    80005d2c:	00054d63          	bltz	a0,80005d46 <create+0x162>
    dp->nlink++;  // for ".."
    80005d30:	04a4d783          	lhu	a5,74(s1)
    80005d34:	2785                	addiw	a5,a5,1
    80005d36:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d3a:	8526                	mv	a0,s1
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	46e080e7          	jalr	1134(ra) # 800041aa <iupdate>
    80005d44:	b761                	j	80005ccc <create+0xe8>
  ip->nlink = 0;
    80005d46:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005d4a:	8552                	mv	a0,s4
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	45e080e7          	jalr	1118(ra) # 800041aa <iupdate>
  iunlockput(ip);
    80005d54:	8552                	mv	a0,s4
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	782080e7          	jalr	1922(ra) # 800044d8 <iunlockput>
  iunlockput(dp);
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	778080e7          	jalr	1912(ra) # 800044d8 <iunlockput>
  return 0;
    80005d68:	bdcd                	j	80005c5a <create+0x76>
    return 0;
    80005d6a:	8aaa                	mv	s5,a0
    80005d6c:	b5fd                	j	80005c5a <create+0x76>

0000000080005d6e <sys_dup>:
{
    80005d6e:	7179                	addi	sp,sp,-48
    80005d70:	f406                	sd	ra,40(sp)
    80005d72:	f022                	sd	s0,32(sp)
    80005d74:	ec26                	sd	s1,24(sp)
    80005d76:	e84a                	sd	s2,16(sp)
    80005d78:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d7a:	fd840613          	addi	a2,s0,-40
    80005d7e:	4581                	li	a1,0
    80005d80:	4501                	li	a0,0
    80005d82:	00000097          	auipc	ra,0x0
    80005d86:	dc0080e7          	jalr	-576(ra) # 80005b42 <argfd>
    return -1;
    80005d8a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d8c:	02054363          	bltz	a0,80005db2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005d90:	fd843903          	ld	s2,-40(s0)
    80005d94:	854a                	mv	a0,s2
    80005d96:	00000097          	auipc	ra,0x0
    80005d9a:	e0c080e7          	jalr	-500(ra) # 80005ba2 <fdalloc>
    80005d9e:	84aa                	mv	s1,a0
    return -1;
    80005da0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005da2:	00054863          	bltz	a0,80005db2 <sys_dup+0x44>
  filedup(f);
    80005da6:	854a                	mv	a0,s2
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	310080e7          	jalr	784(ra) # 800050b8 <filedup>
  return fd;
    80005db0:	87a6                	mv	a5,s1
}
    80005db2:	853e                	mv	a0,a5
    80005db4:	70a2                	ld	ra,40(sp)
    80005db6:	7402                	ld	s0,32(sp)
    80005db8:	64e2                	ld	s1,24(sp)
    80005dba:	6942                	ld	s2,16(sp)
    80005dbc:	6145                	addi	sp,sp,48
    80005dbe:	8082                	ret

0000000080005dc0 <sys_read>:
{
    80005dc0:	7179                	addi	sp,sp,-48
    80005dc2:	f406                	sd	ra,40(sp)
    80005dc4:	f022                	sd	s0,32(sp)
    80005dc6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005dc8:	fd840593          	addi	a1,s0,-40
    80005dcc:	4505                	li	a0,1
    80005dce:	ffffe097          	auipc	ra,0xffffe
    80005dd2:	804080e7          	jalr	-2044(ra) # 800035d2 <argaddr>
  argint(2, &n);
    80005dd6:	fe440593          	addi	a1,s0,-28
    80005dda:	4509                	li	a0,2
    80005ddc:	ffffd097          	auipc	ra,0xffffd
    80005de0:	7d4080e7          	jalr	2004(ra) # 800035b0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005de4:	fe840613          	addi	a2,s0,-24
    80005de8:	4581                	li	a1,0
    80005dea:	4501                	li	a0,0
    80005dec:	00000097          	auipc	ra,0x0
    80005df0:	d56080e7          	jalr	-682(ra) # 80005b42 <argfd>
    80005df4:	87aa                	mv	a5,a0
    return -1;
    80005df6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005df8:	0007cc63          	bltz	a5,80005e10 <sys_read+0x50>
  return fileread(f, p, n);
    80005dfc:	fe442603          	lw	a2,-28(s0)
    80005e00:	fd843583          	ld	a1,-40(s0)
    80005e04:	fe843503          	ld	a0,-24(s0)
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	43c080e7          	jalr	1084(ra) # 80005244 <fileread>
}
    80005e10:	70a2                	ld	ra,40(sp)
    80005e12:	7402                	ld	s0,32(sp)
    80005e14:	6145                	addi	sp,sp,48
    80005e16:	8082                	ret

0000000080005e18 <sys_write>:
{
    80005e18:	7179                	addi	sp,sp,-48
    80005e1a:	f406                	sd	ra,40(sp)
    80005e1c:	f022                	sd	s0,32(sp)
    80005e1e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e20:	fd840593          	addi	a1,s0,-40
    80005e24:	4505                	li	a0,1
    80005e26:	ffffd097          	auipc	ra,0xffffd
    80005e2a:	7ac080e7          	jalr	1964(ra) # 800035d2 <argaddr>
  argint(2, &n);
    80005e2e:	fe440593          	addi	a1,s0,-28
    80005e32:	4509                	li	a0,2
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	77c080e7          	jalr	1916(ra) # 800035b0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e3c:	fe840613          	addi	a2,s0,-24
    80005e40:	4581                	li	a1,0
    80005e42:	4501                	li	a0,0
    80005e44:	00000097          	auipc	ra,0x0
    80005e48:	cfe080e7          	jalr	-770(ra) # 80005b42 <argfd>
    80005e4c:	87aa                	mv	a5,a0
    return -1;
    80005e4e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e50:	0007cc63          	bltz	a5,80005e68 <sys_write+0x50>
  return filewrite(f, p, n);
    80005e54:	fe442603          	lw	a2,-28(s0)
    80005e58:	fd843583          	ld	a1,-40(s0)
    80005e5c:	fe843503          	ld	a0,-24(s0)
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	4a6080e7          	jalr	1190(ra) # 80005306 <filewrite>
}
    80005e68:	70a2                	ld	ra,40(sp)
    80005e6a:	7402                	ld	s0,32(sp)
    80005e6c:	6145                	addi	sp,sp,48
    80005e6e:	8082                	ret

0000000080005e70 <sys_close>:
{
    80005e70:	1101                	addi	sp,sp,-32
    80005e72:	ec06                	sd	ra,24(sp)
    80005e74:	e822                	sd	s0,16(sp)
    80005e76:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e78:	fe040613          	addi	a2,s0,-32
    80005e7c:	fec40593          	addi	a1,s0,-20
    80005e80:	4501                	li	a0,0
    80005e82:	00000097          	auipc	ra,0x0
    80005e86:	cc0080e7          	jalr	-832(ra) # 80005b42 <argfd>
    return -1;
    80005e8a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e8c:	02054463          	bltz	a0,80005eb4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	c6c080e7          	jalr	-916(ra) # 80001afc <myproc>
    80005e98:	fec42783          	lw	a5,-20(s0)
    80005e9c:	07f1                	addi	a5,a5,28
    80005e9e:	078e                	slli	a5,a5,0x3
    80005ea0:	953e                	add	a0,a0,a5
    80005ea2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005ea6:	fe043503          	ld	a0,-32(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	260080e7          	jalr	608(ra) # 8000510a <fileclose>
  return 0;
    80005eb2:	4781                	li	a5,0
}
    80005eb4:	853e                	mv	a0,a5
    80005eb6:	60e2                	ld	ra,24(sp)
    80005eb8:	6442                	ld	s0,16(sp)
    80005eba:	6105                	addi	sp,sp,32
    80005ebc:	8082                	ret

0000000080005ebe <sys_fstat>:
{
    80005ebe:	1101                	addi	sp,sp,-32
    80005ec0:	ec06                	sd	ra,24(sp)
    80005ec2:	e822                	sd	s0,16(sp)
    80005ec4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005ec6:	fe040593          	addi	a1,s0,-32
    80005eca:	4505                	li	a0,1
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	706080e7          	jalr	1798(ra) # 800035d2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005ed4:	fe840613          	addi	a2,s0,-24
    80005ed8:	4581                	li	a1,0
    80005eda:	4501                	li	a0,0
    80005edc:	00000097          	auipc	ra,0x0
    80005ee0:	c66080e7          	jalr	-922(ra) # 80005b42 <argfd>
    80005ee4:	87aa                	mv	a5,a0
    return -1;
    80005ee6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ee8:	0007ca63          	bltz	a5,80005efc <sys_fstat+0x3e>
  return filestat(f, st);
    80005eec:	fe043583          	ld	a1,-32(s0)
    80005ef0:	fe843503          	ld	a0,-24(s0)
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	2de080e7          	jalr	734(ra) # 800051d2 <filestat>
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	6105                	addi	sp,sp,32
    80005f02:	8082                	ret

0000000080005f04 <sys_link>:
{
    80005f04:	7169                	addi	sp,sp,-304
    80005f06:	f606                	sd	ra,296(sp)
    80005f08:	f222                	sd	s0,288(sp)
    80005f0a:	ee26                	sd	s1,280(sp)
    80005f0c:	ea4a                	sd	s2,272(sp)
    80005f0e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f10:	08000613          	li	a2,128
    80005f14:	ed040593          	addi	a1,s0,-304
    80005f18:	4501                	li	a0,0
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	6da080e7          	jalr	1754(ra) # 800035f4 <argstr>
    return -1;
    80005f22:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f24:	10054e63          	bltz	a0,80006040 <sys_link+0x13c>
    80005f28:	08000613          	li	a2,128
    80005f2c:	f5040593          	addi	a1,s0,-176
    80005f30:	4505                	li	a0,1
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	6c2080e7          	jalr	1730(ra) # 800035f4 <argstr>
    return -1;
    80005f3a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f3c:	10054263          	bltz	a0,80006040 <sys_link+0x13c>
  begin_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	d02080e7          	jalr	-766(ra) # 80004c42 <begin_op>
  if((ip = namei(old)) == 0){
    80005f48:	ed040513          	addi	a0,s0,-304
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	ad6080e7          	jalr	-1322(ra) # 80004a22 <namei>
    80005f54:	84aa                	mv	s1,a0
    80005f56:	c551                	beqz	a0,80005fe2 <sys_link+0xde>
  ilock(ip);
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	31e080e7          	jalr	798(ra) # 80004276 <ilock>
  if(ip->type == T_DIR){
    80005f60:	04449703          	lh	a4,68(s1)
    80005f64:	4785                	li	a5,1
    80005f66:	08f70463          	beq	a4,a5,80005fee <sys_link+0xea>
  ip->nlink++;
    80005f6a:	04a4d783          	lhu	a5,74(s1)
    80005f6e:	2785                	addiw	a5,a5,1
    80005f70:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	234080e7          	jalr	564(ra) # 800041aa <iupdate>
  iunlock(ip);
    80005f7e:	8526                	mv	a0,s1
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	3b8080e7          	jalr	952(ra) # 80004338 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f88:	fd040593          	addi	a1,s0,-48
    80005f8c:	f5040513          	addi	a0,s0,-176
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	ab0080e7          	jalr	-1360(ra) # 80004a40 <nameiparent>
    80005f98:	892a                	mv	s2,a0
    80005f9a:	c935                	beqz	a0,8000600e <sys_link+0x10a>
  ilock(dp);
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	2da080e7          	jalr	730(ra) # 80004276 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005fa4:	00092703          	lw	a4,0(s2)
    80005fa8:	409c                	lw	a5,0(s1)
    80005faa:	04f71d63          	bne	a4,a5,80006004 <sys_link+0x100>
    80005fae:	40d0                	lw	a2,4(s1)
    80005fb0:	fd040593          	addi	a1,s0,-48
    80005fb4:	854a                	mv	a0,s2
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	9ba080e7          	jalr	-1606(ra) # 80004970 <dirlink>
    80005fbe:	04054363          	bltz	a0,80006004 <sys_link+0x100>
  iunlockput(dp);
    80005fc2:	854a                	mv	a0,s2
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	514080e7          	jalr	1300(ra) # 800044d8 <iunlockput>
  iput(ip);
    80005fcc:	8526                	mv	a0,s1
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	462080e7          	jalr	1122(ra) # 80004430 <iput>
  end_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	cea080e7          	jalr	-790(ra) # 80004cc0 <end_op>
  return 0;
    80005fde:	4781                	li	a5,0
    80005fe0:	a085                	j	80006040 <sys_link+0x13c>
    end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	cde080e7          	jalr	-802(ra) # 80004cc0 <end_op>
    return -1;
    80005fea:	57fd                	li	a5,-1
    80005fec:	a891                	j	80006040 <sys_link+0x13c>
    iunlockput(ip);
    80005fee:	8526                	mv	a0,s1
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	4e8080e7          	jalr	1256(ra) # 800044d8 <iunlockput>
    end_op();
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	cc8080e7          	jalr	-824(ra) # 80004cc0 <end_op>
    return -1;
    80006000:	57fd                	li	a5,-1
    80006002:	a83d                	j	80006040 <sys_link+0x13c>
    iunlockput(dp);
    80006004:	854a                	mv	a0,s2
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	4d2080e7          	jalr	1234(ra) # 800044d8 <iunlockput>
  ilock(ip);
    8000600e:	8526                	mv	a0,s1
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	266080e7          	jalr	614(ra) # 80004276 <ilock>
  ip->nlink--;
    80006018:	04a4d783          	lhu	a5,74(s1)
    8000601c:	37fd                	addiw	a5,a5,-1
    8000601e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	186080e7          	jalr	390(ra) # 800041aa <iupdate>
  iunlockput(ip);
    8000602c:	8526                	mv	a0,s1
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	4aa080e7          	jalr	1194(ra) # 800044d8 <iunlockput>
  end_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	c8a080e7          	jalr	-886(ra) # 80004cc0 <end_op>
  return -1;
    8000603e:	57fd                	li	a5,-1
}
    80006040:	853e                	mv	a0,a5
    80006042:	70b2                	ld	ra,296(sp)
    80006044:	7412                	ld	s0,288(sp)
    80006046:	64f2                	ld	s1,280(sp)
    80006048:	6952                	ld	s2,272(sp)
    8000604a:	6155                	addi	sp,sp,304
    8000604c:	8082                	ret

000000008000604e <sys_unlink>:
{
    8000604e:	7151                	addi	sp,sp,-240
    80006050:	f586                	sd	ra,232(sp)
    80006052:	f1a2                	sd	s0,224(sp)
    80006054:	eda6                	sd	s1,216(sp)
    80006056:	e9ca                	sd	s2,208(sp)
    80006058:	e5ce                	sd	s3,200(sp)
    8000605a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000605c:	08000613          	li	a2,128
    80006060:	f3040593          	addi	a1,s0,-208
    80006064:	4501                	li	a0,0
    80006066:	ffffd097          	auipc	ra,0xffffd
    8000606a:	58e080e7          	jalr	1422(ra) # 800035f4 <argstr>
    8000606e:	18054163          	bltz	a0,800061f0 <sys_unlink+0x1a2>
  begin_op();
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	bd0080e7          	jalr	-1072(ra) # 80004c42 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000607a:	fb040593          	addi	a1,s0,-80
    8000607e:	f3040513          	addi	a0,s0,-208
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	9be080e7          	jalr	-1602(ra) # 80004a40 <nameiparent>
    8000608a:	84aa                	mv	s1,a0
    8000608c:	c979                	beqz	a0,80006162 <sys_unlink+0x114>
  ilock(dp);
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	1e8080e7          	jalr	488(ra) # 80004276 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006096:	00003597          	auipc	a1,0x3
    8000609a:	90a58593          	addi	a1,a1,-1782 # 800089a0 <syscall_list+0x2b0>
    8000609e:	fb040513          	addi	a0,s0,-80
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	69e080e7          	jalr	1694(ra) # 80004740 <namecmp>
    800060aa:	14050a63          	beqz	a0,800061fe <sys_unlink+0x1b0>
    800060ae:	00003597          	auipc	a1,0x3
    800060b2:	8fa58593          	addi	a1,a1,-1798 # 800089a8 <syscall_list+0x2b8>
    800060b6:	fb040513          	addi	a0,s0,-80
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	686080e7          	jalr	1670(ra) # 80004740 <namecmp>
    800060c2:	12050e63          	beqz	a0,800061fe <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060c6:	f2c40613          	addi	a2,s0,-212
    800060ca:	fb040593          	addi	a1,s0,-80
    800060ce:	8526                	mv	a0,s1
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	68a080e7          	jalr	1674(ra) # 8000475a <dirlookup>
    800060d8:	892a                	mv	s2,a0
    800060da:	12050263          	beqz	a0,800061fe <sys_unlink+0x1b0>
  ilock(ip);
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	198080e7          	jalr	408(ra) # 80004276 <ilock>
  if(ip->nlink < 1)
    800060e6:	04a91783          	lh	a5,74(s2)
    800060ea:	08f05263          	blez	a5,8000616e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060ee:	04491703          	lh	a4,68(s2)
    800060f2:	4785                	li	a5,1
    800060f4:	08f70563          	beq	a4,a5,8000617e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060f8:	4641                	li	a2,16
    800060fa:	4581                	li	a1,0
    800060fc:	fc040513          	addi	a0,s0,-64
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	d08080e7          	jalr	-760(ra) # 80000e08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006108:	4741                	li	a4,16
    8000610a:	f2c42683          	lw	a3,-212(s0)
    8000610e:	fc040613          	addi	a2,s0,-64
    80006112:	4581                	li	a1,0
    80006114:	8526                	mv	a0,s1
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	50c080e7          	jalr	1292(ra) # 80004622 <writei>
    8000611e:	47c1                	li	a5,16
    80006120:	0af51563          	bne	a0,a5,800061ca <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006124:	04491703          	lh	a4,68(s2)
    80006128:	4785                	li	a5,1
    8000612a:	0af70863          	beq	a4,a5,800061da <sys_unlink+0x18c>
  iunlockput(dp);
    8000612e:	8526                	mv	a0,s1
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	3a8080e7          	jalr	936(ra) # 800044d8 <iunlockput>
  ip->nlink--;
    80006138:	04a95783          	lhu	a5,74(s2)
    8000613c:	37fd                	addiw	a5,a5,-1
    8000613e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006142:	854a                	mv	a0,s2
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	066080e7          	jalr	102(ra) # 800041aa <iupdate>
  iunlockput(ip);
    8000614c:	854a                	mv	a0,s2
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	38a080e7          	jalr	906(ra) # 800044d8 <iunlockput>
  end_op();
    80006156:	fffff097          	auipc	ra,0xfffff
    8000615a:	b6a080e7          	jalr	-1174(ra) # 80004cc0 <end_op>
  return 0;
    8000615e:	4501                	li	a0,0
    80006160:	a84d                	j	80006212 <sys_unlink+0x1c4>
    end_op();
    80006162:	fffff097          	auipc	ra,0xfffff
    80006166:	b5e080e7          	jalr	-1186(ra) # 80004cc0 <end_op>
    return -1;
    8000616a:	557d                	li	a0,-1
    8000616c:	a05d                	j	80006212 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000616e:	00003517          	auipc	a0,0x3
    80006172:	84250513          	addi	a0,a0,-1982 # 800089b0 <syscall_list+0x2c0>
    80006176:	ffffa097          	auipc	ra,0xffffa
    8000617a:	3ca080e7          	jalr	970(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000617e:	04c92703          	lw	a4,76(s2)
    80006182:	02000793          	li	a5,32
    80006186:	f6e7f9e3          	bgeu	a5,a4,800060f8 <sys_unlink+0xaa>
    8000618a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000618e:	4741                	li	a4,16
    80006190:	86ce                	mv	a3,s3
    80006192:	f1840613          	addi	a2,s0,-232
    80006196:	4581                	li	a1,0
    80006198:	854a                	mv	a0,s2
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	390080e7          	jalr	912(ra) # 8000452a <readi>
    800061a2:	47c1                	li	a5,16
    800061a4:	00f51b63          	bne	a0,a5,800061ba <sys_unlink+0x16c>
    if(de.inum != 0)
    800061a8:	f1845783          	lhu	a5,-232(s0)
    800061ac:	e7a1                	bnez	a5,800061f4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061ae:	29c1                	addiw	s3,s3,16
    800061b0:	04c92783          	lw	a5,76(s2)
    800061b4:	fcf9ede3          	bltu	s3,a5,8000618e <sys_unlink+0x140>
    800061b8:	b781                	j	800060f8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061ba:	00003517          	auipc	a0,0x3
    800061be:	80e50513          	addi	a0,a0,-2034 # 800089c8 <syscall_list+0x2d8>
    800061c2:	ffffa097          	auipc	ra,0xffffa
    800061c6:	37e080e7          	jalr	894(ra) # 80000540 <panic>
    panic("unlink: writei");
    800061ca:	00003517          	auipc	a0,0x3
    800061ce:	81650513          	addi	a0,a0,-2026 # 800089e0 <syscall_list+0x2f0>
    800061d2:	ffffa097          	auipc	ra,0xffffa
    800061d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>
    dp->nlink--;
    800061da:	04a4d783          	lhu	a5,74(s1)
    800061de:	37fd                	addiw	a5,a5,-1
    800061e0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061e4:	8526                	mv	a0,s1
    800061e6:	ffffe097          	auipc	ra,0xffffe
    800061ea:	fc4080e7          	jalr	-60(ra) # 800041aa <iupdate>
    800061ee:	b781                	j	8000612e <sys_unlink+0xe0>
    return -1;
    800061f0:	557d                	li	a0,-1
    800061f2:	a005                	j	80006212 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061f4:	854a                	mv	a0,s2
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	2e2080e7          	jalr	738(ra) # 800044d8 <iunlockput>
  iunlockput(dp);
    800061fe:	8526                	mv	a0,s1
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	2d8080e7          	jalr	728(ra) # 800044d8 <iunlockput>
  end_op();
    80006208:	fffff097          	auipc	ra,0xfffff
    8000620c:	ab8080e7          	jalr	-1352(ra) # 80004cc0 <end_op>
  return -1;
    80006210:	557d                	li	a0,-1
}
    80006212:	70ae                	ld	ra,232(sp)
    80006214:	740e                	ld	s0,224(sp)
    80006216:	64ee                	ld	s1,216(sp)
    80006218:	694e                	ld	s2,208(sp)
    8000621a:	69ae                	ld	s3,200(sp)
    8000621c:	616d                	addi	sp,sp,240
    8000621e:	8082                	ret

0000000080006220 <sys_open>:

uint64
sys_open(void)
{
    80006220:	7131                	addi	sp,sp,-192
    80006222:	fd06                	sd	ra,184(sp)
    80006224:	f922                	sd	s0,176(sp)
    80006226:	f526                	sd	s1,168(sp)
    80006228:	f14a                	sd	s2,160(sp)
    8000622a:	ed4e                	sd	s3,152(sp)
    8000622c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000622e:	f4c40593          	addi	a1,s0,-180
    80006232:	4505                	li	a0,1
    80006234:	ffffd097          	auipc	ra,0xffffd
    80006238:	37c080e7          	jalr	892(ra) # 800035b0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000623c:	08000613          	li	a2,128
    80006240:	f5040593          	addi	a1,s0,-176
    80006244:	4501                	li	a0,0
    80006246:	ffffd097          	auipc	ra,0xffffd
    8000624a:	3ae080e7          	jalr	942(ra) # 800035f4 <argstr>
    8000624e:	87aa                	mv	a5,a0
    return -1;
    80006250:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006252:	0a07c963          	bltz	a5,80006304 <sys_open+0xe4>

  begin_op();
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	9ec080e7          	jalr	-1556(ra) # 80004c42 <begin_op>

  if(omode & O_CREATE){
    8000625e:	f4c42783          	lw	a5,-180(s0)
    80006262:	2007f793          	andi	a5,a5,512
    80006266:	cfc5                	beqz	a5,8000631e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006268:	4681                	li	a3,0
    8000626a:	4601                	li	a2,0
    8000626c:	4589                	li	a1,2
    8000626e:	f5040513          	addi	a0,s0,-176
    80006272:	00000097          	auipc	ra,0x0
    80006276:	972080e7          	jalr	-1678(ra) # 80005be4 <create>
    8000627a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000627c:	c959                	beqz	a0,80006312 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000627e:	04449703          	lh	a4,68(s1)
    80006282:	478d                	li	a5,3
    80006284:	00f71763          	bne	a4,a5,80006292 <sys_open+0x72>
    80006288:	0464d703          	lhu	a4,70(s1)
    8000628c:	47a5                	li	a5,9
    8000628e:	0ce7ed63          	bltu	a5,a4,80006368 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006292:	fffff097          	auipc	ra,0xfffff
    80006296:	dbc080e7          	jalr	-580(ra) # 8000504e <filealloc>
    8000629a:	89aa                	mv	s3,a0
    8000629c:	10050363          	beqz	a0,800063a2 <sys_open+0x182>
    800062a0:	00000097          	auipc	ra,0x0
    800062a4:	902080e7          	jalr	-1790(ra) # 80005ba2 <fdalloc>
    800062a8:	892a                	mv	s2,a0
    800062aa:	0e054763          	bltz	a0,80006398 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062ae:	04449703          	lh	a4,68(s1)
    800062b2:	478d                	li	a5,3
    800062b4:	0cf70563          	beq	a4,a5,8000637e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062b8:	4789                	li	a5,2
    800062ba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062be:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062c2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062c6:	f4c42783          	lw	a5,-180(s0)
    800062ca:	0017c713          	xori	a4,a5,1
    800062ce:	8b05                	andi	a4,a4,1
    800062d0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062d4:	0037f713          	andi	a4,a5,3
    800062d8:	00e03733          	snez	a4,a4
    800062dc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062e0:	4007f793          	andi	a5,a5,1024
    800062e4:	c791                	beqz	a5,800062f0 <sys_open+0xd0>
    800062e6:	04449703          	lh	a4,68(s1)
    800062ea:	4789                	li	a5,2
    800062ec:	0af70063          	beq	a4,a5,8000638c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062f0:	8526                	mv	a0,s1
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	046080e7          	jalr	70(ra) # 80004338 <iunlock>
  end_op();
    800062fa:	fffff097          	auipc	ra,0xfffff
    800062fe:	9c6080e7          	jalr	-1594(ra) # 80004cc0 <end_op>

  return fd;
    80006302:	854a                	mv	a0,s2
}
    80006304:	70ea                	ld	ra,184(sp)
    80006306:	744a                	ld	s0,176(sp)
    80006308:	74aa                	ld	s1,168(sp)
    8000630a:	790a                	ld	s2,160(sp)
    8000630c:	69ea                	ld	s3,152(sp)
    8000630e:	6129                	addi	sp,sp,192
    80006310:	8082                	ret
      end_op();
    80006312:	fffff097          	auipc	ra,0xfffff
    80006316:	9ae080e7          	jalr	-1618(ra) # 80004cc0 <end_op>
      return -1;
    8000631a:	557d                	li	a0,-1
    8000631c:	b7e5                	j	80006304 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000631e:	f5040513          	addi	a0,s0,-176
    80006322:	ffffe097          	auipc	ra,0xffffe
    80006326:	700080e7          	jalr	1792(ra) # 80004a22 <namei>
    8000632a:	84aa                	mv	s1,a0
    8000632c:	c905                	beqz	a0,8000635c <sys_open+0x13c>
    ilock(ip);
    8000632e:	ffffe097          	auipc	ra,0xffffe
    80006332:	f48080e7          	jalr	-184(ra) # 80004276 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006336:	04449703          	lh	a4,68(s1)
    8000633a:	4785                	li	a5,1
    8000633c:	f4f711e3          	bne	a4,a5,8000627e <sys_open+0x5e>
    80006340:	f4c42783          	lw	a5,-180(s0)
    80006344:	d7b9                	beqz	a5,80006292 <sys_open+0x72>
      iunlockput(ip);
    80006346:	8526                	mv	a0,s1
    80006348:	ffffe097          	auipc	ra,0xffffe
    8000634c:	190080e7          	jalr	400(ra) # 800044d8 <iunlockput>
      end_op();
    80006350:	fffff097          	auipc	ra,0xfffff
    80006354:	970080e7          	jalr	-1680(ra) # 80004cc0 <end_op>
      return -1;
    80006358:	557d                	li	a0,-1
    8000635a:	b76d                	j	80006304 <sys_open+0xe4>
      end_op();
    8000635c:	fffff097          	auipc	ra,0xfffff
    80006360:	964080e7          	jalr	-1692(ra) # 80004cc0 <end_op>
      return -1;
    80006364:	557d                	li	a0,-1
    80006366:	bf79                	j	80006304 <sys_open+0xe4>
    iunlockput(ip);
    80006368:	8526                	mv	a0,s1
    8000636a:	ffffe097          	auipc	ra,0xffffe
    8000636e:	16e080e7          	jalr	366(ra) # 800044d8 <iunlockput>
    end_op();
    80006372:	fffff097          	auipc	ra,0xfffff
    80006376:	94e080e7          	jalr	-1714(ra) # 80004cc0 <end_op>
    return -1;
    8000637a:	557d                	li	a0,-1
    8000637c:	b761                	j	80006304 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000637e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006382:	04649783          	lh	a5,70(s1)
    80006386:	02f99223          	sh	a5,36(s3)
    8000638a:	bf25                	j	800062c2 <sys_open+0xa2>
    itrunc(ip);
    8000638c:	8526                	mv	a0,s1
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	ff6080e7          	jalr	-10(ra) # 80004384 <itrunc>
    80006396:	bfa9                	j	800062f0 <sys_open+0xd0>
      fileclose(f);
    80006398:	854e                	mv	a0,s3
    8000639a:	fffff097          	auipc	ra,0xfffff
    8000639e:	d70080e7          	jalr	-656(ra) # 8000510a <fileclose>
    iunlockput(ip);
    800063a2:	8526                	mv	a0,s1
    800063a4:	ffffe097          	auipc	ra,0xffffe
    800063a8:	134080e7          	jalr	308(ra) # 800044d8 <iunlockput>
    end_op();
    800063ac:	fffff097          	auipc	ra,0xfffff
    800063b0:	914080e7          	jalr	-1772(ra) # 80004cc0 <end_op>
    return -1;
    800063b4:	557d                	li	a0,-1
    800063b6:	b7b9                	j	80006304 <sys_open+0xe4>

00000000800063b8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063b8:	7175                	addi	sp,sp,-144
    800063ba:	e506                	sd	ra,136(sp)
    800063bc:	e122                	sd	s0,128(sp)
    800063be:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063c0:	fffff097          	auipc	ra,0xfffff
    800063c4:	882080e7          	jalr	-1918(ra) # 80004c42 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063c8:	08000613          	li	a2,128
    800063cc:	f7040593          	addi	a1,s0,-144
    800063d0:	4501                	li	a0,0
    800063d2:	ffffd097          	auipc	ra,0xffffd
    800063d6:	222080e7          	jalr	546(ra) # 800035f4 <argstr>
    800063da:	02054963          	bltz	a0,8000640c <sys_mkdir+0x54>
    800063de:	4681                	li	a3,0
    800063e0:	4601                	li	a2,0
    800063e2:	4585                	li	a1,1
    800063e4:	f7040513          	addi	a0,s0,-144
    800063e8:	fffff097          	auipc	ra,0xfffff
    800063ec:	7fc080e7          	jalr	2044(ra) # 80005be4 <create>
    800063f0:	cd11                	beqz	a0,8000640c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	0e6080e7          	jalr	230(ra) # 800044d8 <iunlockput>
  end_op();
    800063fa:	fffff097          	auipc	ra,0xfffff
    800063fe:	8c6080e7          	jalr	-1850(ra) # 80004cc0 <end_op>
  return 0;
    80006402:	4501                	li	a0,0
}
    80006404:	60aa                	ld	ra,136(sp)
    80006406:	640a                	ld	s0,128(sp)
    80006408:	6149                	addi	sp,sp,144
    8000640a:	8082                	ret
    end_op();
    8000640c:	fffff097          	auipc	ra,0xfffff
    80006410:	8b4080e7          	jalr	-1868(ra) # 80004cc0 <end_op>
    return -1;
    80006414:	557d                	li	a0,-1
    80006416:	b7fd                	j	80006404 <sys_mkdir+0x4c>

0000000080006418 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006418:	7135                	addi	sp,sp,-160
    8000641a:	ed06                	sd	ra,152(sp)
    8000641c:	e922                	sd	s0,144(sp)
    8000641e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	822080e7          	jalr	-2014(ra) # 80004c42 <begin_op>
  argint(1, &major);
    80006428:	f6c40593          	addi	a1,s0,-148
    8000642c:	4505                	li	a0,1
    8000642e:	ffffd097          	auipc	ra,0xffffd
    80006432:	182080e7          	jalr	386(ra) # 800035b0 <argint>
  argint(2, &minor);
    80006436:	f6840593          	addi	a1,s0,-152
    8000643a:	4509                	li	a0,2
    8000643c:	ffffd097          	auipc	ra,0xffffd
    80006440:	174080e7          	jalr	372(ra) # 800035b0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006444:	08000613          	li	a2,128
    80006448:	f7040593          	addi	a1,s0,-144
    8000644c:	4501                	li	a0,0
    8000644e:	ffffd097          	auipc	ra,0xffffd
    80006452:	1a6080e7          	jalr	422(ra) # 800035f4 <argstr>
    80006456:	02054b63          	bltz	a0,8000648c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000645a:	f6841683          	lh	a3,-152(s0)
    8000645e:	f6c41603          	lh	a2,-148(s0)
    80006462:	458d                	li	a1,3
    80006464:	f7040513          	addi	a0,s0,-144
    80006468:	fffff097          	auipc	ra,0xfffff
    8000646c:	77c080e7          	jalr	1916(ra) # 80005be4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006470:	cd11                	beqz	a0,8000648c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006472:	ffffe097          	auipc	ra,0xffffe
    80006476:	066080e7          	jalr	102(ra) # 800044d8 <iunlockput>
  end_op();
    8000647a:	fffff097          	auipc	ra,0xfffff
    8000647e:	846080e7          	jalr	-1978(ra) # 80004cc0 <end_op>
  return 0;
    80006482:	4501                	li	a0,0
}
    80006484:	60ea                	ld	ra,152(sp)
    80006486:	644a                	ld	s0,144(sp)
    80006488:	610d                	addi	sp,sp,160
    8000648a:	8082                	ret
    end_op();
    8000648c:	fffff097          	auipc	ra,0xfffff
    80006490:	834080e7          	jalr	-1996(ra) # 80004cc0 <end_op>
    return -1;
    80006494:	557d                	li	a0,-1
    80006496:	b7fd                	j	80006484 <sys_mknod+0x6c>

0000000080006498 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006498:	7135                	addi	sp,sp,-160
    8000649a:	ed06                	sd	ra,152(sp)
    8000649c:	e922                	sd	s0,144(sp)
    8000649e:	e526                	sd	s1,136(sp)
    800064a0:	e14a                	sd	s2,128(sp)
    800064a2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064a4:	ffffb097          	auipc	ra,0xffffb
    800064a8:	658080e7          	jalr	1624(ra) # 80001afc <myproc>
    800064ac:	892a                	mv	s2,a0
  
  begin_op();
    800064ae:	ffffe097          	auipc	ra,0xffffe
    800064b2:	794080e7          	jalr	1940(ra) # 80004c42 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064b6:	08000613          	li	a2,128
    800064ba:	f6040593          	addi	a1,s0,-160
    800064be:	4501                	li	a0,0
    800064c0:	ffffd097          	auipc	ra,0xffffd
    800064c4:	134080e7          	jalr	308(ra) # 800035f4 <argstr>
    800064c8:	04054b63          	bltz	a0,8000651e <sys_chdir+0x86>
    800064cc:	f6040513          	addi	a0,s0,-160
    800064d0:	ffffe097          	auipc	ra,0xffffe
    800064d4:	552080e7          	jalr	1362(ra) # 80004a22 <namei>
    800064d8:	84aa                	mv	s1,a0
    800064da:	c131                	beqz	a0,8000651e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064dc:	ffffe097          	auipc	ra,0xffffe
    800064e0:	d9a080e7          	jalr	-614(ra) # 80004276 <ilock>
  if(ip->type != T_DIR){
    800064e4:	04449703          	lh	a4,68(s1)
    800064e8:	4785                	li	a5,1
    800064ea:	04f71063          	bne	a4,a5,8000652a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064ee:	8526                	mv	a0,s1
    800064f0:	ffffe097          	auipc	ra,0xffffe
    800064f4:	e48080e7          	jalr	-440(ra) # 80004338 <iunlock>
  iput(p->cwd);
    800064f8:	16093503          	ld	a0,352(s2)
    800064fc:	ffffe097          	auipc	ra,0xffffe
    80006500:	f34080e7          	jalr	-204(ra) # 80004430 <iput>
  end_op();
    80006504:	ffffe097          	auipc	ra,0xffffe
    80006508:	7bc080e7          	jalr	1980(ra) # 80004cc0 <end_op>
  p->cwd = ip;
    8000650c:	16993023          	sd	s1,352(s2)
  return 0;
    80006510:	4501                	li	a0,0
}
    80006512:	60ea                	ld	ra,152(sp)
    80006514:	644a                	ld	s0,144(sp)
    80006516:	64aa                	ld	s1,136(sp)
    80006518:	690a                	ld	s2,128(sp)
    8000651a:	610d                	addi	sp,sp,160
    8000651c:	8082                	ret
    end_op();
    8000651e:	ffffe097          	auipc	ra,0xffffe
    80006522:	7a2080e7          	jalr	1954(ra) # 80004cc0 <end_op>
    return -1;
    80006526:	557d                	li	a0,-1
    80006528:	b7ed                	j	80006512 <sys_chdir+0x7a>
    iunlockput(ip);
    8000652a:	8526                	mv	a0,s1
    8000652c:	ffffe097          	auipc	ra,0xffffe
    80006530:	fac080e7          	jalr	-84(ra) # 800044d8 <iunlockput>
    end_op();
    80006534:	ffffe097          	auipc	ra,0xffffe
    80006538:	78c080e7          	jalr	1932(ra) # 80004cc0 <end_op>
    return -1;
    8000653c:	557d                	li	a0,-1
    8000653e:	bfd1                	j	80006512 <sys_chdir+0x7a>

0000000080006540 <sys_exec>:

uint64
sys_exec(void)
{
    80006540:	7145                	addi	sp,sp,-464
    80006542:	e786                	sd	ra,456(sp)
    80006544:	e3a2                	sd	s0,448(sp)
    80006546:	ff26                	sd	s1,440(sp)
    80006548:	fb4a                	sd	s2,432(sp)
    8000654a:	f74e                	sd	s3,424(sp)
    8000654c:	f352                	sd	s4,416(sp)
    8000654e:	ef56                	sd	s5,408(sp)
    80006550:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006552:	e3840593          	addi	a1,s0,-456
    80006556:	4505                	li	a0,1
    80006558:	ffffd097          	auipc	ra,0xffffd
    8000655c:	07a080e7          	jalr	122(ra) # 800035d2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006560:	08000613          	li	a2,128
    80006564:	f4040593          	addi	a1,s0,-192
    80006568:	4501                	li	a0,0
    8000656a:	ffffd097          	auipc	ra,0xffffd
    8000656e:	08a080e7          	jalr	138(ra) # 800035f4 <argstr>
    80006572:	87aa                	mv	a5,a0
    return -1;
    80006574:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006576:	0c07c363          	bltz	a5,8000663c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000657a:	10000613          	li	a2,256
    8000657e:	4581                	li	a1,0
    80006580:	e4040513          	addi	a0,s0,-448
    80006584:	ffffb097          	auipc	ra,0xffffb
    80006588:	884080e7          	jalr	-1916(ra) # 80000e08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000658c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006590:	89a6                	mv	s3,s1
    80006592:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006594:	02000a13          	li	s4,32
    80006598:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000659c:	00391513          	slli	a0,s2,0x3
    800065a0:	e3040593          	addi	a1,s0,-464
    800065a4:	e3843783          	ld	a5,-456(s0)
    800065a8:	953e                	add	a0,a0,a5
    800065aa:	ffffd097          	auipc	ra,0xffffd
    800065ae:	f68080e7          	jalr	-152(ra) # 80003512 <fetchaddr>
    800065b2:	02054a63          	bltz	a0,800065e6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800065b6:	e3043783          	ld	a5,-464(s0)
    800065ba:	c3b9                	beqz	a5,80006600 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	628080e7          	jalr	1576(ra) # 80000be4 <kalloc>
    800065c4:	85aa                	mv	a1,a0
    800065c6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065ca:	cd11                	beqz	a0,800065e6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065cc:	6605                	lui	a2,0x1
    800065ce:	e3043503          	ld	a0,-464(s0)
    800065d2:	ffffd097          	auipc	ra,0xffffd
    800065d6:	f92080e7          	jalr	-110(ra) # 80003564 <fetchstr>
    800065da:	00054663          	bltz	a0,800065e6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800065de:	0905                	addi	s2,s2,1
    800065e0:	09a1                	addi	s3,s3,8
    800065e2:	fb491be3          	bne	s2,s4,80006598 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065e6:	f4040913          	addi	s2,s0,-192
    800065ea:	6088                	ld	a0,0(s1)
    800065ec:	c539                	beqz	a0,8000663a <sys_exec+0xfa>
    kfree(argv[i]);
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	472080e7          	jalr	1138(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065f6:	04a1                	addi	s1,s1,8
    800065f8:	ff2499e3          	bne	s1,s2,800065ea <sys_exec+0xaa>
  return -1;
    800065fc:	557d                	li	a0,-1
    800065fe:	a83d                	j	8000663c <sys_exec+0xfc>
      argv[i] = 0;
    80006600:	0a8e                	slli	s5,s5,0x3
    80006602:	fc0a8793          	addi	a5,s5,-64
    80006606:	00878ab3          	add	s5,a5,s0
    8000660a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000660e:	e4040593          	addi	a1,s0,-448
    80006612:	f4040513          	addi	a0,s0,-192
    80006616:	fffff097          	auipc	ra,0xfffff
    8000661a:	16e080e7          	jalr	366(ra) # 80005784 <exec>
    8000661e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006620:	f4040993          	addi	s3,s0,-192
    80006624:	6088                	ld	a0,0(s1)
    80006626:	c901                	beqz	a0,80006636 <sys_exec+0xf6>
    kfree(argv[i]);
    80006628:	ffffa097          	auipc	ra,0xffffa
    8000662c:	438080e7          	jalr	1080(ra) # 80000a60 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006630:	04a1                	addi	s1,s1,8
    80006632:	ff3499e3          	bne	s1,s3,80006624 <sys_exec+0xe4>
  return ret;
    80006636:	854a                	mv	a0,s2
    80006638:	a011                	j	8000663c <sys_exec+0xfc>
  return -1;
    8000663a:	557d                	li	a0,-1
}
    8000663c:	60be                	ld	ra,456(sp)
    8000663e:	641e                	ld	s0,448(sp)
    80006640:	74fa                	ld	s1,440(sp)
    80006642:	795a                	ld	s2,432(sp)
    80006644:	79ba                	ld	s3,424(sp)
    80006646:	7a1a                	ld	s4,416(sp)
    80006648:	6afa                	ld	s5,408(sp)
    8000664a:	6179                	addi	sp,sp,464
    8000664c:	8082                	ret

000000008000664e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000664e:	7139                	addi	sp,sp,-64
    80006650:	fc06                	sd	ra,56(sp)
    80006652:	f822                	sd	s0,48(sp)
    80006654:	f426                	sd	s1,40(sp)
    80006656:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006658:	ffffb097          	auipc	ra,0xffffb
    8000665c:	4a4080e7          	jalr	1188(ra) # 80001afc <myproc>
    80006660:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006662:	fd840593          	addi	a1,s0,-40
    80006666:	4501                	li	a0,0
    80006668:	ffffd097          	auipc	ra,0xffffd
    8000666c:	f6a080e7          	jalr	-150(ra) # 800035d2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006670:	fc840593          	addi	a1,s0,-56
    80006674:	fd040513          	addi	a0,s0,-48
    80006678:	fffff097          	auipc	ra,0xfffff
    8000667c:	dc2080e7          	jalr	-574(ra) # 8000543a <pipealloc>
    return -1;
    80006680:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006682:	0c054463          	bltz	a0,8000674a <sys_pipe+0xfc>
  fd0 = -1;
    80006686:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000668a:	fd043503          	ld	a0,-48(s0)
    8000668e:	fffff097          	auipc	ra,0xfffff
    80006692:	514080e7          	jalr	1300(ra) # 80005ba2 <fdalloc>
    80006696:	fca42223          	sw	a0,-60(s0)
    8000669a:	08054b63          	bltz	a0,80006730 <sys_pipe+0xe2>
    8000669e:	fc843503          	ld	a0,-56(s0)
    800066a2:	fffff097          	auipc	ra,0xfffff
    800066a6:	500080e7          	jalr	1280(ra) # 80005ba2 <fdalloc>
    800066aa:	fca42023          	sw	a0,-64(s0)
    800066ae:	06054863          	bltz	a0,8000671e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066b2:	4691                	li	a3,4
    800066b4:	fc440613          	addi	a2,s0,-60
    800066b8:	fd843583          	ld	a1,-40(s0)
    800066bc:	70a8                	ld	a0,96(s1)
    800066be:	ffffb097          	auipc	ra,0xffffb
    800066c2:	0ca080e7          	jalr	202(ra) # 80001788 <copyout>
    800066c6:	02054063          	bltz	a0,800066e6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066ca:	4691                	li	a3,4
    800066cc:	fc040613          	addi	a2,s0,-64
    800066d0:	fd843583          	ld	a1,-40(s0)
    800066d4:	0591                	addi	a1,a1,4
    800066d6:	70a8                	ld	a0,96(s1)
    800066d8:	ffffb097          	auipc	ra,0xffffb
    800066dc:	0b0080e7          	jalr	176(ra) # 80001788 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066e0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066e2:	06055463          	bgez	a0,8000674a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800066e6:	fc442783          	lw	a5,-60(s0)
    800066ea:	07f1                	addi	a5,a5,28
    800066ec:	078e                	slli	a5,a5,0x3
    800066ee:	97a6                	add	a5,a5,s1
    800066f0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800066f4:	fc042783          	lw	a5,-64(s0)
    800066f8:	07f1                	addi	a5,a5,28
    800066fa:	078e                	slli	a5,a5,0x3
    800066fc:	94be                	add	s1,s1,a5
    800066fe:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006702:	fd043503          	ld	a0,-48(s0)
    80006706:	fffff097          	auipc	ra,0xfffff
    8000670a:	a04080e7          	jalr	-1532(ra) # 8000510a <fileclose>
    fileclose(wf);
    8000670e:	fc843503          	ld	a0,-56(s0)
    80006712:	fffff097          	auipc	ra,0xfffff
    80006716:	9f8080e7          	jalr	-1544(ra) # 8000510a <fileclose>
    return -1;
    8000671a:	57fd                	li	a5,-1
    8000671c:	a03d                	j	8000674a <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000671e:	fc442783          	lw	a5,-60(s0)
    80006722:	0007c763          	bltz	a5,80006730 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006726:	07f1                	addi	a5,a5,28
    80006728:	078e                	slli	a5,a5,0x3
    8000672a:	97a6                	add	a5,a5,s1
    8000672c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006730:	fd043503          	ld	a0,-48(s0)
    80006734:	fffff097          	auipc	ra,0xfffff
    80006738:	9d6080e7          	jalr	-1578(ra) # 8000510a <fileclose>
    fileclose(wf);
    8000673c:	fc843503          	ld	a0,-56(s0)
    80006740:	fffff097          	auipc	ra,0xfffff
    80006744:	9ca080e7          	jalr	-1590(ra) # 8000510a <fileclose>
    return -1;
    80006748:	57fd                	li	a5,-1
}
    8000674a:	853e                	mv	a0,a5
    8000674c:	70e2                	ld	ra,56(sp)
    8000674e:	7442                	ld	s0,48(sp)
    80006750:	74a2                	ld	s1,40(sp)
    80006752:	6121                	addi	sp,sp,64
    80006754:	8082                	ret
	...

0000000080006760 <kernelvec>:
    80006760:	7111                	addi	sp,sp,-256
    80006762:	e006                	sd	ra,0(sp)
    80006764:	e40a                	sd	sp,8(sp)
    80006766:	e80e                	sd	gp,16(sp)
    80006768:	ec12                	sd	tp,24(sp)
    8000676a:	f016                	sd	t0,32(sp)
    8000676c:	f41a                	sd	t1,40(sp)
    8000676e:	f81e                	sd	t2,48(sp)
    80006770:	fc22                	sd	s0,56(sp)
    80006772:	e0a6                	sd	s1,64(sp)
    80006774:	e4aa                	sd	a0,72(sp)
    80006776:	e8ae                	sd	a1,80(sp)
    80006778:	ecb2                	sd	a2,88(sp)
    8000677a:	f0b6                	sd	a3,96(sp)
    8000677c:	f4ba                	sd	a4,104(sp)
    8000677e:	f8be                	sd	a5,112(sp)
    80006780:	fcc2                	sd	a6,120(sp)
    80006782:	e146                	sd	a7,128(sp)
    80006784:	e54a                	sd	s2,136(sp)
    80006786:	e94e                	sd	s3,144(sp)
    80006788:	ed52                	sd	s4,152(sp)
    8000678a:	f156                	sd	s5,160(sp)
    8000678c:	f55a                	sd	s6,168(sp)
    8000678e:	f95e                	sd	s7,176(sp)
    80006790:	fd62                	sd	s8,184(sp)
    80006792:	e1e6                	sd	s9,192(sp)
    80006794:	e5ea                	sd	s10,200(sp)
    80006796:	e9ee                	sd	s11,208(sp)
    80006798:	edf2                	sd	t3,216(sp)
    8000679a:	f1f6                	sd	t4,224(sp)
    8000679c:	f5fa                	sd	t5,232(sp)
    8000679e:	f9fe                	sd	t6,240(sp)
    800067a0:	a29fc0ef          	jal	ra,800031c8 <kerneltrap>
    800067a4:	6082                	ld	ra,0(sp)
    800067a6:	6122                	ld	sp,8(sp)
    800067a8:	61c2                	ld	gp,16(sp)
    800067aa:	7282                	ld	t0,32(sp)
    800067ac:	7322                	ld	t1,40(sp)
    800067ae:	73c2                	ld	t2,48(sp)
    800067b0:	7462                	ld	s0,56(sp)
    800067b2:	6486                	ld	s1,64(sp)
    800067b4:	6526                	ld	a0,72(sp)
    800067b6:	65c6                	ld	a1,80(sp)
    800067b8:	6666                	ld	a2,88(sp)
    800067ba:	7686                	ld	a3,96(sp)
    800067bc:	7726                	ld	a4,104(sp)
    800067be:	77c6                	ld	a5,112(sp)
    800067c0:	7866                	ld	a6,120(sp)
    800067c2:	688a                	ld	a7,128(sp)
    800067c4:	692a                	ld	s2,136(sp)
    800067c6:	69ca                	ld	s3,144(sp)
    800067c8:	6a6a                	ld	s4,152(sp)
    800067ca:	7a8a                	ld	s5,160(sp)
    800067cc:	7b2a                	ld	s6,168(sp)
    800067ce:	7bca                	ld	s7,176(sp)
    800067d0:	7c6a                	ld	s8,184(sp)
    800067d2:	6c8e                	ld	s9,192(sp)
    800067d4:	6d2e                	ld	s10,200(sp)
    800067d6:	6dce                	ld	s11,208(sp)
    800067d8:	6e6e                	ld	t3,216(sp)
    800067da:	7e8e                	ld	t4,224(sp)
    800067dc:	7f2e                	ld	t5,232(sp)
    800067de:	7fce                	ld	t6,240(sp)
    800067e0:	6111                	addi	sp,sp,256
    800067e2:	10200073          	sret
    800067e6:	00000013          	nop
    800067ea:	00000013          	nop
    800067ee:	0001                	nop

00000000800067f0 <timervec>:
    800067f0:	34051573          	csrrw	a0,mscratch,a0
    800067f4:	e10c                	sd	a1,0(a0)
    800067f6:	e510                	sd	a2,8(a0)
    800067f8:	e914                	sd	a3,16(a0)
    800067fa:	6d0c                	ld	a1,24(a0)
    800067fc:	7110                	ld	a2,32(a0)
    800067fe:	6194                	ld	a3,0(a1)
    80006800:	96b2                	add	a3,a3,a2
    80006802:	e194                	sd	a3,0(a1)
    80006804:	4589                	li	a1,2
    80006806:	14459073          	csrw	sip,a1
    8000680a:	6914                	ld	a3,16(a0)
    8000680c:	6510                	ld	a2,8(a0)
    8000680e:	610c                	ld	a1,0(a0)
    80006810:	34051573          	csrrw	a0,mscratch,a0
    80006814:	30200073          	mret
	...

000000008000681a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000681a:	1141                	addi	sp,sp,-16
    8000681c:	e422                	sd	s0,8(sp)
    8000681e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006820:	0c0007b7          	lui	a5,0xc000
    80006824:	4705                	li	a4,1
    80006826:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006828:	c3d8                	sw	a4,4(a5)
}
    8000682a:	6422                	ld	s0,8(sp)
    8000682c:	0141                	addi	sp,sp,16
    8000682e:	8082                	ret

0000000080006830 <plicinithart>:

void
plicinithart(void)
{
    80006830:	1141                	addi	sp,sp,-16
    80006832:	e406                	sd	ra,8(sp)
    80006834:	e022                	sd	s0,0(sp)
    80006836:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006838:	ffffb097          	auipc	ra,0xffffb
    8000683c:	298080e7          	jalr	664(ra) # 80001ad0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006840:	0085171b          	slliw	a4,a0,0x8
    80006844:	0c0027b7          	lui	a5,0xc002
    80006848:	97ba                	add	a5,a5,a4
    8000684a:	40200713          	li	a4,1026
    8000684e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006852:	00d5151b          	slliw	a0,a0,0xd
    80006856:	0c2017b7          	lui	a5,0xc201
    8000685a:	97aa                	add	a5,a5,a0
    8000685c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006860:	60a2                	ld	ra,8(sp)
    80006862:	6402                	ld	s0,0(sp)
    80006864:	0141                	addi	sp,sp,16
    80006866:	8082                	ret

0000000080006868 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006868:	1141                	addi	sp,sp,-16
    8000686a:	e406                	sd	ra,8(sp)
    8000686c:	e022                	sd	s0,0(sp)
    8000686e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006870:	ffffb097          	auipc	ra,0xffffb
    80006874:	260080e7          	jalr	608(ra) # 80001ad0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006878:	00d5151b          	slliw	a0,a0,0xd
    8000687c:	0c2017b7          	lui	a5,0xc201
    80006880:	97aa                	add	a5,a5,a0
  return irq;
}
    80006882:	43c8                	lw	a0,4(a5)
    80006884:	60a2                	ld	ra,8(sp)
    80006886:	6402                	ld	s0,0(sp)
    80006888:	0141                	addi	sp,sp,16
    8000688a:	8082                	ret

000000008000688c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000688c:	1101                	addi	sp,sp,-32
    8000688e:	ec06                	sd	ra,24(sp)
    80006890:	e822                	sd	s0,16(sp)
    80006892:	e426                	sd	s1,8(sp)
    80006894:	1000                	addi	s0,sp,32
    80006896:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006898:	ffffb097          	auipc	ra,0xffffb
    8000689c:	238080e7          	jalr	568(ra) # 80001ad0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068a0:	00d5151b          	slliw	a0,a0,0xd
    800068a4:	0c2017b7          	lui	a5,0xc201
    800068a8:	97aa                	add	a5,a5,a0
    800068aa:	c3c4                	sw	s1,4(a5)
}
    800068ac:	60e2                	ld	ra,24(sp)
    800068ae:	6442                	ld	s0,16(sp)
    800068b0:	64a2                	ld	s1,8(sp)
    800068b2:	6105                	addi	sp,sp,32
    800068b4:	8082                	ret

00000000800068b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068b6:	1141                	addi	sp,sp,-16
    800068b8:	e406                	sd	ra,8(sp)
    800068ba:	e022                	sd	s0,0(sp)
    800068bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068be:	479d                	li	a5,7
    800068c0:	04a7cc63          	blt	a5,a0,80006918 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800068c4:	0023f797          	auipc	a5,0x23f
    800068c8:	eac78793          	addi	a5,a5,-340 # 80245770 <disk>
    800068cc:	97aa                	add	a5,a5,a0
    800068ce:	0187c783          	lbu	a5,24(a5)
    800068d2:	ebb9                	bnez	a5,80006928 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068d4:	00451693          	slli	a3,a0,0x4
    800068d8:	0023f797          	auipc	a5,0x23f
    800068dc:	e9878793          	addi	a5,a5,-360 # 80245770 <disk>
    800068e0:	6398                	ld	a4,0(a5)
    800068e2:	9736                	add	a4,a4,a3
    800068e4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800068e8:	6398                	ld	a4,0(a5)
    800068ea:	9736                	add	a4,a4,a3
    800068ec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800068f0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800068f4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800068f8:	97aa                	add	a5,a5,a0
    800068fa:	4705                	li	a4,1
    800068fc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006900:	0023f517          	auipc	a0,0x23f
    80006904:	e8850513          	addi	a0,a0,-376 # 80245788 <disk+0x18>
    80006908:	ffffc097          	auipc	ra,0xffffc
    8000690c:	c7c080e7          	jalr	-900(ra) # 80002584 <wakeup>
}
    80006910:	60a2                	ld	ra,8(sp)
    80006912:	6402                	ld	s0,0(sp)
    80006914:	0141                	addi	sp,sp,16
    80006916:	8082                	ret
    panic("free_desc 1");
    80006918:	00002517          	auipc	a0,0x2
    8000691c:	0d850513          	addi	a0,a0,216 # 800089f0 <syscall_list+0x300>
    80006920:	ffffa097          	auipc	ra,0xffffa
    80006924:	c20080e7          	jalr	-992(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006928:	00002517          	auipc	a0,0x2
    8000692c:	0d850513          	addi	a0,a0,216 # 80008a00 <syscall_list+0x310>
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	c10080e7          	jalr	-1008(ra) # 80000540 <panic>

0000000080006938 <virtio_disk_init>:
{
    80006938:	1101                	addi	sp,sp,-32
    8000693a:	ec06                	sd	ra,24(sp)
    8000693c:	e822                	sd	s0,16(sp)
    8000693e:	e426                	sd	s1,8(sp)
    80006940:	e04a                	sd	s2,0(sp)
    80006942:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006944:	00002597          	auipc	a1,0x2
    80006948:	0cc58593          	addi	a1,a1,204 # 80008a10 <syscall_list+0x320>
    8000694c:	0023f517          	auipc	a0,0x23f
    80006950:	f4c50513          	addi	a0,a0,-180 # 80245898 <disk+0x128>
    80006954:	ffffa097          	auipc	ra,0xffffa
    80006958:	328080e7          	jalr	808(ra) # 80000c7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000695c:	100017b7          	lui	a5,0x10001
    80006960:	4398                	lw	a4,0(a5)
    80006962:	2701                	sext.w	a4,a4
    80006964:	747277b7          	lui	a5,0x74727
    80006968:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000696c:	14f71b63          	bne	a4,a5,80006ac2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006970:	100017b7          	lui	a5,0x10001
    80006974:	43dc                	lw	a5,4(a5)
    80006976:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006978:	4709                	li	a4,2
    8000697a:	14e79463          	bne	a5,a4,80006ac2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000697e:	100017b7          	lui	a5,0x10001
    80006982:	479c                	lw	a5,8(a5)
    80006984:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006986:	12e79e63          	bne	a5,a4,80006ac2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000698a:	100017b7          	lui	a5,0x10001
    8000698e:	47d8                	lw	a4,12(a5)
    80006990:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006992:	554d47b7          	lui	a5,0x554d4
    80006996:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000699a:	12f71463          	bne	a4,a5,80006ac2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000699e:	100017b7          	lui	a5,0x10001
    800069a2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069a6:	4705                	li	a4,1
    800069a8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069aa:	470d                	li	a4,3
    800069ac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800069ae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069b0:	c7ffe6b7          	lui	a3,0xc7ffe
    800069b4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47db8eaf>
    800069b8:	8f75                	and	a4,a4,a3
    800069ba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069bc:	472d                	li	a4,11
    800069be:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800069c0:	5bbc                	lw	a5,112(a5)
    800069c2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800069c6:	8ba1                	andi	a5,a5,8
    800069c8:	10078563          	beqz	a5,80006ad2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069cc:	100017b7          	lui	a5,0x10001
    800069d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800069d4:	43fc                	lw	a5,68(a5)
    800069d6:	2781                	sext.w	a5,a5
    800069d8:	10079563          	bnez	a5,80006ae2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069dc:	100017b7          	lui	a5,0x10001
    800069e0:	5bdc                	lw	a5,52(a5)
    800069e2:	2781                	sext.w	a5,a5
  if(max == 0)
    800069e4:	10078763          	beqz	a5,80006af2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800069e8:	471d                	li	a4,7
    800069ea:	10f77c63          	bgeu	a4,a5,80006b02 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800069ee:	ffffa097          	auipc	ra,0xffffa
    800069f2:	1f6080e7          	jalr	502(ra) # 80000be4 <kalloc>
    800069f6:	0023f497          	auipc	s1,0x23f
    800069fa:	d7a48493          	addi	s1,s1,-646 # 80245770 <disk>
    800069fe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006a00:	ffffa097          	auipc	ra,0xffffa
    80006a04:	1e4080e7          	jalr	484(ra) # 80000be4 <kalloc>
    80006a08:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006a0a:	ffffa097          	auipc	ra,0xffffa
    80006a0e:	1da080e7          	jalr	474(ra) # 80000be4 <kalloc>
    80006a12:	87aa                	mv	a5,a0
    80006a14:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006a16:	6088                	ld	a0,0(s1)
    80006a18:	cd6d                	beqz	a0,80006b12 <virtio_disk_init+0x1da>
    80006a1a:	0023f717          	auipc	a4,0x23f
    80006a1e:	d5e73703          	ld	a4,-674(a4) # 80245778 <disk+0x8>
    80006a22:	cb65                	beqz	a4,80006b12 <virtio_disk_init+0x1da>
    80006a24:	c7fd                	beqz	a5,80006b12 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006a26:	6605                	lui	a2,0x1
    80006a28:	4581                	li	a1,0
    80006a2a:	ffffa097          	auipc	ra,0xffffa
    80006a2e:	3de080e7          	jalr	990(ra) # 80000e08 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a32:	0023f497          	auipc	s1,0x23f
    80006a36:	d3e48493          	addi	s1,s1,-706 # 80245770 <disk>
    80006a3a:	6605                	lui	a2,0x1
    80006a3c:	4581                	li	a1,0
    80006a3e:	6488                	ld	a0,8(s1)
    80006a40:	ffffa097          	auipc	ra,0xffffa
    80006a44:	3c8080e7          	jalr	968(ra) # 80000e08 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a48:	6605                	lui	a2,0x1
    80006a4a:	4581                	li	a1,0
    80006a4c:	6888                	ld	a0,16(s1)
    80006a4e:	ffffa097          	auipc	ra,0xffffa
    80006a52:	3ba080e7          	jalr	954(ra) # 80000e08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a56:	100017b7          	lui	a5,0x10001
    80006a5a:	4721                	li	a4,8
    80006a5c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006a5e:	4098                	lw	a4,0(s1)
    80006a60:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006a64:	40d8                	lw	a4,4(s1)
    80006a66:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006a6a:	6498                	ld	a4,8(s1)
    80006a6c:	0007069b          	sext.w	a3,a4
    80006a70:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006a74:	9701                	srai	a4,a4,0x20
    80006a76:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006a7a:	6898                	ld	a4,16(s1)
    80006a7c:	0007069b          	sext.w	a3,a4
    80006a80:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006a84:	9701                	srai	a4,a4,0x20
    80006a86:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006a8a:	4705                	li	a4,1
    80006a8c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006a8e:	00e48c23          	sb	a4,24(s1)
    80006a92:	00e48ca3          	sb	a4,25(s1)
    80006a96:	00e48d23          	sb	a4,26(s1)
    80006a9a:	00e48da3          	sb	a4,27(s1)
    80006a9e:	00e48e23          	sb	a4,28(s1)
    80006aa2:	00e48ea3          	sb	a4,29(s1)
    80006aa6:	00e48f23          	sb	a4,30(s1)
    80006aaa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006aae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ab2:	0727a823          	sw	s2,112(a5)
}
    80006ab6:	60e2                	ld	ra,24(sp)
    80006ab8:	6442                	ld	s0,16(sp)
    80006aba:	64a2                	ld	s1,8(sp)
    80006abc:	6902                	ld	s2,0(sp)
    80006abe:	6105                	addi	sp,sp,32
    80006ac0:	8082                	ret
    panic("could not find virtio disk");
    80006ac2:	00002517          	auipc	a0,0x2
    80006ac6:	f5e50513          	addi	a0,a0,-162 # 80008a20 <syscall_list+0x330>
    80006aca:	ffffa097          	auipc	ra,0xffffa
    80006ace:	a76080e7          	jalr	-1418(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ad2:	00002517          	auipc	a0,0x2
    80006ad6:	f6e50513          	addi	a0,a0,-146 # 80008a40 <syscall_list+0x350>
    80006ada:	ffffa097          	auipc	ra,0xffffa
    80006ade:	a66080e7          	jalr	-1434(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006ae2:	00002517          	auipc	a0,0x2
    80006ae6:	f7e50513          	addi	a0,a0,-130 # 80008a60 <syscall_list+0x370>
    80006aea:	ffffa097          	auipc	ra,0xffffa
    80006aee:	a56080e7          	jalr	-1450(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006af2:	00002517          	auipc	a0,0x2
    80006af6:	f8e50513          	addi	a0,a0,-114 # 80008a80 <syscall_list+0x390>
    80006afa:	ffffa097          	auipc	ra,0xffffa
    80006afe:	a46080e7          	jalr	-1466(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006b02:	00002517          	auipc	a0,0x2
    80006b06:	f9e50513          	addi	a0,a0,-98 # 80008aa0 <syscall_list+0x3b0>
    80006b0a:	ffffa097          	auipc	ra,0xffffa
    80006b0e:	a36080e7          	jalr	-1482(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006b12:	00002517          	auipc	a0,0x2
    80006b16:	fae50513          	addi	a0,a0,-82 # 80008ac0 <syscall_list+0x3d0>
    80006b1a:	ffffa097          	auipc	ra,0xffffa
    80006b1e:	a26080e7          	jalr	-1498(ra) # 80000540 <panic>

0000000080006b22 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b22:	7119                	addi	sp,sp,-128
    80006b24:	fc86                	sd	ra,120(sp)
    80006b26:	f8a2                	sd	s0,112(sp)
    80006b28:	f4a6                	sd	s1,104(sp)
    80006b2a:	f0ca                	sd	s2,96(sp)
    80006b2c:	ecce                	sd	s3,88(sp)
    80006b2e:	e8d2                	sd	s4,80(sp)
    80006b30:	e4d6                	sd	s5,72(sp)
    80006b32:	e0da                	sd	s6,64(sp)
    80006b34:	fc5e                	sd	s7,56(sp)
    80006b36:	f862                	sd	s8,48(sp)
    80006b38:	f466                	sd	s9,40(sp)
    80006b3a:	f06a                	sd	s10,32(sp)
    80006b3c:	ec6e                	sd	s11,24(sp)
    80006b3e:	0100                	addi	s0,sp,128
    80006b40:	8aaa                	mv	s5,a0
    80006b42:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b44:	00c52d03          	lw	s10,12(a0)
    80006b48:	001d1d1b          	slliw	s10,s10,0x1
    80006b4c:	1d02                	slli	s10,s10,0x20
    80006b4e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006b52:	0023f517          	auipc	a0,0x23f
    80006b56:	d4650513          	addi	a0,a0,-698 # 80245898 <disk+0x128>
    80006b5a:	ffffa097          	auipc	ra,0xffffa
    80006b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <acquire>
  for(int i = 0; i < 3; i++){
    80006b62:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b64:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006b66:	0023fb97          	auipc	s7,0x23f
    80006b6a:	c0ab8b93          	addi	s7,s7,-1014 # 80245770 <disk>
  for(int i = 0; i < 3; i++){
    80006b6e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b70:	0023fc97          	auipc	s9,0x23f
    80006b74:	d28c8c93          	addi	s9,s9,-728 # 80245898 <disk+0x128>
    80006b78:	a08d                	j	80006bda <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006b7a:	00fb8733          	add	a4,s7,a5
    80006b7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006b82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006b84:	0207c563          	bltz	a5,80006bae <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006b88:	2905                	addiw	s2,s2,1
    80006b8a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006b8c:	05690c63          	beq	s2,s6,80006be4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006b90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006b92:	0023f717          	auipc	a4,0x23f
    80006b96:	bde70713          	addi	a4,a4,-1058 # 80245770 <disk>
    80006b9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006b9c:	01874683          	lbu	a3,24(a4)
    80006ba0:	fee9                	bnez	a3,80006b7a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006ba2:	2785                	addiw	a5,a5,1
    80006ba4:	0705                	addi	a4,a4,1
    80006ba6:	fe979be3          	bne	a5,s1,80006b9c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006baa:	57fd                	li	a5,-1
    80006bac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006bae:	01205d63          	blez	s2,80006bc8 <virtio_disk_rw+0xa6>
    80006bb2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006bb4:	000a2503          	lw	a0,0(s4)
    80006bb8:	00000097          	auipc	ra,0x0
    80006bbc:	cfe080e7          	jalr	-770(ra) # 800068b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006bc0:	2d85                	addiw	s11,s11,1
    80006bc2:	0a11                	addi	s4,s4,4
    80006bc4:	ff2d98e3          	bne	s11,s2,80006bb4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bc8:	85e6                	mv	a1,s9
    80006bca:	0023f517          	auipc	a0,0x23f
    80006bce:	bbe50513          	addi	a0,a0,-1090 # 80245788 <disk+0x18>
    80006bd2:	ffffc097          	auipc	ra,0xffffc
    80006bd6:	94e080e7          	jalr	-1714(ra) # 80002520 <sleep>
  for(int i = 0; i < 3; i++){
    80006bda:	f8040a13          	addi	s4,s0,-128
{
    80006bde:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006be0:	894e                	mv	s2,s3
    80006be2:	b77d                	j	80006b90 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006be4:	f8042503          	lw	a0,-128(s0)
    80006be8:	00a50713          	addi	a4,a0,10
    80006bec:	0712                	slli	a4,a4,0x4

  if(write)
    80006bee:	0023f797          	auipc	a5,0x23f
    80006bf2:	b8278793          	addi	a5,a5,-1150 # 80245770 <disk>
    80006bf6:	00e786b3          	add	a3,a5,a4
    80006bfa:	01803633          	snez	a2,s8
    80006bfe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c00:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006c04:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c08:	f6070613          	addi	a2,a4,-160
    80006c0c:	6394                	ld	a3,0(a5)
    80006c0e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c10:	00870593          	addi	a1,a4,8
    80006c14:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c16:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c18:	0007b803          	ld	a6,0(a5)
    80006c1c:	9642                	add	a2,a2,a6
    80006c1e:	46c1                	li	a3,16
    80006c20:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c22:	4585                	li	a1,1
    80006c24:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006c28:	f8442683          	lw	a3,-124(s0)
    80006c2c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c30:	0692                	slli	a3,a3,0x4
    80006c32:	9836                	add	a6,a6,a3
    80006c34:	058a8613          	addi	a2,s5,88
    80006c38:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006c3c:	0007b803          	ld	a6,0(a5)
    80006c40:	96c2                	add	a3,a3,a6
    80006c42:	40000613          	li	a2,1024
    80006c46:	c690                	sw	a2,8(a3)
  if(write)
    80006c48:	001c3613          	seqz	a2,s8
    80006c4c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c50:	00166613          	ori	a2,a2,1
    80006c54:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c58:	f8842603          	lw	a2,-120(s0)
    80006c5c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c60:	00250693          	addi	a3,a0,2
    80006c64:	0692                	slli	a3,a3,0x4
    80006c66:	96be                	add	a3,a3,a5
    80006c68:	58fd                	li	a7,-1
    80006c6a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c6e:	0612                	slli	a2,a2,0x4
    80006c70:	9832                	add	a6,a6,a2
    80006c72:	f9070713          	addi	a4,a4,-112
    80006c76:	973e                	add	a4,a4,a5
    80006c78:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006c7c:	6398                	ld	a4,0(a5)
    80006c7e:	9732                	add	a4,a4,a2
    80006c80:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c82:	4609                	li	a2,2
    80006c84:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006c88:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c8c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006c90:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c94:	6794                	ld	a3,8(a5)
    80006c96:	0026d703          	lhu	a4,2(a3)
    80006c9a:	8b1d                	andi	a4,a4,7
    80006c9c:	0706                	slli	a4,a4,0x1
    80006c9e:	96ba                	add	a3,a3,a4
    80006ca0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006ca4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ca8:	6798                	ld	a4,8(a5)
    80006caa:	00275783          	lhu	a5,2(a4)
    80006cae:	2785                	addiw	a5,a5,1
    80006cb0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cb4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cb8:	100017b7          	lui	a5,0x10001
    80006cbc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cc0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006cc4:	0023f917          	auipc	s2,0x23f
    80006cc8:	bd490913          	addi	s2,s2,-1068 # 80245898 <disk+0x128>
  while(b->disk == 1) {
    80006ccc:	4485                	li	s1,1
    80006cce:	00b79c63          	bne	a5,a1,80006ce6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006cd2:	85ca                	mv	a1,s2
    80006cd4:	8556                	mv	a0,s5
    80006cd6:	ffffc097          	auipc	ra,0xffffc
    80006cda:	84a080e7          	jalr	-1974(ra) # 80002520 <sleep>
  while(b->disk == 1) {
    80006cde:	004aa783          	lw	a5,4(s5)
    80006ce2:	fe9788e3          	beq	a5,s1,80006cd2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006ce6:	f8042903          	lw	s2,-128(s0)
    80006cea:	00290713          	addi	a4,s2,2
    80006cee:	0712                	slli	a4,a4,0x4
    80006cf0:	0023f797          	auipc	a5,0x23f
    80006cf4:	a8078793          	addi	a5,a5,-1408 # 80245770 <disk>
    80006cf8:	97ba                	add	a5,a5,a4
    80006cfa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006cfe:	0023f997          	auipc	s3,0x23f
    80006d02:	a7298993          	addi	s3,s3,-1422 # 80245770 <disk>
    80006d06:	00491713          	slli	a4,s2,0x4
    80006d0a:	0009b783          	ld	a5,0(s3)
    80006d0e:	97ba                	add	a5,a5,a4
    80006d10:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d14:	854a                	mv	a0,s2
    80006d16:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d1a:	00000097          	auipc	ra,0x0
    80006d1e:	b9c080e7          	jalr	-1124(ra) # 800068b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d22:	8885                	andi	s1,s1,1
    80006d24:	f0ed                	bnez	s1,80006d06 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d26:	0023f517          	auipc	a0,0x23f
    80006d2a:	b7250513          	addi	a0,a0,-1166 # 80245898 <disk+0x128>
    80006d2e:	ffffa097          	auipc	ra,0xffffa
    80006d32:	092080e7          	jalr	146(ra) # 80000dc0 <release>
}
    80006d36:	70e6                	ld	ra,120(sp)
    80006d38:	7446                	ld	s0,112(sp)
    80006d3a:	74a6                	ld	s1,104(sp)
    80006d3c:	7906                	ld	s2,96(sp)
    80006d3e:	69e6                	ld	s3,88(sp)
    80006d40:	6a46                	ld	s4,80(sp)
    80006d42:	6aa6                	ld	s5,72(sp)
    80006d44:	6b06                	ld	s6,64(sp)
    80006d46:	7be2                	ld	s7,56(sp)
    80006d48:	7c42                	ld	s8,48(sp)
    80006d4a:	7ca2                	ld	s9,40(sp)
    80006d4c:	7d02                	ld	s10,32(sp)
    80006d4e:	6de2                	ld	s11,24(sp)
    80006d50:	6109                	addi	sp,sp,128
    80006d52:	8082                	ret

0000000080006d54 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d54:	1101                	addi	sp,sp,-32
    80006d56:	ec06                	sd	ra,24(sp)
    80006d58:	e822                	sd	s0,16(sp)
    80006d5a:	e426                	sd	s1,8(sp)
    80006d5c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d5e:	0023f497          	auipc	s1,0x23f
    80006d62:	a1248493          	addi	s1,s1,-1518 # 80245770 <disk>
    80006d66:	0023f517          	auipc	a0,0x23f
    80006d6a:	b3250513          	addi	a0,a0,-1230 # 80245898 <disk+0x128>
    80006d6e:	ffffa097          	auipc	ra,0xffffa
    80006d72:	f9e080e7          	jalr	-98(ra) # 80000d0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d76:	10001737          	lui	a4,0x10001
    80006d7a:	533c                	lw	a5,96(a4)
    80006d7c:	8b8d                	andi	a5,a5,3
    80006d7e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006d80:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d84:	689c                	ld	a5,16(s1)
    80006d86:	0204d703          	lhu	a4,32(s1)
    80006d8a:	0027d783          	lhu	a5,2(a5)
    80006d8e:	04f70863          	beq	a4,a5,80006dde <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006d92:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d96:	6898                	ld	a4,16(s1)
    80006d98:	0204d783          	lhu	a5,32(s1)
    80006d9c:	8b9d                	andi	a5,a5,7
    80006d9e:	078e                	slli	a5,a5,0x3
    80006da0:	97ba                	add	a5,a5,a4
    80006da2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006da4:	00278713          	addi	a4,a5,2
    80006da8:	0712                	slli	a4,a4,0x4
    80006daa:	9726                	add	a4,a4,s1
    80006dac:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006db0:	e721                	bnez	a4,80006df8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006db2:	0789                	addi	a5,a5,2
    80006db4:	0792                	slli	a5,a5,0x4
    80006db6:	97a6                	add	a5,a5,s1
    80006db8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006dba:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dbe:	ffffb097          	auipc	ra,0xffffb
    80006dc2:	7c6080e7          	jalr	1990(ra) # 80002584 <wakeup>

    disk.used_idx += 1;
    80006dc6:	0204d783          	lhu	a5,32(s1)
    80006dca:	2785                	addiw	a5,a5,1
    80006dcc:	17c2                	slli	a5,a5,0x30
    80006dce:	93c1                	srli	a5,a5,0x30
    80006dd0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006dd4:	6898                	ld	a4,16(s1)
    80006dd6:	00275703          	lhu	a4,2(a4)
    80006dda:	faf71ce3          	bne	a4,a5,80006d92 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006dde:	0023f517          	auipc	a0,0x23f
    80006de2:	aba50513          	addi	a0,a0,-1350 # 80245898 <disk+0x128>
    80006de6:	ffffa097          	auipc	ra,0xffffa
    80006dea:	fda080e7          	jalr	-38(ra) # 80000dc0 <release>
}
    80006dee:	60e2                	ld	ra,24(sp)
    80006df0:	6442                	ld	s0,16(sp)
    80006df2:	64a2                	ld	s1,8(sp)
    80006df4:	6105                	addi	sp,sp,32
    80006df6:	8082                	ret
      panic("virtio_disk_intr status");
    80006df8:	00002517          	auipc	a0,0x2
    80006dfc:	ce050513          	addi	a0,a0,-800 # 80008ad8 <syscall_list+0x3e8>
    80006e00:	ffff9097          	auipc	ra,0xffff9
    80006e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
