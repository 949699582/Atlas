//
//  AlertView.h
//  Popup
//
// All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AlertBlock)(BOOL ok);
@interface AlertView : NSViewController

@property (nonatomic, copy)AlertBlock completeBlock;
-(void)updateUI:(NSString*)message ok:(NSString *)ok;
@end

NS_ASSUME_NONNULL_END
