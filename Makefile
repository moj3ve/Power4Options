GO_EASY_ON_ME = 1
FINALPACKAGE=1
DEBUG=0

THEOS_DEVICE_IP = 172.30.1.32 -p 22

ARCHS := arm64 arm64e
TARGET := iphone:clang:13.1:7.1
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Power4Options

Power4Options_FILES = Tweak.xm
Power4Options_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
