# AI Standalone Makefile
#
# 混合策略：复用原版源文件 + 提取数据表

CC = gcc
CFLAGS = -Wall -Wextra -O2 -g
CFLAGS += -I./include
CFLAGS += -DSTANDALONE_BUILD

# ============================================================================
#                           Standalone 源文件
# ============================================================================

STANDALONE_SRCS = src/ai_standalone.c

# ============================================================================
#                           复用的原版源文件
# ============================================================================

# AI 核心逻辑
VANILLA_AI_SRCS = ../src/battle_ai_script_commands.c

# 伤害计算和属性计算（包含 AI_CalcDmg, TypeCalc）
VANILLA_BATTLE_SRCS = ../src/battle_script_commands.c

# 战斗工具函数（包含 CheckMoveLimitations 等）
# VANILLA_UTIL_SRCS = ../src/battle_util.c

# 当前先添加这两个核心文件
VANILLA_SRCS = $(VANILLA_AI_SRCS) $(VANILLA_BATTLE_SRCS)

# 所有源文件
SRCS = $(STANDALONE_SRCS) $(VANILLA_SRCS)

# 目标
TARGET = ai_test.exe

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^ 2>&1 | head -100

clean:
	rm -f $(TARGET)
