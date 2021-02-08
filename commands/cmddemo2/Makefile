# Makefile for test command.

# cross-compile gcc support.
CC=${CROSS_COMPILE}gcc
CFLAGS+=
LDFLAGS+=

# install output support.
O?=

# target command as dir name.
TARGET=$(notdir $(shell pwd))
OBJS=$(subst .c,.o,$(notdir $(wildcard *.c)))

all : $(TARGET)

# target command support.
$(TARGET) : $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@

.PHONY: clean install
# target clean support.
clean :
	@echo "clean $(TARGET)"
	@rm -f *.o
	@[ ! -f $(TARGET) ] || rm -f $(TARGET)
	@[ -z $(O) ] || [ ! -f $(O)/$(TARGET) ] || rm -f $(O)/$(TARGET)

# target install support.
install : $(TARGET)
	@echo "install $(TARGET)"
	@[ -z $(O) ] || (mkdir -p $(O) && cp $(TARGET) $(O)/)

# gcc: .c -> .o
%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@
