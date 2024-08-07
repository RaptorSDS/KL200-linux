# Makefile for XKC_KL200 library

CXX = g++
CXXFLAGS = -std=c++11 -Wall

LIBNAME = libXKC_KL200.a
INCLUDES = -I.
SRCS = XKC_KL200.cpp
OBJS = $(SRCS:.cpp=.o)

all: $(LIBNAME) example

$(LIBNAME): $(OBJS)
	ar rcs $(LIBNAME) $(OBJS)

example: main.cpp $(LIBNAME)
	$(CXX) $(CXXFLAGS) -o example main.cpp -L. -lXKC_KL200

install: $(LIBNAME)
	mkdir -p /usr/local/include/XKC_KL200
	cp XKC_KL200.h /usr/local/include/XKC_KL200/
	cp $(LIBNAME) /usr/local/lib/

uninstall:
	rm -rf /usr/local/include/XKC_KL200
	rm -f /usr/local/lib/$(LIBNAME)

clean:
	rm -f $(OBJS) $(LIBNAME) example
