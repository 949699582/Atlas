		//
//  PassWordVC.m
//  ChartsUI
//
// All rights reserved.
//

#import "PassWordVC.h"

#define PSW @"4396"
@interface PassWordVC ()

@property (weak) IBOutlet NSTextField *titleLabel;

@property (weak) IBOutlet NSTextField *pswTF;

@property (weak) IBOutlet NSButton *startButton;


@end

@implementation PassWordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
}

-(void)viewDidAppear{
    [super viewDidAppear];
    self.pswTF.stringValue = @"";
    [self.startButton becomeFirstResponder];
    self.titleLabel.stringValue = self.obj.title;
    self.startButton.title = self.obj.buttonTitle;
    self.pswTF.placeholderString = self.obj.passTFPlacehodle;
}



-(void)updateUIWithModel:(PassWordModel*)obj{
    self.titleLabel.stringValue = obj.title;
    self.startButton.title = obj.buttonTitle;
    self.pswTF.placeholderString = obj.passTFPlacehodle;
}


- (IBAction)clickOK:(id)sender {
    
    NSString * str = self.pswTF.stringValue;
    
    if (self.completeBlock) {
        self.completeBlock(str);
    }
    
    [self dismissController:nil];
}

@end
