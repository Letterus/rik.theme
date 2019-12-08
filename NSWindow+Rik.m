#include "Rik+Button.h"
#include "RikWindowButton.h"
#include <AppKit/NSAnimation.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSImage.h>
#import "GNUstepGUI/GSTheme.h"

@interface DefaultButtonAnimation: NSAnimation
{
  NSButtonCell * defaultbuttoncell;
  BOOL reverse;
}

@property (nonatomic, assign) BOOL reverse;
@property (retain) NSButtonCell * defaultbuttoncell;

@end

@implementation DefaultButtonAnimation

@synthesize reverse;
@synthesize defaultbuttoncell;

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
  [super setCurrentProgress: progress];
  if(defaultbuttoncell)
    {
        if(reverse)
        {
          defaultbuttoncell.pulseProgress = [NSNumber numberWithFloat: 1.0 - progress];
        }else{
          defaultbuttoncell.pulseProgress = [NSNumber numberWithFloat: progress];
        }
        [[defaultbuttoncell controlView] setNeedsDisplay: YES];
    }
  if (defaultbuttoncell && progress >= 1.0)
  {
    reverse = !reverse;
    [self startAnimation];
  }
}
@end

@interface DefaultButtonAnimationController : NSObject <NSWindowDelegate>

{
  DefaultButtonAnimation * animation;
  NSButtonCell * buttoncell;
}

@property (retain) NSButtonCell * buttoncell;
@property (retain) NSAnimation * animation;

@end
@implementation DefaultButtonAnimationController
@synthesize buttoncell;
@synthesize animation;
- (id) initWithButtonCell: (NSButtonCell*) cell
{
  if (self = [super init]) {
    buttoncell = cell;
  }
  return self;
}
- (void) startPulse
{
  [self startPulse: NO];
}
- (void) startPulse: (BOOL) reverse
{
  animation = [[DefaultButtonAnimation alloc] initWithDuration:0.7
                                animationCurve:NSAnimationEaseInOut];
  animation.reverse = reverse;
  [animation addProgressMark: 1.0];
  [animation setDelegate: self];
  [animation setFrameRate:30.0];
  [animation setAnimationBlockingMode:NSAnimationNonblocking];
  animation.defaultbuttoncell = buttoncell;
  [animation startAnimation];
}
- (void)animation:(NSAnimation *)a
            didReachProgressMark:(NSAnimationProgress)progress
{
  //[animation stopAnimation];
  //[self startPulse: !animation.reverse];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [animation stopAnimation];
}

@end


static Ivar defaultButtonCell_ivar(void)
{
  static Ivar iv;
  if (iv == NULL)
    {
      iv = class_getInstanceVariable([NSWindow class], "_defaultButtonCell");
      NSCAssert(iv, @"Unable to find _defaultButtonCell instance variable of NSWindow");
    }
  return iv;
}

static Ivar f_ivar(void)
{
  static Ivar iv;
  if (iv == NULL)
    {
      iv = class_getInstanceVariable([NSWindow class], "_f");
      NSCAssert(iv, @"Unable to find _f instance variable of NSWindow");
    }
  return iv;
}

@implementation NSWindow(RikTheme)

+ (NSButton *) standardWindowButton: (NSWindowButton)button
                       forStyleMask: (NSUInteger) mask
{
  RikWindowButton *newButton;

  switch (button)
    {
      case NSWindowCloseButton:
        newButton = [[RikWindowButton alloc] init];
        [newButton setBaseColor: [NSColor colorWithCalibratedRed: 0.698 green: 0.427 blue: 1.00 alpha: 1]];
        [newButton setImage: [NSImage imageNamed: @"common_Close"]];
        [newButton setAlternateImage: [NSImage imageNamed: @"common_CloseH"]];
        [newButton setAction: @selector(performClose:)];
        break;
      case NSWindowMiniaturizeButton:
        newButton = [[RikWindowButton alloc] init];
        [newButton setBaseColor: [NSColor colorWithCalibratedRed: 0.9 green: 0.7 blue: 0.3 alpha: 1]];
        [newButton setImage: [NSImage imageNamed: @"common_Miniaturize"]];
        [newButton setAlternateImage: [NSImage imageNamed: @"common_MiniaturizeH"]];
        [newButton setAction: @selector(miniaturize:)];
        break;

      case NSWindowZoomButton:
        // FIXME
        newButton = [[RikWindowButton alloc] init];
        [newButton setBaseColor: [NSColor colorWithCalibratedRed: 0.322 green: 0.778 blue: 0.244 alpha: 1]];
        [newButton setAction: @selector(zoom:)];
        break;

      case NSWindowToolbarButton:
        // FIXME
        newButton = [[RikWindowButton alloc] init];
        [newButton setAction: @selector(toggleToolbarShown:)];
        break;
      case NSWindowDocumentIconButton:
      default:
        newButton = [[RikWindowButton alloc] init];
        // FIXME
        break;
    }

  [newButton setRefusesFirstResponder: YES];
  [newButton setButtonType: NSMomentaryChangeButton];
  [newButton setImagePosition: NSImageOnly];
  [newButton setBordered: YES];
  [newButton setTag: button];
  return AUTORELEASE(newButton);
}
- (void) setDefaultButtonCell: (NSButtonCell *)aCell
{
  object_setIvar(self, defaultButtonCell_ivar(), aCell);

  struct GSWindowFlagsType* f = (struct GSWindowFlagsType*) object_getIvar(self, f_ivar());
  f->default_button_cell_key_disabled = NO;

  [aCell setKeyEquivalent: @"\r"];
  [aCell setKeyEquivalentModifierMask: 0];
  [aCell setIsDefaultButton: [NSNumber numberWithBool: YES]];

  DefaultButtonAnimationController * animationcontroller = [[DefaultButtonAnimationController alloc] initWithButtonCell: aCell];
  [self setDelegate:animationcontroller];
  [animationcontroller startPulse];
}
- (void) animateDefaultButton: (id)sender
{
}

@end

