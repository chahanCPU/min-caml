SLDS = contest

all: $(SLDS:%=%.ppm)

# minrt.s: 

%.ppm: minrt.s sld/%_uart.sld
	make -C ../simulator/ TESTS="../myraytracer/minrt.s $(SLDS:%=../myraytracer/sld/%_uart.sld)"
	mv minrt.s.ppm $(*:%=%.ppm)

clean:
	rm -f $(SLDS:%=%.ppm) minrt.s.binary minrt.s.bintext
