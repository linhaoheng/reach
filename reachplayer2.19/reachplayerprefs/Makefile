ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

SYSROOT=$(THEOS)/sdks/iPhoneOS15.6.sdk

THEOS_PACKAGE_SCHEME=rootless

BUNDLE_NAME = reachplayerprefs
$(BUNDLE_NAME)_FILES = REACHPLAYERPreferences.m LHHSliderCell.m LHHColorPickerCell.m LHHSwitchCell.m LHHRootListController.m
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk
