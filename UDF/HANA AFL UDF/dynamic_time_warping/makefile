all: libafldtw.so

libafldtw.so: dtw.o   afl_dtwIspc.o
	g++ -shared -lhdbaflsdk -Wl,-no-undefined -L/usr/sap/MIT/home/afl_sdk//libs -o $@ $^

.cpp.o: dtw.cpp afl_dtwIspc.cpp
	g++ -fPIC -Wall -O2 -g -I/usr/sap/MIT/home/afl_sdk//include -c $< -o $@

clean:
	rm -f libafldtw.so dtw.o   afl_dtwIspc.o

