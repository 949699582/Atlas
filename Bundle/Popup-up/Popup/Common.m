//
//  Common.m
//  H340Monitor
//
//  Created by 周红强 on 2023/5/27.
//

#import "Common.h"

@implementation Common

+ (NSString *)runCmd:(NSString *)cmd{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    
    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    NSLog(@"输出结果 =%@",result);
    
    return result;
}

+ (NSString *)matchEnglishAndDigitsInString:(NSString *)inputString {
    NSError *error = nil;
    
    // 创建正则表达式，匹配英文字符和数字
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z0-9]+" options:0 error:&error];
    
    if (regex != nil) {
        // 在输入字符串中查找匹配项
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        
        // 遍历匹配结果
        for (NSTextCheckingResult *match in matches) {
            NSString *matchedString = [inputString substringWithRange:[match range]];
            NSLog(@"Matched: %@", matchedString);
            NSLog(@"Matched.length: %ld", matchedString.length);
            return matchedString;
        }
    } else {
        return @"";
//        NSLog(@"Error creating regex: %@", [error localizedDescription]);
    }
    return @"";
}


+ (BOOL)folderExistsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    
    // 检查路径是否存在以及是否是一个目录
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    
    // 返回是否存在并且是目录
    return exists && isDirectory;
}

@end
