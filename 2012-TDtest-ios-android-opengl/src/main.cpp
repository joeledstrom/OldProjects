//
//  GameMain.cpp
//  TDtest
//
//  Created by Joel Edström on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#include "common.h"

#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include "Game.h"




#ifdef GDT_PLATFORM_ANDROID
double log2(double x) {
    return log(x)/log(2);
}
#endif



static shared_ptr<gdt::Application> game;


static void on_touch(touch_type_t what, int screenX, int screenY) {
    game->onTouch((gdt::touch_type_t) what, screenX, screenY);
}

void gdt_hook_initialize() {    
    
    gdt_set_callback_touch(&on_touch);
    
    game.reset(new Game());
    game->onInit();
    
}

void gdt_hook_visible(bool newContext) {
    game->onVisible(newContext);
}


void gdt_hook_render() {
    game->onRender();
}

void gdt_hook_active() {
    game->onActive();
}
void gdt_hook_inactive() {
    game->onInactive();
}
void gdt_hook_save_state() {
    game->onSaveState();
}
void gdt_hook_hidden() {
    game->onHidden();
}
