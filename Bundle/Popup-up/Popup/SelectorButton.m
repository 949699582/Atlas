//
//  SelectorButton.m
//  Popup
//
//  Created by answer.guo on 2022/7/21.
//  Copyright © 2022 luxshare-ict.jax. All rights reserved.
//

#import "SelectorButton.h"

@interface SelectorButton ()
@property (weak) IBOutlet NSTextField *tipLable;
@property (weak) IBOutlet NSButton *slightButton;
@property (weak) IBOutlet NSButton *mediumButton;
@property (weak) IBOutlet NSButton *badButton;
@property (weak) IBOutlet NSButton *passButton;

@end

@implementation SelectorButton

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
-(void)updateSelect:(NSString*)message buttonPass:(NSString *)buttonPass buttonSlight:(NSString *)buttonSlight buttonMedium:(NSString *)buttonMedium buttonBad:(NSString *)buttonBad;
{
    self.tipLable.stringValue = message;
    self.passButton.title = buttonPass;
    self.slightButton.title = buttonSlight;
    self.mediumButton.title = buttonMedium;
    self.badButton.title = buttonBad;
//    self.MeaagetLab.stringValue = message;
//    self.tipYesBtn.title = tYes;
//    self.tipNoBtn.title = tNo;
}
- (IBAction)passAction:(id)sender {
    if (self.selectBlock) {
        self.selectBlock(@0);
    }
    [self dismissController:nil];
    
}

- (IBAction)slightAction:(id)sender {
    if (self.selectBlock) {
        self.selectBlock(@1);
    }
    [self dismissController:nil];
    
}
- (IBAction)mediumAction:(id)sender {
    if (self.selectBlock) {
        self.selectBlock(@2);
    }
    [self dismissController:nil];
}
- (IBAction)badAction:(id)sender {
    if (self.selectBlock) {
        self.selectBlock(@3);
    }
    [self dismissController:nil];
}


@end
