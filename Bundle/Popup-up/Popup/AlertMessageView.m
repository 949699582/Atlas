//
//  AlertMessageView.m
//  Popup
//

//

#import "AlertMessageView.h"

@interface AlertMessageView ()

@property (weak) IBOutlet NSTextField *MeaagetLab;
@property (weak) IBOutlet NSButton *tipNoBtn;
@property (weak) IBOutlet NSButton *tipYesBtn;

@end

@implementation AlertMessageView

- (void)viewDidLoad {
    [super viewDidLoad];
   
}

-(void)updateView:(NSString*)message tipYes:(NSString *)tYes tipNo:(NSString *)tNo
{
    self.MeaagetLab.stringValue = message;
    self.tipYesBtn.title = tYes;
    self.tipNoBtn.title = tNo;
}

- (IBAction)tipNoAction:(id)sender {
    if (self.messageBlock) {
        self.messageBlock(NO);
    }
    [self dismissController:nil];
}

- (IBAction)tipYesAction:(id)sender {
    if (self.messageBlock) {
        self.messageBlock(YES);
    }
    [self dismissController:nil];
}

@end
