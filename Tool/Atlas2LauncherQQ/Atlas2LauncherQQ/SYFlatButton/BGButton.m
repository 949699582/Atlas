//
//  BGButton.m
//  Atlas2LauncherQQ
//
//  Created by 周红强 on 17/08/2024.
//

#import "BGButton.h"

@implementation BGButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    // 设置按钮背景颜色为绿色
    [[NSColor greenColor] setFill];
    NSRectFill(dirtyRect);
    
    // 设置按钮标题字体颜色为白色
    [[NSColor whiteColor] set];
    
    // 获取按钮标题
    NSString *title = self.title;
    
    // 计算标题显示的矩形区域，以实现水平居中
    NSDictionary *attributes = @{NSFontAttributeName: [NSFont systemFontOfSize:14]};
    CGFloat titleWidth = [title sizeWithAttributes:attributes].width;
    CGFloat x = (self.bounds.size.width - titleWidth) / 2;
    NSRect titleRect = NSMakeRect(x, 0, titleWidth, self.bounds.size.height);
    
    // 创建并配置 NSMutableParagraphStyle
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    // 绘制标题，水平和垂直都居中
    [title drawInRect:titleRect withAttributes:@{
        NSFontAttributeName: [NSFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    
}

@end
