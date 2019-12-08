#include "Rik.h"

static Ivar items_ivar(void)
{
  static Ivar iv;
  if (iv == NULL)
    {
      iv = class_getInstanceVariable([NSSegmentedCell class], "_items");
      NSCAssert(iv, @"Unable to find _items instance variable of NSSegmentedCell");
    }
  return iv;
}

@interface NSSegmentedCell(RikTheme)
@end
@implementation NSSegmentedCell(RikTheme)


- (NSColor*) textColor
{
  //IT DOES NOT WORK (??)
  struct GSCellFlagsType myCell;
  object_getInstanceVariable(self, "_cell", (void**)&myCell);

  if(myCell.state == GSThemeSelectedState)
    return [NSColor whiteColor];
  if (myCell.is_disabled)
    return [NSColor disabledControlTextColor];
  else
    return [NSColor controlTextColor];
}

- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
                                    inView: (NSView*)controlView
{
  CGFloat radius = 4;
  cellFrame = NSInsetRect(cellFrame, 0.5, 0.5);
  NSColor* strokeColorButton = [Rik controlStrokeColor];
  NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: cellFrame
                                                                       xRadius: radius
                                                                       yRadius: radius];
  [strokeColorButton setStroke];
  [roundedRectanglePath setLineWidth: 1];
  [roundedRectanglePath stroke];
  NSMutableArray *items = object_getIvar(self, items_ivar());
  NSInteger i;
  NSUInteger count = [items count];
  NSRect frame = cellFrame;
  NSRect controlFrame = [controlView frame];

  NSBezierPath* linesPath = [NSBezierPath bezierPath];
  [linesPath setLineWidth: 1];
  CGFloat offsetX = 0;
  for (i = 0; i < count-1;i++)
    {
      frame.size.width = [[items objectAtIndex: i] width];
      if(frame.size.width == 0.0)
        {
          frame.size.width = (controlFrame.size.width - frame.origin.x) / (count);
        }
      offsetX += frame.size.width;
      offsetX = floor(offsetX) + 0.5;
      [linesPath moveToPoint: NSMakePoint(offsetX, NSMinY(frame) + 3)];
      [linesPath lineToPoint: NSMakePoint(offsetX, NSMaxY(frame) - 3)];
    }
  [linesPath stroke];
}
- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (NSIsEmptyRect(cellFrame))
    return;
// i want to draw the border for last
  [self drawInteriorWithFrame: cellFrame inView: controlView];
  [self _drawBorderAndBackgroundWithFrame: cellFrame inView: controlView];
  [self _drawFocusRingWithFrame: cellFrame inView: controlView];
}
@end
