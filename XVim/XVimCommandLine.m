//
//  XVimCommandLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandLine.h"
#import "XVimCommandField.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "DVTKit.h"

#define COMMAND_FIELD_HEIGHT 18.0


@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSTextField* _static;
    NSTextField* _error;
    NSTextField* _argument;
    NSTimer* _errorTimer;
}
@end

@implementation XVimCommandLine
@synthesize tag = _tag;
- (id) init{
    self = [super initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
    if (self) {
        [self setBoundsOrigin:NSMakePoint(0,0)];
        
        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,100,COMMAND_FIELD_HEIGHT)];
        [_static setEditable:NO];
        [_static setBordered:NO];
        [_static setSelectable:NO];
        [[_static cell] setFocusRingType:NSFocusRingTypeNone];
        [_static setBackgroundColor:[NSColor textBackgroundColor]]; 
        [self addSubview:_static];
        
        // Error Message
        _error = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_error setEditable:NO];
        [_error setBordered:NO];
        [_error setSelectable:NO];
        [[_error cell] setFocusRingType:NSFocusRingTypeNone];
        [_error setBackgroundColor:[NSColor redColor]]; 
        [_error setHidden:YES];
        [self addSubview:_error];
        
        // Command View
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        [_command setTextColor:[NSColor textColor]];
        [_command setBackgroundColor:[NSColor textBackgroundColor]]; 
        [_command setHidden:YES];
        [self addSubview:_command];
        
		// Argument View
		_argument = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, COMMAND_FIELD_HEIGHT)];
        [_argument setEditable:NO];
        [_argument setBordered:NO];
        [_argument setSelectable:NO];
        [[_argument cell] setFocusRingType:NSFocusRingTypeNone];
        [_argument setBackgroundColor:[NSColor clearColor]];
        [self addSubview:_argument];
        
        self.tag = XVIM_CMDLINE_TAG;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontAndColorSourceTextSettingsChanged:) name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
    }
    return self;
}

- (void)dealloc{
    [_command release];
    [_static release];
    [_error release];
    [super dealloc];
}

- (void)errorMsgExpired{
    [_error setHidden:YES];
}

- (void)setModeString:(NSString*)string
{
    [_static setStringValue:string];
}

- (void)setArgumentString:(NSString*)string{
    [_argument setStringValue:string];
}

- (void)errorMessage:(NSString*)string
{
	NSString* msg = string;
	if( [msg length] != 0 ){
		[_error setStringValue:msg];
		[_error setHidden:NO];
		[_errorTimer invalidate];
		_errorTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(errorMsgExpired) userInfo:nil repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:_errorTimer forMode:NSDefaultRunLoopMode];
	}else{
		[_errorTimer invalidate];
		[_error setHidden:YES];
	}
}

- (XVimCommandField*)commandField
{
	return _command;
}

- (void)layoutCmdline:(NSView*) parent{
    NSRect frame = [parent frame];
    [NSClassFromString(@"DVTFontAndColorTheme") addObserver:self forKeyPath:@"currentTheme" options:NSKeyValueObservingOptionNew context:nil];
    [self setBoundsOrigin:NSMakePoint(0,0)];
    
    // Set colors
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    [_static setBackgroundColor:[theme sourceTextBackgroundColor]];
    [_command setTextColor:[theme sourcePlainTextColor]];
    [_command setBackgroundColor:[theme sourceTextBackgroundColor]];
    [_command setInsertionPointColor:[theme sourceTextInsertionPointColor]];
    [_argument setTextColor:[theme sourcePlainTextColor]];
	
	CGFloat argumentSize = MIN(frame.size.width, 100);
    
    // Layout command area
    [_error setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_error setFrameOrigin:NSMakePoint(0, 0)];
    [_static setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_argument setFrameSize:NSMakeSize(argumentSize, COMMAND_FIELD_HEIGHT)];
    [_argument setFrameOrigin:NSMakePoint(frame.size.width - argumentSize, 0)];
    
    NSView *border = nil;
    NSView *nsview = nil;
    for( NSView* v in [parent subviews] ){
        if( [NSStringFromClass([v class]) isEqualToString:@"DVTBorderedView"] ){
            border = v;
        }else if( [NSStringFromClass([v class]) isEqualToString:@"NSView"] ){
            nsview = v;
        }
    }
    if( nsview != nil && border != nil && [border isHidden] ){
        self.frame = NSMakeRect(0, 0, parent.frame.size.width, +COMMAND_FIELD_HEIGHT);
        nsview.frame = NSMakeRect(0, COMMAND_FIELD_HEIGHT, parent.frame.size.width, parent.frame.size.height-COMMAND_FIELD_HEIGHT);
    }else{
        self.frame = NSMakeRect(0, border.frame.size.height, parent.frame.size.width, COMMAND_FIELD_HEIGHT);
        nsview.frame = NSMakeRect(0, border.frame.size.height+COMMAND_FIELD_HEIGHT, parent.frame.size.width, parent.frame.size.height-border.frame.size.height-COMMAND_FIELD_HEIGHT);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"hidden"]) {
        [self layoutCmdline:[self superview]];
    }else if( [keyPath isEqualToString:@"DVTFontAndColorCurrentTheme"] ){
        [self layoutCmdline:[self superview]];
    }
}

- (void)didFrameChanged:(NSNotification*)notification
{
    [self layoutCmdline:[notification object]];
}

- (void)fontAndColorSourceTextSettingsChanged:(NSNotification*)notification{
    [self layoutCmdline:[self superview]];
}
@end
