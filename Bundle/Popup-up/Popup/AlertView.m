//
//  AlertView.m
//  Popup
//
// All rights reserved.
//

#import "AlertView.h"

@interface AlertView ()

@property (weak) IBOutlet NSTextField *msg;


@property (weak) IBOutlet NSButton *ok;


@end

@implementation AlertView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)updateUI:(NSString*)message ok:(NSString *)ok{
    self.msg.stringValue = message;
    self.ok.title = ok;
}

- (IBAction)clickok:(id)sender {
    if (self.completeBlock) {
        self.completeBlock(YES);
    }
    [self dismissController:nil];
}

@end
