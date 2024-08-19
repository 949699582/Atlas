//
//  ViewController.m
//  Atlas2LauncherQQ
//
//  Created by 周红强 on 17/08/2024.
//

#import <Cocoa/Cocoa.h>
#import "BGView.h"
#import "SYFlatButton.h"
#import "Common.h"

#define QQWidth 60
#define QQHeight 40


@interface ViewController : NSViewController
@property (weak) IBOutlet BGView *startView;
@property (weak) IBOutlet BGView *auditView;
@property (weak) IBOutlet BGView *killView;
@property (weak) IBOutlet BGView *nopdcaView;

@property (nonatomic,copy)NSString *stop_cmd;
@property (nonatomic,copy)NSString *open_cmd;
@property (nonatomic,copy)NSString *start_cmd;
@property (nonatomic,copy)NSString *kill_cmd;
@property (nonatomic,copy)NSString *sh_path;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"getPlistName" ofType:@"sh"];
    if (scriptPath) {
        NSLog(@"脚本路径: %@", scriptPath);
        self.sh_path = scriptPath;
        // 注意：在 iOS 上，你不能直接执行这个脚本
        // 在 macOS 上，你可能需要使用 NSTask 来执行它
    } else {
        NSLog(@"未找到脚本文件");
    }
    
    self.stop_cmd = @"/usr/local/bin/AtlasLauncher stop";
    self.open_cmd = @"open /AppleInternal/Applications/AtlasUI.app;open /AppleInternal/Applications/AtlasRecordsUI.app";
    self.kill_cmd = @"pgrep -f Atlas | xargs kill -9";
    
      
    SYFlatButton *button_start = [[SYFlatButton alloc] initWithFrame:NSMakeRect(NSMidX([self.startView bounds]) - 30,
                                                                          NSMidY([self.startView bounds]) - 20,
                                                                          60, 40)];
    button_start.title = @"Start";
    button_start.momentary = YES;
    button_start.cornerRadius = 4.0;
    button_start.backgroundNormalColor = [NSColor greenColor];
    button_start.backgroundHighlightColor = [NSColor blueColor];
    [button_start setTarget:self];
    [button_start setAction:@selector(startButtonClicked:)];
    
    [self.startView addSubview:button_start];
    
    SYFlatButton *button_audit = [[SYFlatButton alloc] initWithFrame:NSMakeRect(NSMidX([self.auditView bounds]) - 30,
                                                                          NSMidY([self.auditView bounds]) - 20,
                                                                          60, 40)];
    button_audit.title = @"Audit";
    button_audit.momentary = YES;
    button_audit.cornerRadius = 4.0;
    button_audit.backgroundNormalColor = [NSColor redColor];
    button_audit.backgroundHighlightColor = [NSColor blueColor];
    [button_audit setTarget:self];
    [button_audit setAction:@selector(auditButtonClicked:)];
    
    [self.auditView addSubview:button_audit];
    
    
    SYFlatButton *button_kill = [[SYFlatButton alloc] initWithFrame:NSMakeRect(NSMidX([self.killView bounds]) - 30,
                                                                          NSMidY([self.killView bounds]) - 20,
                                                                          60, 40)];
    button_kill.title = @"Kill";
    button_kill.momentary = YES;
    button_kill.cornerRadius = 4.0;
    button_kill.backgroundNormalColor = [NSColor yellowColor];
    button_kill.backgroundHighlightColor = [NSColor blueColor];
    [button_kill setTarget:self];
    [button_kill setAction:@selector(killButtonClicked:)];
    
    [self.killView addSubview:button_kill];
    
    
    
    SYFlatButton *button_nopdca = [[SYFlatButton alloc] initWithFrame:NSMakeRect(NSMidX([self.nopdcaView bounds]) - 30,
                                                                          NSMidY([self.nopdcaView bounds]) - 20,
                                                                          60, 40)];
    button_nopdca.title = @"nopdca";
    button_nopdca.momentary = YES;
    button_nopdca.cornerRadius = 4.0;
    button_nopdca.backgroundNormalColor = [NSColor orangeColor];
    button_nopdca.backgroundHighlightColor = [NSColor blueColor];
    [button_nopdca setTarget:self];
    [button_nopdca setAction:@selector(nopdcaButtonClicked:)];
    
    [self.nopdcaView addSubview:button_nopdca];

}

- (void)startButtonClicked:(SYFlatButton *)sender {
    // 处理 Start 按钮的点击事件
    NSLog(@"========>startButtonClicked");
    [Common runCmd:self.stop_cmd];
    
    [Common runCmd:self.open_cmd];
    
    NSString *start_cmd = @"/usr/local/bin/AtlasLauncher start ~/Library/Atlas2/Config/station.plist";
    [Common runCmd:start_cmd];
}

- (void)auditButtonClicked:(id)sender {
    // 处理 Audit 按钮的点击事件
    NSLog(@"========>auditButtonClicked");
    [Common runCmd:self.stop_cmd];
    
    [Common runCmd:self.open_cmd];
    
    NSString *start_cmd = @"/usr/local/bin/AtlasLauncher start ~/Library/Atlas2/Config/stationAudit.plist";
    [Common runCmd:start_cmd];
}

- (void)killButtonClicked:(id)sender {
    // 处理 Kill 按钮的点击事件
    NSLog(@"========>killButtonClicked");
    [Common runCmd:self.stop_cmd];
    
//    [Common runCmd:self.open_cmd];
    
//    NSString *start_cmd = @"/usr/local/bin/AtlasLauncher start ~/Library/Atlas2/Config/stationAudit.plist";
    [Common runCmd:self.kill_cmd];
}

- (void)nopdcaButtonClicked:(id)sender {
    // 处理 NOPDCA 按钮的点击事件
    NSLog(@"========>nopdcaButtonClicked");
    
    [Common runCmd:self.stop_cmd];
    
    [Common runCmd:self.open_cmd];
    
    NSString *start_cmd = @"/usr/local/bin/AtlasLauncher start ~/Library/Atlas2/Config/stationNOPDCA.plist";
    [Common runCmd:start_cmd];
}

@end
