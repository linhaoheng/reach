TARGET := iphone:clang:15.6:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

DEBUG=0
FINALPACKAGE=1
THEOS_PACKAGE_SCHEME=rootless

SYSROOT=$(THEOS)/sdks/iPhoneOS15.6.sdk

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachPlayer

ReachPlayer_FILES = Tweak.xm ReachPlayerContainerView.xm UIColor+Hex.m LHHNowPlayingProgressKnobView.m LHHNowPlayingProgressView.m  MSHFAudioProcessing.m MSHFAudioSource.m MSHFView.m MSHFJelloLayer.m MSHFJelloView.m
ReachPlayer_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations
ReachPlayer_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences && killall -9 SpringBoard"
SUBPROJECTS += reachplayerprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
