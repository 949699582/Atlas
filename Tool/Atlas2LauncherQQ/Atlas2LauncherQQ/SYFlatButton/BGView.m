//
//  BGView.m
//  Atlas2LauncherQQ
//
//  Created by 周红强 on 17/08/2024.
//

#import "BGView.h"

@implementation BGView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [[NSColor blackColor] set];
//    [self.color set];
    NSRectFill(dirtyRect);
}

@end
