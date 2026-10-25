
PROJECT := Chirp
BUILD_DIR := build

NASM ?= nasm
CC_WIN ?= gcc

SHARED_SRC := shared/src
SHARED_INCLUDE := shared/include
SHARED_BUILD := $(BUILD_DIR)/shared
SHARED_SOURCES := $(wildcard $(SHARED_SRC)/*.asm)
SHARED_OBJECTS := $(patsubst $(SHARED_SRC)/%.asm,$(SHARED_BUILD)/%.o,$(SHARED_SOURCES))

CLIENT_SRC := client/src
CLIENT_BUILD := $(BUILD_DIR)/client
CLIENT_SOURCES := $(wildcard $(CLIENT_SRC)/*.asm)
CLIENT_OBJECTS := $(patsubst $(CLIENT_SRC)/%.asm,$(CLIENT_BUILD)/%.o,$(CLIENT_SOURCES))
CLIENT_TARGET := $(CLIENT_BUILD)/$(PROJECT)Client.exe

SERVER_SRC := server/src
SERVER_BUILD := $(BUILD_DIR)/server
SERVER_SOURCES := $(wildcard $(SERVER_SRC)/*.asm)
SERVER_OBJECTS := $(patsubst $(SERVER_SRC)/%.asm,$(SERVER_BUILD)/%.o,$(SERVER_SOURCES))
SERVER_TARGET := $(SERVER_BUILD)/$(PROJECT)Server.exe

.PHONY: all build client server run-client run-server clean tree check-tools

all: build

# build both
build: client server

# build client
client: check-tools $(CLIENT_TARGET)

# build server
server: check-tools $(SERVER_TARGET)

# link client
$(CLIENT_TARGET): $(CLIENT_OBJECTS) $(SHARED_OBJECTS)
	@if not exist "$(subst /,\,$(dir $@))" mkdir "$(subst /,\,$(dir $@))"
	$(CC_WIN) -o $@ $^ -lws2_32 -lkernel32

# link server
$(SERVER_TARGET): $(SERVER_OBJECTS) $(SHARED_OBJECTS)
	@if not exist "$(subst /,\,$(dir $@))" mkdir "$(subst /,\,$(dir $@))"
	$(CC_WIN) -o $@ $^ -lws2_32 -lkernel32

# assemble client
$(CLIENT_BUILD)/%.o: $(CLIENT_SRC)/%.asm
	@if not exist "$(subst /,\,$(dir $@))" mkdir "$(subst /,\,$(dir $@))"
	$(NASM) -f win64 -g -F cv8 -I$(SHARED_INCLUDE)/ -o $@ $<

# assemble server
$(SERVER_BUILD)/%.o: $(SERVER_SRC)/%.asm
	@if not exist "$(subst /,\,$(dir $@))" mkdir "$(subst /,\,$(dir $@))"
	$(NASM) -f win64 -g -F cv8 -I$(SHARED_INCLUDE)/ -o $@ $<

$(SHARED_BUILD)/%.o: $(SHARED_SRC)/%.asm
	@if not exist "$(subst /,\,$(dir $@))" mkdir "$(subst /,\,$(dir $@))"
	$(NASM) -f win64 -g -F cv8 -I$(SHARED_INCLUDE)/ -o $@ $<

run-client: client
	$(subst /,\,$(CLIENT_TARGET))

run-server: server
	$(subst /,\,$(SERVER_TARGET))

clean:
	@if exist "$(BUILD_DIR)" rmdir /s /q "$(BUILD_DIR)"

tree:
	@echo Project files:
	@dir /s /b /a-d

check-tools:
	@where $(NASM) >NUL 2>&1 || (echo Missing: $(NASM) & exit /b 1)
	@where $(CC_WIN) >NUL 2>&1 || (echo Missing: $(CC_WIN) & exit /b 1)
