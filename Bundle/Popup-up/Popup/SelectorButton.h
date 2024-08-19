//
//  SelectorButton.h
//  Popup
//
//  Created by answer.guo on 2022/7/21.
//  Copyright © 2022 luxshare-ict.jax. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SelectBlock)(NSNumber *ok);
@interface SelectorButton : NSViewController

@property (nonatomic, copy)SelectBlock selectBlock;
-(void)updateSelect:(NSString*)message buttonPass:(NSString *)buttonPass buttonSlight:(NSString *)buttonSlight buttonMedium:(NSString *)buttonMedium buttonBad:(NSString *)buttonBad;

@end

NS_ASSUME_NONNULL_END
