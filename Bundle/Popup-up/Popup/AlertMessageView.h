//
//  AlertMessageView.h
//  Popup
//

//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AlertBlock)(BOOL ok);
@interface AlertMessageView : NSViewController

@property (nonatomic, copy)AlertBlock messageBlock;
-(void)updateView:(NSString*)message tipYes:(NSString *)tYes tipNo:(NSString *)tNo;

@end

NS_ASSUME_NONNULL_END
