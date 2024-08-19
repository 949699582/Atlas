//
//  PassWordVC.h
//  ChartsUI
//
// All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PassWordModel.h"
NS_ASSUME_NONNULL_BEGIN
typedef void(^PSWBlock)(NSString * sn);
@interface PassWordVC : NSViewController

@property (nonatomic, strong) PassWordModel *obj;

@property (nonatomic, copy)PSWBlock completeBlock;

-(void)updateUIWithModel:(PassWordModel*)obj;

@end

NS_ASSUME_NONNULL_END
