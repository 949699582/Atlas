//
//  Common.h
//  H340Monitor
//
//  Created by 周红强 on 2023/5/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Common : NSObject

+ (NSString *)runCmd:(NSString *)cmd;

+ (NSString *)matchEnglishAndDigitsInString:(NSString *)inputString;

// 检查文件夹路径是否存在
+ (BOOL)folderExistsAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
