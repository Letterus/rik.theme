@interface NSWindow(RikTheme)
{
}
+ (NSButton *) standardWindowButton: (NSWindowButton)button 
                       forStyleMask: (NSUInteger) mask;
                       
- (void) setDefaultButtonCell: (NSButtonCell *)aCell; 
@end
