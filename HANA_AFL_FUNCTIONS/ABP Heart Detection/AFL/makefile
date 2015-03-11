all: libaflmimicsignal.so

libaflmimicsignal.so: mimicsignal.o   data_cleanser.o   beat_detector.o   afl_mimicsignalIspc.o
	g++ -shared -lhdbaflsdk -Wl,-no-undefined -L/usr/sap/HF1/home/afl_sdk/libs -o $@ $^

.cpp.o: mimicsignal.cpp   data_cleanser.cpp   beat_detector.cpp   afl_mimicsignalIspc.cpp
	g++ -fPIC -Wall -O2 -g -I/usr/sap/HF1/home/afl_sdk/include -c $< -o $@

clean:
	rm -f libaflmimicsignal.so  mimicsignal.o   data_cleanser.o   beat_detection.o   afl_mimicsignalIspc.o

