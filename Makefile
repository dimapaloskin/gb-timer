build:
	rgbasm -o main.obj main.asm
	rgblink -m main.map -n main.sym -o main.gb main.obj
	rgbfix -p0 -v main.gb
