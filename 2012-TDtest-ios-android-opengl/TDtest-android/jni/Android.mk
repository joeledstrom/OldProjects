LOCAL_PATH := $(call my-dir)


include $(CLEAR_VARS)

LOCAL_MODULE := native

LOCAL_CFLAGS := -DANDROID_NDK -DDISABLE_IMPORTGL


LOCAL_SRC_FILES := src/MD5.cpp src/MD5Model.cpp src/ResourceManager.cpp src/GLResources.cpp src/GameMain.cpp gdt/gdt/android/gdt_android.c gdt/gdt/gdt_common.c
 

LOCAL_C_INCLUDES := $(LOCAL_PATH)/libwebp/src $(LOCAL_PATH)/gdt/include $(LOCAL_PATH)/../../cml-1_0_3

LOCAL_LDLIBS := -lGLESv2 -ldl -llog -lm

LOCAL_STATIC_LIBRARIES := webp

include $(BUILD_SHARED_LIBRARY)


include $(LOCAL_PATH)/libwebp/Android.mk
