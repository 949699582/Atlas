// Version 0.0.2
//  Popup.m
//  Popup
//
//All rights reserved.
//

#import "Popup.h"
#import <AtlasLogging/AtlasLogging.h>
#import <AtlasLuaSequencer/AtlasLuaSequencer.h>
#import "PassWordVC.h"
#import "AlertView.h"
#import "PassWordModel.h"
#import "AlertMessageView.h"
#import "SelectorButton.h"
#import "Common.h"

@interface Popup ()
@property (nonatomic, strong) NSButton *startButton;
@property (nonatomic, strong) PassWordModel *pswModel;
@property (nonatomic, strong) NSMutableDictionary *systemDict;
@property (nonatomic, assign) BOOL isClickStart;
@property (nonatomic, assign) BOOL isAlertPop;
@property (nonatomic, copy) NSNumber * isTipYes;
@property (nonatomic, copy) NSNumber * selector;
//@property (nonatomic, strong) PassWordVC * passVC;
@property (nonatomic, strong) NSTextField *textField;
@property (strong) IBOutlet NSView *viewWindow;
@property (nonatomic, copy) NSString *snField;
@property (nonatomic, copy) NSString *sn1;
@property (nonatomic, copy) NSString *textFieldId;
@property (nonatomic,copy) NSString *stationName;
@property (nonatomic, strong) NSDictionary *checkBoxDic;
@property (nonatomic,strong)NSButton *buttonStart;
@property (nonatomic,assign)NSInteger buttonStatus;

@property (nonatomic,strong)NSButton *buttonStart2;
@property (nonatomic,assign)NSInteger buttonStatus2;

@property (nonatomic,strong)NSButton *buttonXuanZhuan;
@property (nonatomic,strong)NSButton *systemReset;

@property (nonatomic,strong)NSTextField *inputField;


@end

@implementation Popup
-(instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _pswModel = [PassWordModel new];
        _pswModel.title = @"请扫码!!!";
        _pswModel.buttonTitle = @"Start";
        _pswModel.passTFPlacehodle = @"";
        _systemDict = [NSMutableDictionary dictionary];
    }
    return  self;
}

- (void)startBtnClick:(NSButton *)btn{
    //    ATKLog("start button clicked ==%ld",btn.tag);
    ATKLog("start button clicked");
    
    self.buttonStatus2 = 0;
    self.buttonStatus = 1;
    
    self.buttonStart.enabled = NO;
    self.buttonStart2.enabled = NO;
    
    
}

- (void)startBtn2Click:(NSButton *)btn{
    //    ATKLog("start button clicked ==%ld",btn.tag);
    ATKLog("start button clicked");
    
    self.buttonStatus2 = 1;
    self.buttonStatus = 0;
    
    
    self.buttonStart.enabled = NO;
    self.buttonStart2.enabled = NO;
    
}

- (void)xuanZhuanAction:(NSButton *)btn{
    //    ATKLog("start button clicked ==%ld",btn.tag);
    ATKLog("xuanZhuanAction Action");
    NSString *cmd = @"/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlXuanZhuan2.py";
    NSString *xuanzhuanRes =[Common runCmd:cmd];
    ATKLog("xuanzhuanRes ===%@",xuanzhuanRes);
    
}

- (void)systemResetAction:(NSButton *)btn{
    //    ATKLog("start button clicked ==%ld",btn.tag);
    ATKLog("xuanZhuanAction Action");
    NSString *cmd = @"/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/serialPortSystemReset.py";
    NSString *xuanzhuanRes =[Common runCmd:cmd];
    ATKLog("xuanzhuanRes ===%@",xuanzhuanRes);
}

-(void)upMethod{
    ATKLog("up1 Action");
    NSString *cmdUp1 = @"/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlNeedleUp1.py";
    NSString *up1Res =[Common runCmd:cmdUp1];
    ATKLog("up1Res ===%@",up1Res);
    
    ATKLog("up2 Action");
    NSString *cmdUp2 = @"/usr/local/bin/python3 /Users/gdlocal/Library/Atlas2/ScriptFile/ControlNeedleUp2.py";
    NSString *up2Res =[Common runCmd:cmdUp2];
    ATKLog("up2Res ===%@",up2Res);
}

- (NSString *)getStartClickStatus:(NSString*)str Error:(NSError **)error{
    
    NSString *buttonStatusString = [NSString stringWithFormat:@"%ld",self.buttonStatus];
    //    self.buttonStatus = 0;
    NSString *buttonStatusString2 = [NSString stringWithFormat:@"%ld",self.buttonStatus2];
    //    self.buttonStatus2 = 0;
    if([str isEqualToString:@"1"]){
        return buttonStatusString;
    }else if([str isEqualToString:@"2"]){
        return buttonStatusString2;
    }
    return @"11";
}

- (NSString *)getStartClickStatus1:(NSString*)str Error:(NSError **)error{
    
    //    NSString *buttonStatusString = [NSString stringWithFormat:@"%ld",self.buttonStatus];
    //    self.buttonStatus = 0;
    NSString *buttonStatusString2 = [NSString stringWithFormat:@"%ld",self.buttonStatus2];
    //    self.buttonStatus2 = 0;
    if([str isEqualToString:@"2"]){
        return buttonStatusString2;
    }
    return [NSString stringWithFormat:@"%ld",self.buttonStatus2];
}

- (void)customButtonStart{
    // 创建按钮
    self.buttonStart = [[NSButton alloc] initWithFrame:NSMakeRect(20, 150, 100, 40)];
    [self.buttonStart setTitle:@"Group0"];
    self.buttonStart.tag = 1;
    [self.buttonStart setButtonType:NSButtonTypeMomentaryPushIn];
    [self.buttonStart setBezelStyle:NSBezelStyleRegularSquare];
    // 设置按钮类型为方形
    
    
    // 设置按钮的目标和动作
    [self.buttonStart setTarget:self];
    [self.buttonStart setAction:@selector(startBtnClick:)];
    
    // 将按钮添加到视图中
    [[self.view layer] setBackgroundColor:[NSColor greenColor].CGColor];
    [[self.view layer] setCornerRadius:10];
    [self.view addSubview:self.buttonStart];
    
    
    // 创建按钮
    self.buttonStart2 = [[NSButton alloc] initWithFrame:NSMakeRect(140, 150, 100, 40)];
    [self.buttonStart2 setTitle:@"Group1"];
    self.buttonStart.tag = 2;
    [self.buttonStart2 setButtonType:NSButtonTypeMomentaryPushIn];
    [self.buttonStart2 setBezelStyle:NSBezelStyleRegularSquare];
    
    // 设置按钮的目标和动作
    [self.buttonStart2 setTarget:self];
    [self.buttonStart2 setAction:@selector(startBtn2Click:)];
    
    // 将按钮添加到视图中
    [[self.view layer] setBackgroundColor:[NSColor greenColor].CGColor];
    [[self.view layer] setCornerRadius:10];
    [self.view addSubview:self.buttonStart2];
    
    // 创建按钮
    self.buttonXuanZhuan = [[NSButton alloc] initWithFrame:NSMakeRect(300, 150, 100, 40)];
    [self.buttonXuanZhuan setTitle:@"旋转"];
    self.buttonXuanZhuan.tag = 3;
    [self.buttonXuanZhuan setButtonType:NSButtonTypeMomentaryPushIn];
    [self.buttonXuanZhuan setBezelStyle:NSBezelStyleRegularSquare];
    
    // 设置按钮的目标和动作
    [self.buttonXuanZhuan setTarget:self];
    [self.buttonXuanZhuan setAction:@selector(xuanZhuanAction:)];
    
    // 将按钮添加到视图中
    [[self.view layer] setBackgroundColor:[NSColor greenColor].CGColor];
    [[self.view layer] setCornerRadius:10];
    [self.view addSubview:self.buttonXuanZhuan];
    
    // 创建按钮
    self.systemReset = [[NSButton alloc] initWithFrame:NSMakeRect(420, 150, 100, 40)];
    [self.systemReset setTitle:@"Reset"];
    self.systemReset.tag = 4;
    [self.systemReset setButtonType:NSButtonTypeMomentaryPushIn];
    [self.systemReset setBezelStyle:NSBezelStyleRegularSquare];
    
    self.systemReset.hidden = YES;
    // 设置按钮的目标和动作
    [self.systemReset setTarget:self];
    [self.systemReset setAction:@selector(systemResetAction:)];
    
    // 将按钮添加到视图中
    [[self.view layer] setBackgroundColor:[NSColor greenColor].CGColor];
    [[self.view layer] setCornerRadius:10];
    [self.view addSubview:self.systemReset];
    
    
    
    self.inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(500, 155, 250, 30)];
    
    // 设置输入框的占位符
    [self.inputField setPlaceholderString:@"SN..."];
    

    // 设置输入框的边框样式
    [self.inputField setBezeled:YES];
    [self.inputField setBezelStyle:NSBezelStyleRounded];
    
    // 设置输入框的背景颜色（可选）
    [self.inputField setBackgroundColor:[NSColor whiteColor]];
    
    // 将NSTextField添加到窗口的内容视图中
    [self.view addSubview:self.inputField];
    
}

- (void)viewWillAppear{
    [super viewWillAppear];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.buttonStart2.enabled = NO;
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 获取plist文件路径
    self.buttonStatus = 9999;
    self.buttonStatus2 = 9999;
    
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    
    // 获取当前登录用户的账号名称
    NSString *userName = [processInfo userName];
    NSString *plistPath = [NSString stringWithFormat:@"/Users/%@/Library/Atlas2/Config/station.plist", userName];
    ATKLog("station plist path:%@",plistPath);
    //    NSString *plistPath = @"~/Library/Atlas2/Config/station.plist";
    // 读取plist文件内容
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    NSDictionary *GroupConfig = [dict objectForKey:@"GroupConfig"];
    id groupNumberId = [GroupConfig objectForKey:@"Instances"];
    NSNumber *groupNumber = (NSNumber *)groupNumberId;
    int groupNumberInt = [groupNumber intValue];
    ATKLog("groupNumberInt:%d",groupNumberInt);
    
    NSArray *slotArray = [[dict objectForKey:@"GroupConfig"] objectForKey:@"SlotConfig"];
    int slotNumber = (int)[slotArray count];
    
    ATKLog("groupNumber:%d slotNumber:%d",groupNumberInt,slotNumber);
    //    创建start button
    [self customButtonStart];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    for (int r = 0;r<groupNumberInt;r++)
    {
        // 创建一个 NSTextField 对象
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(5, 270-r*30, 100, 20)];
        
        // 设置标签的样式为静态文本
        [label setBezeled:NO];
        [label setDrawsBackground:NO];
        [label setEditable:NO];
        [label setSelectable:NO];
        NSString *lableText = [NSString stringWithFormat:@"Group %d: ", r];
        // 设置标签的文本内容
        [label setStringValue:lableText];
        // 设置字体大小和颜色
        NSFont *font = [NSFont systemFontOfSize:16.0]; // 设置字体大小为 16
        [label setFont:font];
        
        NSColor *textColor = [NSColor blueColor]; // 设置文本颜色为蓝色
        [label setTextColor:textColor];
        
        // 将标签添加到窗口中
        [[self view] addSubview:label];
        NSMutableArray *checkBoxArray = [NSMutableArray array];
        for (int c = 0;c<slotNumber;c++)
        {
            // 创建一个复选框
            NSButton *checkBox = [[NSButton alloc] initWithFrame:NSMakeRect(110+c*100, 270-r*30, 100, 20)];
            [checkBox setButtonType:NSButtonTypeSwitch]; // 设置按钮类型为复选框
            NSString *titleString = [NSString stringWithFormat:@"slot%d", c+1];
            [checkBox setTitle:titleString]; // 设置复选框的标题
            [checkBox setState:NSControlStateValueOn]; // 设置初始状态为未选中
            
            // 为复选框添加目标和动作方法
            [checkBox setTarget:self];
            [checkBox setAction:@selector(checkBoxAction:)];
            
            // 将复选框添加到视图中
            [[self view] addSubview:checkBox];
            [checkBoxArray addObject:checkBox];
        }
        
        // 创建每行的全选复选框
        
        NSButton *selectAllCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(130+slotNumber*100, 270-r*30, 100, 20)];
        selectAllCheckbox.title = @"All";
        selectAllCheckbox.tag = r;
        selectAllCheckbox.bezelStyle = NSBezelStyleRegularSquare;
        selectAllCheckbox.buttonType = NSButtonTypeSwitch;
        [selectAllCheckbox setTarget:self];
        [selectAllCheckbox setAction:@selector(selectAllCheckboxClicked:)];
        [self.view addSubview:selectAllCheckbox];
        
        [dictionary setObject:checkBoxArray forKey:@(r)];
        //        [dictionary setObject:checkBoxArray forKey:[NSString stringWithFormat:@"%d",r]];
        
        
    }
    self.checkBoxDic = dictionary;
    //    ATKLog("Modified Immutable Dictionary: %@", self.checkBoxDic);
}

- (void)selectAllCheckboxClicked:(NSButton *)button{
    NSButton *selectAllCheckbox = (NSButton *)button;
    NSControlStateValue selectAllState = selectAllCheckbox.state;
    
    NSLog(@"checkBoxDic ==%@",self.checkBoxDic);
    NSLog(@"button.tag ==%ld",button.tag);
    
    NSMutableArray<NSButton *> *checkboxesForRow = [self.checkBoxDic objectForKey:@(button.tag)];
    NSLog(@"checkboxesForRow ==%@",checkboxesForRow);
    
    for (NSButton *checkbox in checkboxesForRow) {
        
        checkbox.state = selectAllState;
    }
}

- (void)checkBoxAction:(id)sender {
    NSButton *checkbox = (NSButton *)sender;
    if ([checkbox state] == NSControlStateValueOn) {
        NSLog(@"复选框被选中");
    } else {
        NSLog(@"复选框未被选中");
    }
}

- (NSString *)getInputSN:(NSString*)str Error:(NSError **)error{
    return self.inputField.stringValue;
}
- (CGFloat)minHeightHint
{
    return 300.0;
}
- (CGFloat)minWidthHint
{
    return 1200.0;
}

- (id)pluginContext;
{
    return self;
}
- (NSDictionary *)pluginConstants
{
    NSDictionary *constantsTable = @{};
    return constantsTable;
}
- (NSDictionary *)pluginFunctionTable
{
    NSDictionary *functionTable = @{
        @"alert":@[@[ATKSelector(alertWithMsg:ok:),ATKString,ATKString]],
        @"queryAlert":@[@[ATKSelector(queryAlertIsPopWithError:)]],
        @"queryStart":@[@[ATKSelector(queryStartIsCLickWithError:)]],
        @"scan":@[@[ATKSelector(scanWithKey:name:startName:placehodle:error:),ATKString,ATKString,ATKString,ATKString]],
        @"reset":@[@[ATKSelector(reset)]],
        @"resetWithGroupIndex":@[@[ATKSelector(resetWithGroupIndex:error:),ATKString]],
        @"resetWithButtonIndex":@[@[ATKSelector(resetWithButtonIndex:error:),ATKString]],
        @"get":@[@[ATKSelector(getValueByKey:error:),ATKString]],
        @"set":@[@[ATKSelector(saveKey:value:),ATKString,ATKString]],
        @"showAlert":@[@[ATKSelector(showAlertTitle:tipYes:tipNo:),ATKString,ATKString,ATKString]],
        @"isTip":@[@[ATKSelector(queryisTipWithError:)]],
        @"getTime":@[@[ATKSelector(getTimeMs:)]],
        @"selectBox":@[@[ATKSelector(showSelectTitle:buttonPass:buttonSlight:buttonMedium:buttonBad:),ATKString,ATKString,ATKString,ATKString,ATKString]],
        @"selectResult":@[@[ATKSelector(querySelector:)]],
        @"getField":@[@[ATKSelector(getFieldContent:)]],
        @"getFieldSN":@[@[ATKSelector(getFieldSN:)]],
        @"getSNs":@[@[ATKSelector(getSNs:Error:),ATKString]],
        @"getcheckBoxState":@[@[ATKSelector(checkBoxState:andSlot:Error:),ATKString,ATKString]],
        @"getStartClickStatus":@[@[ATKSelector(getStartClickStatus:Error:),ATKString]],
        @"getStartClickStatus1":@[@[ATKSelector(getStartClickStatus1:Error:),ATKString]],
        @"getInputSN":@[@[ATKSelector(getInputSN:Error:),ATKString]]
        
    };
    return functionTable;
}
-(id)checkBoxState:(NSString*)group_number andSlot:(NSString*)slot_number Error:(NSError **)error{
    ATKLog("group:%@---slot:%@",group_number,slot_number);
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSNumber *group = [numberFormatter numberFromString:group_number];
    NSNumber *numberTypeSlot = [numberFormatter numberFromString:slot_number];
    NSInteger slot = [numberTypeSlot integerValue];
    
    NSMutableArray *checkBoxList = [self.checkBoxDic objectForKey:group];
    NSButton *checkBox = [checkBoxList objectAtIndex:slot];
    if ([checkBox state] == NSControlStateValueOn) {
        ATKLog("group:%@---slot:%@ Selected",group_number,slot_number);
        return @"1";
    } else {
        ATKLog("group:%@---slot:%@ Unselected",group_number,slot_number);
        return @"0";
    }
    //    return @"0";
}
//-(id)getSNs1:(NSString*)group andSlot:(NSString*)slot_number Error:(NSError **)error{
//    ATKLog("group is ****%@",group);
//    if([group isEqualToString:@"0"]){
//        return self.snField;
//    };
//    return @"0";
//}
-(id)getSNs:(NSString*)group Error:(NSError **)error{
    ATKLog("group is ****%@",group);
    if([group isEqualToString:@"0"]){
        return self.snField;
    };
    return @"0";
}
- (void)textFieldAction:(id)sendor {
    ATKLog("textFieldAction00000000");
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.self.textField.enabled = NO;
    });
    ATKLog("tag = %ld  sn=%@",self.textField.tag,self.textField.stringValue);
    self.textFieldId = [NSString stringWithFormat:@"%ld",(long)self.textField.tag];
    self.snField = self.textField.stringValue;
}
-(id)getFieldContent:(NSError **)error{
    return self.textFieldId;
}
-(id)getFieldSN:(NSError **)error{
    return self.snField;
}
-(id)getTimeMs:(NSError **)error{
    NSTimeInterval time=[[NSDate date] timeIntervalSince1970];
    NSString *timeSTP = [[NSString alloc] initWithFormat:@"%f",time];
    return timeSTP;
}
-(void)alertWithMsg:(NSString *)msg ok:(NSString*)ok{
    __weak typeof(self)weakSelf = self;
    weakSelf.isAlertPop = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.goertek.Popup"];
        AlertView * vc = [[AlertView alloc]initWithNibName:@"AlertView" bundle:bundle];
        [weakSelf presentViewControllerAsSheet:vc];
        [vc updateUI:msg ok:ok];
        vc.completeBlock = ^(BOOL ok) {
            weakSelf.isAlertPop = NO;
        };
        weakSelf.isAlertPop = YES;
    });
}

-(id)queryAlertIsPopWithError:(NSError **)error{
    
    if (_isAlertPop) {
        return @(1);
    }
    return @(0);
}

-(id)queryStartIsCLickWithError:(NSError **)error{
    
    if (_isClickStart) {
        return @(1);
    }
    return @(0);
}


-(void)saveKey:(NSString *)key value:(NSString *)value{
    
    [self.systemDict addEntriesFromDictionary:@{key:value}];
    
}


-(id)getValueByKey:(NSString *)key error:(NSError **)error{
    
    NSString * value = self.systemDict[key];
    if (value == nil) {
        return  [NSNull null];
    }
    return value;
}

-(id)resetWithGroupIndex:(NSString *)index error:(NSError **)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([index isEqualToString:@"1"]){
            self.buttonStart2.enabled = YES;
        }else if([index isEqualToString:@"2"]){
            self.buttonStart.enabled = YES;
        }
    });
    return @"11";
}

-(id)resetWithButtonIndex:(NSString *)index error:(NSError **)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([index isEqualToString:@"1"]){
            self.buttonStart.enabled = YES;
        }else if([index isEqualToString:@"2"]){
            self.buttonStart2.enabled = YES;
        }
    });
    return @"11";
}

- (void)reset{
    self.snField = @"";
    self.textFieldId = @"";
    self.isClickStart = NO;
    self.buttonStatus = 0;
    self.buttonStatus2 = 0;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //        self.buttonStart.enabled = YES;
        //        self.buttonStart2.enabled = YES;
        weakSelf.inputField.stringValue = @"";
        [weakSelf.view.window makeFirstResponder:nil];
        if (! self.textField.isEnabled){
            weakSelf.self.textField.enabled = YES;
            if (! [self.stationName containsString:@"OQC"]){
                self.textField.stringValue = @"";
            }
            [self.textField becomeFirstResponder];
        }else if (self.textField.stringValue){
            [self.textField becomeFirstResponder];
        }
        if( !self.startButton.isEnabled){
            weakSelf.self.startButton.enabled = YES;
        }
    });
    
    
}

-(id)scanWithKey:(NSString *)key name:(NSString *)name startName:(NSString *)start placehodle:(NSString *)placehodle error:(NSError **)error{
    
    __block NSString * value = @"";
    _pswModel = [PassWordModel new];
    _pswModel.title = name;
    _pswModel.buttonTitle = start;
    _pswModel.passTFPlacehodle = placehodle;
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.goertek.Popup"];
    __block PassWordVC *passVC = [[PassWordVC alloc]initWithNibName:@"PassWordVC" bundle:bundle];
    passVC.obj = self.pswModel;
    ATKLog("⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️……%@",name);
    __weak typeof(self)weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [passVC updateUIWithModel:weakSelf.pswModel];
        [weakSelf presentViewControllerAsSheet:passVC];
    });
    
    
    dispatch_semaphore_t sema =dispatch_semaphore_create(0);
    passVC.completeBlock = ^(NSString * sn) {
        if (sn.length > 0) {
            [weakSelf saveKey:key value:sn];
        }
        value = sn;
        dispatch_semaphore_signal(sema);
    };
    dispatch_semaphore_wait(sema,DISPATCH_TIME_FOREVER);
    return value;
}


- (void)clickOK:(id)sender {
    __weak typeof(self)weakSelf = self;
    self.isClickStart = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.startButton.enabled = NO;
    });
    
}


-(void)showAlertTitle:(NSString *)msg tipYes:(NSString *)tYes tipNo:(NSString *)tNo{
    __weak typeof(self)weakSelf = self;
    self.isTipYes = @2;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.goertek.Popup"];
        AlertMessageView * vc = [[AlertMessageView alloc]initWithNibName:@"AlertMessageView" bundle:bundle];
        [weakSelf presentViewControllerAsSheet:vc];
        [vc updateView:msg tipYes:tYes tipNo:tNo];
        vc.messageBlock = ^(BOOL ok) {
            if (ok == YES) {
                weakSelf.isTipYes = @1;
            }else
            {
                weakSelf.isTipYes = @0;
            }
        };
    });
}
-(id)queryisTipWithError:(NSError **)error{
    return self.isTipYes;
}


-(void)showSelectTitle:(NSString*)message buttonPass:(NSString *)buttonPass buttonSlight:(NSString *)buttonSlight buttonMedium:(NSString *)buttonMedium buttonBad:(NSString *)buttonBad
{
    __weak typeof(self)weakSelf = self;
    self.selector = @4;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.goertek.Popup"];
        SelectorButton * vc = [[SelectorButton alloc]initWithNibName:@"SelectorButton" bundle:bundle];
        [weakSelf presentViewControllerAsSheet:vc];
        [vc updateSelect:message buttonPass:buttonPass buttonSlight:buttonSlight buttonMedium:buttonMedium buttonBad:buttonBad];
        vc.selectBlock = ^(NSNumber *ok) {
            if ([ok isEqualToNumber:@0]) {
                weakSelf.selector = @0;
            };
            if ([ok isEqualToNumber:@1])
            {
                weakSelf.selector = @1;
            };
            if ([ok isEqualToNumber:@2])
            {
                weakSelf.selector = @2;
            }
            ;
            if ([ok isEqualToNumber:@3])
            {
                weakSelf.selector = @3;
            }
        };
    });
}
-(id)querySelector:(NSError **)error{
    return self.selector;
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(deleteBackward:)) {
        // 处理回撤按键事件
        return YES;
    }
    return NO;
}
@end
