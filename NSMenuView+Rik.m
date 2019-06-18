#import "Rik.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSMenuView.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSButton.h"
#import "AppKit/NSPopUpButtonCell.h"
#import "AppKit/NSScreen.h"
#import "AppKit/NSWindow.h"
#import "AppKit/PSOperators.h"

#import "GNUstepGUI/GSTheme.h"
#import "GNUstepGUI/GSTitleView.h"
#define HORIZONTAL_MENU_LEFT_PADDING 8


typedef struct _GSCellRect {
  NSRect rect;
} GSCellRect;

#define GSI_ARRAY_TYPES         0
#define GSI_ARRAY_TYPE          GSCellRect

#define GSI_ARRAY_NO_RETAIN
#define GSI_ARRAY_NO_RELEASE

#ifdef GSIArray
#undef GSIArray
#endif
#include <GNUstepBase/GSIArray.h>

static NSMapTable *viewInfo = 0;

#define cellRects ((GSIArray)NSMapGet(viewInfo, self))

@interface NSMenuView(rikTheme)
- (void) sizeToFit;
@end


@implementation NSMenuView(rikTheme)

- (void) sizeToFit
{
  BOOL isPullDown =
    [_attachedMenu _ownedByPopUp] && [[_attachedMenu _owningPopUp] pullsDown];

  if (_horizontal == YES)
    {
      unsigned i;
      unsigned howMany = [_itemCells count];
      float currentX = HORIZONTAL_MENU_LEFT_PADDING;
//      NSRect scRect = [[NSScreen mainScreen] frame];

      GSIArrayRemoveAllItems(cellRects);

/*
      scRect.size.height = [NSMenuView menuBarHeight];
      [self setFrameSize: scRect.size];
      _cellSize.height = scRect.size.height;
*/
      _cellSize.height = [NSMenuView menuBarHeight];

      if (howMany && isPullDown)
        {
          GSCellRect elem;
          elem.rect = NSMakeRect (currentX,
                                  0,
                                  (2 * _horizontalEdgePad),
                                  [self heightForItem: 0]);
          GSIArrayAddItem(cellRects, (GSIArrayItem)elem);
          currentX += 2 * _horizontalEdgePad;
        }
      for (i = isPullDown ? 1 : 0; i < howMany; i++)
        {
          GSCellRect elem;
          NSMenuItemCell *aCell = [self menuItemCellForItemAtIndex: i];
          float titleWidth = [aCell titleWidth];

          if ([aCell imageWidth])
            {
              titleWidth += [aCell imageWidth] + GSCellTextImageXDist;
            }

          elem.rect = NSMakeRect (currentX,
                                  0,
                                  (titleWidth + (2 * _horizontalEdgePad)),
                                  [self heightForItem: i]);
          GSIArrayAddItem(cellRects, (GSIArrayItem)elem);

          currentX += titleWidth + (2 * _horizontalEdgePad);
        }
    }
  else
    {
      unsigned i;
      unsigned howMany = [_itemCells count];
      unsigned wideTitleView = 1;
      float    neededImageAndTitleWidth = 0.0;
      float    neededKeyEquivalentWidth = 0.0;
      float    neededStateImageWidth = 0.0;
      float    accumulatedOffset = 0.0;
      float    popupImageWidth = 0.0;
      float    menuBarHeight = 0.0;

      if (_titleView)
        {
          NSMenu *m = [_attachedMenu supermenu];
          NSMenuView *r = [m menuRepresentation];

          neededImageAndTitleWidth = [_titleView titleSize].width;
          if (r != nil && [r isHorizontal] == YES)
            {
              NSMenuItemCell *msr;

              msr = [r menuItemCellForItemAtIndex:
                [m indexOfItemWithTitle: [_attachedMenu title]]];
              neededImageAndTitleWidth
                = [msr titleWidth] + GSCellTextImageXDist;
            }

          if (_titleView)
            menuBarHeight = [[self class] menuBarHeight];
          else
            menuBarHeight += _leftBorderOffset;
        }
      else
        {
          menuBarHeight += _leftBorderOffset;
        }

      for (i = isPullDown ? 1 : 0; i < howMany; i++)
        {
          float aStateImageWidth;
          float aTitleWidth;
          float anImageWidth;
          float anImageAndTitleWidth;
          float aKeyEquivalentWidth;
          NSMenuItemCell *aCell = [self menuItemCellForItemAtIndex: i];
          
          // State image area.
          aStateImageWidth = [aCell stateImageWidth];
          
          // Title and Image area.
          aTitleWidth = [aCell titleWidth];
          anImageWidth = [aCell imageWidth];
          
          // Key equivalent area.
          aKeyEquivalentWidth = [aCell keyEquivalentWidth];
          
          switch ([aCell imagePosition])
            {
              case NSNoImage: 
                anImageAndTitleWidth = aTitleWidth;
                break;
                
              case NSImageOnly: 
                anImageAndTitleWidth = anImageWidth;
                break;
                
              case NSImageLeft: 
              case NSImageRight: 
                anImageAndTitleWidth
                  = anImageWidth + aTitleWidth + GSCellTextImageXDist;
                break;
                
              case NSImageBelow: 
              case NSImageAbove: 
              case NSImageOverlaps: 
              default: 
                if (aTitleWidth > anImageWidth)
                  anImageAndTitleWidth = aTitleWidth;
                else
                  anImageAndTitleWidth = anImageWidth;
                break;
            }
          
          if (aStateImageWidth > neededStateImageWidth)
            neededStateImageWidth = aStateImageWidth;
          
          if (anImageAndTitleWidth > neededImageAndTitleWidth)
            neededImageAndTitleWidth = anImageAndTitleWidth;
                    
          if (aKeyEquivalentWidth > neededKeyEquivalentWidth)
            neededKeyEquivalentWidth = aKeyEquivalentWidth;
          
          // Title view width less than item's left part width
          if ((anImageAndTitleWidth + aStateImageWidth) 
              > neededImageAndTitleWidth)
            wideTitleView = 0;
          
          // Popup menu has only one item with nibble or arrow image
          if (anImageWidth)
            popupImageWidth = anImageWidth;
        }
      if (isPullDown && howMany)
        howMany -= 1;
      
      // Cache the needed widths.
      _stateImageWidth = neededStateImageWidth;
      _imageAndTitleWidth = neededImageAndTitleWidth;
      _keyEqWidth = neededKeyEquivalentWidth;
      
      accumulatedOffset = _horizontalEdgePad;
      if (howMany)
        {
          // Calculate the offsets and cache them.
          if (neededStateImageWidth)
            {
              _stateImageOffset = accumulatedOffset;
              accumulatedOffset += neededStateImageWidth += _horizontalEdgePad;
            }
          
          if (neededImageAndTitleWidth)
            {
              _imageAndTitleOffset = accumulatedOffset;
              accumulatedOffset += neededImageAndTitleWidth;
            }
          
          if (wideTitleView)
            {
              _keyEqOffset = accumulatedOffset = neededImageAndTitleWidth
                + (3 * _horizontalEdgePad);
            }
          else
            {
              _keyEqOffset = accumulatedOffset += (2 * _horizontalEdgePad);
            }
          accumulatedOffset += neededKeyEquivalentWidth + _horizontalEdgePad; 
          
          if ([_attachedMenu supermenu] != nil && neededKeyEquivalentWidth < 8)
            {
              accumulatedOffset += 8 - neededKeyEquivalentWidth;
            }
        }
      else
        {
          accumulatedOffset += neededImageAndTitleWidth + 3 + 2;
          if ([_attachedMenu supermenu] != nil)
            accumulatedOffset += 15;
        }
      
      // Calculate frame size.
      if (_needsSizing)
        {
          // Add the border width: 1 for left, 2 for right sides
          _cellSize.width = accumulatedOffset + 3;
        }

      if ([_attachedMenu _ownedByPopUp])
        {
          _keyEqOffset = _cellSize.width - _keyEqWidth - popupImageWidth;
        }

      [self setFrameSize: NSMakeSize(_cellSize.width + _leftBorderOffset, 
                                     [self totalHeight] 
                                     + menuBarHeight)];
      [_titleView setFrame: NSMakeRect (0, [self totalHeight],
                                        NSWidth (500),//was (_bounds)
					menuBarHeight)];
    }
  _needsSizing = NO;
}
@end
